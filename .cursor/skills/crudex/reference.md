# CRUDEX — Referência técnica

## Planilhas Excel

| Arquivo | Papel |
|---------|-------|
| `CRUDEX.xlsm` | Metadados do sistema **atual** (21 abas, nomes completos) |
| `CRUDEX_Novissimo.xlsm` | Metadados **alvo** (**39** abas/tabelas e crescendo, aliases) |

## Novíssimo — mapa de abas

| Alias | Name (tabela) | Papel |
|-------|---------------|-------|
| `Cat` | Categories | Categorias de tipos (`string`, `number`…); flags `Ask*` |
| `Cmp` | Comparators | Comparadores para `Cnd` e `Rul` |
| `Rul` | Rules | Regras por categoria × comparador |
| `Eng` | Engines | SGBDs (~10): Provider, PackageName, IsActive |
| `Typ` | Types | Tipos lógicos (independente de SGBD); `CategoryId` |
| `Map` | Mappings | `EngineId` + `TypeId` → tipo físico do dialeto (~380 linhas) |
| `Own` | Owners | Owner; `EngineId` (SGBD); Id=1 = plataforma global; **`AskDatabasePath`** — ver abaixo |
| `Dmn` | Domains | `TypeId`, validações, `OwnerId`; **`ValidValues`** (lista fixa `;`, dropdown single, paginado no 1.0); **`ListValues`** (2.0 — seleção múltipla, a implementar) |
| `Msk` | Masks | Máscaras semânticas + legenda ValidMask/EditMask na aba |
| `Mkg` | Maskings | `Dmn` ↔ `Msk` + CheckDigit opcional |
| `Db` | Databases | **Ápice operacional** do CRUDEX: banco lógico (`OwnerId`, `EngineId`, Name) |
| `Env` | Environments | Hierarquia de ambientes (`ParentEnvironmentId`, `Name`, `Description`) — ver abaixo |
| `Con` | Connections | Conexão física (`ConnectionString`, `EngineId`, **`EnvironmentId`**, **`OwnerId`**) |
| `Sys` | Systems | Sistema — filho de `Db` (`DatabaseId`, Prefix, MaxRetryLogins) |
| `Mnu` | Menus | Menu por **`SystemId`** (1.0): `ParentMenuId`, `Sequence`, `Caption`, `Message`, **`Action`**, **`IsActive`** |
| `Tbl` | Tables | Definição da tabela (`Name`, `Alias`, …) — **sem** campos de menu |
| `Col` | Columns | `DomainId` (não TypeId); flags `Is*`; `IsVirtual` |
| `Idx` | Indexes | Índices; **`IsUnique`** + `Idk` |
| `Idk` | Indexkeys | Chaves de índice |
| `Inc` | Includes | Colunas incluídas em índice |
| `Uni` | Unicities | Unicidade cruzada entre colunas |
| `Exp` | Expressions | Agrupa condições (`Name`, `TableId`) |
| `Cnd` | Conditions | Linhas lógicas: `Cmp`, AND/OR, parênteses, colunas/valores |
| `Ref` | References | Relação FK: `FkTableId`, `PkTableId`, `Name`, `IsParentChild` |
| `Rfk` | Referencekeys | Colunas FK: `ReferenceId`, `FkColumnId`, `Sequence` |
| `Usr` | Users | Usuários por `OwnerId` (simples — dispensa detalhamento) |
| `Prm` | Permissions | CRUD direto: `SystemId` + `UserId` + `TableId` + `CanCreate/Read/Update/Delete` (sem grupos) |
| `Prp` | Properties | Catálogo de propriedades HTML/controle (nativas e customizadas) |
| `Bhv` | Behaviors | Aplica `Prp` em `Col` quando `ExpressionId` é verdadeira |
| `Sch` | Schedulers | Agendamento de tarefas (quando executar) — **WIP** |
| `Snp` | Snipers | Gatilho de execução ligado a `Tbl` (`IsBefore`) |
| `Scr` | Scripts | Scripts SQL por `SniperId` + `DatabaseId`, `Sequence` |
| `Url` | Urls | Chamadas HTTP (APIs) por `SniperId`, `Method`, `URL`, `Sequence` |
| `Ses` | Sessions | `Id` gerado a cada login (`OwnerId`, `SystemId`, `UserId`, `PublicKey`, `IsLogged`) |
| `Trs` | Transactions | Transações |
| `Ope` | Operations | Operações pendentes |

