// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsTable.mjs  (initTable)
   - Seleção de tabela/linha/coluna/célula:
       * click: célula
       * ctrl+click: tabela -> linha -> coluna -> tabela...
       * focusin (TAB): sincroniza seleção visual com célula focada
   - Movimentação da tabela:
       * moveTableByChar (←/→): desloca 1 caractere atravessando parágrafos
       * moveTableToPrevParagraph / moveTableToNextParagraph (↑/↓)
   - Estilos:
       * applyBorderToTableTarget
       * applyRadiusToTableTarget
   - Util:
       * getSelectedTableHost
       * getSelectedTableTargets

   Depende do ctx (injectado por initSelection):
     - focusAndRestore()
     - saveSelection()
     - ensureParagraphAlive(p)
     - appendToParagraphEnd(p, el)

   Uso:
     import { initTable } from "./WordexFunctionsTable.mjs";
     initTable(ctx); // injeta no ctx as funções/estado de tabela
   ========================================================================== */

/**
 * @typedef {Object} TWordexCtx
 * @property {HTMLElement} stage
 * @property {any} wordex
 * @property {HTMLElement|null} modePill
 * @property {HTMLElement|null} modeText
 * @property {Range|null} savedRange
 * @property {number} alignState
 * @property {boolean} insertMode
 * @property {Document=} doc
 *
 * // vindo do initSelection:
 * @property {() => void=} focusAndRestore
 * @property {() => void=} saveSelection
 * @property {(p:HTMLParagraphElement)=>void=} ensureParagraphAlive
 * @property {(p:HTMLParagraphElement, el:HTMLElement)=>void=} appendToParagraphEnd
 */

/**
 * @param {TWordexCtx} ctx
 */
