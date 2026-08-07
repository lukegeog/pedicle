# Unified Pedicle Platform — Architecture

## Goal

One app, three sections, reachable from a single home screen:

1. **Cases** (today's Pedicle) — log a case, attach/annotate photos, dictate a debrief.
2. **Theatre Logbook** — photo of the list → Claude vision extraction → SAC indicative flagging → submit to eLogbook.
3. **ISCP Reflections** — generate the seven-heading reflection from a logged case.

Primary device: phone, for Cases. Secondary device: laptop, for Theatre Logbook review/editing and the eLogbook submit step (which needs a real desktop browser).

## Why this isn't a pure merge of the two existing codebases

- **Pedicle** is a single HTML file, zero backend, IndexedDB only. That's exactly why it works as a mobile PWA.
- **Theatre logbook app** is a Streamlit (Python) server app. Its `elogbook_submit.py` drives a real Chromium window via Playwright, with a human confirming each case before it saves — that step is inherently a desktop, interactive-login action. It cannot run inside a static PWA or on a phone, and shouldn't try to.
- The two apps' Supabase setup deliberately uses the `service_role` key, kept server-side only, with RLS set to deny-all otherwise. That's safe for a Streamlit server no one else can reach, but the key must never ship inside a static site's JS — anyone who views source gets full database access. Moving case data to a browser-reachable store means introducing proper multi-user auth (Supabase Auth) and RLS scoped to `auth.uid()`, not lifting the existing schema as-is.

## Decisions made with Luke

- Data model: **one shared `cases` table**, synced via Supabase, feeding all three sections. A case logged on the phone in theatre becomes visible on the laptop for eLogbook submission, without export/import.
- eLogbook submission: **stays a local, desktop-only step**. Same Playwright script, same human-in-the-loop per-case confirmation. The unified app's desktop view gets a "Submit to eLogbook" panel that shows/launches the same command `app.py`'s cloud-mode banner already tells you to run today — this isn't new behaviour, just relocated into the merged app's UI.
- Stay single-file / no-build in spirit: no bundler, no compiler. The entry point stays `index.html`; growing feature set is split into a handful of plain `.js` files loaded via `<script src>` tags (still zero build step, just organised).

## Data model (Supabase / Postgres)

```
cases
  id              uuid pk default gen_random_uuid()
  user_id         uuid not null default auth.uid()   -- RLS key
  source          text        -- 'pedicle' | 'logbook' | 'manual'
  created_at      timestamptz default now()
  updated_at      timestamptz default now()
  date_of_surgery date
  patient_ref     text        -- non-identifying code / V-number
  patient_age     text
  patient_gender  text
  category        text
  cepod           text
  consultant      text
  hospital        text
  supervision     text
  procedure_raw   text
  elogbook_term   text
  operation_note  text
  summary         text        -- Pedicle reflective fields
  markings        text
  technical_tips  text
  equipment       text
  dictation_transcript text
  indicative      boolean default false
  sac_groups      text
  submitted_at    timestamptz -- stamped once eLogbook submit confirms
  iscp_reflection jsonb       -- the seven ISCP headings
  photos          jsonb default '[]'  -- [{storage_path, caption, annotations}]
  model_term      text        -- learning-loop bookkeeping (was `_model_term`)

corrections
  id         uuid pk default gen_random_uuid()
  user_id    uuid not null default auth.uid()
  raw        text
  term       text
  created_at timestamptz default now()
```

(`cases` also has a `local_id text` column with a unique `(user_id, local_id)` index — this is what lets the browser upsert by its own IndexedDB id instead of the server-generated uuid.)

RLS on both tables: `select/insert/update/delete using (user_id = auth.uid())`.

Photos move from base64-in-JSON to a Supabase Storage bucket `case-photos`, one object per photo, path prefixed `{auth.uid()}/...`, with a storage policy restricting access to the owning user. The `photos` jsonb column just holds pointers + annotation metadata.

Auth: Supabase Auth, email + password (or magic link), public sign-up disabled so only your account exists. The anon key ships in the client — safe, because every table/bucket is RLS-scoped to `auth.uid()`.

## App shell

- `index.html` — shell: PIN/auth gate, bottom-nav (mobile) / sidebar (desktop) switching between **Cases**, **Logbook**, **ISCP**, **Settings**.
- `js/data.js` — Supabase client init, `cases` CRUD, IndexedDB mirror for offline queueing on mobile (write locally first, flush to Supabase when back online — important for spotty theatre wifi).
- `js/cases.js` — today's Pedicle case form, photo capture/annotation, dictation.
- `js/logbook.js` — theatre-list photo upload → Claude vision extraction (ported from `app.py`'s prompt, now called directly from the browser with your API key, same pattern Pedicle already uses) → card/table review → indicative flagging (ported from `indicative_codes.py`) → operation-tree picker (ported from `procedure_tree.py` + `elogbook_tree.json`).
- `js/iscp.js` — reflection generator, extending Pedicle's existing one, now pulling structured case fields instead of free text alone.
- `js/submit-panel.js` — desktop-only "Submit to eLogbook" panel: pulls pending cases from Supabase, shows the same terminal command, optionally triggers it if running from a local dev server (not possible from a hosted static page — browsers can't spawn local processes; this is a hard constraint, not an oversight).
- `elogbook_submit.py` — kept nearly as-is, repointed to read from the new `cases` table (via the Supabase REST API with a *local-only* key you keep in `.streamlit`-style secrets on your laptop, never shipped to the browser) instead of `logbook.json`.

## Migration plan (phased)

1. **Schema + auth** — create the new Supabase project/tables above, set up your Supabase Auth account. *(this phase's output: `supabase/schema.sql`)*
2. **Shell + Cases** — build the home screen and port Pedicle's case logging/photos/dictation onto the new schema. Verify on phone.
3. **Logbook section** — port the extraction prompt, review UI, and indicative flagging into the shell. Verify photo → cases flow end to end.
4. **eLogbook submit** — repoint `elogbook_submit.py` at the new table; verify one real submission end to end before trusting it for a full list.
5. **ISCP section** — extend the existing reflection generator to read the richer case record.
6. **Mobile polish** — offline queueing, PWA manifest/icons, one-handed layout pass for in-theatre use.
7. **Retire old apps** — once the unified app has run in parallel for a couple of theatre days without issues, stop using the standalone Pedicle and Streamlit apps.

## Open item, unrelated to this plan

`pedicle/.git/config` has a GitHub personal access token embedded in the remote URL in plaintext. Revoke it on GitHub and re-add the remote via SSH or a credential helper before doing anything else with that repo.
