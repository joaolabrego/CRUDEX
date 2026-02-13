// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

import { TWordexRow } from "./WordexRow.mjs";
import { TWordexColumn } from "./WordexColumn.mjs";
import { TWordexCell } from "./WordexCell.mjs";

/* =============================================================================
   CSS (1x) — seleção/moldura padrão do Wordex
   - Mantém o visual quando você marca classes (sel-table/sel-row/sel-col/sel-cell)
   - Não interfere se você aplicar moldura via style inline (frame()).
   ========================================================================== */

let __wordex_css_ready = false;

function __ensureWordexCss() {
  if (__wordex_css_ready) return;
  __wordex_css_ready = true;

  const id = "wordex-core-css";
  if (document.getElementById(id)) return;

  const st = document.createElement("style");
  st.id = id;

  st.textContent = `
    /* =========================
       Wordex - seleção visual
       ========================= */

    /* Tabela selecionada (classe no wrapper) */
    .rx-tbl-wrap.sel-table{
      outline: 2px solid #22ff22;
      outline-offset: 2px;
    }

    /* Linha selecionada (classe no TR) */
    tr.sel-row > td,
    tr.sel-row > th{
      outline: 2px solid #22ff22;
      outline-offset: -2px;
    }

    /* Coluna selecionada (classe na célula) */
    td.sel-col,
    th.sel-col{
      outline: 2px solid #22ff22;
      outline-offset: -2px;
    }

    /* Célula selecionada (classe na célula) */
    td.sel-cell,
    th.sel-cell{
      outline: 2px solid #22ff22;
      outline-offset: -2px;
    }
  `;

  document.head.appendChild(st);
}

/* =============================================================================
   WordexSelection — estado do que está “ativo” no editor
   - Mantém referências diretas (sem duplicar DOM).
   ========================================================================== */

/**
 * Estado de seleção do TWordex.
 * Mantém “o que está ativo” no editor (sem duplicar DOM).
 */
class WordexSelection {
  /** @type {HTMLElement|null} */ paragraph = null; // <p> ou <wordex-p>
  /** @type {HTMLImageElement|null} */ image = null; // <img>

  /** @type {HTMLElement|null} */ tblWrap = null; // span/div.rx-tbl-wrap
  /** @type {HTMLTableElement|null} */ table = null;
  /** @type {HTMLTableRowElement|null} */ row = null;
  /** @type {HTMLTableCellElement|null} */ cell = null;
  /** @type {number|null} */ colIndex = null; // índice de coluna selecionada (cellIndex)

  clear() {
    this.paragraph = null;
    this.image = null;
    this.tblWrap = null;
    this.table = null;
    this.row = null;
    this.cell = null;
    this.colIndex = null;
  }
}

/* =============================================================================
   TWordex — orquestrador
   - Centraliza seleção + comandos chamados por toolbar/botões.
   - Captura clique/foco pra manter estado consistente.
   ========================================================================== */

/** @typedef {"table"|"row"|"column"|"cell"} TblSelectionLevel */

export class TWordex {
  /** @type {HTMLElement} */ #root;
  /** @type {WordexSelection} */ #sel = new WordexSelection();
  /** @type {HTMLElement|null} */ #modePill = null;
  /** @type {HTMLElement|null} */ #modeText = null;
  /** @type {number} */ #maxHeaderFooterParagraphs = 10;
  /** @type {HTMLElement|null} */ #lastTblWrap = null;
  /** @type {TblSelectionLevel} */ #lastTblSelectionKind = "table";

  /**
   * @param {HTMLElement|{stage: HTMLElement, modePill?: HTMLElement|null, modeText?: HTMLElement|null, maxHeaderFooterParagraphs?: number}} config
   */
  constructor(config) {
    let root;

    // Suporta tanto objeto de configuração quanto HTMLElement direto
    if (config instanceof HTMLElement) {
      root = config;
    } else if (config && config.stage instanceof HTMLElement) {
      root = config.stage;
      this.#modePill = config.modePill || null;
      this.#modeText = config.modeText || null;
      this.#maxHeaderFooterParagraphs = config.maxHeaderFooterParagraphs || 10;
    } else {
      throw new Error(
        "TWordex: root inválido. Espera HTMLElement ou objeto com propriedade 'stage'.",
      );
    }

    if (!(root instanceof HTMLElement))
      throw new Error("TWordex: root inválido.");
    this.#root = root;

    // Garante CSS base (1x)
    __ensureWordexCss();

    // listeners básicos de seleção (captura clique/foco antes do restante do app)
    this.#root.addEventListener("mousedown", (e) => this.#onPointer(e), true);
    this.#root.addEventListener("focusin", (e) => this.#onFocus(e), true);
  }

  /**
   * Inicializa o editor Wordex
   */
  init() {
    // Inicialização básica - pode ser expandida conforme necessário
    // Por enquanto, apenas garante que os listeners estão ativos
    if (this.#modeText) {
      this.#modeText.textContent = "INS";
    }
  }

  // ========= seleção (pública) =========

