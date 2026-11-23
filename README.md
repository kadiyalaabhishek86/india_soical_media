# Aara — India Social Matching App (PRD v2.2)

> **Android-first social matching app for adults across India.**  
> Meet new people through 60-second random voice calls. When both choose **Add Friend**, continue the conversation privately through free text chat.

---

## 1. Architecture & Project Structure

The project is structured into four distinct, decoupled workspaces:

```
├── mobile/                 # Flutter & Dart Android App (Riverpod + go_router)
│   ├── lib/
│   │   ├── core/           # Luxury theme tokens, constants, network client, providers, router
│   │   ├── features/       # Screens 1 to 10 (Auth, Match, Call, Post-Call, Friends, Profile, Passes)
│   │   ├── shared/         # Reusable luxury UI widgets (AaraButton, AaraCard, AaraTimer, etc.)
│   │   ├── app.dart        # MaterialApp.router configuration
│   │   └── main.dart       # Entry point with ProviderScope
│   ├── test/               # Flutter widget & unit tests
│   └── pubspec.yaml
│
├── backend/                # FastAPI & Pydantic Business API
│   ├── app/
│   │   ├── api/v1/         # Auth, Match, Calls, Friendships, Messages, Moderation, Passes, Admin
│   │   ├── core/           # Config, Database (SQLite / Postgres), Security (JWT, MFA, PBKDF2)
│   │   ├── models/         # SQLAlchemy DB models & Pydantic schemas
│   │   ├── services/       # Matching service, Calling provider adapter, Play Billing service
│   │   └── main.py         # App factory, CORS, lifespan table init & demo seeder
│   ├── tests/              # Pytest test suite covering all PRD acceptance criteria
│   ├── requirements.txt
│   └── .env.example
│
├── supabase/               # Versioned PostgreSQL Migrations & RLS Policies
│   ├── migrations/
│   │   ├── 001_initial_schema.sql       # Profiles & Languages
│   │   ├── 002_matching_and_calls.sql   # Queues, Call sessions & 1-credit usage idempotency
│   │   ├── 003_friends_and_chat.sql     # Friend choices, Canonical Friendships, Messages
│   │   ├── 004_moderation_and_admin.sql # Blocks, Reports, Passes, Staff users & Audit logs
│   │   └── 005_rls_policies.sql         # Supabase Row Level Security default-deny policies
│   └── seed_demo.sql                    # Seed data for User A (Aarav), User B (Priya), Admin
│
└── admin/                  # React + TypeScript Operations & Moderation Console (Vite)
    ├── src/
    │   ├── api/            # Admin API client with MFA & Bearer auth
    │   ├── components/     # Top staff navbar, metrics, badges
    │   ├── pages/          # Reports queue, Calls/Usage analytics, Payments lookup, Audit log
    │   ├── App.tsx
    │   └── main.tsx
    ├── package.json
    └── vite.config.ts
```

---

## 2. Luxury Design System & Visual Identity

- **Backgrounds:** Near-black charcoal (`#0D0D10`, `#16161B`, `#1E1E26`).
- **Typography:** Warm ivory text (`#FAF8F5`, `#B5AFA7`), Georgia serif display styling for titles/wordmarks, readable sans-serif for chat and controls.
- **Accents:** Muted champagne gold (`#D4AF37`, `#E8CF82`, `#A68524`) with subtle 1px borders and soft pulse glows.
- **Call Timer:** Prominent 60-second circular countdown timer with animated arc and visual warning when under 10 seconds.
- **Accessibility & Devices:** Keyboard-safe layouts, high contrast ratios, screen reader semantics, comfortable touch targets (52px+).

---

## 3. Quickstart & Local Setup (Windows PowerShell)

### Prerequisites
- Python 3.11+
- Flutter 3.24+ & Dart 3.5+
- Node.js 18+ & npm

---

### Step 1: Start the FastAPI Backend

Open a PowerShell terminal:

```powershell
# Navigate to the backend directory
cd "c:\Users\win 10\Desktop\abhishek files\date app\app\backend"

# (Optional) Activate your Python virtual environment
# python -m venv venv; .\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run the backend with hot reload
$env:PYTHONPATH="."
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

- **API Root:** [http://127.0.0.1:8000/](http://127.0.0.1:8000/)
- **Interactive Swagger Docs:** [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **Healthcheck:** [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)

---

### Step 2: Start the React Admin Operations Console

Open a second PowerShell terminal:

```powershell
# Navigate to the admin directory
cd "c:\Users\win 10\Desktop\abhishek files\date app\app\admin"

# Install node dependencies
npm install

# Start Vite development server
npm run dev
```

- **Local Admin Console Link:** [http://localhost:3000](http://localhost:3000)
- **Staff Credentials:**
  - Username: `admin`
  - Password: `Admin@12345`
  - MFA TOTP Code: `123456`

---

### Step 3: Run the Flutter Mobile App

Open a third PowerShell terminal:

```powershell
# Navigate to the mobile directory
cd "c:\Users\win 10\Desktop\abhishek files\date app\app\mobile"

