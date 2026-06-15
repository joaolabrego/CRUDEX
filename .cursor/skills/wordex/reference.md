# Wordex + CRUDEX — Referência técnica

> Decisões de arquitetura registradas para implementação Wordex no CRUDEX 1.0.  
> Última revisão: junho/2026.

---

## 0. Origem do desenho

No **Clipper** (década de 1990), o autor já havia implementado uma classe **Report** muito completa, com **OOP emulada por vetores** (estruturas próprias). Esse modelo antecipa o que hoje virou:

- árvore de dados recursiva (tabelas / filhos / critérios)
- totais e agrupamentos por nível
- separação entre **fonte de dados** e **layout do documento**

O CRUDEX (`TRecordSet`, Queries, metadado) e o Wordex (JSON + template + PDF) são a mesma ideia em stack web — década de 90 no Clipper, 2020s na web; o contrato JSON e o iframe fecham o ciclo.

**GAS** (Harbour, **2021**): `GAS/` — Gerador Automático de Sistema, CUI, menu até `WaitKey`/`MenuModal`; desistiu antes do TBrowse. Em seguida: **PHP → Node.js → C#** (CRUDEX atual). O `readme.txt` do GAS cita versão `GAS20210606`.

---

## 1. Visão geral

```
CRUDEX (Queries)  →  JSON  →  Wordex: objeto Tabela (+ outros)  →  PDF
         ↑ dados                    ↑ relatório de verdade (layout)
    Reports (template HTML)
```

- **Query / JSON** = motor de **dados** (árvore recursiva, totais, coleções).
- **Relatório de verdade** = objeto **Tabela** do Wordex: Header / Group / Detail / Footer, domínio, macros por célula, repetição por `Items`. Gráficos, textboxes e imagens complementam; a banda linha a linha é a tabela.
- **Macros de sistema** (`@PageNumber`, `@PageCount`, `@Today`, …) = Wordex na paginação; **não** vêm do CRUDEX/JSON.

O CRUDEX não desenha o relatório — alimenta o JSON. O Wordex não modela a árvore de negócio — consome o JSON na **tabela** (e demais objetos).

- **Reports**: templates HTML salvos (autossuficientes).
- **Queries**: metadado de dados — tabela raiz + relações; **não** é `VIEW` do SQL.
- **Macro** (`wordex.xlsm`): spec da geração JSON para portagem ao CRUDEX.

### Caso de uso real (trabalho — independente do CRUDEX)

Serviço que gerava **cartas RDLC → PDF → e-mail**; RDLC falhava esporadicamente. **Solução no trabalho:** HTML em **C# linha a linha** + **IronPDF** — permanece assim; o CRUDEX **não** entra nesse ambiente (projeto pessoal / SoftLab).

O desenho CRUDEX + Wordex + Scheduler é **paralelo** ao mesmo problema (carta agendada por e-mail), não substituto do que roda no emprego.

---

## 2. Wordex — modos de arquivo

### Desenvolvimento (3 arquivos)

| Arquivo | Função |
|---------|--------|
| `wordex.html` | Editor, toolbar, `ObterPDF` |
| `wordex-paged.html` | Paginação A4, header/footer |
| `wordex-pdf.html` | Captura → PDF |

### Template salvo (runtime)

- Botão **💾 Salvar template HTML** gera **um único `.html`**.
- Incorpora motor Wordex + templates embutidos (`wordexEmbeddedTemplates`) + documento (`wordexSavedDocument`).
- Motor ~1,3 MB; template pode crescer muito com imagens base64 — **sem limite artificial** (trade-off do usuário).

### Paginação e formatos de página

Toolbar **Página**: séries **A0–A10**, **B**, **C**, Letter, Legal, ANSI, etc. + retrato/paisagem.

**Formato personalizado** (planejado / em evolução): usuário define **largura e altura** (mm) do “pergaminho” — qualquer documento físico:

| Exemplo | Uso |
|---------|-----|
| A4 / A3 | Relatório, carta |
| Personalizado pequeno | **Crachá**, tag |
| Personalizado + grade de etiquetas | **Etiquetas** (dimensões da folha e da etiqueta no formato custom) |

Mesmo motor (tabela Wordex, Query, `ObterPDF`); só muda `PAGE_WIDTH` / `PAGE_HEIGHT` na paginação. Report CRUD guarda o template já com o formato escolhido.

