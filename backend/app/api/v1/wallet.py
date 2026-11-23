from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.database_models import Profile, CoinTransaction
from app.models.schemas import WalletBalanceResponse, CoinPackPurchaseRequest, CoinTransactionResponse

router = APIRouter(prefix="/wallet", tags=["wallet"])

PACKS = {
    "pack_40": {"coins": 40, "price_inr": 9.00, "label": "40 Coins"},
    "pack_100": {"coins": 100, "price_inr": 19.00, "label": "100 Coins"},
    "pack_275": {"coins": 275, "price_inr": 49.00, "label": "275 Coins"},
    "pack_600": {"coins": 600, "price_inr": 99.00, "label": "600 Coins"},
    "pack_1250": {"coins": 1250, "price_inr": 199.00, "label": "1,250 Coins"},
    "pack_3300": {"coins": 3300, "price_inr": 499.00, "label": "3,300 Coins (Best Value)"},
}

@router.get("/balance", response_model=WalletBalanceResponse)
async def get_wallet_balance(
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(CoinTransaction).where(CoinTransaction.user_id == current_user.id).order_by(desc(CoinTransaction.created_at)).limit(50)
    res = await db.execute(q)
    txs = res.scalars().all()

    tx_list = [
        CoinTransactionResponse(
            id=t.id,
            amount=t.amount,
            transaction_type=t.transaction_type,
            description=t.description,
            created_at=t.created_at,
        )
        for t in txs
    ]

    # If new user without history, seed standard initial bonus entry
    if not tx_list:
        tx_list = [
            CoinTransactionResponse(
                id="tx-init",
                amount=120,
                transaction_type="bonus",
                description="Welcome to FriendLoop bonus coins! 🎁",
                created_at=current_user.created_at or datetime.utcnow(),
            )
        ]

    return WalletBalanceResponse(
        coins=current_user.coins,
        transactions=tx_list,
    )

@router.post("/buy", response_model=WalletBalanceResponse)
async def purchase_coins(
    req: CoinPackPurchaseRequest,
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    pack = PACKS.get(req.pack_id)
    coins_to_add = pack["coins"] if pack else req.coins
    price = pack["price_inr"] if pack else req.price_inr

    current_user.coins += coins_to_add

    tx = CoinTransaction(
        user_id=current_user.id,
        amount=coins_to_add,
        transaction_type="purchase",
        description=f"Purchased {coins_to_add} coins for ₹{int(price)}",
        reference_id=f"pay_{int(datetime.utcnow().timestamp())}",
    )
    db.add(tx)
    await db.commit()
    await db.refresh(current_user)

    return await get_wallet_balance(current_user=current_user, db=db)

@router.get("/history", response_model=List[CoinTransactionResponse])
async def get_history(
    current_user: Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    q = select(CoinTransaction).where(CoinTransaction.user_id == current_user.id).order_by(desc(CoinTransaction.created_at))
    res = await db.execute(q)
    txs = res.scalars().all()

    return [
        CoinTransactionResponse(
            id=t.id,
            amount=t.amount,
            transaction_type=t.transaction_type,
            description=t.description,
            created_at=t.created_at,
        )
        for t in txs
    ]
