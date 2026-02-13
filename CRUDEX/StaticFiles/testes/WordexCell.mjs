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
 * Wrapper OO (NÃO é Web Component):
 * - Não muda o DOM (continua sendo <td>/<th>)
 * - Só adiciona uma API limpa para operar na célula
 *
 * Uso:
 *   const cell = new TWordexCell(td);
 *   cell.frame();                // moldura verde padrão
 *   cell.align = "center";
 *   cell.text = "ABC";
 */
export class TWordexCell {
  /** @type {HTMLTableCellElement} */
  #td;

  // ===== CSS “encapsulado” (1x) =====
  // Observação: isto NÃO depende de <wordex-tbl>.
  // Aplica somente a células <td>/<th> que você marcar com classes.
  static #cssReady = false;
  static #ensureCss() {
    if (TWordexCell.#cssReady) return;
    TWordexCell.#cssReady = true;

    const id = "wordex-cell-css";
    if (document.getElementById(id)) return;

    const st = document.createElement("style");
    st.id = id;

    st.textContent = `
      /* =========================
         WordexCell - classes utilitárias
         ========================= */

      /* Seleção (compatível com seu padrão sel-cell) */
      td.sel-cell, th.sel-cell{
        outline: 2px solid #22ff22;
        outline-offset: -2px;
      }
    `;

    document.head.appendChild(st);
  }

  /**
   * @param {HTMLTableCellElement} td <td> ou <th>
   */
  constructor(td) {
    TWordexCell.#ensureCss();

    if (!(td instanceof HTMLTableCellElement))
      throw new Error("TWordexCell precisa de um <td> ou <th>.");

    this.#td = td;
  }

  /** Acesso ao elemento real */
  get el() {
    return this.#td;
  }

  // ===== seleção (usa sua classe sel-cell) =====

  get selected() {
    return this.#td.classList.contains("sel-cell");
  }

  set selected(v) {
    this.#td.classList.toggle("sel-cell", !!v);
  }

  // ===== moldura (2 opções: inline ou por classe) =====

  /**
   * Moldura inline (não depende de CSS).
   * @param {string} css ex: "2px solid #22ff22"
   */
  frame(css = "2px solid #22ff22") {
    this.#td.style.outline = css;
    this.#td.style.outlineOffset = "-2px";
  }

  /** Remove moldura inline */
  clearFrame() {
    this.#td.style.outline = "";
    this.#td.style.outlineOffset = "";
  }

  /**
   * Moldura por classe (usa o CSS injetado).
   * Útil se você preferir não mexer em style inline.
   */
  set framed(v) {
    this.#td.classList.toggle("sel-cell", !!v);
  }
  get framed() {
    return this.#td.classList.contains("sel-cell");
  }

  // ===== texto =====

  get text() {
    return this.#td.textContent ?? "";
  }

  set text(v) {
    this.#td.innerHTML = "";
    const s = String(v ?? "");
    if (s === "") this.#td.appendChild(document.createElement("br"));
    else this.#td.appendChild(document.createTextNode(s));
  }

  // ===== alinhamento =====

  /** @param {CellAlign} v */
  set align(v) {
    this.#td.style.textAlign = String(v || "").trim();
  }

  /** @param {CellVAlign} v */
  set vAlign(v) {
    // CSS usa "middle" mesmo, não "center"
    this.#td.style.verticalAlign = String(v || "").trim();
  }

  // ===== spans =====

  /** @param {number} n */
  set colspan(n) {
    const v = Math.max(1, n | 0);
    this.#td.colSpan = v;
    if (v === 1) this.#td.removeAttribute("colspan");
  }

  /** @param {number} n */
  set rowspan(n) {
    const v = Math.max(1, n | 0);
    this.#td.rowSpan = v;
    if (v === 1) this.#td.removeAttribute("rowspan");
  }
}