## Hierarquia operacional — **`Db` no topo**

O **nível mais alto do CRUDEX** é **`Db` (Database)**. Abaixo dele vêm **`Sys` (Systems)**, **`Con` (Connections)** e demais metadados (`Tbl`, `Col`, `Mnu`, snipers, etc.).

```
Db (Database)
  → Sys (Systems)          System.DatabaseId
  → Env (Environments — cadeia linear de deploy, raiz única)
  → Con (Connections)      DatabaseId + EnvironmentId
  → Tbl → Col → …          metadado de dados e UI

Con (DatabaseId NULL)       conexões externas — snipers; OwnerId **obrigatório** em Con
```

- **URL runtime:** `localhost:3000/{Sys.Name}.{Env.Name}` — o **usuário escolhe o ambiente no link** (`dev`, `hml`, `prd`, …). Ex.: `localhost:3000/crudex.dev`, `localhost:3000/sic.prd` (`Env.Name` livre, definido no metadado)
- **`Con` externas (`DatabaseId` NULL):** snipers em outro servidor/SGBD; **não herdam owner do `Db`** — ver `Con` abaixo
- **Sessão (`Ses`):** `OwnerId` + `SystemId` + …
- Metamodelo transversal (tipos, domínios, owners): `Own`, `Eng`, `Typ`, `Map`, `Dmn`… — escopo próprio, não substituem `Db` como ápice operacional

## Systems (`Sys`) — CRUDEX, SIC e **`Prefix`** (2.0)

**CRUDEX** e **SIC** não são camadas (motor vs produto). São **dois sistemas distintos**, ambos **especificados pelo próprio CRUDEX** (metamodelo bootstrap). O operador pode nem distinguir — vê menus e telas — mas no metadado são `Sys` separados no mesmo `Db` (ou em `Db` distintos, conforme deploy).

Campo **`Prefix`** em **`Systems`** (2.0): agrupa vários `Sys` como **módulos de um ERP lógico único**. Exemplo SIC:

| `Sys.Name` | `Prefix` | Papel |
|------------|----------|--------|
| `crudex` | — | Metamodelo / manutenção do próprio CRUDEX |
| **`sic`** | **`sic`** | **Sistema auxiliar (hub)** — menu dos subsistemas do ERP |
| `contabilidade` | `sic` | Módulo |
| `faturamento` | `sic` | Módulo (NF, SEFAZ, …) |
| `vendas` | `sic` | Módulo |
| `compras` | `sic` | Módulo |

Mesmo **`Prefix`** → o runtime trata o conjunto como **um sistema ERP** (sessão, escopo de negócio), mantendo cada módulo como `Sys` próprio (tabelas, menus, permissões por área). **Sem `Prefix`** (ou valores distintos) → sistemas independentes.

### URL — `nomeSistema.ambiente` + hub auxiliar

Formato único: **`localhost:3000/{Sys.Name}.{Env.Name}`**. Sistema **e** ambiente vêm do link — o operador (ou o bookmark) define se entra em `dev`, `hml`, `prd`, etc.

| URL (exemplo) | Comportamento |
|---------------|---------------|
| `localhost:3000/contabilidade.dev` | Subsistema **contabilidade** no ambiente **dev** |
| `localhost:3000/vendas.prd` | Subsistema **vendas** em **produção** |
| `localhost:3000/sic.hml` | **`Sys` auxiliar** `sic` em **hml** — menu agregador dos `Sys` com `Prefix = sic` |

