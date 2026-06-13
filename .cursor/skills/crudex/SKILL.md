---
name: crudex
description: >-
  Orienta trabalho no SGSI CRUDEX. Use ao modificar metadados, procedures, frontend,
  gerador SQL ou implementar o modelo Novíssimo (CRUDEX_Novissimo.xlsm). O sistema
  atual reflete CRUDEX.xlsm e SCRIPT-CRUDEX.sql; o alvo de implementação é o Novíssimo.
---

# CRUDEX — SGSI

## Princípio central

A inteligência reside no **banco de dados** (stored procedures). C# e JavaScript são camadas finas.

```
Planilha Excel → Gerador SQL → SQL Server ← ASP.NET ← Browser (SPA)
```

## Dois modelos — não confundir

| | **Atual (em produção)** | **Alvo (implementar)** |
|--|-------------------------|-------------------------|
| Planilha | `CRUDEX.xlsm` | `CRUDEX_Novissimo.xlsm` |
| Abas de dados | Nome da tabela (`Categories`) | **Alias** da tabela (`Cat`) — índice em `Tbl` |
| Gerador | `Scripts.cs` (T-SQL monolítico) | **Reescrever** — multi-SGBD, procedures novas |
| SQL válido | `SCRIPT-CRUDEX.sql` apenas | A gerar do Novíssimo |
| Tipos SQL | `#DataType` fixo T-SQL | `Cli.EngineId` + `Dmn.TypeId` → `Map` |
| FK / pai-filho | `Col.ReferenceTableId`, `Tbl.ParentTableId` | `Ref` (`IsParentChild`) |
| Menu | `Menus` separado | `Mnu` (títulos) + campos em `Tbl` |

`appsettings.json` aponta `CRUDEX.xlsm` — coerente com o código atual.

## Convenções da planilha Novíssimo

### Colunas `#` = lookup

Colunas cujo título começa com `#` são fórmulas Excel (VLOOKUP). **Não são colunas físicas** do banco. Ignorar no DDL/INSERT; usar só na geração/leitura humana, ou resolver via FK real.

### Abas por Alias

A aba `Tbl` define `Name` (SQL/procedure) e `Alias` (nome da aba Excel). Ex.: tabela `Categories` → aba `Cat`.

### Tenant (`Cli`)

- `ClientId = 1` (CRUDEX/SoftLab) = catálogo **global**, visível a **todos**.
- `ClientId > 1` = dados **privados** do tenant.
- Filtro padrão: `ClientId IN (1, @SessionClientId)` — sem coluna `IsPlatform`; ID 1 é convenção fixa.
- Nome pode migrar para *tenant* no futuro.

### Tipo SQL físico

```
Col.DomainId → Dmn.TypeId
Cli.EngineId (tenant da sessão) + Dmn.TypeId → Map → tipo do dialeto
Dmn.Length / Dmn.Decimals completam o tipo
```

`Cat` classifica tipos (`Typ`); `Eng` cadastra ~10 SGBDs; `Map` mapeia cada `Typ` por engine.

## Hierarquia Novíssimo (resumo)

```
Cat → Typ → Map (× Eng de Cli)
Cli → Dmn (+ Mkg → Msk), Db → Con → Sys → Tbl → Col
Mnu (popups) + Tbl.MenuId/MenuSequence/MenuCaption (itens)
Ref (FK + IsParentChild) | Uni | Exp → Cnd | Prm | Sch (agenda — substitui Windows Services) | Snp (triggers before/after CRUD → Scr/Url)
```

Detalhes de cada aba: [reference.md](reference.md).

## Pontos de desenho importantes

**Domínios (`Dmn`)** — Colunas usam `DomainId`, não `TypeId`. Domínio concentra validações, listas, tenant; coluna (`Col`) traz flags `Is*`.

**Máscaras (`Msk` + `Mkg`)** — Máscara **semântica** (`ValidMask`: `9` numérico, `A` alfabético, `X` alfanumérico, `#` alfanumérico/especial). Na edição converte para `EditMask` (`#` por posição digitável). Escape `\A` para literal reservado. `Mkg` liga `Dmn`↔`Msk` + parâmetros opcionais de dígito verificador (`CheckDigitModule`, `CheckDigitFactors` com `|` para múltiplos DVs).

**Menu** — `Mnu` = títulos horizontais dos popups; itens vêm de `Tbl`. Tabelas filhas (`Ref.IsParentChild`) **sem `MenuId` por convenção** (só master-detail); tecnicamente pode ter menu, mas fica redundante.

**Referências (`Ref`)** — Não existe `ParentTableId`. `ColumnId` (FK), `TableId` (pai), `Alias`, `ExpressionId` opcional, `IsParentChild`.

**Unicidades (`Uni`)** — Valor de `LeftColumnId` não pode existir em `RightColumnId` (mesma ou outra tabela). `IsBirectional = true`: vale nos dois sentidos (ex.: `Tbl.Name` × `Tbl.Alias`).

