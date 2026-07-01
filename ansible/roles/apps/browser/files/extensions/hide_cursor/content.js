(() => {
  const hiddenCursorCss = "*, *::before, *::after { cursor: none !important; }";
  const blockedMouseEvents = [
    "mousedown",
    "mouseup",
    "mousemove",
    "pointermove",
    "click",
    "contextmenu",
    "auxclick",
  ];

  let fullscreen = false;
  let cursorHidden = false;
  const style = document.createElement("style");
  document.documentElement.appendChild(style);

  function hideCursor() {
    cursorHidden = true;
    style.textContent = hiddenCursorCss;
  }

  function showCursor() {
    cursorHidden = false;
    style.textContent = "";
  }

  function isVideoFullscreen() {
    const element = document.fullscreenElement;
    return (
      element instanceof HTMLVideoElement ||
      Boolean(element?.querySelector("video"))
    );
  }

  function setFullscreen(active) {
    if (fullscreen === active) {
      return;
    }

    fullscreen = active;
    if (active) {
      hideCursor();
    } else {
      showCursor();
    }
  }

  const fullscreenDisplay = window.matchMedia("(display-mode: fullscreen)");

  function syncFullscreen() {
    const elementFullscreen = Boolean(document.fullscreenElement);
    const active = (elementFullscreen || fullscreenDisplay.matches) &&
      !(elementFullscreen && isVideoFullscreen());
    setFullscreen(active);
  }

  function blockMouseInput(event) {
    if (!fullscreen || !cursorHidden) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
  }

  for (const eventName of blockedMouseEvents) {
    document.addEventListener(eventName, blockMouseInput, true);
  }

  document.addEventListener("fullscreenchange", syncFullscreen);
  fullscreenDisplay.addEventListener("change", syncFullscreen);
  syncFullscreen();

  document.addEventListener(
    "keydown",
    (event) => {
      if (!fullscreen || event.key !== "Escape") {
        return;
      }

      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      if (cursorHidden) {
        showCursor();
      } else {
        hideCursor();
      }
    },
    true
  );
})();
