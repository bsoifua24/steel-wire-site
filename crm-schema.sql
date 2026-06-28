-- ═══════════════════════════════════════════════════════════════════════
-- Steel & Aire Soluciones — CRM Schema
-- Run in Supabase SQL editor AFTER schema.sql and schema-v2.sql.
-- Idempotent: safe to re-run.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1. CRM CONTACTS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm_contacts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,
  deal_id       UUID REFERENCES deals(id) ON DELETE SET NULL,
  full_name     TEXT NOT NULL,
  email         TEXT,
  phone         TEXT,
  company       TEXT,
  source        TEXT DEFAULT 'direct',   -- direct, referral, website, conference, cold
  stage         TEXT DEFAULT 'prospect', -- prospect, onboarding, collecting, reviewing,
                                         -- marketing, term_sheet, closing, closed, paused
  priority      TEXT DEFAULT 'normal',   -- low, normal, high, urgent
  next_followup DATE,
  followup_note TEXT,
  assigned_to   UUID REFERENCES profiles(id) ON DELETE SET NULL,
  tags          TEXT[] DEFAULT '{}',
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE crm_contacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage crm_contacts" ON crm_contacts;
CREATE POLICY "Admins manage crm_contacts" ON crm_contacts
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- ── 2. CRM ACTIVITIES ────────────────────────────────────────────────
-- Every interaction: calls, emails, meetings, notes, system events
CREATE TABLE IF NOT EXISTS crm_activities (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id    UUID REFERENCES crm_contacts(id) ON DELETE CASCADE,
  deal_id       UUID REFERENCES deals(id) ON DELETE SET NULL,
  activity_type TEXT NOT NULL DEFAULT 'note',
    -- call | email | meeting | note | doc_uploaded | phase_advanced | task_completed | system
  subject       TEXT,
  body          TEXT NOT NULL,
  logged_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  activity_date TIMESTAMPTZ DEFAULT now(),
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE crm_activities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage crm_activities" ON crm_activities;
CREATE POLICY "Admins manage crm_activities" ON crm_activities
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- Index for fast per-contact lookups
CREATE INDEX IF NOT EXISTS idx_crm_activities_contact ON crm_activities(contact_id, activity_date DESC);

-- ── 3. CRM TASKS ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm_tasks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id  UUID REFERENCES crm_contacts(id) ON DELETE CASCADE,
  deal_id     UUID REFERENCES deals(id) ON DELETE SET NULL,
  title       TEXT NOT NULL,
  description TEXT,
  due_date    DATE,
  assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
  priority    TEXT DEFAULT 'normal',   -- low, normal, high, urgent
  completed   BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE crm_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage crm_tasks" ON crm_tasks;
CREATE POLICY "Admins manage crm_tasks" ON crm_tasks
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE INDEX IF NOT EXISTS idx_crm_tasks_contact ON crm_tasks(contact_id);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_due ON crm_tasks(due_date) WHERE NOT completed;

-- ── 4. DOCUMENT EXPIRY TRACKING ──────────────────────────────────────
-- Tracks issue date of time-sensitive documents (PFS, appraisals, etc.)
CREATE TABLE IF NOT EXISTS doc_expiry (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id     UUID REFERENCES deals(id) ON DELETE CASCADE,
  item_id     UUID REFERENCES checklist_items(id) ON DELETE CASCADE,
  doc_name    TEXT,
  issued_date DATE NOT NULL,
  expiry_days INTEGER DEFAULT 90,
  alerted     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(item_id)
);

ALTER TABLE doc_expiry ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage doc_expiry" ON doc_expiry;
CREATE POLICY "Admins manage doc_expiry" ON doc_expiry
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Borrowers view own doc_expiry" ON doc_expiry;
CREATE POLICY "Borrowers view own doc_expiry" ON doc_expiry
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM deals
      WHERE deals.id = doc_expiry.deal_id
        AND deals.borrower_id = auth.uid()
    )
  );

-- ── DONE ─────────────────────────────────────────────────────────────
-- After running this file:
-- 1. The CRM tab will load from Supabase (not localStorage).
-- 2. Document expiry tracking will be available on deal detail pages.
-- 3. Add clients via the CRM tab — they can be linked to deal rooms.
