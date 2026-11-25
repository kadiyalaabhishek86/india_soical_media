from datetime import datetime, timedelta
from typing import List, Optional
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.database_models import Profile, Subscription, GalleryItem
from app.models.schemas import PlusSubscriptionResponse, GalleryItemResponse, GalleryUploadRequest

router = APIRouter(tags=["plus_and_gallery"])

# Sample gallery items for demo profiles
SAMPLE_GALLERY = {
    "photos": [
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1511884642898-4c92249e20b6?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=800&q=80",
    ],
    "videos": [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    ]
}

@router.get("/plus/status", response_model=PlusSubscriptionResponse)
async def get_plus_status(
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    is_active = False
    if current_user.is_plus_subscriber and current_user.plus_valid_until:
        if current_user.plus_valid_until > datetime.utcnow():
            is_active = True
        else:
            current_user.is_plus_subscriber = False
            await db.commit()

    return PlusSubscriptionResponse(
        is_plus_subscriber=is_active,
        plus_valid_until=current_user.plus_valid_until,
        price_inr=350.00,
        plan_name="FriendLoop Plus Monthly",
    )

class PlusSubscribeRequest(BaseModel):
    payment_method: Optional[str] = "google_play" # "google_play" or "alternative_razorpay"

@router.post("/plus/subscribe", response_model=PlusSubscriptionResponse)
async def subscribe_plus(
    req: Optional[PlusSubscribeRequest] = None,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    method = req.payment_method if req and req.payment_method else "google_play"
    now = datetime.utcnow()
    valid_until = now + timedelta(days=30)
    current_user.is_plus_subscriber = True
    current_user.plus_valid_until = valid_until

    sub = Subscription(
        user_id=current_user.id,
        plan_id=f"plus_monthly_{method}",
        price_inr=350.00,
        status="active",
        starts_at=now,
        expires_at=valid_until,
    )
    db.add(sub)
    await db.commit()
    await db.refresh(current_user)

    return PlusSubscriptionResponse(
        is_plus_subscriber=True,
        plus_valid_until=valid_until,
        price_inr=350.00,
        plan_name="FriendLoop Plus Monthly",
    )

@router.get("/users/{user_id}/gallery", response_model=List[GalleryItemResponse])
async def get_user_gallery(
    user_id: str,
    media_type: str = "photo",
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Check if visitor is the owner or has Plus subscription
    is_owner = (current_user.id == user_id)
    has_plus = is_owner or (current_user.is_plus_subscriber and (current_user.plus_valid_until and current_user.plus_valid_until > datetime.utcnow()))

    q = select(GalleryItem).where(
        GalleryItem.user_id == user_id,
        GalleryItem.media_type == media_type
    ).order_by(desc(GalleryItem.created_at))
    res = await db.execute(q)
    items = res.scalars().all()

    response_items = []
    if items:
        for it in items:
            response_items.append(GalleryItemResponse(
                id=it.id,
                user_id=it.user_id,
                media_type=it.media_type,
                media_url=it.media_url if (has_plus or not it.is_plus_only) else "",
                thumbnail_url=it.thumbnail_url if (has_plus or not it.is_plus_only) else "",
                caption=it.caption,
                is_plus_only=it.is_plus_only,
                created_at=it.created_at,
            ))
    else:
        # Default sample items matching mockups
        urls = SAMPLE_GALLERY["photos"] if media_type == "photo" else SAMPLE_GALLERY["videos"]
        for idx, u in enumerate(urls):
            response_items.append(GalleryItemResponse(
                id=f"sample-{media_type}-{idx}",
                user_id=user_id,
                media_type=media_type,
                media_url=u if has_plus else "",
                thumbnail_url=u if has_plus else "",
                caption="Trekking in the Himalayas ⛰️" if idx == 0 else f"Moments {idx+1}",
                is_plus_only=True,
                created_at=datetime.utcnow(),
            ))

    return response_items

@router.post("/gallery/upload", response_model=GalleryItemResponse, status_code=status.HTTP_201_CREATED)
async def upload_gallery_item(
    req: GalleryUploadRequest,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    item = GalleryItem(
        user_id=current_user.id,
        media_type=req.media_type,
        media_url=req.media_url,
        thumbnail_url=req.thumbnail_url,
        caption=req.caption,
        is_plus_only=req.is_plus_only,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)

    return GalleryItemResponse(
        id=item.id,
        user_id=item.user_id,
        media_type=item.media_type,
        media_url=item.media_url,
        thumbnail_url=item.thumbnail_url,
        caption=item.caption,
        is_plus_only=item.is_plus_only,
        created_at=item.created_at,
    )
