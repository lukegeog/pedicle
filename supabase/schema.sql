-- Unified Pedicle platform schema.
-- Paste into Supabase SQL editor (Project -> SQL -> New query -> Run).
--
-- Unlike the old theatre-logbook schema (a single service_role-only jsonb
-- blob), this ships to a browser: every table is per-row RLS-scoped to
-- auth.uid(), so the anon key is safe to embed in the static app.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- cases: one row per procedure. Feeds Cases (Pedicle), Logbook, and ISCP.
-- ---------------------------------------------------------------------------

create table if not exists public.cases (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid not null default auth.uid() references auth.users(id) on delete cascade,
    local_id            text,     -- the browser-side id (e.g. Pedicle's `c_...`), used for upsert matching
    source              text not null default 'manual', -- 'pedicle' | 'logbook' | 'manual'
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),

    date_of_surgery     date,
    patient_ref         text,     -- non-identifying code / V-number, never a real name/NHS number
    patient_age         text,
    patient_gender      text,

    category            text,
    cepod               text,
    consultant          text,
    hospital            text,
    supervision         text,
    procedure_raw       text,
    elogbook_term       text,
    operation_note      text,

    summary             text,     -- Pedicle reflective fields
    markings            text,
    technical_tips      text,
    equipment           text,
    dictation_transcript text,

    indicative          boolean not null default false,
    sac_groups          text,
    submitted_at        timestamptz,

    iscp_reflection     jsonb,    -- {situation, task, action, ... 7 headings}
    photos              jsonb not null default '[]'::jsonb, -- [{storage_path, caption, annotations}]
    model_term          text      -- learning-loop bookkeeping (was `_model_term`)
);

alter table public.cases enable row level security;

create policy "cases_select_own" on public.cases
    for select using (user_id = auth.uid());
create policy "cases_insert_own" on public.cases
    for insert with check (user_id = auth.uid());
create policy "cases_update_own" on public.cases
    for update using (user_id = auth.uid());
create policy "cases_delete_own" on public.cases
    for delete using (user_id = auth.uid());

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end $$;

drop trigger if exists trg_cases_updated_at on public.cases;
create trigger trg_cases_updated_at
    before update on public.cases
    for each row execute function public.set_updated_at();

create index if not exists idx_cases_user_date on public.cases (user_id, date_of_surgery desc);
create index if not exists idx_cases_user_submitted on public.cases (user_id, submitted_at);

-- NOT a partial index: PostgREST's upsert (used by the app's push-to-cloud
-- sync) issues a plain `ON CONFLICT (user_id, local_id) DO UPDATE`, and
-- Postgres can only use a *partial* unique index as a conflict arbiter if
-- the ON CONFLICT clause repeats the same WHERE condition -- which the
-- client library doesn't do. A full unique constraint still permits
-- multiple NULL local_id rows (NULLs are never considered equal to each
-- other under a unique constraint), so nothing is lost by dropping the
-- `where local_id is not null` predicate.
alter table public.cases
  add constraint cases_user_local_id_key unique (user_id, local_id);

-- ---------------------------------------------------------------------------
-- corrections: learning loop for the eLogbook-term matcher.
-- ---------------------------------------------------------------------------

create table if not exists public.corrections (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
    raw         text not null,
    term        text not null,
    created_at  timestamptz not null default now()
);

alter table public.corrections enable row level security;

create policy "corrections_select_own" on public.corrections
    for select using (user_id = auth.uid());
create policy "corrections_insert_own" on public.corrections
    for insert with check (user_id = auth.uid());
create policy "corrections_delete_own" on public.corrections
    for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Storage: case photos, one object per photo, scoped per user by path prefix.
-- Run this after creating a bucket named 'case-photos' (Storage -> New bucket,
-- Private).
-- ---------------------------------------------------------------------------

-- Single broad policy rather than four narrow ones (select/insert/update/
-- delete): this project is single-user (public sign-up is off, see below),
-- so the folder-prefix/auth.uid() ownership check adds no real protection
-- and the split policies previously missed UPDATE -- which upsert:true
-- (used by the app's re-sync-safe photo upload) needs, since re-uploading
-- an existing path is an UPDATE under the hood, not an INSERT.
create policy "case_photos_authenticated_all" on storage.objects
    for all using (
        bucket_id = 'case-photos' and auth.role() = 'authenticated'
    ) with check (
        bucket_id = 'case-photos' and auth.role() = 'authenticated'
    );

-- ---------------------------------------------------------------------------
-- Disable public sign-up so this stays single-user (do this in the Supabase
-- dashboard instead if you'd rather not run SQL for it):
-- Authentication -> Providers -> Email -> turn OFF "Allow new users to sign up"
-- after you've created your one account.
-- ---------------------------------------------------------------------------
