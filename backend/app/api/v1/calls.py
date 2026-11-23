from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Header, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.database_models import CallSession, CallParticipant, CallUsageRecord, Profile, Pass
from app.models.schemas import ConnectCallRequest, ReconnectResponse, CallSessionResponse
from app.services.calling_provider import get_calling_provider
from app.api.v1.match import build_session_response

router = APIRouter(prefix="/calls", tags=["calls"])

async def charge_credit_idempotently(db: AsyncSession, user_id: str, call_id: str):
    """
    Ensures exactly 1 credit is deducted per participant per session.
    Idempotent: Duplicate or simultaneous callbacks consume zero extra credits.
    """
    # Check if already charged
    stmt = select(CallUsageRecord).where(
        CallUsageRecord.user_id == user_id,
        CallUsageRecord.call_id == call_id
    )
    existing_record = (await db.execute(stmt)).scalar_one_or_none()
    if existing_record:
        return # Already charged

    # Check for active pass
    now = datetime.now(timezone.utc)
    pass_stmt = select(Pass).where(
        Pass.user_id == user_id,
        Pass.status == "active",
        Pass.expires_at > now
    )
    active_pass = (await db.execute(pass_stmt)).scalars().first()

    credit_type = "paid_pass" if active_pass else "free"

    usage = CallUsageRecord(
        user_id=user_id,
        call_id=call_id,
        credit_type=credit_type
    )
    db.add(usage)

    if credit_type == "free":
        # Deduct free credit safely
        p_stmt = select(Profile).where(Profile.id == user_id)
        profile = (await db.execute(p_stmt)).scalar_one()
        if profile.free_calls_remaining > 0:
            profile.free_calls_remaining -= 1

    await db.commit()

@router.get("/{room_id}", response_model=CallSessionResponse)
async def get_call_session(
    room_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CallSession).where(CallSession.room_id == room_id)
    session = (await db.execute(stmt)).scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Call session not found.")

    return await build_session_response(session, user_id, db)

@router.post("/connect", response_model=CallSessionResponse)
async def participant_connected(
    request: ConnectCallRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CallSession).where(CallSession.room_id == request.room_id)
    call_sess = (await db.execute(stmt)).scalar_one_or_none()
    if not call_sess:
        raise HTTPException(status_code=404, detail="Call session not found.")

    if call_sess.status in ["completed", "cancelled", "terminated"]:
        raise HTTPException(status_code=400, detail="Call session has already ended.")

    # Find participant record
    p_stmt = select(CallParticipant).where(
        CallParticipant.call_id == call_sess.id,
        CallParticipant.user_id == user_id
    )
    part = (await db.execute(p_stmt)).scalar_one_or_none()
    if not part:
        raise HTTPException(status_code=403, detail="Not an authorized participant of this call.")

    now = datetime.now(timezone.utc)
    if not part.connected_at:
        part.connected_at = now

    # Check if ALL participants are now connected
    all_parts = call_sess.participants
    all_connected = len(all_parts) >= 2 and all(p.connected_at is not None for p in all_parts)

    if all_connected and call_sess.status != "connected":
        # Start server-owned 60-second timer!
        call_sess.status = "connected"
        call_sess.started_at = now
        call_sess.shared_end_time = now + timedelta(seconds=call_sess.duration_seconds)
        await db.commit()

        # Deduct 1 credit idempotently for EACH participant
        for p in all_parts:
            await charge_credit_idempotently(db, p.user_id, call_sess.id)
    else:
        await db.commit()

    await db.refresh(call_sess)
    return await build_session_response(call_sess, user_id, db)

@router.post("/leave")
async def leave_call(
    request: ConnectCallRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CallSession).where(CallSession.room_id == request.room_id)
    call_sess = (await db.execute(stmt)).scalar_one_or_none()
    if not call_sess:
        raise HTTPException(status_code=404, detail="Call session not found.")

    p_stmt = select(CallParticipant).where(
        CallParticipant.call_id == call_sess.id,
        CallParticipant.user_id == user_id
    )
    part = (await db.execute(p_stmt)).scalar_one_or_none()
    if part:
        part.disconnected_at = datetime.now(timezone.utc)

    # If call was connecting or connected, mark it completed or terminated
    if call_sess.status in ["created", "connecting"]:
        call_sess.status = "cancelled"
        call_sess.terminated_reason = f"User {user_id[:8]} left before connection"
    elif call_sess.status == "connected":
        call_sess.status = "completed"
        call_sess.terminated_reason = f"User {user_id[:8]} hung up"

    await db.commit()
    get_calling_provider().end_room(call_sess.room_id)
    return {"success": True, "status": call_sess.status}

@router.get("/reconnect/{room_id}", response_model=ReconnectResponse)
async def reconnect_call(
    room_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CallSession).where(CallSession.room_id == room_id)
    call_sess = (await db.execute(stmt)).scalar_one_or_none()
    if not call_sess:
        raise HTTPException(status_code=404, detail="Call session not found.")

    now = datetime.now(timezone.utc)
    remaining_seconds = 0

    if call_sess.shared_end_time:
        # Reconnection uses the same session and remaining time!
        shared_time = call_sess.shared_end_time
        if shared_time.tzinfo is None:
            shared_time = shared_time.replace(tzinfo=timezone.utc)
        delta = (shared_time - now).total_seconds()
        remaining_seconds = max(0, int(delta))
        if remaining_seconds <= 0 and call_sess.status == "connected":
            call_sess.status = "completed"
            call_sess.terminated_reason = "60s timer expired"
            await db.commit()
    elif call_sess.status in ["created", "connecting"]:
        remaining_seconds = 60

    return ReconnectResponse(
        room_id=call_sess.room_id,
        status=call_sess.status,
        shared_end_time=call_sess.shared_end_time,
        remaining_seconds=remaining_seconds
    )

@router.post("/webhook")
async def provider_webhook(
    request: Request,
    x_signature: Optional[str] = Header(None, alias="X-Provider-Signature"),
    db: AsyncSession = Depends(get_db)
):
    body = await request.body()
    provider = get_calling_provider()
    if not provider.verify_webhook_signature(body, x_signature):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid webhook signature")

    data = await request.json()
    event_type = data.get("event")
    room_id = data.get("room_id")
    participant_user_id = data.get("user_id")

    if not room_id:
        return {"status": "ignored"}

    stmt = select(CallSession).where(CallSession.room_id == room_id)
    call_sess = (await db.execute(stmt)).scalar_one_or_none()
    if not call_sess:
        return {"status": "not_found"}

    now = datetime.now(timezone.utc)

    if event_type == "participant_joined" and participant_user_id:
        p_stmt = select(CallParticipant).where(
            CallParticipant.call_id == call_sess.id,
            CallParticipant.user_id == participant_user_id
        )
        part = (await db.execute(p_stmt)).scalar_one_or_none()
        if part and not part.connected_at:
            part.connected_at = now

        # Check if both connected
        if len(call_sess.participants) >= 2 and all(p.connected_at is not None for p in call_sess.participants):
            if call_sess.status != "connected":
                call_sess.status = "connected"
                call_sess.started_at = now
                call_sess.shared_end_time = now + timedelta(seconds=call_sess.duration_seconds)
                await db.commit()
                for p in call_sess.participants:
                    await charge_credit_idempotently(db, p.user_id, call_sess.id)
            else:
                await db.commit()
        else:
            await db.commit()

    elif event_type in ["participant_left", "room_finished"]:
        if call_sess.status == "connected":
            call_sess.status = "completed"
            call_sess.terminated_reason = "Provider room finished"
            await db.commit()

    return {"status": "processed"}
