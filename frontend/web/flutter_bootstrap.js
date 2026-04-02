{{flutter_js}}
{{flutter_build_config}}

// Force fresh app boot on deployments where stale service-worker caches can
// cause a white screen due to old asset manifests.
(async function bootstrapFlutter() {
  if (typeof window !== 'undefined' && 'caches' in window) {
    const cacheKeys = await caches.keys();
    await Promise.all(cacheKeys.map((key) => caches.delete(key)));
  }

  if (typeof navigator !== 'undefined' && 'serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }

  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: null,
    },
  });
})();