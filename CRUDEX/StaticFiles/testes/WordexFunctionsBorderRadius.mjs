// @ts-check
'use strict'

/* ============================================================================

   (mesmo cabeçalho…)

   ========================================================================== */

/**
 * @typedef {Object} BorderRadiusCtx
 * @property {() => void} focusAndRestore
 * @property {() => void} saveSelection
 * @property {() => (HTMLTableCellElement|null)} getCurrentCell
 * @property {() => (HTMLParagraphElement|null)} getCurrentParagraph
 * @property {Document=} doc
 */

/**
 * @typedef {Object} TableBridge
 * @property {() => HTMLElement[]} getSelectedTableTargets
 * @property {(el: HTMLElement, cssBorder: string) => void} applyBorderToTableTarget
 * @property {(el: HTMLElement, cssRadius: string, enable: boolean) => void} applyRadiusToTableTarget
 */

/**
 * Instala handlers de borda e radius.
 * @param {BorderRadiusCtx} ctx
 * @param {TableBridge} table
 */
export function initBorderRadius (ctx, table) {
  const doc = ctx.doc || document

  const tbBorder = doc.getElementById('tbBorder')
  const tbRadius = doc.getElementById('tbRadius')
  const tbColor = doc.getElementById('tbColor')

  // ----------------------------
  // B O R D E R
  // ----------------------------
  if (tbBorder instanceof HTMLSelectElement) {
    tbBorder.addEventListener('change', () => {
      const v = tbBorder.value
      if (v === '') return

      ctx.focusAndRestore()

      const color =
      tbColor instanceof HTMLInputElement && tbColor.value
        ? tbColor.value
        : '#000'

      const cssBorder = makeCssBorder(v, color)

      // 1) imagem selecionada
      const selImg = doc.querySelector('wordex-img[selected]')
      if (selImg instanceof HTMLElement) {
        // @ts-expect-error - selImg pode ser Web Component com propriedade border
        const img = selImg
        if (typeof img.border !== 'undefined') img.border = cssBorder
        else selImg.style.border = cssBorder

        ctx.saveSelection()
        tbBorder.value = ''
        return
      }

      // 2) seleção de tabela/linha/col/célula
      const targets = table.getSelectedTableTargets()
      if (targets.length) {
        targets.forEach((t) => table.applyBorderToTableTarget(t, cssBorder))
        ctx.saveSelection()
        tbBorder.value = ''
        return
      }

      // 3) célula atual
      const td = ctx.getCurrentCell()
      if (td) {
        td.style.border = cssBorder
        ctx.saveSelection()
        tbBorder.value = ''
        return
      }

      // 4) parágrafo atual
      const p = ctx.getCurrentParagraph()
      if (p) p.style.border = cssBorder

      ctx.saveSelection()
      tbBorder.value = ''
    })
  }

  // ----------------------------
  // R A D I U S
  // ----------------------------
  if (tbRadius instanceof HTMLSelectElement) {
    tbRadius.addEventListener('change', () => {
      const v = tbRadius.value
      if (v === '') return

      ctx.focusAndRestore()

      const cssRadius = `${v}px`
      const enable = v !== '0'

      // 1) imagem selecionada
      const selImg = doc.querySelector('wordex-img[selected]')
      if (selImg instanceof HTMLElement) {
        // @ts-expect-error - selImg pode ser Web Component com propriedade borderRadius
        const img = selImg
        if (typeof img.borderRadius !== 'undefined') img.borderRadius = cssRadius
        selImg.style.borderRadius = cssRadius
        selImg.style.overflow = enable ? 'hidden' : ''

        ctx.saveSelection()
        tbRadius.value = ''
        return
      }

      // 2) seleção de tabela/linha/col/célula
      const targets = table.getSelectedTableTargets()
      if (targets.length) {
        targets.forEach((t) => table.applyRadiusToTableTarget(t, cssRadius, enable))
        ctx.saveSelection()
        tbRadius.value = ''
        return
      }

      // 3) célula atual
      const td = ctx.getCurrentCell()
      if (td) {
        td.style.borderRadius = cssRadius
        td.style.overflow = enable ? 'hidden' : ''
        ctx.saveSelection()
        tbRadius.value = ''
        return
      }

      // 4) parágrafo atual
      const p = ctx.getCurrentParagraph()
      if (p) {
        p.style.borderRadius = cssRadius
        p.style.overflow = enable ? 'hidden' : ''
      }

      ctx.saveSelection()
      tbRadius.value = ''
    })
  }
}

/* -------------------------------------------------------------------------- */

/**
 * Monta CSS de borda a partir do select (px) e da cor.
 * @param {string} v Valor do select ("none", "1", "2", ...)
 * @param {string | null | undefined} color Cor em hexadecimal
 * @returns {string}
 */
function makeCssBorder (v, color) {
  if (!v || v === 'none') return ''
  return `${v}px solid ${color || '#000'}`
}
