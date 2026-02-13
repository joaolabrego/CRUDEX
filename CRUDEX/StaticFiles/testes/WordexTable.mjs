// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

/**
 * @typedef {"titles"|"group"|"detail"|"total"|""} RowKind
 * @typedef {"none"|"table"|"row"} TblSelectionKind
 */

/**
 * Web Component <wordex-tbl>
 * - Light DOM (sem shadow)
 * - Wrapper .rx-tbl-wrap (não editável) + <table> com <td contenteditable>
 * - Tipagem/JSDoc: para o VS Code parar de reclamar
 */
export class TWordexTable extends HTMLElement {
  /** @type {HTMLDivElement} */ #wrap;
  /** @type {HTMLTableElement} */ #tbl;
  /** @type {HTMLTableSectionElement} */ #tbody;

  // ===== CSS encapsulado (1x, escopado) =====
  static #cssReady = false;
  static #ensureCss() {
    if (TWordexTable.#cssReady) return;
    TWordexTable.#cssReady = true;

    const id = "wordex-tbl-css";
    if (document.getElementById(id)) return;

    const st = document.createElement("style");
    st.id = id;

    st.textContent = `
      wordex-tbl {
        display: inline-block;
        margin: 0 4px;
      }

      wordex-tbl .rx-tbl-wrap{
        display: inline-block;
        max-width: 100%;
      }

      wordex-tbl .rx-tbl{
        border-collapse: collapse;
        table-layout: fixed;
        width: auto;
      }

      wordex-tbl .rx-tbl td,
      wordex-tbl .rx-tbl th{
        border: 1px solid #000;
        padding: 4px 6px;
        vertical-align: top;
        min-width: 24px;
        height: 22px;
      }

      wordex-tbl .rx-tbl td[contenteditable="true"]{
        cursor: text;
      }

      wordex-tbl .rx-tbl td > br{
        line-height: 1;
      }

      /* ===== seleção (somente table e row) ===== */
      wordex-tbl .rx-tbl-wrap.sel-table{
        outline: 2px solid #22ff22;
        outline-offset: 2px;
      }

      wordex-tbl .rx-tbl tr.sel-row > td,
      wordex-tbl .rx-tbl tr.sel-row > th{
        outline: 2px solid #22ff22;
        outline-offset: -2px;
      }

      @media print{
        wordex-tbl .rx-tbl-wrap{ break-inside: avoid; }
      }
    `;

    document.head.appendChild(st);
  }

  constructor() {
    super();
    TWordexTable.#ensureCss();

    // NÃO cria/append nada aqui
    /** @type {any} */ (this)._built = false;
  }

  static get observedAttributes() {
    return ["rows", "cols", "items", "border", "radius"];
  }

