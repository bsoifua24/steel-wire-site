-- ══════════════════════════════════════════════════
-- Steel & Aire Soluciones — Supabase Schema
-- Paste this entire file into Supabase SQL Editor
-- and click Run.
-- ══════════════════════════════════════════════════

-- ── PROFILES ──
create table if not exists profiles (
  id          uuid references auth.users(id) on delete cascade primary key,
  role        text not null default 'borrower' check (role in ('admin','borrower')),
  full_name   text,
  company     text,
  created_at  timestamptz default now()
);

-- Auto-create a profile row whenever someone signs up
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ── DEALS ──
create table if not exists deals (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  asset_type    text not null default 'Multifamily',
  raise_amount  text,
  borrower_id   uuid references profiles(id) on delete set null,
  phase         int not null default 0 check (phase between 0 and 4),
  created_at    timestamptz default now()
);

-- ── CHECKLIST ITEMS ──
create table if not exists checklist_items (
  id          uuid primary key default gen_random_uuid(),
  deal_id     uuid references deals(id) on delete cascade not null,
  group_name  text not null,
  doc_name    text not null,
  doc_sub     text,
  phase       int not null default 0,
  sort_order  int not null default 0,
  status      text not null default 'needed' check (status in ('needed','uploaded','review','approved')),
  created_at  timestamptz default now()
);

-- ── DOCUMENTS ──
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

-- ── DEAL PRIVATE NOTES (admin only) ──
create table if not exists deal_private (
  deal_id     uuid references deals(id) on delete cascade primary key,
  notes       text,
  updated_at  timestamptz default now()
);

-- ── ROW LEVEL SECURITY ──
alter table profiles       enable row level security;
alter table deals          enable row level security;
alter table checklist_items enable row level security;
alter table documents      enable row level security;
alter table deal_private   enable row level security;

-- Helper: check if the current user is admin
create or replace function is_admin()
returns boolean language sql security definer as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

-- Profiles: users see their own; admins see all
create policy "own profile read"   on profiles for select using (id = auth.uid());
create policy "admin profile read" on profiles for select using (is_admin());
create policy "own profile update" on profiles for update using (id = auth.uid());

-- Deals: admins see all; borrowers see only theirs
create policy "admin all deals"    on deals for all    using (is_admin());
create policy "borrower own deals" on deals for select using (borrower_id = auth.uid());

-- Checklist items
create policy "admin all checklist" on checklist_items for all using (is_admin());
create policy "borrower read checklist" on checklist_items for select
  using (exists (select 1 from deals where id = checklist_items.deal_id and borrower_id = auth.uid()));

-- Documents
create policy "admin all docs"       on documents for all using (is_admin());
create policy "borrower read docs"   on documents for select
  using (exists (select 1 from deals where id = documents.deal_id and borrower_id = auth.uid()));
create policy "borrower upload docs" on documents for insert
  with check (exists (select 1 from deals where id = documents.deal_id and borrower_id = auth.uid()));

-- Deal private notes: admin only
create policy "admin private notes" on deal_private for all using (is_admin());

-- ── STORAGE BUCKET ──
insert into storage.buckets (id, name, public)
values ('deal-files', 'deal-files', false)
on conflict (id) do nothing;

create policy "admin storage"          on storage.objects for all
  using (bucket_id = 'deal-files' and is_admin());
create policy "borrower upload files"  on storage.objects for insert
  with check (bucket_id = 'deal-files' and auth.uid() is not null);
create policy "borrower read files"    on storage.objects for select
  using (bucket_id = 'deal-files' and auth.uid() is not null);

-- ══════════════════════════════════════════════════
-- AFTER RUNNING: make your account the admin by
-- running this one extra line (replace the email):
--
-- update profiles set role = 'admin'
--   where id = (select id from auth.users where email = 'your@email.com');
--
-- ══════════════════════════════════════════════════
