// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

/**
 * Tipos (contratos) usados pelos wrappers do Wordex.
 *
 * ParagraphAlign: valores aceitos por CSS text-align.
 * TblOnlyAlign: alinhamento do parágrafo “exclusivo de tabela” (flex justify-content).
 * ImgWrap: estados de wrap (classes wrap-inline/left/right).
 * RowKind: classificação semântica de linhas da tabela.
 * TblSelectionKind: tipo de seleção atual (espelhada via classes sel-*).
 *
 * @typedef {"left"|"center"|"right"|"justify"|"start"|"end"} ParagraphAlign
 * @typedef {"left"|"center"|"right"} TblOnlyAlign
 * @typedef {"inline"|"left"|"right"} ImgWrap
 * @typedef {"titles"|"group"|"detail"|"total"|""} RowKind
 * @typedef {"none"|"table"|"row"|"col"|"cell"} TblSelectionKind
 */

/**
 * Web Component: <wordex-p>
 *
 * Estrutura interna (SEM Shadow DOM):
 *   <wordex-p>
 *     <p> ...conteúdo... </p>
 *   </wordex-p>
 *
 * Objetivo:
 * - light DOM, compatível com seu editor/seleção
 * - API por propriedades (align, border, borderRadius, tableOnlyAlign...)
 * - helpers para consultar imagens/tabelas existentes dentro do parágrafo
 * - NÃO mantém estado paralelo: lê/escreve no DOM
 * - injeta CSS 1x no <head>, escopado em "wordex-p > p"
 */
export class TWordexParagraph extends HTMLElement {
  /** @type {HTMLParagraphElement} */
  #p;

  /** injeta CSS uma vez (escopado em wordex-p > p) */
  static #cssReady = false;
  static #ensureCss() {
    if (TWordexParagraph.#cssReady) return;
    TWordexParagraph.#cssReady = true;

    const id = "wordex-p-css";
    if (document.getElementById(id)) return;

    const st = document.createElement("style");
    st.id = id;

    st.textContent = `
      wordex-p > p {
        margin: 0 0 6px 0;
      }

      /* ===== PARÁGRAFO EXCLUSIVO DA TABELA ===== */
      wordex-p > p.rx-tbl-only {
        display: flex;
        margin: 0 0 6px 0;
      }
      wordex-p > p.rx-tbl-only.left  { justify-content: flex-start; }
      wordex-p > p.rx-tbl-only.center{ justify-content: center; }
      wordex-p > p.rx-tbl-only.right { justify-content: flex-end; }
      wordex-p > p.rx-tbl-only > br { display: none; }
    `;
    document.head.appendChild(st);
  }