O hub não substitui os módulos: é um **`Sys` especificado como os outros** (`Name` = valor do `Prefix`), cuja função é **navegar** para os subsistemas no **mesmo** `Env.Name` do link. Atalho direto: `contabilidade.prd`; entrada genérica no ERP: `sic.prd`.

Mercado compra **SIC** (NF, SEFAZ, custo); **CRUDEX** é o sistema que especifica CRUDEX e SIC — invisível como a classe `Report` no Clipper, mas não é “camada por baixo”: é outro `Sys` no mesmo fabricante.

## Connections (`Con`) — owner e `DatabaseId`

| `DatabaseId` | Papel | `OwnerId` |
|--------------|-------|-----------|
| **Preenchido** | Conexão de um `Db` num **`Env`** | Vem do **`Db.OwnerId`** (herdado ou validado — `Con` não fica órfã) |
| **NULL** | Conexão **externa** (outro banco/SGBD) para snipers (`Scr`) | **`OwnerId` obrigatório em `Con`** — sem `Db` pai, não há de onde herdar |

Problema evitado: `Con` externa sem `DatabaseId` **não pode** ficar sem escopo de owner. Cada connection externa pertence a um owner (`OwnerId IN (1, @SessionOwnerId)` na listagem/uso).

**Implementação na UI/metadado:** pode usar **`Bhv`** — ex.: ao preencher `DatabaseId`, propagar/sincronizar `OwnerId` a partir do `Db`; com `DatabaseId` NULL, exigir `OwnerId` explícito ou default da sessão. Validate na procedure complementa.

## Environments (`Env`) — cadeia linear de deploy

Tabela **`Environments`** (aba **`Env`**) — **2.0**, substitui dev/hml/prd engessados:

| Campo | Papel |
|-------|--------|
| `Id` | PK |
| `ParentEnvironmentId` | Pai imediato; **`NULL` = raiz** (única) |
| `Name` | Identificador livre — 2.º segmento da URL (`crudex.dev` → `Env.Name` = `dev`) |
| `Description` | Texto para o usuário |

**Não é árvore — é cadeia linear** (lista encadeada). Regras estruturais (Validate paranoico):

| Regra | Significado |
|-------|-------------|
| **Raiz única** | Só **1** registro com `ParentEnvironmentId` NULL por owner |
| **Sem órfãos** | Todo ambiente não-raiz aponta para pai existente na cadeia |
| **Sem irmãos** | Cada ambiente é pai de **no máximo 1** filho — sequência única, sem ramificações |

Exemplo (nomes livres; pode ter 50 elos):

```
dev   ParentEnvironmentId = NULL     ← única raiz
hml   ParentEnvironmentId = dev
prd   ParentEnvironmentId = hml
…     (cadeia continua linearmente)
```

**Deploy:** promoção só **pai → filho imediato** ao longo da cadeia — ordem de aplicação implícita, sem hardcode de nomes.

**Versionamento (futuro):** a cadeia `Env` sustenta **pipeline de versão** — cada versão gera deploy; após aplicar e testar em cada elo, exige **aprovação manual** antes de promover ao seguinte. **Reprovação manual** → **reabre o ambiente anterior** (retrocede um elo na cadeia). Exemplo clássico (3 elos, papéis ilustrativos):

| Elo | Quem aprova/reprova (exemplo) |
|-----|-------------------------------|
| 1.º (raiz, ex. dev) | **Analista** |
| 2.º (ex. hml) | **Usuário** |
| 3.º (ex. prd) | **DBA** — aplica em produção; aprovação final **conclui a versão** |

Todas as decisões são **manuais** (aprovar ou reprovar).

