// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsImage.mjs
   - Seleção de imagem (<wordex-img[selected]>)
   - Inserção via file picker (#tbImgIns + #tbImgFile)
   - Movimento:
       * moveImgByChar (←/→): 1 caractere, atravessando parágrafos
       * moveImgToOtherParagraph (↑/↓)
   - Resize: resizeImg (sm/lg)
   - Wrap: setImgWrap (inline/left/right)

   Depende de ctx:
   - stage: HTMLElement
   - select: API de seleção (saveSelection/insertNodeAtCaret/ensureParagraphAlive/appendToParagraphEnd)
   ========================================================================== */

/**
 * @typedef {Object} ImageCtx
 * @property {HTMLElement} stage
 * @property {ReturnType<import("./WordexFunctionsSelect.mjs").CreateSelectApi>} select
 * @property {Document=} doc
 */

/**
 * Inicializa o módulo de imagem.
 * @param {ImageCtx} ctx
 */
export function initImage(ctx) {
  const doc = ctx.doc || document;
  const { select, stage } = ctx;

  if (!(stage instanceof HTMLElement)) throw new Error("stage inválido.");

  /** @type {HTMLElement|null} */
  let selectedImg = null;

  /** Remove seleção de qualquer imagem. */
  function clearImageSelection() {
    doc.querySelectorAll("wordex-img[selected]").forEach((el) => {
      el.removeAttribute("selected");
    });
    selectedImg = null;
  }

  /**
   * Seleciona 1 imagem (host <wordex-img>).
   * @param {HTMLElement} wxImg
   */
  function selectImage(wxImg) {
    clearImageSelection();
    wxImg.setAttribute("selected", "");
    selectedImg = wxImg;
    select.saveSelection(); // não move caret
  }

  /**
   * Acha o host <wordex-img> (com base num alvo qualquer).
   * @param {EventTarget|null} t
   * @returns {HTMLElement|null}
   */
  function closestWordexImgTarget(t) {
    if (!(t instanceof Node)) return null;
    const el = t.nodeType === 1 ? /** @type {Element} */ (t) : t.parentElement;
    if (!el) return null;
    const host = el.closest("wordex-img");
    return host instanceof HTMLElement ? host : null;
  }

  /**
   * Retorna a imagem selecionada (host).
   * @returns {HTMLElement|null}
   */
  function getSelImg() {
    return selectedImg && selectedImg.isConnected ? selectedImg : null;
  }

  /**
   * Move a imagem para o fim do parágrafo anterior.
   * - Primeiro tenta pelo wrapper <wordex-p> (seu padrão).
   * - Fallback: p anterior “normal”.
   * @param {HTMLElement} imgHost
   * @returns {boolean}
   */
  function moveImgToPrevParagraph(imgHost) {
    const wp = imgHost.closest("wordex-p");
    if (wp && wp instanceof HTMLElement) {
      const prevWp = wp.previousElementSibling;
      if (prevWp && prevWp.tagName === "WORDEX-P") {
        const prevP = prevWp.querySelector("p");
        const curP = wp.querySelector("p");
        if (prevP instanceof HTMLParagraphElement) {
          imgHost.remove();
          if (curP instanceof HTMLParagraphElement)
            select.ensureParagraphAlive(curP);
          select.appendToParagraphEnd(prevP, imgHost);
          return true;
        }
      }
    }

    const p = imgHost.closest("p");
    if (!p) return false;

    let prev = p.previousElementSibling;
    while (prev && prev.tagName !== "P") prev = prev.previousElementSibling;
    if (!(prev instanceof HTMLParagraphElement)) return false;

    imgHost.remove();
    select.ensureParagraphAlive(p);
    select.appendToParagraphEnd(prev, imgHost);
    return true;
  }

  /**
   * Move a imagem para o início do próximo parágrafo.
   * @param {HTMLElement} imgHost
   * @returns {boolean}
   */
  function moveImgToNextParagraph(imgHost) {
    const wp = imgHost.closest("wordex-p");
    if (wp && wp instanceof HTMLElement) {
      const nextWp = wp.nextElementSibling;
      if (nextWp && nextWp.tagName === "WORDEX-P") {
        const nextP = nextWp.querySelector("p");
        const curP = wp.querySelector("p");
        if (nextP instanceof HTMLParagraphElement) {
          imgHost.remove();
          if (curP instanceof HTMLParagraphElement)
            select.ensureParagraphAlive(curP);

          const first = nextP.firstChild;
          if (
            first &&
            first.nodeType === 1 &&
            /** @type {Element} */ (first).tagName === "BR"
          ) {
            nextP.insertBefore(imgHost, first);
          } else {
            nextP.insertBefore(imgHost, nextP.firstChild);
          }
          select.ensureParagraphAlive(nextP);
          return true;
        }
      }
    }

    const p = imgHost.closest("p");
    if (!p) return false;

    let next = p.nextElementSibling;
    while (next && next.tagName !== "P") next = next.nextElementSibling;
    if (!(next instanceof HTMLParagraphElement)) return false;

    imgHost.remove();
    select.ensureParagraphAlive(p);

    const first = next.firstChild;
    if (
      first &&
      first.nodeType === 1 &&
      /** @type {Element} */ (first).tagName === "BR"
    ) {
      next.insertBefore(imgHost, first);
    } else {
      next.insertBefore(imgHost, next.firstChild);
    }
    select.ensureParagraphAlive(next);
    return true;
  }

  /** @param {HTMLElement} imgHost */
  function isAtParagraphStart(imgHost) {
    let n = imgHost.previousSibling;
    while (n) {
      if (n.nodeType === 3) {
        if (/** @type {Text} */ (n.data || "").length > 0) return false;
      } else if (n instanceof HTMLElement) {
        if (n.tagName !== "BR") return false;
      }
      n = n.previousSibling;
    }
    return true;
  }

  /** @param {HTMLElement} imgHost */
  function isAtParagraphEnd(imgHost) {
    let n = imgHost.nextSibling;
    while (n) {
      if (n.nodeType === 3) {
        if (/** @type {Text} */ (n.data || "").trim().length > 0) return false;
      } else if (n.nodeType === 1) {
        if (
          /** @type {Element} */ (n.tagName || "").toUpperCase() !== "BR"
        )
          return false;
      }
      n = n.nextSibling;
    }
    return true;
  }

  /** @param {HTMLElement} imgHost */
  function getFirstTextContentAfter(imgHost) {
    let n = imgHost.nextSibling;
    while (n) {
      if (n.nodeType === 3) {
        const t = /** @type {Text} */ (n);
        if ((t.data || "").trim().length > 0) return t;
      } else if (n.nodeType === 1) {
        const tag = /** @type {Element} */ (n.tagName || "").toUpperCase();
        if (tag === "BR") {
          n = n.nextSibling;
          continue;
        }
        break;
      }
      n = n.nextSibling;
    }
    return null;
  }

  /**
   * Move <wordex-img> 1 caractere dentro do parágrafo (esquerda/direita).
   * @param {HTMLElement} imgHost
   * @param {-1|1} dir
   */
  function moveImgByChar(imgHost, dir) {
    const parent = imgHost.parentNode;
    if (!parent) return;

    const before = imgHost.previousSibling;

    if (dir < 0) {
      if (isAtParagraphStart(imgHost)) {
        moveImgToPrevParagraph(imgHost);
        return;
      }

      if (before && before.nodeType === 3) {
        const t = /** @type {Text} */ (before);
        if (!t.data.length) return;

        const ch = t.data.slice(-1);
        t.data = t.data.slice(0, -1);
        if (!t.data.length) t.remove();

        parent.insertBefore(doc.createTextNode(ch), imgHost.nextSibling);
      }
      return;
    }

    if (isAtParagraphEnd(imgHost)) {
      moveImgToNextParagraph(imgHost);
      return;
    }

    const t = getFirstTextContentAfter(imgHost);
    if (t) {
      const ch = t.data.slice(0, 1);
      t.data = t.data.slice(1);
      if (!t.data.length) t.remove();
      parent.insertBefore(doc.createTextNode(ch), imgHost);
    }
  }

  /**
   * @param {HTMLElement} imgHost
   * @param {-1|1} dir
   */
  function moveImgToOtherParagraph(imgHost, dir) {
    if (dir < 0) moveImgToPrevParagraph(imgHost);
    else moveImgToNextParagraph(imgHost);
  }

  /**
   * Ajusta largura da imagem.
   * @param {HTMLElement} imgHost
   * @param {number} deltaPx
   */
  function resizeImg(imgHost, deltaPx) {
    const minPx = 20;
    const maxPx = 800;

    // @ts-expect-error - imgHost pode ser HTMLElement ou Web Component com propriedade widthPx
    const el = imgHost;

    let cur = 80;
    if (typeof el.widthPx === "number" && Number.isFinite(el.widthPx)) {
      cur = el.widthPx;
    } else {
      const attr = imgHost.getAttribute("width");
      if (attr) {
        const n = parseInt(attr, 10);
        if (Number.isFinite(n)) cur = n;
      } else {
        const css = imgHost.style.getPropertyValue("--iw").trim();
        if (css.endsWith("px")) {
          const n = parseFloat(css);
          if (Number.isFinite(n)) cur = n;
        }
      }
    }

    const next = Math.max(minPx, Math.min(maxPx, Math.round(cur + deltaPx)));

    imgHost.style.setProperty("--iw", `${next}px`);
    imgHost.setAttribute("width", String(next));

    if (typeof el.widthPx !== "undefined") {
      try {
        el.widthPx = next;
      } catch {}
    }

    select.saveSelection();
  }

  /**
   * @param {HTMLElement} imgHost
   * @param {"inline"|"left"|"right"} wrap
   */
  function setImgWrap(imgHost, wrap) {
    // @ts-expect-error - imgHost pode ser HTMLElement ou Web Component com propriedade wrap
    const img = imgHost;
    try {
      img.wrap = wrap;
    } catch {}
    imgHost.setAttribute("wrap", wrap);
  }

  // ----------------------------
  // Bind seleção (stage)
  // ----------------------------
  stage.addEventListener(
    "mousedown",
    (ev) => {
      const wxImg = closestWordexImgTarget(ev.target);
      if (wxImg) {
        selectImage(wxImg);
        ev.preventDefault();
        ev.stopPropagation();
        return;
      }
      clearImageSelection();
    },
    true,
  );

  // ----------------------------
  // File picker (#tbImgIns + #tbImgFile)
  // ----------------------------
  const tbImgIns = doc.getElementById("tbImgIns");
  const tbImgFile = doc.getElementById("tbImgFile");

  if (tbImgIns instanceof HTMLButtonElement && tbImgFile instanceof HTMLInputElement) {
    tbImgIns.addEventListener("click", () => {
      select.saveSelection();
      tbImgFile.value = "";
      tbImgFile.click();
    });

    tbImgFile.addEventListener("change", () => {
      const file = tbImgFile.files && tbImgFile.files[0];
      if (!file) return;

      const fr = new FileReader();
      fr.onload = () => {
        const dataUrl = String(fr.result || "");
        if (!dataUrl) return;

        // @ts-expect-error - createElement retorna HTMLElement, mas customElements.define garante que é TWordexImage
        const wxImg = doc.createElement("wordex-img");
        wxImg.setAttribute("src", dataUrl);
        wxImg.setAttribute("wrap", "inline");
        wxImg.setAttribute("width", "140");

        const ok = select.insertNodeAtCaret(wxImg);
        if (!ok) return;

        selectImage(wxImg);
      };

      fr.readAsDataURL(file);
    });
  }

  // ----------------------------
  // Botões (se existirem)
  // ----------------------------
  const tbImgSm = doc.getElementById("tbImgSm");
  const tbImgLg = doc.getElementById("tbImgLg");
  const tbImgLeft = doc.getElementById("tbImgLeft");
  const tbImgRight = doc.getElementById("tbImgRight");
  const tbImgUp = doc.getElementById("tbImgUp");
  const tbImgDown = doc.getElementById("tbImgDown");
  const tbImgWrapInline = doc.getElementById("tbImgWrapInline");
  const tbImgWrapLeft = doc.getElementById("tbImgWrapLeft");
  const tbImgWrapRight = doc.getElementById("tbImgWrapRight");

  if (tbImgSm instanceof HTMLButtonElement) {
    tbImgSm.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      resizeImg(img, -10);
    });
  }

  if (tbImgLg instanceof HTMLButtonElement) {
    tbImgLg.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      resizeImg(img, +10);
    });
  }

  if (tbImgLeft instanceof HTMLButtonElement) {
    tbImgLeft.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      moveImgByChar(img, -1);
    });
  }

  if (tbImgRight instanceof HTMLButtonElement) {
    tbImgRight.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      moveImgByChar(img, +1);
    });
  }

  if (tbImgUp instanceof HTMLButtonElement) {
    tbImgUp.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      moveImgToOtherParagraph(img, -1);
    });
  }

  if (tbImgDown instanceof HTMLButtonElement) {
    tbImgDown.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      moveImgToOtherParagraph(img, +1);
    });
  }

  if (tbImgWrapInline instanceof HTMLButtonElement) {
    tbImgWrapInline.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      setImgWrap(img, "inline");
    });
  }

  if (tbImgWrapLeft instanceof HTMLButtonElement) {
    tbImgWrapLeft.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      setImgWrap(img, "left");
    });
  }

  if (tbImgWrapRight instanceof HTMLButtonElement) {
    tbImgWrapRight.addEventListener("click", () => {
      const img = getSelImg();
      if (!img) return;
      setImgWrap(img, "right");
    });
  }

  // expõe no ctx se você quiser que outros módulos consultem
  ctx.image = {
    getSelImg,
    clearImageSelection,
    selectImage,
    closestWordexImgTarget,
    moveImgByChar,
    moveImgToOtherParagraph,
    resizeImg,
    setImgWrap,
  };
}
