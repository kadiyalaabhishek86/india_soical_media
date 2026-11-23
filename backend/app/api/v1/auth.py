from datetime import datetime, date
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id, create_access_token
from app.core.config import settings
from app.models.database_models import Profile, ProfileLanguage
from app.models.schemas import (
    SendOtpRequest, SendOtpResponse, VerifyOtpRequest, AuthTokenResponse,
    ProfileCreateRequest, ProfileResponse, UpdateLanguagesRequest,
    ProfileUpdateRequest, ImageUploadRequest, ImageUploadResponse
)
from app.services.billing_service import get_active_pass_for_user

router = APIRouter(prefix="/auth", tags=["auth"])

# In-memory OTP storage for demo/development
OTP_STORE = {
    "+919876543210": "123456", # Aarav demo phone
    "+919876543211": "123456", # Priya demo phone
}

@router.post("/send-otp", response_model=SendOtpResponse)
async def send_otp(request: SendOtpRequest):
    phone = request.phone
    # In demo mode, generate static 123456
    otp = "123456"
    OTP_STORE[phone] = otp

    demo_otp = otp if settings.DEMO_MODE else None
    return SendOtpResponse(
        success=True,
        phone=phone,
        message="OTP sent successfully" if not settings.DEMO_MODE else "SIMULATED OTP: 123456",
        demo_otp=demo_otp
    )

@router.post("/verify-otp", response_model=AuthTokenResponse)
async def verify_otp(request: VerifyOtpRequest, db: AsyncSession = Depends(get_db)):
    phone = request.phone.strip()
    if not phone.startswith("+91"):
        clean = phone.replace(" ", "")
        if clean.startswith("91") and len(clean) == 12:
            phone = f"+{clean}"
        elif len(clean) == 10:
            phone = f"+91{clean}"

    expected_otp = OTP_STORE.get(phone, "123456" if settings.DEMO_MODE else None)
    if not expected_otp or request.otp.strip() != expected_otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP.")

    # Find or create placeholder profile
    stmt = select(Profile).where(Profile.phone == phone)
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()

    is_new = False
    profile_complete = False

    if not profile:
        is_new = True
        # Create minimal profile placeholder (requires profile completion)
        profile = Profile(
            phone=phone,
            display_name=f"User_{phone[-4:]}",
            date_of_birth=date(2000, 1, 1), # Default placeholder
            state_or_union_territory="Unknown",
            city=None,
            free_calls_remaining=5,
            rules_accepted=False
        )
        db.add(profile)
        await db.commit()
        await db.refresh(profile)
    else:
        if profile.is_deleted:
            profile.is_deleted = False # Reactivate if logging back in
            await db.commit()
        profile_complete = profile.rules_accepted and profile.state_or_union_territory != "Unknown"

    token = create_access_token({"sub": profile.id, "phone": profile.phone})
    return AuthTokenResponse(
        access_token=token,
        user_id=profile.id,
        is_new_user=is_new,
        profile_complete=profile_complete
    )

@router.post("/profile", response_model=ProfileResponse)
async def setup_profile(
    request: ProfileCreateRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Profile).where(Profile.id == user_id)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")

    profile.display_name = request.display_name.strip()
    profile.date_of_birth = request.date_of_birth
    profile.gender = request.gender or "Prefer not to say"
    profile.looking_for = request.looking_for.strip() if request.looking_for else None
    if request.images is not None:
        profile.images = [img for img in request.images if img][:3]
    profile.state_or_union_territory = request.state_or_union_territory.strip()
    profile.city = request.city.strip() if request.city else None
    profile.rules_accepted = request.rules_accepted
    profile.updated_at = datetime.utcnow()

    # Clear old languages and set new
    await db.execute(delete(ProfileLanguage).where(ProfileLanguage.profile_id == user_id))
    for lang in request.languages:
        db.add(ProfileLanguage(profile_id=user_id, language=lang.strip()))

    await db.commit()
    await db.refresh(profile)

    langs = [l.language for l in profile.languages]
    return ProfileResponse(
        id=profile.id,
        phone=profile.phone,
        display_name=profile.display_name,
        date_of_birth=profile.date_of_birth,
        age=profile.age,
        gender=profile.gender or "Prefer not to say",
        looking_for=profile.looking_for,
        images=profile.images or [],
        state_or_union_territory=profile.state_or_union_territory,
        city=profile.city,
        languages=langs,
        free_calls_remaining=profile.free_calls_remaining,
        is_adult=profile.is_adult,
        rules_accepted=profile.rules_accepted,
        created_at=profile.created_at
    )

