from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, delete
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.database_models import QueueEntry, CallSession, CallParticipant, Profile
from app.models.schemas import JoinQueueRequest, QueueStatusResponse, CallSessionResponse, PublicProfileResponse
from app.services.matching_service import try_match_user

router = APIRouter(prefix="/match", tags=["match"])

async def build_session_response(session: CallSession, current_user_id: str, db: AsyncSession) -> CallSessionResponse:
    user_token = None
    partner_profile = None

    p_stmt = select(CallParticipant).where(CallParticipant.call_id == session.id)
    participants = (await db.execute(p_stmt)).scalars().all()

    for p in participants:
        if p.user_id == current_user_id:
            user_token = p.token
        else:
            p_stmt = select(Profile).options(selectinload(Profile.languages)).where(Profile.id == p.user_id)
            prof = (await db.execute(p_stmt)).scalar_one_or_none()
            if prof:
                langs = [l.language for l in prof.languages]
                partner_profile = PublicProfileResponse(
                    id=prof.id,
                    display_name=prof.display_name,
                    state_or_union_territory=prof.state_or_union_territory,
                    city=prof.city,
                    languages=langs
                )

    return CallSessionResponse(
        id=session.id,
        room_id=session.room_id,
        call_mode=session.call_mode,
        status=session.status,
        started_at=session.started_at,
        shared_end_time=session.shared_end_time,
        duration_seconds=session.duration_seconds,
        token=user_token,
        partner=partner_profile
    )

@router.post("/join", response_model=QueueStatusResponse)
async def join_queue(
    request: JoinQueueRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    try:
        session = await try_match_user(
            db,
            user_id=user_id,
            call_mode=request.call_mode,
            allow_any_language=request.allow_any_language
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    if session:
        session_resp = await build_session_response(session, user_id, db)
        return QueueStatusResponse(
            in_queue=False,
            queue_id=None,
            call_mode=session.call_mode,
            matched_session=session_resp
        )
    else:
        q_stmt = select(QueueEntry).where(QueueEntry.user_id == user_id)
        q = (await db.execute(q_stmt)).scalar_one_or_none()
        return QueueStatusResponse(
            in_queue=True,
            queue_id=q.id if q else None,
            call_mode=request.call_mode,
            allow_any_language=request.allow_any_language,
            wait_time_seconds=0,
            matched_session=None
        )

@router.post("/cancel")
async def cancel_queue(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    await db.execute(delete(QueueEntry).where(QueueEntry.user_id == user_id))
    await db.commit()
    return {"success": True, "message": "Cancelled queue search. Zero credits consumed."}

@router.post("/broaden", response_model=QueueStatusResponse)
async def broaden_languages(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    try:
        session = await try_match_user(
            db,
            user_id=user_id,
            call_mode="voice",
            allow_any_language=True
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    if session:
        session_resp = await build_session_response(session, user_id, db)
        return QueueStatusResponse(
            in_queue=False,
            matched_session=session_resp
        )
    else:
        q_stmt = select(QueueEntry).where(QueueEntry.user_id == user_id)
        q = (await db.execute(q_stmt)).scalar_one_or_none()
        return QueueStatusResponse(
            in_queue=True,
            queue_id=q.id if q else None,
            call_mode="voice",
            allow_any_language=True,
            matched_session=None
        )

@router.get("/status", response_model=QueueStatusResponse)
async def get_queue_status(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    # First check active call
    active_call_stmt = select(CallSession).join(CallParticipant).where(
        CallParticipant.user_id == user_id,
        CallSession.status.in_(["created", "connecting", "connected"])
    )
    active_call = (await db.execute(active_call_stmt)).scalar_one_or_none()
    if active_call:
        session_resp = await build_session_response(active_call, user_id, db)
        return QueueStatusResponse(
            in_queue=False,
            matched_session=session_resp
        )

    # Check queue
    q_stmt = select(QueueEntry).where(QueueEntry.user_id == user_id, QueueEntry.status == "waiting")
    q = (await db.execute(q_stmt)).scalar_one_or_none()
    if q:
        return QueueStatusResponse(
            in_queue=True,
            queue_id=q.id,
            call_mode=q.call_mode,
            allow_any_language=q.allow_any_language,
            matched_session=None
        )

    return QueueStatusResponse(in_queue=False, matched_session=None)
