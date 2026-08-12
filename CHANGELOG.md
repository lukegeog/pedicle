# Changelog

## Unreleased — Fix misread MRNs/ages by sending high-resolution column crops, 2026-08-12

- **Fix: MRNs and ages came back as digit-scrambles of the real values** (V1189914 read as V1869991, V1065722 as V0572572), with every case collapsed onto one date. Root cause was resolution, not prompting: the vision API downsamples any image to ~1568px on its long edge, so on a 2600-4000px page photo each MRN digit reached the model only a dozen-or-so pixels wide — enough to see "a 7-digit number", not which one.
- The extractor now sends **native-resolution crops of the Date/MRN/Age/Gender columns** alongside the whole page. Crops are cut into vertical bands with a 6% overlap so no row falls in a gap, and scaled only if a band still exceeds the API limit. Measured effect: 1.7x more linear detail on the digits for a flatbed scan, 2.1x for a full-resolution phone photo. The prompt directs the model to read identifiers from the crops and the operation text from the full page, and to de-duplicate rows appearing in the overlap.
- **New review warning when every case shares one date** — a real theatre list spans several, so it's a cheap signal that rows weren't read individually (which is how this failure presented).

## Unreleased — Fix Submit panel showing the wrong instructions, 2026-08-12

- **Fix: the Submit-to-eLogbook panel always showed the "Download JSON first" instructions**, even with Cloud sync connected. The panel branches on being signed in, but it renders during boot *before* the Supabase session has been restored, and nothing re-rendered it afterwards — so the no-sync fallback stuck permanently. It now re-renders when auth state settles, and correctly shows the simpler `python elogbook_submit.py` (no file needed) once signed in.

## Unreleased — Fix skin cancer excisions coded as "wide excision", 2026-08-12

- **Fix: `WLE BCC + local flap` rows were being coded as "wide local excision".** In eLogbook that term only exists under *Non-skin soft tissue tumours* — i.e. sarcoma — so a BCC/SCC/melanoma coded that way is filed under the wrong specialty. eLogbook wants a single combined term naming both lesion and reconstruction: `Excision of BCC & local Flap`, `Excision of SCC & FTSG`, and so on. The extraction prompt now spells out that matrix (8 lesion types × 8 reconstruction types), states that "WLE" is a margin rather than a code, and that the anatomical site belongs in the operation note rather than the term.
- **The prompt's example terms were fabricated**, not real eLogbook entries (`'Nail bed repair — primary'` vs the real `'Repair nailbed'`), which taught the extractor to invent plausible-sounding labels. Replaced with 13 verbatim entries from the tree, plus an explicit instruction to copy real entries rather than invent.
- **New fallback:** any extracted term that isn't an exact tree entry is now resolved to the nearest real one via the same scorer the search box uses, fed both the invented term and the raw list text. `Wide local excision` + `WLE SCC + FTSG (upper lid)` → `Excision of SCC & FTSG`. The original model output is kept in `modelTerm` for the learning loop.
- **New review warning** when a term isn't a real eLogbook operation — those can't be picked from eLogbook's typeahead at submission time, so it's better to catch them during review.

## Unreleased — Fix operation search matching nonsense, 2026-08-12

- **Fix: single-character tokens in the operation tree scored ~0.87 against almost any query.** `lbScore()` filtered query tokens to 2+ characters but never applied the same filter to the tree side, so incidental one-character tokens — `n`/`h` from "H&N", `s` from "tendon(s)", `1`/`2` from zone numbers — matched via the substring branch and dragged irrelevant leaves to the top. This is the root cause of `NBR` returning "Sentinel node biopsy H&N" (`nbr` contains `n`), and of the extensor abbreviations returning *flexor* repairs (`extensor` contains `s`). The tree side now uses the same length filter, and substring matching requires 3+ characters (2-character tokens must match exactly).
- **Added missing abbreviations** that appear in the extractor's own prompt but not the search shorthand map: `NBR`, `FSWO`, `EDC`, `MUA`, `CTD`, `WD`. `NBR` now correctly resolves to "Repair nailbed"; `EDC` maps to the zone V extensor tendon repair rather than the anatomical name, which on its own ranked "Extensor digitorum brevis flap" first.

