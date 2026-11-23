from datetime import date, datetime, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.database_models import Profile, ProfileLanguage, Friendship, Message

DEMO_FRIENDS = [
    {
        "id": "33333333-3333-3333-3333-333333333333",
        "phone": "+919876543212",
        "name": "Anand Kumar",
        "dob": date(2000, 3, 10),
        "gender": "Male",
        "state": "Telangana",
        "city": "Hyderabad",
        "looking_for": "Software engineer who loves photography, South Indian food, and weekend road trips. Always happy to chat with people from all states!",
        "images": [
            "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=800&q=80"
        ],
        "languages": ["Telugu", "Hindi", "English"],
        "last_msg": "Anand Kumar joined Telegram",
        "unread": 0,
        "hours_ago": 0.5
    },
    {
        "id": "44444444-4444-4444-4444-444444444444",
        "phone": "+919876543213",
        "name": "Ananya Iyer",
        "dob": date(2001, 7, 19),
        "gender": "Female",
        "state": "Tamil Nadu",
        "city": "Chennai",
        "looking_for": "Classical dancer and UI designer. Interested in architecture, indie music, and meaningful discussions across India.",
        "images": [
            "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80"
        ],
        "languages": ["Tamil", "English", "Hindi"],
        "last_msg": "Do you listen to fusion jazz? Really enjoyed our 60s conversation! 🎶",
        "unread": 2,
        "hours_ago": 2
    },
    {
        "id": "55555555-5555-5555-5555-555555555555",
        "phone": "+919876543214",
        "name": "Kabir Verma",
        "dob": date(1999, 11, 4),
        "gender": "Male",
        "state": "Delhi",
        "city": "New Delhi",
        "looking_for": "Consultant from Delhi. Avid reader, fitness enthusiast, and passionate about startups and tech innovations.",
        "images": [
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1492562080023-ab3db95bfbbce?auto=format&fit=crop&w=800&q=80"
        ],
        "languages": ["Hindi", "English", "Punjabi"],
        "last_msg": "Let me know when you are free for another quick voice chat! ☕",
        "unread": 0,
        "hours_ago": 24
    },
    {
        "id": "66666666-6666-6666-6666-666666666666",
        "phone": "+919876543215",
        "name": "Rohan Deshmukh",
        "dob": date(1997, 9, 28),
        "gender": "Male",
        "state": "Maharashtra",
        "city": "Pune",
        "looking_for": "Automotive engineer based in Pune. Love trekking the Sahyadri mountains and discussing good cinema.",
        "images": [
            "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80"
        ],
        "languages": ["Marathi", "Hindi", "English"],
        "last_msg": "Thanks for the book recommendations, really liked the first chapter!",
        "unread": 0,
        "hours_ago": 72
    },
    {
        "id": "77777777-7777-7777-7777-777777777777",
        "phone": "+919876543216",
        "name": "Sneha Reddy",
        "dob": date(2001, 2, 14),
        "gender": "Female",
        "state": "Karnataka",
        "city": "Bengaluru",
        "looking_for": "Product designer in Indiranagar. Great coffee, cozy cafes, and thoughtful late night talks.",
        "images": [
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80"
        ],
        "languages": ["Telugu", "Kannada", "English"],
        "last_msg": "Filter coffee in Bengaluru is undefeated 😉 Let me know if you visit!",
        "unread": 1,
        "hours_ago": 5
    }
]

async def seed_demo_friends_and_chats(session: AsyncSession):
    """
    Seeds rich demo friends, active friendships, and recent messages for Aarav & Priya
    so the Telegram-style Friends list UI is active and populated out of the box.
    """
    aarav_id = "11111111-1111-1111-1111-111111111111"
    priya_id = "22222222-2222-2222-2222-222222222222"

    for f in DEMO_FRIENDS:
        p = await session.get(Profile, f["id"])
        if not p:
            p = Profile(
                id=f["id"],
                phone=f["phone"],
                display_name=f["name"],
                date_of_birth=f["dob"],
                gender=f["gender"],
                state_or_union_territory=f["state"],
                city=f["city"],
                looking_for=f["looking_for"],
                images=f["images"],
                free_calls_remaining=5,
                rules_accepted=True
            )
            session.add(p)
            await session.flush()
            for lang in f["languages"]:
                session.add(ProfileLanguage(profile_id=p.id, language=lang))

    # Friendship: Aarav & Priya
    ap_fs = (await session.execute(
        select(Friendship).where(
            Friendship.user_id1 == aarav_id,
            Friendship.user_id2 == priya_id
        )
    )).scalar_one_or_none()

    now = datetime.now()
    if not ap_fs:
        ap_fs = Friendship(
            user_id1=aarav_id,
            user_id2=priya_id,
            status="active",
            updated_at=now - timedelta(minutes=15)
        )
        session.add(ap_fs)
        await session.flush()
        msg1 = Message(
            friendship_id=ap_fs.id,
            sender_id=priya_id,
            content="Hey Aarav! Loved our 60-second voice match! Let's keep chatting here ✨",
            status="unread",
            created_at=now - timedelta(minutes=15)
        )
        session.add(msg1)

    # Friendships with Aarav
    for f in DEMO_FRIENDS:
        f_id = f["id"]
        u1, u2 = (aarav_id, f_id) if aarav_id < f_id else (f_id, aarav_id)
        fs = (await session.execute(
            select(Friendship).where(Friendship.user_id1 == u1, Friendship.user_id2 == u2)
        )).scalar_one_or_none()

        if not fs:
            msg_time = now - timedelta(hours=f["hours_ago"])
            fs = Friendship(
                user_id1=u1,
                user_id2=u2,
                status="active",
                updated_at=msg_time
            )
            session.add(fs)
            await session.flush()
            m = Message(
                friendship_id=fs.id,
                sender_id=f_id,
                content=f["last_msg"],
                status="unread" if f["unread"] > 0 else "read",
                created_at=msg_time
            )
            session.add(m)

    # Friendships with Priya
    for fid in ["33333333-3333-3333-3333-333333333333", "77777777-7777-7777-7777-777777777777"]:
        u1, u2 = (priya_id, fid) if priya_id < fid else (fid, priya_id)
        p_fs = (await session.execute(
            select(Friendship).where(Friendship.user_id1 == u1, Friendship.user_id2 == u2)
        )).scalar_one_or_none()

        if not p_fs:
            p_fs = Friendship(
                user_id1=u1,
                user_id2=u2,
                status="active",
                updated_at=now - timedelta(hours=3)
            )
            session.add(p_fs)
            await session.flush()
            session.add(Message(
                friendship_id=p_fs.id,
                sender_id=fid,
                content="Hi Priya! Great connecting on Aara!",
                status="read",
                created_at=now - timedelta(hours=3)
            ))

    await session.commit()
