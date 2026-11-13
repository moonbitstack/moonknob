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

const dial = document.querySelector(".dial");

if (dial) {
  const CENTER = 130;
  const SPREAD = 46;
  const RECORD = 30;
  const ANSWERS = {
    0: "nothing is reported",
    1: "reported to whatever the program logs with",
    2: "a clash stops the program",
    3: "the caller answers with the record",
  };
  const state = { wins: 1, given: 10, clash: 0 };

  const needle = dial.querySelector(".needle");
  const ticks = dial.querySelector(".ticks");
  const detents = [...document.querySelectorAll(".detents span")];
  const choosers = [...document.querySelectorAll(".chooser button")];
  const answers = document.querySelector(".answer-value");
  const origin = document.querySelector(".answer-origin");
  const note = document.querySelector(".note");
  const keys = [...document.querySelectorAll(".keys button")];

  // Thirteen ticks over the travel, drawn once.
  for (let i = 0; i <= 12; i += 1) {
    const angle = ((i / 12) * 2 - 1) * SPREAD;
    const major = i === 0 || i === 6 || i === 12;
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
    const at = (radius) => ({
      x: CENTER + radius * Math.sin((angle * Math.PI) / 180),
      y: CENTER - radius * Math.cos((angle * Math.PI) / 180),
    });
    const from = at(96);
    const to = at(major ? 108 : 103);
    line.setAttribute("x1", from.x.toFixed(2));
    line.setAttribute("y1", from.y.toFixed(2));
    line.setAttribute("x2", to.x.toFixed(2));
    line.setAttribute("y2", to.y.toFixed(2));
    line.setAttribute("class", major ? "tick major" : "tick");
    ticks.append(line);
  }

  const place = (wins, glide = true) => {
    state.wins = wins;
    needle.style.transition = glide ? "" : "none";
    needle.style.transform = `rotate(${(wins === 0 ? -1 : 1) * SPREAD}deg)`;
    dial.setAttribute("aria-valuenow", String(wins));
    dial.setAttribute("aria-valuetext", wins === 0 ? "Base, the record wins" : "Extra, this call wins");
    for (const span of detents) {
      span.setAttribute("aria-current", String(Number(span.dataset.wins) === wins));
    }
    render();
  };

  let engine = null;

  const render = () => {
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

  // Dragging: the needle follows the pointer inside the travel and settles on
  // whichever detent is nearer when it is let go.
  let dragging = false;
  const angleOf = (event) => {
    const box = dial.getBoundingClientRect();
    const x = event.clientX - (box.left + box.width / 2);
    const y = event.clientY - (box.top + box.height / 2);
    return (Math.atan2(x, -y) * 180) / Math.PI;
  };
  dial.addEventListener("pointerdown", (event) => {
    dragging = true;
    dial.setPointerCapture(event.pointerId);
    const angle = Math.max(-SPREAD, Math.min(SPREAD, angleOf(event)));
    needle.style.transition = "none";
    needle.style.transform = `rotate(${angle}deg)`;
  });
  dial.addEventListener("pointermove", (event) => {
    if (!dragging) return;
    const angle = Math.max(-SPREAD, Math.min(SPREAD, angleOf(event)));
    needle.style.transform = `rotate(${angle}deg)`;
  });
  const release = (event) => {
    if (!dragging) return;
    dragging = false;
    dial.releasePointerCapture(event.pointerId);
    place(angleOf(event) < 0 ? 0 : 1);
  };
  dial.addEventListener("pointerup", release);
  dial.addEventListener("pointercancel", () => {
    dragging = false;
    place(state.wins);
  });

  dial.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft" || event.key === "Home") {
      place(0);
      event.preventDefault();
    } else if (event.key === "ArrowRight" || event.key === "End") {
      place(1);
      event.preventDefault();
    } else if (event.key === " " || event.key === "Enter") {
      place(state.wins === 0 ? 1 : 0);
      event.preventDefault();
    }
  });

  for (const span of detents) {
    span.addEventListener("click", () => place(Number(span.dataset.wins)));
    span.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        place(Number(span.dataset.wins));
        event.preventDefault();
      }
    });
  }

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

  const start = () => {
    try {
      const angle = state.wins === 0 ? -SPREAD : SPREAD;
      needle.style.transform = `rotate(${angle}deg)`;
    } catch (error) {
      // Nothing to place yet.
    }
    render();
  };

  // The engine is a build product; without it the plate still reads as a plate.
  start();
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
        copy.dataset.copied = "true";
        const was = copy.textContent;
        copy.textContent = "copied";
        setTimeout(() => {
          copy.textContent = was;
          delete copy.dataset.copied;
        }, 1400);
      } catch (error) {
        // A browser without clipboard access leaves the line to be selected by hand.
      }
    });
  }
}