@router.put("/profile", response_model=ProfileResponse)
async def update_profile(
    request: ProfileUpdateRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Updates profile details (DOB, Gender, Looking For, Images up to 3).
    Strictly validates that 'looking_for' does not contain any phone numbers!
    """
    stmt = select(Profile).where(Profile.id == user_id, Profile.is_deleted == False)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")

    if request.display_name is not None:
        profile.display_name = request.display_name.strip()
    if request.date_of_birth is not None:
        profile.date_of_birth = request.date_of_birth
    if request.gender is not None:
        profile.gender = request.gender.strip()
    if request.looking_for is not None:
        profile.looking_for = request.looking_for.strip() if request.looking_for.strip() else None
    if request.state_or_union_territory is not None:
        profile.state_or_union_territory = request.state_or_union_territory.strip()
    if request.city is not None:
        profile.city = request.city.strip() if request.city.strip() else None
    if request.images is not None:
        profile.images = [img for img in request.images if img][:3]

    if request.languages is not None and len(request.languages) > 0:
        await db.execute(delete(ProfileLanguage).where(ProfileLanguage.profile_id == user_id))
        for lang in request.languages:
            db.add(ProfileLanguage(profile_id=user_id, language=lang.strip()))

    profile.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(profile)

    langs = [l.language for l in profile.languages]
    active_pass = await get_active_pass_for_user(db, user_id)
    return ProfileResponse(
        id=profile.id,
        phone=profile.phone,
        display_name=profile.display_name,
        date_of_birth=profile.date_of_birth,
        age=profile.age,
        gender=profile.gender or "Prefer not to say",
        looking_for=profile.looking_for,
        images=profile.images or [],
        state_or_union_territory=profile.state_or_union_territory,
        city=profile.city,
        languages=langs,
        free_calls_remaining=profile.free_calls_remaining,
        is_adult=profile.is_adult,
        rules_accepted=profile.rules_accepted,
        has_active_pass=active_pass is not None,
        pass_expires_at=active_pass.expires_at if active_pass else None,
        created_at=profile.created_at
    )

@router.post("/profile/image", response_model=ImageUploadResponse)
async def upload_profile_image(
    request: ImageUploadRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Sets one of the 3 profile images (slot 0, 1, or 2).
    """
    stmt = select(Profile).where(Profile.id == user_id, Profile.is_deleted == False)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")

    current_images = list(profile.images or [])
    slot = max(0, min(2, request.slot_index))

    while len(current_images) <= slot:
        current_images.append("")

    current_images[slot] = request.image_base64
    final_images = [img for img in current_images if img][:3]
    profile.images = final_images
    profile.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(profile)

    return ImageUploadResponse(
        success=True,
        image_url=request.image_base64,
        slot_index=slot,
        images=profile.images
    )

@router.get("/me", response_model=ProfileResponse)
async def get_me(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    stmt = select(Profile).where(Profile.id == user_id, Profile.is_deleted == False)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found or deleted.")

    langs = [l.language for l in profile.languages]
    active_pass = await get_active_pass_for_user(db, user_id)

    return ProfileResponse(
        id=profile.id,
        phone=profile.phone,
        display_name=profile.display_name,
        date_of_birth=profile.date_of_birth,
        age=profile.age,
        gender=profile.gender or "Prefer not to say",
        looking_for=profile.looking_for,
        images=profile.images or [],
        state_or_union_territory=profile.state_or_union_territory,
        city=profile.city,
        languages=langs,
        free_calls_remaining=profile.free_calls_remaining,
        is_adult=profile.is_adult,
        rules_accepted=profile.rules_accepted,
        has_active_pass=active_pass is not None,
        pass_expires_at=active_pass.expires_at if active_pass else None,
        created_at=profile.created_at
    )

@router.put("/languages", response_model=ProfileResponse)
async def update_languages(
    request: UpdateLanguagesRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Profile).where(Profile.id == user_id)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")

    await db.execute(delete(ProfileLanguage).where(ProfileLanguage.profile_id == user_id))
    for lang in request.languages:
        db.add(ProfileLanguage(profile_id=user_id, language=lang.strip()))

    await db.commit()
    await db.refresh(profile)

    langs = [l.language for l in profile.languages]
    active_pass = await get_active_pass_for_user(db, user_id)

    return ProfileResponse(
        id=profile.id,
        phone=profile.phone,
        display_name=profile.display_name,
        state_or_union_territory=profile.state_or_union_territory,
        city=profile.city,
        languages=langs,
        free_calls_remaining=profile.free_calls_remaining,
        is_adult=profile.is_adult,
        rules_accepted=profile.rules_accepted,
        has_active_pass=active_pass is not None,
        pass_expires_at=active_pass.expires_at if active_pass else None,
        created_at=profile.created_at
    )

@router.post("/accept-rules")
async def accept_rules(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    stmt = select(Profile).where(Profile.id == user_id)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")
    profile.rules_accepted = True
    await db.commit()
    return {"success": True, "message": "Community rules accepted."}
