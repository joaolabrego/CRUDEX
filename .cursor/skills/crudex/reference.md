# CRUDEX — Referência técnica

## Planilhas Excel

| Arquivo | Papel |
|---------|-------|
| `CRUDEX.xlsm` | Metadados do sistema **atual** (21 abas, nomes completos) |
| `CRUDEX_Novissimo.xlsm` | Metadados **alvo** (34 abas, aliases) |

## Novíssimo — mapa de abas

| Alias | Name (tabela) | Papel |
|-------|---------------|-------|
| `Cat` | Categories | Categorias de tipos (`string`, `number`…); flags `Ask*` |
| `Cmp` | Comparators | Comparadores para `Cnd` e `Rul` |
| `Rul` | Rules | Regras por categoria × comparador |
| `Eng` | Engines | SGBDs (~10): Provider, PackageName, IsActive |
| `Typ` | Types | Tipos lógicos (independente de SGBD); `CategoryId` |
| `Map` | Mappings | `EngineId` + `TypeId` → tipo físico do dialeto (~380 linhas) |
| `Cli` | Clients | Tenant; `EngineId` define SGBD do cliente; Id=1 = plataforma global |
| `Dmn` | Domains | Instância reutilizável: `TypeId`, validações, `ClientId` |
| `Msk` | Masks | Máscaras semânticas + legenda ValidMask/EditMask na aba |
| `Mkg` | Maskings | `Dmn` ↔ `Msk` + CheckDigit opcional |
| `Db` | Databases | Banco lógico: `ClientId`, `EngineId`, Name |
| `Con` | Connections | Conexão por ambiente (`dev`/`hml`/`prd`) |
| `Sys` | Systems | Sistema: `DatabaseId`, Prefix, MaxRetryLogins |
| `Mnu` | Menus | Títulos e hierarquia dos popups (`ParentMenuId`) |
| `Tbl` | Tables | Tabelas + **item de menu** (`MenuId`, `MenuSequence`, `MenuCaption`, `MenuMessage`) |
| `Col` | Columns | `DomainId` (não TypeId); flags `Is*`; `IsVirtual` |
| `Idx` | Indexes | Índices |
| `Idk` | Indexkeys | Chaves de índice |
| `Inc` | Includes | Colunas incluídas em índice |
| `Uni` | Unicities | Unicidade cruzada entre colunas |
| `Exp` | Expressions | Agrupa condições (`Name`, `TableId`) |
| `Cnd` | Conditions | Linhas lógicas: `Cmp`, AND/OR, parênteses, colunas/valores |
| `Ref` | References | FKs: `ColumnId`, `TableId`, `Alias`, `ExpressionId`, `IsParentChild` |
| `Usr` | Users | Usuários por `ClientId` (simples — dispensa detalhamento) |
| `Prm` | Permissions | CRUD direto: `SystemId` + `UserId` + `TableId` + `CanCreate/Read/Update/Delete` (sem grupos) |
| `Prp` | Properties | Catálogo de propriedades HTML/controle (nativas e customizadas) |
| `Bhv` | Behaviors | Aplica `Prp` em `Col` quando `ExpressionId` é verdadeira |
| `Sch` | Schedulers | Agendamento de tarefas (quando executar) — **WIP** |
| `Snp` | Snipers | Gatilho de execução ligado a `Tbl` (`IsBefore`) |
| `Scr` | Scripts | Scripts SQL por `SniperId` + `DatabaseId`, `Sequence` |
| `Url` | Urls | Chamadas HTTP (APIs) por `SniperId`, `Method`, `URL`, `Sequence` |
| `Ses` | Sessions | `Id` gerado a cada login (`ClientId`, `SystemId`, `UserId`, `PublicKey`, `IsLogged`) |
| `Trs` | Transactions | Transações |
| `Ope` | Operations | Operações pendentes |

## Engines (`Eng`)

| Id | Nome | Provider (ex.) |
|----|------|----------------|
| 1 | SQL Server | Microsoft.Data.SqlClient |
| 2 | MySQL | MySql.Data.MySqlClient |
| 3 | MariaDB | MySqlConnector |
| 4 | PostgreSQL | Npgsql |
| 5–10 | Firebird, Interbase, SQL Anywhere, Informix, Oracle, DB2 | … |

Somente SQL Server `IsActive=true` na planilha atual; arquitetura prevê todos.

## Categorias (`Cat`)

10 categorias: `string`, `number`, `date`, `datetime`, `time`, `text`, `boolean`, `image`, `binary`, `undefined`.