## Unreleased — Fix "could not load the operation list", 2026-08-12

- **Fix: the eLogbook operation tree is now inlined in `index.html`** instead of fetched from `elogbook-tree.json` at runtime. That fetch was the single point of failure behind "Could not load the operation list", and it had been failing *silently* in the search box too (that call site swallowed the error, so the search just returned nothing). Everything else the app needs — manifest, icons — was already inlined as a data URI for exactly this reason; the tree was the lone exception. Now works offline and on first load before the service worker has cached anything. `elogbook-tree.json` stays in the repo as the editable source of truth.
- **Fix: one failed load no longer poisons every retry.** `loadElogbookTree()` memoised the *in-flight promise*, so a single failure cached a rejected promise and the picker stayed broken for the rest of the page session even once connectivity came back.
- Bumped `SW_VERSION` to `v2` so cached shells pick up the change.

## Unreleased — Browse operations by category, 2026-08-12

- **New "Or browse the full eLogbook list" button** under the operation search box. Opens a drill-down browser over the same 1,927-operation tree, using eLogbook's own hierarchy (14 top-level areas → subcategory → operation) — for when you know roughly where a procedure sits but not what it's called. Breadcrumbs at the top let you jump back up any level; each category shows how many operations sit beneath it. Where a subcategory has both its own operations and further subcategories (e.g. Upper Limb → Bone & joints), both are shown under separate headings, matching eLogbook. If the extractor already guessed a category for the row, the browser opens straight to that area.
- Typed search and the browser now share one select handler, so a term picked either way is stored, categorised and SAC-indicative-flagged identically.

## Unreleased — Logbook list fixes, 2026-08-07

- **New "Clear list" button** in the Theatre Logbook toolbar (red, confirms first). Deletes every logbook case on this device — fixes newly-uploaded lists stacking on top of whatever was extracted before instead of replacing it.
- **Fix: display order didn't match the uploaded photo.** `coerceLogbookCases()` now assigns each row a strictly-increasing `createdAt` (previously all rows from one extraction could share the same millisecond, so the fallback tie-breaker — a random id suffix — silently reordered them); `logbookCases()` now explicitly sorts by `createdAt` rather than trusting IndexedDB's default key order.
- `confirmDialog()` gained an explicit `destructive` option so a custom button label (like "Clear list") can still get the red styling instead of only matching on the literal word "Delete".

## Unreleased — Logbook extraction fix, 2026-08-07

- **Fix: misread MRNs/V-numbers.** Claude vision was occasionally reading a mangled digit as a stray letter (e.g. "VT2117319" instead of "V2117319"). The extraction prompt now spells out the exact format (V + exactly 7 digits, no second letter) and calls out this specific failure mode; `normalizePatientId()` also strips any junk between the V and the digit run as a safety net. A patient ID that still doesn't match `V` + 7 digits after cleanup now surfaces as a review warning instead of silently passing through.
- **Fix: row order / age accuracy on rotated photos.** The prompt now explicitly tells Claude to mentally un-rotate a sideways-photographed list before reading top-to-bottom, and to read the age cell independently rather than inferring it from nearby digits (e.g. the MRN).

## Unreleased — Phase 6 (Mobile polish + offline queueing), 2026-07-17

- **Full offline app shell.** New `sw.js` service worker precaches the app shell (registered from `index.html`); the site now loads with zero signal, not just zero-signal case data (that already worked via IndexedDB). Network-first for the page itself so you get the latest code the moment you have signal, cache-first for static assets. Bump `SW_VERSION` in `sw.js` whenever `index.html` changes, or clients keep the old cached shell.
- **Maskable icon** added to the inline manifest (kept as a `data:` URI to match the existing single-file design — a service worker is the one thing that can't be inlined, since browsers won't run one from a `data:` URL).
- **Background auto-sync.** Cloud sync now retries automatically when connectivity returns and on a 5-minute timer while online + signed in, on top of the existing manual "Sync now" button. The Cloud Sync status line in Settings now distinguishes "offline, will resync automatically" from "not connected."
- **Tap targets**: `.icon-btn` (sheet back/cancel buttons) and `.sheet-save` bumped to a 44px minimum.

