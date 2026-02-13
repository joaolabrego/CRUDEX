// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsOvertype.mjs
   - INS/OVR real (Insert alterna)
   - Pill (verde INS / vermelho OVR)
   - caret-color dos .editable (verde INS / vermelho OVR)
   - Em OVR: digitação substitui 1 char à direita (TextNode)

   Dependências (passadas via ctx):
   - focusAndRestore(): void
   - placeCaretAfter(node: Node): void
   - saveSelection(): void

   Opcional:
   - isBlockingOvertype?: () => boolean   // ex.: há <wordex-img[selected]>?
   - onModeChange?: (insertMode:boolean) => void
   ========================================================================== */

/**
 * @typedef {Object} OvertypeCtx
 * @property {HTMLElement|null} modePill
 * @property {HTMLElement|null} modeText
 * @property {() => void} focusAndRestore
 * @property {(node: Node) => void} placeCaretAfter
 * @property {() => void} saveSelection
 * @property {(() => boolean)=} isBlockingOvertype
 * @property {((insertMode: boolean) => void)=} onModeChange
 */

let installed = false;

/**
 * Inicializa INS/OVR e retorna controle (get/set/dispose).
 * @param {OvertypeCtx} ctx
 */
export function initOvertype(ctx) {
  if (installed) {
    // evita duplo bind em hot-reload / init repetido
    return null;
  }
  installed = true;

  ensureModeCss();

  let insertMode = true;
  setModeUI(ctx.modePill, ctx.modeText, insertMode);
  ctx.onModeChange?.(insertMode);

  /** @param {KeyboardEvent} e */
  function onKeyDownOvertype(e) {
    if (insertMode) return;
    if (handleOvertypeKey(e, ctx)) e.preventDefault();
  }

  /** @param {KeyboardEvent} e */
  function onKeyDownInsert(e) {
    if (e.key !== "Insert") return;
    e.preventDefault();
    setInsertMode(!insertMode);
  }

  document.addEventListener("keydown", onKeyDownOvertype, true);
  document.addEventListener("keydown", onKeyDownInsert, true);

  function setInsertMode(v) {
    insertMode = !!v;
    setModeUI(ctx.modePill, ctx.modeText, insertMode);
    ctx.onModeChange?.(insertMode);
  }

  function dispose() {
    document.removeEventListener("keydown", onKeyDownOvertype, true);
    document.removeEventListener("keydown", onKeyDownInsert, true);
    installed = false;
  }

  return makeApi(() => insertMode, setInsertMode, dispose);
}

/* -------------------------------------------------------------------------- */

function makeApi(get, set, dispose) {
  return {
    getInsertMode: get,
    setInsertMode: set,
    toggleInsertMode: () => set(!get()),
    dispose,
  };
}

function disposeNoop() {}

/**
 * Atualiza UI do modo INS/OVR.
 * @param {HTMLElement|null} modePill
 * @param {HTMLElement|null} modeText
 * @param {boolean} insertMode
 */
function setModeUI(modePill, modeText, insertMode) {
  if (modeText instanceof HTMLElement) {
    modeText.textContent = insertMode ? "INS" : "OVR";
  }

  if (modePill instanceof HTMLElement) {
    modePill.classList.toggle("ovr", !insertMode);
    modePill.classList.toggle("ins", insertMode);
    modePill.style.background = insertMode ? "#0a0" : "#a00";
    modePill.style.color = "#fff";
  }

  document.documentElement.classList.toggle("wx-ovr", !insertMode);
  document.documentElement.classList.toggle("wx-ins", insertMode);
}

/**
 * Injeta CSS 1x.
 */
function ensureModeCss() {
  const id = "wordex-mode-css";
  if (document.getElementById(id)) return;

  const st = document.createElement("style");
  st.id = id;
  st.textContent = `
    html.wx-ins .editable { caret-color: #22ff22; }
    html.wx-ovr .editable { caret-color: #ff2222; }
    #modePill.ins { background:#0a0; color:#fff; }
    #modePill.ovr { background:#a00; color:#fff; }
  `;
  document.head.appendChild(st);
}

/**
 * Em OVR: se não há seleção, substitui 1 caractere à direita do caret.
 * @param {KeyboardEvent} e
 * @param {OvertypeCtx} ctx
 * @returns {boolean}
 */
function handleOvertypeKey(e, ctx) {
  if (e.ctrlKey || e.altKey || e.metaKey) return false;
  if (e.isComposing) return false;
  if (e.key.length !== 1) return false;

  if (typeof ctx.isBlockingOvertype === "function" && ctx.isBlockingOvertype())
    return false;

  if (!ctx.isBlockingOvertype && document.querySelector("wordex-img[selected]"))
    return false;

  ctx.focusAndRestore();

  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0) return false;

  const r = sel.getRangeAt(0);
  if (!r.collapsed) return false;

  const node = r.startContainer;
  if (node.nodeType !== 3) return false;

  const text = /** @type {Text} */ (node);
  const pos = r.startOffset;

  if (pos < text.data.length) {
    const rr = r.cloneRange();
    rr.setStart(text, pos);
    rr.setEnd(text, pos + 1);
    rr.deleteContents();
  }

  const ins = document.createTextNode(e.key);
  r.insertNode(ins);

  ctx.placeCaretAfter(ins);
  ctx.saveSelection();
  return true;
}