Flags `Ask*`: o que pode ser configurado em domínios/colunas daquela categoria (máscara, grid, filtro, criptografia, por extenso…).

## Resolução de tipo SQL

```
1. Col.DomainId → Dmn (Name, Length, Decimals, ValidValues, ClientId)
2. Dmn.TypeId → Typ → Cat (regras, Rul)
3. Sessão → Cli.ClientId → Cli.EngineId
4. Map WHERE EngineId AND TypeId → nome físico (ex.: bigint / INT8 / NUMBER)
5. Montar tipo: Map.Name + Dmn.Length + Dmn.Decimals
```

## Tenant (`Cli`)

- **Id 1**: dados CRUDEX/plataforma — visíveis a todos os tenants.
- **Id 2+**: dados privados — só o tenant dono + catálogo do Id 1.
- SQL: `WHERE ClientId IN (1, @SessionClientId)`
- Entidades com `ClientId`: `Dmn`, `Msk`, `Db`, `Usr`, `Sch`, `Ses`

## Máscaras (`Msk`)

Legenda na aba:

**EditMask** — cada `#` = posição digitável (alfanumérico ou especial).

**ValidMask** (semântica em `Msk.Mask`):

| Token | Aceita |
|-------|--------|
| `9` | numérico |
| `A` | alfabético |
| `X` | alfanumérico |
| `#` | alfanumérico ou especial |

Fluxo: ValidMask → gera EditMask → cada tecla em `#` valida contra token semântico. `\A` = literal `A`. `Modificators`: `left`, `upper`…

## Maskings (`Mkg`)

| Campo | Uso |
|-------|-----|
| `DomainId`, `MaskId` | Liga domínio à máscara |
| `CheckDigitModule` | Módulo (11, 10…) — opcional |
| `CheckDigitFactors` | Fatores `;` separados; `\|` entre DVs |
| `CheckDigitGreaterThanNine` | Substituição se DV > 9 (`0`, `X`) |

Funções existentes: `TMask.CheckDigit()`, `crudex.CheckDigit`.

## Menu (`Mnu` + `Tbl`)

```
Mnu: Manutenção → Cadastro, Definição (popups aninhados)
Tbl: cada tabela com MenuId aponta para popup + MenuSequence + MenuCaption
```

Tabelas filhas (`Ref.IsParentChild`): sem `MenuId` por convenção (master-detail). Pode ter menu, mas redundante.

Ação derivada: `grid/{Db.Name}/{Tbl.Name}`.

## Referências (`Ref`)

**Não existe `ParentTableId`.**

| Campo | Papel |
|-------|--------|
| `ColumnId` | Coluna FK (filho) |
| `TableId` | Tabela referenciada (pai) |
| `Alias` | Nome lógico da relação |
| `ExpressionId` | Condição opcional (`Exp`/`Cnd`) |
| `IsParentChild` | `true` = FK + master-detail no formulário |

DDL de FK gerado a partir de `Ref`, não de `Col.ReferenceTableId` (ausente no Novíssimo).

## Unicidades (`Uni`)

| Campo | Papel |
|-------|--------|
| `LeftColumnId` | Coluna A |
| `RightColumnId` | Coluna B (mesma ou outra tabela) |
| `IsBirectional` | `true`: A não pode existir em B **e** B não pode existir em A |

Exemplo `Tbl`: `Name` e `Alias` compartilham espaço de valores únicos.

Diferente de `Idx.IsUnique` (unicidade na própria coluna/índice).

## Expressões (`Exp` + `Cnd`)

`Exp` = cabeçalho (`Name`, `TableId`). `Cnd` = linhas com `Sequence`, `Connector` (AND/OR), parênteses, `LeftColumnId`, `ComparatorId` (`Cmp`), `RightColumnId` ou `RightValues`.

Uso: filtros fixos de grid, relatórios, escopo de dados (ex.: só clientes do gerente), `Ref.ExpressionId`, `Bhv.ExpressionId`.

Mesclar em `{Table}Read` com filtro ad hoc do usuário.

## Permissões (`Prm`)

Modelo **direto** — sem grupos/roles (grupos confundiram mais do que ajudaram):

| Campo | Papel |
|-------|--------|
| `SystemId` + `UserId` + `TableId` | Chave da permissão |
| `CanCreate` / `CanRead` / `CanUpdate` / `CanDelete` | Flags CRUD por tabela |

Substitui o antigo `SystemsUsers` (só vínculo usuário-sistema). Validação nas procedures antes de `Read`/`Persist`/etc.