  constructor() {
    super();

    // cria o <p> real
    this.#p = document.createElement("p");

    // hospeda no light DOM
    this.appendChild(this.#p);

    // CSS escopado (1x)
    TWordexParagraph.#ensureCss();
  }

  /** @returns {string[]} */
  static get observedAttributes() {
    return [
      "align",
      "space-after",
      "border",
      "radius",
      "tbl-only",
      "tbl-align",
    ];
  }

  /**
   * Ao entrar no DOM:
   * - move qualquer child que o usuário tenha colocado direto em <wordex-p> pra dentro do <p>
   * - aplica atributos como estado inicial
   */
  connectedCallback() {
    // move tudo que não seja o próprio <p> para dentro do <p>
    /** @type {ChildNode[]} */
    const toMove = [];
    for (const n of Array.from(this.childNodes)) {
      if (n === this.#p) continue;
      toMove.push(n);
    }
    toMove.forEach((n) => this.#p.appendChild(n));

    if (this.hasAttribute("align"))
      this.align = /** @type {ParagraphAlign} */ (
        this.getAttribute("align") || "left"
      );

    if (this.hasAttribute("space-after"))
      this.spaceAfterPx =
        parseInt(this.getAttribute("space-after") || "0", 10) || 0;

    if (this.hasAttribute("border"))
      this.border = this.getAttribute("border") || "";

    if (this.hasAttribute("radius"))
      this.borderRadius = this.getAttribute("radius") || "";

    if (this.hasAttribute("tbl-only")) this.isTableOnly = true;

    if (this.hasAttribute("tbl-align"))
      this.tableOnlyAlign = /** @type {TblOnlyAlign} */ (
        this.getAttribute("tbl-align") || "left"
      );
  }

  /**
   * @param {string} name
   * @param {string|null} _oldV
   * @param {string|null} newV
   */
  attributeChangedCallback(name, _oldV, newV) {
    if (name === "align")
      this.align = /** @type {ParagraphAlign} */ ((newV || "left").trim());

    if (name === "space-after")
      this.spaceAfterPx = parseInt(newV || "0", 10) || 0;

    if (name === "border") this.border = newV || "";

    if (name === "radius") this.borderRadius = newV || "";

    if (name === "tbl-only") this.isTableOnly = newV != null;

    if (name === "tbl-align")
      this.tableOnlyAlign = /** @type {TblOnlyAlign} */ (
        (newV || "left").trim()
      );
  }

  // ========= helpers privados =========

  /**
   * Normaliza valor CSS.
   * @param {string|null} v
   * @returns {string}
   */
  #normCss(v) {
    if (!v) return "";
    return String(v).trim();
  }

  /**
   * Faz parse de px com fallback.
   * @param {string|null} v
   * @param {number} fallback
   * @returns {number}
   */
  #parsePx(v, fallback = 0) {
    const s = String(v || "").trim();
    if (!s) return fallback;
    if (s.endsWith("px")) return parseFloat(s);
    const n = Number(s);
    return Number.isFinite(n) ? n : fallback;
  }

  /**
   * Sincroniza atributo evitando setAttribute redundante.
   * @param {string} name
   * @param {string} v
   */
  #syncAttr(name, v) {
    const sv = (v ?? "").toString().trim();
    if (sv === "") {
      if (this.hasAttribute(name)) this.removeAttribute(name);
      return;
    }
    if (this.getAttribute(name) !== sv) this.setAttribute(name, sv);
  }

