// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsInsert.mjs
   - Toggle INS/OVR via tecla Insert
   - Atualiza UI (pill/text) + classes no <html>

   Depende de ctx:
   - modePill: HTMLElement|null
   - modeText: HTMLElement|null
   - doc?: Document
   - (opcional) onInsertModeChange?: (insertMode:boolean)=>void

   Requer:
   - ensureModeCss() deve ter sido chamado pelo Main (módulo Css)
   ========================================================================== */

/**
 * Atualiza UI do modo INS/OVR (visual + classes para CSS).
 * - .wx-ins / .wx-ovr no <html> para caret-color
 * - .ins / .ovr no pill
 * @param {HTMLElement|null} modePill
 * @param {HTMLElement|null} modeText
 * @param {boolean} insertMode
 * @param {Document=} doc
 */
export function setModeUI(modePill, modeText, insertMode, doc = document) {
  if (modeText instanceof HTMLElement) {
    modeText.textContent = insertMode ? "INS" : "OVR";
  }

  if (modePill instanceof HTMLElement) {
    modePill.classList.toggle("ovr", !insertMode);
    modePill.classList.toggle("ins", insertMode);
    modePill.style.background = insertMode ? "#0a0" : "#a00";
    modePill.style.color = "#fff";
  }

  doc.documentElement.classList.toggle("wx-ovr", !insertMode);
  doc.documentElement.classList.toggle("wx-ins", insertMode);
}

/**
 * @typedef {Object} InsertCtx
 * @property {HTMLElement|null} modePill
 * @property {HTMLElement|null} modeText
 * @property {Document=} doc
 * @property {boolean=} insertMode
 * @property {(insertMode:boolean)=>void=} onInsertModeChange
 */

/**
 * Inicializa o módulo Insert (INS/OVR).
 * @param {InsertCtx} ctx
 */
export function initInsert(ctx) {
  const doc = ctx.doc || document;

  // estado global
  ctx.insertMode = ctx.insertMode ?? true;

  const apply = () => {
    setModeUI(
      ctx.modePill instanceof HTMLElement ? ctx.modePill : null,
      ctx.modeText instanceof HTMLElement ? ctx.modeText : null,
      !!ctx.insertMode,
      doc,
    );
    if (typeof ctx.onInsertModeChange === "function") {
      ctx.onInsertModeChange(!!ctx.insertMode);
    }
  };

  apply();

  doc.addEventListener(
    "keydown",
    (e) => {
      if (e.key !== "Insert") return;
      e.preventDefault();
      ctx.insertMode = !ctx.insertMode;
      apply();
    },
    true,
  );

  // expõe helpers (opcional)
  ctx.insert = {
    getInsertMode: () => !!ctx.insertMode,
    setInsertMode: (v) => {
      ctx.insertMode = !!v;
      apply();
    },
  };
}
