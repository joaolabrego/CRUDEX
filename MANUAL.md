# Manual do CRUDEX 1.0

Plataforma para construção de sistemas de informação orientados por **metadados**. Em vez de programar telas, grids e formulários tabela a tabela, descreve-se a estrutura do sistema — e o CRUDEX gera dinamicamente a aplicação.

> **Versão deste manual:** CRUDEX 1.0 (modelo atual, planilha `CRUDEX.xlsm` + `SCRIPT-CRUDEX.sql`).  
> O modelo **Novíssimo** (`CRUDEX_Novissimo.xlsm`) está documentado como evolução futura na [Parte III](#parte-iii--evolução-novíssimo).

---

## Sumário

1. [Conceitos fundamentais](#conceitos-fundamentais)
2. [Parte I — Manual do usuário](#parte-i--manual-do-usuário) — inclui [Atalhos de teclado](#atalhos-de-teclado)
3. [Parte II — Manual do desenvolvedor](#parte-ii--manual-do-desenvolvedor)
4. [Parte III — Evolução (Novíssimo)](#parte-iii--evolução-novíssimo)
5. [Glossário](#glossário)

---

## Conceitos fundamentais

| Conceito | Descrição |
|----------|-----------|
| **Metadados** | Definição das tabelas, colunas, domínios, menus e regras na planilha Excel |
| **Sistema** | Conjunto de tabelas ligadas a um banco (ex.: `crudex`) |
| **Ambiente** | Instância de conexão (`dev`, `hml`, `prd`) — URL `/{sistema}.{ambiente}` |
| **Grid** | Lista paginada de registros de uma tabela |
| **Formulário** | Tela de inclusão, alteração, exclusão, consulta, filtro ou pesquisa |
| **Procedure** | Lógica no SQL Server (`CategoriesRead`, `CategoriesPersist`, etc.) |
| **Transação** | Rascunho de alterações antes do commit definitivo |

### Princípio de arquitetura

A inteligência está no **banco de dados** (stored procedures). O ASP.NET e o JavaScript são camadas finas de apresentação e comunicação.

```
Planilha Excel → Gerador SQL → SQL Server ← ASP.NET ← Browser (SPA)
```

---

## Parte I — Manual do usuário

### Acesso ao sistema

1. Abra o endereço do sistema, por exemplo: `http://localhost:5000/crudex.dev`
2. Informe **usuário** e **senha**
3. Opcionalmente marque **Alterar senha** para definir nova senha no mesmo login
4. Após autenticação, o **menu principal** é exibido

O sistema encerra a sessão automaticamente após período de inatividade (configurável em `appsettings.json` → `IDLE_TIME_IN_MINUTES_LIMIT`).

### Menu principal

O menu organiza as tabelas cadastradas nos metadados. Cada item abre o **grid** da tabela correspondente.

### O grid (lista de registros)

O grid mostra as colunas marcadas como **listáveis** (`IsListable`) nos metadados.

| Área | Função |
|------|--------|
| **Cabeçalho** | Nomes das colunas; clique para **ordenar** (ascendente/descendente) |
| **Corpo** | Registros da página atual |
| **Rodapé** | Navegação de página, botões de ação e indicadores |

#### Botões do grid

| Botão | Função | Atalho |
|-------|--------|--------|
| Incluir | Abre formulário de **inclusão** | Alt+I |
| Alterar | Abre formulário de **alteração** do registro selecionado | Alt+A |
| Excluir | Abre formulário de **exclusão** | Alt+E |
| Ver | Abre formulário somente leitura (**consulta**) | Alt+V |
| Pesquisar | Localiza registro na página conforme critérios | *(sem atalho; tooltip indica Alt+P)* |
| Filtrar | Restringe os dados carregados do servidor | Alt+F |
| Desfiltrar | Remove todos os filtros ativos | Alt+L |
| Desordenar | Remove ordenação customizada | Alt+O |
| Sair | Volta ao menu principal | Alt+X |

Navegação e demais teclas: ver [Atalhos de teclado — grid](#atalhos-de-teclado).

### Operações CRUD

| Operação | O que faz |
|----------|-----------|
| **Incluir** | Cria registro novo |
| **Alterar** | Modifica registro existente |
| **Excluir** | Remove registro (com confirmação) |
| **Consultar (Ver)** | Exibe dados sem permitir edição |

### Formulários

Campos exibidos dependem da operação e das flags nos metadados (`IsEditable`, `IsFilterable`, etc.).

#### Botões do formulário

| Botão | Quando aparece | Função |
|-------|----------------|--------|
| **Persistir** | Inclusão / Alteração / Exclusão (primeira gravação) | Envia operação ao servidor como **rascunho** (transação aberta) |
| **Confirmar** | Após persistir, ou em Filtro/Pesquisa | **Commit** definitivo ou aplica filtro/pesquisa |
| **Cancelar** | Sempre (exceto consulta) | Descarta alterações / fecha sem aplicar |

#### Fluxo de edição (incluir / alterar / excluir)

```
1. Preencher campos
2. Persistir  →  operação fica pendente (transação aberta)
3. Confirmar  →  gravação definitiva no banco
   ou
   Cancelar   →  desfaz tudo (rollback)
```

Várias operações podem ser persistidas na mesma transação antes do commit.

**Inclusão:** após **Confirmar** com sucesso, o formulário é **remontado vazio** para uma nova inclusão (não volta ao grid). Use **Cancelar** para retornar à lista.

#### Campos especiais

| Tipo | Comportamento |
|------|---------------|
| **Texto / número** | Máscara quando definida no domínio |
| **Checkbox (edição)** | Clique alterna: sim → não → nulo (se opcional) |
| **Lista (FK)** | Dropdown paginado com descrição amigável em vez do código |
| **Obrigatório** | Balão nativo do navegador bloqueia Persistir/Confirmar se vazio |

Mensagens de validação usam o **Caption** do campo (texto amigável), não o nome técnico.

### Filtro e pesquisa

Filtro e pesquisa usam os campos marcados como **filtráveis** (`IsFilterable`). A interface segue o estilo **condição Clipper**: cada campo pode participar ou ser ignorado.

#### Estados de um critério

| Estado | Aparência | Efeito |
|--------|-----------|--------|
| **Ignorar** | Campo vazio, checkbox transparente | Critério **não entra** na consulta |
| **Nulo** | Placeholder "nulo" ou checkbox `–` | Filtra `IS NULL` |
| **Sim / Não** | Checkbox ✓ / ✗ | Igualdade booleana |
| **Valor** | Texto, número ou item da lista | Igualdade (filtro) ou contém (pesquisa em texto) |

#### Checkbox em modo condição (filtro/pesquisa)

Clique no checkbox cicla:

**sim → não → nulo → ignorar**

Em campos **obrigatórios** na edição, o ciclo é apenas **sim → não** (sem nulo/ignorar).

Para alternar **nulo** e **ignorar** com o teclado, use **Del** ou **Backspace** — ver [Atalhos de teclado — filtro e pesquisa](#formulário--filtro-e-pesquisa-del--backspace).

#### Diferença entre filtro e pesquisa

| | **Filtro** | **Pesquisa** |
|--|------------|--------------|
| Escopo | Recarrega dados do **servidor** (procedure `{Table}Read`) | Percorre / destaca na **página atual** |
| Texto | Igualdade exata | Contém (LIKE) |
| Uso típico | Restringir conjunto grande de registros | Achar linha visível rapidamente |

#### Tooltip do botão Desfiltrar

Mostra os critérios ativos, por exemplo:

- `ReferenceTableId IS NULL`
- `IsRequired = sim`
- `Name = 'Código'`

Critérios ignorados não aparecem.

### Atalhos de teclado

Referência consolidada. No **grid**, clique na tabela antes de usar os atalhos (ela recebe o foco). No **formulário**, o atalho vale para o **campo com foco**.

#### Grid — ações (Alt + tecla)

| Atalho | Ação |
|--------|------|
| Alt+I | Incluir |
| Alt+A | Alterar |
| Alt+E | Excluir |
| Alt+V | Consultar (Ver) |
| Alt+F | Filtrar |
| Alt+L | Desfiltrar |
| Alt+O | Desordenar |
| Alt+X | Sair (menu) |

> O botão **Pesquisar** exibe *Alt+P* no tooltip, mas esse atalho **ainda não está ligado** no grid — use o clique no botão.

#### Grid — navegação

| Tecla | Ação |
|-------|------|
| ↑ / ↓ | Registro anterior / seguinte |
| Page Up / Page Down | Página anterior / seguinte |
| Ctrl+E / Ctrl+X | Registro anterior / seguinte (alternativo) |
| Ctrl+C / Ctrl+R | Página anterior / seguinte (alternativo) |
| Enter | Abre **Alterar** no registro selecionado |
| Esc | Sair (volta ao menu) |

Campo numérico no rodapé: digite o número da página e confirme para ir diretamente a ela.

#### Formulário — navegação geral

| Tecla | Ação |
|-------|------|
| Tab / Enter | Próximo campo (`input`, `textarea` ou checkbox) |
| Esc | **Cancelar** e fechar; em **Consulta**, confirma e sai |

#### Formulário — checkbox

Com o foco no checkbox:

| Tecla / mouse | Ação |
|---------------|------|
| Clique | Avança para o próximo estado |
| Espaço / Enter | Idem |

Ciclos de estado:

| Modo | Ciclo |
|------|-------|
| **Edição** (incluir/alterar) | sim → não → nulo *(só se opcional)* |
| **Condição** (filtrar/pesquisar) | sim → não → nulo → ignorar |

#### Formulário — filtro e pesquisa (Del / Backspace)

Válido apenas em **Filtrar** e **Pesquisar**, em campos **não obrigatórios** (`IsRequired = false`).

Funciona em **texto**, **número**, **lista (FK/dropdown)** e **checkbox**.

| Situação | Del ou Backspace |
|----------|------------------|
| Campo **com conteúdo** | Apaga normalmente (não altera o modo condição) |
| Campo **vazio**, 1.ª vez | Define critério **nulo** (placeholder `nulo`, filtro `IS NULL`) |
| Campo **vazio**, 2.ª vez | **Ignora** o critério (equivalente a vazio/transparente) |
| Checkbox já em **nulo** | Vai direto para **ignorar** |

Fluxo resumido em campo vazio:

```
(vazio / ignorar) ──Del──► nulo ──Del──► ignorar
```

Alternativa ao teclado: clique no checkbox para ciclar até **nulo** ou **ignorar**; em listas FK, o placeholder `nulo` indica o estado ativo.

### Ordenação

- Clique no **cabeçalho** da coluna para ordenar
- Clique repetido alterna ascendente / descendente
- **Desordenar** (Alt+O) volta à ordem padrão

### Validação

| Camada | Quando |
|--------|--------|
| **Frontend** | Antes de Persistir/Confirmar — campos obrigatórios, máscaras, FK |
| **Backend** | Procedures `{Table}Validate` e constraints SQL — domínio, mínimo/máximo, FK, unicidade |

Erros do servidor aparecem em diálogo com mensagem em português.

---

## Parte II — Manual do desenvolvedor

### Estrutura do repositório

```
CRUDEX/
├── Program.cs              # Rotas ASP.NET, bootstrap
├── Classes/
│   ├── Scripts.cs          # Gerador SQL a partir do Excel
│   ├── Procedure.cs        # Execução de procedures
│   ├── Config.class.cs     # Metadados (Config)
│   └── Settings.class.cs   # Configuração da aplicação
├── StaticFiles/
│   ├── Assets/
│   │   ├── CRUDEX.xlsm     # Metadados do sistema atual
│   │   └── Styles/         # CSS
│   ├── Classes/            # Frontend SPA (TSystem, TBrowse, TForm…)
│   └── db/
│       └── SCRIPT-CRUDEX.sql   # Única fonte SQL válida do modelo atual
└── appsettings.json        # Conexão, Excel, imagens, paginação
```

### Metadados — planilha `CRUDEX.xlsm`

Cada aba corresponde a uma **tabela física** (nome completo, ex.: `Categories`).

Principais abas:

| Aba | Conteúdo |
|-----|----------|
| Systems, Databases, Connections | Sistemas e ambientes |
| Tables | Tabelas, menu, pai-filho (`ParentTableId`) |
| Columns | Colunas, domínio, FK (`ReferenceTableId`), flags |
| Domains, Types, Categories | Tipos e validações |
| Masks | Máscaras de entrada |
| Menus | Itens de menu |
| Indexes, Indexkeys, Unicities | Índices e unicidades cruzadas |

Colunas cujo título começa com **`#`** são lookups Excel (VLOOKUP) — **não** viram coluna física.

### Flags importantes em `Columns`

| Flag | Efeito |
|------|--------|
| `IsPrimarykey` | Chave primária |
| `IsAutoIncrement` | Identity / sequência |
| `IsRequired` | Obrigatório na edição |
| `IsListable` | Aparece no grid |
| `IsFilterable` | Participa de filtro/pesquisa |
| `IsEditable` | Editável em incluir/alterar |
| `IsGridable` | Reservado para layout |
| `IsEncrypted` | Criptografia |
| `ReferenceTableId` | FK → dropdown + `{Table}List` |

### Domínios e máscaras

- Cada coluna aponta para um **Domain** (`DomainId`)
- Domínio define tipo lógico, tamanho, valores válidos, máscara
- Máscara usa `#` por posição digitável; validação numérica pode exigir apenas dígitos parciais

### Procedures geradas

Para cada tabela `Foo` / `Fooss`:

| Procedure | Função |
|-----------|--------|
| `FooValidate` | Valida JSON `@ActualRecord` |
| `FooPersist` | Grava operação pendente |
| `FooCommit` | Aplica operação confirmada |
| `FoossRead` | Lista paginada com filtro JSON |
| `FoossList` | Lista simplificada (dropdowns) |

Infraestrutura: `Config`, `Login`, `GetPublicKey`, `TransactionBegin/Commit/Rollback`, `NewId`, `ScriptSystem`.

### Contrato do `{Table}Read`

Parâmetros principais:

- `@LoginId` — sessão
- `@RecordFilter` — JSON de filtros
- `@OrderBy` — ordenação
- `@PageNumber`, `@LimitRows`, `@MaxPage`

Formato atual de `@RecordFilter`:

```json
{
  "Filter": { "Name": "valor", "ReferenceTableId": null },
  "Fixed": { "TableId": 5 },
  "Id": 10
}
```

| JSON | SQL gerado |
|------|------------|
| Chave **ausente** | Critério ignorado |
| `"campo": null` | `AND [T].[campo] IS NULL` |
| `"campo": true/false` | Igualdade bit |
| `"campo": "texto"` | Igualdade |
| `"$._": [1,2,3]` | Lista de IDs selecionados |

Chaves em `$.Filter`, `$.Fixed` ou na **raiz plana** do JSON são reconhecidas.

### API HTTP

| Método | Rota | Função |
|--------|------|--------|
| GET | `/` | Regenera script + tela inicial |
| GET/POST | `/{sistema}.{ambiente}` | Fluxo da SPA |
| POST | `/{sistema}.{ambiente}` + action | `config`, `login`, `execute` |

Variável de ambiente `CRUDEX_ENVIRONMENT`: `dev` | `hml` | `prd`.

### Workflow de manutenção

1. Editar `CRUDEX/StaticFiles/Assets/CRUDEX.xlsm`
2. Regenerar SQL:
   - Reiniciar a aplicação (GET `/` chama `Scripts.Generate()`), **ou**
   - Compilar e executar com o projeto parado
3. Aplicar procedures no SQL Server  
   ⚠️ O script completo faz `DROP DATABASE` no início — em ambiente existente, executar apenas os blocos `ALTER PROCEDURE` necessários
4. Acessar `/{sistema}.{ambiente}` e testar

### Frontend — classes principais

| Classe | Arquivo | Papel |
|--------|---------|-------|
| `TSystem` | `TSystem.class.mjs` | Bootstrap, metadados em memória, roteamento de telas |
| `TBrowse` | `TBrowse.class.mjs` | Grid, botões, filtro/pesquisa na UI |
| `TForm` | `TForm.class.mjs` | Formulários CRUD, validação frontend |
| `TRecordSet` | `TRecordset.class.mjs` | Paginação, filtro, chamadas `{Table}Read` |
| `TRecord` | `TRecord.class.mjs` | Uma linha + `references.{alias}` |
| `TDropdown` | `TDropdown.class.mjs` | Listas FK paginadas |
| `TCheckbox` | `TCheckbox.class.mjs` | Checkbox edição e modo condição |
| `TEditBox` | `TEditBox.class.mjs` | Input unificado por tipo de coluna |
| `TTransaction` | `TTransaction.class.mjs` | Ciclo persist/commit |

### Configuração (`appsettings.json`)

| Chave | Uso |
|-------|-----|
| `ConnectionString` | SQL Server |
| `FILENAME_EXCEL` | Planilha de metadados |
| `ROWS_PER_PAGE` | Linhas por página no grid |
| `IDLE_TIME_IN_MINUTES_LIMIT` | Timeout de sessão |
| `DIRECTORY_SCRIPTS` | Pasta de saída do SQL gerado |
| `*_IMAGE` | Ícones dos botões |

### Depuração

1. Identificar tabela e ação → procedure em `SCRIPT-CRUDEX.sql`
2. Reproduzir JSON enviado (`RecordFilter`, `@ActualRecord`)
3. Verificar `@LoginId` e transação aberta (`Transactions` / `Operations`)
4. Erros usam `THROW 51000` com mensagem em português

---

## Parte III — Evolução (Novíssimo)

O arquivo `CRUDEX_Novissimo.xlsm` define o **modelo alvo** (34 abas, aliases curtos). Principais mudanças previstas:

| Área | Atual | Novíssimo |
|------|-------|-----------|
| Planilha | Nome da tabela = aba | Aba = **Alias** (`Cat`, `Tbl`, `Col`…) |
| Tipos SQL | `#DataType` fixo T-SQL | `Map` × engine do cliente |
| FK / pai-filho | `ReferenceTableId`, `ParentTableId` | Tabela `Ref` + `IsParentChild` |
| Menu | `Menus` separado | **`Mnu`** (= `Menus` 1.0) |
| Filtro avançado | Igualdade + IS NULL | Operadores `Cmp` (=, LIKE, IN, BETWEEN…) |
| Comportamentos | Hardcode no form | `Prp` / `Bhv` declarativos |
| Multi-SGBD | Só SQL Server | `Eng` + providers |
| Master-detail | Parcial | Formulário pai com filhas via `Ref` |

Documentação técnica detalhada: `.cursor/skills/crudex/reference.md`.

---

## Glossário

| Termo | Significado |
|-------|-------------|
| **Caption** | Rótulo amigável do campo na tela |
| **Commit** | Confirmação definitiva das operações pendentes |
| **Domain** | Tipo lógico + validações reutilizável |
| **FK** | Chave estrangeira — ligação entre tabelas |
| **Persist** | Grava rascunho da operação sem confirmar |
| **RecordFilter** | JSON de filtros enviado ao `{Table}Read` |
| **SPA** | Single Page Application — aplicação web sem recarregar página |
| **Owner** | Cliente / organização — **2.0 Novíssimo** (aba `Own`, tabela `Owners`); não existe no 1.0 |

---

## Referências

- [README.md](README.md) — visão geral do projeto
- [CRUDEX/StaticFiles/db/SCRIPT-CRUDEX.sql](CRUDEX/StaticFiles/db/SCRIPT-CRUDEX.sql) — procedures em produção
- [.cursor/skills/crudex/SKILL.md](.cursor/skills/crudex/SKILL.md) — guia para agentes/desenvolvimento
- [.cursor/skills/crudex/reference.md](.cursor/skills/crudex/reference.md) — referência técnica Novíssimo

---

*SoftLab / SGSI — CRUDEX 1.0*
