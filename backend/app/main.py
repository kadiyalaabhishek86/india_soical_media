import os
from contextlib import asynccontextmanager
from datetime import date
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from app.core.config import settings
from app.core.database import engine, Base, AsyncSessionLocal
from app.models.database_models import Profile, ProfileLanguage, StaffUser
from app.core.demo_seed import seed_demo_friends_and_chats
from app.core.security import hash_password
from app.api.v1 import auth, match, calls, friendships, messages, moderation, passes, admin, reels, rooms, wallet, plus

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Production security validation
    settings.validate_production_readiness()

    # Create tables if not already created
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        for col, col_type, default_val in [
            ("coins", "INTEGER", "120"),
            ("is_plus_subscriber", "BOOLEAN", "FALSE"),
            ("plus_valid_until", "TIMESTAMPTZ", "NULL"),
            ("username", "VARCHAR(50)", "NULL"),
        ]:
            try:
                await conn.execute(text(f"ALTER TABLE profiles ADD COLUMN IF NOT EXISTS {col} {col_type} DEFAULT {default_val};"))
            except Exception:
                try:
                    await conn.execute(text(f"ALTER TABLE profiles ADD COLUMN {col} {col_type} DEFAULT {default_val};"))
                except Exception:
                    pass

    # Seed demo users if in DEMO_MODE
    if settings.DEMO_MODE:
        async with AsyncSessionLocal() as session:
            # Seed Aarav
            aarav = await session.get(Profile, "11111111-1111-1111-1111-111111111111")
            if not aarav:
                aarav = Profile(
                    id="11111111-1111-1111-1111-111111111111",
                    phone="+919876543210",
                    display_name="Aarav Sharma",
                    date_of_birth=date(1998, 5, 15),
                    state_or_union_territory="Maharashtra",
                    city="Mumbai",
                    free_calls_remaining=5,
                    rules_accepted=True
                )
                session.add(aarav)
                session.add(ProfileLanguage(profile_id=aarav.id, language="Hindi"))
                session.add(ProfileLanguage(profile_id=aarav.id, language="English"))

            # Seed Priya
            priya = await session.get(Profile, "22222222-2222-2222-2222-222222222222")
            if not priya:
                priya = Profile(
                    id="22222222-2222-2222-2222-222222222222",
                    phone="+919876543211",
                    display_name="Priya Patel",
                    date_of_birth=date(2000, 8, 22),
                    state_or_union_territory="Karnataka",
                    city="Bengaluru",
                    free_calls_remaining=5,
                    rules_accepted=True
                )
                session.add(priya)
                session.add(ProfileLanguage(profile_id=priya.id, language="Hindi"))
                session.add(ProfileLanguage(profile_id=priya.id, language="English"))
                session.add(ProfileLanguage(profile_id=priya.id, language="Kannada"))

            # Seed Admin staff
            admin_user = await session.get(StaffUser, "99999999-9999-9999-9999-999999999999")
            if not admin_user:
                admin_user = StaffUser(
                    id="99999999-9999-9999-9999-999999999999",
                    username=settings.ADMIN_DEFAULT_USERNAME,
                    email="ops@aara.social",
                    hashed_password=hash_password(settings.ADMIN_DEFAULT_PASSWORD),
                    role="admin",
                    is_active=True
                )
                session.add(admin_user)

            await session.commit()
            await seed_demo_friends_and_chats(session)
    yield

app = FastAPI(
    title=f"{settings.APP_NAME} API",
    description="India Social Matching App Backend - 60-Second Random Voice Matching & Pilot Operations",
    version="2.2.0",
    lifespan=lifespan
)

# CORS configuration for mobile emulator, physical devices, and admin console
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API v1 Routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(match.router, prefix="/api/v1")
app.include_router(calls.router, prefix="/api/v1")
app.include_router(friendships.router, prefix="/api/v1")
app.include_router(messages.router, prefix="/api/v1")
app.include_router(moderation.router, prefix="/api/v1")
app.include_router(passes.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(reels.router, prefix="/api/v1")
app.include_router(rooms.router, prefix="/api/v1")
app.include_router(wallet.router, prefix="/api/v1")
app.include_router(plus.router, prefix="/api/v1")

# Mount built static Admin Console on /admin directly (no separate server needed)
admin_dist_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "admin", "dist"))
if os.path.isdir(admin_dist_path):
    app.mount("/admin", StaticFiles(directory=admin_dist_path, html=True), name="admin")


@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": "2.2.0",
        "demo_mode": settings.DEMO_MODE,
        "environment": settings.ENVIRONMENT,
        "calling_provider": settings.CALLING_PROVIDER,
        "feature_flags": {
            "private_voice": settings.FEATURE_PRIVATE_VOICE,
            "video": settings.FEATURE_VIDEO,
            "paid_pass": settings.FEATURE_PAID_PASS,
        },
        "docs_url": "/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": date.today().isoformat()}