  connectedCallback() {
    // monta a estrutura 1x aqui (pode ter filhos)
    /** @type {any} */ const self = this;
    if (!self._built) {
      self._built = true;

      this.#wrap = document.createElement("div");
      this.#wrap.className = "rx-tbl-wrap";
      this.#wrap.contentEditable = "false";
      this.#wrap.tabIndex = 0;

      this.#tbl = document.createElement("table");
      this.#tbl.className = "rx-tbl";

      this.#tbody = document.createElement("tbody");

      this.#tbl.appendChild(this.#tbody);
      this.#wrap.appendChild(this.#tbl);

      // limpa qualquer lixo e monta
      this.innerHTML = "";
      this.appendChild(this.#wrap);
    }

    // cria tabela default se não existir conteúdo
    if (!this.#tbody.children.length) {
      const r = parseInt(this.getAttribute("rows") || "0", 10) || 2;
      const c = parseInt(this.getAttribute("cols") || "0", 10) || 2;
      this.create(r, c);
    }

    // aplica atributos
    if (this.hasAttribute("items"))
      this.itemsTag = this.getAttribute("items") || "";
    if (this.hasAttribute("border"))
      this.border = this.getAttribute("border") || "";
    if (this.hasAttribute("radius"))
      this.borderRadius = this.getAttribute("radius") || "";
  }

  /**
   * Reage a mudanças de atributo (HTML → API)
   * @param {string} name
   * @param {string | null} _oldV
   * @param {string | null} newV
   */
  attributeChangedCallback(name, _oldV, newV) {
    /** @type {any} */ const self = this;
    if (!self._built) return;
    switch (name) {
      case "items":
        this.itemsTag = newV || "";
        break;

      case "cols": {
        const c = parseInt(newV || "0", 10) || 0;
        if (c > 0) this.cols = c;
        break;
      }

      case "rows": {
        // rows é “espelho” do estado; não redesenha sozinho pra não destruir conteúdo
        break;
      }

      case "border":
        this.border = newV || "";
        break;

      case "radius":
        this.borderRadius = newV || "";
        break;
    }
  }

  /**
   * Cria (ou recria) a grade.
   * @param {number} rows
   * @param {number} cols
   */
  create(rows, cols) {
    const r = Math.max(1, Math.min(50, Math.round(rows || 1)));
    const c = Math.max(1, Math.min(50, Math.round(cols || 1)));

    this.#tbody.innerHTML = "";
    for (let i = 0; i < r; i++) this.#tbody.appendChild(this.#createRow(c));

    this.cols = c;
    this.#syncAttr("rows", String(r));
    this.#syncAttr("cols", String(c));
  }

  /** Quantidade de colunas (espelhada em data-cols do wrap) */
  /** @returns {number} */
  get cols() {
    const n = parseInt(this.#wrap.dataset.cols || "0", 10);
    return Number.isFinite(n) ? n : 0;
  }

  /** @param {number} v */
  set cols(v) {
    const n = Math.max(1, Math.min(50, Math.round(v || 1)));
    this.#wrap.dataset.cols = String(n);
    this.#syncAttr("cols", String(n));
  }

  /** Quantidade de linhas atuais (tr dentro do tbody) */
  /** @returns {number} */
  get rows() {
    return this.#tbody.querySelectorAll(":scope > tr").length;
  }

  /** Tag de items (data-items + title + attribute) */
  /** @returns {string} */
  get itemsTag() {
    return this.#wrap.dataset.items || "";
  }

  /** @param {string} v */
  set itemsTag(v) {
    const t = (v || "").trim();
    if (!t) {
      delete this.#wrap.dataset.items;
      this.#wrap.removeAttribute("title");
      this.removeAttribute("items");
    } else {
      this.#wrap.dataset.items = t;
      this.#wrap.title = `{{${t}}}`;
      this.setAttribute("items", t);
    }
  }

  /** Borda do WRAP (não das células) */
  /** @returns {string} */
  get border() {
    return (this.#wrap.style.border || "").trim();
  }

  /** @param {string} v */
  set border(v) {
    const b = v === "none" ? "" : v || "";
    this.#wrap.style.border = b;
    this.#syncAttr("border", b);
  }

  /** Raio do WRAP (não das células) */
  /** @returns {string} */
  get borderRadius() {
    return (this.#wrap.style.borderRadius || "").trim();
  }

  /** @param {string} v */
  set borderRadius(v) {
    const r = (v || "").trim();
    this.#wrap.style.borderRadius = r;

    const isZero = r === "" || r === "0" || r === "0px";
    this.#wrap.style.overflow = isZero ? "" : "hidden";

    this.#syncAttr("radius", r);
  }

  /** Seleção da tabela (classe no wrap) */
  /** @returns {boolean} */
  get selected() {
    return this.#wrap.classList.contains("sel-table");
  }

  /** @param {boolean} v */
  set selected(v) {
    this.#wrap.classList.toggle("sel-table", !!v);
  }

  /** Tipo de seleção atual (table/row/none) */
  /** @returns {TblSelectionKind} */
  get selectionKind() {
    if (!this.selected) return "none";
    if (this.#wrap.querySelector("tr.sel-row")) return "row";
    return "table";
  }

  /**
   * Retorna kind da linha (via dataset.kind).
   * @param {number} rowIndex
   * @returns {RowKind}
   */
  getRowKind(rowIndex) {
    const tr = this.#getRow(rowIndex);
    const k = tr?.dataset.kind || "";
    return /** @type {RowKind} */ (k);
  }

  /**
   * Define kind da linha.
   * @param {number} rowIndex
   * @param {RowKind} kind
   */
  setRowKind(rowIndex, kind) {
    const tr = this.#getRow(rowIndex);
    if (!tr) return;
    tr.dataset.kind = kind || "";
  }

  /* =========================
     Helpers privados
     ========================= */

  /**
   * Cria uma linha com N células editáveis.
   * @param {number} cols
   * @returns {HTMLTableRowElement}
   */
  #createRow(cols) {
    const tr = document.createElement("tr");
    tr.dataset.kind = "detail";

    for (let c = 0; c < cols; c++) {
      const td = document.createElement("td");
      td.contentEditable = "true";
      td.appendChild(document.createElement("br"));
      tr.appendChild(td);
    }
    return tr;
  }

  /**
   * Retorna a <tr> pelo índice.
   * @param {number} i
   * @returns {HTMLTableRowElement|null}
   */
  #getRow(i) {
    const rows = this.#tbody.querySelectorAll(":scope > tr");
    const tr = rows[i] || null;
    return tr instanceof HTMLTableRowElement ? tr : null;
  }

  /**
   * Mantém atributo HTML sincronizado com estado interno.
   * @param {string} name
   * @param {unknown} v
   */
  #syncAttr(name, v) {
    const sv = (v ?? "").toString().trim();
    if (sv === "") {
      if (this.hasAttribute(name)) this.removeAttribute(name);
      return;
    }
    if (this.getAttribute(name) !== sv) this.setAttribute(name, sv);
  }
}

customElements.define("wordex-tbl", TWordexTable);