## Propriedades e comportamentos (`Prp` + `Bhv`)

**`Prp`** — catálogo de propriedades DOM (nativas + customizadas). `CategoryId` **só tipa o `Value`** em `Bhv` (não restringe coluna).

| `CategoryId` | Exemplos `Prp.Name` |
|--------------|---------------------|
| vazio | `disabled`, `hidden`, `readonly`, `required` (flags) |
| `string` | `placeholder`, `class`, `style`, `mask`… |
| `number` | `maxlength`, `minlength`, `step` |
| `undefined` | `value`, `min`, `max` |

**`Bhv`** — filé-mignon: comportamento dinâmico por coluna.

| Campo | Papel |
|-------|--------|
| `ColumnId` | Coluna cujo controle será afetado |
| `ExpressionId` | `Exp`/`Cnd` avaliada a cada change no form |
| `PropertyId` | `Prp` a aplicar se expressão = verdadeira |
| `Value` | Valor da propriedade (tipado por `Prp.CategoryId`) |

### Runtime no form de edição

A cada **`change`** no formulário:

1. Para cada coluna em edição, varrer seus `Bhv`
2. Avaliar `ExpressionId` contra estado atual do registro
3. Se verdadeira → aplicar `Value` à propriedade `PropertyId` no input

### Exemplo: CPF ou CNPJ no mesmo campo

Input aceita ambos; conforme escolha do usuário (outra coluna ou valor parcial):

```
Bhv 1: Expression "tipo = CPF"  → Property mask → Value (máscara CPF)
Bhv 2: Expression "tipo = CNPJ" → Property mask → Value (máscara CNPJ)
```

A cada change, reavalia e troca máscara dinamicamente via `TMask`/semantic mask.

Substitui hardcode em `TForm` (`min`, `max`, `HtmlInputType` fixos) por regras declarativas em metadados.

## Agendamento e execução (`Sch`, `Snp`, `Scr`, `Url`) — em evolução

### `Sch` — schedulers (quando)

**Substituem Windows Services** — o CRUDEX agenda e dispara tarefas em background via metadados, sem serviço Windows externo.

Agendamento por tenant (`ClientId`): `Interval`, `Periodicity` (ex. `day`), `TimeOfDay`, `DayOfMonth`, `NextRunDate`, flags `IsBusinessDays`, `IsFirstOrLastDay`, `IsRunOnce`, `IsActive`.

**Lacuna atual:** falta ligar `Sch` ao **o quê** executar. Intenção: disparar `Scr`/`Url` (scripts SQL e chamadas HTTP/API), uma ou várias — mesmo payload do sniper, disparo por tempo.

### `Snp` + `Scr` + `Url` — snipers (triggers CRUD)

**Snipers = triggers de metadados** — executados **antes ou depois** de operações CRUD na tabela, conforme `IsBefore`:

| `IsBefore` | Momento |
|------------|---------|
| `true` | Antes do CRUD (validação, preparação, bloqueio) |
| `false` | Depois do CRUD (efeitos colaterais, integração, notificação) |

**`Snp`**: `TableId`, `Name`, `IsBefore`, `IsActive`.

**`Scr`** — scripts SQL: `SniperId`, `DatabaseId`, `Sequence`, `Script`.

**`Url`** — chamadas HTTP (APIs): `SniperId`, `Sequence`, `Method`, `URL`.

**Unicidade de `Sequence` por `SniperId`:** `Scr` e `Url` compartilham a mesma fila de execução — uma `Sequence` não pode existir em ambas para o mesmo sniper. Ex.: Seq 5 = SQL, Seq 10 = HTTP, Seq 15 = SQL (pipeline único ordenado).

Fluxo CRUD com sniper:
```
Persist/Commit em Tbl X
  → se Snp ativo (IsBefore=true)  → executa Scr[] + Url[]
  → operação CRUD
  → se Snp ativo (IsBefore=false) → executa Scr[] + Url[]
```

### `Sch` vs `Snp`

| | **Scheduler (`Sch`)** | **Sniper (`Snp`)** |
|--|----------------------|-------------------|
| Disparo | Tempo (substitui Windows Service) | Before/after CRUD (substitui trigger SQL) |
| Payload | `Scr` + `Url` (a ligar) | `Scr` + `Url` |

Mesmo tipo de execução (scripts + HTTP); gatilhos diferentes.

## Sessão, transação e operações (`Ses` → `Trs` → `Ope`)

### `Ses` (sessions)