# Get packages
flutter pub get

# Run on connected Android device or emulator
flutter run -d android

# (Alternatively, run on Chrome or Windows desktop for immediate visual testing)
flutter run -d chrome
```

---

## 4. Testing with Two Demo Users (Aarav & Priya)

The app includes an **instant zero-SMS Demo Mode** with a top Persona Switcher banner:

1. **User A (Aarav Sharma):**
   - **Phone:** `+91 98765 43210`
   - **Location:** Maharashtra (Mumbai)
   - **Languages:** Hindi, English
   - **Allowance:** 5 Free Calls

2. **User B (Priya Patel):**
   - **Phone:** `+91 98765 43211`
   - **Location:** Karnataka (Bengaluru)
   - **Languages:** Hindi, English, Kannada
   - **Allowance:** 5 Free Calls

### How to execute the full 2-User E2E Flow:
1. **User A queues:** Open the app as Aarav (default) and tap **Start Voice Match**. Aarav enters the queue waiting for a Hindi/English speaker.
2. **User B joins:** Use the top bar switcher icon or open a second window with Priya (`+91 98765 43211`, OTP `123456`) and tap **Start Voice Match**.
3. **Instant Match Across States:** The backend atomically pairs Aarav and Priya on shared language **Hindi** across state boundaries (Maharashtra & Karnataka).
4. **60-Second Call:**
   - Both connect -> Server starts the **60-second shared timer**.
   - Exactly **1 credit** is deducted per participant. Duplicate or simultaneous callbacks consume zero extra credits.
   - In-call controls: Mute, Leave, Block, Report. Camera remains OFF by default.
5. **Post-Call Mutual Add Friend:**
   - User A chooses **Add Friend** -> Choice is recorded and kept strictly private.
   - User B chooses **Add Friend** -> System creates exactly **one canonical friendship** and unlocks private chat.
6. **Private Text Chat:**
   - Both friends can now send free messages in the **Friends** tab with sent/delivered/read status ticks.
7. **Blocking:**
   - If User A blocks User B, all active calls terminate, queue entries clear, and chat access is blocked immediately.
8. **Admin Review:**
   - In the Admin Console ([http://localhost:3000](http://localhost:3000)), staff can review reports, inspect case-specific context (reporter identity is never shown), suspend malicious accounts, and monitor media spending.

---

## 5. Acceptance Verification Checklist

All PRD acceptance checks were verified:

| Acceptance Test Case | Status | Verification Method |
|---|---|---|
| **Underage rejection (18+)** |  **PASSED** | DOB validator rejects users under 18; returns 422 |
| **Suspended user blocked** |  **PASSED** | Suspended accounts cannot join queue or send messages |
| **Cross-state matching on language** |  **PASSED** | User A (Maharashtra) and User B (Karnataka) match on shared language |
| **Failed/cancelled calls preserve credits** |  **PASSED** | Cancelling queue consumes zero credits; balance stays at 5 |
| **Connected call starts 60s timer** |  **PASSED** | Server shared_end_time issued only when both participants connect |
| **Idempotent credit deduction** |  **PASSED** | Simultaneous or duplicate callbacks charge at most 1 credit |
| **Reconnect preserves call deadline** |  **PASSED** | Reconnection retrieves original session and remaining seconds |
| **Unilateral Add Friend remains private** |  **PASSED** | Single-sided choice never exposed; mutual choice creates 1 friendship |
| **Private chat & blocking enforcement** |  **PASSED** | Active friends chat; blocking terminates calls & closes chat |
| **Staff authorization & report privacy** |  **PASSED** | Non-staff tokens rejected; reports hide reporter identity |
| **₹20 Pass verification & refunds** |  **PASSED** | Play Billing token verified idempotently; refund revokes pass |
| **Flutter Widget & Static Analysis** |  **PASSED** | `dart analyze mobile/lib` (0 errors), `flutter test` (all passed) |
| **Admin Console Build** |  **PASSED** | `tsc && vite build` bundled in 1.23s |

---

## 6. Live Integrations & Production Deployment

To switch from Demo Mode to Production:
1. Set `DEMO_MODE=false` and `ENVIRONMENT=production` in `backend/.env`.
2. Provide production secrets:
   - `SUPABASE_JWT_SECRET`: 32+ character signing key from your Supabase Dashboard.
   - `CALLING_PROVIDER`: Set to `livekit` or `agora` with your WebRTC API key and secret.
   - `ADMIN_SECRET_KEY`: High-entropy secret for staff tokens.
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Service account key for Google Play Developer API.
3. Apply SQL migrations in `supabase/migrations/` to your production Supabase database.