  /**
   * Lista imagens "legadas" (img.rx-img) e imagens dentro de wordex-img.
   * @returns {HTMLImageElement[]}
   */
  #imgs() {
    return Array.from(
      this.#p.querySelectorAll("img.rx-img, wordex-img img.rx-img"),
    );
  }

  /**
   * Lista wrappers de tabela (legado e dentro de wordex-tbl).
   * @returns {HTMLDivElement[]}
   */
  #tbls() {
    return Array.from(
      this.#p.querySelectorAll("div.rx-tbl-wrap, wordex-tbl div.rx-tbl-wrap"),
    );
  }

  // ========= acesso ao <p> real =========

  /** @returns {HTMLParagraphElement} */
  get el() {
    return this.#p;
  }

  // ========= Parágrafo =========

  /** @returns {ParagraphAlign} */
  get align() {
    // @ts-expect-error - textAlign pode retornar string vazia, mas garantimos fallback para "left"
    const v = (this.#p.style.textAlign || "").trim();
    return v || "left";
  }

  /** @param {ParagraphAlign} value */
  set align(value) {
    const v = (value || "").trim();
    this.#p.style.textAlign = v;
    this.#syncAttr("align", v);
  }

  /** @returns {number} */
  get spaceAfterPx() {
    return this.#parsePx(this.#p.style.marginBottom, 0);
  }

  /** @param {number} px */
  set spaceAfterPx(px) {
    const n = Math.max(0, Math.round(px || 0));
    this.#p.style.marginBottom = n ? `${n}px` : "";
    this.#syncAttr("space-after", n ? String(n) : "");
  }

  /** @returns {string} */
  get border() {
    return this.#normCss(this.#p.style.border);
  }

  /** @param {string} cssBorder */
  set border(cssBorder) {
    const b = cssBorder === "none" ? "" : cssBorder || "";
    this.#p.style.border = b;
    this.#syncAttr("border", b);
  }

  /** @returns {string} */
  get borderRadius() {
    return this.#normCss(this.#p.style.borderRadius);
  }

  /** @param {string} radius */
  set borderRadius(radius) {
    const r = (radius || "").trim();
    this.#p.style.borderRadius = r;

    const isZero = r === "" || r === "0" || r === "0px";
    this.#p.style.overflow = isZero ? "" : "hidden";

    // se r == "" remove, senão grava
    this.#syncAttr("radius", r);
  }

  /** @returns {boolean} */
  get isTableOnly() {
    return this.#p.classList.contains("rx-tbl-only");
  }

  /** @param {boolean} v */
  set isTableOnly(v) {
    this.#p.classList.toggle("rx-tbl-only", !!v);

    if (v) {
      this.setAttribute("tbl-only", "");

      // remove <br> direto do p (igual seu CSS espera)
      this.#p.querySelectorAll(":scope > br").forEach((b) => b.remove());

      if (
        !this.#p.classList.contains("left") &&
        !this.#p.classList.contains("center") &&
        !this.#p.classList.contains("right")
      ) {
        this.#p.classList.add("left");
      }
    } else {
      this.removeAttribute("tbl-only");
      this.#p.classList.remove("left", "center", "right");
      this.removeAttribute("tbl-align");
    }
  }

  /** @returns {TblOnlyAlign} */
  get tableOnlyAlign() {
    if (this.#p.classList.contains("center")) return "center";
    if (this.#p.classList.contains("right")) return "right";
    return "left";
  }

  /** @param {TblOnlyAlign} value */
  set tableOnlyAlign(value) {
    const v = (value || "left").trim();
    this.#p.classList.remove("left", "center", "right");
    this.#p.classList.add(v);
    this.#syncAttr("tbl-align", v);
  }

  /** @returns {boolean} */
  get containsFloat() {
    return !!this.#p.querySelector(".rx-img.wrap-left, .rx-img.wrap-right");
  }

  // ========= Imagens =========

  /** @returns {number} */
  get imageCount() {
    return this.#imgs().length;
  }

  /**
   * Retorna metadados das imagens presentes no parágrafo.
   * @returns {{el:HTMLImageElement, tag:string, wrap:ImgWrap, widthPx:number, src:string}[]}
   */
  get images() {
    return this.#imgs().map((img) => {
      const wrap = img.dataset.wrap;
      const wwrap =
        wrap === "left" || wrap === "right" || wrap === "inline"
          ? wrap
          : "inline";

      const iw = (img.style.getPropertyValue("--iw") || "").trim();
      const w = iw.endsWith("px")
        ? parseFloat(iw)
        : Math.round(img.getBoundingClientRect().width);

      return {
        el: img,
        tag: img.dataset.img || "",
        wrap: wwrap,
        widthPx: Number.isFinite(w) ? w : 80,
        src: img.currentSrc || img.src || "",
      };
    });
  }

  /**
   * Lê tag (dataset.img) de uma imagem.
   * @param {HTMLImageElement} img
   * @returns {string}
   */
  getImgTag(img) {
    return img?.dataset?.img || "";
  }

  /**
   * Define tag (dataset.img) + title.
   * @param {HTMLImageElement} img
   * @param {string} tag
   */
  setImgTag(img, tag) {
    if (!img) return;
    const t = (tag || "").trim();
    if (!t) {
      delete img.dataset.img;
      img.removeAttribute("title");
    } else {
      img.dataset.img = t;
      img.title = `{{${t}}}`;
    }
  }

  /**
   * Lê wrap (dataset.wrap) de uma imagem.
   * @param {HTMLImageElement} img
   * @returns {ImgWrap}
   */
  getImgWrap(img) {
    const w = img?.dataset?.wrap || "inline";
    return w === "left" || w === "right" || w === "inline" ? w : "inline";
  }

  /**
   * Define wrap: ajusta classes wrap-* e dataset.wrap.
   * @param {HTMLImageElement} img
   * @param {ImgWrap} wrap
   */
  setImgWrap(img, wrap) {
    if (!img) return;
    const w =
      wrap === "left" || wrap === "right" || wrap === "inline"
        ? wrap
        : "inline";
    img.classList.remove("wrap-left", "wrap-right", "wrap-inline");
    img.classList.add(`wrap-${w}`);
    img.dataset.wrap = w;
  }

  /**
   * Lê largura atual (px) de uma imagem.
   * @param {HTMLImageElement} img
   * @returns {number}
   */
  getImgWidthPx(img) {
    if (!img) return 0;
    const cur = (img.style.getPropertyValue("--iw") || "").trim();
    if (cur.endsWith("px")) return parseFloat(cur);
    return Math.round(img.getBoundingClientRect().width);
  }

  /**
   * Define largura (px) usando CSS var --iw.
   * @param {HTMLImageElement} img
   * @param {number} px
   */
  setImgWidthPx(img, px) {
    if (!img) return;
    const w = Math.max(20, Math.round(px || 0));
    img.style.setProperty("--iw", `${w}px`);
  }

  // ========= Tabelas =========

  /** @returns {number} */
  get tableCount() {
    return this.#tbls().length;
  }

  /**
   * Retorna metadados das tabelas presentes no parágrafo.
   * @returns {{el:HTMLDivElement, itemsTag:string, cols:number, rowKinds:RowKind[]}[]}
   */
  get tables() {
    return this.#tbls().map((wrap) => {
      const cols = parseInt(wrap.dataset.cols || "0", 10) || 0;

      const rowKinds = Array.from(wrap.querySelectorAll("tr")).map((tr) => {
        const k = tr.dataset.kind || "";
        return k === "titles" ||
          k === "group" ||
          k === "detail" ||
          k === "total" ||
          k === ""
          ? k
          : "";
      });

      return { el: wrap, itemsTag: wrap.dataset.items || "", cols, rowKinds };
    });
  }

  /**
   * Lê items tag (dataset.items) do wrapper da tabela.
   * @param {HTMLDivElement} tblWrap
   * @returns {string}
   */
  getTblItemsTag(tblWrap) {
    return tblWrap?.dataset?.items || "";
  }

  /**
   * Define items tag (dataset.items) + title.
   * @param {HTMLDivElement} tblWrap
   * @param {string} tag
   */
  setTblItemsTag(tblWrap, tag) {
    if (!tblWrap) return;
    const t = (tag || "").trim();
    if (!t) {
      delete tblWrap.dataset.items;
      tblWrap.removeAttribute("title");
    } else {
      tblWrap.dataset.items = t;
      tblWrap.title = `{{${t}}}`;
    }
  }

  /**
   * Lê número de colunas (dataset.cols) do wrapper.
   * @param {HTMLDivElement} tblWrap
   * @returns {number}
   */
  getTblCols(tblWrap) {
    const n = parseInt(tblWrap?.dataset?.cols || "0", 10);
    return Number.isFinite(n) ? n : 0;
  }

  /**
   * Lê o kind de uma linha.
   * @param {HTMLTableRowElement} tr
   * @returns {RowKind}
   */
  getRowKind(tr) {
    const k = tr?.dataset?.kind || "";
    return k === "titles" ||
      k === "group" ||
      k === "detail" ||
      k === "total" ||
      k === ""
      ? k
      : "";
  }

  /**
   * Define o kind de uma linha.
   * @param {HTMLTableRowElement} tr
   * @param {RowKind} kind
   */
  setRowKind(tr, kind) {
    if (!tr) return;
    tr.dataset.kind = kind || "";
  }

  // ========= Seleção de tabela (espelhada por classes) =========

  /** @returns {TblSelectionKind} */
  get tblSelectionKind() {
    const wrap = this.#p.querySelector(".rx-tbl-wrap.sel-table");
    if (!wrap) return "none";
    if (wrap.querySelector("td.sel-cell")) return "cell";
    if (wrap.querySelector("tr.sel-row")) return "row";
    if (wrap.querySelector("td.sel-col")) return "col";
    return "table";
  }

  /** @returns {HTMLDivElement|null} */
  get selectedTable() {
    return this.#p.querySelector(".rx-tbl-wrap.sel-table") || null;
  }

  /** @returns {HTMLTableRowElement|null} */
  get selectedRow() {
    return this.#p.querySelector("tr.sel-row") || null;
  }

  /** @returns {HTMLTableCellElement|null} */
  get selectedCell() {
    return this.#p.querySelector("td.sel-cell") || null;
  }

  /** @returns {number|null} */
  get selectedColIndex() {
    const td = /** @type {HTMLTableCellElement|null} */ (
      this.#p.querySelector("td.sel-col")
    );
    return td ? td.cellIndex : null;
  }
}

customElements.define("wordex-p", TWordexParagraph);
