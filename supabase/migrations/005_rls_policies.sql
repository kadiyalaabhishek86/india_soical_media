-- 005_rls_policies.sql
-- Supabase Row Level Security (RLS) Policies
-- Default-deny direct access to private sensitive data (phone, birth date, reports reporter_id)

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_usage_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_audit_logs ENABLE ROW LEVEL SECURITY;

-- 1. Profiles: Users can view their own profile with full details.
-- Others can only see public info (display_name, state_or_union_territory, city) via secure views or backend API.
CREATE POLICY "Users can read own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 2. Profile Languages: Users manage their own languages
CREATE POLICY "Users can view languages"
    ON profile_languages FOR SELECT
    USING (TRUE);

CREATE POLICY "Users can manage own languages"
    ON profile_languages FOR ALL
    USING (auth.uid() = profile_id);

-- 3. Messages: Only participants in an active friendship can read and insert messages
CREATE POLICY "Friendship participants can view messages"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM friendships f
            WHERE f.id = messages.friendship_id
              AND f.status = 'active'
              AND (f.user_id1 = auth.uid() OR f.user_id2 = auth.uid())
        )
    );

CREATE POLICY "Friendship participants can send messages"
    ON messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM friendships f
            WHERE f.id = messages.friendship_id
              AND f.status = 'active'
              AND (f.user_id1 = auth.uid() OR f.user_id2 = auth.uid())
        )
    );

-- 4. Reports: Anyone can create a report, but reports can never be read by normal users
CREATE POLICY "Users can create reports"
    ON reports FOR INSERT
    WITH CHECK (reporter_id = auth.uid());

-- 5. Friend choices: Chooser can only view their own choice. Reciprocal choice cannot be seen!
CREATE POLICY "Users can view own friend choice"
    ON friend_choices FOR SELECT
    USING (chooser_id = auth.uid());

CREATE POLICY "Users can insert own friend choice"
    ON friend_choices FOR INSERT
    WITH CHECK (chooser_id = auth.uid());