---

## 3b. Backend — API e Schedulers CRUDEX (Chrome headless)

Além do iframe, o Wordex roda **sem browser do usuário** — acionado pela **API** do CRUDEX ou por **Schedulers** (tarefas agendadas no próprio metadado). **Não** há Windows Service Wordex separado.

```text
Scheduler CRUDEX (quando executar)
    → Script/URL ou ação interna
    → Query → JSON
    → headless: ObterPDF(json) com Reports.Template
    → PDF (disco, e-mail, etc.)
```

| Variante | Ferramenta | Quando |
|----------|------------|--------|
| **A — ObterPDF** | Playwright / Puppeteer chama `ObterPDF(json)` | Preferida — um passo, igual ao iframe |
| **B — Chrome print** | Headless gera HTML `.pagex-page` → `WordexChromePdf` | HTML paginado já salvo |

**Regras:**

- **Não** implementar paginação em C# — usa `wordex-paged.html` (DOM/JS).
- Servir arquivos por **HTTP** (não `file://` no headless).
- Servir template Wordex por **HTTP** no host CRUDEX (não `file://` no headless).
- Agendamento = **Schedulers** do CRUDEX (`Sch` no Novíssimo), não serviço Windows dedicado.

O CRUDEX expõe endpoint ou tarefa agendada que monta JSON da Query e chama headless — usuário final não precisa de iframe.

### Dashboard

Não é produto separado: **um Report** (template HTML Wordex) com **várias tabelas** (e gráficos) no mesmo layout; **uma Query por tabela/fonte** — cada objeto Wordex consome a collection/campo da sua Query no JSON (ROOT com vários filhos escalares/collections).

Arquivos de apoio no projeto Wordex dev: `helpBACKEND.txt`, `helpCHROME.txt` (referência headless; o cron vive no CRUDEX).

---

## 3. API iframe

### Chamada direta (mesma origem HTTP)

```javascript
const dataUri = await iframe.contentWindow.ObterPDF(json);
// data:application/pdf;base64,...
```

### postMessage

```javascript
// CRUDEX → Wordex
{ type: "wordex-obter-pdf", id: "...", json: {...}, options: {...} }

// Wordex → CRUDEX
{ type: "wordex-obter-pdf-result", id: "...", ok: true, dataUri: "...", fileName: "..." }
```

`ObterPDF` monta, pagina e captura internamente — usuário não precisa salvar HTML intermediário.

---

## 4. Formato JSON

Exemplo: `Wordex/crudex.json`.

### Macros de sistema (Wordex — não vêm do JSON/CRUDEX)

Resolvidas pelo **motor Wordex** na montagem/paginação (`resolveSystemMacroValue`). Sintaxe `{{@Nome}}` ou inserção via combo **Campo** (prefixo `@`). **Não** precisam de JSON carregado.

| Macro | Função |
|-------|--------|
| `@PageNumber` | Página atual (resolvida após paginação — *deferred*) |
| `@PageCount` | Total de páginas (*deferred*) |
| `@Today` | Data de geração (formato local) |
| `@Now` | Data e hora de geração |
| `@DateISO` | `AAAA-MM-DD` |
| `@Time` | Hora |
| `@Year` / `@Month` / `@Day` | Partes da data de geração |

`@PageNumber` e `@PageCount` só têm valor **após a paginação** (header/footer, textboxes). Antes disso o relatório é fluxo contínuo — “rolo de pergaminho”; a quebra em páginas A4 é que define página atual e total.

Data/hora usam `generationTime` do relatório (conhecidas antes da paginação).

**Macros de dados** (`{{Nome}}`, `{{Clientes.Nome}}`, …) vêm do JSON gerado pela **Query** no CRUDEX.

### Wrapper por campo

```json
"Nome": { "Kind": "string", "Value": "Evadin S/A" }
```

### Collection (vetor de objetos)

```json
"Clientes": {
  "Kind": "collection",
  "Items": [
    {
      "ClienteId": { "Kind": "number", "Value": 1 },
      "Nome": { "Kind": "string", "Value": "João Silva" },
      "Produtos": { "Kind": "collection", "Items": [ ... ] }
    }
  ]
}
```

