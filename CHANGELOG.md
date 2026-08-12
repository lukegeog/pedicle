# Changelog

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
