-- ============================================================
-- KRBECCSL 100 Years — Memento Distribution System
-- Supabase Schema  (paste in SQL Editor → Run)
-- ============================================================

-- 1. MEMBERS
CREATE TABLE IF NOT EXISTS members (
  id          BIGSERIAL PRIMARY KEY,
  member_id   TEXT UNIQUE NOT NULL,
  member_name TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TOKENS  (pre-printed physical token registry)
CREATE TABLE IF NOT EXISTS tokens (
  token_id     TEXT PRIMARY KEY,          -- e.g. S0001, G0042
  token_type   TEXT NOT NULL CHECK (token_type IN ('sweet', 'gift')),
  member_id    BIGINT REFERENCES members(id) ON DELETE SET NULL,
  issued       BOOLEAN NOT NULL DEFAULT FALSE,
  delivered    BOOLEAN NOT NULL DEFAULT FALSE,
  issued_at    TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tokens_member_type
  ON tokens(member_id, token_type)
  WHERE member_id IS NOT NULL;

-- 3. LOGS
CREATE TABLE IF NOT EXISTS logs (
  id            BIGSERIAL PRIMARY KEY,
  member_id     BIGINT REFERENCES members(id) ON DELETE SET NULL,
  token_id      TEXT,
  action        TEXT,
  operator_name TEXT,
  timestamp     TIMESTAMPTZ DEFAULT NOW()
);

-- 4. APP USERS  (self-contained user system with roles)
--    Passwords are stored as SHA-256 hashes.
--    Roles: admin | issue | sweet | gift
CREATE TABLE IF NOT EXISTS app_users (
  id            BIGSERIAL PRIMARY KEY,
  display_name  TEXT NOT NULL,
  username      TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,           -- SHA-256 hex string
  role          TEXT NOT NULL CHECK (role IN ('admin','issue','sweet','gift','viewer')),
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_members_member_id ON members(member_id);
CREATE INDEX IF NOT EXISTS idx_tokens_member_id  ON tokens(member_id);
CREATE INDEX IF NOT EXISTS idx_tokens_type       ON tokens(token_type);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp    ON logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_username ON app_users(username);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE members   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tokens    ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs      ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Allow anon key to do everything (the app authenticates at the
-- application layer via app_users, not via Supabase Auth)
CREATE POLICY "allow_all_members"   ON members   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_tokens"    ON tokens    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_logs"      ON logs      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_app_users" ON app_users FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- SEED: DEFAULT USERS
-- Change passwords after first login!
--
-- Role permissions:
--   admin  → all screens (Issue, Sweet, Gift, Dashboard, Members, Load Tokens, Users)
--   issue  → Issue Tokens screen only
--   sweet  → Sweet Counter screen only
--   gift   → Gift Counter screen only
-- ============================================================
INSERT INTO app_users (display_name, username, password_hash, role, active) VALUES

  -- ADMIN (1)
  -- Password: Admin@123
  ('Admin',           'admin',      'e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7', 'admin', true),

  -- TOKEN ISSUE OPERATORS (3)
  -- Password: Issue@123
  ('Issue Operator 1','issue.op1',  '24937fd78eb531a3a53788ab94588aa0a591c2427841370f2c10a1d9dcb1372a', 'issue', true),
  ('Issue Operator 2','issue.op2',  '24937fd78eb531a3a53788ab94588aa0a591c2427841370f2c10a1d9dcb1372a', 'issue', true),
  ('Issue Operator 3','issue.op3',  '24937fd78eb531a3a53788ab94588aa0a591c2427841370f2c10a1d9dcb1372a', 'issue', true),

  -- GIFT COUNTER OPERATORS (2)
  -- Password: Gift@123
  ('Gift Counter 1',  'gift.op1',   'badfc6dd17b49a687cf1caca78e7ea71a0db85235ca0788415e53c9830be6cc0', 'gift',  true),
  ('Gift Counter 2',  'gift.op2',   'badfc6dd17b49a687cf1caca78e7ea71a0db85235ca0788415e53c9830be6cc0', 'gift',  true),

  -- SWEET COUNTER OPERATORS (2)
  -- Password: Sweet@123
  ('Sweet Counter 1', 'sweet.op1',  '0b0f472b9ee07822a8039f6a577c5f468fae7f19508d32883a7da82390d5f43f', 'sweet', true),
  ('Sweet Counter 2', 'sweet.op2',  '0b0f472b9ee07822a8039f6a577c5f468fae7f19508d32883a7da82390d5f43f', 'sweet', true),

  -- DASHBOARD VIEWER (1)
  -- Password: View@123
  ('Dashboard Viewer','viewer',     '8520137ee15ce060552d9cb8dac80816712d7a8c046cc38d527807ad2699556d', 'viewer', true)

ON CONFLICT (username) DO NOTHING;

-- ============================================================
-- DEFAULT LOGIN CREDENTIALS  (change after setup!)
-- ============================================================
-- Username        Password      Role
-- ─────────────────────────────────────────────────────────
-- admin           Admin@123     Admin (all access)
-- issue.op1       Issue@123     Issue Tokens only
-- issue.op2       Issue@123     Issue Tokens only
-- issue.op3       Issue@123     Issue Tokens only
-- gift.op1        Gift@123      Gift Counter only
-- gift.op2        Gift@123      Gift Counter only
-- sweet.op1       Sweet@123     Sweet Counter only
-- sweet.op2       Sweet@123     Sweet Counter only
-- viewer          View@123      Dashboard only
-- ============================================================

-- ============================================================
-- LOAD PRE-PRINTED TOKENS (run after setup, adjust range)
-- ============================================================
-- Sweet tokens S0001–S0500:
-- INSERT INTO tokens (token_id, token_type, issued, delivered)
-- SELECT 'S' || LPAD(i::text, 4, '0'), 'sweet', false, false
-- FROM generate_series(1, 500) AS i
-- ON CONFLICT (token_id) DO NOTHING;
--
-- Gift tokens G0001–G0500:
-- INSERT INTO tokens (token_id, token_type, issued, delivered)
-- SELECT 'G' || LPAD(i::text, 4, '0'), 'gift', false, false
-- FROM generate_series(1, 500) AS i
-- ON CONFLICT (token_id) DO NOTHING;
