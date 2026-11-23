import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.database_models import Profile, Reel, ReelLike, ReelComment
from app.models.schemas import ReelResponse, ReelCreateRequest, ReelCommentResponse, ReelCommentRequest

router = APIRouter(prefix="/reels", tags=["reels"])

# Sample initial reels to ensure high quality content out of the box
DEFAULT_REELS = [
    {
        "id": "11111111-aaaa-bbbb-cccc-111111111111",
        "user_name": "Aditi Sharma",
        "user_avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80",
        "caption": "Friendship trips hit different! 💜",
        "likes_count": 3400,
        "comments_count": 286,
    },
    {
        "id": "22222222-aaaa-bbbb-cccc-222222222222",
        "user_name": "Rohit Verma",
        "user_avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80",
        "video_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "thumbnail_url": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80",
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
    }
]

@router.get("", response_model=List[ReelResponse])
async def list_reels(
    feed: str = Query("discover"),
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Reel).order_by(desc(Reel.created_at)).limit(30)
    result = await db.execute(query)
    db_reels = result.scalars().all()

    # Pre-fetch user likes
    user_likes_query = select(ReelLike.reel_id).where(ReelLike.user_id == current_user.id)
    user_likes_res = await db.execute(user_likes_query)
    liked_reel_ids = set(user_likes_res.scalars().all())

    items = []
    for r in db_reels:
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

    # If DB has fewer than default, include defaults
    if len(items) == 0:
        for d in DEFAULT_REELS:
            items.append(ReelResponse(
                id=d["id"],
                user_id=current_user.id,
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

@router.post("", response_model=ReelResponse, status_code=status.HTTP_201_CREATED)
async def create_reel(
    req: ReelCreateRequest,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
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

    return ReelResponse(
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
        # Return default reference comments matching mockups
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
