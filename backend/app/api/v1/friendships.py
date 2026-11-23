from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.database_models import (
    CallSession, CallParticipant, FriendChoice, Friendship, Profile, Message, Block
)
from app.models.schemas import (
    FriendChoiceRequest, FriendChoiceResponse, FriendListItem, FriendProfileResponse
)

router = APIRouter(prefix="/friendships", tags=["friendships"])

@router.post("/choose", response_model=FriendChoiceResponse)
async def choose_friend(
    request: FriendChoiceRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Records participant's choice to add friend.
    Unilateral choice stays strictly private!
    If both choose each other, creates exactly one friendship atomically.
    """
    call_id = request.call_id
    target_id = request.target_id

    if user_id == target_id:
        raise HTTPException(status_code=400, detail="Cannot add oneself as a friend.")

    # 1. Verify caller was a participant of this call
    cp_stmt = select(CallParticipant).where(
        CallParticipant.call_id == call_id,
        CallParticipant.user_id == user_id
    )
    if not (await db.execute(cp_stmt)).scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Caller was not a participant of this call.")

    # 2. Check blocks
    block_stmt = select(Block).where(
        or_(
            and_(Block.blocker_id == user_id, Block.blocked_id == target_id),
            and_(Block.blocker_id == target_id, Block.blocked_id == user_id)
        )
    )
    if (await db.execute(block_stmt)).scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Cannot add blocked user as friend.")

    # 3. Record choice (idempotent)
    choice_stmt = select(FriendChoice).where(
        FriendChoice.call_id == call_id,
        FriendChoice.chooser_id == user_id,
        FriendChoice.target_id == target_id
    )
    existing_choice = (await db.execute(choice_stmt)).scalar_one_or_none()
    if not existing_choice:
        new_choice = FriendChoice(call_id=call_id, chooser_id=user_id, target_id=target_id)
        db.add(new_choice)
        await db.flush()

    # 4. Check if reciprocal choice exists
    reciprocal_stmt = select(FriendChoice).where(
        FriendChoice.call_id == call_id,
        FriendChoice.chooser_id == target_id,
        FriendChoice.target_id == user_id
    )
    reciprocal = (await db.execute(reciprocal_stmt)).scalar_one_or_none()

    if reciprocal:
        # Both chose Add Friend! Create exactly one canonical friendship
        u1, u2 = (user_id, target_id) if user_id < target_id else (target_id, user_id)
        fs_stmt = select(Friendship).where(Friendship.user_id1 == u1, Friendship.user_id2 == u2)
        friendship = (await db.execute(fs_stmt)).scalar_one_or_none()

        if not friendship:
            friendship = Friendship(
                user_id1=u1,
                user_id2=u2,
                status="active",
                origin_call_id=call_id
            )
            db.add(friendship)
            await db.commit()
            await db.refresh(friendship)
        elif friendship.status != "active":
            friendship.status = "active"
            friendship.updated_at = datetime.utcnow()
            await db.commit()

        return FriendChoiceResponse(
            choice_recorded=True,
            is_mutual=True,
            friendship_id=friendship.id
        )
    else:
        # Unilateral choice: keep strictly private!
        await db.commit()
        return FriendChoiceResponse(
            choice_recorded=True,
            is_mutual=False,
            friendship_id=None
        )

@router.get("", response_model=List[FriendListItem])
async def list_friends(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Friendship).where(
        or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id),
        Friendship.status == "active"
    ).order_by(Friendship.updated_at.desc())

    friendships = (await db.execute(stmt)).scalars().all()
    results = []

    for f in friendships:
        friend_id = f.user_id2 if f.user_id1 == user_id else f.user_id1

        # Profile of friend
        p_stmt = select(Profile).where(Profile.id == friend_id, Profile.is_deleted == False)
        friend_profile = (await db.execute(p_stmt)).scalar_one_or_none()
        if not friend_profile:
            continue

        # Last message
        msg_stmt = select(Message).where(Message.friendship_id == f.id).order_by(Message.created_at.desc())
        last_msg = (await db.execute(msg_stmt)).scalars().first()

        # Unread count
        unread_stmt = select(Message).where(
            Message.friendship_id == f.id,
            Message.sender_id != user_id,
            Message.status != "read"
        )
        unreads = len((await db.execute(unread_stmt)).scalars().all())

        results.append(FriendListItem(
            friendship_id=f.id,
            friend_id=friend_id,
            display_name=friend_profile.display_name,
            age=friend_profile.age,
            gender=friend_profile.gender or "Prefer not to say",
            images=friend_profile.images or [],
            state_or_union_territory=friend_profile.state_or_union_territory,
            city=friend_profile.city,
            unread_count=unreads,
            last_message=last_msg.content if last_msg else None,
            last_message_time=last_msg.created_at if last_msg else None,
            created_at=f.created_at
        ))

    return results

@router.get("/{friendship_id}/profile", response_model=FriendProfileResponse)
async def get_friend_profile(
    friendship_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns public friend profile with 3 photos, age, gender, location, and looking_for note.
    Keeps phone number and birth date strictly private!
    """
    stmt = select(Friendship).where(
        Friendship.id == friendship_id,
        or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id),
        Friendship.status == "active"
    )
    friendship = (await db.execute(stmt)).scalar_one_or_none()
    if not friendship:
        raise HTTPException(status_code=404, detail="Active friendship not found.")

    friend_id = friendship.user_id2 if friendship.user_id1 == user_id else friendship.user_id1
    p_stmt = select(Profile).where(Profile.id == friend_id, Profile.is_deleted == False)
    friend_profile = (await db.execute(p_stmt)).scalar_one_or_none()
    if not friend_profile:
        raise HTTPException(status_code=404, detail="Friend profile not found.")

    langs = [l.language for l in friend_profile.languages]
    return FriendProfileResponse(
        id=friend_profile.id,
        display_name=friend_profile.display_name,
        age=friend_profile.age,
        gender=friend_profile.gender or "Prefer not to say",
        looking_for=friend_profile.looking_for,
        images=friend_profile.images or [],
        state_or_union_territory=friend_profile.state_or_union_territory,
        city=friend_profile.city,
        languages=langs,
        friendship_id=friendship.id,
        created_at=friend_profile.created_at
    )

@router.delete("/{friendship_id}")
async def unfriend(
    friendship_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Friendship).where(
        Friendship.id == friendship_id,
        or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id)
    )
    friendship = (await db.execute(stmt)).scalar_one_or_none()
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found.")

    friendship.status = "unfriended"
    friendship.updated_at = datetime.utcnow()
    await db.commit()
    return {"success": True, "message": "Friendship ended. Chat access closed."}
