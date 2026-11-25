import os
import time
from contextlib import asynccontextmanager
from datetime import date, datetime
import httpx
from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.database import engine, Base, AsyncSessionLocal, get_db
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

# Mount static uploads directory for reels and media files
uploads_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "uploads"))
os.makedirs(os.path.join(uploads_dir, "reels"), exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")


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

@app.get("/readyz")
@app.get("/redyz")
@app.get("/api/v1/readyz")
@app.get("/api/v1/redyz")
async def readiness_check(request: Request, db: AsyncSession = Depends(get_db)):
    """
    Readiness probe verifying live connections to:
    1. PostgreSQL / SQLite Database via SQLAlchemy AsyncSession.
    2. Redis via Upstash REST or direct Redis TCP.
    """
    db_info = {}
    redis_info = {}

    # 1. Database Connection Check
    t0 = time.time()
    try:
        res = await db.execute(text("SELECT 1"))
        val = res.scalar()
        latency = round((time.time() - t0) * 1000, 2)
        db_info = {
            "status": "connected",
            "healthy": True,
            "dialect": engine.dialect.name,
            "latency_ms": latency,
            "test_query": val
        }
    except Exception as e:
        db_info = {
            "status": "disconnected",
            "healthy": False,
            "error": str(e)
        }

    # 2. Redis Connection Check
    t0 = time.time()
    upstash_url = settings.UPSTASH_REDIS_REST_URL or os.getenv("UPSTASH_REDIS_REST_URL")
    upstash_token = settings.UPSTASH_REDIS_REST_TOKEN or os.getenv("UPSTASH_REDIS_REST_TOKEN")
    redis_url = settings.REDIS_URL or os.getenv("REDIS_URL")

    # Priority A: Upstash Redis REST
    if upstash_url and upstash_token:
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                res = await client.get(
                    f"{upstash_url}/ping",
                    headers={"Authorization": f"Bearer {upstash_token}"}
                )
                latency = round((time.time() - t0) * 1000, 2)
                if res.status_code == 200:
                    redis_info = {
                        "status": "connected",
                        "healthy": True,
                        "provider": "upstash_rest",
                        "ping_response": res.json().get("result", "PONG"),
                        "latency_ms": latency
                    }
                else:
                    redis_info = {
                        "status": "error",
                        "healthy": False,
                        "provider": "upstash_rest",
                        "http_status": res.status_code,
                        "body": res.text[:200]
                    }
        except Exception as e:
            redis_info = {
                "status": "error",
                "healthy": False,
                "provider": "upstash_rest",
                "error": str(e)
            }
    # Priority B: Native Redis TCP
    elif redis_url:
        try:
            import redis.asyncio as aioredis
            r = aioredis.from_url(redis_url, socket_connect_timeout=2.0)
            pong = await r.ping()
            await r.close()
            latency = round((time.time() - t0) * 1000, 2)
            redis_info = {
                "status": "connected",
                "healthy": True,
                "provider": "redis_tcp",
                "ping_response": "PONG" if pong is True else str(pong),
                "latency_ms": latency
            }
        except Exception as e:
            redis_info = {
                "status": "error",
                "healthy": False,
                "provider": "redis_tcp",
                "error": str(e)
            }
    else:
        redis_info = {
            "status": "not_configured",
            "healthy": False,
            "message": "No REDIS_URL or UPSTASH_REDIS_REST_URL found in environment"
        }

    is_ready = db_info.get("healthy", False) and (redis_info.get("healthy", True) or redis_info.get("status") == "not_configured")
    status_code = 200 if is_ready else 503

    accept_header = request.headers.get("accept", "").lower()
    format_param = request.query_params.get("format", "").lower()

    if "text/html" in accept_header or format_param == "html":
        db_badge = "✅ Connected" if db_info.get("healthy") else "❌ Error"
        db_color = "#2E7D32" if db_info.get("healthy") else "#C62828"
        db_bg = "#E8F5E9" if db_info.get("healthy") else "#FFEBEE"

        r_healthy = redis_info.get("healthy", False)
        r_badge = "✅ Connected" if r_healthy else ("⚠️ Not Configured" if redis_info.get("status") == "not_configured" else "❌ Error")
        r_color = "#2E7D32" if r_healthy else ("#E65100" if redis_info.get("status") == "not_configured" else "#C62828")
        r_bg = "#E8F5E9" if r_healthy else ("#FFF3E0" if redis_info.get("status") == "not_configured" else "#FFEBEE")

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FriendLoop System Readiness (/redyz)</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #F4EBFC; margin: 0; padding: 24px; display: flex; justify-content: center; align-items: center; min-height: 100vh; color: #2D1B4E; }}
    .card {{ background: white; border-radius: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); padding: 32px; max-width: 520px; width: 100%; box-sizing: border-box; }}
    .header {{ display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1.5px solid #F0E5FA; }}
    .logo {{ font-size: 24px; font-weight: 800; color: #6D28D9; }}
    .status-badge {{ background: {"#E8F5E9" if is_ready else "#FFEBEE"}; color: {"#2E7D32" if is_ready else "#C62828"}; padding: 6px 14px; border-radius: 20px; font-weight: 700; font-size: 13px; }}
    .section {{ border: 1.5px solid #F0E5FA; border-radius: 14px; padding: 16px; margin-bottom: 14px; background: #FAF6FD; }}
    .sec-header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }}
    .sec-title {{ font-size: 16px; font-weight: 700; color: #2D1B4E; }}
    .pill {{ padding: 4px 10px; border-radius: 10px; font-size: 12px; font-weight: 700; }}
    .row {{ display: flex; justify-content: space-between; font-size: 13px; color: #555; margin: 4px 0; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }}
    .ts {{ font-size: 12px; color: #888; text-align: center; margin-top: 18px; }}
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="logo">♾️ FriendLoop</div>
      <div class="status-badge">{"SYSTEM READY" if is_ready else "SYSTEM UNHEALTHY"}</div>
    </div>

    <div class="section">
      <div class="sec-header">
        <div class="sec-title">🗄️ Database Connection</div>
        <div class="pill" style="background:{db_bg}; color:{db_color};">{db_badge}</div>
      </div>
      <div class="row"><span>Dialect / Engine:</span><b>{db_info.get("dialect", "unknown")}</b></div>
      <div class="row"><span>Latency:</span><b>{db_info.get("latency_ms", "N/A")} ms</b></div>
      <div class="row"><span>Query Check:</span><b>SELECT 1 = {db_info.get("test_query", "N/A")}</b></div>
    </div>

    <div class="section">
      <div class="sec-header">
        <div class="sec-title">⚡ Redis Connection</div>
        <div class="pill" style="background:{r_bg}; color:{r_color};">{r_badge}</div>
      </div>
      <div class="row"><span>Provider:</span><b>{redis_info.get("provider", "N/A")}</b></div>
      <div class="row"><span>Ping Response:</span><b>{redis_info.get("ping_response", "N/A")}</b></div>
      <div class="row"><span>Latency:</span><b>{redis_info.get("latency_ms", "N/A")} ms</b></div>
    </div>

    <div class="ts">Readiness endpoint: /redyz • {datetime.utcnow().isoformat()}Z</div>
  </div>
</body>
</html>"""
        return HTMLResponse(content=html_content, status_code=status_code)

    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if is_ready else "unhealthy",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "database": db_info,
            "redis": redis_info
        }
    )


@app.get("/child-safety", response_class=HTMLResponse)
async def child_safety_standards():
    """
    Public Child Safety Standards & CSAM Prevention Policy.
    Complies with Google Play's Child Safety Standards policy:
    https://support.google.com/googleplay/android-developer/answer/9878809
    """
    html = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Child Safety Standards & CSAM Policy | FriendLoop</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8F5FE; color: #2C0E37; margin: 0; padding: 24px; line-height: 1.6; }
    .container { max-width: 800px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 36px; box-shadow: 0 4px 20px rgba(110, 19, 216, 0.08); }
    h1 { color: #6E13D8; font-size: 28px; margin-top: 0; }
    h2 { color: #4A1270; font-size: 20px; border-bottom: 2px solid #EFE6FD; padding-bottom: 8px; margin-top: 28px; }
    .badge { display: inline-block; background: #E8F5E9; color: #2E7D32; font-weight: bold; padding: 4px 12px; border-radius: 20px; font-size: 13px; margin-bottom: 16px; }
    .contact-box { background: #F3E8FF; border: 1px solid #D8B4FE; border-radius: 12px; padding: 20px; margin: 24px 0; }
    .contact-box h3 { margin-top: 0; color: #6E13D8; }
    ul { padding-left: 20px; }
    li { margin-bottom: 8px; }
    a { color: #6E13D8; font-weight: 600; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .footer { text-align: center; color: #8E7A96; font-size: 13px; margin-top: 32px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">Google Play Child Safety Standards Compliance</div>
    <h1>FriendLoop Child Safety Standards & Zero-Tolerance Policy</h1>
    <p>Last Updated: November 2026</p>
    
    <p>FriendLoop is committed to creating a safe and secure environment for our community. We uphold an uncompromising, absolute <strong>zero-tolerance policy</strong> regarding Child Sexual Abuse Material (CSAM), Child Sexual Exploitation and Abuse (CSAE), grooming, and any form of endangerment or exploitation of minors.</p>

    <h2>1. Strict 18+ Age Restriction</h2>
    <p>FriendLoop is designed exclusively for adults. Minors (individuals under the age of 18) are strictly prohibited from creating accounts, accessing rooms, streaming reels, or using 1-on-1 audio/video calling. We enforce age verification upon signup and utilize Google Play Console's <strong>Restrict Minor Access</strong> configuration to prevent minors from downloading the application.</p>

    <h2>2. Zero Tolerance for CSAM / CSAE</h2>
    <p>Any account found uploading, transmitting, generating, soliciting, or facilitating child sexual abuse material or child exploitation will be:</p>
    <ul>
      <li><strong>Permanently banned</strong> and all associated device identifiers blacklisted immediately.</li>
      <li>Reported promptly to the <strong>National Center for Missing & Exploited Children (NCMEC)</strong> and local Indian cybercrime authorities (Cyber Crime Division / CERT-In) in compliance with applicable law.</li>
      <li>All relevant metadata, IP logs, and content preserved securely for law enforcement investigation.</li>
    </ul>

    <h2>3. In-App Reporting & Rapid Response Moderation</h2>
    <p>Users have immediate, 24/7 in-app tools to report profiles, chat messages, reels, and live rooms. Every report flagged with reasons of <em>Underage User</em> or <em>Inappropriate Content</em> triggers an expedited review by our safety operations team within 1 hour.</p>

    <div class="contact-box">
      <h3>Designated Child Safety Contact</h3>
      <p>In accordance with Google Play developer policies, FriendLoop has a designated Child Safety Officer responsible for reviewing safety escalations and cooperating with child protection authorities:</p>
      <p><strong>Designated Officer:</strong> Safety & Trust Operations Lead</p>
      <p><strong>Email:</strong> <a href="mailto:safety@friendloop.app">safety@friendloop.app</a></p>
      <p><strong>Escalation Office:</strong> FriendLoop India Safety Desk, Bengaluru, Karnataka, India</p>
      <p><strong>Emergency Inquiries:</strong> <a href="mailto:ops@aara.social">ops@aara.social</a></p>
    </div>

    <h2>4. Cooperation with Law Enforcement</h2>
    <p>We work collaboratively with global child safety organizations, law enforcement bodies, and telecommunications authorities to prevent the spread of abusive material and ensure swift legal prosecution of perpetrators.</p>

    <div class="footer">
      © 2026 FriendLoop Inc. • <a href="/delete-account">Account Deletion</a> • <a href="/readyz">System Status</a>
    </div>
  </div>
</body>
</html>"""
    return HTMLResponse(content=html)


@app.get("/delete-account", response_class=HTMLResponse)
@app.get("/account-deletion", response_class=HTMLResponse)
async def public_account_deletion_page():
    """
    Public Account and Data Deletion Request Page.
    Complies with Google Play's Account Deletion requirement:
    https://support.google.com/googleplay/android-developer/answer/13327111
    """
    html = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Delete Your FriendLoop Account & Data</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8F5FE; color: #2C0E37; margin: 0; padding: 24px; line-height: 1.6; }
    .container { max-width: 650px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 36px; box-shadow: 0 4px 20px rgba(110, 19, 216, 0.08); }
    h1 { color: #6E13D8; font-size: 26px; margin-top: 0; }
    .badge { display: inline-block; background: #FEE2E2; color: #B91C1C; font-weight: bold; padding: 4px 12px; border-radius: 20px; font-size: 13px; margin-bottom: 16px; }
    .notice { background: #FFFBEB; border-left: 4px solid #F59E0B; padding: 14px 16px; border-radius: 6px; margin: 20px 0; font-size: 14px; }
    .form-group { margin-bottom: 20px; }
    label { display: block; font-weight: 600; margin-bottom: 8px; color: #4A1270; }
    input, textarea, select { width: 100%; box-sizing: border-box; padding: 12px; border: 1.5px solid #E2D9F3; border-radius: 10px; font-size: 15px; outline: none; }
    input:focus, textarea:focus { border-color: #6E13D8; }
    button { width: 100%; background: #DC2626; color: white; border: none; padding: 14px; border-radius: 10px; font-size: 16px; font-weight: bold; cursor: pointer; transition: background 0.2s; }
    button:hover { background: #B91C1C; }
    .info-list { font-size: 14px; color: #554460; padding-left: 20px; }
    .info-list li { margin-bottom: 6px; }
    .success-msg { display: none; background: #ECFDF5; border: 1px solid #10B981; color: #065F46; padding: 16px; border-radius: 10px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">Google Play Account Deletion Mandate</div>
    <h1>Request FriendLoop Account & Data Deletion</h1>
    
    <p>Under Google Play's User Data policy and applicable data protection regulations, you can delete your FriendLoop account and all associated personal data directly without needing the mobile app installed.</p>

    <div class="notice">
      <strong>What will be deleted:</strong>
      <ul class="info-list" style="margin-top: 8px; margin-bottom: 0;">
        <li>Your profile information, name, date of birth, bio, and images.</li>
        <li>Your uploaded reels, comments, likes, and rooms history.</li>
        <li>Your 1-to-1 private chat messages and media attachments.</li>
        <li>Your coin balances, calling history, and contact identifiers.</li>
      </ul>
      <p style="margin: 8px 0 0 0; font-size: 12px; color: #78350F;">Note: Non-identifiable transaction receipts are retained strictly as required by Indian taxation and regulatory laws (7 years).</p>
    </div>

    <div id="successBox" class="success-msg">
      <h3>Account Deletion Request Received</h3>
      <p>Your request has been registered. If your phone number matches an active account, all personal data, media, and friendships will be wiped within 24 hours.</p>
    </div>

    <form id="deleteForm" onsubmit="submitDeletion(event)">
      <div class="form-group">
        <label for="phone">Registered Mobile Number (with country code):</label>
        <input type="tel" id="phone" placeholder="+91 98765 43210" required />
      </div>

      <div class="form-group">
        <label for="reason">Reason for leaving (Optional):</label>
        <select id="reason">
          <option value="privacy">Privacy concerns</option>
          <option value="no_longer_use">No longer use the app</option>
          <option value="found_friends">Met enough friends</option>
          <option value="other">Other</option>
        </select>
      </div>

      <div class="form-group">
        <label for="comments">Additional Details (Optional):</label>
        <textarea id="comments" rows="3" placeholder="Tell us if you experienced any specific issues..."></textarea>
      </div>

      <button type="submit" id="submitBtn">Request Account & Data Deletion</button>
    </form>

    <p style="text-align: center; font-size: 13px; color: #8E7A96; margin-top: 24px;">
      For questions or immediate assistance, contact our Data Protection Officer at <a href="mailto:privacy@friendloop.app" style="color: #6E13D8;">privacy@friendloop.app</a>.
    </p>
  </div>

  <script>
    async function submitDeletion(e) {
      e.preventDefault();
      const btn = document.getElementById('submitBtn');
      const phone = document.getElementById('phone').value.trim();
      const reason = document.getElementById('reason').value;
      const details = document.getElementById('comments').value.trim();

      btn.disabled = true;
      btn.innerText = 'Submitting Request...';

      try {
        const res = await fetch('/api/v1/public/delete-account-request', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone, reason, details })
        });
        document.getElementById('deleteForm').style.display = 'none';
        document.getElementById('successBox').style.display = 'block';
      } catch (err) {
        alert('Could not submit request. Please email privacy@friendloop.app');
        btn.disabled = false;
        btn.innerText = 'Request Account & Data Deletion';
      }
    }
  </script>
</body>
</html>"""
    return HTMLResponse(content=html)


@app.post("/api/v1/public/delete-account-request")
async def public_delete_account_request(request: Request, db: AsyncSession = Depends(get_db)):
    """
    Public web deletion request handler fulfilling Google Play's required deletion URL.
    """
    body = await request.json()
    phone = body.get("phone", "").strip()
    if not phone:
        return JSONResponse(status_code=400, content={"error": "Phone number is required."})

    # Normalize phone: remove spaces and hyphens
    clean_phone = phone.replace(" ", "").replace("-", "")
    if not clean_phone.startswith("+"):
        clean_phone = f"+91{clean_phone}" if len(clean_phone) == 10 else f"+{clean_phone}"

    stmt = select(Profile).where(Profile.phone == clean_phone)
    profile = (await db.execute(stmt)).scalar_one_or_none()
    if profile:
        profile.is_deleted = True
        profile.display_name = "Deleted User"
        profile.phone = f"+9100000{profile.phone[-5:]}_web_del_{int(datetime.utcnow().timestamp())}"
        profile.updated_at = datetime.utcnow()
        await db.commit()

    return {
        "success": True,
        "message": "Your account deletion request has been registered and processed."
    }
