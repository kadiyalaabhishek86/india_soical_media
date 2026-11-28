import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.core.database import get_db
from app.core.security import get_current_user, get_optional_current_user
from app.models.database_models import Profile, PartyRoom, PartyParticipant, CoinTransaction
from app.models.schemas import PartyRoomResponse, PartyRoomCreateRequest, PartyParticipantResponse

router = APIRouter(prefix="/rooms", tags=["rooms"])

DEFAULT_ROOMS = [
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555551",
        "title": "Chai & Conversations ☕",
        "room_type": "voice",
        "activity_type": "voice_lounge",
        "language": "Hindi",
        "access_type": "public",
        "entry_fee_coins": 0,
        "max_seats": 20,
        "active_count": 18,
        "host_name": "Priya Nair",
        "host_avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555556",
        "title": "Carrom Clash Match #408 🎯",
        "room_type": "voice",
        "activity_type": "carrom",
        "language": "Hindi",
        "access_type": "public",
        "entry_fee_coins": 10,
        "max_seats": 2,
        "active_count": 2,
        "host_name": "Rhea Sharma",
        "host_avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555557",
        "title": "Party Room #104 Voice Mimic 🐱",
        "room_type": "voice",
        "activity_type": "voice_mimic",
        "language": "English",
        "access_type": "public",
        "entry_fee_coins": 0,
        "max_seats": 10,
        "active_count": 6,
        "host_name": "Rohan Verma",
        "host_avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80",
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555553",
        "title": "Party #104 Truth or Dare 🍾",
        "room_type": "voice",
        "activity_type": "truth_or_dare",
        "language": "Hindi",
        "access_type": "public",
        "entry_fee_coins": 0,
        "max_seats": 15,
        "active_count": 8,
        "host_name": "Ananya Gupta",
        "host_avatar": "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80",
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555555",
        "title": "TABLE #12 Ludo 2v2 Party 🎲",
        "room_type": "voice",
        "activity_type": "ludo",
        "language": "Hindi",
        "access_type": "public",
        "entry_fee_coins": 10,
        "max_seats": 4,
        "active_count": 4,
        "host_name": "Karthik M",
        "host_avatar": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80",
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555552",
        "title": "Travel Buddies India ✈️",
        "room_type": "video",
        "activity_type": "video_stage",
        "language": "English",
        "access_type": "public",
        "entry_fee_coins": 0,
        "max_seats": 24,
        "active_count": 24,
        "host_name": "Rahul Singh",
        "host_avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80",
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555554",
        "title": "Telugu Hangout",
        "room_type": "voice",
        "activity_type": "voice_lounge",
        "language": "Telugu",
        "access_type": "public",
        "entry_fee_coins": 0,
        "max_seats": 30,
        "active_count": 28,
        "host_name": "Vamshi K",
        "host_avatar": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80",
    }
]

@router.get("", response_model=List[PartyRoomResponse])
async def list_rooms(
    type: str = Query("all"),
    db: AsyncSession = Depends(get_db)
):
    query = select(PartyRoom).where(PartyRoom.status == "active")
    if type in ["voice", "video"]:
        query = query.where(PartyRoom.room_type == type)
    query = query.order_by(desc(PartyRoom.created_at)).limit(30)

    result = await db.execute(query)
    rooms = result.scalars().all()

    items = []
    for r in rooms:
        active_c = len(r.participants)
        items.append(PartyRoomResponse(
            id=r.id,
            title=r.title,
            host_id=r.host_id,
            host_name=r.host.display_name if r.host else "Host",
            host_avatar=r.host.images[0] if (r.host and r.host.images) else None,
            room_type=r.room_type,
            activity_type=r.activity_type,
            language=r.language,
            access_type=r.access_type,
            entry_fee_coins=r.entry_fee_coins,
            max_seats=r.max_seats,
            active_count=active_c if active_c > 0 else 1,
            status=r.status,
            participants=[
                PartyParticipantResponse(
                    user_id=p.user_id,
                    user_name=p.user.display_name if p.user else "User",
                    user_avatar=p.user.images[0] if (p.user and p.user.images) else None,
                    role=p.role,
                    seat_index=p.seat_index,
                    joined_at=p.joined_at,
                )
                for p in r.participants
            ],
            created_at=r.created_at,
        ))

    # Always include default rooms so the menu is always vibrant
    existing_ids = {r.id for r in rooms}
    for d in DEFAULT_ROOMS:
        if type != "all" and d["room_type"] != type:
            continue
        if d["id"] not in existing_ids:
            items.append(PartyRoomResponse(
                id=d["id"],
                title=d["title"],
                host_id="host-1",
                host_name=d["host_name"],
                host_avatar=d["host_avatar"],
                room_type=d["room_type"],
                activity_type=d["activity_type"],
                language=d["language"],
                access_type=d["access_type"],
                entry_fee_coins=d["entry_fee_coins"],
                max_seats=d["max_seats"],
                active_count=d["active_count"],
                status="active",
                participants=[
                    PartyParticipantResponse(
                        user_id="host-1",
                        user_name=d["host_name"],
                        user_avatar=d["host_avatar"],
                        role="host",
                        seat_index=0,
                        joined_at=datetime.utcnow(),
                    )
                ],
                created_at=datetime.utcnow(),
            ))

    return items