export function initTable(ctx) {
  const doc = ctx.doc || document;
  const stage = ctx.stage;

  if (!(stage instanceof HTMLElement)) throw new Error("stage inválido.");
  if (typeof ctx.ensureParagraphAlive !== "function") throw new Error("initSelection não instalado (ensureParagraphAlive).");
  if (typeof ctx.appendToParagraphEnd !== "function") throw new Error("initSelection não instalado (appendToParagraphEnd).");

  // CSS 1x (visual simples)
  (function ensureTableSelCss() {
    const id = "wordex-table-sel-css";
    if (doc.getElementById(id)) return;
    const st = doc.createElement("style");
    st.id = id;
    st.textContent = `
      .wx-sel-cell  { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-row   { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-col   { outline: 2px solid #22ff22; outline-offset: -2px; }
      .wx-sel-table { outline: 2px solid #22ff22; outline-offset: -2px; }
    `;
    doc.head.appendChild(st);
  })();

  /** @type {{ kind: "cell"|"row"|"col"|"table"|null, table: HTMLTableElement|null, cell: HTMLTableCellElement|null, colIndex: number }} */
  let tblSel = { kind: null, table: null, cell: null, colIndex: -1 };

  function clearTableSelection() {
    doc
      .querySelectorAll(".wx-sel-cell,.wx-sel-row,.wx-sel-col,.wx-sel-table")
      .forEach((el) => {
        el.classList.remove("wx-sel-cell", "wx-sel-row", "wx-sel-col", "wx-sel-table");
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
    const cells = Array.from(row.children).filter((x) => x instanceof HTMLTableCellElement);
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
      const cells = Array.from(tr.children).filter((x) => x instanceof HTMLTableCellElement);
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
   * Retorna o elemento "movível" da tabela:
   * - se o <table> está num ShadowRoot, retorna o host <wordex-tbl>
   * - senão: tenta closest("wordex-tbl")
   * - fallback: o próprio <table>
   * @returns {HTMLElement|null}
   */
  function getSelectedTableHost() {
    const t = tblSel.table;
    if (!t || !t.isConnected) return null;

    const root = t.getRootNode();
    if (root instanceof ShadowRoot) {
      const host = root.host;
      if (host instanceof HTMLElement && host.tagName === "WORDEX-TBL") return host;
    }

    const host = t.closest("wordex-tbl");
    return host instanceof HTMLElement ? host : t;
  }

  /**
   * Retorna o(s) elemento(s) alvo da seleção de tabela:
   * - kind=cell -> [td]
   * - kind=row  -> [td/th... da linha]
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
      return Array.from(tr.querySelectorAll("td,th")).filter((x) => x instanceof HTMLElement);
    }

    if (tblSel.kind === "cell") {
      const td = tblSel.table.querySelector("td.wx-sel-cell,th.wx-sel-cell");
      return td instanceof HTMLElement ? [td] : [];
    }

    if (tblSel.kind === "col") {
      return Array.from(tblSel.table.querySelectorAll("td.wx-sel-col,th.wx-sel-col")).filter(
        (x) => x instanceof HTMLElement,
      );
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
    const table = el.closest("table");
    if (table instanceof HTMLTableElement) {
      table.style.borderCollapse = "separate";
      table.style.borderSpacing = table.style.borderSpacing || "0";
    }
    el.style.borderRadius = cssRadius;
    el.style.overflow = enable ? "hidden" : "";
  }

  /* ------------------------------------------------------------------------
     Movimentação entre parágrafos
     --------------------------------------------------------------------- */

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
          if (curP instanceof HTMLParagraphElement) ctx.ensureParagraphAlive(curP);
          ctx.appendToParagraphEnd(prevP, tblHost);
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
    ctx.ensureParagraphAlive(p);
    ctx.appendToParagraphEnd(prev, tblHost);
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
          if (curP instanceof HTMLParagraphElement) ctx.ensureParagraphAlive(curP);

          const first = nextP.firstChild;
          if (first && first.nodeType === 1 && /** @type {Element} */ (first).tagName === "BR") {
            nextP.insertBefore(tblHost, first);
          } else {
            nextP.insertBefore(tblHost, nextP.firstChild);
          }
          ctx.ensureParagraphAlive(nextP);
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
    ctx.ensureParagraphAlive(p);

    const first = next.firstChild;
    if (first && first.nodeType === 1 && /** @type {Element} */ (first).tagName === "BR") {
      next.insertBefore(tblHost, first);
    } else {
      next.insertBefore(tblHost, next.firstChild);
    }
    ctx.ensureParagraphAlive(next);
    return true;
  }

  /**
   * Último TextNode antes de `el` dentro de `root` (ordem de documento).
   * @param {HTMLElement} root
   * @param {HTMLElement} el
   * @returns {Text|null}
   */
  function findPrevTextNode(root, el) {
    const w = doc.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    /** @type {Text|null} */
    let last = null;

    let n = w.nextNode();
    while (n) {
      const t = /** @type {Text} */ (n);

      if (el.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING) break;

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
    const w = doc.createTreeWalker(root, NodeFilter.SHOW_TEXT);

    let n = w.nextNode();
    while (n) {
      const t = /** @type {Text} */ (n);
      if (el.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING) {
        if ((t.data || "").length > 0) return t;
      }
      n = w.nextNode();
    }
    return null;
  }

  /**
   * Move a tabela 1 caractere (esquerda/direita) dentro do parágrafo.
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

      parent.insertBefore(doc.createTextNode(ch), tblHost.nextSibling);
      return;
    }

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

    parent.insertBefore(doc.createTextNode(ch), tblHost);
  }

  /* ------------------------------------------------------------------------
     Binding: clique e TAB
     --------------------------------------------------------------------- */

  function bindTableSelection() {
    // TAB/focus: sincroniza seleção visual com célula atual
    doc.addEventListener("focusin", (ev) => {
      const el = ev.target;
      if (!(el instanceof HTMLElement)) return;

      const cell = el.closest("td,th");
      if (!(cell instanceof HTMLTableCellElement)) return;

      selectCell(cell);
    });

    // Clique no stage: seleção de tabela/célula
    stage.addEventListener(
      "mousedown",
      (ev) => {
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

        setTimeout(() => {
          if (cell.isConnected) selectCell(cell);
        }, 0);
      },
      true,
    );
  }

  // -----------------------
  // Exporta no ctx
  // -----------------------
  Object.defineProperty(ctx, "tblSel", { get: () => tblSel });

  ctx.bindTableSelection = bindTableSelection;

  ctx.clearTableSelection = clearTableSelection;
  ctx.selectCell = selectCell;
  ctx.selectTable = selectTable;
  ctx.selectRow = selectRow;
  ctx.selectCol = selectCol;

  ctx.getSelectedTableHost = getSelectedTableHost;
  ctx.getSelectedTableTargets = getSelectedTableTargets;

  ctx.moveTableByChar = moveTableByChar;
  ctx.moveTableToPrevParagraph = moveTableToPrevParagraph;
  ctx.moveTableToNextParagraph = moveTableToNextParagraph;

  ctx.applyBorderToTableTarget = applyBorderToTableTarget;
  ctx.applyRadiusToTableTarget = applyRadiusToTableTarget;
}
