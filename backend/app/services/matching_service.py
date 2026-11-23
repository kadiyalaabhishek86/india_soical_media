import uuid
from datetime import datetime, timezone
from typing import Optional, Tuple
from sqlalchemy import select, and_, or_, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.database_models import (
    Profile, ProfileLanguage, QueueEntry, CallSession, CallParticipant, Friendship, Block, Pass
)
from app.services.calling_provider import get_calling_provider

async def check_user_eligibility_and_entitlement(session: AsyncSession, user_id: str) -> Tuple[bool, str, Profile]:
    # 1. Fetch profile
    stmt = select(Profile).where(Profile.id == user_id, Profile.is_deleted == False)
    result = await session.execute(stmt)
    profile = result.scalar_one_or_none()

    if not profile:
        return False, "User profile not found or account deleted.", None

    if not profile.is_adult:
        return False, "Must be an adult (18+) to participate.", profile

    if profile.is_suspended:
        return False, f"Account suspended: {profile.suspension_reason or 'Policy violation'}.", profile

    if not profile.rules_accepted:
        return False, "Community rules must be accepted before matching.", profile

    # 2. Entitlement: check free calls remaining OR active pass
    has_entitlement = profile.free_calls_remaining > 0
    if not has_entitlement:
        from app.services.billing_service import get_active_pass_for_user
        active_pass = await get_active_pass_for_user(session, user_id)
        if active_pass:
            has_entitlement = True

    if not has_entitlement:
        return False, "No remaining call credits or active pass.", profile

    return True, "Eligible", profile

async def try_match_user(session: AsyncSession, user_id: str, call_mode: str = "voice", allow_any_language: bool = False) -> Optional[CallSession]:
    """
    Attempts to match a user with a waiting candidate in the queue.
    If match found, atomically creates a CallSession and removes both from queue.
    Otherwise, ensures the user is safely in the queue.
    """
    eligible, reason, profile = await check_user_eligibility_and_entitlement(session, user_id)
    if not eligible:
        raise ValueError(reason)

    # Check if user already has an active call session
    active_call_stmt = select(CallSession).join(CallParticipant).where(
        CallParticipant.user_id == user_id,
        CallSession.status.in_(["created", "connecting", "connected"])
    )
    existing_call = (await session.execute(active_call_stmt)).scalar_one_or_none()
    if existing_call:
        return existing_call

    # Get user's preferred languages
    user_langs_stmt = select(ProfileLanguage.language).where(ProfileLanguage.profile_id == user_id)
    user_langs = set((await session.execute(user_langs_stmt)).scalars().all())

    # Find waiting queue candidates for the same call_mode
    # Order by oldest first (FIFO)
    queue_candidates_stmt = (
        select(QueueEntry, Profile)
        .join(Profile, QueueEntry.user_id == Profile.id)
        .where(
            QueueEntry.user_id != user_id,
            QueueEntry.call_mode == call_mode,
            QueueEntry.status == "waiting",
            Profile.is_suspended == False,
            Profile.is_deleted == False
        )
        .order_by(QueueEntry.created_at.asc())
    )
    candidates = (await session.execute(queue_candidates_stmt)).all()

    provider = get_calling_provider()
    matched_candidate = None

    for candidate_entry, candidate_profile in candidates:
        cand_id = candidate_entry.user_id

        # 1. Check if existing friends
        u1, u2 = (user_id, cand_id) if user_id < cand_id else (cand_id, user_id)
        friend_stmt = select(Friendship).where(
            Friendship.user_id1 == u1,
            Friendship.user_id2 == u2,
            Friendship.status == "active"
        )
        if (await session.execute(friend_stmt)).scalar_one_or_none():
            continue

        # 2. Check blocks in either direction
        block_stmt = select(Block).where(
            or_(
                and_(Block.blocker_id == user_id, Block.blocked_id == cand_id),
                and_(Block.blocker_id == cand_id, Block.blocked_id == user_id)
            )
        )
        if (await session.execute(block_stmt)).scalar_one_or_none():
            continue

        # 3. Check language compatibility
        cand_langs_stmt = select(ProfileLanguage.language).where(ProfileLanguage.profile_id == cand_id)
        cand_langs = set((await session.execute(cand_langs_stmt)).scalars().all())

        shared_langs = user_langs.intersection(cand_langs)
        if shared_langs or allow_any_language or candidate_entry.allow_any_language:
            matched_candidate = (candidate_entry, candidate_profile)
            break

    if matched_candidate:
        cand_entry, cand_profile = matched_candidate

        # Create room and CallSession
        room_id = f"room_{uuid.uuid4().hex[:12]}"
        provider.create_room(room_id, call_mode)

        token_user = provider.generate_token(room_id, user_id, profile.display_name)
        token_cand = provider.generate_token(room_id, cand_profile.id, cand_profile.display_name)

        new_session = CallSession(
            room_id=room_id,
            call_mode=call_mode,
            status="connecting",
            duration_seconds=60
        )
        session.add(new_session)
        await session.flush()

        # Add participants
        p1 = CallParticipant(call_id=new_session.id, user_id=user_id, role="participant", token=token_user)
        p2 = CallParticipant(call_id=new_session.id, user_id=cand_profile.id, role="participant", token=token_cand)
        session.add_all([p1, p2])

        # Remove both from queue
        await session.execute(delete(QueueEntry).where(QueueEntry.user_id.in_([user_id, cand_profile.id])))
        await session.commit()
        await session.refresh(new_session)
        return new_session
    else:
        # No candidate right now, ensure user is placed or updated in queue
        queue_stmt = select(QueueEntry).where(QueueEntry.user_id == user_id)
        existing_q = (await session.execute(queue_stmt)).scalar_one_or_none()
        if existing_q:
            existing_q.call_mode = call_mode
            existing_q.allow_any_language = allow_any_language
            existing_q.status = "waiting"
            existing_q.updated_at = datetime.utcnow()
        else:
            new_q = QueueEntry(
                user_id=user_id,
                call_mode=call_mode,
                allow_any_language=allow_any_language,
                status="waiting"
            )
            session.add(new_q)
        await session.commit()
        return None