@router.post("", response_model=PartyRoomResponse, status_code=status.HTTP_201_CREATED)
async def create_room(
    req: PartyRoomCreateRequest,
    current_user: Optional[Profile] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    if not current_user:
        # Provide default profile if unauthenticated
        stmt = select(Profile).limit(1)
        res = await db.execute(stmt)
        current_user = res.scalar_one_or_none()
        if not current_user:
            current_user = Profile(
                id=str(uuid.uuid4()),
                phone="+919876543210",
                display_name="You (Host)",
                coins=100,
                rules_accepted=True,
            )
            db.add(current_user)
            await db.commit()
            await db.refresh(current_user)

    room = PartyRoom(
        title=req.title,
        host_id=current_user.id,
        room_type=req.room_type,
        activity_type=req.activity_type,
        language=req.language,
        access_type=req.access_type,
        entry_fee_coins=req.entry_fee_coins,
        max_seats=req.max_seats,
        status="active",
    )
    db.add(room)
    await db.flush()

    host_participant = PartyParticipant(
        room_id=room.id,
        user_id=current_user.id,
        role="host",
        seat_index=0,
    )
    db.add(host_participant)
    await db.commit()
    await db.refresh(room)

    return PartyRoomResponse(
        id=room.id,
        title=room.title,
        host_id=current_user.id,
        host_name=current_user.display_name,
        host_avatar=current_user.images[0] if current_user.images else None,
        room_type=room.room_type,
        activity_type=room.activity_type,
        language=room.language,
        access_type=room.access_type,
        entry_fee_coins=room.entry_fee_coins,
        max_seats=room.max_seats,
        active_count=1,
        status="active",
        participants=[
            PartyParticipantResponse(
                user_id=current_user.id,
                user_name=current_user.display_name,
                user_avatar=current_user.images[0] if current_user.images else None,
                role="host",
                seat_index=0,
                joined_at=host_participant.joined_at,
            )
        ],
        created_at=room.created_at,
    )

@router.get("/{room_id}", response_model=PartyRoomResponse)
async def get_room_detail(
    room_id: str,
    db: AsyncSession = Depends(get_db)
):
    q = select(PartyRoom).where(PartyRoom.id == room_id)
    res = await db.execute(q)
    r = res.scalar_one_or_none()
    if not r:
        # Check defaults
        for d in DEFAULT_ROOMS:
            if d["id"] == room_id:
                return PartyRoomResponse(
                    id=d["id"],
                    title=d["title"],
                    host_id="host-1",
                    host_name=d["host_name"],
                    host_avatar=d["host_avatar"],
                    room_type=d["room_type"],
                    activity_type=d["activity_type"],
                    language=d["language"],
                    access_type=d["access_type"],
                    entry_fee_coins=d["entry_fee_coins"],
                    max_seats=d["max_seats"],
                    active_count=d["active_count"],
                    status="active",
                    participants=[
                        PartyParticipantResponse(
                            user_id="host-1",
                            user_name=d["host_name"],
                            user_avatar=d["host_avatar"],
                            role="host",
                            seat_index=0,
                            joined_at=datetime.utcnow(),
                        ),
                        PartyParticipantResponse(
                            user_id="speaker-1",
                            user_name="Ananya R",
                            user_avatar="https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80",
                            role="speaker",
                            seat_index=1,
                            joined_at=datetime.utcnow(),
                        ),
                        PartyParticipantResponse(
                            user_id="speaker-2",
                            user_name="Karthik M",
                            user_avatar="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80",
                            role="speaker",
                            seat_index=2,
                            joined_at=datetime.utcnow(),
                        ),
                    ],
                    created_at=datetime.utcnow(),
                )
        raise HTTPException(status_code=404, detail="Room not found")

    return PartyRoomResponse(
        id=r.id,
        title=r.title,
        host_id=r.host_id,
        host_name=r.host.display_name if r.host else "Host",
        host_avatar=r.host.images[0] if (r.host and r.host.images) else None,
        room_type=r.room_type,
        activity_type=r.activity_type,
        language=r.language,
        access_type=r.access_type,
        entry_fee_coins=r.entry_fee_coins,
        max_seats=r.max_seats,
        active_count=len(r.participants),
        status=r.status,
        participants=[
            PartyParticipantResponse(
                user_id=p.user_id,
                user_name=p.user.display_name if p.user else "User",
                user_avatar=p.user.images[0] if (p.user and p.user.images) else None,
                role=p.role,
                seat_index=p.seat_index,
                joined_at=p.joined_at,
            )
            for p in r.participants
        ],
        created_at=r.created_at,
    )

@router.post("/{room_id}/join")
async def join_room(
    room_id: str,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(PartyParticipant).where(
        PartyParticipant.room_id == room_id,
        PartyParticipant.user_id == current_user.id
    )
    res = await db.execute(q)
    existing = res.scalar_one_or_none()

    if not existing:
        part = PartyParticipant(
            room_id=room_id,
            user_id=current_user.id,
            role="listener",
            seat_index=None,
        )
        db.add(part)
        await db.commit()

    return {"status": "joined", "role": existing.role if existing else "listener"}

@router.post("/{room_id}/leave")
async def leave_room(
    room_id: str,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(PartyParticipant).where(
        PartyParticipant.room_id == room_id,
        PartyParticipant.user_id == current_user.id
    )
    res = await db.execute(q)
    existing = res.scalar_one_or_none()
    if existing:
        await db.delete(existing)
        await db.commit()

    return {"status": "left"}

@router.post("/{room_id}/close")
async def close_room(
    room_id: str,
    db: AsyncSession = Depends(get_db)
):
    q = select(PartyRoom).where(PartyRoom.id == room_id)
    res = await db.execute(q)
    room = res.scalar_one_or_none()
    if room:
        room.status = "closed"
        await db.commit()
    return {"status": "closed"}

@router.post("/{room_id}/request-speak")
async def request_speak(
    room_id: str,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(PartyParticipant).where(
        PartyParticipant.room_id == room_id,
        PartyParticipant.user_id == current_user.id
    )
    res = await db.execute(q)
    part = res.scalar_one_or_none()
    if part:
        part.role = "speaker"
        await db.commit()
    return {"status": "requested", "role": "speaker"}