| Reprovar em… | Efeito |
|--------------|--------|
| **Raiz (ex. dev)** | Permanece na raiz — **não tem para onde correr** |
| **Qualquer outro elo** | Reabre **todos os níveis abaixo** (em direção à raiz): ex. **hml** → dev; **prd** → hml **e** dev |

**Aprovar** avança **um elo** (sobe na cadeia). **Reprovar** no elo corrente desfaz **toda a cadeia abaixo dele** até a raiz.

**Versão aberta:** só **uma versão em andamento** por **`Sys`** (sistema) ou por **`Db`** (database) — a definir; impede deploys concorrentes e conflito na cadeia `Env`. **Tabelas de versão/aprovação/deploy** — ainda **não** na planilha; virão depois (`Env` primeiro).

**Quantidade livre:** 50 ambientes = cadeia de 50 elos — permitido. **`Validate`/`Commit`** garante linearidade; **`Name` único** por owner; promoção não pula elo.

**Cadastro:** sem muleta na UI — quem monta a cadeia sabe que a **raiz** tem `ParentEnvironmentId` vazio. **Sem asterisco vermelho** nessa coluna (`IsRequired` off): NULL é válido. **`Validate`** barra só estado inválido (duas raízes, órfão, ciclo…). Mesmo espírito do `Mnu`.

**Índice via metadado (`Idx` + `Idk`):**

- **`IsUnique` em `ParentEnvironmentId`** — impede duplicata (dois filhos do mesmo pai). Sem `WHERE`; índice simples.

**Raiz única, existência da raiz, órfãos, ciclos** → **`Validate`** (índice não cobre NULL duplicado nem “tem de existir uma raiz”).

**`Con.EnvironmentId`** liga conexão física ao ambiente. Mesmo `Db` pode ter uma `Con` por `Env`.