Cada elemento de `Items` é um **objeto** (mapa de campos), não escalar.

### Object (registro único)

```json
"Categoria": {
  "Kind": "object",
  "Value": {
    "CategoriaId": { "Kind": "number", "Value": 1 },
    "Nome": { "Kind": "string", "Value": "Eletrônico" }
  }
}
```

### Layout típico de relatório (ex.: `crudex.json`)

O JSON exportado trata **ROOT como `collection`** — recomenda-se **apenas uma linha** em `Items` (um registro de envelope). O arquivo pode ser o array `Items` ou array com um único elemento; o Wordex usa macros no contexto **ROOT**.

```text
ROOT (collection, Items[0] recomendado)
├── Nome, CNPJ, Logotipo …     ← escalares (cabeçalho)
├── Clientes (collection)      ← corpo do relatório (tudo aninhado aqui)
│     └── Items[]
│           ├── campos do cliente
│           ├── Produtos (collection)
│           ├── TotaisProdutos (totals)      ← por cliente
│           └── TotaisProdutosGrafico (graph) ← por cliente
├── TotaisProdutosGerais (totals)            ← total geral (ROOT)
└── TotaisProdutosGrafico (graph/histogram)  ← gráfico geral (ROOT)
```

**Regras:**

- **ROOT** = `collection` (não `object`) — mesmo com 1 linha só. Motivo: `object` no vocabulário CRUDEX/Wordex é registro único aninhado (ex.: FK `ObterRegistro` / `Categoria`); usar `object` no envelope ROOT geraria confusão. `collection` com `Items[0]` deixa a forma explícita (vetor) sem ambiguidade.
- **CRUDEX:** a Query valida ROOT — **apenas 1 linha permitida** (regra de metadado/runtime). No **Excel** (`wordex.xlsm`) não há como impedir várias linhas; é protótipo/design livre.
- O **detalhe** (linhas, filhos, totais/gráficos **por grupo**) fica **dentro** de `Clientes`.
- **Total geral** e **gráfico geral** ficam no **mesmo item ROOT**, como irmãos de `Clientes` — fórmulas `ObterRegistroTotal` / `ObterGrafico` **sem** critério de filho (`""` no agrupamento/filtro).

Isso orienta a **Query**: nó ROOT = `collection` (1 registro); tabela raiz do **detalhe** = `Clientes`; agregados globais = colunas no item ROOT, não dentro de `Clientes`.

### Totals e graph

```json
"TotaisProdutos": {
  "Kind": "totals",
  "Items": [{ "PreçoSum": { "Kind": "string", "Value": "150,00" }, ... }]
}
"TotaisProdutosGrafico": {
  "Kind": "graph",
  "Items": [{
    "PreçoSum": { "Kind": "string", "Value": "150,00" },
    "PreçoSum_Label": { "Kind": "string", "Value": "Preço" }
  }]
}
```

No consumidor Wordex, `graph` é tratado como **`histogram`** nos gráficos.

---

## 5. Kind = Category

**`Kind` no JSON = `Categories.Name`** do tipo (via `Type` → `Category`).

Não existe enum Kind separado do metadado CRUDEX.

### Obsoleto

- `Wordex_InferirKind`, `Wordex_InferirKindDatasource`, inferência de Kind pelo **valor** da célula.

### Regra atual — embalagem

```
1. Retorno é vetor?     → Kind = collection
2. Retorno é objeto?    → Kind = object
3. Senão                → Kind = Category.Name do Type (string, number, date, totals, graph, …)
```

- Inferência **estrutural** (vetor vs objeto): OK — vem da forma do tipo/retorno, não do conteúdo.
- Escalares e agregados especiais: Category **explícita** no Type.

### Categorias CRUDEX 1.0 (existentes)

`string`, `number`, `date`, `datetime`, `time`, `text`, `boolean`, `image`, `binary`, `undefined`.

### Categorias Wordex / Queries (estender ou alinhar)

`collection`, `object`, `totals`, `graph` — entram no catálogo `Categories` ou são deduzidas por forma (collection/object) + Category para totals/graph.

---

## 6. wordex.xlsm — planilha como Query (protótipo)

### Abas = tabelas

Ex.: `ROOT`, `Clientes`, `Produtos`, `Categorias`.

