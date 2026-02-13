// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsSelect.mjs  (initSelection)
   - Salva/restaura seleção (Range clone) em ctx.savedRange.
   - Helpers: nó do caret, célula atual, parágrafo atual.
   - focusAndRestore: td editável > contenteditable real > .editable > .body-ed
   - placeCaretAfter / insertNodeAtCaret.
   - ensureParagraphAlive / appendToParagraphEnd.
   - bindSelectionChange: listener selectionchange (1x) p/ manter ctx.savedRange atualizado.
   ========================================================================== */

/**
 * @typedef {Object} TWordexCtx
 * @property {HTMLElement} stage
 * @property {any} wordex
 * @property {HTMLElement|null} modePill
 * @property {HTMLElement|null} modeText
 * @property {Range|null} savedRange
 * @property {number} alignState
 * @property {boolean} insertMode
 * @property {Document=} doc
 * @property {string=} bodySelector
 * @property {string=} editableSelector
 */

/**
 * @param {TWordexCtx} ctx
 */
export function initSelection(ctx) {
  const doc = ctx.doc || document;
  const bodySelector = ctx.bodySelector || ".body-ed";
  const editableSelector = ctx.editableSelector || ".editable";

  // -----------------------
  // Core: save/restore
  // -----------------------
  function saveSelection() {
    const sel = doc.getSelection();
    if (!sel || sel.rangeCount === 0) return;
    ctx.savedRange = sel.getRangeAt(0).cloneRange();
  }

  /**
   * @returns {boolean}
   */
  function restoreSelection() {
    if (!ctx.savedRange) return false;
    const sel = doc.getSelection();
    if (!sel) return false;
    sel.removeAllRanges();
    sel.addRange(ctx.savedRange);
    return true;
  }

  // -----------------------
  // Context helpers
  // -----------------------
  /**
   * @returns {Node|null}
   */
  function getSelNode() {
    const sel = doc.getSelection();
    if (!sel || sel.rangeCount === 0) return null;
    const n = sel.getRangeAt(0).startContainer;
    return n.nodeType === 3 ? n.parentNode : n;
  }

  /**
   * @returns {HTMLTableCellElement|null}
   */
  function getCurrentCell() {
    const n = getSelNode();
    if (!(n instanceof HTMLElement)) return null;
    const td = n.closest("td,th");
    return td instanceof HTMLTableCellElement ? td : null;
  }

  /**
   * @returns {HTMLParagraphElement|null}
   */
  function getCurrentParagraph() {
    const n = getSelNode();
    if (!(n instanceof HTMLElement)) return null;
    const p = n.closest("p");
    return p instanceof HTMLParagraphElement ? p : null;
  }

  // -----------------------
  // Focus + restore
  // -----------------------
  function focusAndRestore() {
    restoreSelection();

    // 1) se está em célula editável
    const td = getCurrentCell();
    if (td && td.isContentEditable) {
      // @ts-expect-error - focus pode não existir em todos os elementos, mas é seguro usar optional chaining
      td.focus?.({ preventScroll: true });
      restoreSelection();
      return;
    }

    // 2) foca o CONTENTEDITABLE real onde o caret está (funciona com shadow também)
    const n = getSelNode();
    if (n instanceof HTMLElement) {
      const ce = n.closest('[contenteditable="true"],[contenteditable="plaintext-only"]');
      if (ce instanceof HTMLElement) {
        // @ts-expect-error - focus pode não existir em todos os elementos, mas é seguro usar optional chaining
        ce.focus?.({ preventScroll: true });
        restoreSelection();
        return;
      }

      if (n.isContentEditable) {
        // @ts-expect-error - focus pode não existir em todos os elementos, mas é seguro usar optional chaining
        n.focus?.({ preventScroll: true });
        restoreSelection();
        return;
      }
    }

    // 3) se o activeElement já está dentro de .editable, foca nele
    const a = doc.activeElement;
    if (a instanceof HTMLElement && typeof a.closest === "function" && a.closest(editableSelector)) {
      // @ts-expect-error - focus pode não existir em todos os elementos, mas é seguro usar optional chaining
      a.focus?.({ preventScroll: true });
      restoreSelection();
      return;
    }

    // 4) fallback: body-ed (sempre usando doc, NÃO document)
    const body = doc.querySelector(bodySelector);
    if (body instanceof HTMLElement) {
      // @ts-expect-error - focus pode não existir em todos os elementos, mas é seguro usar optional chaining
      body.focus?.({ preventScroll: true });
    }
    restoreSelection();
  }

  // -----------------------
  // Insert helpers
  // -----------------------
  /**
   * @param {Node} node
   */
  function placeCaretAfter(node) {
    const r = doc.createRange();
    r.setStartAfter(node);
    r.collapse(true);

    const sel = doc.getSelection();
    if (!sel) return;

    sel.removeAllRanges();
    sel.addRange(r);
    ctx.savedRange = r.cloneRange();
  }

  /**
   * @param {Node} node
   * @returns {boolean}
   */
  function insertNodeAtCaret(node) {
    focusAndRestore();

    const sel = doc.getSelection();
    if (!sel || sel.rangeCount === 0) return false;

    const range = sel.getRangeAt(0);
    range.deleteContents();
    range.insertNode(node);

    placeCaretAfter(node);
    return true;
  }

  /**
   * @param {HTMLParagraphElement} p
   */
  function ensureParagraphAlive(p) {
    if (!p.childNodes.length) p.appendChild(doc.createElement("br"));
  }

  /**
   * @param {HTMLParagraphElement} p
   * @param {HTMLElement} el
   */
  function appendToParagraphEnd(p, el) {
    const last = p.lastChild;
    if (last && last.nodeType === 1 && /** @type {Element} */ (last).tagName === "BR") {
      p.insertBefore(el, last);
    } else {
      p.appendChild(el);
    }
    ensureParagraphAlive(p);
  }

  // -----------------------
  // bindSelectionChange (1x)
  // -----------------------
  function bindSelectionChange() {
    const BOUND_KEY = "__wordex_selectionchange_bound__";
    // @ts-expect-error - Propriedade dinâmica para evitar múltiplos listeners
    if (doc[BOUND_KEY]) return;

    doc.addEventListener("selectionchange", () => {
      const sel = doc.getSelection();
      if (!sel || sel.rangeCount === 0) return;

      const node = getSelNode();
      if (!(node instanceof HTMLElement)) return;

      // salva se seleção está em td/th OU dentro de .editable
      const inCell = !!node.closest("td,th");
      const inEditable = !!node.closest(editableSelector);

      if (inCell || inEditable) saveSelection();
    });

    // @ts-expect-error - Propriedade dinâmica para marcar listener como instalado
    doc[BOUND_KEY] = true;
  }

  bindSelectionChange();

  // -----------------------
  // Exporta no ctx
  // -----------------------
  ctx.saveSelection = saveSelection;
  ctx.restoreSelection = restoreSelection;

  ctx.getSelNode = getSelNode;
  ctx.getCurrentCell = getCurrentCell;
  ctx.getCurrentParagraph = getCurrentParagraph;

  ctx.focusAndRestore = focusAndRestore;

  ctx.placeCaretAfter = placeCaretAfter;
  ctx.insertNodeAtCaret = insertNodeAtCaret;

  ctx.ensureParagraphAlive = ensureParagraphAlive;
  ctx.appendToParagraphEnd = appendToParagraphEnd;

  // salva um estado inicial, se houver seleção
  saveSelection();
}
