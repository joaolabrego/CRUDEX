// @ts-check
"use strict";

/* ============================================================================
   WordexFunctionsToolbar.mjs  (initToolbar)
   - Toolbar não rouba caret (mousedown preventDefault em botões).
   - Botões data-cmd via execCommand.
   - Fonte / Tamanho / Cor.
   - Orientação retrato/paisagem.
   - Alinhamento cíclico: 0->1->2->3->0 (Left, Center, Right, Justify)

   Depende do ctx (injectado por initSelection):
     - saveSelection()
     - focusAndRestore()
   Usa/atualiza:
     - ctx.alignState (number)
   ========================================================================== */

/**
 * @typedef {Object} TWordexCtx
 * @property {() => void=} saveSelection
 * @property {() => void=} focusAndRestore
 * @property {number=} alignState
 * @property {Document=} doc
 */

/**
 * @param {TWordexCtx} ctx
 */
export function initToolbar(ctx) {
  const doc = ctx.doc || document;

  if (typeof ctx.saveSelection !== "function") throw new Error("initSelection não instalado (saveSelection).");
  if (typeof ctx.focusAndRestore !== "function") throw new Error("initSelection não instalado (focusAndRestore).");

  // ------------------------------------------------------------
  // 0) Toolbar não rouba foco
  // ------------------------------------------------------------
  doc.querySelectorAll(".topbar button").forEach((el) => {
    el.addEventListener(
      "mousedown",
      (ev) => {
        ctx.saveSelection();
        ev.preventDefault(); // impede focus no botão
      },
      true,
    );
  });

  doc.querySelectorAll(".topbar select, .topbar input").forEach((el) => {
    el.addEventListener(
      "mousedown",
      () => {
        ctx.saveSelection(); // deixa abrir normal
      },
      true,
    );
  });

  // ------------------------------------------------------------
  // 1) Alinhamento (cíclico 0->1->2->3->0)
  // ------------------------------------------------------------
  const tbAlign = doc.getElementById("tbAlign");
  if (tbAlign instanceof HTMLButtonElement) {
    const order = ["justifyLeft", "justifyCenter", "justifyRight", "justifyFull"];

    if (typeof ctx.alignState !== "number") ctx.alignState = 0;

    tbAlign.addEventListener("click", () => {
      ctx.focusAndRestore();

      const next = (ctx.alignState + 1) % order.length;
      doc.execCommand(order[next]);
      ctx.alignState = next;

      ctx.saveSelection();
    });
  }

  // ------------------------------------------------------------
  // 2) Botões de formatação (data-cmd)
  // ------------------------------------------------------------
  doc.querySelectorAll("button[data-cmd]").forEach((btn) => {
    if (!(btn instanceof HTMLButtonElement)) return;
    btn.addEventListener("click", () => {
      const cmd = btn.dataset.cmd;
      if (!cmd) return;
      ctx.focusAndRestore();
      doc.execCommand(cmd);
      ctx.saveSelection();
    });
  });

  // ------------------------------------------------------------
  // 3) Fonte / Tamanho / Cor
  // ------------------------------------------------------------
  const tbFont = doc.getElementById("tbFont");
  if (tbFont instanceof HTMLSelectElement) {
    tbFont.addEventListener("change", () => {
      const v = tbFont.value;
      if (!v) return;
      ctx.focusAndRestore();
      doc.execCommand("fontName", false, v);
      ctx.saveSelection();
      tbFont.value = "";
    });
  }

  const tbSize = doc.getElementById("tbSize");
  if (tbSize instanceof HTMLSelectElement) {
    tbSize.addEventListener("change", () => {
      const v = tbSize.value;
      if (!v) return;
      ctx.focusAndRestore();
      doc.execCommand("fontSize", false, v);
      ctx.saveSelection();
      tbSize.value = "";
    });
  }

  const tbColor = doc.getElementById("tbColor");
  if (tbColor instanceof HTMLInputElement) {
    tbColor.addEventListener("input", () => {
      const v = tbColor.value;
      if (!v) return;
      ctx.focusAndRestore();
      doc.execCommand("foreColor", false, v);
      ctx.saveSelection();
    });
    ctx.tbColor = tbColor;
  } else {
    ctx.tbColor = null;
  }

  // ------------------------------------------------------------
  // 4) Orientação: Retrato / Paisagem
  // ------------------------------------------------------------
  const tbOrientation = doc.getElementById("tbOrientation");
  if (tbOrientation instanceof HTMLButtonElement) {
    tbOrientation.addEventListener("click", () => {
      ctx.saveSelection();
      ctx.focusAndRestore();

      const page = doc.querySelector(".page");
      if (!(page instanceof HTMLElement)) return;

      page.classList.toggle("landscape");
      ctx.saveSelection();
    });
  }
}
