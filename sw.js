const CACHE = 'steelaire-v3';

const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/login.html',
  '/onboarding.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png'
];

// On install: cache core pages so the app shell loads offline
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

// On activate: delete any old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch strategy:
// - Supabase / EmailJS API calls → always network (never cache auth/data)
// - Everything else → network-first, fall back to cache
self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Let API calls pass through untouched
  if (
    url.includes('supabase.co') ||
    url.includes('emailjs.com') ||
    url.includes('googleapis.com') ||
    url.includes('jsdelivr.net') ||
    url.includes('unpkg.com') ||
    e.request.method !== 'GET'
  ) return;

  e.respondWith(
    fetch(e.request)
      .then(res => {
        // Cache successful responses for our own origin
        if (res.ok && url.startsWith(self.location.origin)) {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
