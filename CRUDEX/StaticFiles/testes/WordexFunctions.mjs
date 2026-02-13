// @ts-check
'use strict'

import { TWordex } from './Wordex.mjs'

// CSS (injeções 1x)
import { ensureModeCss } from './WordexFunctionsCss.mjs'

// Módulos (todos em init*)
import { initSelection } from './WordexFunctionsSelect.mjs'
import { initToolbar } from './WordexFunctionsToolbar.mjs'
import { initFormat } from './WordexFunctionsFormat.mjs'
import { initBorderRadius } from './WordexFunctionsBorderRadius.mjs'
import { initOrientation } from './WordexFunctionsOrientation.mjs'
import { initInsert } from './WordexFunctionsInsert.mjs'
import { initImage } from './WordexFunctionsImage.mjs'
import { initTable } from './WordexFunctionsTable.mjs'
import { initOvertype } from './WordexFunctionsOvertype.mjs'

/** Compat: mantém seu HTML atual com `import { WordexFunctions } ...` */
export const WordexFunctions = { Main}

/** Recomendado: `import { Main } ...` */
export function Main () {
  // 1) CSS base
  ensureModeCss()

  // 2) Torna header/body/footer editáveis
  document.querySelectorAll('.editable').forEach((ed) => {
    if (!(ed instanceof HTMLElement)) return
    ed.contentEditable = 'true'
    ed.spellcheck = false
  })

  // 3) Instancia Wordex
  const stage = document.getElementById('stage')
  const modePill = document.getElementById('modePill')
  const modeText = document.getElementById('modeText')

  if (!(stage instanceof HTMLElement)) throw new Error('stage inválido.')

  const wordex = new TWordex({
    stage,
    modePill: modePill instanceof HTMLElement ? modePill : null,
    modeText: modeText instanceof HTMLElement ? modeText : null,
    maxHeaderFooterParagraphs: 10
  })

  if (typeof wordex.init === 'function') wordex.init()

  // 4) Contexto compartilhado (mínimo)
  // @ts-expect-error - ctx é expandido dinamicamente por diferentes módulos (initSelection, initToolbar, etc.)
  /** @type {any} */
  const ctx = {
    stage,
    wordex,
    modePill: modePill instanceof HTMLElement ? modePill : null,
    modeText: modeText instanceof HTMLElement ? modeText : null,

    // estados globais
    savedRange: /** @type {Range|null} */ (null),
    alignState: 0,
    insertMode: true
  }

  // 5) Inicializa módulos (ordem)
  initSelection(ctx)
  initToolbar(ctx)
  initFormat(ctx)
  initBorderRadius(ctx)
  initOrientation(ctx)
  initInsert(ctx)
  initTable(ctx)
  initImage(ctx)
  initOvertype(ctx)
}
