// @ts-check
"use strict";

import { TWordex } from "./Wordex.mjs";

/* ============================================================================
   WordexFunctions.mjs
   - Toolbar sem “roubar” caret (botões não focam; selects/inputs abrem normal).
   - Salva/restaura seleção.
   - INS/OVR real:
       * Insert alterna.
       * Pill: verde INS / vermelho OVR.
       * Caret (cursor) dos .editable: verde INS / vermelho OVR.
       * Em OVR: digitação substitui 1 char à direita (TextNode).
   - Borda / Raio:
       * img selecionada > seleção de tabela/linha/coluna/célula > td/th do caret > <p>.
   - Orientação: alterna retrato/paisagem via classe .landscape na .page
   - Tabela:
       * Inserir <wordex-tbl> exatamente no caret.
   - Imagem:
       * Inserir via file picker: insere <wordex-img> no caret.
       * Seleção por click: marca [selected] no <wordex-img>.
       * Botões: mover (← → ↑ ↓), dimensionar (sm/lg), wrap (inline/left/right).
   - Seleção de Tabela (mouse):
       * click simples em td/th: seleciona célula
       * ctrl+click em td/th: tabela -> linha -> coluna -> tabela...
   ========================================================================== */

/** Range salvo (clone) para restaurar a seleção após cliques na toolbar. */
/** @type {Range|null} */
let savedRange = null;
// 0=Left, 1=Center, 2=Right, 3=Justify
let alignState = 0;


/** Salva seleção atual (cloneRange). */
function saveSelection() {
  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0) return;
  savedRange = sel.getRangeAt(0).cloneRange();
}

/**
 * Restaura seleção salva (removeAllRanges + addRange).
 * @returns {boolean}
 */
function restoreSelection() {
  if (!savedRange) return false;
  const sel = window.getSelection();
  if (!sel) return false;
  sel.removeAllRanges();
  sel.addRange(savedRange);
  return true;
}

/**
 * Retorna o nó “real” onde está o caret (se for Text node, sobe pro parent).
 * @returns {Node|null}
 */
function getSelNode() {
  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0) return null;
  const n = sel.getRangeAt(0).startContainer;
  return n.nodeType === 3 ? n.parentNode : n;
}

/**
 * Retorna a célula atual (td/th) se o caret estiver dentro de uma.
 * @returns {HTMLTableCellElement|null}
 */
function getCurrentCell() {
  const n = getSelNode();
  if (!(n instanceof HTMLElement)) return null;
  const td = n.closest("td,th");
  return td instanceof HTMLTableCellElement ? td : null;
}

/**
 * Retorna o parágrafo atual (p) se o caret estiver dentro de um.
 * @returns {HTMLParagraphElement|null}
 */
function getCurrentParagraph() {
  const n = getSelNode();
  if (!(n instanceof HTMLElement)) return null;
  const p = n.closest("p");
  return p instanceof HTMLParagraphElement ? p : null;
}

/**
 * Monta CSS de borda a partir do select (px) e da cor.
 * @param {string} v Valor do select ("none", "1", "2", ...)
 * @param {string | null | undefined} color Cor em hexadecimal
 * @returns {string}
 */
function makeCssBorder(v, color) {
  if (!v || v === "none") return "";
  return `${v}px solid ${color || "#000"}`;
}

/**
 * Atualiza UI do modo INS/OVR (visual + classes para CSS).
 * - .wx-ins / .wx-ovr no <html> para caret-color
 * - .ins / .ovr no pill
 * @param {HTMLElement | null} modePill
 * @param {HTMLElement | null} modeText
 * @param {boolean} insertMode
 */
function setModeUI(modePill, modeText, insertMode) {
  if (modeText instanceof HTMLElement) {
    modeText.textContent = insertMode ? "INS" : "OVR";
  }

  if (modePill instanceof HTMLElement) {
    modePill.classList.toggle("ovr", !insertMode);
    modePill.classList.toggle("ins", insertMode);
    modePill.style.background = insertMode ? "#0a0" : "#a00";
    modePill.style.color = "#fff";
  }

  document.documentElement.classList.toggle("wx-ovr", !insertMode);
  document.documentElement.classList.toggle("wx-ins", insertMode);
}

/**
 * Injeta CSS 1x:
 * - caret-color dos .editable conforme wx-ins/wx-ovr
 */
function ensureModeCss() {
  const id = "wordex-mode-css";
  if (document.getElementById(id)) return;

  const st = document.createElement("style");
  st.id = id;
  st.textContent = `
    html.wx-ins .editable { caret-color: #22ff22; }
    html.wx-ovr .editable { caret-color: #ff2222; }
    #modePill.ins { background:#0a0; color:#fff; }
    #modePill.ovr { background:#a00; color:#fff; }
  `;
  document.head.appendChild(st);
}

/**
 * Garante que:
 * - a seleção volta para onde estava
 * - o foco volta pro lugar certo (célula ou editor)
 */
function focusAndRestore() {
  restoreSelection();

  const td = getCurrentCell();
  if (td && td.isContentEditable) {
    td.focus?.({ preventScroll: true });
    restoreSelection();
    return;
  }

  const a = document.activeElement;
  if (a instanceof HTMLElement && a.classList.contains("editable")) {
    a.focus({ preventScroll: true });
    restoreSelection();
    return;
  }

  const body = document.querySelector(".body-ed");
  if (body instanceof HTMLElement) body.focus?.({ preventScroll: true });
  restoreSelection();
}

