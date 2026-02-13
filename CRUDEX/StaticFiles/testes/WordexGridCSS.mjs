// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

/**
 * Flag interna para garantir que o CSS seja injetado apenas uma vez.
 * Evita duplicação ao importar o módulo em vários lugares.
 */
let __wordex_grid_css = false;

/**
 * Injeta o CSS base de seleção/moldura do Wordex (1x).
 *
 * Responsabilidades:
 * - visual de linha selecionada (tr.sel-row)
 * - visual de coluna selecionada (td/th.sel-col)
 * - visual de célula selecionada (td/th.sel-cell)
 *
 * Observação:
 * - NÃO aplica estilos inline
 * - NÃO depende de Web Components
 * - Apenas responde às classes já usadas pelo Wordex
 */
export function ensureWordexGridCss() {
  if (__wordex_grid_css) return;
  __wordex_grid_css = true;

  const id = "wordex-grid-css";
  if (document.getElementById(id)) return;
  if (!document.head) return; // defesa extra

  const st = document.createElement("style");
  st.id = id;

  st.textContent = `
    /* =========================
       Wordex - Grid selection
       ========================= */

    /* Linha selecionada */
    tr.sel-row > td,
    tr.sel-row > th {
      outline: 2px solid #22ff22;
      outline-offset: -2px;
    }

    /* Coluna selecionada */
    td.sel-col,
    th.sel-col {
      outline: 2px solid #22ff22;
      outline-offset: -2px;
    }

    /* Célula selecionada */
    td.sel-cell,
    th.sel-cell {
      outline: 2px solid #22ff22;
      outline-offset: -2px;
    }
  `;

  document.head.appendChild(st);
}
