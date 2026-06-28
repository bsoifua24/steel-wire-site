-- ═══════════════════════════════════════════════════════════════════════════
-- Steel & Aire Soluciones — Schema v2 Migration
-- Safe to run on top of v1 (idempotent).
-- Paste this ENTIRE file into the Supabase SQL Editor and click Run.
-- Then paste seed-requirements.sql in a second tab.
-- ═══════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 1 — Postgres enums
-- Postgres has no CREATE TYPE IF NOT EXISTS, so we guard with an exception.
-- ─────────────────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE asset_class_enum AS ENUM (
    'multifamily',
    'data_center',
    'hard_money',
    'nuclear'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE submitter_type_enum AS ENUM (
    'borrower',
    'broker',
    'land_partner'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE deal_status_enum AS ENUM (
    'active',
    'paused',
    'closed_won',
    'closed_lost',
    'dead'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE interest_status_enum AS ENUM (
    'pending',
    'interested',
    'passed',
    'term_sheet_issued'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 2 — Extend the existing deals table
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS asset_class    asset_class_enum,
  ADD COLUMN IF NOT EXISTS submitter_type submitter_type_enum DEFAULT 'borrower',
  ADD COLUMN IF NOT EXISTS deal_status    deal_status_enum    DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS geography      TEXT,
  ADD COLUMN IF NOT EXISTS loan_type      TEXT;   -- bridge / construction / perm / equity / mezz

-- Best-effort migration of existing text asset_type → new enum.
-- Only sets asset_class when still NULL so re-runs are safe.
UPDATE deals SET asset_class = 'multifamily'
  WHERE asset_class IS NULL
    AND lower(asset_type) LIKE '%multifamily%';

UPDATE deals SET asset_class = 'data_center'
  WHERE asset_class IS NULL
    AND (lower(asset_type) LIKE '%data center%'
      OR lower(asset_type) LIKE '%data_center%');

UPDATE deals SET asset_class = 'nuclear'
  WHERE asset_class IS NULL
    AND (lower(asset_type) LIKE '%nuclear%'
      OR lower(asset_type) LIKE '%energy%');

UPDATE deals SET asset_class = 'hard_money'
  WHERE asset_class IS NULL
    AND (lower(asset_type) LIKE '%hard money%'
      OR lower(asset_type) LIKE '%bridge%');


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 3 — Extend checklist_items
-- Adds requirement_id so each seeded item traces back to its template row.
-- FK added after asset_class_requirements is created (Step 4).
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE checklist_items
  ADD COLUMN IF NOT EXISTS requirement_id UUID;


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 4 — asset_class_requirements
-- Config table: defines every document required per asset_class + phase.
-- Admins edit this table; the app reads it when seeding a new deal room.
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS asset_class_requirements (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_class  asset_class_enum NOT NULL,
  phase        INT         NOT NULL CHECK (phase BETWEEN 0 AND 4),
  group_name   TEXT        NOT NULL,
  doc_name     TEXT        NOT NULL,
  doc_sub      TEXT,
  required     BOOLEAN     NOT NULL DEFAULT TRUE,
  sort_order   INT         NOT NULL DEFAULT 0,
  -- notes visible only to admin (flags, assumptions, caveats)
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (asset_class, phase, doc_name)
);

-- Now add the FK from checklist_items → requirements (safe to re-run)
DO $$ BEGIN
  ALTER TABLE checklist_items
    ADD CONSTRAINT fk_checklist_requirement
    FOREIGN KEY (requirement_id)
    REFERENCES asset_class_requirements (id)
    ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 5 — phase_history
-- Records every phase transition with who made it and when.
-- Enables "time in phase" analytics and a full audit trail.
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS phase_history (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id         UUID        REFERENCES deals(id) ON DELETE CASCADE NOT NULL,
  from_phase      INT,        -- NULL on initial deal creation
  to_phase        INT         NOT NULL,
  transitioned_by UUID        REFERENCES auth.users(id),
  note            TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 6 — capital_partners
-- Lender / family office / DFI mandate profiles.
-- If a lender has a portal login, user_id links to auth.users.
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS capital_partners (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  firm_name       TEXT        NOT NULL,
  contact_name    TEXT,
  contact_email   TEXT,
  -- Postgres native array columns for multi-value mandate fields
  asset_classes   TEXT[],     -- subset of enum values as text for flexibility
  structures      TEXT[],     -- ['debt','equity','mezz','preferred_equity']
  geographies     TEXT[],     -- ['Hawaii','Southeast US','National']
  min_check       NUMERIC,
  max_check       NUMERIC,
  min_ltv         NUMERIC,
  max_ltv         NUMERIC,
  notes           TEXT,
  user_id         UUID        REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 7 — deal_lender_matches
-- Explicit record of which deals have been shared with which partners,
-- how they were shared, and what their current interest status is.
-- share_token enables a read-only URL that bypasses auth.
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS deal_lender_matches (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id         UUID        REFERENCES deals(id) ON DELETE CASCADE NOT NULL,
  partner_id      UUID        REFERENCES capital_partners(id) ON DELETE CASCADE NOT NULL,
  shared_at       TIMESTAMPTZ DEFAULT NOW(),
  share_token     TEXT        UNIQUE DEFAULT gen_random_uuid()::TEXT,
  interest_status interest_status_enum DEFAULT 'pending',
  notes           TEXT,
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (deal_id, partner_id)
);


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8 — RLS on new tables
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE asset_class_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE phase_history            ENABLE ROW LEVEL SECURITY;
ALTER TABLE capital_partners         ENABLE ROW LEVEL SECURITY;
ALTER TABLE deal_lender_matches      ENABLE ROW LEVEL SECURITY;

-- Drop all policies so this file is safe to re-run
DROP POLICY IF EXISTS "anyone read requirements"       ON asset_class_requirements;
DROP POLICY IF EXISTS "admin manage requirements"      ON asset_class_requirements;
DROP POLICY IF EXISTS "admin all phase_history"        ON phase_history;
DROP POLICY IF EXISTS "borrower read phase_history"    ON phase_history;
DROP POLICY IF EXISTS "admin all capital_partners"     ON capital_partners;
DROP POLICY IF EXISTS "lender own partner read"        ON capital_partners;
DROP POLICY IF EXISTS "lender own partner update"      ON capital_partners;
DROP POLICY IF EXISTS "lender own partner insert"      ON capital_partners;
DROP POLICY IF EXISTS "admin all matches"              ON deal_lender_matches;
DROP POLICY IF EXISTS "lender own matches"             ON deal_lender_matches;
DROP POLICY IF EXISTS "lender matched deals"           ON deals;
DROP POLICY IF EXISTS "lender matched checklist"       ON checklist_items;

-- asset_class_requirements
--   Any logged-in user can read (needed for checklist seeding on deal create).
--   Only admin can write.
CREATE POLICY "anyone read requirements"
  ON asset_class_requirements FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "admin manage requirements"
  ON asset_class_requirements FOR ALL
  USING (is_admin());

-- phase_history
CREATE POLICY "admin all phase_history"
  ON phase_history FOR ALL
  USING (is_admin());

CREATE POLICY "borrower read phase_history"
  ON phase_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM deals
      WHERE id = phase_history.deal_id
        AND borrower_id = auth.uid()
    )
  );

-- capital_partners
CREATE POLICY "admin all capital_partners"
  ON capital_partners FOR ALL
  USING (is_admin());

CREATE POLICY "lender own partner read"
  ON capital_partners FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "lender own partner update"
  ON capital_partners FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "lender own partner insert"
  ON capital_partners FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- deal_lender_matches
CREATE POLICY "admin all matches"
  ON deal_lender_matches FOR ALL
  USING (is_admin());

CREATE POLICY "lender own matches"
  ON deal_lender_matches FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM capital_partners
      WHERE id = deal_lender_matches.partner_id
        AND user_id = auth.uid()
    )
  );

-- deals: lenders can now read deals they've been explicitly matched with
CREATE POLICY "lender matched deals"
  ON deals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM deal_lender_matches dlm
      JOIN capital_partners cp ON cp.id = dlm.partner_id
      WHERE dlm.deal_id = deals.id
        AND cp.user_id = auth.uid()
    )
  );