/**
 * Posiciona caret imediatamente após um nó inserido.
 * @param {Node} node
 */
function placeCaretAfter(node) {
  const r = document.createRange();
  r.setStartAfter(node);
  r.collapse(true);

  const sel = window.getSelection();
  if (!sel) return;

  sel.removeAllRanges();
  sel.addRange(r);
  savedRange = r.cloneRange();
}

/**
 * Insere um nó no caret (ou na seleção), sem perder a posição.
 * @param {Node} node
 * @returns {boolean}
 */
function insertNodeAtCaret(node) {
  focusAndRestore();

  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0) return false;

  const range = sel.getRangeAt(0);
  range.deleteContents();
  range.insertNode(node);

  placeCaretAfter(node);
  return true;
}

/**
 * Garante que um <p> vazio continue editável (mantém um <br>).
 * @param {HTMLParagraphElement} p
 */
function ensureParagraphAlive(p) {
  if (!p.childNodes.length) p.appendChild(document.createElement("br"));
}

/**
 * Insere um elemento no final de um <p> (antes do <br> final, se existir).
 * @param {HTMLParagraphElement} p
 * @param {HTMLElement} el
 */
function appendToParagraphEnd(p, el) {
  const last = p.lastChild;
  if (
    last &&
    last.nodeType === 1 &&
    /** @type {Element} */ (last).tagName === "BR"
  ) {
    p.insertBefore(el, last);
  } else {
    p.appendChild(el);
  }
  ensureParagraphAlive(p);
}

/** Compat: mantém seu HTML atual com `import { WordexFunctions } ...` */
export const WordexFunctions = { Main };

