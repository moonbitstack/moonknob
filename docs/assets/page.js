// The plate on the home page runs on the library itself, built for JavaScript by
// the docs workflow. Everything it shows — the answer, which side it came from,
// the warning, the abort — is what `Merge` and `OnClash` answered.

const root = document.documentElement;

// Page scrollbar: the thumb appears once the page has moved, and the reserved
// width never changes, so nothing jumps.
const mark = () => root.classList.toggle("at-top", window.scrollY === 0);
window.addEventListener("scroll", mark, { passive: true });
mark();

// Theme: follow the system until someone picks a side, for this visit only.
const toggle = document.querySelector(".switch");
if (toggle) {
  const system = window.matchMedia("(prefers-color-scheme: dark)");
  const current = () => root.dataset.theme ?? (system.matches ? "dark" : "light");
  const label = () => {
    const next = current() === "dark" ? "light" : "dark";
    toggle.setAttribute("aria-label", `Switch to the ${next} theme`);
    toggle.title = `Switch to the ${next} theme`;
  };
  label();
  toggle.addEventListener("click", () => {
    const next = current() === "dark" ? "light" : "dark";
    root.dataset.theme = next;
    try {
      sessionStorage.setItem("moonknob-theme", next);
    } catch (error) {
      // No storage: the choice lasts until the next page, which is enough.
    }
    label();
  });
}

const rocker = document.querySelector(".rocker");

if (rocker) {
  const RECORD = 30;
  const ANSWERS = {
    0: "nothing is reported",
    1: "reported to whatever the program logs with",
    2: "a clash stops the program",
    3: "the caller answers with the record",
  };
  const state = { wins: 1, given: 10, clash: 0 };

  const sides = [...rocker.querySelectorAll("button")];
  const choosers = [...document.querySelectorAll(".chooser button")];
  const answers = document.querySelector(".answer-value");
  const origin = document.querySelector(".answer-origin");
  const note = document.querySelector(".note");
  const keys = [...document.querySelectorAll(".keys button")];

  let engine = null;

  const render = () => {
    for (const button of sides) {
      button.setAttribute("aria-pressed", String(Number(button.dataset.wins) === state.wins));
    }
    for (const button of keys) {
      button.setAttribute("aria-pressed", String(Number(button.dataset.clash) === state.clash));
    }
    for (const button of choosers) {
      button.setAttribute("aria-pressed", String(Number(button.dataset.given) === state.given));
    }
    if (!engine) {
      note.dataset.state = "";
      note.textContent = "the plate needs the compiled library; the workflow builds it";
      return;
    }
    try {
      const said = JSON.parse(engine.resolve(RECORD, state.given, state.wins, state.clash));
      answers.textContent = String(said.value);
      origin.textContent = said.origin;
      if (said.names.length === 0) {
        note.dataset.state = "";
        note.textContent = "the same value twice is not a clash";
      } else if (said.line) {
        note.dataset.state = "said";
        note.textContent = said.line;
      } else {
        note.dataset.state = "";
        note.textContent = ANSWERS[state.clash];
      }
    } catch (error) {
      // `Panic` aborts; on this target the abort arrives as an exception, so the
      // page can say what stopped instead of going blank.
      answers.textContent = "—";
      origin.textContent = "stopped";
      note.dataset.state = "stopped";
      note.textContent = error.message;
    }
  };

  // Two positions, thrown by a press: the switch is the whole control.
  const place = (wins) => {
    state.wins = wins;
    render();
  };

  for (const button of sides) {
    button.addEventListener("click", () => place(Number(button.dataset.wins)));
  }

  rocker.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      const next = state.wins === 0 ? 1 : 0;
      place(next);
      sides[next].focus();
      event.preventDefault();
    }
  });

  for (const button of choosers) {
    button.addEventListener("click", () => {
      state.given = Number(button.dataset.given);
      render();
    });
  }

  for (const button of keys) {
    button.addEventListener("click", () => {
      state.clash = Number(button.dataset.clash);
      render();
    });
  }

  // The engine is a build product; without it the plate still reads as a plate.
  render();
  import(new URL("../engine/moonknob.js", import.meta.url))
    .then((module) => {
      engine = module;
      render();
    })
    .catch(() => render());

  const copy = document.querySelector(".install code");
  if (copy) {
    copy.title = "Click to copy";
    copy.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(copy.textContent.trim());
        const was = copy.textContent;
        copy.textContent = "copied";
        setTimeout(() => {
          copy.textContent = was;
        }, 1400);
      } catch (error) {
        // A browser without clipboard access leaves the line to be selected by hand.
      }
    });
  }
}