-- checklist_items: lenders can read completion % for matched deals
CREATE POLICY "lender matched checklist"
  ON checklist_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM deal_lender_matches dlm
      JOIN capital_partners cp ON cp.id = dlm.partner_id
      WHERE dlm.deal_id = checklist_items.deal_id
        AND cp.user_id = auth.uid()
    )
  );


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 9 — Storage policy tightening
--
-- SECURITY FLAG: The existing "borrower upload files" and "borrower read files"
-- policies only check auth.uid() IS NOT NULL, meaning any logged-in user can
-- upload or read from deal-files. Tightened below.
--
-- Storage path format used by the app: {deal_id}/{item_id}/{ts}-{filename}
-- so split_part(name,'/',1) = deal_id.
-- ─────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "borrower upload files"       ON storage.objects;
DROP POLICY IF EXISTS "borrower read files"         ON storage.objects;
DROP POLICY IF EXISTS "lender read matched files"   ON storage.objects;

-- Borrowers: upload only to their own deal's folder
CREATE POLICY "borrower upload files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'deal-files'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM deals
      WHERE borrower_id = auth.uid()
        AND id::TEXT = split_part(name, '/', 1)
    )
  );

-- Borrowers and admin: read only their own deal files
CREATE POLICY "borrower read files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'deal-files'
    AND (
      is_admin()
      OR EXISTS (
        SELECT 1 FROM deals
        WHERE borrower_id = auth.uid()
          AND id::TEXT = split_part(name, '/', 1)
      )
    )
  );

-- Lenders: read files for deals they've been matched with
CREATE POLICY "lender read matched files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'deal-files'
    AND EXISTS (
      SELECT 1 FROM deal_lender_matches dlm
      JOIN capital_partners cp ON cp.id = dlm.partner_id
      WHERE cp.user_id = auth.uid()
        AND dlm.deal_id::TEXT = split_part(name, '/', 1)
    )
  );


-- ═══════════════════════════════════════════════════════════════════════════
-- After running this file, run seed-requirements.sql in a second SQL Editor
-- tab to populate asset_class_requirements for all four asset classes.
-- ═══════════════════════════════════════════════════════════════════════════
