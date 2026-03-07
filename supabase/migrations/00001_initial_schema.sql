-- =============================================================================
-- Pledge App: Initial Database Schema
-- =============================================================================
-- Tables: user_profiles, habits, habit_logs, deposits, transactions, friendships
-- Views: leaderboard
-- RLS: Enabled on all tables with per-user policies
-- Triggers: updated_at auto-update on user_profiles and habits
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. user_profiles
-- ---------------------------------------------------------------------------
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    privy_user_id TEXT UNIQUE NOT NULL,
    phone TEXT,
    wallet_address TEXT,
    username TEXT UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    risk_profile TEXT NOT NULL DEFAULT 'moderate',
    vault_balance DECIMAL(18,2) DEFAULT 0,
    investment_pool_balance DECIMAL(18,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 2. habits
-- ---------------------------------------------------------------------------
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    type TEXT NOT NULL,
    stake_amount DECIMAL(18,2) DEFAULT 10,
    schedule INT[] DEFAULT ARRAY[1,2,3,4,5,6,7],
    target_value DECIMAL DEFAULT 0,
    verification_type TEXT DEFAULT 'auto',
    is_active BOOLEAN DEFAULT true,
    is_paused BOOLEAN DEFAULT false,
    current_streak INT DEFAULT 0,
    best_streak INT DEFAULT 0,
    success_rate DECIMAL DEFAULT 0,
    location_latitude DECIMAL,
    location_longitude DECIMAL,
    location_radius DECIMAL,
    location_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 3. habit_logs
-- ---------------------------------------------------------------------------
CREATE TABLE habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    verified_at TIMESTAMPTZ,
    penalty_amount DECIMAL(18,2) DEFAULT 0,
    invested_amount DECIMAL(18,2) DEFAULT 0,
    fee_amount DECIMAL(18,2) DEFAULT 0,
    verification_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (habit_id, log_date)
);

-- ---------------------------------------------------------------------------
-- 4. deposits
-- ---------------------------------------------------------------------------
CREATE TABLE deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id),
    session_id TEXT,
    amount DECIMAL(18,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    wallet_address TEXT NOT NULL,
    coinbase_response JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    confirmed_at TIMESTAMPTZ
);

-- ---------------------------------------------------------------------------
-- 5. transactions
-- ---------------------------------------------------------------------------
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id),
    type TEXT NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    description TEXT,
    related_habit_id UUID REFERENCES habits(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 6. friendships
-- ---------------------------------------------------------------------------
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id),
    friend_id UUID NOT NULL REFERENCES user_profiles(id),
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_habit_logs_user_date ON habit_logs(user_id, log_date);
CREATE INDEX idx_habit_logs_habit_date ON habit_logs(habit_id, log_date);
CREATE INDEX idx_transactions_user_created ON transactions(user_id, created_at DESC);
CREATE INDEX idx_deposits_user_status ON deposits(user_id, status);
CREATE INDEX idx_user_profiles_username ON user_profiles(username);
CREATE INDEX idx_friendships_user_status ON friendships(user_id, status);
CREATE INDEX idx_friendships_friend_status ON friendships(friend_id, status);

-- =============================================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_habits_updated_at
    BEFORE UPDATE ON habits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- user_profiles policies
-- ---------------------------------------------------------------------------

-- Users can read their own full profile
CREATE POLICY "Users can read own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = id);

-- Any authenticated user can read public profile fields (for leaderboard/social)
CREATE POLICY "Authenticated users can read public profiles"
    ON user_profiles FOR SELECT
    USING (auth.role() = 'authenticated');

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- habits policies
-- ---------------------------------------------------------------------------

CREATE POLICY "Users can read own habits"
    ON habits FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own habits"
    ON habits FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own habits"
    ON habits FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own habits"
    ON habits FOR DELETE
    USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- habit_logs policies
-- ---------------------------------------------------------------------------

CREATE POLICY "Users can read own habit logs"
    ON habit_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own habit logs"
    ON habit_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own habit logs"
    ON habit_logs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- deposits policies
-- ---------------------------------------------------------------------------

CREATE POLICY "Users can read own deposits"
    ON deposits FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own deposits"
    ON deposits FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- transactions policies
-- ---------------------------------------------------------------------------

CREATE POLICY "Users can read own transactions"
    ON transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
    ON transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- friendships policies
-- ---------------------------------------------------------------------------

-- Both parties can see friendships
CREATE POLICY "Users can read own friendships"
    ON friendships FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Only the requester can create a friendship
CREATE POLICY "Users can insert own friendships"
    ON friendships FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Only the friend (recipient) can accept/reject
CREATE POLICY "Friends can update friendship status"
    ON friendships FOR UPDATE
    USING (auth.uid() = friend_id)
    WITH CHECK (auth.uid() = friend_id);

-- Either party can delete (unfriend/cancel)
CREATE POLICY "Either party can delete friendship"
    ON friendships FOR DELETE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- =============================================================================
-- LEADERBOARD VIEW
-- =============================================================================

CREATE VIEW leaderboard AS
SELECT
    up.id,
    up.username,
    up.display_name,
    up.avatar_url,
    COALESCE(MAX(h.current_streak), 0) AS best_active_streak,
    COUNT(DISTINCT h.id) AS active_habits,
    COALESCE(SUM(CASE WHEN hl.status = 'verified' THEN 1 ELSE 0 END), 0) AS total_verified,
    COALESCE(SUM(hl.invested_amount), 0) AS total_invested
FROM user_profiles up
LEFT JOIN habits h ON h.user_id = up.id AND h.is_active = true
LEFT JOIN habit_logs hl ON hl.user_id = up.id AND hl.log_date >= CURRENT_DATE - INTERVAL '30 days'
WHERE up.username IS NOT NULL
GROUP BY up.id;