  /** Estado atual (read-only do ponto de vista estrutural) */
  get selection() {
    return this.#sel;
  }

  /**
   * Limpa classes de seleção padrão (sel-*) no DOM
   * (não mexe em outline inline aplicado por frame()).
   */
  clearDomSelection() {
    // tabela
    this.#root
      .querySelectorAll(".rx-tbl-wrap.sel-table")
      .forEach((x) => x.classList.remove("sel-table"));

    // linha
    this.#root
      .querySelectorAll("tr.sel-row")
      .forEach((x) => x.classList.remove("sel-row"));

    // coluna/célula
    this.#root
      .querySelectorAll("td.sel-col,th.sel-col,td.sel-cell,th.sel-cell")
      .forEach((x) => x.classList.remove("sel-col", "sel-cell"));
  }

  // ========= seleção explícita =========

  /**
   * Seleciona explicitamente uma célula (e marca classes no DOM).
   * @param {HTMLTableCellElement} td
   * @returns {boolean}
   */
  selectCell(td) {
    if (!(td instanceof HTMLTableCellElement)) return false;

    const tr = td.closest("tr");
    const tbl = td.closest("table");
    const wrap = td.closest(".rx-tbl-wrap");

    if (!(tr instanceof HTMLTableRowElement)) return false;
    if (!(tbl instanceof HTMLTableElement)) return false;
    if (!(wrap instanceof HTMLElement)) return false;

    this.clearDomSelection();
    this.#sel.clear();

    wrap.classList.add("sel-table");
    td.classList.add("sel-cell");

    this.#sel.tblWrap = wrap;
    this.#sel.table = tbl;
    this.#sel.row = tr;
    this.#sel.cell = td;

    // cellIndex é ok para tabela simples (sem colspan/rowspan pesados)
    this.#sel.colIndex = td.cellIndex;

    return true;
  }

  /**
   * Seleciona explicitamente uma linha.
   * @param {HTMLTableRowElement} tr
   * @returns {boolean}
   */
  selectRow(tr) {
    if (!(tr instanceof HTMLTableRowElement)) return false;

    const tbl = tr.closest("table");
    const wrap = tr.closest(".rx-tbl-wrap");

    if (!(tbl instanceof HTMLTableElement)) return false;
    // ✅ CORREÇÃO: wrapper pode ser <span> ou <div>
    if (!(wrap instanceof HTMLElement)) return false;

    this.clearDomSelection();
    this.#sel.clear();

    wrap.classList.add("sel-table");
    tr.classList.add("sel-row");

    this.#sel.tblWrap = wrap;
    this.#sel.table = tbl;
    this.#sel.row = tr;

    return true;
  }

  /**
   * Seleciona uma “coluna” por índice (marca sel-col em cada célula).
   * @param {HTMLTableElement} table
   * @param {number} colIndex
   * @returns {boolean}
   */
  selectColumn(table, colIndex) {
    if (!(table instanceof HTMLTableElement)) return false;

    const wrap = table.closest(".rx-tbl-wrap");
    // ✅ CORREÇÃO: wrapper pode ser <span> ou <div>
    if (!(wrap instanceof HTMLElement)) return false;

    this.clearDomSelection();
    this.#sel.clear();

    wrap.classList.add("sel-table");

    const col = new TWordexColumn(table, colIndex);
    col.selected = true;

    this.#sel.tblWrap = wrap;
    this.#sel.table = table;
    this.#sel.colIndex = colIndex;

    return true;
  }

  // ========= comandos (para botões) =========

  /**
   * Aplica moldura na seleção atual (cell > row > col > table).
   * @param {string} css ex: "2px solid #22ff22"
   * @returns {boolean}
   */
  frameSelection(css = "2px solid #22ff22") {
    const s = this.#sel;

    if (s.cell) {
      try {
        new TWordexCell(s.cell).frame(css);
      } catch {
        s.cell.style.outline = css;
        s.cell.style.outlineOffset = "-2px";
      }
      return true;
    }

    if (s.row) {
      new TWordexRow(s.row).frame(css);
      return true;
    }

    if (s.table && s.colIndex != null) {
      new TWordexColumn(s.table, s.colIndex).frame(css);
      return true;
    }

    if (s.tblWrap) {
      s.tblWrap.style.outline = css;
      s.tblWrap.style.outlineOffset = "2px";
      return true;
    }

    return false;
  }

  /**
   * Remove moldura inline da seleção atual (cell > row > col > table).
   * @returns {boolean}
   */
  clearFrameSelection() {
    const s = this.#sel;

    if (s.cell) {
      try {
        new TWordexCell(s.cell).clearFrame();
      } catch {
        s.cell.style.outline = "";
        s.cell.style.outlineOffset = "";
      }
      return true;
    }

    if (s.row) {
      new TWordexRow(s.row).clearFrame();
      return true;
    }

    if (s.table && s.colIndex != null) {
      new TWordexColumn(s.table, s.colIndex).clearFrame();
      return true;
    }

    if (s.tblWrap) {
      s.tblWrap.style.outline = "";
      s.tblWrap.style.outlineOffset = "";
      return true;
    }

    return false;
  }

