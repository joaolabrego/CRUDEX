# CRUDEX — Estado atual do projeto

Documento de referência para retomar o trabalho. Última revisão: **junho de 2026**.

## Contexto

- Projeto **pessoal** (hobby): plataforma de sistemas de informação orientados por metadados.
- A empresa onde o autor trabalha **não demonstrou interesse** em adotar o CRUDEX.
- Horizonte: **~2,5 anos** para aposentadoria — desenvolvimento no ritmo que couber.
- Ferramenta principal de apoio: **Cursor** (plano Pro + on-demand com **limite de gasto** recomendado ~US$ 100/ciclo ≈ R$ 500/mês total).

O CRUDEX continua valioso como obra técnica e aprendizado; não depende de aprovação externa para existir no repositório.

---

## O que é o CRUDEX 1.0 (em produção no código)

Plataforma em que **metadados** (tabelas, colunas, domínios, menus, FKs) descrevem um sistema; o runtime gera grids, formulários e CRUD sem código por tabela.

**Princípio:** a inteligência está no **SQL Server** (stored procedures). C# e JavaScript são camadas finas.

```
CRUDEX.xlsm → Scripts.Generate() → SCRIPT-CRUDEX.sql → SQL Server ← ASP.NET ← Browser (SPA)
```

**URL:** `/{sistema}.{ambiente}` — ex.: `http://localhost:5000/crudex.dev`

| POST | Função |
|------|--------|
| `/config` | Metadados (`Config`) |
| `/login` | Autenticação (`Login`) |
| `/execute` | CRUD (`{Table}Read`, `Persist`, transações, etc.) |

**Ciclo de dados:** `Validate` → `Persist` → `Commit` (+ `Read` / `List` por tabela).

---

## Modelo Novíssimo (2.0) — pausado

- Especificação: `CRUDEX/StaticFiles/Assets/CRUDEX_Novissimo.xlsm`
- Alvo: multi-SGBD, abas por **Alias**, `Ref`/`Rfk`, `Mnu`, `Map`, owners, etc.
- **Não implementar** gerador/procedures/runtime 2.0 até decisão explícita — ver [.cursor/skills/crudex/SKILL.md](.cursor/skills/crudex/SKILL.md) e [reference.md](.cursor/skills/crudex/reference.md).

Trabalho pontual já feito no gerador legado: `RenameExcelSheetsByTableAlias()` em `Scripts.cs` (renomeia abas `Cat`→`Categories` quando existe aba `Tbl`).

---

## Estrutura do repositório

```
SGSI_CRUDEX/
├── README.md                 # Visão geral
├── MANUAL.md                 # Manual usuário + desenvolvedor (1.0)
├── ESTADO-ATUAL.md           # Este arquivo
├── CRUDEX/
│   ├── Program.cs            # Host ASP.NET, rotas, --generate-script
│   ├── appsettings.json      # Conexão, Excel, estilos, paginação, chaves
│   ├── Classes/              # Backend C#
│   │   ├── Scripts.cs        # Gerador T-SQL a partir do Excel
│   │   ├── Procedure.cs      # Execução de procedures
│   │   ├── Config.class.cs   # Metadados
│   │   ├── RecordCrypto.class.cs
│   │   ├── ComparatorRegistry.cs
│   │   └── NovissimoExcel.cs # Ponte leitura Novíssimo (futuro)
│   └── StaticFiles/
│       ├── Assets/
│       │   ├── CRUDEX.xlsm           # Metadados 1.0 (fonte do gerador)
│       │   ├── CRUDEX_Novissimo.xlsm # Especificação 2.0
│       │   └── Styles/               # CSS (main, grid, form, dropdown…)
│       ├── Classes/                  # Frontend SPA (*.class.mjs)
│       ├── Components/               # TScreen.component.mjs
│       └── db/
│           └── SCRIPT-CRUDEX.sql     # Única fonte SQL válida do modelo 1.0
└── Wordex/                           # Integração relatórios/PDF (ver skill wordex)
```

---

## Backend (C#) — implementado

| Área | Arquivos / notas |
|------|------------------|
| API REST | `Program.cs`, `Api.class.cs` |
| Procedures | `Procedure.cs` — JSON `@ActualRecord`, `@LastRecord` |
| Gerador SQL | `Scripts.cs` — monolito T-SQL a partir de `CRUDEX.xlsm` |
| Config / Settings | `Config.class.cs`, `Settings.class.cs` |
| Criptografia | `RecordCrypto` + `TransportCrypto` (JS) — AES-GCM; transporte RSA dual |
| Comparadores | `ComparatorRegistry.cs` (SQL); `TComparator.class.mjs` (JS) |
| Relatórios | `Reports.cs` — integração Wordex |

**Gerar script SQL:**

```bash
cd CRUDEX
dotnet run -- --generate-script
dotnet run -- --generate-script --with-data
```

**Subir aplicação:**

```bash
cd CRUDEX
dotnet run
```

Requisitos: SQL Server com banco `crudex` e script aplicado; ajustar `ConnectionString` em `appsettings.json`.

---