Escopo por **`OwnerId`** — a definir na planilha; catálogo Id 1 visível a todos se aplicável.

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
1. Col.DomainId → Dmn (Name, Length, Decimals, ValidValues, OwnerId)
2. Dmn.TypeId → Typ → Cat (regras, Rul)
3. Sessão → Own.OwnerId → Own.EngineId
4. Map WHERE EngineId AND TypeId → nome físico (ex.: bigint / INT8 / NUMBER)
5. Montar tipo: Map.Name + Dmn.Length + Dmn.Decimals
```

## Comparadores (`Cmp`) e runtime

Metadado (`Cmp` + `Rul`): `Symbol`, `Description`, `Arity` — **sem** `SqlComparator`/`JsComparator` (lógica no código, como `Prp` → `TProperty`).

| Camada | Arquivo | Papel |
|--------|---------|-------|
| JS | `TComparator.class.mjs` | Registry por `Symbol`; `buildJs`, `parseValues` |
| C# | `ComparatorRegistry.cs` | `BuildSqlPredicate`, validação por `Symbol`+`Arity`; usado em `Scripts.cs` |
| Metadado | `Cmp`, `Rul` | Catálogo + quais operadores cada categoria pode usar |

**Pendente — importante, implementar depois:** SQL dos comparadores **por Engine (`Eng`)**, engessado no código (`TComparator` / `ComparatorRegistry`), **não** tabela estilo `Map`. Predicados variam estruturalmente entre SGBDs (`IN` + OPENJSON vs `ANY`/unnest, `LIKE` vs `ILIKE`, etc.) — é lógica procedural, não troca de rótulo. JS permanece único (browser não usa dialeto SQL).

**Resolução por engine (fallback):** metadado `Cmp` define **qual** operador (`Symbol`, `Arity`, `Rul`); `TComparator` / `ComparatorRegistry` define **como** montar SQL/JS. Fluxo: handler **padrão** engessado na classe; se existir versão **por engine** para aquele `Symbol`, **esta prevalece**; senão, padrão. Overrides **só onde o dialeto difere**.

**Chaves por nome, não por Id:** registry e overrides indexados por **`Symbol`** (comparador) e **`Eng.Name`** (SGBD, ex.: `"MySQL"`, `"SQL Server"`) — nunca por `ComparatorId`/`EngineId` numérico. Alinhado a `TProperty`/`Prp.Name` e `Typ.Name`.

Paralelo: `Typ`/`Map` = tradução declarativa; `Cmp`/registry = implementação fixa por engine.

## Owner (`Own` / `Owners`) — **2.0 exclusivo**

Conceito **Novíssimo** — o **1.0** não tem owners. Aba **`Own`**; tabela **`Owners`**.

- **Id 1**: dados CRUDEX/plataforma — visíveis a todos os owners.
- **Id 2+**: dados privados — só o owner + catálogo do Id 1.
- **`AskDatabasePath`**: `1` = gerador/UI **pede** caminho de ficheiros quando o SGBD suporta (ex.: SQL Server instalado, `.mdf`/`.ldf`). `0` = **não pede** — container/Docker, SGBDs que nunca usam path, ou implantação que também **permite** omitir path. Não é flag “Docker vs produção”; é **perguntar ou não**, por owner.
- SQL: `WHERE OwnerId IN (1, @SessionOwnerId)`
- Entidades com `OwnerId`: `Dmn`, `Msk`, `Db`, `Con` (obrigatório se `DatabaseId` NULL), `Usr`, `Sch`, `Ses`

## Domínios — listas na UI (`Dmn`)

**Princípio:** um só componente (`TDropdown`) e **um só comportamento** de picker — filtro, paginação (5/página), teclado, validação. A **origem dos dados** muda só o carregamento (`loader` servidor vs catálogo local); a UI **não** muda.

| Campo | Origem | Modo |
|-------|--------|------|
| **`ValidValues`** | `Dmn`, `;` separados — catálogo local | Single |
| **FK** | `{Table}Read` via `loader` | Single |
| **`ListValues`** (2.0) | `Dmn` — a implementar | **Multi** (mesmo `TDropdown`, mesma paginação) |

### `TListValues` — espelho do `TRecordSet` em memória (**implementado v1**)

Classe em `TListValues.class.mjs`. Construtor: **string** de valores + separador opcional (`;` default) → `split` em **`data`**. Mesma API de paginação/navegação que `TRecordSet`, sem `{Table}Read`.

| | **`TRecordSet`** | **`TListValues`** |
|--|------------------|-------------------|
| Fonte | Servidor (`{Table}Read`) | `data` em memória (`Dmn.ValidValues`, futuro `ListValues`) |
| Paginação | `readPickerPage`, `fetchPickerPage` | **Idêntica** — fatia `data` localmente |
| Filtro picker | `Picker.Value` no `Read` | `includes` case-insensitive sobre `data` |
| Última página | `PaddingGridLastPage: true` no `Read` | Mesma regra — janela deslocada para preencher `limitRows` |

**`TDropdown.loader`:** FK → `TRecordSet.fetchPickerPage`; `ValidValues` → `TListValues.fetchPickerPage`.

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

## Menu (`Mnu`) — modelo 1.0

Estrutura **igual à 1.0** (`Menus`): entidade **separada** de `Tbl`. Permite a **mesma tabela** (`Action`) em **vários sistemas** ou várias entradas no menu.

| Campo | Papel |
|-------|--------|
| `SystemId` | Menu pertence ao sistema |
| `Sequence` | Ordem no popup / barra |
| `Caption`, `Message` | Texto do item |
| `Action` | Tabela alvo (ex.: `grid/crudex/Tables`) — só dispara se **não tiver filhos** |
| `ParentMenuId` | **`NULL` = opção horizontal**; **preenchido** = suspenso |
| `IsActive` | `false` → item **não aparece** no menu — **manual** (analista decide); nada automático por master-detail |

Montagem **100% manual**: o usuário cadastra `Mnu`, vê no runtime, ajusta `Sequence`/`Caption`/`ParentMenuId`/`IsActive` até ficar como quer. Tudo é possível; **`Validate`** só barra inconsistência estrutural (FK, unicidades).

Runtime (`TMenu`): filhos → submenu (`Action` ignorado); folha → `Action`. Só itens `IsActive` no menu (`Config`/`TMenu` 2.0).

**`Tbl`** só define estrutura — **não** carrega `MenuId` nem caption. Tabelas filhas (`Ref.IsParentChild`): sem item de menu por convenção (master-detail).

Ação derivada: `grid/{Db.Name}/{Tbl.Name}` (via `Action` no menu).

## Referências (`Ref` + `Rfk`)

Substituem `Col.ReferenceTableId` e `Tbl.ParentTableId` (1.0).

**`References`** — cabeçalho (1 linha = 1 FK lógica ou master-detail):

| Campo | Papel |
|-------|--------|
| `FkTableId` | Tabela filha (onde estão as FKs) |
| `PkTableId` | Tabela referenciada (PK) |
| `Name` | Nome lógico da relação (JSON, joins, UI) |
| `IsParentChild` | `true` = FK + master-detail no formulário |

**`Referencekeys`** — só o lado FK (PK inferida pela ordem canônica do pai):

| Campo | Papel |
|-------|--------|
| `ReferenceId` | → `References` |
| `FkColumnId` | Coluna FK na filha |
| `Sequence` | Ordem relativa (ex.: 5, 10, 15…) — **não** precisa igualar `PkSequence` do pai |

Gerador: `ORDER BY Sequence` em `Referencekeys` e `ORDER BY PkSequence`/`Sequence` na PK do `PkTableId`; pareamento por **posição** (1.ª FK → 1.ª PK, 2.ª → 2.ª…). Validar: mesma quantidade de chaves; `Sequence` única por `ReferenceId`.

DDL: `FOREIGN KEY (fk1, fk2, …) REFERENCES pai (pk1, pk2, …)` — colunas PK **não** cadastradas em `Referencekeys`.

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

Agendamento por owner (`OwnerId`): `Interval`, `Periodicity` (ex. `day`), `TimeOfDay`, `DayOfMonth`, `NextRunDate`, flags `IsBusinessDays`, `IsFirstOrLastDay`, `IsRunOnce`, `IsActive`, `IsForwardHoliday`.

`IsForwardHoliday` (com `IsBusinessDays`): se a data nominal cair em feriado/fim de semana, `1` = avançar para o próximo dia útil; `0` = retroagir para o dia útil anterior. Implementação futura em função de calendário separada de `NextDate`.

**Lacuna atual:** falta ligar `Sch` ao **o quê** executar. Intenção: disparar `Scr`/`Url` (scripts SQL e chamadas HTTP/API), uma ou várias — mesmo payload do sniper, disparo por tempo.

### `Snp` + `Scr` + `Url` — snipers (triggers CRUD)

**Snipers = triggers de metadados** — executados **antes ou depois** de operações CRUD na tabela, conforme `IsBefore`:

| `IsBefore` | Momento |
|------------|---------|
| `true` | Antes do CRUD (validação, preparação, bloqueio) |
| `false` | Depois do CRUD (efeitos colaterais, integração, notificação) |

**`Snp`**: `TableId`, `Name`, `IsBefore`, `IsActive`.

**`Scr`** — scripts SQL extensos por sniper: `SniperId`, `DatabaseId`, `Sequence`, `Script`. Metadado único; o **runtime decide como executar** conforme a conexão alvo (`Db` → `Con` **ou** `Con` externa com `DatabaseId` NULL → `Eng.Provider`):

| Conexão alvo do `Scr` | Execução |
|-----------------------|----------|
| Mesmo provider do sistema (ex.: SQL Server local, `Con` do `Db`) | **Direta** — script extenso na conexão |
| `Con` externa (`DatabaseId` NULL) ou provider ≠ do sistema | **Via HTTP** — mesma URL da API CRUDEX (comando simples por chamada) |

Conexões **`Con` com `DatabaseId` NULL** existem para snipers em **outros bancos/SGBDs** — fora do database operacional do CRUDEX. No caso HTTP, um comando simples por chamada (`EXEC`, `INSERT`, …); o analista cadastra só `Scr`; o desvio é transparente.

**`Url`** — chamadas HTTP explícitas no pipeline: `SniperId`, `Sequence`, `Method`, `URL`. Integrações **externas ao CRUDEX** (SEFAZ NF-e, webhooks, APIs de terceiros). Distinto do roteamento automático de `Scr` acima.

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

`Id` gerado a cada login. `OwnerId`, `SystemId`, `UserId`, `PublicKey`, `IsLogged`. Retornado como `LoginId`.

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
| Tipo SQL | `#DataType` em Types | `Map` × `Own.EngineId` |
| FK | `Col.ReferenceTableId` | `Ref` + `Rfk` |
| Pai-filho | `Tbl.ParentTableId` | `Ref.IsParentChild` |
| Menu | `Menus` + `Action` | **`Mnu`** (= `Menus` 1.0) — **não** campos em `Tbl` |
| Unicidade cruzada | `Unicities` | `Uni` |
| Máscara no domínio | `Domains.MaskId` | `Mkg` |
| Multi-SGBD | Não | `Eng` + `Map` |
| Owner (`Own`) | Não existe | `Owners` + filtro `OwnerId IN (1, @SessionOwnerId)` |

