---
name: crudex
description: >-
  Orienta trabalho no SGSI CRUDEX. Use ao modificar metadados, procedures, frontend,

gerador SQL, integração Wordex (Reports, Queries, JSON, iframe) ou implementar o
  modelo Novíssimo (CRUDEX_Novissimo.xlsm). O sistema atual reflete CRUDEX.xlsm e
  SCRIPT-CRUDEX.sql; o alvo de implementação é o Novíssimo.
---

# CRUDEX — SGSI

## Princípio central

A inteligência reside no **banco de dados** (stored procedures). C# e JavaScript são camadas finas.

```
Metadado (banco, via telas) → Procedures → SQL Server ← ASP.NET ← Browser (SPA)
```

**Bootstrap do autor (fora do produto):** `CRUDEX.xlsm` → `Scripts.Generate()` → `SCRIPT-CRUDEX.sql` — só o mantenedor do SGSI; analistas e SIs usam **telas de cadastro**.

## Excel — mal necessário, não facilitador

- **Fonte de verdade:** banco + CRUD CRUDEX (`Persist` → `Validate` → `Commit`). Cadastro no CRUD é o fluxo normal.
- **Planilha:** bootstrap / carga inicial e visualização; **não** é fluxo de manutenção.
- **`Scripts.Generate()`** — duas fontes (parâmetro `isExcel` / `systemName`):
  - **Excel** (`isExcel=true` ou `systemName=="crudex"`) → `ExcelToDataSet()` → SQL
  - **Banco** (`isExcel=false` ou outro sistema) → `[dbo].[ScriptSystem]` → `GetDataSet()` → SQL  
  Fonte de verdade em operação: **banco + CRUD**; gerar script a partir do banco já existe.
- **Exportação futura (opcional):** gerar **planilha** a partir do banco (sistema → Excel) só para análise — distinto do generate SQL acima.
- Não propor Excel como fluxo de cadastro; não documentar planilha como feature do SGSI para analistas nem usuários finais.

## Dois modelos — não confundir

**Fase actual da 2.0: só análise** — planilha `CRUDEX_Novissimo.xlsm`, documentação, decisões de desenho. **Não implementar** gerador, procedures, runtime nem tabelas de versionamento até o metamodelo estabilizar e houver decisão explícita de codificar.

| | **Atual (em produção)** | **Alvo (2.0 — análise)** |
|--|-------------------------|-------------------------|
| Planilha | `CRUDEX.xlsm` | `CRUDEX_Novissimo.xlsm` |
| Abas de dados | Nome da tabela (`Categories`) | **Alias** da tabela (`Cat`) — índice em `Tbl` |
| Gerador | `Scripts.cs` (T-SQL monolítico) | **Reescrever** — multi-SGBD, procedures novas |
| SQL válido | `SCRIPT-CRUDEX.sql` apenas | A gerar do Novíssimo |
| Tipos SQL | `#DataType` fixo T-SQL | `Own.EngineId` + `Dmn.TypeId` → `Map` |
| FK / pai-filho | `Col.ReferenceTableId`, `Tbl.ParentTableId` | `Ref` (`IsParentChild`) |
| Menu | `Menus` separado | **`Mnu`** (= `Menus` 1.0, `Action` → tabela) |

`appsettings.json` aponta `CRUDEX.xlsm` — coerente com o código atual.

## Convenções da planilha Novíssimo

### Colunas `#` = lookup

Colunas cujo título começa com `#` são fórmulas Excel (VLOOKUP). **Não são colunas físicas** do banco. Ignorar no DDL/INSERT; usar só na geração/leitura humana, ou resolver via FK real.

### Abas por Alias

A aba `Tbl` define `Name` (SQL/procedure) e `Alias` (nome da aba Excel). Ex.: tabela `Categories` → aba `Cat`.

### Owner (`Own`) — **2.0 exclusivo**

Não existe no **1.0** (sem owners). Aba **`Own`** → tabela **`Owners`**. Entra só no Novíssimo:

- `OwnerId = 1` (CRUDEX/SoftLab) = catálogo **global**, visível a **todos**.
- `OwnerId > 1` = dados **privados** do owner.
- Filtro padrão: `OwnerId IN (1, @SessionOwnerId)` — sem coluna `IsPlatform`; ID 1 é convenção fixa.
- **`AskDatabasePath`**: `1` pede path na criação do banco (quando o SGBD suporta); `0` não pede — vale para Docker, para SGBDs sem path, e para os que **permitem** omitir. Por owner; gerador 2.0 (sucessor do `isDocker` fixo do 1.0).

### Tipo SQL físico

```
Col.DomainId → Dmn.TypeId
Own.EngineId (owner da sessão) + Dmn.TypeId → Map → tipo do dialeto
Dmn.Length / Dmn.Decimals completam o tipo
```