## Frontend (SPA) — classes principais

| Classe | Papel |
|--------|--------|
| `TSystem` | Bootstrap, metadados, ações, FK, sessão |
| `TMenu` | Menu principal |
| `TBrowse` | Grid paginado, toolbar, filtros |
| `TForm` | Formulários incluir/alterar/excluir/consulta/filtro/pesquisa |
| `TEditBox` | Campo de formulário; condições; FK; máscaras |
| `TDropdown` | Single, multi, addable; filtro server-side |
| `TCheckbox` | Edição e modo condição (nulo/ignorar) |
| `TCondition` / `TComparator` | Operadores de filtro/pesquisa |
| `TMask` | Máscaras de entrada |
| `TCategoryHtml` | Tipo/alinhamento HTML por categoria (sem `HtmlInputType` no metadado) |
| `TRecordSet` / `TRecord` | Leitura paginada e linha com referências |
| `TLogin` | Autenticação |
| `TransportCrypto` | Cifra de request/response |

Estilos: `StaticFiles/Assets/Styles/` — variáveis em `main.css` (cores de seleção/hover, botões, ícones).

---

## UI — comportamento recente (jun/2026)

### Dropdown (`TDropdown` + `TEditBox`)

- **Single e multi com loader:** digitar no campo **filtra** a lista (servidor).
- **Fora de foco, vazio:** campo em branco (sem “Selecionar...”).
- **Fora de foco, com seleção:** rótulos colapsados (ex.: `Behaviors, Categories`).
- **Em foco, vazio:** placeholder `Select or type to filter`.
- **Texto parcial ao sair do foco:** limpa (não restaura último valor nem auto-completa).
- **Multi:** checkboxes na lista; sem campo “Filtrar...” interno na lista.
- **Comparador:** ao escolher operador, foco vai para o controle de valor (`#focusConditionControl`).

### Grid / scrollbar

- Linha selecionada: classe `currentRow` + `--grid-current-row-color`.
- Hover exploração: `--background-color-focus`.
- Tooltip da scrollbar: indica página ao passar o mouse.

### Categoria → HTML

- `TCategoryHtml.class.mjs` mapeia `Category.Name` → `input`/`checkbox`/`textarea`/alinhamento.
- Colunas `HtmlInputType` / `HtmlInputAlign` removidas do fluxo runtime (ainda podem existir no `SCRIPT-CRUDEX.sql` gerado até regenerar planilha).

---

## Integração Wordex

Relatórios PDF via iframe + template Wordex + JSON gerado pelo CRUDEX (`Reports`, `Queries`).

Documentação: [.cursor/skills/wordex/SKILL.md](.cursor/skills/wordex/SKILL.md)

---

## Pendências conhecidas (não priorizadas)

| Item | Notas |
|------|--------|
| Migração 2.0 completa | Novíssimo, gerador multi-SGBD, procedures novas |
| `HtmlInputType`/`HtmlInputAlign` | Remover da planilha e regenerar `SCRIPT-CRUDEX.sql` |
| `dbo.Config.sql` / `dbo.ScriptSystem.sql` | Reaplicar no banco após mudanças de metadado |
| Master-detail em formulário | `Ref.IsParentChild` — não existe no 1.0 |
| Comparadores SQL por engine | Registry hoje é T-SQL |
| Shell ERP (SIC) | iframes por sistema — visão futura, não implementada |
| Formulários `Bhv`/`Prp` | Comportamentos dinâmicos no Novíssimo |

---

## Documentação existente

| Documento | Conteúdo |
|-----------|----------|
| [DOCUMENTACAO.md](DOCUMENTACAO.md) | **Documentação técnica consolidada** — sistema inteiro |
| [README.md](README.md) | Visão geral e links |
| [MANUAL.md](MANUAL.md) | Usuário final + desenvolvedor (1.0) |
| [.cursor/skills/crudex/SKILL.md](.cursor/skills/crudex/SKILL.md) | Regras para agentes; Novíssimo; arquitetura |
| [.cursor/skills/crudex/reference.md](.cursor/skills/crudex/reference.md) | Referência aba a aba |
| [.cursor/skills/wordex/](.cursor/skills/wordex/) | Wordex ↔ CRUDEX |

---

## Como retomar (modo econômico)

1. Definir limite on-demand no Cursor (~**US$ 100**/ciclo após reset).
2. Preferir modelo **Auto**; uma tarefa por vez; evitar agente em loop.
3. Mudanças **pequenas e testáveis** — o projeto já tem base grande.
4. Antes de alterar metadado: backup `CRUDEX.xlsm` + regenerar script se necessário.
5. Testar em `crudex.dev` local antes de commit.

---

## Visão de futuro (opcional)

- **Hobby contínuo:** evoluir UI/UX e corrigir pontos no 1.0.
- **Congelar:** manter repo como está; retomar só quando quiser.
- **2.0:** só quando houver energia e orçamento para migração grande.

O código no repositório **já documenta** boa parte da intenção; este arquivo fixa o **retrato de junho/2026** para não depender da memória ou do histórico de chat.
