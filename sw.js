/* Pedicle service worker — full offline app-shell cache.
   Bump SW_VERSION any time index.html (or any precached file) changes,
   so clients pick up the new version instead of serving a stale shell
   forever. This is the one manual step this strategy requires. */
const SW_VERSION = 'v1';
const CACHE_NAME = `pedicle-${SW_VERSION}`;

// The manifest and its icons are inlined as data: URIs inside index.html
// (matching the app's existing single-file convention), so there's no
// separate manifest.json/icon file to precache here — index.html alone
// carries everything. icon/pedicle-icon.png is a source asset (used in
// the repo/README), not something the running app fetches, but it's
// cheap to have available offline too.
const PRECACHE_URLS = [
  './',
  './index.html',
  './elogbook-tree.json',
  './icon/pedicle-icon.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// Let the page ask a waiting SW to activate immediately (used by the
// "Update ready" toast in index.html) instead of waiting for a full
// close-and-reopen.
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;

  // Only ever handle our own same-origin GETs. Supabase, the Anthropic
  // API, and the jsdelivr CDN script are cross-origin and must always
  // hit the network directly — caching a third-party script or an API
  // response here would risk pinning a stale library version or, worse,
  // serving a cached auth/API response.
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) {
    return;
  }

  // App shell navigations: network-first so you always get the latest
  // code the moment you have signal, falling back to the last cached
  // shell when offline. This is what makes "full offline" not mean
  // "permanently stuck on whatever version happened to be cached."
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Static same-origin assets: cache-first (fast, works offline),
  // refreshing the cache in the background on every successful fetch.
  event.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
        return res;
      }).catch(() => cached);
      return cached || network;
    })
  );
});