## Geração de scripts

**Atual** — `Scripts.cs`:
- Fonte **Excel** (padrão `crudex`): `ExcelToDataSet()` ← `FILENAME_EXCEL`
- Fonte **banco**: `GetDataSet()` ← procedure `[dbo].[ScriptSystem]` (`isExcel=false` ou `systemName` ≠ `crudex`)
- Abas pelo `table["Name"]` (Excel) ou datasets do ScriptSystem (banco)
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

`CRUDEX_ENVIRONMENT`: nome de um registro em **`Env`** (1.0: `dev` | `hml` | `prd` fixos)

## Deploy banco (SCRIPT-CRUDEX.sql)

Script faz `DROP DATABASE crudex`; ajustar paths `.mdf`/`.ldf` antes de executar.

## Status do modelo Novíssimo

**Só análise por agora** — não codificar 2.0 ainda. Planilha em evolução (**39** tabelas; versionamento = tabelas futuras). Documentar decisões; implementação (gerador, `Config`, frontend, versionamento) quando o metamodelo estabilizar.

**O código atual não possui forms master-detail.** Implementar via `Ref.IsParentChild` + tabelas filhas (sem `MenuId` por convenção).

## Procedures atuais e evolução do `Read`

**Baseline:** todas as procedures em produção estão em `SCRIPT-CRUDEX.sql` (única fonte SQL válida do modelo atual). Versões intermediárias existem e serão testadas antes de consolidar mudanças.

