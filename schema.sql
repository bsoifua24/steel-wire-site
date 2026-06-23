-- ══════════════════════════════════════════════════
-- Steel & Aire Soluciones — Supabase Schema
-- IDEMPOTENT: safe to run multiple times.
-- Paste this entire file into Supabase SQL Editor
-- and click Run.
-- ══════════════════════════════════════════════════

-- ── TABLES ──
create table if not exists profiles (
  id                uuid references auth.users(id) on delete cascade primary key,
  role              text not null default 'borrower' check (role in ('admin','borrower')),
  full_name         text,
  company           text,
  phone             text,
  position          text,
  project_interests text,
  email             text,
  created_at        timestamptz default now()
);

create table if not exists deals (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  asset_type    text not null default 'Multifamily',
  raise_amount  text,
  borrower_id   uuid references profiles(id) on delete set null,
  phase         int not null default 0 check (phase between 0 and 4),
  created_at    timestamptz default now()
);

create table if not exists checklist_items (
  id             uuid primary key default gen_random_uuid(),
  deal_id        uuid references deals(id) on delete cascade not null,
  group_name     text not null,
  doc_name       text not null,
  doc_sub        text,
  phase          int not null default 0,
  sort_order     int not null default 0,
  status         text not null default 'needed' check (status in ('needed','uploaded','review','approved')),
  revision_note  text,
  created_at     timestamptz default now()
);

create table if not exists documents (
  id            uuid primary key default gen_random_uuid(),
  item_id       uuid references checklist_items(id) on delete cascade not null,
  deal_id       uuid references deals(id) on delete cascade not null,
  uploaded_by   uuid references auth.users(id) not null,
  file_name     text not null,
  file_size     bigint,
  storage_path  text not null,
  created_at    timestamptz default now()
);

create table if not exists deal_private (
  deal_id     uuid references deals(id) on delete cascade primary key,
  notes       text,
  updated_at  timestamptz default now()
);

create table if not exists deal_messages (
  id           uuid primary key default gen_random_uuid(),
  deal_id      uuid references deals(id) on delete cascade not null,
  user_id      uuid references auth.users(id) not null,
  sender_name  text not null,
  body         text not null,
  created_at   timestamptz default now()
);

create table if not exists deal_activity (
  id          uuid primary key default gen_random_uuid(),
  deal_id     uuid references deals(id) on delete cascade not null,
  user_id     uuid references auth.users(id),
  description text not null,
  created_at  timestamptz default now()
);

