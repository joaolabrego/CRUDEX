// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsCss.mjs
   - Centraliza todas as injeções de CSS dinâmico do Wordex
   - Garante injeção 1x por id
   ========================================================================== */

/**
 * Injeta um bloco de CSS apenas uma vez (por id).
 * @param {string} id
 * @param {string} css
 * @param {Document=} doc
 */
export function injectCssOnce(id, css, doc = document) {
  if (doc.getElementById(id)) return;

  const st = doc.createElement("style");
  st.id = id;
  st.textContent = css;
  doc.head.appendChild(st);
}

/**
 * CSS do caret INS/OVR + pill.
 * @param {Document=} doc
 */
export function ensureModeCss(doc = document) {
  injectCssOnce(
    "wordex-mode-css",
    `
      html.wx-ins .editable { caret-color: #22ff22; }
      html.wx-ovr .editable { caret-color: #ff2222; }

      #modePill.ins { background:#0a0; color:#fff; }
      #modePill.ovr { background:#a00; color:#fff; }
    `,
    doc,
  );
}

/**
 * CSS de seleção visual de tabela/linha/coluna/célula.
 * Usado pelos módulos Select/Table.
 * @param {Document=} doc
 */
export function ensureTableSelectionCss(doc = document) {
  injectCssOnce(
    "wordex-table-selection-css",
    `
      .wx-sel-cell  { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-row   { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-col   { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-table { outline: 2px solid #22ff22; outline-offset: -2px; }
    `,
    doc,
  );
}

/**
 * CSS auxiliar para imagens selecionadas.
 * @param {Document=} doc
 */
export function ensureImageSelectionCss(doc = document) {
  injectCssOnce(
    "wordex-image-selection-css",
    `
      wordex-img[selected] {
        outline: 2px solid #ff4444;
        outline-offset: 2px;
      }
    `,
    doc,
  );
}