`Id` gerado a cada login. `ClientId`, `SystemId`, `UserId`, `PublicKey`, `IsLogged`. Retornado como `LoginId`.

### `Trs` (transactions)

Contêiner de operações — **filha de `Ses`**. Uma transação por ciclo de edição no form.

### `Ope` (operations)

Operações pendentes **antes do commit**: `TransactionId`, `TableName`, `Action` (create/update/delete), `LastRecord`, `ActualRecord` (JSON), `IsConfirmed`.

### Fluxo no form

```
1. Abrir form de edição     → TransactionBegin → Trs (SessionId)
2. Cada gravar/persist      → Ope (pendente, IsConfirmed = null)
3. Confirmar no form        → TransactionCommit → executa {Table}Commit de cada Ope
4. Cancelar                 → TransactionRollback
```

`Trs` agrupa; `Ope` guarda o rascunho JSON até o commit definitivo — mesmo modelo do CRUDEX atual, hierarquia explícita `Ses` → `Trs` → `Ope`.

## Sistema atual (SCRIPT-CRUDEX.sql)

### Procedure Config — datasets (`@DatabaseName='all'`)

0 Systems, 1 Databases, 2 Tables, 3 Columns, 4 Domains, 5 Types, 6 Categories, 7 Menus, 8 Indexes, 9 Indexkeys, 10 Masks, 11 Unicities

### Procedures por tabela

`{Singular}Validate`, `{Singular}Persist`, `{Singular}Commit`, `{Plural}Read`, `{Plural}List`

### Infraestrutura

`Config`, `Login`, `GetPublicKey`, `NewId`, `NewOperationId`, `ScriptSystem`, `crudex.TransactionBegin/Commit/Rollback`, `crudex.IS_EQUAL`, `crudex.CheckDigit`

### Modelo antigo vs Novíssimo

| Conceito | Atual | Novíssimo |
|----------|-------|-----------|
| Aba Excel | `Name` | `Alias` |
| Tipo SQL | `#DataType` em Types | `Map` × `Cli.EngineId` |
| FK | `Col.ReferenceTableId` | `Ref` |
| Pai-filho | `Tbl.ParentTableId` | `Ref.IsParentChild` |
| Menu item | `Menus.Action` | `Tbl.MenuId`… |
| Unicidade cruzada | `Unicities` | `Uni` |
| Máscara no domínio | `Domains.MaskId` | `Mkg` |
| Multi-SGBD | Não | `Eng` + `Map` |
| Multi-tenant | `ClientId DEFAULT 1` em tudo | `Cli` + filtro IN (1, @Session) |

## Geração de scripts

**Atual** — `Scripts.cs`:
- Lê `FILENAME_EXCEL` (`CRUDEX.xlsm`)
- Abas pelo `table["Name"]`
- Emite T-SQL monolítico → `SCRIPT-{DATABASE}.sql`

**Novíssimo** — requer gerador novo:
- Abas pelo `Tbl.Alias`
- Ignorar colunas `#`
- Resolver tipos via `Map`
- Emitir dialeto por `Eng`
- Procedures com contrato redesenhado

## Runtime ASP.NET

```
GET  /{sys}.{env}           → HTML + TSystem.Run()
POST /{sys}.{env}/config    → Config JSON
POST /{sys}.{env}/login     → Login
POST /{sys}.{env}/execute   → Procedures
```

`appsettings.json`: `ConnectionString`, `CONFIG_PROCEDURE`, `ROWS_PER_PAGE`, `FILENAME_EXCEL`, etc.

`CRUDEX_ENVIRONMENT`: `dev` | `hml` | `prd`

## Deploy banco (SCRIPT-CRUDEX.sql)

Script faz `DROP DATABASE crudex`; ajustar paths `.mdf`/`.ldf` antes de executar.

## Status do modelo Novíssimo

Documentação das 34 abas concluída para implementação. Extensões futuras possíveis.

**O código atual não possui forms master-detail.** Implementar via `Ref.IsParentChild` + tabelas filhas (sem `MenuId` por convenção).

## Procedures atuais e evolução do `Read`

**Baseline:** todas as procedures em produção estão em `SCRIPT-CRUDEX.sql` (única fonte SQL válida do modelo atual). Versões intermediárias existem e serão testadas antes de consolidar mudanças.

### `{Table}Read` hoje (`SCRIPT-CRUDEX.sql`)

Parâmetros típicos: `@LoginId`, `@RecordFilter` (JSON), `@OrderBy`, `@PaddingGridLastPage`, `@IsActionList`, `@PageNumber`, `@LimitRows`, `@MaxPage` OUT.