**Expressões (`Exp` + `Cnd`)** — `Exp` agrupa `Cnd`. Usos: filtros fixos de grid/relatório, escopo de dados, **`Bhv`** (avaliadas a cada `change` no form).

**Comportamentos (`Prp` + `Bhv`)** — `Prp` cataloga propriedades DOM (`CategoryId` só tipa `Value`). `Bhv`: coluna + expressão → se verdadeira, aplica `Value` em `PropertyId` (ex.: máscara CPF/CNPJ dinâmica).

## Sistema atual — runtime

### Rotas

`/{system}.{environment}` — ex.: `crudex.dev`

| POST | Ação | Uso |
|------|------|-----|
| `/config` | metadados | `Config` procedure |
| `/login` | sessão | `Login` procedure |
| `/execute` | CRUD | `{Table}Read`, transações, etc. |

### Padrão CRUD (atual)

`Validate` → `Persist` → `Commit` + `Read` / `List` por tabela. Transação: abrir form → `Trs` (`Ses`); persist → `Ope`; confirmar → `TransactionCommit`.

### Arquivos-chave

- Backend: `Program.cs`, `Procedure.cs`, `Config.class.cs`, `Scripts.cs`
- Frontend: `TSystem`, `TGrid`, `TForm`, `TMenu`, `TMask`, `TConfig`
- SQL: **somente** `StaticFiles/db/SCRIPT-CRUDEX.sql` (ignorar outros `.sql` fragmentados)

## Workflow

### Manter sistema atual

1. Editar `CRUDEX.xlsm`
2. `Scripts.Generate()` → `SCRIPT-CRUDEX.sql`
3. Executar script no SQL Server
4. Acessar `/{sistema}.{env}`

### Implementar Novíssimo

1. Tratar `CRUDEX_Novissimo.xlsm` como especificação
2. Novo gerador: abas por `Alias`, `Map` por engine, dialetos SQL, procedures redesenhadas
3. Evoluir `Config`, `Procedure.cs` (multi-provider via `Eng.Provider`), frontend (`TMask` semântico, menu via `Mnu`+`Tbl`, `Ref` sem `ParentTableId`)
4. **Não** adaptar `Scripts.cs` linha a linha — modelo incompatível

### Depurar CRUD

1. Tabela + ação em `SCRIPT-CRUDEX.sql`
2. Parâmetros JSON da procedure
3. `LoginId` / transação pendentes

## Constantes e convenções

- `PLATFORM_CLIENT_ID = 1` (tenant global)
- Colunas reservadas no gerador: `Data`, `Kind`, `CreatedAt`, `CreatedBy`, `UpdatedAt`, `UpdatedBy`, `UniqueIdentifier`
- Registros em procedures: JSON (`@ActualRecord`, `@LastRecord`)
- Erros: `THROW 51000`, mensagens em português

## Referência completa

Novíssimo aba a aba, procedures atuais, fluxos: [reference.md](reference.md).

## Sprint atual: `TRecordSet` + `TRecord` ★

**Em andamento — primeira implementação.** Centraliza leitura, filtro, pesquisa, paginação e referências no frontend.

| Classe | Arquivo | Papel |
|--------|---------|-------|
| `TRecordSet` | `TRecordset.class.mjs` | `goPage`, `nextRow`, `goRow`, filtros, chama `{Table}Read` |
| `TRecord` | `TRecord.class.mjs` | Uma linha; escalares + `references.{alias}.campo` |

Testar no CRUDEX atual (`SCRIPT-CRUDEX.sql`). Filtro Novíssimo (`Cmp`, AND) depois, sem mudar API pública.

**Depois:** testar grid com recordset → Novíssimo → master-detail, `Bhv`, etc.

## Escopo de implementação (Novíssimo)

Metadados documentados nas 34 abas de `CRUDEX_Novissimo.xlsm`. Haverá extensões futuras; implementar o que está definido agora.

**Gaps principais vs. código atual:**

| Área | Atual | A implementar |
|------|-------|----------------|
| Gerador SQL | `Scripts.cs` T-SQL + `CRUDEX.xlsm` | Novo gerador multi-SGBD, abas por `Alias`, `Map` |
| Metadados | `ParentTableId`, `ReferenceTableId` | `Ref`, `Uni`, `Exp`/`Cnd`, `Prm`, `Mkg`… |
| Menu | `Menus` + `Action` | `Mnu` + `Tbl.MenuId`… |
| Máscaras | `#` direto em `TMask` | ValidMask/EditMask semântico + `Mkg` |
| Comportamentos | hardcode em `TForm` | `Prp`/`Bhv` a cada `change` |
| Execução | — | `Sch`, `Snp` → `Scr`/`Url` (pipeline `Sequence` único) |
| **Forms master-detail** | **Não existe** | `Ref.IsParentChild` — formulário pai com filhas |

Prioridade de runtime: **`TRecordSet` + `TRecord`** (agora) → `TGrid`/relatórios → `Config`/procedures Novíssimo → master-detail, `TMask`, `Bhv`, `Mnu`/`Tbl`.
