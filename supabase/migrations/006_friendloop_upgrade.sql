-- 006_friendloop_upgrade.sql
-- FriendLoop Upgrades: Coins, Plus Subscriptions, Reels, Party Rooms, Gallery, and Financials

-- 1. Upgrade Profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS coins INTEGER NOT NULL DEFAULT 120;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_plus_subscriber BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS plus_valid_until TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS username VARCHAR(50);

-- 2. Reels
CREATE TABLE IF NOT EXISTS reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    likes_count INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reels_created_at ON reels(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reels_user_id ON reels(user_id);

CREATE TABLE IF NOT EXISTS reel_likes (
    reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (reel_id, user_id)
);

CREATE TABLE IF NOT EXISTS reel_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id UUID NOT NULL REFERENCES reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    likes_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reel_comments_reel_id ON reel_comments(reel_id);

-- 3. Profile Galleries (Photos & Videos with Plus lock)
CREATE TABLE IF NOT EXISTS galleries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL DEFAULT 'photo', -- 'photo' or 'video'
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    is_plus_only BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_galleries_user_id ON galleries(user_id);

-- 4. Live Party Rooms
CREATE TABLE IF NOT EXISTS party_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(120) NOT NULL,
    host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    room_type VARCHAR(20) NOT NULL DEFAULT 'voice', -- 'voice', 'video'
    activity_type VARCHAR(30) NOT NULL DEFAULT 'voice_lounge', -- 'ludo', 'carrom', 'truth_or_dare', 'voice_mimic', 'voice_lounge', 'video_stage'
    language VARCHAR(40) NOT NULL DEFAULT 'Hindi',
    access_type VARCHAR(20) NOT NULL DEFAULT 'public', -- 'public', 'invite_only', 'vip'
    entry_fee_coins INTEGER NOT NULL DEFAULT 0,
    max_seats INTEGER NOT NULL DEFAULT 8,
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'closed'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_party_rooms_status ON party_rooms(status);

CREATE TABLE IF NOT EXISTS party_participants (
    room_id UUID NOT NULL REFERENCES party_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'listener', -- 'host', 'speaker', 'listener'
    seat_index INTEGER,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

-- 5. Coin Transactions & Wallet
CREATE TABLE IF NOT EXISTS coin_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL, -- Positive for addition, negative for deduction
    transaction_type VARCHAR(40) NOT NULL, -- 'purchase', 'call_voice', 'call_video', 'room_entry', 'gift', 'bonus'
    description TEXT,
    reference_id VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_user_id ON coin_transactions(user_id);

-- 6. Plus Subscriptions (₹350/mo)
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    plan_id VARCHAR(40) NOT NULL DEFAULT 'plus_monthly',
    price_inr NUMERIC(10, 2) NOT NULL DEFAULT 350.00,
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'expired', 'cancelled'
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);

-- 7. Admin Financial Tracking (Gross - Refunds - Expenses - Taxes = Net Profit)
CREATE TABLE IF NOT EXISTS admin_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(60) NOT NULL, -- 'Server & Infra', 'Marketing', 'Payment Gateways', 'Staff & Ops', 'Other'
    amount_inr NUMERIC(12, 2) NOT NULL,
    description TEXT,
    recorded_by UUID REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_type VARCHAR(40) NOT NULL, -- 'GST 18%', 'TDS 1%', 'Corporate Tax'
    rate_percentage NUMERIC(5, 2) NOT NULL DEFAULT 18.00,
    amount_inr NUMERIC(12, 2) NOT NULL,
    period VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