## 0.4.0 — 2026-05-07

- **Photo annotation**: open any photo in the fullscreen viewer and tap the new pencil icon to mark it up. Canvas-based pen with five colours (red/blue/green/yellow/white), three stroke widths, undo, clear, save, and cancel. Apple Pencil and finger both work via pointer events. Save flattens the drawing into the photo and replaces it in the case. Available from both the New/Edit sheet (annotate before saving) and the case detail view (annotate already-saved photos). Cancelling discards the strokes.

## 0.3.1 — 2026-05-07

- **ISCP framing fix**: AI drafts now assume the registrar was the **primary operating surgeon** for the case (not assisting). The prompt sets the level at senior registrar (ST6+ / approaching CCT) and instructs Claude to frame Strengths and "What did I do well" as ownership of decisions and execution, not as observation or junior learning.
- **New "Refine with feedback" button** on the ISCP sheet (visible whenever a Claude key is configured). Tap it, type free-text feedback (e.g. *"I was the primary surgeon, rewrite to reflect that"* or *"make Recommended Actions more specific to flap design"*), and Claude rewrites the current draft applying the feedback throughout. You can refine repeatedly until the draft is right, then Copy.
- Tweak: confirm-dialogs that aren't destructive now use the teal primary-action button style instead of the red destructive style.

## 0.3.0 — 2026-05-07

- **Whisper transcription** (optional). Paste an OpenAI API key in Settings → Smart features → OpenAI API key (Whisper). When set, the Dictate mic button records audio via MediaRecorder, uploads it to OpenAI Whisper after you stop, and inserts the high-accuracy transcript into the textarea. Whisper is biased toward plastic-surgery vocabulary via a tuned prompt (suture sizes, anatomy, eponyms, V-numbers). Falls back to browser Web Speech API when no OpenAI key is configured.
- **Auto-drafted ISCP reflections**. The "Generate ISCP reflection" button now auto-drafts with Claude as soon as the sheet opens (whenever a Claude API key is set). A new ↻ Regenerate button in the sheet header lets you re-roll the draft until you're happy.
- **Removed the "Use Claude for…" toggles** from Settings. Configuring an API key is now the single signal: key set = AI features active. Clearing the key disables them.
- New "OpenAI API key (Whisper)" entry in Settings, sitting alongside Claude API key + model.

## 0.2.1 — 2026-05-07

- **Fix**: Dictation no longer overwrites earlier transcripts when you pause and resume. The recogniser now snapshots the textarea content at each `start()` and treats it as the committed prefix, so unfinalised interim text from a previous pause (which iOS Safari drops on `stop()`) is preserved. Manual edits during a pause are preserved for the same reason.

## 0.2.0 — 2026-05-07

- Renamed app to **Pedicle**, with a new minimalist anatomical icon (lobulated skin block + muscle pedicle + bifurcating vessel on a grey disc).
- Photo input now offers Camera / Photo Library / Choose File via the native picker (no more straight-to-camera).
- Replaced single "Learning points" field with three structured fields: **Markings**, **Technical tips**, **Equipment / sutures**.
- Added **Date of surgery** field (separate from created/updated timestamps).
- Added two new case categories: **Cleft / craniofacial** and **Head & neck**.
- Added **Dictate** button on the case form. Web Speech API transcription, with a one-time disclaimer about cloud transcription. Local heuristic parser routes the transcript into the right fields and extracts V-numbers via regex.
- Added optional **Claude API integration**:
  - Paste API key in Settings; toggle per-feature use.
  - Smarter dictation parsing (LLM picks the right field for each sentence).
  - AI-drafted ISCP reflection text under the seven standard headings.
  - V-number auto-redacted from any text sent to Claude. Photos never sent.
- Added **Generate ISCP reflection** button on each case detail view, with copy-to-clipboard.
- Backward-compat migration: legacy `learning` field auto-promotes into `technicalTips` on first load after upgrade.

## 0.1.0 — Initial release

- Single-file PWA with PIN lock, IndexedDB storage, photo capture, eight case categories, search/filter, JSON export/import.
