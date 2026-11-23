-- 003_friends_and_chat.sql
-- Mutual Add Friend choices, Canonical Friendships, and Private Chat Messages

CREATE TABLE IF NOT EXISTS friend_choices (
    call_id UUID NOT NULL REFERENCES call_sessions(id) ON DELETE CASCADE,
    chooser_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (call_id, chooser_id, target_id)
);

CREATE INDEX IF NOT EXISTS idx_friend_choices_lookup ON friend_choices(call_id, target_id, chooser_id);

-- Friendships table with canonical ordering user_id1 < user_id2
CREATE TABLE IF NOT EXISTS friendships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id1 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user_id2 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, unfriended, blocked
    origin_call_id UUID REFERENCES call_sessions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT chk_canonical_friendship_order CHECK (user_id1 < user_id2),
    CONSTRAINT uq_friendship_pair UNIQUE (user_id1, user_id2)
);

CREATE INDEX IF NOT EXISTS idx_friendships_user1 ON friendships(user_id1, status);
CREATE INDEX IF NOT EXISTS idx_friendships_user2 ON friendships(user_id2, status);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    friendship_id UUID NOT NULL REFERENCES friendships(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'sent', -- sent, delivered, read
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_messages_friendship_created ON messages(friendship_id, created_at ASC);
