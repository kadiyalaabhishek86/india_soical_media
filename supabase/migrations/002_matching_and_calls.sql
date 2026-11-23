-- 002_matching_and_calls.sql
-- Queues, Call Sessions, Participants, and Idempotent Usage Accounting

CREATE TABLE IF NOT EXISTS queue_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
    call_mode VARCHAR(10) NOT NULL DEFAULT 'voice',
    allow_any_language BOOLEAN DEFAULT FALSE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'waiting', -- waiting, matched, cancelled
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_queue_entries_status_mode ON queue_entries(status, call_mode, created_at);

CREATE TABLE IF NOT EXISTS call_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id VARCHAR(100) NOT NULL UNIQUE,
    call_mode VARCHAR(10) NOT NULL DEFAULT 'voice',
    status VARCHAR(20) NOT NULL DEFAULT 'created', -- created, connecting, connected, completed, cancelled, terminated
    started_at TIMESTAMPTZ,
    shared_end_time TIMESTAMPTZ,
    duration_seconds INT DEFAULT 60 NOT NULL,
    terminated_reason VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_call_sessions_status ON call_sessions(status);
CREATE INDEX IF NOT EXISTS idx_call_sessions_room ON call_sessions(room_id);

CREATE TABLE IF NOT EXISTS call_participants (
    call_id UUID NOT NULL REFERENCES call_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'participant' NOT NULL,
    token TEXT,
    connected_at TIMESTAMPTZ,
    disconnected_at TIMESTAMPTZ,
    PRIMARY KEY (call_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_call_participants_user ON call_participants(user_id);

-- Call usage accounting: strictly 1 credit record per (user_id, call_id).
-- Ensures simultaneous or duplicate provider webhook calls never double-charge.
CREATE TABLE IF NOT EXISTS call_usage_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    call_id UUID NOT NULL REFERENCES call_sessions(id) ON DELETE CASCADE,
    credit_type VARCHAR(20) NOT NULL DEFAULT 'free', -- free, paid_pass
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT uq_call_usage_user_call UNIQUE (user_id, call_id)
);

CREATE INDEX IF NOT EXISTS idx_call_usage_user ON call_usage_records(user_id);
