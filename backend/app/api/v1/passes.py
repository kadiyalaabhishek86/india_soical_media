from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.core.config import settings
from app.models.schemas import (
    VerifyPurchaseRequest, PassResponse, RazorpayOrderCreateRequest,
    RazorpayOrderResponse, RazorpayVerifyPaymentRequest
)
from app.services.billing_service import (
    verify_and_grant_pass, get_active_pass_for_user,
    create_razorpay_order, verify_razorpay_payment
)

router = APIRouter(prefix="/passes", tags=["passes"])

@router.get("/status", response_model=Optional[PassResponse])
async def get_pass_status(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    pass_obj = await get_active_pass_for_user(db, user_id)
    if not pass_obj:
        return None

    now = datetime.now(timezone.utc)
    exp = pass_obj.expires_at
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    remaining_minutes = max(0, int(round((exp - now).total_seconds() / 60)))

    return PassResponse(
        id=pass_obj.id,
        status=pass_obj.status,
        starts_at=pass_obj.starts_at,
        expires_at=pass_obj.expires_at,
        is_active=pass_obj.status == "active" and exp > now,
        remaining_minutes=remaining_minutes
    )

@router.post("/razorpay/create-order", response_model=RazorpayOrderResponse)
async def razorpay_create_order(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Creates a ₹20 (2000 paise) Razorpay order for the 20-minute random match pass.
    """
    order = create_razorpay_order(amount=2000, currency="INR")
    return RazorpayOrderResponse(
        order_id=order["order_id"],
        amount=order["amount"],
        currency=order["currency"],
        key_id=order["key_id"],
        description=order["description"]
    )

@router.post("/razorpay/verify-payment", response_model=PassResponse)
async def razorpay_verify_payment(
    request: RazorpayVerifyPaymentRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Verifies the Razorpay payment signature and activates the 20-minute pass.
    """
    success, msg, pass_obj = await verify_razorpay_payment(
        session=db,
        user_id=user_id,
        razorpay_order_id=request.razorpay_order_id,
        razorpay_payment_id=request.razorpay_payment_id,
        razorpay_signature=request.razorpay_signature
    )

    if not success or not pass_obj:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=msg)

    now = datetime.now(timezone.utc)
    exp = pass_obj.expires_at
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    remaining_minutes = max(0, int(round((exp - now).total_seconds() / 60)))

    return PassResponse(
        id=pass_obj.id,
        status=pass_obj.status,
        starts_at=pass_obj.starts_at,
        expires_at=pass_obj.expires_at,
        is_active=True,
        remaining_minutes=remaining_minutes
    )

@router.post("/verify", response_model=PassResponse)
async def verify_purchase(
    request: VerifyPurchaseRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    if not settings.FEATURE_PAID_PASS and not settings.DEMO_MODE:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Paid pass feature is currently disabled in Pilot 1."
        )

    success, msg, pass_obj = await verify_and_grant_pass(
        session=db,
        user_id=user_id,
        purchase_token=request.purchase_token,
        order_id=request.order_id
    )

    if not success or not pass_obj:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=msg)

    now = datetime.now(timezone.utc)
    exp = pass_obj.expires_at
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    remaining_minutes = max(0, int(round((exp - now).total_seconds() / 60)))

    return PassResponse(
        id=pass_obj.id,
        status=pass_obj.status,
        starts_at=pass_obj.starts_at,
        expires_at=pass_obj.expires_at,
        is_active=True,
        remaining_minutes=remaining_minutes
    )
