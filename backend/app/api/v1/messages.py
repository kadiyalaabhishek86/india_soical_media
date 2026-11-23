from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.database_models import Friendship, Message, Block, Profile
from app.models.schemas import SendMessageRequest, MessageResponse, UpdateMessageStatusRequest

router = APIRouter(prefix="/messages", tags=["messages"])

@router.post("", response_model=MessageResponse)
async def send_message(
    request: SendMessageRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    # 1. Check sender status
    sender_stmt = select(Profile).where(Profile.id == user_id, Profile.is_deleted == False)
    sender = (await db.execute(sender_stmt)).scalar_one_or_none()
    if not sender or sender.is_suspended:
        raise HTTPException(status_code=403, detail="Account suspended or inactive. Cannot send messages.")

    # 2. Verify active friendship
    fs_stmt = select(Friendship).where(
        Friendship.id == request.friendship_id,
        or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id)
    )
    friendship = (await db.execute(fs_stmt)).scalar_one_or_none()
    if not friendship or friendship.status != "active":
        raise HTTPException(status_code=403, detail="Active friendship required to send messages.")

    recipient_id = friendship.user_id2 if friendship.user_id1 == user_id else friendship.user_id1

    # 3. Recheck block status
    block_stmt = select(Block).where(
        or_(
            and_(Block.blocker_id == user_id, Block.blocked_id == recipient_id),
            and_(Block.blocker_id == recipient_id, Block.blocked_id == user_id)
        )
    )
    if (await db.execute(block_stmt)).scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Cannot send message to a blocked user.")

    # 4. Check recipient status
    recipient_stmt = select(Profile).where(Profile.id == recipient_id, Profile.is_deleted == False)
    recipient = (await db.execute(recipient_stmt)).scalar_one_or_none()
    if not recipient or recipient.is_suspended:
        raise HTTPException(status_code=403, detail="Recipient is suspended or unavailable.")

    # 5. Insert message
    msg = Message(
        friendship_id=friendship.id,
        sender_id=user_id,
        content=request.content.strip(),
        status="sent",
        created_at=datetime.utcnow()
    )
    db.add(msg)
    friendship.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(msg)

    return MessageResponse.model_validate(msg)

@router.get("/{friendship_id}", response_model=List[MessageResponse])
async def get_messages(
    friendship_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    # Verify participant
    fs_stmt = select(Friendship).where(
        Friendship.id == friendship_id,
        or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id)
    )
    friendship = (await db.execute(fs_stmt)).scalar_one_or_none()
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found.")

    # Fetch messages
    msg_stmt = select(Message).where(Message.friendship_id == friendship_id).order_by(Message.created_at.asc())
    messages = (await db.execute(msg_stmt)).scalars().all()

    # Mark unread messages as read
    for m in messages:
        if m.sender_id != user_id and m.status != "read":
            m.status = "read"
    await db.commit()

    return [MessageResponse.model_validate(m) for m in messages]
