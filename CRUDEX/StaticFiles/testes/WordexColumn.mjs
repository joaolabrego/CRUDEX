// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

/**
 * WordexColumn — wrapper leve para “coluna” por índice (cellIndex) dentro de <table>.
 * - selected: marca classe sel-col nas células
 * - align/vAlign: aplica alinhamento em todas as células da coluna
 * - frame/clearFrame: aplica outline inline em todas as células da coluna
 */

/**
 * @typedef {"left"|"center"|"right"|"justify"|"start"|"end"} CellAlign
 * @typedef {"top"|"middle"|"bottom"} CellVAlign
 */

export class TWordexColumn {
  /** @type {HTMLTableElement} */
  #table;
  /** @type {number} */
  #col;

  /**
   * @param {HTMLTableElement} table
   * @param {number} colIndex
   */
  constructor(table, colIndex) {
    if (!(table instanceof HTMLTableElement))
      throw new Error("TWordexColumn precisa de um <table>.");

    const c = colIndex | 0;
    if (c < 0) throw new Error("colIndex inválido.");

    this.#table = table;
    this.#col = c;
  }

  get table() {
    return this.#table;
  }

  get colIndex() {
    return this.#col;
  }

  /** @returns {HTMLTableCellElement[]} */
  get cells() {
    const rows = Array.from(this.#table.querySelectorAll("tr"));
    /** @type {HTMLTableCellElement[]} */
    const out = [];

    for (const tr of rows) {
      const tds = tr.querySelectorAll(":scope > td, :scope > th");
      const td = /** @type {HTMLTableCellElement|null} */ (
        tds[this.#col] || null
      );
      if (td) out.push(td);
    }
    return out;
  }

  /** @param {boolean} v */
  set selected(v) {
    const cells = this.cells;
    for (const td of cells) td.classList.toggle("sel-col", !!v);
  }

  /**
   * Aplica moldura inline em todas as células da coluna.
   * @param {string} css ex: "2px solid #22ff22"
   */
  frame(css = "2px solid #22ff22") {
    const cells = this.cells;
    for (const td of cells) {
      td.style.outline = css;
      td.style.outlineOffset = "-2px";
    }
  }

  /** Remove moldura inline da coluna inteira. */
  clearFrame() {
    const cells = this.cells;
    for (const td of cells) {
      td.style.outline = "";
      td.style.outlineOffset = "";
    }
  }

  /** @param {CellAlign} v */
  set align(v) {
    const s = (v || "").trim();
    const cells = this.cells;
    for (const td of cells) td.style.textAlign = s;
  }

  /** @param {CellVAlign} v */
  set vAlign(v) {
    const s = (v || "").trim();
    const cells = this.cells;
    for (const td of cells) td.style.verticalAlign = s;
  }
}
