// @ts-check
'use strict'

/* ============================================================================
   WordexFunctionsFormat.mjs
   - data-cmd: bold/italic/underline/etc.
   - FIX: funciona dentro de ShadowRoot (Wordex WC) SEM depender de execCommand.
          * Se houver seleção: envolve em <span style=...>
          * Se estiver colapsado (caret): cria um <span> com ZWSP e deixa o caret
            “dentro” dele (pra você digitar já formatado). Clicar de novo no mesmo
            botão, estando dentro desse span, remove o span.
   ========================================================================== */

/**
 * @typedef {Object} FormatCtx
 * @property {() => void} focusAndRestore
 * @property {() => void} saveSelection
 * @property {Document=} doc
 */

/**
 * @param {FormatCtx} ctx
 */
export function initFormat (ctx) {
  const doc = ctx.doc || document

  // 1) Botões data-cmd
  doc.querySelectorAll('button[data-cmd]').forEach((btn) => {
    if (!(btn instanceof HTMLButtonElement)) return

    btn.addEventListener('click', () => {
      const cmd = String(btn.dataset.cmd || '').toLowerCase()
      if (!cmd) return

      ctx.focusAndRestore()

      // para bold/italic/underline: usa engine própria (shadow-safe)
      if (cmd === 'bold' || cmd === 'italic' || cmd === 'underline') {
        toggleInline(cmd, doc)
        ctx.saveSelection()
        return
      }

      // demais: tenta execCommand (pra fora do shadow / casos simples)
      doc.execCommand(btn.dataset.cmd)
      ctx.saveSelection()
    })
  })

  // 2) Alinhamento
  installAlign(doc, ctx)

  // 3) Fonte / tamanho / cor
  installFontSizeColor(doc, ctx)
}

/* -------------------------------------------------------------------------- */

function installAlign (doc, ctx) {
  const tbAlign = doc.getElementById('tbAlign')
  if (!(tbAlign instanceof HTMLButtonElement)) return

  /** @type {0|1|2|3} */
  let alignState = 0
  const order = ['justifyLeft', 'justifyCenter', 'justifyRight', 'justifyFull']

  tbAlign.addEventListener('click', () => {
    ctx.focusAndRestore()
    const next = /** @type {0|1|2|3} */ ((alignState + 1) % 4)
    doc.execCommand(order[next])
    alignState = next
    ctx.saveSelection()
  })
}

function installFontSizeColor (doc, ctx) {
  const tbFont = doc.getElementById('tbFont')
  if (tbFont instanceof HTMLSelectElement) {
    tbFont.addEventListener('change', () => {
      const v = tbFont.value
      if (!v) return
      ctx.focusAndRestore()
      doc.execCommand('fontName', false, v)
      ctx.saveSelection()
      tbFont.value = ''
    })
  }

  const tbSize = doc.getElementById('tbSize')
  if (tbSize instanceof HTMLSelectElement) {
    tbSize.addEventListener('change', () => {
      const v = tbSize.value
      if (!v) return
      ctx.focusAndRestore()
      doc.execCommand('fontSize', false, v)
      ctx.saveSelection()
      tbSize.value = ''
    })
  }

  const tbColor = doc.getElementById('tbColor')
  if (tbColor instanceof HTMLInputElement) {
    tbColor.addEventListener('input', () => {
      const v = tbColor.value
      if (!v) return
      ctx.focusAndRestore()
      doc.execCommand('foreColor', false, v)
      ctx.saveSelection()
    })
  }
}

/* -------------------------------------------------------------------------- */
/* Shadow-safe inline toggles                                                  */
/* -------------------------------------------------------------------------- */

const WX_INLINE_ATTR = 'data-wx-inline'

/**
 * @param {"bold"|"italic"|"underline"} cmd
 * @param {Document} doc
 */
