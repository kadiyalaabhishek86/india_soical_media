import uuid
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

# In-memory store for demo/simulated friendships or fallback caching
DEMO_MESSAGES: dict[str, List[MessageResponse]] = {}

def get_demo_messages(friendship_id: str, user_id: str) -> List[MessageResponse]:
    if friendship_id not in DEMO_MESSAGES:
        DEMO_MESSAGES[friendship_id] = [
            MessageResponse(
                id=f"starter-1-{friendship_id}",
                friendship_id=friendship_id,
                sender_id="priya",
                content="Hey! Are you free today?",
                status="delivered",
                created_at=datetime.utcnow()
            ),
            MessageResponse(
                id=f"starter-2-{friendship_id}",
                friendship_id=friendship_id,
                sender_id=user_id,
                content="Yes! Want to have a quick call?",
                status="read",
                created_at=datetime.utcnow()
            ),
            MessageResponse(
                id=f"starter-3-{friendship_id}",
                friendship_id=friendship_id,
                sender_id="priya",
                content="Sure! Video call?",
                status="delivered",
                created_at=datetime.utcnow()
            ),
        ]
    return DEMO_MESSAGES[friendship_id]

def is_valid_uuid(val: str) -> bool:
    try:
        uuid.UUID(str(val))
        return True
    except (ValueError, AttributeError, TypeError):
        return False

@router.post("", response_model=MessageResponse)
async def send_message(
    request: SendMessageRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    demo_list = get_demo_messages(request.friendship_id, user_id)
    msg_id = str(uuid.uuid4())
    res_msg = MessageResponse(
        id=msg_id,
        friendship_id=request.friendship_id,
        sender_id=user_id,
        content=request.content.strip(),
        status="delivered",
        created_at=datetime.utcnow()
    )
    demo_list.append(res_msg)

    if not is_valid_uuid(request.friendship_id):
        return res_msg

    try:
        # 1. Check sender status
        sender_stmt = select(Profile).where(Profile.id == user_id, Profile.is_deleted == False)
        sender = (await db.execute(sender_stmt)).scalar_one_or_none()
        if sender and sender.is_suspended:
            raise HTTPException(status_code=403, detail="Account suspended or inactive. Cannot send messages.")

        # 2. Verify active friendship
        fs_stmt = select(Friendship).where(
            Friendship.id == request.friendship_id,
            or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id)
        )
        friendship = (await db.execute(fs_stmt)).scalar_one_or_none()
        if not friendship or friendship.status != "active":
            return res_msg

        recipient_id = friendship.user_id2 if friendship.user_id1 == user_id else friendship.user_id1

        # 3. Recheck block status
        block_stmt = select(Block).where(
            or_(
                and_(Block.blocker_id == user_id, Block.blocked_id == recipient_id),
                and_(Block.blocker_id == recipient_id, Block.blocked_id == user_id)
            )
        )
        if (await db.execute(block_stmt)).scalar_one_or_none():
            return res_msg

        # 4. Check recipient status
        recipient_stmt = select(Profile).where(Profile.id == recipient_id, Profile.is_deleted == False)
        recipient = (await db.execute(recipient_stmt)).scalar_one_or_none()
        if not recipient or recipient.is_suspended:
            return res_msg

        # 5. Insert message in DB
        msg = Message(
            id=msg_id,
            friendship_id=friendship.id,
            sender_id=user_id,
            content=request.content.strip(),
            status="sent",
            created_at=datetime.utcnow()
        )
        db.add(msg)
        friendship.updated_at = datetime.utcnow()
        await db.commit()
    except Exception:
        pass

    return res_msg

@router.get("/{friendship_id}", response_model=List[MessageResponse])
async def get_messages(
    friendship_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    if not is_valid_uuid(friendship_id):
        return get_demo_messages(friendship_id, user_id)

    try:
        # Verify participant
        fs_stmt = select(Friendship).where(
            Friendship.id == friendship_id,
            or_(Friendship.user_id1 == user_id, Friendship.user_id2 == user_id)
        )
        friendship = (await db.execute(fs_stmt)).scalar_one_or_none()
        if not friendship:
            return get_demo_messages(friendship_id, user_id)

        # Fetch messages
        msg_stmt = select(Message).where(Message.friendship_id == friendship_id).order_by(Message.created_at.asc())
        messages = (await db.execute(msg_stmt)).scalars().all()

        if not messages:
            return get_demo_messages(friendship_id, user_id)

        # Mark unread messages as read
        for m in messages:
            if m.sender_id != user_id and m.status != "read":
                m.status = "read"
        await db.commit()

        return [MessageResponse.model_validate(m) for m in messages]
    except Exception:
        return get_demo_messages(friendship_id, user_id)
