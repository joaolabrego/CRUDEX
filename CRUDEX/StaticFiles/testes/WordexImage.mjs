// Comentário abaixo ativa o TypeScript “por trás” no VS Code, sem virar TypeScript.
// Ele passa a validar seus JSDoc (@param, @returns, @typedef etc.) e apontar erros.
// @ts-check
"use strict";

/**
 * Estados de wrap/float da imagem.
 * - inline: imagem no fluxo normal do texto
 * - left  : float left (texto contorna à direita)
 * - right : float right (texto contorna à esquerda)
 *
 * @typedef {"inline"|"left"|"right"} ImgWrap
 */

/**
 * Web Component <wordex-img>
 *
 * - Usa Shadow DOM apenas para a imagem interna
 * - O FLOAT é aplicado no :host (obrigatório para contorno funcionar)
 * - Não interfere no texto externo
 */
export class TWordexImage extends HTMLElement {
  /** @type {ShadowRoot} */
  #root;

  /** @type {HTMLImageElement} */
  #img;

  constructor() {
    super();

    this.#root = this.attachShadow({ mode: "open" });

    const style = document.createElement("style");
    style.textContent = `
      :host {
        display: inline-block;
        vertical-align: baseline;
        max-width: 100%;
        width: var(--iw, 80px);
      }

      /* wrap/float no HOST */
      :host([wrap="left"])  { float: left;  margin: 0 10px 6px 0; display: block; }
      :host([wrap="right"]) { float: right; margin: 0 0 6px 10px; display: block; }
      :host([wrap="inline"]),
      :host(:not([wrap])) { float: none; margin: 0; display: inline-block; }

      /* seleção visual */
      :host([selected]) {
        outline: 2px solid rgba(57, 255, 20, 0.85);
        outline-offset: 2px;
      }

      img {
        display: block;
        width: 100%;
        height: auto;
        border: none;
        border-radius: 0;
      }
    `;

    this.#img = document.createElement("img");
    this.#root.append(style, this.#img);
  }

  /** @returns {string[]} */
  static get observedAttributes() {
    return [
      "src",
      "alt",
      "wrap",
      "width",
      "img",
      "border",
      "radius",
      "selected",
    ];
  }

  /** Called when inserted in DOM */
  connectedCallback() {
    // defaults
    if (!this.hasAttribute("wrap")) this.wrap = "inline";
    if (!this.hasAttribute("width")) this.widthPx = 80;

    // sincroniza atributos existentes
    if (this.hasAttribute("src")) this.src = this.getAttribute("src") || "";
    if (this.hasAttribute("alt")) this.alt = this.getAttribute("alt") || "";
    if (this.hasAttribute("wrap"))
      this.wrap = this.#normalizeWrap(this.getAttribute("wrap"));
    if (this.hasAttribute("width"))
      this.widthPx = parseInt(this.getAttribute("width") || "80", 10) || 80;
    if (this.hasAttribute("img")) this.tag = this.getAttribute("img") || "";
    if (this.hasAttribute("border"))
      this.border = this.getAttribute("border") || "";
    if (this.hasAttribute("radius"))
      this.borderRadius = this.getAttribute("radius") || "";
    if (this.hasAttribute("selected")) this.selected = true;
  }

  /**
   * Reage a mudanças de atributo (HTML → API)
   * @param {string} name
   * @param {string|null} _oldV
   * @param {string|null} newV
   */
  attributeChangedCallback(name, _oldV, newV) {
    switch (name) {
      case "src":
        if (this.#img.src !== (newV || "")) this.src = newV || "";
        break;
      case "alt":
        this.alt = newV || "";
        break;
      case "wrap":
        this.wrap = this.#normalizeWrap(newV);
        break;
      case "width": {
        const w = parseInt(newV || "0", 10);
        if (w > 0) this.widthPx = w;
        break;
      }
      case "img":
        this.tag = newV || "";
        break;
      case "border":
        this.border = newV || "";
        break;
      case "radius":
        this.borderRadius = newV || "";
        break;
      case "selected":
        this.selected = newV != null;
        break;
    }
  }

  /* =========================
     API pública
     ========================= */

  /** @returns {string} */
  get tag() {
    return this.getAttribute("img") || "";
  }

  /** @param {string} v */
  set tag(v) {
    const t = (v || "").trim();
    if (!t) {
      this.removeAttribute("img");
      this.removeAttribute("title");
    } else {
      this.#syncAttr("img", t);
      this.title = `{{${t}}}`;
    }
  }

  /** @returns {ImgWrap} */
  get wrap() {
    return this.#normalizeWrap(this.getAttribute("wrap"));
  }

  /** @param {ImgWrap} v */
  set wrap(v) {
    this.#syncAttr("wrap", this.#normalizeWrap(v));
  }

  /** @returns {number} */
  get widthPx() {
    const cur = this.style.getPropertyValue("--iw");
    if (cur.endsWith("px")) return parseFloat(cur) || 80;
    return 80;
  }

  /** @param {number} px */
  set widthPx(px) {
    const w = Math.max(20, Math.round(px || 0));
    this.style.setProperty("--iw", `${w}px`);
    this.#syncAttr("width", String(w));
  }

  /** @returns {string} */
  get src() {
    return this.#img.src || "";
  }

  /** @param {string} v */
  set src(v) {
    const s = v || "";
    this.#img.src = s;
    if (s) this.#syncAttr("src", s);
    else this.removeAttribute("src");
  }

  /** @returns {string} */
  get alt() {
    return this.#img.alt || "";
  }

  /** @param {string} v */
  set alt(v) {
    const a = v || "";
    this.#img.alt = a;
    if (a) this.#syncAttr("alt", a);
    else this.removeAttribute("alt");
  }

  /** @returns {string} */
  get border() {
    return (this.style.border || "").trim();
  }

  /** @param {string} v */
  set border(v) {
    const b = v === "none" ? "" : v || "";
    this.style.border = b;
    if (b) this.#syncAttr("border", b);
    else this.removeAttribute("border");
  }

  /** @returns {string} */
  get borderRadius() {
    return (this.style.borderRadius || "").trim();
  }

  /** @param {string} v */
  set borderRadius(v) {
    const r = (v || "").trim();
    this.style.borderRadius = r;
    this.style.overflow = r && r !== "0" && r !== "0px" ? "hidden" : "";
    if (r) this.#syncAttr("radius", r);
    else this.removeAttribute("radius");
  }

  /** @returns {boolean} */
  get selected() {
    return this.hasAttribute("selected");
  }

  /** @param {boolean} v */
  set selected(v) {
    if (v) this.setAttribute("selected", "");
    else this.removeAttribute("selected");
  }

  /* =========================
     Helpers privados
     ========================= */

  /**
   * Normaliza wrap inválido para "inline".
   * @param {any} v
   * @returns {ImgWrap}
   */
  #normalizeWrap(v) {
    return v === "left" || v === "right" || v === "inline" ? v : "inline";
  }

  /**
   * Sincroniza atributo evitando setAttribute redundante.
   * - Se v vazio: remove o atributo.
   * - Se v não vazio: seta somente se mudou.
   * @param {string} name
   * @param {string} v
   */
  #syncAttr(name, v) {
    const sv = String(v ?? "").trim();
    if (!sv) {
      this.removeAttribute(name);
      return;
    }
    if (this.getAttribute(name) !== sv) this.setAttribute(name, sv);
  }
}

customElements.define("wordex-img", TWordexImage);
