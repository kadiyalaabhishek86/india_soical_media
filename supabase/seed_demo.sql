-- seed_demo.sql
-- Seed data for local testing with 2 distinct adult participants across Indian states and staff accounts

-- User A: Aarav (Maharashtra, Hindi & English)
INSERT INTO profiles (
    id, phone, display_name, date_of_birth, state_or_union_territory, city, free_calls_remaining, rules_accepted
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '+919876543210',
    'Aarav Sharma',
    '1998-05-15',
    'Maharashtra',
    'Mumbai',
    5,
    TRUE
) ON CONFLICT (id) DO NOTHING;

INSERT INTO profile_languages (profile_id, language) VALUES
('11111111-1111-1111-1111-111111111111', 'Hindi'),
('11111111-1111-1111-1111-111111111111', 'English')
ON CONFLICT DO NOTHING;

-- User B: Priya (Karnataka, Hindi, English, Kannada)
INSERT INTO profiles (
    id, phone, display_name, date_of_birth, state_or_union_territory, city, free_calls_remaining, rules_accepted
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    '+919876543211',
    'Priya Patel',
    '2000-08-22',
    'Karnataka',
    'Bengaluru',
    5,
    TRUE
) ON CONFLICT (id) DO NOTHING;

INSERT INTO profile_languages (profile_id, language) VALUES
('22222222-2222-2222-2222-222222222222', 'Hindi'),
('22222222-2222-2222-2222-222222222222', 'English'),
('22222222-2222-2222-2222-222222222222', 'Kannada')
ON CONFLICT DO NOTHING;

-- Staff Users (Password: Admin@12345, hashed using argon2/sha256 in backend)
INSERT INTO staff_users (
    id, username, email, hashed_password, role, is_active
) VALUES (
    '99999999-9999-9999-9999-999999999999',
    'admin',
    'ops@aara.social',
    '$2b$12$e8kZ1Fp05vL41Zf9g/5dkuLz7K3nBw7U2l1gO7Jv2b1G9d2yB3x/2', -- demo hash for Admin@12345
    'admin',
    TRUE
) ON CONFLICT (id) DO NOTHING;
