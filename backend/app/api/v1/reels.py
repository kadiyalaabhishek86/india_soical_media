import os
import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.core.database import get_db
from app.core.security import get_current_user, get_optional_current_user
from app.models.database_models import Profile, Reel, ReelLike, ReelComment
from app.models.schemas import ReelResponse, ReelCreateRequest, ReelCommentResponse, ReelCommentRequest

router = APIRouter(prefix="/reels", tags=["reels"])

# Session memory buffer for uploaded reels to guarantee they always persist at top on reload
_IN_MEMORY_REELS: List[dict] = []

# Sample initial reels to ensure high quality content out of the box
DEFAULT_REELS = [
    {
        "id": "11111111-aaaa-bbbb-cccc-111111111111",
        "user_name": "Priya Patel",
        "user_avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80",
        "caption": "Friendship trips hit different! 💜",
        "likes_count": 3401,
        "comments_count": 287,
    },
    {
        "id": "22222222-aaaa-bbbb-cccc-222222222222",
        "user_name": "Rohit Verma",
        "user_avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80",
        "caption": "Weekend trek with friends! ⛰️",
        "likes_count": 1820,
        "comments_count": 94,
    },
    {
        "id": "33333333-aaaa-bbbb-cccc-333333333333",
        "user_name": "Neha Jain",
        "user_avatar": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80",
        "caption": "Chai and long conversations in Bengaluru ☕✨",
        "likes_count": 2950,
        "comments_count": 142,
    },
    {
        "id": "44444444-aaaa-bbbb-cccc-444444444444",
        "user_name": "Vikram Rao",
        "user_avatar": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80",
        "caption": "Road trip across the Western Ghats 🚗💨",
        "likes_count": 4120,
        "comments_count": 310,
    },
    {
        "id": "55555555-aaaa-bbbb-cccc-555555555555",
        "user_name": "Ananya Reddy",
        "user_avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80",
        "caption": "Exploring hidden cafes in Hyderabad ☕🥐",
        "likes_count": 3890,
        "comments_count": 245,
    },
    {
        "id": "66666666-aaaa-bbbb-cccc-666666666666",
        "user_name": "Arjun Mehta",
        "user_avatar": "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=800&q=80",
        "caption": "Next trip, count me in! Sunset vibes 🌅",
        "likes_count": 2150,
        "comments_count": 88,
    }
]

@router.get("", response_model=List[ReelResponse])
async def list_reels(
    feed: str = Query("discover"),
    current_user: Optional[Profile] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Reel).order_by(desc(Reel.created_at)).limit(30)
    result = await db.execute(query)
    db_reels = result.scalars().all()

    # Pre-fetch user likes if logged in
    liked_reel_ids = set()
    if current_user:
        user_likes_query = select(ReelLike.reel_id).where(ReelLike.user_id == current_user.id)
        user_likes_res = await db.execute(user_likes_query)
        liked_reel_ids = set(user_likes_res.scalars().all())

    items = []
    seen_ids = set()

    # 1. In-memory buffer reels (newly created in this session, always at index 0)
    for mem in _IN_MEMORY_REELS:
        if mem["id"] not in seen_ids:
            seen_ids.add(mem["id"])
            items.append(ReelResponse(
                id=mem["id"],
                user_id=mem.get("user_id", current_user.id if current_user else "default-user"),
                user_name=mem.get("user_name", "You"),
                user_avatar=mem.get("user_avatar"),
                video_url=mem["video_url"],
                thumbnail_url=mem.get("thumbnail_url"),
                caption=mem.get("caption"),
                likes_count=mem.get("likes_count", 0),
                comments_count=mem.get("comments_count", 0),
                is_liked=mem["id"] in liked_reel_ids,
                created_at=mem.get("created_at", datetime.utcnow()),
            ))

    # 2. Database saved reels
    for r in db_reels:
        if r.id not in seen_ids:
            seen_ids.add(r.id)
            items.append(ReelResponse(
                id=r.id,
                user_id=r.user_id,
                user_name=r.user.display_name if r.user else "FriendLoop User",
                user_avatar=r.user.images[0] if (r.user and r.user.images) else None,
                video_url=r.video_url,
                thumbnail_url=r.thumbnail_url,
                caption=r.caption,
                likes_count=r.likes_count,
                comments_count=r.comments_count,
                is_liked=r.id in liked_reel_ids,
                created_at=r.created_at,
            ))

    # 3. Default seed reels
    current_uid = current_user.id if current_user else "default-user"
    for d in DEFAULT_REELS:
        if d["id"] not in seen_ids:
            seen_ids.add(d["id"])
            items.append(ReelResponse(
                id=d["id"],
                user_id=current_uid,
                user_name=d["user_name"],
                user_avatar=d["user_avatar"],
                video_url=d["video_url"],
                thumbnail_url=d["thumbnail_url"],
                caption=d["caption"],
                likes_count=d["likes_count"],
                comments_count=d["comments_count"],
                is_liked=d["id"] in liked_reel_ids,
                created_at=datetime.utcnow(),
            ))

    return items

