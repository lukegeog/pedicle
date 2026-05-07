# Changelog

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
