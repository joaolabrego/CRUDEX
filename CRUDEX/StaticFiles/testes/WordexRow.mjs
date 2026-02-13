// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

/**
 * Tipos aceitos (contratos).
 * @typedef {"left"|"center"|"right"|"justify"|"start"|"end"} CellAlign
 * @typedef {"top"|"middle"|"bottom"} CellVAlign
 */

/**
 * WordexRow — wrapper leve para uma <tr>.
 * - frame/clearFrame: outline inline em todas as células da linha
 * - align/vAlign: aplica alinhamento em todas as células da linha
 *
 * Obs: para evitar “Property 'style' does not exist on type ...” no VS Code,
 * tipamos as células como HTMLTableCellElement e guardamos em variável local.
 */
export class TWordexRow {
  /** @type {HTMLTableRowElement} */
  #tr;

  /**
   * @param {HTMLTableRowElement} tr
   */
  constructor(tr) {
    if (!(tr instanceof HTMLTableRowElement)) {
      throw new Error("TWordexRow: tr inválido.");
    }
    this.#tr = tr;
  }

  /**
   * Lista as células diretas desta linha.
   * (Guarda em variável local pra usar o padrão que você pediu.)
   * @returns {HTMLTableCellElement[]}
   */
  get cells() {
    return Array.from(
      this.#tr.querySelectorAll(":scope > td, :scope > th"),
    ).filter((n) => n instanceof HTMLTableCellElement);
  }

  /**
   * Moldura (outline) em todas as células.
   * @param {string} css ex: "2px solid #22ff22"
   */
  frame(css = "2px solid #22ff22") {
    const cells = this.cells;
    for (const td of cells) {
      td.style.outline = css;
      td.style.outlineOffset = "-2px";
    }
  }

  /** Remove moldura (outline) em todas as células. */
  clearFrame() {
    const cells = this.cells;
    for (const td of cells) {
      td.style.outline = "";
      td.style.outlineOffset = "";
    }
  }

  /** @param {CellAlign} v */
  set align(v) {
    const s = String(v || "").trim();
    const cells = this.cells;
    for (const td of cells) {
      td.style.textAlign = s;
    }
  }

  /** @param {CellVAlign} v */
  set vAlign(v) {
    const s = String(v || "").trim();
    const cells = this.cells;
    for (const td of cells) {
      td.style.verticalAlign = s;
    }
  }
}
