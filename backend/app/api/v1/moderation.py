from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, and_, or_, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.database_models import (
    Block, Report, Profile, CallSession, CallParticipant, Friendship, QueueEntry, SupportTicket
)
from app.models.schemas import BlockUserRequest, ReportRequest, ReportResponse, SupportTicketRequest, PublicProfileResponse
from app.services.calling_provider import get_calling_provider

router = APIRouter(prefix="/moderation", tags=["moderation"])

@router.post("/block")
async def block_user(
    request: BlockUserRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    target_id = request.blocked_id
    if user_id == target_id:
        raise HTTPException(status_code=400, detail="Cannot block oneself.")

    # 1. Insert block record
    stmt = select(Block).where(Block.blocker_id == user_id, Block.blocked_id == target_id)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if not existing:
        db.add(Block(blocker_id=user_id, blocked_id=target_id, reason=request.reason))

    # 2. End any active call between the pair immediately
    active_calls_stmt = select(CallSession).join(CallParticipant).where(
        CallParticipant.user_id.in_([user_id, target_id]),
        CallSession.status.in_(["created", "connecting", "connected"])
    )
    calls = (await db.execute(active_calls_stmt)).scalars().all()
    for call in calls:
        call.status = "terminated"
        call.terminated_reason = f"User {user_id[:8]} blocked participant"
        get_calling_provider().end_room(call.room_id)

    # 3. If there is a friendship, mark it blocked
    u1, u2 = (user_id, target_id) if user_id < target_id else (target_id, user_id)
    fs_stmt = select(Friendship).where(Friendship.user_id1 == u1, Friendship.user_id2 == u2)
    fs = (await db.execute(fs_stmt)).scalar_one_or_none()
    if fs:
        fs.status = "blocked"
        fs.updated_at = datetime.utcnow()

    # 4. Remove both from queue
    await db.execute(delete(QueueEntry).where(QueueEntry.user_id.in_([user_id, target_id])))

    await db.commit()
    return {"success": True, "message": "User blocked successfully. Active contact ended."}

@router.get("/blocked", response_model=List[PublicProfileResponse])
async def list_blocked_users(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Block).where(Block.blocker_id == user_id)
    blocks = (await db.execute(stmt)).scalars().all()
    blocked_ids = [b.blocked_id for b in blocks]

    if not blocked_ids:
        return []

    prof_stmt = select(Profile).where(Profile.id.in_(blocked_ids))
    profiles = (await db.execute(prof_stmt)).scalars().all()

    return [
        PublicProfileResponse(
            id=p.id,
            display_name=p.display_name,
            state_or_union_territory=p.state_or_union_territory,
            city=p.city,
            languages=[l.language for l in p.languages]
        )
        for p in profiles
    ]

@router.delete("/block/{target_id}")
async def unblock_user(
    target_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    await db.execute(delete(Block).where(Block.blocker_id == user_id, Block.blocked_id == target_id))
    await db.commit()
    return {"success": True, "message": "User unblocked."}

@router.post("/report", response_model=ReportResponse)
async def report_user(
    request: ReportRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    valid_reasons = ["harassment", "threats", "scam", "underage", "inappropriate_content", "other"]
    if request.reason not in valid_reasons:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid reason. Must be one of: {', '.join(valid_reasons)}"
        )

    # Verify reported user exists
    p_stmt = select(Profile).where(Profile.id == request.reported_id)
    if not (await db.execute(p_stmt)).scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Reported user not found.")

    report = Report(
        reporter_id=user_id,
        reported_id=request.reported_id,
        call_id=request.call_id,
        reason=request.reason,
        details=request.details,
        status="pending"
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    return ReportResponse(
        report_id=report.id,
        message="Thank you for keeping Aara safe. Your report has been submitted confidentially."
    )

@router.post("/support")
async def contact_support(
    request: SupportTicketRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    ticket = SupportTicket(
        user_id=user_id,
        subject=request.subject or "User Feedback",
        message=request.message,
        status="open"
    )
    db.add(ticket)
    await db.commit()
    await db.refresh(ticket)
    return {
        "success": True,
        "ticket_id": ticket.id,
        "message": "Support & feedback received. Our team will review within 24 hours."
    }

@router.post("/delete-account")
async def delete_account(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Profile).where(Profile.id == user_id)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")

    # Soft delete: wipe identifiers, mark deleted
    profile.is_deleted = True
    profile.display_name = "Deleted User"
    profile.phone = f"+9100000{profile.phone[-5:]}_del_{int(datetime.utcnow().timestamp())}"
    profile.updated_at = datetime.utcnow()

    # Cancel active calls and friendships
    await db.execute(delete(QueueEntry).where(QueueEntry.user_id == user_id))

    fs_stmt = select(Friendship).where(or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id))
    friendships = (await db.execute(fs_stmt)).scalars().all()
    for f in friendships:
        f.status = "unfriended"

    await db.commit()
    return {"success": True, "message": "Account successfully deleted."}
