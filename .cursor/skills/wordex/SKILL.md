---
name: wordex
description: >-
  Orienta integração Wordex ↔ CRUDEX (Reports, Queries, JSON, iframe, PDF).
  Use ao implementar tabelas Reports/Queries, exportação JSON, iframe com ObterPDF,
  ou portar a macro do wordex.xlsm para runtime. Projeto em Wordex/.
---

# Wordex + CRUDEX

## Papel de cada sistema

| | **CRUDEX** | **Wordex** |
|--|------------|------------|
| Função | Dados, telas, regras, JSON | Template, layout, paginação, PDF |
| Entrada | Metadado + Query (árvore de dados) | Template HTML + JSON |
| Saída | JSON Wordex | HTML paginado + PDF |

O Wordex **não substitui** o CRUDEX. CRUDEX produz o JSON; Wordex monta o documento.

## Integração planejada (CRUDEX 1.0)

```
Menu → grid Reports (usuário escolhe template)
     → CRUDEX executa Query ligada ao relatório
     → JSON (formato Wordex)
     → iframe com template salvo (Reports.Template)
     → ObterPDF(json) → PDF
```

### Tabelas de metadado (a criar)

| Tabela | Conteúdo |
|--------|----------|
| **Reports** | Template HTML autossuficiente (💾 Salvar template Wordex), nome, descrição |
| **Queries** | Tabela raiz + relações pai-filho/FK com outras tabelas — espelho declarativo do JSON (**não** é VIEW do SQL) |

A macro VBA do `wordex.xlsm` é a **especificação** da geração JSON; em runtime vira procedure/C#.

## Arquivos Wordex

| Ambiente | Arquivos |
|----------|----------|
| **Dev** | `wordex.html`, `wordex-paged.html`, `wordex-pdf.html` (3 arquivos) |
| **Runtime / iframe** | Um `.html` por template salvo (motor + template embutidos, ~1,3 MB motor) |
| **Proto no repo** | `Wordex/Wordex 1.0.html`, `wordex.xlsm`, `crudex.json` |

Servir por **HTTP** (não confiar só em `file://`).

## Modos de execução

| Modo | Onde | Como |
|------|------|------|
| **Standalone** | Browser | `wordex.html` — editor + montagem + PDF local |
| **Frontend (iframe)** | SPA CRUDEX | Template salvo em iframe → `ObterPDF(json)` |
| **Editor de campo HTML** | Form CRUDEX (domínio HTML) | Botão no form → Wordex (editor) → grava `nvarchar(max)` do campo |
| **Backend** | API CRUDEX, **Schedulers** | Chrome headless → `ObterPDF(json)` |

Detalhes editor HTML: [reference.md §13](reference.md#13-editor-html-em-campos-do-form-crudex).

No backend: **não paginar em C#** — mesmo pipeline do iframe. O agendamento fica nos **Schedulers** do CRUDEX (metadado `Sch` / tabela futura), não em serviço Windows à parte.

## API iframe

```javascript
// mesma origem
const pdf = await iframe.contentWindow.ObterPDF(json);

// postMessage
// → { type: "wordex-obter-pdf", id, json, options }
// ← { type: "wordex-obter-pdf-result", ok, dataUri, fileName }
```

## Kind / Category — regra única

**Kind no JSON = `Categories.Name`** (Category do Type). Não há vocabulário Wordex separado.

**Obsoleto:** `Wordex_InferirKind*` (inferir Kind pelo valor da célula).

### Árvore de decisão ao embalar JSON

```
Tipo / retorno da expressão
    ├─ vetor?  → collection  (Items = vetor de objetos)
    ├─ objeto? → object      (Value = um registro)
    └─ senão   → Category explícita do Type (string, number, totals, graph, …)
```

- **`collection`** = vetor de **objetos** (cada item de `Items` é um mapa campo → `{ Kind, Value }`).
- **`object`** = um único registro (ex.: FK via `ObterRegistro`).
- Escalares e agregados (`totals`, `graph`) vêm da Category quando não é vetor nem objeto.

## Funções UDF (wordex.xlsm) — resumo

| Função | Forma | Category JSON |
|--------|-------|---------------|
| `ObterRegistros(aba)` / `ObterRegistros(aba; col; valor)` | vetor | collection |
| `ObterRegistro(aba; colChave; valor)` | objeto | object |
| `ObterRegistroTotal` (= `ObterTotal`) | vetor agregado | totals |
| `ObterGrafico` | vetor agregado | graph → Wordex consome como `histogram` |

Planilha modelo: linha 1 = nome do campo; linha 2 = Category; linha 3+ = valor ou fórmula UDF.

**ROOT** na planilha: mesma estrutura que qualquer aba (motor recursivo); Category `collection`; 1 linha no CRUDEX.

## Documentação do metamodelo

Visualizar estrutura, relacionamentos e domínios via **Reports + Queries** Wordex — substituto da planilha para **análise**. Query sobre metadado (`Tbl`, `Col`, `Ref`, `Dmn`…); fonte de verdade continua o CRUD.

- **Pré-definidos:** mantenedor SGSI pode entregar relatórios prontos com o CRUDEX (templates + queries de metadado).
- **Do usuário:** nada impede criar os seus próprios Reports/Queries sobre o mesmo metamodelo.

## Documentação

- Detalhes: [reference.md](reference.md)
- Manual operacional: `Wordex/MANUAL-WORDEX.md`
- CRUDEX geral: [../crudex/SKILL.md](../crudex/SKILL.md)
