// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsOrientation.mjs  (initOrientation)
   - Alterna retrato/paisagem
   - Aplica em TODAS as .page (se existir mais de uma)
   - Marca estado em page.dataset.orientation ("portrait"|"landscape")
   - Não usa logs
   ========================================================================== */

/**
 * @typedef {Object} OrientationCtx
 * @property {() => void} saveSelection
 * @property {() => void} focusAndRestore
 * @property {Document=} doc
 */

/**
 * @param {OrientationCtx} ctx
 */
export function initOrientation(ctx) {
  const doc = ctx.doc || document;

  const tbOrientation = doc.getElementById("tbOrientation");
  if (!(tbOrientation instanceof HTMLButtonElement)) return;

  /**
   * @returns {HTMLElement[]}
   */
  function getPages() {
    return Array.from(doc.querySelectorAll(".page")).filter((x) => x instanceof HTMLElement);
  }

  /**
   * Determina o estado atual baseado em dataset ou classe.
   * @param {HTMLElement} page
   * @returns {"portrait"|"landscape"}
   */
  function getOrientation(page) {
    const d = (page.dataset.orientation || "").toLowerCase();
    if (d === "landscape" || d === "portrait") return /** @type {"portrait"|"landscape"} */ (d);
    return page.classList.contains("landscape") ? "landscape" : "portrait";
  }

  /**
   * Aplica o estado nas páginas.
   * @param {"portrait"|"landscape"} ori
   */
  function apply(ori) {
    const pages = getPages();
    for (const page of pages) {
      page.classList.toggle("landscape", ori === "landscape");
      page.dataset.orientation = ori;
    }
  }

  /**
   * Aplica o estado atual ao carregar (se houver dataset prévio).
   */
  function applyCurrent() {
    const pages = getPages();
    if (!pages.length) return;
    apply(getOrientation(pages[0]));
  }

  // aplica uma vez ao iniciar
  applyCurrent();

  tbOrientation.addEventListener("click", () => {
    ctx.saveSelection?.();
    ctx.focusAndRestore?.();

    const pages = getPages();
    if (!pages.length) return;

    const cur = getOrientation(pages[0]);
    const next = cur === "portrait" ? "landscape" : "portrait";
    apply(next);

    ctx.saveSelection?.();
  });
}
