# Changelog

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