**ROOT é tabela como qualquer outra** — sem ramo especial no código. `ObterRegistros` / `GerarJson` são **recursivos**: para cada coluna cujo retorno é filho (`collection`, etc.), descem à aba referenciada com o mesmo algoritmo (campos linha 1/2, linhas 3+, critérios de filtro). Convenções de produto (1 linha, `collection` vs `object`) não alteram a recursão.

### Layout por aba

| Linha | Conteúdo |
|-------|----------|
| **1** | Nome do campo no JSON |
| **2** | Category (`string`, `collection`, `totals`, `graph`, `image`, `object`, `number`, …) |
| **3+** | Valor fixo **ou** fórmula UDF |

### Exemplo ROOT (linha 3)

| Coluna | Fórmula |
|--------|---------|
| Clientes | `=ObterRegistros("Clientes")` |
| TotaisProdutosGerais | `=ObterRegistroTotal("Produtos"; ""; "Preço, Quantidade"; "Sum")` |
| TotaisProdutosGrafico | `=ObterGrafico("Produtos"; ""; "Preço, Quantidade"; "Sum")` |

### Exemplo Clientes (por linha, filho filtrado)

```excel
=ObterRegistros("Produtos"; "ClienteId"; A3)
=ObterRegistroTotal("Produtos"; ""; "Preço, Quantidade"; "Sum"; "ClienteId"; A3)
=ObterGrafico("Produtos"; ""; "Preço, Quantidade"; "Sum"; "ClienteId"; A3)
```

### Exemplo Produtos (FK → object)

```excel
=ObterRegistro("Categorias"; "CategoriaId"; C3)
```

---

## 7. Funções UDF (VBA) — referência

### ObterRegistros

```excel
=ObterRegistros("Clientes")
=ObterRegistros("Produtos"; "ClienteId"; A3)
```

- Lê aba a partir da linha 3.
- Colunas escalares → `{ Kind, Value }` com Category explícita (linha 2).
- Colunas collection/totals/graph → avalia UDF filha recursivamente.
- Critérios opcionais: pares `NomeColuna, Valor`.

### ObterRegistroTotal (= ObterTotal, alias legado ObterRegistroTotal)

```excel
=ObterRegistroTotal("Produtos"; ""; "Preço, Quantidade"; "Sum")
=ObterRegistroTotal("Produtos"; ""; "Preço, Quantidade"; "Sum"; "ClienteId"; A3)
```

Parâmetros:

1. Nome da aba/tabela
2. Coluna de agrupamento (`""` = total geral)
3. Colunas a totalizar (vírgula)
4. Agregação (`Sum`; também `Count`, `Min`, `Max`, `Avg` via `ObterTotais`)
5. Critérios (ParamArray): pares coluna, valor

Saída: `Kind: "totals"`, campos `ColunaSum`, etc.

### ObterGrafico

```excel
=ObterGrafico("Produtos"; ""; "Preço, Quantidade"; "Sum")
=ObterGrafico("Produtos"; "CategoriaId"; "Preço"; "Sum")
```

- Agrupamento por coluna para categorias/séries do histograma.
- Saída: `Kind: "graph"` + campos `*_Label` para legenda.
- Variante: `ObterRegistroGrafico`.

### ObterRegistro

Lookup FK → `Kind: "object"`.

### GerarJson / SalvarJsonEmDisco

Exporta workbook → arquivo `.json` (ex.: `crudex.json`).

### Helpers Wordex_* (embalagem)

`Wordex_ObterKindColuna`, `Wordex_JsonCampoTipado`, `Wordex_EmbalarJsonColuna`, formatação numérica, imagem → base64, etc.

---

## 8. Tabela Queries (desenho)

> Nome **`Queries`** (plural) — evita confusão com `VIEW` do SQL. É tabela de **metadado CRUDEX**, não DDL de banco.

Cada **Query** define:

- **Tabela raiz** (ex.: aba `ROOT` — tratada como **qualquer tabela**; o walker é recursivo)
- **Relações** com outras tabelas: pai-filho (`ReferenceTableId` / `IsParentChild`) ou FK
- Colunas selecionadas, Category/tipo, expressões equivalentes às UDF (`ObterRegistros`, …)

A Query **espelha a planilha** / árvore JSON:

- Nó = tabela + colunas selecionadas + referências
- Coluna escalar: Category via Type
- Coluna filha vetor: expressão tipo `ObterRegistros` → collection
- Coluna FK: expressão tipo `ObterRegistro` → object
- Coluna agregada: `ObterRegistroTotal` / `ObterGrafico` → totals / graph

**Não** é SQL `VIEW` nem consulta escrita à mão — é metadado declarativo; o walker executa `{Table}Read` e embala JSON.

Parâmetros das UDF (aba, agrupamento, colunas, agregação, critérios) viram campos na definição da coluna da Query (tabela filha de metadado, a definir).

---

## 9. Tabela Reports (desenho)

| Campo | Função |
|-------|--------|
| `Name`, `Description` | Grid de seleção |
| `Template` | `nvarchar(max)` — HTML autossuficiente salvo do Wordex |
| `QueryId` (FK) | Fonte de dados JSON (árvore a partir da tabela raiz) |
| `SystemId`, `ClientId` | Escopo (padrão CRUDEX) |

Fluxo: usuário escolhe Report → CRUDEX carrega Template + executa Query → JSON → iframe → PDF.

---

## 10. Implementação CRUDEX — gaps

| Item | Estado |
|------|--------|
| Tabelas Reports, Queries no Excel | A criar |
| Procedure/endpoint JSON | Portar macro VBA |
| Ação frontend iframe | A criar (`TSystem` só tem grid/menu/login hoje) |
| Servir templates em StaticFiles | A definir |
| `Reports.cs` (Word/LibreOffice .docx) | Legado — distinto do Wordex HTML |

### Fases sugeridas

1. **PoC:** template salvo + iframe + `crudex.json` fixo + `ObterPDF`
2. **Queries + JSON dinâmico** via procedure
3. **Menu Reports** + metadado completo

---

## 11. Pipeline PDF (referência)

```text
wordexDocument (template)
  → buildGeneratedReportHtml(data)     ← “pergaminho” contínuo (body-flow)
  → wordex-paged.html (.pagex-page)    ← quebra A4; @PageNumber / @PageCount
  → wordex-pdf.html (html2canvas / jsPDF)
  → PDF
```

Backend: **não paginar em C#** — usar headless + `ObterPDF(json)` ou HTML já paginado.

---

## 13. Editor HTML em campos do form (CRUDEX)

Além de **relatórios** (template + Query + PDF), o Wordex serve como **editor rich HTML** para campos de domínio **HTML** (`nvarchar(max)`).

```text
Form CRUDEX → coluna com Category/domínio HTML
    → botão (ex.: “Editar HTML” / ícone)
    → modal ou painel com iframe Wordex (modo editor, não relatório)
    → usuário edita conteúdo
    → Confirmar / Fechar Wordex
    → HTML gravado no campo; **volta ao form de edição como se nunca tivesse saído**
       (mesmo registro, mesma transação, foco/cursor preservados — overlay, não navegação)
```

| Aspecto | Relatório | Campo HTML |
|---------|-----------|------------|
| Wordex | Template salvo + `ObterPDF(json)` | **Editor** (`wordex.html` ou modo edição) |
| Entrada | Query → JSON completo | Valor atual do campo (HTML fragment ou documento) |
| Saída | PDF | String HTML no `nvarchar(max)` |
| JSON Query | Sim | Não (só o campo) |

Implementação futura: detectar domínio HTML em `TEditBox`/`TForm`; **modal** com iframe (não troca `TSystem.Action`); ao fechar, atualiza valor do campo + `ActualRecord` e restaura o form. Distinto do fluxo Reports.

---

## 12. Decisões fixas (não reverter sem motivo)

| Tema | Decisão |
|------|---------|
| Kind | = Category.Name; vetor→collection, objeto→object |
| Inferir Kind por valor | Obsoleto |
| collection | Vetor de objetos (`Items[]`) |
| Runtime iframe | Template salvo, não editor dev |
| Tamanho template | Sem limite; usuário paga o preço (carga/PDF) |
| ROOT 1 linha | Recomendado no Excel; **obrigatório** na Query CRUDEX (`Validate`) |
| Integração | iframe + `ObterPDF`; headless via API ou **Schedulers CRUDEX** (sem Windows Service Wordex) |