`Cat` classifica tipos (`Typ`); `Eng` cadastra ~10 SGBDs; `Map` mapeia cada `Typ` por engine.

## Hierarquia Novíssimo (resumo)

**Nível mais alto do CRUDEX:** **`Db` (Database)**. Abaixo vêm **`Sys` (Systems)** e o restante do metadado operacional.

```
Cat → Typ → Map (× Eng de Own)

Own → Dmn (+ Mkg → Msk)          ← escopo multi-owner (2.0)

Db (Database — ápice)
  → Sys (Systems)
  → Env (Environments — cadeia linear, raiz única)
  → Con (DatabaseId + EnvironmentId)
  → Tbl → Col → …
  → Mnu (por SystemId, Action → Tbl)
Con (DatabaseId NULL + OwnerId)  ← externas: snipers; owner explícito (não herda de Db)

Ref (FK + IsParentChild) | Exp → Cnd | Bhv | Snp → Scr/Url
```

Detalhes de cada aba: [reference.md](reference.md).

## Pontos de desenho importantes

**Domínios (`Dmn`)** — Colunas usam `DomainId`, não `TypeId`. Domínio concentra validações, listas, owner; coluna (`Col`) traz flags `Is*`.

**Máscaras (`Msk` + `Mkg`)** — Máscara **semântica** (`ValidMask`: `9` numérico, `A` alfabético, `X` alfanumérico, `#` alfanumérico/especial). Na edição converte para `EditMask` (`#` por posição digitável). Escape `\A` para literal reservado. `Mkg` liga `Dmn`↔`Msk` + parâmetros opcionais de dígito verificador (`CheckDigitModule`, `CheckDigitFactors` com `|` para múltiplos DVs).

**Menu** — **`Mnu`** (= `Menus` 1.0): `ParentMenuId` **NULL** = barra horizontal; filhos = suspenso. `Action` só quando o item não tem filhos.

**Referências (`Ref` + `Rfk`)** — Não existe `ParentTableId` nem `ReferenceTableId`. `References`: `FkTableId`, `PkTableId`, `Name`, `IsParentChild`. `Referencekeys`: `FkColumnId` + `Sequence`; PK do pai inferida por ordem.

