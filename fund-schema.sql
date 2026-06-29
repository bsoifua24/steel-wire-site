-- ═══════════════════════════════════════════════════════════════════════
-- Steel & Aire Soluciones — Fund Intelligence Schema
-- Run AFTER schema.sql, schema-v2.sql, and crm-schema.sql.
-- Idempotent: safe to re-run.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1. FUND SETTINGS (single row, shared across all team members) ────
CREATE TABLE IF NOT EXISTS fund_settings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fund_name        TEXT NOT NULL DEFAULT 'Steel & Aire Fund I',
  target_aum       BIGINT DEFAULT 0,        -- target total fund size in dollars
  committed        BIGINT DEFAULT 0,         -- total LP capital committed
  deployed         BIGINT DEFAULT 0,         -- capital deployed into deals
  returned         BIGINT DEFAULT 0,         -- capital returned to LPs
  target_irr       NUMERIC(5,2) DEFAULT 0,   -- target IRR percentage
  target_multiple  NUMERIC(5,2) DEFAULT 0,   -- target equity multiple (e.g. 1.8x)
  vintage_year     INTEGER,
  fund_strategy    TEXT,
  alert_email      TEXT,                     -- email address for stale-deal alerts
  last_stale_alert TIMESTAMPTZ,             -- prevents re-sending within 24h
  updated_at       TIMESTAMPTZ DEFAULT now(),
  updated_by       UUID REFERENCES profiles(id) ON DELETE SET NULL
);

ALTER TABLE fund_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage fund_settings" ON fund_settings;
CREATE POLICY "Admins manage fund_settings" ON fund_settings
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- LPs and borrowers can read the fund overview (no deal-specific data here)
DROP POLICY IF EXISTS "Authenticated users view fund_settings" ON fund_settings;
CREATE POLICY "Authenticated users view fund_settings" ON fund_settings
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Seed a default row (only if none exists)
INSERT INTO fund_settings (fund_name)
SELECT 'Steel & Aire Fund I'
WHERE NOT EXISTS (SELECT 1 FROM fund_settings);


-- ── 2. LP INVESTMENTS (one row per LP per fund) ──────────────────────
-- Tracks each limited partner's capital account.
CREATE TABLE IF NOT EXISTS lp_investments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  fund_name       TEXT DEFAULT 'Steel & Aire Fund I',
  commitment      BIGINT DEFAULT 0,          -- total dollar commitment
  called_capital  BIGINT DEFAULT 0,          -- how much has been called (drawn)
  distributions   BIGINT DEFAULT 0,          -- total distributions returned to this LP
  current_nav     BIGINT DEFAULT 0,          -- current estimated net asset value
  irr             NUMERIC(5,2),              -- LP-level projected or realized IRR
  equity_multiple NUMERIC(5,2),
  investment_date DATE,
  notes           TEXT,                      -- admin notes (not visible to LP)
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE lp_investments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage lp_investments" ON lp_investments;
CREATE POLICY "Admins manage lp_investments" ON lp_investments
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- Each LP can only see their own row
DROP POLICY IF EXISTS "LPs view own investment" ON lp_investments;
CREATE POLICY "LPs view own investment" ON lp_investments
  FOR SELECT USING (profile_id = auth.uid());


-- ── 3. CAPITAL CALL NOTICES ──────────────────────────────────────────
-- Tracks when capital is called from LPs and whether they've funded.
CREATE TABLE IF NOT EXISTS capital_calls (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lp_investment_id UUID REFERENCES lp_investments(id) ON DELETE CASCADE,
  call_date       DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date        DATE,
  amount          BIGINT NOT NULL,
  funded          BOOLEAN DEFAULT false,
  funded_date     DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE capital_calls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage capital_calls" ON capital_calls;
CREATE POLICY "Admins manage capital_calls" ON capital_calls
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "LPs view own capital_calls" ON capital_calls;
CREATE POLICY "LPs view own capital_calls" ON capital_calls
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM lp_investments
      WHERE lp_investments.id = capital_calls.lp_investment_id
        AND lp_investments.profile_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_capital_calls_lp ON capital_calls(lp_investment_id);


-- ── 4. DISTRIBUTIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS distributions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lp_investment_id UUID REFERENCES lp_investments(id) ON DELETE CASCADE,
  dist_date       DATE NOT NULL DEFAULT CURRENT_DATE,
  amount          BIGINT NOT NULL,
  dist_type       TEXT DEFAULT 'return_of_capital', -- return_of_capital | profit | preferred
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE distributions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage distributions" ON distributions;
CREATE POLICY "Admins manage distributions" ON distributions
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "LPs view own distributions" ON distributions;
CREATE POLICY "LPs view own distributions" ON distributions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM lp_investments
      WHERE lp_investments.id = distributions.lp_investment_id
        AND lp_investments.profile_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_distributions_lp ON distributions(lp_investment_id);


-- ── GRANT LP ROLE ─────────────────────────────────────────────────────
-- To make a user an LP, run:
--   UPDATE profiles SET role = 'lp' WHERE email = 'lp@example.com';
-- LPs can then sign in at lp-portal.html.

-- ── DONE ──────────────────────────────────────────────────────────────
-- After running this file:
-- 1. Go to fund-portal.html → ⚙ Settings → fill in your fund numbers → Save
--    The deployment bar will appear on the dashboard.
-- 2. To add an LP: create their account in the Deal Room (login.html),
--    then UPDATE profiles SET role='lp' WHERE email='...';
--    then INSERT a row into lp_investments for that profile_id.
-- 3. The LP can then sign in at lp-portal.html to view their account.

-- ── FUND SETTINGS SEED (run after initial schema) ─────────────────────
-- Adds IRR range support and sets the initial fund figures.
ALTER TABLE fund_settings ADD COLUMN IF NOT EXISTS target_irr_max NUMERIC(5,2) DEFAULT 0;

UPDATE fund_settings SET
  fund_name      = 'Steel & Aire Fund I',
  target_aum     = 10000000000,
  committed      = 50000000,
  deployed       = 10000000,
  returned       = 0,
  target_irr     = 15,
  target_irr_max = 25,
  updated_at     = now()
WHERE true;