@router.post("/upload-media")
async def upload_reel_media(
    file: UploadFile = File(...),
    current_user: Optional[Profile] = Depends(get_optional_current_user),
):
    target_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "uploads", "reels"))
    os.makedirs(target_dir, exist_ok=True)

    file_id = str(uuid.uuid4())
    original_name = file.filename or "video.mp4"
    ext = os.path.splitext(original_name)[1]
    if not ext:
        ext = ".mp4" if "video" in (file.content_type or "") else ".jpg"

    saved_filename = f"{file_id}{ext}"
    file_path = os.path.join(target_dir, saved_filename)

    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)

    return {
        "url": f"/uploads/reels/{saved_filename}",
        "filename": original_name,
        "size": len(content),
    }

@router.post("", response_model=ReelResponse, status_code=status.HTTP_201_CREATED)
async def create_reel(
    req: ReelCreateRequest,
    current_user: Optional[Profile] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
):
    if not current_user:
        stmt = select(Profile).limit(1)
        res = await db.execute(stmt)
        current_user = res.scalar_one_or_none()
        if not current_user:
            current_user = Profile(
                id=str(uuid.uuid4()),
                phone="+919876543210",
                display_name="You",
                coins=100,
                rules_accepted=True,
            )
            db.add(current_user)
            await db.commit()
            await db.refresh(current_user)

    new_reel = Reel(
        user_id=current_user.id,
        video_url=req.video_url,
        thumbnail_url=req.thumbnail_url,
        caption=req.caption,
        likes_count=0,
        comments_count=0,
    )
    db.add(new_reel)
    await db.commit()
    await db.refresh(new_reel)

    resp = ReelResponse(
        id=new_reel.id,
        user_id=current_user.id,
        user_name=current_user.display_name,
        user_avatar=current_user.images[0] if current_user.images else None,
        video_url=new_reel.video_url,
        thumbnail_url=new_reel.thumbnail_url,
        caption=new_reel.caption,
        likes_count=0,
        comments_count=0,
        is_liked=False,
        created_at=new_reel.created_at,
    )

    # Cache in memory buffer so GET /reels always returns it at top immediately
    _IN_MEMORY_REELS.insert(0, resp.model_dump())

    return resp