**Comparadores (`Cmp`)** — Metadado só catálogo (`Symbol`, `Arity`, `Rul`). SQL/JS no código: `TComparator` (JS), `ComparatorRegistry` (C#). **Pendente:** SQL por `Engine` no registry (não tabela `Map`).

**Unicidades (`Uni`)** — Valor de `LeftColumnId` não pode existir em `RightColumnId` (mesma ou outra tabela). `IsBirectional = true`: vale nos dois sentidos (ex.: `Tbl.Name` × `Tbl.Alias`).

**Expressões (`Exp` + `Cnd`)** — `Exp` agrupa `Cnd`. Usos: filtros fixos de grid/relatório, escopo de dados, **`Bhv`** (avaliadas a cada `change` no form).

**Comportamentos (`Prp` + `Bhv`)** — `Prp` cataloga propriedades DOM (`CategoryId` só tipa `Value`). `Bhv`: coluna + expressão → se verdadeira, aplica `Value` em `PropertyId` (ex.: máscara CPF/CNPJ dinâmica).

## Sistema atual — runtime

### Criptografia unificada

Uma única primitiva (`TransportCrypto` em C# e JS): **AES-256-GCM** com envelope JSON v1.

| Uso | Conteúdo cifrado | ek | Chave AES |
|-----|------------------|-----|-----------|
| **Transporte API** | JSON inteiro de request/response | Sempre (RSA-OAEP) | Por mensagem; `ek` embrulha a AES com RSA do **destinatário** |
| **Coluna `IsEncrypted`** | Valor do campo (string) | Não | **Mestra** (`DATA_ENCRYPTION_KEY` em appsettings / env) |

**RSA dual:** servidor mantém par fixo (`RSA_PRIVATE_KEY` / `RSA_PUBLIC_KEY` em appsettings, auto-criado); pública retornada no `config`. Cliente gera par RSA **por instância** (cada carga da SPA); pública enviada no login (`ClientRsaPublicKey` → `Sessions`). **Bidirecional:** request → `ek` com pública do **servidor**; response → `ek` com pública do **cliente**. A chave AES nunca trafega em claro.

Envelope transporte: `{ "v": 1, "ek", "iv", "t", "d" }`. Colunas armazenadas: `{ "v", "iv", "t", "d" }` sem `ek`.

API transporte: `EncryptTransport` / `DecryptValue` + unwrap `ek`; colunas: `EncryptStoredValue` / `DecryptStoredValue`.

**Implementação:** `RecordCrypto` cifra `ActualRecord`/`LastRecord` no persist e decifra o `DataSet` no read (servidor). Frontend recebe valores em claro dentro do transporte cifrado.

Chave mestra: `DATA_ENCRYPTION_KEY` (base64, 32 bytes). Par RSA servidor: `RSA_PRIVATE_KEY` / `RSA_PUBLIC_KEY` (PKCS#8 / SPKI base64). `Settings.Get` prioriza variável de ambiente. Se ausente ou inválida no `appsettings.json`, o servidor **gera e grava** na primeira inicialização.

**Fase atual:** transporte ativo; colunas com `IsEncrypted = 1` no metadado são cifradas no servidor ao gravar e decifradas ao ler.

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
- Frontend: `TSystem`, `TBrowse`, `TForm`, `TMenu`, `TMask`, `TConfig`
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
3. Evoluir `Config`, `Procedure.cs` (multi-provider via `Eng.Provider`), frontend (`TMask` semântico, menu via **`Mnu`** como 1.0, `Ref` sem `ParentTableId`)
4. **Não** adaptar `Scripts.cs` linha a linha — modelo incompatível

### Depurar CRUD

1. Tabela + ação em `SCRIPT-CRUDEX.sql`
2. Parâmetros JSON da procedure
3. `LoginId` / transação pendentes

## Constantes e convenções

- `PLATFORM_OWNER_ID = 1` (owner plataforma / global) — **2.0** (`Own`/`Owners`); não aplicável ao 1.0
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

Metadados em `CRUDEX_Novissimo.xlsm` (**39** tabelas e crescendo). Haverá extensões futuras; implementar o que está definido agora.

**Gaps principais vs. código atual:**

| Área | Atual | A implementar |
|------|-------|----------------|
| Gerador SQL | `Scripts.cs` T-SQL + `CRUDEX.xlsm` | Novo gerador multi-SGBD, abas por `Alias`, `Map` |
| Metadados | `ParentTableId`, `ReferenceTableId` | `Ref`/`Rfk`, `Uni`, `Exp`/`Cnd`, `Prm`, `Mkg`… |
| Comparadores SQL | `SqlComparator` no Excel (legado) | `TComparator`/`ComparatorRegistry` (1.0 ✓); **por Engine depois** |
| Menu | `Menus` separado | **`Mnu`** (= `Menus` 1.0) |
| Máscaras | `#` direto em `TMask` | ValidMask/EditMask semântico + `Mkg` |
| Comportamentos | hardcode em `TForm` | `Prp`/`Bhv` a cada `change` |
| Execução | — | `Sch`, `Snp` → `Scr`/`Url` (pipeline `Sequence` único) |
| **Forms master-detail** | **Não existe** | `Ref.IsParentChild` — formulário pai com filhas |

Prioridade de runtime: **`TRecordSet` + `TRecord`** (agora) → `TBrowse`/relatórios → `Config`/procedures Novíssimo → master-detail, `TMask`, `Bhv`, **`Mnu`**.

## Wordex + CRUDEX (integração 1.0)

Relatórios PDF via **iframe** + template Wordex salvo + JSON gerado pelo CRUDEX.

| Metadado | Papel |
|----------|--------|
| **Reports** | Template HTML autossuficiente (Wordex) |
| **Queries** | Tabela raiz + pai-filho/FK → árvore JSON (**não** confundir com VIEW do SQL) |

**Kind JSON** = `Categories.Name`. Vetor → `collection`; objeto → `object`; senão Category explícita. Macro `wordex.xlsm` = spec da geração JSON.

### Sistema de informação completo (visão)

```text
Dados (CRUD)  →  Informação (semântica)  →  Apresentação (Wordex)
   tabelas         domínios, queries,           relatório, dashboard,
   transações      regras, metadado             etiqueta, crachá, NF-e, …
```

CRUDEX cobre **dados** hoje; **Queries** ligam a **semântica** exportável; **Wordex** cobre **apresentação** — tudo metadado, sem projeto por entrega.

**Documentação do metamodelo (Wordex):** visualizar estrutura, relacionamentos, domínios, etc. — **substituto da planilha para análise**. Mesmo mecanismo de qualquer relatório; Query sobre metadado (`Tbl`, `Col`, `Ref`, `Dmn`…). Pode ser **relatório pré-definido** (mantenedor SGSI entrega com o CRUDEX) **ou criado pelo usuário** — nada impede os dois.

**Dashboard** = apenas um **Report** (template Wordex) com **várias tabelas/gráficos** Wordex no layout; **uma Query por fonte** (cada tabela do dashboard liga a sua Query / collection no JSON).

**Formatos Wordex:** A0…A10, B, C, ANSI, etc. + **personalizado** (largura/altura mm) — crachá, etiqueta, qualquer documento; no personalizado, definição de **etiquetas** na folha.

Detalhes: [../wordex/SKILL.md](../wordex/SKILL.md) e [../wordex/reference.md](../wordex/reference.md). Projeto: `Wordex/`.
