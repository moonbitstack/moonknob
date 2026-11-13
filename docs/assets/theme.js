// Runs before the first paint: the theme is the one picked earlier in this visit,
// or whatever the system prefers. A refresh is not "earlier in this visit", so it
// drops the choice and follows the system again.

(() => {
  const key = "moonknob-theme";
  const navigations = performance.getEntriesByType
    ? performance.getEntriesByType("navigation")
    : [];
  const reload =
    navigations[0]?.type === "reload" || performance.navigation?.type === 1;
  try {
    if (reload) {
      sessionStorage.removeItem(key);
      return;
    }
    const saved = sessionStorage.getItem(key);
    if (saved === "light" || saved === "dark") {
      document.documentElement.dataset.theme = saved;
    }
  } catch (error) {
    // A browser that refuses storage simply keeps following the system.
  }
})();
