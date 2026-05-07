# Pedicle

A reflective casebook for plastic surgery residents. Single-file Progressive Web App (PWA). All case data, photos, and (optional) API keys stay on the device in IndexedDB.

## Features

- **Categories**: Breast, Lower limb, Elective hand, Hand trauma, Cosmetic, Burns, Skin, Flaps, Cleft / craniofacial, Head & neck.
- **Per-case fields**: Patient ID, Date of surgery, Case type, Summary, Markings, Technical tips, Equipment / sutures, Photos.
- **Dictate** button: voice-record a debrief, transcript auto-routes into the right fields.
- **ISCP reflection generator**: produces text under the seven standard headings, ready to paste into the ISCP web form.
- **PIN lock** on entry.
- **Search & filter** across IDs, summaries, tips, equipment.
- **Export / Import** JSON backup with photos.

The smart features (dictation parsing + ISCP drafting) work in two modes:

- **Local** (default): regex/keyword heuristics, no network calls.
- **Claude API** (optional): paste a key in Settings for materially better parsing and properly drafted reflective text. Patient ID is auto-redacted before any text leaves the device. Photos are never sent.

## Quickstart

Open `index.html` in any modern browser. To use it as a phone app you need to host it over HTTPS (PWAs require it). The recommended path is GitHub Pages:

### Deploy on GitHub Pages

**First-time setup** (run in Terminal):

```bash
cd "/Users/lukegeog/Documents/Claude/Projects/Clinical work/pedicle"

# Clear the partial .git that the sandbox left (sandbox couldn't finish init)
rm -rf .git

# Fresh init
git init -b main
git add .
git commit -m "Initial commit: Pedicle v0.2.0"
```

Now create the GitHub repo and push:

1. Go to <https://github.com/new>, name the repo (e.g. `pedicle`), make it **Private**, do **not** add README/license/gitignore (we already have them). Create.
2. GitHub shows you a "push existing repository" snippet — copy the three commands and run them in the same Terminal:
   ```bash
   git remote add origin https://github.com/<your-username>/pedicle.git
   git branch -M main
   git push -u origin main
   ```
3. In the repo on GitHub, go to **Settings → Pages → Build and deployment**: source `Deploy from a branch`, branch `main`, folder `/ (root)`. Save.
4. Wait ~1 minute. Your URL is `https://<username>.github.io/pedicle/`.
5. Open that URL on your phone in Safari → **Share → Add to Home Screen**. The Pedicle icon appears on your home screen and opens full-screen like a native app.

**For ongoing changes**: edit `index.html`, then in Terminal:

```bash
git add . && git commit -m "describe what you changed" && git push
```

The live app updates within ~30s. Your IndexedDB data persists across deploys because it's keyed to the origin (URL).

### Migrating from your existing casebook.html host

If you've been using the previous Netlify-hosted version, your existing data lives in IndexedDB at that origin. To carry it across:

1. On the old host: open the app → Settings → **Export all cases** → save the JSON.
2. Set up Pedicle on GitHub Pages as above.
3. On the new URL: open the app, set up your PIN, Settings → **Import from backup** → pick the JSON.
4. Verify everything's there, then you can retire the Netlify URL.

### iPhone install notes

- Use Safari (not Chrome) for the initial Add to Home Screen — Safari handles `apple-touch-icon` properly.
- iOS caches the icon at the moment you add it. To refresh after icon changes: long-press the home-screen tile → Remove from Home Screen → re-add from Safari.

## Optional: Claude API setup

1. Create an Anthropic API key at <https://console.anthropic.com/>.
2. In Pedicle, tap the gear icon → **Smart features** → **Claude API key** → paste.
3. Enable **Use Claude for dictation** and/or **Use Claude for ISCP drafts**.
4. Default model is `claude-haiku-4-5-20251001` (cheapest/fastest). Switch to `claude-sonnet-4-6` or `claude-opus-4-6` from the **Model** setting if you want better drafts.

The app calls Anthropic's API directly from the browser using the
`anthropic-dangerous-direct-browser-access` header. The key is stored in IndexedDB on this device only; it is **not** synced or backed up unless you Export.

### Information governance

- Use a **non-identifying code** in the Patient ID field. Photos + a raw NHS/hospital number = identifiable patient data.
- Browser dictation routes audio through Apple (iOS Safari) or Google (Android Chrome) for speech-to-text. There is no in-browser way around this. Avoid speaking patient names while the mic is live.
- When Claude API is enabled, V-numbers are auto-redacted from text before any request. Photos are never sent.
- Treat the JSON exports as confidential. Save them somewhere protected (encrypted iCloud Drive folder, etc.).

## Backup & restore

- **Export**: Settings → Export all cases → JSON file (photos embedded as base64).
- **Restore**: Settings → Import from backup → pick the JSON.
- Recommended cadence: monthly, or before any major redeploy.

## Local development

Just edit `index.html` and refresh. There are no build steps. The single-file design keeps the app trivially hostable anywhere.

To preview on your phone before pushing, run a local HTTPS server (e.g. `npx serve` over an HTTPS-tunnelled URL via Cloudflare Tunnel, ngrok, or similar) — IndexedDB and `getUserMedia` (mic) require HTTPS for full functionality.

## Roadmap (not yet implemented)

Suggestions parked for future iterations:

- Operating consultant field (filter "all Mr Smith cases").
- Cross-case tags (e.g. "DIEP", "Bruner pearl").
- Logbook CSV export.
- Per-case PDF export for sharing.
- Service worker for true offline support.

## File layout

```
pedicle/
├── index.html          # the entire app (HTML + CSS + JS, single file)
├── README.md           # this file
├── CHANGELOG.md        # version history
├── LICENSE             # MIT
├── .gitignore
└── icon/               # source assets for the app icon
    ├── pedicle-icon.svg
    └── pedicle-icon.png
```

## License

MIT. See `LICENSE`.
