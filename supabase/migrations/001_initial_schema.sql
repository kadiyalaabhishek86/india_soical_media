-- 001_initial_schema.sql
-- India Social Matching App (Aara) - Core Profiles & Languages Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    display_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    state_or_union_territory VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    is_adult BOOLEAN DEFAULT TRUE NOT NULL,
    is_suspended BOOLEAN DEFAULT FALSE NOT NULL,
    suspension_reason TEXT,
    free_calls_remaining INT DEFAULT 5 NOT NULL CHECK (free_calls_remaining >= 0),
    rules_accepted BOOLEAN DEFAULT FALSE NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for phone lookups and active profile checks
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_adult_suspended ON profiles(is_adult, is_suspended, is_deleted);

-- Preferred conversation languages per profile
CREATE TABLE IF NOT EXISTS profile_languages (
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    language VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (profile_id, language)
);

CREATE INDEX IF NOT EXISTS idx_profile_languages_lang ON profile_languages(language);
