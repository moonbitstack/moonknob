// Runs before the first paint: the theme is either the one picked during this
// visit or whatever the system prefers, and a refresh goes back to the system.
(() => {
  try {
    const saved = sessionStorage.getItem("moonknob-theme");
    if (saved === "light" || saved === "dark") {
      document.documentElement.dataset.theme = saved;
    }
  } catch (error) {
    // A browser that refuses storage simply keeps following the system.
  }
})();