function toggleInline (cmd, doc) {
  const sel = doc.getSelection()
  if (!sel || sel.rangeCount === 0) return

  const r = sel.getRangeAt(0)
  if (!r) return

  const style = styleFor(cmd)

  // 1) Se tem seleção: envolve
  if (!r.collapsed) {
    wrapRangeWithSpan(r, style, doc)
    return
  }

  // 2) Caret colapsado:
  //    Se já está dentro de um span wx-inline desse cmd -> remove
  const host = closestInlineSpanAtCaret(sel, doc, cmd)
  if (host) {
    unwrapSpanKeepCaret(host, doc)
    return
  }

  //    Senão cria span com ZWSP e põe o caret dentro
  insertInlineSpanAtCaret(r, style, cmd, doc)
}

/**
 * @param {"bold"|"italic"|"underline"} cmd
 * @returns {Partial<CSSStyleDeclaration>}
 */
function styleFor (cmd) {
  if (cmd === 'bold') return { fontWeight: '700' }
  if (cmd === 'italic') return { fontStyle: 'italic' }
  return { textDecoration: 'underline' }
}

/**
 * @param {Range} range
 * @param {Partial<CSSStyleDeclaration>} css
 * @param {Document} doc
 */
function wrapRangeWithSpan (range, css, doc) {
  const frag = range.extractContents()
  const span = doc.createElement('span')
  span.setAttribute(WX_INLINE_ATTR, '1')
  Object.assign(span.style, css)
  span.appendChild(frag)
  range.insertNode(span)

  // seleciona o conteúdo aplicado
  const sel = doc.getSelection()
  if (sel) {
    sel.removeAllRanges()
    const r2 = doc.createRange()
    r2.selectNodeContents(span)
    sel.addRange(r2)
  }
}

/**
 * Se caret está dentro de um span wx-inline compatível, retorna ele.
 * @param {Selection} sel
 * @param {Document} doc
 * @param {"bold"|"italic"|"underline"} cmd
 * @returns {HTMLSpanElement|null}
 */
function closestInlineSpanAtCaret (sel, doc, cmd) {
  const n = sel.anchorNode
  if (!n) return null

  const el = n.nodeType === 1 ? /** @type {Element} */ (n) : n.parentElement
  if (!el) return null

  const span = el.closest(`span[${WX_INLINE_ATTR}]`)
  if (!(span instanceof HTMLSpanElement)) return null

  // confirma que é do tipo do cmd (batendo estilo)
  if (cmd === 'bold' && span.style.fontWeight) return span
  if (cmd === 'italic' && span.style.fontStyle) return span
  if (cmd === 'underline' && span.style.textDecoration) return span

  // se não tem estilo inline (pode ter herdado), não mexe
  return null
}

/**
 * Cria <span wx-inline>ZWSP</span> e posiciona caret dentro.
 * @param {Range} r
 * @param {Partial<CSSStyleDeclaration>} css
 * @param {"bold"|"italic"|"underline"} cmd
 * @param {Document} doc
 */
function insertInlineSpanAtCaret (r, css, cmd, doc) {
  const span = doc.createElement('span')
  span.setAttribute(WX_INLINE_ATTR, cmd)
  Object.assign(span.style, css)

  // ZWSP: garante que o caret “entre” no span
  const zwsp = doc.createTextNode('\u200B')
  span.appendChild(zwsp)

  r.insertNode(span)

  // caret dentro do span (após o ZWSP)
  const sel = doc.getSelection()
  if (!sel) return

  sel.removeAllRanges()
  const rr = doc.createRange()
  rr.setStart(zwsp, 1)
  rr.collapse(true)
  sel.addRange(rr)
}

/**
 * Remove o span e mantém o caret no lugar (aproximado).
 * @param {HTMLSpanElement} span
 * @param {Document} doc
 */
function unwrapSpanKeepCaret (span, doc) {
  const parent = span.parentNode
  if (!parent) return

  // pega texto interno sem o ZWSP
  const text = span.textContent ? span.textContent.replace(/\u200B/g, '') : ''

  const tn = doc.createTextNode(text)
  parent.insertBefore(tn, span)
  span.remove()

  // caret no final do texto inserido
  const sel = doc.getSelection()
  if (!sel) return

  sel.removeAllRanges()
  const r = doc.createRange()
  r.setStart(tn, tn.data.length)
  r.collapse(true)
  sel.addRange(r)
}