`@RecordFilter` atual:
- JSON **plano** coluna → valor (predominantemente igualdade)
- Chave especial `$._` = array de Ids selecionados
- Filtro/pesquisa do grid (`TGrid` → `TForm` FILTER/SEARCH) serializa `#FilterValues` / `#SearchValues` nesse formato

### `{Table}Read` Novíssimo (mudança grande — em teste)

**Filtragem** e **pesquisa** passarão JSON estruturado com:

| Parte | Conteúdo |
|-------|----------|
| valor | dado da coluna / critério |
| operador | símbolo ou id de `Cmp` (`<`, `=`, `∈`, `⊃` LIKE, `∃` BETWEEN…) |
| comparando | literal, lista, outra coluna ou intervalo conforme `Cmp.Arity` |

**Conector fixo `AND`** — reflete como o usuário pensa: na prática formula critérios encadeados (“nome contém X **e** data após Y **e** status Z”), raramente OR. A UI de filtro/pesquisa só monta condições em **AND** (sem escolher conector nem parênteses). Condições **complexas** (OR, parênteses) ficam em **`Exp`/`Cnd`** — analista/negócio, não o usuário final na grid.

Compilação: `WHERE col1 op val1 AND col2 op val2 AND …` via `Cmp.CodeSQL`.

**Emular OR sem OR na UI:** operadores `∈` (IN) e `∃` (BETWEEN) cobrem disjunção e faixas. OR explícito só em `Exp`/`Cnd`.

**Cobertura estimada:** filtro/pesquisa na grid (AND + `Cmp`) atende ~**90%** dos casos do usuário; os ~10% restantes → expressões fixas (`Exp`/`Cnd`) definidas pelo analista.

Mesclar com expressões fixas (`Exp`/`Cnd`) e `Prm` antes de executar a query.

Frontend (`TGrid`/`TForm`): adaptar envio de FILTER/SEARCH para array de critérios (sem conector explícito).

## `TRecordSet` (frontend — **implementado v1**)

Classe JS em `TRecordset.class.mjs` + `TRecord.class.mjs`. Encapsula `{Table}Read` com paginação, filtros e referências.

**Testar primeiro no CRUDEX atual** (`CategoriesRead` etc. em `SCRIPT-CRUDEX.sql`); evoluir filtros quando o `Read` Novíssimo (JSON + `Cmp`) existir.

### Responsabilidades

| Responsabilidade | Detalhe |
|------------------|---------|
| Paginação transparente | Buffer da página atual; ao `nextRow` no fim da página, chama `Read` da próxima até `EOF` |
| Filtro/pesquisa | Condições (`AND` + `Cmp`) ficam **na classe** — JSON enviado ao `Read` |
| Ordenação | `OrderBy` mantido na classe |
| Consumo total | Iterar todos os registros (grid **e relatórios) sem o caller gerenciar páginas |

### API prevista — leitura sequencial e randômica

**Sequencial** — registro a registro; busca próxima/anterior página automaticamente:
- `nextRow` / `priorRow`
- `goTop` / `goBottom` — primeiro/último registro do recordset
- `BOF` / `EOF`

**Randômica** — acesso direto por página ou posição:
- `goPage(n)` — carrega página `n` via `{Table}Read` (não usar `readPage`)
- `goRow(n)` — posiciona no registro global `n` (1..rowCount); internamente calcula página e offset

Propriedades: `record`, `records`, `rowCount`, `pageNumber`, `pageCount`, `rowNumber`, `orderBy`.

Métodos de estado: `BOF()` / `EOF()` → `true` ou `false`.

Métodos de filtro: `setFilter`, `setSearch`, `setFixedFilter`, `clearFilters`, `clearSearch`, `clearOrderBy`, `toggleOrderDirection`.

### Dados principais + tabelas referenciadas — `TRecord`

Cada `goPage` / `{Table}Read` traz a página principal + datasets das tabelas referenciadas (já assim no `Read`).

**`TRecord`** — uma linha: colunas escalares do `datarow` + `references.{alias}` resolvido via FK + buffer de refs da página.

**Ao montar cada linha:** para cada `Ref` da tabela, resolver FK via `TColumn` + buffer da página → preencher `record.references`:

```javascript
// Funcionário com DeptoId = 5, Ref.Alias = "deptos"
record.references.deptos.Nome   // nome do departamento
record.DeptoId                  // ainda 5 (escalar)
```