  /**
   * Alinha conteúdo da seleção (cell/row/col)
   * @param {"left"|"center"|"right"|"justify"|""|null|undefined} hAlign
   * @param {"top"|"middle"|"bottom"|""|null|undefined} vAlign
   */
  alignSelection(hAlign, vAlign) {
    const s = this.#sel;

    if (s.cell) {
      if (hAlign) s.cell.style.textAlign = hAlign;
      if (vAlign) s.cell.style.verticalAlign = vAlign;
      return true;
    }

    if (s.row) {
      const r = new TWordexRow(s.row);
      if (hAlign) r.align = hAlign;
      if (vAlign) r.vAlign = vAlign;
      return true;
    }

    if (s.table && s.colIndex != null) {
      const c = new TWordexColumn(s.table, s.colIndex);
      if (hAlign) c.align = hAlign;
      if (vAlign) c.vAlign = vAlign;
      return true;
    }

    return false;
  }

  // ========= captura de seleção =========

  /**
   * Captura clique/ponteiro e decide “o que foi selecionado”.
   * @param {Event} e
   */
  #onPointer(e) {
    const t = e.target instanceof HTMLElement ? e.target : null;
    if (!t) return;

    const isCtrl = e instanceof MouseEvent && e.ctrlKey;
    const wrap = t.closest(".rx-tbl-wrap");
    const tr = t.closest("tr");
    const td = t.closest("td,th");
    const table = wrap?.querySelector("table");

    if (isCtrl && wrap && table instanceof HTMLTableElement) {
      const sameTable = wrap === this.#lastTblWrap;
      const comingFromCell = this.#lastTblSelectionKind === "cell";

      if (!sameTable || comingFromCell) {
        this.clearDomSelection();
        this.#sel.clear();
        wrap.classList.add("sel-table");
        this.#sel.tblWrap = wrap;
        this.#sel.table = table;
        this.#lastTblWrap = wrap;
        this.#lastTblSelectionKind = "table";
        this.#moveFocusOutOfTable(wrap);
        return;
      }

      if (this.#lastTblSelectionKind === "table") {
        if (tr instanceof HTMLTableRowElement) {
          this.selectRow(tr);
          this.#lastTblSelectionKind = "row";
          this.#moveFocusOutOfTable(wrap);
        }
        return;
      }
      if (this.#lastTblSelectionKind === "row") {
        if (td instanceof HTMLTableCellElement) {
          this.selectColumn(table, td.cellIndex);
          this.#lastTblSelectionKind = "column";
          this.#moveFocusOutOfTable(wrap);
        }
        return;
      }
      if (this.#lastTblSelectionKind === "column") {
        this.clearDomSelection();
        this.#sel.clear();
        wrap.classList.add("sel-table");
        this.#sel.tblWrap = wrap;
        this.#sel.table = table;
        this.#lastTblSelectionKind = "table";
        this.#moveFocusOutOfTable(wrap);
      }
      return;
    }

    if (td instanceof HTMLTableCellElement) {
      this.selectCell(td);
      this.#lastTblWrap = td.closest(".rx-tbl-wrap");
      this.#lastTblSelectionKind = "cell";
      return;
    }

    if (wrap instanceof HTMLElement) {
      this.clearDomSelection();
      this.#sel.clear();
      wrap.classList.add("sel-table");
      this.#sel.tblWrap = wrap;
      const tbl = wrap.querySelector("table");
      if (tbl instanceof HTMLTableElement) this.#sel.table = tbl;
      this.#moveFocusOutOfTable(wrap);
      return;
    }

    // imagem
    const img = t.closest("img");
    if (img instanceof HTMLImageElement) {
      this.clearDomSelection();
      this.#sel.clear();
      this.#sel.image = img;
      return;
    }

    // parágrafo
    const p = t.closest("wordex-p, p");
    if (p instanceof HTMLElement) {
      this.clearDomSelection();
      this.#sel.clear();
      this.#sel.paragraph = p;
      return;
    }
  }

  /**
   * Tira o cursor da tabela: se o foco estiver dentro do wrap, move para o stage.
   * @param {HTMLElement} wrap
   */
  #moveFocusOutOfTable(wrap) {
    const active = document.activeElement;
    if (!(active instanceof Node) || !wrap.contains(active)) return;
    // @ts-expect-error - blur pode não existir em todos os elementos, mas é seguro usar optional chaining
    active.blur?.();
    this.#root.tabIndex = -1;
    this.#root.focus({ preventScroll: true });
    const sel = window.getSelection();
    if (sel) sel.removeAllRanges();
  }

  /**
   * Captura foco (quando td fica focável/editável) e sincroniza seleção.
   * @param {FocusEvent} e
   */
  #onFocus(e) {
    const t = e.target;
    if (!(t instanceof HTMLElement)) return;

    const td = t.closest("td,th");
    if (td instanceof HTMLTableCellElement) this.selectCell(td);
  }
}