### `{Table}Read` hoje (`SCRIPT-CRUDEX.sql`)

Parâmetros típicos: `@LoginId`, `@RecordFilter` (JSON), `@OrderBy`, `@PaddingGridLastPage`, `@IsActionList`, `@PageNumber`, `@LimitRows`, `@MaxPage` OUT.

`@RecordFilter` atual:
- JSON **plano** coluna → valor (predominantemente igualdade)
- Chave especial `$._` = array de Ids selecionados
- Filtro/pesquisa do grid (`TBrowse` → `TForm` FILTER/SEARCH) serializa `#FilterValues` / `#SearchValues` nesse formato

### `{Table}Read` Novíssimo (mudança grande — em teste)

**Filtragem** e **pesquisa** passarão JSON estruturado com:

| Parte | Conteúdo |
|-------|----------|
| valor | dado da coluna / critério |
| operador | símbolo ou id de `Cmp` (`<`, `=`, `∈`, `⊃` LIKE, `∃` BETWEEN…) |
| comparando | literal, lista, outra coluna ou intervalo conforme `Cmp.Arity` |

**Conector fixo `AND`** — reflete como o usuário pensa: na prática formula critérios encadeados (“nome contém X **e** data após Y **e** status Z”), raramente OR. A UI de filtro/pesquisa só monta condições em **AND** (sem escolher conector nem parênteses). Condições **complexas** (OR, parênteses) ficam em **`Exp`/`Cnd`** — analista/negócio, não o usuário final na grid.

