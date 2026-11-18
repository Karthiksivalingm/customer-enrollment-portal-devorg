/*
 * Iframe support for the enrollment form (index.html and thank-you.html).
 *
 * When the page runs inside an iframe, it tells the parent page:
 *   { type: "ep-enrollment-form:height", height: <px> }   whenever its height changes
 *   { type: "ep-enrollment-form:step", step: "company" | "people" | "review" }
 *   { type: "ep-enrollment-form:submitted" }              on the thank-you page
 * The parent can use these to size the iframe and scroll it into view
 * (see embed-demo.html). Messages contain no form data.
 * When the page is opened directly (not in an iframe), this does nothing.
 */
(function () {
  "use strict";

  const PREFIX = "ep-enrollment-form:";
  const embedded = window.parent !== window;
  let lastHeight = 0;

  function post(message) {
    if (embedded) {
      // "*" is safe here: the messages carry only a height or a step name.
      window.parent.postMessage(message, "*");
    }
  }

  /** Height of the form content (not the iframe), so the iframe can also shrink. */
  function contentHeight() {
    const root = document.querySelector(".ep-embed") || document.body;
    return Math.ceil(root.getBoundingClientRect().height);
  }

  function reportHeight() {
    const height = contentHeight();
    if (height > 0 && height !== lastHeight) {
      lastHeight = height;
      post({ type: PREFIX + "height", height });
    }
  }

  window.EPEmbed = Object.freeze({
    embedded,
    notify(event, detail) {
      post(Object.assign({ type: PREFIX + event }, detail || {}));
    }
  });

  if (!embedded) {
    return;
  }
  document.documentElement.classList.add("ep-is-embedded");
  if (typeof ResizeObserver === "function") {
    const observe = () => {
      const root = document.querySelector(".ep-embed") || document.body;
      new ResizeObserver(reportHeight).observe(root);
    };
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", observe);
    } else {
      observe();
    }
  }
  window.addEventListener("load", reportHeight);
  window.addEventListener("resize", reportHeight);
})();