@router.post("/{reel_id}/like")
async def toggle_like(
    reel_id: str,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    like_q = select(ReelLike).where(ReelLike.reel_id == reel_id, ReelLike.user_id == current_user.id)
    like_res = await db.execute(like_q)
    existing_like = like_res.scalar_one_or_none()

    reel_q = select(Reel).where(Reel.id == reel_id)
    reel_res = await db.execute(reel_q)
    reel = reel_res.scalar_one_or_none()

    if not reel:
        for d in DEFAULT_REELS:
            if d["id"] == reel_id:
                reel = Reel(
                    id=d["id"],
                    user_id=current_user.id,
                    video_url=d["video_url"],
                    thumbnail_url=d["thumbnail_url"],
                    caption=d["caption"],
                    likes_count=d["likes_count"],
                    comments_count=d["comments_count"],
                )
                db.add(reel)
                await db.flush()
                break

    if existing_like:
        await db.delete(existing_like)
        if reel and reel.likes_count > 0:
            reel.likes_count -= 1
        await db.commit()
        return {"liked": False, "likes_count": reel.likes_count if reel else 0}
    else:
        new_like = ReelLike(reel_id=reel_id, user_id=current_user.id)
        db.add(new_like)
        if reel:
            reel.likes_count += 1
        await db.commit()
        return {"liked": True, "likes_count": reel.likes_count if reel else 1}

@router.get("/{reel_id}/comments", response_model=List[ReelCommentResponse])
async def list_comments(
    reel_id: str,
    db: AsyncSession = Depends(get_db)
):
    q = select(ReelComment).where(ReelComment.reel_id == reel_id).order_by(desc(ReelComment.created_at))
    res = await db.execute(q)
    comments = res.scalars().all()

    if not comments:
        # Return default reference comments only for seed reference reels; newly created reels start empty
        seed_ids = {d["id"] for d in DEFAULT_REELS}
        if reel_id in seed_ids:
            return [
                ReelCommentResponse(
                    id="c1",
                    reel_id=reel_id,
                    user_id="user1",
                    user_name="Rohit Verma",
                    user_avatar="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80",
                    comment_text="So fun! Love this group! 💜",
                    likes_count=94,
                    created_at=datetime.utcnow(),
                ),
                ReelCommentResponse(
                    id="c2",
                    reel_id=reel_id,
                    user_id="user2",
                    user_name="Neha Jain",
                    user_avatar="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80",
                    comment_text="Friendship goals! 😍",
                    likes_count=56,
                    created_at=datetime.utcnow(),
                ),
                ReelCommentResponse(
                    id="c3",
                    reel_id=reel_id,
                    user_id="user3",
                    user_name="Arjun Mehta",
                    user_avatar="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80",
                    comment_text="Next trip, count me in! 🙌",
                    likes_count=41,
                    created_at=datetime.utcnow(),
                )
            ]
        return []

    return [
        ReelCommentResponse(
            id=c.id,
            reel_id=c.reel_id,
            user_id=c.user_id,
            user_name=c.user.display_name if c.user else "User",
            user_avatar=c.user.images[0] if (c.user and c.user.images) else None,
            comment_text=c.comment_text,
            likes_count=c.likes_count,
            created_at=c.created_at,
        )
        for c in comments
    ]

@router.post("/{reel_id}/comments", response_model=ReelCommentResponse, status_code=status.HTTP_201_CREATED)
async def add_comment(
    reel_id: str,
    req: ReelCommentRequest,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    reel_q = select(Reel).where(Reel.id == reel_id)
    reel_res = await db.execute(reel_q)
    reel = reel_res.scalar_one_or_none()

    if not reel:
        for d in DEFAULT_REELS:
            if d["id"] == reel_id:
                reel = Reel(
                    id=d["id"],
                    user_id=current_user.id,
                    video_url=d["video_url"],
                    thumbnail_url=d["thumbnail_url"],
                    caption=d["caption"],
                    likes_count=d["likes_count"],
                    comments_count=d["comments_count"],
                )
                db.add(reel)
                await db.flush()
                break

    comment = ReelComment(
        reel_id=reel_id,
        user_id=current_user.id,
        comment_text=req.comment_text.strip(),
        likes_count=0,
    )
    db.add(comment)

    if reel:
        reel.comments_count += 1

    await db.commit()
    await db.refresh(comment)

    return ReelCommentResponse(
        id=comment.id,
        reel_id=comment.reel_id,
        user_id=current_user.id,
        user_name=current_user.display_name,
        user_avatar=current_user.images[0] if current_user.images else None,
        comment_text=comment.comment_text,
        likes_count=0,
        created_at=comment.created_at,
    )