Compilação: `WHERE col1 op val1 AND col2 op val2 AND …` via `ComparatorRegistry` / `TComparator` (SQL Server hoje; **por Engine depois** — ver seção Comparadores).

**Emular OR sem OR na UI:** operadores `∈` (IN) e `∃` (BETWEEN) cobrem disjunção e faixas. OR explícito só em `Exp`/`Cnd`.

**Cobertura estimada:** filtro/pesquisa na grid (AND + `Cmp`) atende ~**90%** dos casos do usuário; os ~10% restantes → expressões fixas (`Exp`/`Cnd`) definidas pelo analista.

Mesclar com expressões fixas (`Exp`/`Cnd`) e `Prm` antes de executar a query.

Frontend (`TBrowse`/`TForm`): adaptar envio de FILTER/SEARCH para array de critérios (sem conector explícito).

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
TBrowse  ──→  TRecordSet  ──→  POST execute / {Table}Read  →  Table + Refs
TReport ──→  TRecordSet  ──→  (mesmo contrato; percorre todas as páginas)
```

`TBrowse` deixa de chamar `Read` diretamente; delega ao `TRecordSet`. Filtros fixos (`Exp`) vêm do servidor; filtros do usuário via métodos na classe.

### `TRecordSet` — contrato com `Read` atual (para testes)

Chamada via `TConfig.GetAPI('execute', …)` igual ao `TBrowse` hoje:

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

### `TListValues` (v1)

`TListValues.class.mjs` — espelho em memória de `TRecordSet` para `Dmn.ValidValues` / `ListValues`. Ver **Domínios — `TListValues`**.

### Checklist de implementação

- [x] **`TRecordSet` + `TRecord`** — v1 em `TRecordset.class.mjs` / `TRecord.class.mjs`
- [ ] Testar no CRUDEX atual (ex.: `Categories`)
- [x] `TBrowse` delega ao `TRecordSet` (`#ReadDataPage` → `goPage`)
- [x] `TForm` usa `SelectedRecord` / `RecordSet.readOne` (compatível com Read JSON)
- [x] **`TDropdown`** — seleção simples, multi, inclusão manual (IN), cardinalidade (BETWEEN)
- [x] **`TListValues`** — espelho em memória de `TRecordSet` para `ValidValues` / `ListValues`
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
- [ ] **`Ref` + `Rfk`** — FK composta, master-detail (substituir `ReferenceTableId`/`ParentTableId`)
- [ ] **`TComparator` / `ComparatorRegistry` por Engine** — SQL multi-SGBD no código (pendente; importante)
- [ ] Procedures redesenhadas (multi-dialeto, `Prm`, `Uni`, `Ref`…)
- [ ] **`{Table}Read`** — JSON filtro/pesquisa com operador + comparando (`Cmp`)
- [ ] `Config` / backend multi-provider (`Eng.Provider`)
- [ ] Menu **`Mnu`** (= modelo 1.0 `Menus`, separado de `Tbl`)
- [ ] `TMask` semântico + `Mkg` check digit
- [ ] `Prp`/`Bhv` no form (`change` → expressão → propriedade)
- [ ] **Master-detail no `TForm`**
- [ ] `Sch` (worker agenda) + `Snp` (triggers) → `Scr`/`Url`
- [ ] Owner `Own`/`Owners` filtro `OwnerId IN (1, @SessionOwnerId)`