create table if not exists onboarding_tracker_clients (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  start_date   date not null,
  share_token  text not null default gen_random_uuid()::text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

create table if not exists onboarding_tracker_steps (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid references onboarding_tracker_clients(id) on delete cascade not null,
  step_index      int not null check (step_index between 0 and 7),
  label           text not null,
  completed       boolean not null default false,
  completed_date  date,
  notes           text,
  stuck_since     timestamptz,
  updated_at      timestamptz default now(),
  unique(client_id, step_index)
);

create table if not exists onboarding_tracker_comments (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid references onboarding_tracker_clients(id) on delete cascade not null,
  body       text not null,
  created_at timestamptz default now()
);

create table if not exists onboarding_clients (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  email         text,
  phone         text,
  company       text,
  project_type  text,
  status        text not null default 'inquiry'
    check (status in ('inquiry','qualified','proposal_sent','negotiating','won','lost')),
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create table if not exists onboarding_tasks (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid references onboarding_clients(id) on delete set null,
  title       text not null,
  description text,
  status      text not null default 'backlog'
    check (status in ('backlog','in_progress','in_review','done')),
  priority    text not null default 'medium'
    check (priority in ('low','medium','high','urgent')),
  due_date    date,
  created_by  uuid references auth.users(id),
  sort_order  int default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

create table if not exists task_assignees (
  id          uuid primary key default gen_random_uuid(),
  task_id     uuid references onboarding_tasks(id) on delete cascade not null,
  user_id     uuid references auth.users(id) on delete cascade not null,
  assigned_at timestamptz default now(),
  unique(task_id, user_id)
);

create table if not exists task_subtasks (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid references onboarding_tasks(id) on delete cascade not null,
  title      text not null,
  completed  boolean default false,
  created_at timestamptz default now()
);

create table if not exists task_comments (
  id          uuid primary key default gen_random_uuid(),
  task_id     uuid references onboarding_tasks(id) on delete cascade not null,
  user_id     uuid references auth.users(id),
  sender_name text not null,
  body        text not null,
  created_at  timestamptz default now()
);

-- ── SAFE COLUMN ADDITIONS ──
alter table profiles          add column if not exists phone             text;
alter table profiles          add column if not exists position          text;
alter table profiles          add column if not exists project_interests text;
alter table profiles          add column if not exists email             text;
alter table checklist_items   add column if not exists revision_note     text;

-- ── AUTO-CREATE PROFILE ON SIGNUP ──
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, full_name, email)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email)
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ── HELPER FUNCTION ──
create or replace function is_admin()
returns boolean language sql security definer as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

-- ── ROW LEVEL SECURITY ──
alter table profiles                    enable row level security;
alter table deals                       enable row level security;
alter table checklist_items             enable row level security;
alter table documents                   enable row level security;
alter table deal_private                enable row level security;
alter table deal_messages               enable row level security;
alter table deal_activity               enable row level security;
alter table onboarding_clients          enable row level security;
alter table onboarding_tasks            enable row level security;
alter table task_assignees              enable row level security;
alter table task_subtasks               enable row level security;
alter table task_comments               enable row level security;
alter table onboarding_tracker_clients  enable row level security;
alter table onboarding_tracker_steps    enable row level security;
alter table onboarding_tracker_comments enable row level security;

-- ── DROP ALL POLICIES (so re-runs don't error) ──
drop policy if exists "own profile read"            on profiles;
drop policy if exists "admin profile read"          on profiles;
drop policy if exists "own profile update"          on profiles;
drop policy if exists "admin all deals"             on deals;
drop policy if exists "borrower own deals"          on deals;
drop policy if exists "admin all checklist"         on checklist_items;
drop policy if exists "borrower read checklist"     on checklist_items;
drop policy if exists "admin all docs"              on documents;
drop policy if exists "borrower read docs"          on documents;
drop policy if exists "borrower upload docs"        on documents;
drop policy if exists "admin private notes"         on deal_private;
drop policy if exists "admin all messages"          on deal_messages;
drop policy if exists "borrower read messages"      on deal_messages;
drop policy if exists "borrower send message"       on deal_messages;
drop policy if exists "admin all activity"          on deal_activity;
drop policy if exists "borrower read activity"      on deal_activity;
drop policy if exists "any user log activity"       on deal_activity;
drop policy if exists "admin onboarding clients"    on onboarding_clients;
drop policy if exists "admin onboarding tasks"      on onboarding_tasks;
drop policy if exists "admin task assignees"        on task_assignees;
drop policy if exists "admin task subtasks"         on task_subtasks;
drop policy if exists "admin task comments"         on task_comments;
drop policy if exists "admin tracker clients"       on onboarding_tracker_clients;
drop policy if exists "admin tracker steps"         on onboarding_tracker_steps;
drop policy if exists "admin tracker comments"      on onboarding_tracker_comments;

-- ── CREATE POLICIES ──

-- Profiles
create policy "own profile read"   on profiles for select using (id = auth.uid());
create policy "admin profile read" on profiles for select using (is_admin());
create policy "own profile update" on profiles for update using (id = auth.uid());

-- Deals
create policy "admin all deals"    on deals for all    using (is_admin());
create policy "borrower own deals" on deals for select using (borrower_id = auth.uid());

-- Checklist items
create policy "admin all checklist"     on checklist_items for all    using (is_admin());
create policy "borrower read checklist" on checklist_items for select
  using (exists (select 1 from deals where id = checklist_items.deal_id and borrower_id = auth.uid()));

-- Documents
create policy "admin all docs"       on documents for all    using (is_admin());
create policy "borrower read docs"   on documents for select
  using (exists (select 1 from deals where id = documents.deal_id and borrower_id = auth.uid()));
create policy "borrower upload docs" on documents for insert
  with check (exists (select 1 from deals where id = documents.deal_id and borrower_id = auth.uid()));

-- Deal private notes
create policy "admin private notes" on deal_private for all using (is_admin());

-- Deal messages
create policy "admin all messages"     on deal_messages for all    using (is_admin());
create policy "borrower read messages" on deal_messages for select
  using (exists (select 1 from deals where id = deal_messages.deal_id and borrower_id = auth.uid()));
create policy "borrower send message"  on deal_messages for insert
  with check (
    exists (select 1 from deals where id = deal_messages.deal_id and borrower_id = auth.uid())
    and user_id = auth.uid()
  );

-- Deal activity
create policy "admin all activity"     on deal_activity for all    using (is_admin());
create policy "borrower read activity" on deal_activity for select
  using (exists (select 1 from deals where id = deal_activity.deal_id and borrower_id = auth.uid()));
create policy "any user log activity"  on deal_activity for insert
  with check (
    is_admin()
    or exists (select 1 from deals where id = deal_activity.deal_id and borrower_id = auth.uid())
  );

-- Onboarding CRM (admin only)
create policy "admin onboarding clients" on onboarding_clients for all using (is_admin());
create policy "admin onboarding tasks"   on onboarding_tasks   for all using (is_admin());
create policy "admin task assignees"     on task_assignees     for all using (is_admin());
create policy "admin task subtasks"      on task_subtasks      for all using (is_admin());
create policy "admin task comments"      on task_comments      for all using (is_admin());

-- Onboarding tracker (admin only)
create policy "admin tracker clients"  on onboarding_tracker_clients  for all using (is_admin());
create policy "admin tracker steps"    on onboarding_tracker_steps    for all using (is_admin());
create policy "admin tracker comments" on onboarding_tracker_comments for all using (is_admin());

-- ── STORAGE BUCKET ──
insert into storage.buckets (id, name, public)
values ('deal-files', 'deal-files', false)
on conflict (id) do nothing;

drop policy if exists "admin storage"         on storage.objects;
drop policy if exists "borrower upload files" on storage.objects;
drop policy if exists "borrower read files"   on storage.objects;

create policy "admin storage"         on storage.objects for all
  using (bucket_id = 'deal-files' and is_admin());
create policy "borrower upload files" on storage.objects for insert
  with check (bucket_id = 'deal-files' and auth.uid() is not null);
create policy "borrower read files"   on storage.objects for select
  using (bucket_id = 'deal-files' and auth.uid() is not null);

-- ══════════════════════════════════════════════════
-- AFTER RUNNING: make your account the admin.
-- Run this separately in a new SQL Editor tab,
-- replacing the email with yours:
--
-- update profiles set role = 'admin'
--   where id = (select id from auth.users where email = 'bsoifua24@gmail.com');
--
-- ══════════════════════════════════════════════════