Estrutura: `this.references.{alias}.{coluna}` — objeto por referência (`deptos`, etc.), chave = `Ref.Alias`.

Fluxo:

1. `goPage(n)` → `Read` → buffers da página + refs brutas
2. Para cada linha → `new TRecord(...)` → monta `references` { alias: rowObject }
3. `TRecordSet` navega sobre `TRecord[]`; grid/relatório usam `record.references.deptos.Nome`

**Princípio:** simples — dados escalares no registro; lookups em `record.references`, não no valor da coluna FK.

### Integração

```
TGrid  ──→  TRecordSet  ──→  POST execute / {Table}Read  →  Table + Refs
TReport ──→  TRecordSet  ──→  (mesmo contrato; percorre todas as páginas)
```

`TGrid` deixa de chamar `Read` diretamente; delega ao `TRecordSet`. Filtros fixos (`Exp`) vêm do servidor; filtros do usuário via métodos na classe.

### `TRecordSet` — contrato com `Read` atual (para testes)

Chamada via `TConfig.GetAPI('execute', …)` igual ao `TGrid` hoje:

```javascript
Parameters: {
  DatabaseName, TableName, Action: 'read',
  InParams: { LoginId, RecordFilter: JSON.stringify(filter), OrderBy, PaddingGridLastPage },
  IOParams: { PageNumber, LimitRows: RowsPerPage, MaxPage: 0 }
}
```

Retorno (um único result set): uma linha com coluna `result` (JSON da página principal) + uma coluna por tabela relacionada (`Types`, `Categories`… com JSON array). Compatível com SGBDs sem múltiplos result sets. `TConfig.ParseReadDataSet` deserializa no frontend.

`Parameters`: `ReturnValue` (rowCount), `PageNumber`, `MaxPage`.

Filtro atual: JSON plano coluna→valor; depois trocar serialização para array `Cmp` sem mudar a API pública do `TRecordSet`.

### Checklist de implementação

- [x] **`TRecordSet` + `TRecord`** — v1 em `TRecordset.class.mjs` / `TRecord.class.mjs`
- [ ] Testar no CRUDEX atual (ex.: `Categories`)
- [x] `TGrid` delega ao `TRecordSet` (`#ReadDataPage` → `goPage`)
- [x] `TForm` usa `SelectedRecord` / `RecordSet.readOne` (compatível com Read JSON)
- [x] **`TDropdown`** — seleção simples, multi, inclusão manual (IN), cardinalidade (BETWEEN)
- [x] **`TForm`** — FK (`ReferenceTableId`) usa `TDropdown.Single` + `{Table}List` via `TList.fetchPage`

### `TDropdown` — modos

| Modo | Factory | Uso |
|------|---------|-----|
| `single` | `TDropdown.Single(...)` | FK / lista paginada, um item |
| `multi` | `TDropdown.Multi(...)` | Vários itens da lista (checkbox) |
| `addable` | `TDropdown.Addable(...)` | IN — digitar e incluir com `+` / remover com `−` |
| `cardinality` | `TDropdown.Cardinality(...)` | BETWEEN — `exactItems: 2`, `requireExact: true` |

```javascript
import TDropdown from "./Classes/TDropdown.class.mjs";

const host = document.createElement("div");
const dd = TDropdown.Single(host, {
    data: [{ Id: 1, Name: "Alpha" }],
    itemsPerPage: 5,
    placeholder: "Selecione...",
});
document.body.append(host);
dd.addEventListener("change", e => console.log(e.detail.value, e.detail.valid));

// BETWEEN (exatamente 2 valores)
TDropdown.Cardinality(host2, {
    exactItems: 2,
    requireExact: true,
    itemsPerPage: 6,
});
```
- [ ] Gerador SQL Novíssimo (`Alias`, `#` lookups, `Map` × `Eng`)
- [ ] Procedures redesenhadas (multi-dialeto, `Prm`, `Uni`, `Ref`…)
- [ ] **`{Table}Read`** — JSON filtro/pesquisa com operador + comparando (`Cmp`)
- [ ] `Config` / backend multi-provider (`Eng.Provider`)
- [ ] Menu `Mnu` + `Tbl`
- [ ] `TMask` semântico + `Mkg` check digit
- [ ] `Prp`/`Bhv` no form (`change` → expressão → propriedade)
- [ ] **Master-detail no `TForm`**
- [ ] `Sch` (worker agenda) + `Snp` (triggers) → `Scr`/`Url`
- [ ] Tenant `Cli` filtro `IN (1, @SessionClientId)`