/** Recomendado: `import { Main } ...` */
export function Main() {
  ensureModeCss();

  /* ------------------------------------------------------------------------
     1) Torna header/body/footer editáveis
     --------------------------------------------------------------------- */
  document.querySelectorAll(".editable").forEach((ed) => {
    if (!(ed instanceof HTMLElement)) return;
    ed.contentEditable = "true";
    ed.spellcheck = false;
  });

  /* ------------------------------------------------------------------------
     2) Instancia Wordex
     --------------------------------------------------------------------- */
  const stage = document.getElementById("stage");
  const modePill = document.getElementById("modePill");
  const modeText = document.getElementById("modeText");

  if (!(stage instanceof HTMLElement)) throw new Error("stage inválido.");

  const wordex = new TWordex({
    stage,
    modePill: modePill instanceof HTMLElement ? modePill : null,
    modeText: modeText instanceof HTMLElement ? modeText : null,
    maxHeaderFooterParagraphs: 10,
  });

  if (typeof wordex.init === "function") wordex.init();

  /* ------------------------------------------------------------------------
     3) INS/OVR (Insert alterna + Overtype real)
     --------------------------------------------------------------------- */
  let insertMode = true;
  setModeUI(
    modePill instanceof HTMLElement ? modePill : null,
    modeText instanceof HTMLElement ? modeText : null,
    insertMode,
  );

  document.addEventListener(
    "keydown",
    (e) => {
      if (insertMode) return;
      if (handleOvertypeKey(e)) e.preventDefault();
    },
    true,
  );

  document.addEventListener(
    "keydown",
    (e) => {
      if (e.key !== "Insert") return;
      e.preventDefault();
      insertMode = !insertMode;
      setModeUI(
        modePill instanceof HTMLElement ? modePill : null,
        modeText instanceof HTMLElement ? modeText : null,
        insertMode,
      );
    },
    true,
  );

  /* ------------------------------------------------------------------------
     4) Mantém savedRange atualizado
     --------------------------------------------------------------------- */
  document.addEventListener("selectionchange", () => {
    const a = document.activeElement;
    const inEditable =
      a instanceof HTMLElement &&
      typeof a.closest === "function" &&
      !!a.closest(".editable");

    const n = getSelNode();
    const inCell =
      n instanceof HTMLElement &&
      typeof n.closest === "function" &&
      !!n.closest("td,th");

    if (inEditable || inCell) saveSelection();
  });

  /* ------------------------------------------------------------------------
     5) Toolbar não rouba foco
     --------------------------------------------------------------------- */
  document.querySelectorAll(".topbar button").forEach((el) => {
    el.addEventListener(
      "mousedown",
      (ev) => {
        saveSelection();
        ev.preventDefault();
      },
      true,
    );
  });

  document.querySelectorAll(".topbar select, .topbar input").forEach((el) => {
    el.addEventListener(
      "mousedown",
      () => {
        saveSelection();
      },
      true,
    );
  });

  const tbAlign = document.getElementById("tbAlign");
if (tbAlign instanceof HTMLButtonElement) {
  const order = ["justifyLeft", "justifyCenter", "justifyRight", "justifyFull"];

  function getAlignStateFromCommand() {
    try {
      if (document.queryCommandState("justifyCenter")) return 1;
      if (document.queryCommandState("justifyRight")) return 2;
      if (document.queryCommandState("justifyFull")) return 3;
      return 0; // left (default)
    } catch {
      return alignState;
    }
  }

tbAlign.addEventListener("click", () => {
  focusAndRestore();
  restoreSelection();   // reforça
  saveSelection();      // reforça

  alignState = getAlignStateFromCommand();
  const next = (alignState + 1) % order.length;
  document.execCommand(order[next]);
  alignState = next;

  saveSelection();
});

}

  /* ------------------------------------------------------------------------
     6) Botões de formatação (execCommand)
     --------------------------------------------------------------------- */
  document.querySelectorAll("button[data-cmd]").forEach((btn) => {
    if (!(btn instanceof HTMLButtonElement)) return;
    btn.addEventListener("click", () => {
      const cmd = btn.dataset.cmd;
      if (!cmd) return;
      focusAndRestore();
      document.execCommand(cmd);
      saveSelection();
    });
  });

  /* ------------------------------------------------------------------------
     7) Fonte / Tamanho / Cor
     --------------------------------------------------------------------- */
  const tbFont = document.getElementById("tbFont");
  if (tbFont instanceof HTMLSelectElement) {
    tbFont.addEventListener("change", () => {
      const v = tbFont.value;
      if (!v) return;
      focusAndRestore();
      document.execCommand("fontName", false, v);
      saveSelection();
      tbFont.value = "";
    });
  }

  const tbSize = document.getElementById("tbSize");
  if (tbSize instanceof HTMLSelectElement) {
    tbSize.addEventListener("change", () => {
      const v = tbSize.value;
      if (!v) return;
      focusAndRestore();
      document.execCommand("fontSize", false, v);
      saveSelection();
      tbSize.value = "";
    });
  }

  const tbColor = document.getElementById("tbColor");
  if (tbColor instanceof HTMLInputElement) {
    tbColor.addEventListener("input", () => {
      const v = tbColor.value;
      if (!v) return;
      focusAndRestore();
      document.execCommand("foreColor", false, v);
      saveSelection();
    });
  }

  /* ------------------------------------------------------------------------
     10) Orientação: Retrato / Paisagem
     --------------------------------------------------------------------- */
  const tbOrientation = document.getElementById("tbOrientation");
  if (tbOrientation instanceof HTMLButtonElement) {
    tbOrientation.addEventListener("click", () => {
      saveSelection();
      focusAndRestore();

      const page = document.querySelector(".page");
      if (!(page instanceof HTMLElement)) return;

      page.classList.toggle("landscape");
      saveSelection();
    });
  }

  /* ------------------------------------------------------------------------
     10b) TABELA: inserir na posição do cursor (caret)
     --------------------------------------------------------------------- */
  const tbTblNew = document.getElementById("tbTblNew");
  if (tbTblNew instanceof HTMLElement) {
    tbTblNew.addEventListener("click", () => {
      saveSelection(); // guarda caret antes do prompt

      const input = window.prompt(
        "Linhas e colunas (ex.: 2, 3)\nPadrão: 2 linhas, 3 colunas",
        "2, 3",
      );
      if (input == null) return;

      // prompt mata foco/seleção -> restaura
      focusAndRestore();

      const parts = input
        .trim()
        .split(/[\s,;xX]+/)
        .filter(Boolean);
      const rows = Math.max(
        1,
        Math.min(50, parseInt(parts[0] || "2", 10) || 2),
      );
      const cols = Math.max(
        1,
        Math.min(50, parseInt(parts[1] || "3", 10) || 3),
      );

      /** @type {HTMLElement} */
      const tbl = /** @type {any} */ (document.createElement("wordex-tbl"));
      tbl.setAttribute("rows", String(rows));
      tbl.setAttribute("cols", String(cols));

      // INSERÇÃO ROBUSTA: dentro do <p> atual (fallback no fim)
      const p = getCurrentParagraph();
      if (!p) return;

      const sel = window.getSelection();
      let inserted = false;

      if (sel && sel.rangeCount > 0) {
        const r = sel.getRangeAt(0);
        if (p.contains(r.startContainer)) {
          r.deleteContents();
          r.insertNode(tbl);
          placeCaretAfter(tbl);
          inserted = true;
        }
      }

      if (!inserted) {
        // fallback: enfia antes do <br> final
        appendToParagraphEnd(p, tbl);
        placeCaretAfter(tbl);
      }

      placeCaretAfter(tbl);
      clearImageSelection(); // se houver imagem selecionada
      clearTableSelection(); // limpa seleção anterior

      const innerTable = tbl.querySelector("table");
      if (innerTable instanceof HTMLTableElement) {
        innerTable.classList.add("wx-sel-table");
        tblSel = {
          kind: "table",
          table: innerTable,
          cell: null,
          colIndex: -1,
        };
      }
      saveSelection();
    });
  } else {
    console.warn("tbTblNew não encontrado. Confira o id do botão da tabela.");
  }

  /* ------------------------------------------------------------------------
     11) IMAGEM: seleção + inserção + botões
     --------------------------------------------------------------------- */

  /** @type {HTMLElement|null} */
  let selectedImg = null;

  /** Remove seleção de qualquer imagem. */
  function clearImageSelection() {
    document.querySelectorAll("wordex-img[selected]").forEach((el) => {
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
    saveSelection(); // não move caret
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
          if (curP instanceof HTMLParagraphElement) ensureParagraphAlive(curP);
          appendToParagraphEnd(prevP, imgHost);
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
    ensureParagraphAlive(p);
    appendToParagraphEnd(prev, imgHost);
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
          if (curP instanceof HTMLParagraphElement) ensureParagraphAlive(curP);

          // insere no começo do próximo
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
          ensureParagraphAlive(nextP);
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
    ensureParagraphAlive(p);

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
    ensureParagraphAlive(next);
    return true;
  }

  /**
   * Retorna true se a imagem está no começo “real” do parágrafo.
   * Ignora TextNode vazio e <br>.
   * @param {HTMLElement} imgHost
   * @returns {boolean}
   */
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

  /**
   * Retorna true se a imagem está no fim “real” do parágrafo.
   * Ignora br e texto vazio/espacos.
   * @param {HTMLElement} imgHost
   * @returns {boolean}
   */
  function isAtParagraphEnd(imgHost) {
    let n = imgHost.nextSibling;
    while (n) {
      if (n.nodeType === 3) {
        if (/** @type {Text} */ (n.data || "").trim().length > 0) return false;
      } else if (n.nodeType === 1) {
        if (/** @type {Element} */ (n.tagName || "").toUpperCase() !== "BR")
          return false;
      }
      n = n.nextSibling;
    }
    return true;
  }

  /**
   * Primeiro TextNode à direita com conteúdo (ignora br e texto vazio).
   * @param {HTMLElement} imgHost
   * @returns {Text|null}
   */
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
   * - Esquerda: se estiver no começo do parágrafo, vai pro fim do anterior.
   * - Direita: se estiver no fim do parágrafo, vai pro começo do próximo.
   * @param {HTMLElement} imgHost
   * @param {-1|1} dir
   */
  function moveImgByChar(imgHost, dir) {
    const parent = imgHost.parentNode;
    if (!parent) return;

    const before = imgHost.previousSibling;

    // ESQUERDA
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

        parent.insertBefore(document.createTextNode(ch), imgHost.nextSibling);
      }
      return;
    }

    // DIREITA
    if (isAtParagraphEnd(imgHost)) {
      moveImgToNextParagraph(imgHost);
      return;
    }

    const t = getFirstTextContentAfter(imgHost);
    if (t) {
      const ch = t.data.slice(0, 1);
      t.data = t.data.slice(1);
      if (!t.data.length) t.remove();
      parent.insertBefore(document.createTextNode(ch), imgHost);
    }
  }

  /**
   * Move a imagem para parágrafo anterior/próximo (↑/↓).
   * @param {HTMLElement} imgHost
   * @param {-1|1} dir -1 cima, +1 baixo
   */
  function moveImgToOtherParagraph(imgHost, dir) {
    if (dir < 0) moveImgToPrevParagraph(imgHost);
    else moveImgToNextParagraph(imgHost);
  }

  /**
   * Ajusta largura da imagem (botões ＋ e －).
   * @param {HTMLElement} imgHost elemento <wordex-img>
   * @param {number} deltaPx valor a somar (ex: +10 ou -10)
   */
  function resizeImg(imgHost, deltaPx) {
    const minPx = 20;
    const maxPx = 800;

    /** @type {any} */
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

    saveSelection();
  }

  /**
   * Ajusta wrap via propriedade wrap do WC.
   * @param {HTMLElement} imgHost
   * @param {"inline"|"left"|"right"} wrap
   */
  function setImgWrap(imgHost, wrap) {
    /** @type {any} */ const img = imgHost;
    try {
      img.wrap = wrap;
    } catch {}
    imgHost.setAttribute("wrap", wrap);
  }

  /**
   * Retorna a imagem selecionada (host).
   * @returns {HTMLElement|null}
   */
  function getSelImg() {
    return selectedImg && selectedImg.isConnected ? selectedImg : null;
  }

  // Clique no stage: seleciona imagem / desmarca
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

  // Inserção via file picker
  const tbImgIns = document.getElementById("tbImgIns");
  const tbImgFile = document.getElementById("tbImgFile");

  if (
    tbImgIns instanceof HTMLButtonElement &&
    tbImgFile instanceof HTMLInputElement
  ) {
    tbImgIns.addEventListener("click", () => {
      saveSelection();
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

        /** @type {HTMLElement} */
        const wxImg = /** @type {any} */ (document.createElement("wordex-img"));
        wxImg.setAttribute("src", dataUrl);
        wxImg.setAttribute("wrap", "inline");
        wxImg.setAttribute("width", "140");

        const ok = insertNodeAtCaret(wxImg);
        if (!ok) return;

        selectImage(wxImg);
      };

      fr.readAsDataURL(file);
    });
  }

  // Botões de imagem (IDs esperados)
  const tbImgSm = document.getElementById("tbImgSm");
  const tbImgLg = document.getElementById("tbImgLg");
  const tbImgLeft = document.getElementById("tbImgLeft");
  const tbImgRight = document.getElementById("tbImgRight");
  const tbImgUp = document.getElementById("tbImgUp");
  const tbImgDown = document.getElementById("tbImgDown");
  const tbImgWrapInline = document.getElementById("tbImgWrapInline");
  const tbImgWrapLeft = document.getElementById("tbImgWrapLeft");
  const tbImgWrapRight = document.getElementById("tbImgWrapRight");

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
      if (img) {
        moveImgByChar(img, -1);
        return;
      }
      const tbl = getSelectedTableHost();
      if (tbl) moveTableByChar(tbl, -1);
    });
  }

  if (tbImgRight instanceof HTMLButtonElement) {
    tbImgRight.addEventListener("click", () => {
      const img = getSelImg();
      if (img) {
        moveImgByChar(img, +1);
        return;
      }
      const tbl = getSelectedTableHost();
      if (tbl) moveTableByChar(tbl, +1);
    });
  }

  if (tbImgUp instanceof HTMLButtonElement) {
    tbImgUp.addEventListener("click", () => {
      const img = getSelImg();
      if (img) {
        moveImgToOtherParagraph(img, -1);
        return;
      }

      const tbl = getSelectedTableHost();
      if (tbl) moveTableToPrevParagraph(tbl);
    });
  }

  if (tbImgDown instanceof HTMLButtonElement) {
    tbImgDown.addEventListener("click", () => {
      const img = getSelImg();
      if (img) {
        moveImgToOtherParagraph(img, +1);
        return;
      }

      const tbl = getSelectedTableHost();
      if (tbl) moveTableToNextParagraph(tbl);
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

  /* ------------------------------------------------------------------------
     12) SELEÇÃO DE TABELA / LINHA / COLUNA / CÉLULA
     - click: célula
     - ctrl+click: tabela -> linha -> coluna -> tabela...
  --------------------------------------------------------------------- */

  // CSS 1x (visual simples)
  (function ensureTableSelCss() {
    const id = "wordex-table-sel-css";
    if (document.getElementById(id)) return;
    const st = document.createElement("style");
    st.id = id;
    st.textContent = `
      .wx-sel-cell  { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-row   { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-col   { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-table { outline: 2px solid #22ff22; outline-offset: -2px; }
    `;
    document.head.appendChild(st);
  })();

  /** @type {{ kind: "cell"|"row"|"col"|"table"|null, table: HTMLTableElement|null, cell: HTMLTableCellElement|null, colIndex: number }} */
  let tblSel = { kind: null, table: null, cell: null, colIndex: -1 };

  function clearTableSelection() {
    document
      .querySelectorAll(".wx-sel-cell,.wx-sel-row,.wx-sel-col,.wx-sel-table")
      .forEach((el) => {
        el.classList.remove(
          "wx-sel-cell",
          "wx-sel-row",
          "wx-sel-col",
          "wx-sel-table",
        );
      });
    tblSel = { kind: null, table: null, cell: null, colIndex: -1 };
  }

  /** @param {Element} el */
  function closestCell(el) {
    const c = el.closest("td,th");
    return c instanceof HTMLTableCellElement ? c : null;
  }

  /** @param {HTMLTableCellElement} cell */
  function getCellTable(cell) {
    const t = cell.closest("table");
    return t instanceof HTMLTableElement ? t : null;
  }

  /** @param {HTMLTableCellElement} cell */
  function getCellRow(cell) {
    const r = cell.closest("tr");
    return r instanceof HTMLTableRowElement ? r : null;
  }

  /** índice simples (sem colspan). */
  /** @param {HTMLTableCellElement} cell */
  function getCellColIndex(cell) {
    const row = cell.parentElement;
    if (!row) return -1;
    const cells = Array.from(row.children).filter(
      (x) => x instanceof HTMLTableCellElement,
    );
    return cells.indexOf(cell);
  }

  /** @param {HTMLTableCellElement} cell */
  function selectCell(cell) {
    clearTableSelection();
    cell.classList.add("wx-sel-cell");
    tblSel.kind = "cell";
    tblSel.cell = cell;
    tblSel.table = getCellTable(cell);
    tblSel.colIndex = getCellColIndex(cell);
  }

  /** @param {HTMLTableRowElement} row */
  function selectRow(row, table) {
    clearTableSelection();
    row.classList.add("wx-sel-row");
    tblSel.kind = "row";
    tblSel.table = table;
    tblSel.cell = null;
    tblSel.colIndex = -1;
  }

  /**
   * Retorna o elemento "movível" da tabela:
   * - se o <table> está num ShadowRoot, retorna o host <wordex-tbl>
   * - senão: tenta closest("wordex-tbl")
   * - fallback: o próprio <table>
   * @returns {HTMLElement|null}
   */
  function getSelectedTableHost() {
    const t = tblSel.table;
    if (!t || !t.isConnected) return null;

    // 1) Shadow DOM? então o movível é o host (wordex-tbl)
    const root = t.getRootNode();
    if (root instanceof ShadowRoot) {
      const host = root.host;
      if (host instanceof HTMLElement && host.tagName === "WORDEX-TBL") {
        return host;
      }
    }

    // 2) Light DOM normal
    const host = t.closest("wordex-tbl");
    return host instanceof HTMLElement ? host : t;
  }

  /**
   * True se el está no começo "real" do parágrafo (ignora texto vazio e <br>).
   * @param {HTMLElement} el
   */
  function isElAtParagraphStart(el) {
    let n = el.previousSibling;
    while (n) {
      if (n.nodeType === 3) {
        // NÃO usa trim: espaço conta como caractere
        if (/** @type {Text} */ (n.data || "").length > 0) return false;
      } else if (n.nodeType === 1) {
        const tag = /** @type {Element} */ (n).tagName.toUpperCase();
        if (tag !== "BR") return false;
      }
      n = n.previousSibling;
    }
    return true;
  }

  /**
   * True se el está no fim "real" do parágrafo (ignora <br> e texto vazio).
   * @param {HTMLElement} el
   */
  function isElAtParagraphEnd(el) {
    let n = el.nextSibling;
    while (n) {
      if (n.nodeType === 3) {
        // NÃO usa trim: espaço conta como caractere
        if (/** @type {Text} */ (n.data || "").length > 0) return false;
      } else if (n.nodeType === 1) {
        const tag = /** @type {Element} */ (n).tagName.toUpperCase();
        if (tag !== "BR") return false;
      }
      n = n.nextSibling;
    }
    return true;
  }

  /**
   * Primeiro TextNode à direita com conteúdo (ignora br e texto vazio).
   * @param {HTMLElement} el
   * @returns {Text|null}
   */
  function getFirstTextContentAfterEl(el) {
    let n = el.nextSibling;
    while (n) {
      if (n.nodeType === 3) {
        const t = /** @type {Text} */ (n);
        // NÃO usa trim: espaço conta como conteúdo
        if ((t.data || "").length > 0) return t;
      } else if (n.nodeType === 1) {
        const tag = /** @type {Element} */ (n).tagName.toUpperCase();
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
   * Move a tabela para o fim do parágrafo anterior.
   * @param {HTMLElement} tblHost
   * @returns {boolean}
   */
  function moveTableToPrevParagraph(tblHost) {
    const wp = tblHost.closest("wordex-p");
    if (wp && wp instanceof HTMLElement) {
      const prevWp = wp.previousElementSibling;
      if (prevWp && prevWp.tagName === "WORDEX-P") {
        const prevP = prevWp.querySelector("p");
        const curP = wp.querySelector("p");
        if (prevP instanceof HTMLParagraphElement) {
          tblHost.remove();
          if (curP instanceof HTMLParagraphElement) ensureParagraphAlive(curP);
          appendToParagraphEnd(prevP, tblHost);
          return true;
        }
      }
    }

    const p = tblHost.closest("p");
    if (!p) return false;

    let prev = p.previousElementSibling;
    while (prev && prev.tagName !== "P") prev = prev.previousElementSibling;
    if (!(prev instanceof HTMLParagraphElement)) return false;

    tblHost.remove();
    ensureParagraphAlive(p);
    appendToParagraphEnd(prev, tblHost);
    return true;
  }

  /**
   * Move a tabela para o início do próximo parágrafo.
   * @param {HTMLElement} tblHost
   * @returns {boolean}
   */
  function moveTableToNextParagraph(tblHost) {
    const wp = tblHost.closest("wordex-p");
    if (wp && wp instanceof HTMLElement) {
      const nextWp = wp.nextElementSibling;
      if (nextWp && nextWp.tagName === "WORDEX-P") {
        const nextP = nextWp.querySelector("p");
        const curP = wp.querySelector("p");
        if (nextP instanceof HTMLParagraphElement) {
          tblHost.remove();
          if (curP instanceof HTMLParagraphElement) ensureParagraphAlive(curP);

          const first = nextP.firstChild;
          if (
            first &&
            first.nodeType === 1 &&
            /** @type {Element} */ (first).tagName === "BR"
          ) {
            nextP.insertBefore(tblHost, first);
          } else {
            nextP.insertBefore(tblHost, nextP.firstChild);
          }
          ensureParagraphAlive(nextP);
          return true;
        }
      }
    }

    const p = tblHost.closest("p");
    if (!p) return false;

    let next = p.nextElementSibling;
    while (next && next.tagName !== "P") next = next.nextElementSibling;
    if (!(next instanceof HTMLParagraphElement)) return false;

    tblHost.remove();
    ensureParagraphAlive(p);

    const first = next.firstChild;
    if (
      first &&
      first.nodeType === 1 &&
      /** @type {Element} */ (first).tagName === "BR"
    ) {
      next.insertBefore(tblHost, first);
    } else {
      next.insertBefore(tblHost, next.firstChild);
    }
    ensureParagraphAlive(next);
    return true;
  }

  /**
   * Move a tabela 1 caractere (esquerda/direita) dentro do parágrafo.
   * - Esquerda: se estiver no início, vai pro fim do parágrafo anterior (se houver).
   * - Direita: se estiver no fim, vai pro início do próximo parágrafo (se houver).
   * @param {HTMLElement} tblHost
   * @param {-1|1} dir
   */
  /**
   * Último TextNode antes de `el` dentro de `root` (ordem de documento).
   * @param {HTMLElement} root
   * @param {HTMLElement} el
   * @returns {Text|null}
   */
  function findPrevTextNode(root, el) {
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    /** @type {Text|null} */
    let last = null;

    let n = w.nextNode();
    while (n) {
      const t = /** @type {Text} */ (n);

      // Se o texto estiver DEPOIS (ou dentro) do el, paramos.
      const pos = el.compareDocumentPosition(t);
      const isAfterOrInside =
        !!(pos & Node.DOCUMENT_POSITION_PRECEDING) || // t antes do el? (ok)
        !!(pos & Node.DOCUMENT_POSITION_CONTAINED_BY); // t dentro do el (ignora depois)
      // compareDocumentPosition é meio "invertido" de intuição; então fazemos um teste melhor:
      // Se el vem ANTES do t, t é "depois" e paramos.
      if (el.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING)
        break;

      if ((t.data || "").length > 0) last = t;
      n = w.nextNode();
    }
    return last;
  }

  /**
   * Primeiro TextNode depois de `el` dentro de `root` (ordem de documento).
   * @param {HTMLElement} root
   * @param {HTMLElement} el
   * @returns {Text|null}
   */
  function findNextTextNode(root, el) {
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);

    let n = w.nextNode();
    while (n) {
      const t = /** @type {Text} */ (n);
      // se t está depois do el, serve
      if (el.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING) {
        if ((t.data || "").length > 0) return t;
      }
      n = w.nextNode();
    }
    return null;
  }

  /**
   * Move a tabela 1 caractere (esquerda/direita) dentro do parágrafo.
   * - Esquerda: se não existe texto antes -> vai pro fim do parágrafo anterior.
   * - Direita: se não existe texto depois -> vai pro início do próximo parágrafo.
   * @param {HTMLElement} tblHost
   * @param {-1|1} dir
   */
  function moveTableByChar(tblHost, dir) {
    const p = tblHost.closest("p");
    if (!(p instanceof HTMLParagraphElement)) return;

    const parent = tblHost.parentNode;
    if (!parent) return;

    if (dir < 0) {
      const prevText = findPrevTextNode(p, tblHost);
      if (!prevText) {
        moveTableToPrevParagraph(tblHost);
        return;
      }

      const s = prevText.data || "";
      if (!s.length) return;

      const ch = s.slice(-1);
      prevText.data = s.slice(0, -1);
      if (!prevText.data.length) prevText.remove();

      // “tabela anda pra esquerda”: joga o char pro lado direito dela
      parent.insertBefore(document.createTextNode(ch), tblHost.nextSibling);
      return;
    }

    // dir > 0
    const nextText = findNextTextNode(p, tblHost);
    if (!nextText) {
      moveTableToNextParagraph(tblHost);
      return;
    }

    const s = nextText.data || "";
    if (!s.length) return;

    const ch = s.slice(0, 1);
    nextText.data = s.slice(1);
    if (!nextText.data.length) nextText.remove();

    // “tabela anda pra direita”: puxa 1 char da direita e põe à esquerda dela
    parent.insertBefore(document.createTextNode(ch), tblHost);
  }

  /** @param {HTMLTableElement} table */
  function selectTable(table) {
    clearTableSelection();
    table.classList.add("wx-sel-table");
    tblSel.kind = "table";
    tblSel.table = table;
    tblSel.cell = null;
    tblSel.colIndex = -1;
  }

  /** @param {HTMLTableElement} table */
  function selectCol(table, colIndex) {
    clearTableSelection();
    if (colIndex < 0) return;

    const rows = Array.from(table.querySelectorAll("tr"));
    for (const tr of rows) {
      const cells = Array.from(tr.children).filter(
        (x) => x instanceof HTMLTableCellElement,
      );
      const c = cells[colIndex];
      if (c instanceof HTMLTableCellElement) c.classList.add("wx-sel-col");
    }

    tblSel.kind = "col";
    tblSel.table = table;
    tblSel.cell = null;
    tblSel.colIndex = colIndex;
  }

  /**
   * Ctrl+click: tabela -> linha -> coluna -> tabela...
   * @param {HTMLTableCellElement} cell
   */
  function cycleTableSelection(cell) {
    const table = getCellTable(cell);
    if (!table) return;

    const sameTable = tblSel.table && tblSel.table === table;

    if (!sameTable || !tblSel.kind) {
      selectTable(table);
      return;
    }

    if (tblSel.kind === "table") {
      const row = getCellRow(cell);
      if (row) selectRow(row, table);
      else selectTable(table);
      return;
    }

    if (tblSel.kind === "row") {
      const ci = getCellColIndex(cell);
      selectCol(table, ci);
      return;
    }

    selectTable(table);
  }

  /**
   * Retorna o(s) elemento(s) alvo da seleção de tabela:
   * - kind=cell -> [td]
   * - kind=row  -> [tr]
   * - kind=table-> [table]
   * - kind=col  -> [td/th... da coluna marcada]
   * @returns {HTMLElement[]}
   */
  function getSelectedTableTargets() {
    if (!tblSel || !tblSel.kind || !tblSel.table) return [];

    if (tblSel.kind === "table") return [tblSel.table];

    if (tblSel.kind === "row") {
      const tr = tblSel.table.querySelector("tr.wx-sel-row");
      if (!(tr instanceof HTMLTableRowElement)) return [];

      return Array.from(tr.querySelectorAll("td,th")).filter(
        (x) => x instanceof HTMLElement,
      );
    }

    if (tblSel.kind === "cell") {
      const td = tblSel.table.querySelector("td.wx-sel-cell,th.wx-sel-cell");
      return td instanceof HTMLElement ? [td] : [];
    }

    if (tblSel.kind === "col") {
      return Array.from(
        tblSel.table.querySelectorAll("td.wx-sel-col,th.wx-sel-col"),
      ).filter((x) => x instanceof HTMLElement);
    }

    return [];
  }

  /**
   * Aplica borda num alvo (e ajusta border-collapse quando for table).
   * @param {HTMLElement} el
   * @param {string} cssBorder
   */
  function applyBorderToTableTarget(el, cssBorder) {
    if (el instanceof HTMLTableElement) {
      el.style.borderCollapse = "separate";
      el.style.borderSpacing = el.style.borderSpacing || "0";
      el.style.border = cssBorder;
      return;
    }
    el.style.border = cssBorder;
  }

  /**
   * Aplica radius num alvo (e garante overflow para recorte).
   * @param {HTMLElement} el
   * @param {string} cssRadius
   * @param {boolean} enable
   */
  function applyRadiusToTableTarget(el, cssRadius, enable) {
    // Se estiver dentro de uma tabela, força separate (senão radius some)
    const table = el.closest("table");
    if (table instanceof HTMLTableElement) {
      table.style.borderCollapse = "separate";
      table.style.borderSpacing = table.style.borderSpacing || "0";
    }

    el.style.borderRadius = cssRadius;
    el.style.overflow = enable ? "hidden" : "";
  }

  /* ------------------------------------------------------------------------
   PATCH: TAB / foco por teclado
   - Quando você navega entre células com TAB (ou clica dentro e o foco muda),
     o caret entra em outra <td>, mas o tblSel continuava apontando para a célula
     antiga (seleção visual ≠ célula corrente).
   - Este patch sincroniza a seleção visual (tblSel + classes wx-sel-*) com a
     célula que recebeu foco.
   --------------------------------------------------------------------- */
  document.addEventListener("focusin", (ev) => {
    const el = ev.target;
    if (!(el instanceof HTMLElement)) return;

    const cell = el.closest("td,th");
    if (!(cell instanceof HTMLTableCellElement)) return;

    // Se quiser evitar “piscar” ao focar a mesma célula, descomente:
    // if (tblSel.cell === cell && tblSel.kind === "cell") return;

    selectCell(cell);
  });

  // Clique no stage: seleção de tabela/célula (sem brigar com seleção de imagem)
  stage.addEventListener(
    "mousedown",
    (ev) => {
      // se clicou numa imagem, deixa o handler de imagem dominar
      const wxImg = closestWordexImgTarget(ev.target);
      if (wxImg) return;

      if (!(ev.target instanceof Element)) return;

      const cell = closestCell(ev.target);
      if (!cell) {
        clearTableSelection();
        return;
      }

      if (ev.ctrlKey) {
        cycleTableSelection(cell);
        ev.preventDefault();
        ev.stopPropagation();
        return;
      }

      // click simples: célula (deixa o caret funcionar normal)
      setTimeout(() => {
        if (cell.isConnected) selectCell(cell);
      }, 0);
    },
    true,
  );

  /* ------------------------------------------------------------------------
     8) Borda (img selecionada > seleção tabela/linha/col/célula > td/th > p)
     --------------------------------------------------------------------- */
  const tbBorder = document.getElementById("tbBorder");
  if (tbBorder instanceof HTMLSelectElement) {
    tbBorder.addEventListener("change", () => {
      const v = tbBorder.value;
      if (v === "") return;

      focusAndRestore();

      const color =
        tbColor instanceof HTMLInputElement ? tbColor.value : "#000";
      const cssBorder = makeCssBorder(v, color);

      const selImg = document.querySelector("wordex-img[selected]");
      if (selImg instanceof HTMLElement) {
        /** @type {any} */ const img = selImg;
        if (typeof img.border !== "undefined") img.border = cssBorder;
        else selImg.style.border = cssBorder;
        saveSelection();
        tbBorder.value = "";
        return;
      }

      // Seleção de tabela/linha/coluna/célula
      const targets = getSelectedTableTargets();
      if (targets.length) {
        targets.forEach((t) => applyBorderToTableTarget(t, cssBorder));
        saveSelection();
        tbBorder.value = "";
        return;
      }

      const td = getCurrentCell();
      if (td) {
        td.style.border = cssBorder;
        saveSelection();
        tbBorder.value = "";
        return;
      }

      const p = getCurrentParagraph();
      if (p) p.style.border = cssBorder;

      saveSelection();
      tbBorder.value = "";
    });
  }

  /* ------------------------------------------------------------------------
     9) Arredondamento (img selecionada > seleção tabela/linha/col/célula > td/th > p)
     --------------------------------------------------------------------- */
  const tbRadius = document.getElementById("tbRadius");
  if (tbRadius instanceof HTMLSelectElement) {
    tbRadius.addEventListener("change", () => {
      const v = tbRadius.value;
      if (v === "") return;

      focusAndRestore();
      const cssRadius = `${v}px`;

      const selImg = document.querySelector("wordex-img[selected]");
      if (selImg instanceof HTMLElement) {
        /** @type {any} */ const img = selImg;
        if (typeof img.borderRadius !== "undefined")
          img.borderRadius = cssRadius;
        selImg.style.borderRadius = cssRadius;
        selImg.style.overflow = v === "0" ? "" : "hidden";
        saveSelection();
        tbRadius.value = "";
        return;
      }

      // Seleção de tabela/linha/coluna/célula
      const targets = getSelectedTableTargets();
      if (targets.length) {
        const enable = v !== "0";
        targets.forEach((t) => applyRadiusToTableTarget(t, cssRadius, enable));
        saveSelection();
        tbRadius.value = "";
        return;
      }

      const td = getCurrentCell();
      if (td) {
        td.style.borderRadius = cssRadius;
        td.style.overflow = v === "0" ? "" : "hidden";
        saveSelection();
        tbRadius.value = "";
        return;
      }

      const p = getCurrentParagraph();
      if (p) {
        p.style.borderRadius = cssRadius;
        p.style.overflow = v === "0" ? "" : "hidden";
      }

      saveSelection();
      tbRadius.value = "";
    });
  }

  /**
   * Em OVR: se não há seleção, substitui 1 caractere à direita do caret.
   * @param {KeyboardEvent} e
   * @returns {boolean} true se tratou o evento (OVR), false se deixa normal (INS)
   */
  function handleOvertypeKey(e) {
    if (e.ctrlKey || e.altKey || e.metaKey) return false;
    if (e.isComposing) return false;
    if (e.key.length !== 1) return false;
    if (document.querySelector("wordex-img[selected]")) return false;

    focusAndRestore();

    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0) return false;

    const r = sel.getRangeAt(0);
    if (!r.collapsed) return false;

    const node = r.startContainer;
    if (node.nodeType !== 3) return false;

    const text = /** @type {Text} */ (node);
    const pos = r.startOffset;

    if (pos < text.data.length) {
      const rr = r.cloneRange();
      rr.setStart(text, pos);
      rr.setEnd(text, pos + 1);
      rr.deleteContents();
    }

    const ins = document.createTextNode(e.key);
    r.insertNode(ins);
    placeCaretAfter(ins);
    saveSelection();
    return true;
  }
}
