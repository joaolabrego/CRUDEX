"use strict";

import TForm from "./TForm.class.mjs";
import TScreen from "./TScreen.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TCheckbox from "./TCheckbox.class.mjs";
import TCondition from "./TCondition.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TRecordSet from "./TRecordset.class.mjs";
import TScrollBar from "./TScrollBar.class.mjs";
import TCategoryHtml from "./TCategoryHtml.class.mjs";

export default class TBrowse {
    #RowCount = 0;
    #LastPageNumber = 1;
    #PageNumber = 1;
    #PageCount = 0;
    #RowNumber = 0;
    #IsRendering = false;
    #IsNavigateByScroll = false;
    #Rows = [];
    #ColumnTitle = null;
    #Data = null;
    #Table = null;
    #RecordSet = null;
    #ScrollBar = null;
    #embedded = false;
    #masterForm = null;
    #readOnlyCud = false;
    #enabled = true;
    #rowsPerPage = 0;

    #HTML = {
        Container: null,
        Table: null,
        Head: null,
        Body: null,
        Foot: null,
        GridViewport: null,
        NumberInput: null,
        CreateButton: null,
        UpdateButton: null,
        DeleteButton: null,
        QueryButton: null,
        SearchButton: null,
        FilterButton: null,
        UnorderButton: null,
        UnfilterButton: null,
        ExitButton: null,
        SelectedRow: null,
    };

    static #Style = "";
    static #Images = {
        Insert: "",
        Edit: "",
        Search: "",
        Filter: "",
        Unfilter: "",
        Unorder: "",
        Delete: "",
        Query: "",
        Exit: "",
    };
    constructor(databaseName, tableName, options = {}) {
        let database = TSystem.GetDatabase(databaseName);

        if (!database) throw new Error("Banco-de-dados não encontrado.");
        this.#Table = database.GetTable(tableName);
        if (!this.#Table)
            throw new Error("Tabela de banco-de-dados não encontrada.");
        this.#embedded = options.embedded === true;
        this.#masterForm = options.masterForm ?? null;
        this.#readOnlyCud = options.readOnlyCud === true;
        this.#rowsPerPage = this.#embedded ? TSystem.RowsPerChildPage : TSystem.RowsPerPage;
        this.#RecordSet = new TRecordSet(this.#Table, {
            showSpinner: !this.#embedded,
            rowsPerPage: this.#rowsPerPage,
        });
        this.#HTML.Container = document.createElement("div");
        this.#HTML.Container.className = "container";
        this.#CreateGrid();
        this.#ScrollBar = TScrollBar.Attach(this.#HTML.Container, {
            min: 1,
            max: 1,
            value: 1,
            onChange: (pageNumber) => {
                if (pageNumber !== this.#PageNumber)
                    this.Renderize(pageNumber);
            },
        });
    }
    setEnabled(enabled) {
        this.#enabled = enabled;
        this.#HTML.Container?.classList.toggle("grid-disabled", !enabled);
    }
    #gridColumns() {
        let columns = this.#Table.Columns.filter(column => column.IsGridable);
        if (!this.#masterForm)
            return columns;
        const linkColumn = TSystem.GetParentLinkColumn(
            this.#Table,
            this.#masterForm.parentTable,
            this.#masterForm.Table,
        );
        if (linkColumn)
            columns = columns.filter(column => column !== linkColumn);
        return columns;
    }
    static Initialize(styles, images) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não são do tipo Styles.");
        if (images.ClassName !== "Images")
            throw new Error("Argumento images não são do tipo Images.");
        this.#Style = styles.Grid;
        this.#Images.Delete = images.Delete;
        this.#Images.Query = images.Query;
        this.#Images.Edit = images.Edit;
        this.#Images.Exit = images.Exit;
        this.#Images.Search = images.Search;
        this.#Images.Filter = images.Filter;
        this.#Images.Unfilter = images.Unfilter;
        this.#Images.Unorder = images.Unorder;
        this.#Images.Insert = images.Insert;
    }
    #CreateGrid() {
        let arrowUp = (event) => {
            event.preventDefault();
            if (this.#HTML.SelectedRow.rowIndex > 1)
                this.#Rows[this.#HTML.SelectedRow.rowIndex - 2].click();
            else if (Math.trunc(this.#PageNumber) === 1) {
                this.Renderize(this.#PageCount);
                this.#Rows[this.#Rows.length - 1].click();
            } else {
                this.Renderize(this.#PageNumber - 1);
                this.#Rows[this.#Rows.length - 1].click();
            }
        },
            arrowDown = (event) => {
                event.preventDefault();
                if (this.#HTML.SelectedRow.rowIndex < this.#Rows.length)
                    this.#Rows[this.#HTML.SelectedRow.rowIndex].click();
                else if (Math.trunc(this.#PageNumber) === this.#PageCount) {
                    this.Renderize(1);
                    this.#Rows[0].click();
                } else {
                    this.Renderize(this.#PageNumber + 1);
                    this.#Rows[0].click();
                }
            },
            pageUp = (event) => {
                event.preventDefault();
                if (this.#PageNumber > 1) this.Renderize(this.#PageNumber - 1);
                else this.Renderize(this.#PageCount);
            },
            pageDown = (event) => {
                event.preventDefault();
                if (this.#PageNumber < this.#PageCount)
                    this.Renderize(this.#PageNumber + 1);
                else this.Renderize(1);
            };

        this.#HTML.Table = document.createElement("table");
        this.#HTML.Table.setAttribute("tabindex", "0");
        this.#HTML.Table.className = "grid box";
        this.#HTML.Table.onkeydown = (event) => {
            if (event.altKey) {
                switch (event.key) {
                    case "i":
                        event.preventDefault();
                        if (!this.#HTML.CreateButton.hidden)
                            this.#HTML.CreateButton.click();
                        break;
                    case "a":
                        event.preventDefault();
                        if (!this.#HTML.UpdateButton.hidden)
                            this.#HTML.UpdateButton.click();
                        break;
                    case "e":
                        event.preventDefault();
                        if (!this.#HTML.DeleteButton.hidden)
                            this.#HTML.DeleteButton.click();
                        break;
                    case "v":
                        event.preventDefault();
                        if (!this.#HTML.QueryButton.hidden) this.#HTML.QueryButton.click();
                        break;
                    case "f":
                        event.preventDefault();
                        if (!this.#HTML.FilterButton.hidden)
                            this.#HTML.FilterButton.click();
                        break;
                    case "l":
                        event.preventDefault();
                        if (!this.#HTML.UnfilterButton.hidden)
                            this.#HTML.UnfilterButton.click();
                        break;
                    case "o":
                        event.preventDefault();
                        if (!this.#HTML.UnorderButton.hidden)
                            this.#HTML.UnorderButton.click();
                        break;
                    case "x":
                        event.preventDefault();
                        if (!this.#HTML.ExitButton.hidden) this.#HTML.ExitButton.click();
                        break;
                }
            } else if (event.ctrlKey) {
                switch (event.key) {
                    case "e":
                        arrowUp(event);
                        break;
                    case "x":
                        arrowDown(event);
                        break;
                    case "c":
                        pageUp(event);
                        break;
                    case "r":
                        pageDown(event);
                        break;
                }
            } else {
                switch (event.key) {
                    case "ArrowUp":
                        arrowUp(event);
                        break;
                    case "ArrowDown":
                        arrowDown(event);
                        break;
                    case "PageUp":
                        pageUp(event);
                        break;
                    case "PageDown":
                        pageDown(event);
                        break;
                    case "Enter":
                        event.preventDefault();
                        this.#HTML.UpdateButton.click();
                        break;
                    case "Escape":
                        event.preventDefault();
                        this.#HTML.ExitButton.click();
                        break;
                }
            }
        };

        let style = document.createElement("style");

        style.textContent = TBrowse.#Style;
        this.#HTML.Table.appendChild(style);

        this.#HTML.Head = document.createElement("thead");
        this.#HTML.Table.appendChild(this.#HTML.Head);

        this.#HTML.Body = document.createElement("tbody");
        this.#HTML.Table.appendChild(this.#HTML.Body);

        this.#HTML.Foot = document.createElement("tfoot");
        this.#HTML.Table.appendChild(this.#HTML.Foot);

        this.#HTML.GridViewport = document.createElement("div");
        this.#HTML.GridViewport.className = "grid-viewport";
        this.#HTML.GridViewport.appendChild(this.#HTML.Table);
        this.#HTML.Container.appendChild(this.#HTML.GridViewport);
    };

    #valueMatchesSearch(column, record, searchValue) {
        if (TCheckbox.isIgnored(searchValue) && TConfig.IsEmpty(searchValue))
            return true;
        if (TCondition.isCriterion(searchValue)) {
            const comparator = searchValue.comparator;
            const expected = searchValue.value;
            const actual = record[column.Name];
            if (TCheckbox.isNullMarker(searchValue))
                return actual == null;
            if (expected === null || expected === undefined)
                return actual == null;
            if (comparator === 9 && expected != null)
                return String(actual ?? "").toLowerCase().includes(String(expected).replace(/^%|%$/g, "").toLowerCase());
            if (Array.isArray(expected))
                return expected.some(item => item == actual);
            return actual == expected;
        }
        if (TCheckbox.hasCondition(searchValue)) {
            const expected = TCheckbox.toFilterValue(searchValue);
            const actual = record[column.Name];
            if (expected === null)
                return actual == null;
            return actual === expected;
        }
        const actual = record[column.Name];
        if (actual == null && TConfig.IsEmpty(searchValue))
            return true;
        if (actual == null || TConfig.IsEmpty(searchValue))
            return false;
        const dataType = (column.Domain?.Type?.Name ?? "").toLowerCase();
        const isText = dataType.includes("char") || dataType.includes("text");
        const left = String(actual).toLowerCase();
        const right = String(searchValue).toLowerCase();
        return isText ? left.includes(right) : left === right;
    }
    #selectSearchedRow() {
        if (!this.#RecordSet.isSearched() || !this.#Data?.length)
            return;
        const columns = this.#Table.Columns.filter(column => column.IsFilterable);
        for (let index = 0; index < this.#Data.length; index++) {
            const record = this.#Data[index];
            if (columns.every(column =>
                this.#valueMatchesSearch(column, record, this.#RecordSet.Search.get(column.Name)))) {
                this.#RowNumber = index;
                return;
            }
        }
        this.#RowNumber = this.#Data.length - 1;
    }
    async #ReadDataPage(pageNumber) {
        await this.#RecordSet.goPage(pageNumber);

        this.#RowCount = this.#RecordSet.rowCount;
        this.#PageNumber = this.#RecordSet.pageNumber;
        this.#PageCount = this.#RecordSet.pageCount;
        this.#ScrollBar.setRange(1, this.#PageCount, this.#PageNumber);
        if (this.#RowCount && this.#RowNumber >= this.#RowCount)
            this.#RowNumber = this.#RowCount - 1;

        return this.#RecordSet.records;
    }
    async Renderize(pageNumber = this.#PageNumber, options = {}) {
        if (this.#IsRendering) return;
        this.#IsRendering = true;
        try {
            if (options.emptyShell) {
                this.#Data = [];
                this.#RowCount = 0;
                this.#PageNumber = 1;
                this.#PageCount = 1;
                this.#RowNumber = 0;
                this.#BuildHtmlHead();
                this.#BuildHtmlBody();
                this.#BuildHtmlFoot();
                this.#ScrollBar.setVisible(false);
                return;
            }
            this.#Data = await this.#ReadDataPage(pageNumber);
            this.#selectSearchedRow();
            if (this.#RowCount > 1)
                TScreen.LastMessage = TScreen.Message =
                    "Clique na linha que deseja selecionar.";
            else
                TScreen.LastMessage = TScreen.Message = "Clique em um dos botões.";
            if (!this.#embedded)
                TScreen.Title = `Manutenção de ${this.#Table.Description}`;
            this.#BuildHtmlHead();
            this.#BuildHtmlBody();
            this.#BuildHtmlFoot();
            if (!this.#embedded) {
                TScreen.WithBackgroundImage = true;
                TScreen.Main = this.#HTML.Container;
                this.#HTML.Table.focus();
            }
            this.#ScrollBar.setVisible(this.#RowCount > this.#rowsPerPage);
            if (!this.#embedded)
                this.#ScrollBar.setTitle(`Página atual: ${this.#PageNumber}`);
        } catch (error) {
            TScreen.ShowError(
                error.message || error.Message,
                `grid/${this.#Table.Database.Name}/${this.#Table.Name}`
            );
        } finally {
            this.#IsRendering = false;
        }
        /*
                globalThis.$ = new Proxy(this.#Table, {
                    get: (target, key) => {
                        const getColumn = (table, columnName) => {
                            let column = table.GetColumn(columnName)
        
                            if (column)
                                return column
                            if (table.ParentTableId)
                                return getColumn(TSystem.GetTable(table.ParentTableId), columnName)
                            throw new Error(`Nome de coluna '${columnName}' não existe.`)
                        }
        
                        return getColumn(target, key).Value
                    },
                    set: (target, key, value) => {
                        let column = target.GetColumn(key)
        
                        return column.Value = value
                    }
                })
                */
    }
    #GetControl(column, value) {
        let control;

        if (TCategoryHtml.isCheckbox(column.Domain.Type.Category)) {
            control = document.createElement("span");
            control.className = "grid-bool";
            if (value === true) {
                control.classList.add("grid-bool-true");
                control.textContent = "\u2713";
            } else if (value === false) {
                control.classList.add("grid-bool-false");
                control.textContent = "\u2717";
            }
        } else {
            control = document.createTextNode(value ?? "");
        }

        return control;
    }
    #BuildHtmlHead() {
        let tr = document.createElement("tr");

        this.#gridColumns().forEach(
            (column) => {
                let th = document.createElement("th");

                th.Name = column.Name;
                th.IsOrdered = this.#RecordSet.getColumnOrder(column);
                th.innerHTML =
                    column.Title +
                    (th.IsOrdered === null
                        ? ""
                        : th.IsOrdered
                            ? "&nbsp;\u25BC"
                            : "&nbsp;\u25B2");
                if (this.#ColumnTitle)
                    th.title = this.#ColumnTitle;
                th.onclick = (event) => {
                    const orderDirection = this.#RecordSet.toggleOrderDirection(column);
                    event.target.IsOrdered = orderDirection;
                    if (orderDirection === null) {
                        event.target.innerHTML = column.Title;
                        this.#ColumnTitle = null;
                    } else if (orderDirection === false) {
                        event.target.innerHTML = `${column.Title}&nbsp;\u25B2`;
                        this.#ColumnTitle = "Clique aqui para ordenar em ordem decrescente";
                    } else {
                        event.target.innerHTML = `${column.Title}&nbsp;\u25BC`;
                        this.#ColumnTitle = "Clique aqui para cancelar ordenação";
                    }
                    this.Renderize();
                };
                tr.appendChild(th);
                //if (column.ReferenceTableId && !this.#ReferenceRecordsets[column.ReferenceTableId])
                //   this.#ReferenceRecordsets[column.ReferenceTableId] = TSystem.GetTable(column.ReferenceTableId).ListTableRows()
            }
        );
        this.#HTML.Head.innerHTML = null;
        tr.title = "Clique no cabeçalho da coluna para ordenar";
        this.#HTML.Head.appendChild(tr);
    }
    #BuildHtmlBody() {
        this.#HTML.Body.innerHTML = null;
        this.#HTML.Body.onwheel = (event) => {
            let key = `${event.ctrlKey ? "Page" : "Arrow"}${event.deltaY > 0 ? "Down" : "Up"
                }`;

            event.preventDefault();
            this.#HTML.SelectedRow.dispatchEvent(
                new KeyboardEvent("keydown", {
                    key, // Nome da tecla (e.g., "ArrowUp", "Enter", "a", etc.)
                    code: key, // Código da tecla
                    bubbles: true, // Permite que o evento se propague na árvore DOM
                    cancelable: true, // Permite que o evento seja cancelado
                })
            );
        };
        this.#Rows.length = 0;
        this.#Data.forEach((row, index) => {
            let tr = document.createElement("tr");

            tr.title = JSON.stringify(row).replace(/,/g, ",\n");
            tr.onclick = (event) => {
                this.#RowNumber = tr.rowIndex - 1;
                if (this.#HTML.SelectedRow)
                    this.#HTML.SelectedRow.classList.remove("currentRow");
                this.#HTML.SelectedRow = event.currentTarget;
                this.#HTML.SelectedRow.scrollIntoView({ behavior: 'auto', block: 'nearest' });
                this.#HTML.SelectedRow.classList.add("currentRow");
            };
            tr.ondblclick = () => {
                if (this.#readOnlyCud)
                    this.#HTML.QueryButton.click();
                else
                    this.#HTML.UpdateButton.click();
            };
            this.#gridColumns().forEach(
                (column) => {
                    const td = document.createElement("td");

                    td.appendChild(this.#GetControl(column, row.getBrowseValue(column)));
                    td.style = `text-align: ${row.getBrowseAlign(column)}`;
                    tr.appendChild(td);
                }
            );
            this.#HTML.Body.appendChild(tr);
            this.#Rows.push(tr);
            if (this.#RowNumber === index) tr.click();
        });
    }
    #BuildHtmlFoot() {
        let tr = document.createElement("tr"),
            th = document.createElement("th"),
            filtered = this.#RecordSet.isFiltered(),
            label;

        th.colSpan = this.#gridColumns().length.toString();
        label = document.createElement("label");
        label.style.float = "left";
        label.innerHTML = "Página:&nbsp;&nbsp;";
        label.hidden = this.#RowCount <= this.#rowsPerPage;

        th.appendChild(label);

        this.#HTML.NumberInput = document.createElement("input");
        this.#HTML.NumberInput.style.float = "left";
        this.#HTML.NumberInput.className = "numberInput";
        this.#HTML.NumberInput.type = "number";
        this.#HTML.NumberInput.value = Math.floor(this.#PageNumber).toString();
        this.#HTML.NumberInput.title = "Ir para página...";
        this.#HTML.NumberInput.hidden = this.#RowCount <= this.#rowsPerPage;
        this.#HTML.NumberInput.min = "1";
        this.#HTML.NumberInput.max = this.#PageCount.toString();
        this.#HTML.NumberInput.onchange = (event) => {
            let value = Number(event.target.value);

            if (value > this.#PageCount) value = this.#PageCount;
            else if (value < 1) value = 1;
            if (this.#IsNavigateByScroll) {
                if (Math.floor(this.#PageNumber) !== Math.floor(this.#LastPageNumber))
                    this.Renderize(this.#PageNumber);
                this.#IsNavigateByScroll = false;
            } else this.Renderize(value);
        };
        th.appendChild(this.#HTML.NumberInput);

        this.#HTML.CreateButton = document.createElement("button");
        this.#HTML.CreateButton.type = "button";
        this.#HTML.CreateButton.style.backgroundImage = TBrowse.#Images.Insert;
        this.#HTML.CreateButton.title = "Incluir registro (alt-i)";
        this.#HTML.CreateButton.hidden = this.#readOnlyCud;
        this.#HTML.CreateButton.onmouseenter = () =>
            (TScreen.Message = "Incluir registro");
        this.#HTML.CreateButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.CreateButton.onclick = () => {
            if (!this.#enabled || this.#readOnlyCud)
                return;
            new TForm(this, TSystem.Actions.CREATE, { masterForm: this.#masterForm }).Configure().then((form) => {
                if (form) form.Renderize();
            });
        };
        th.appendChild(this.#HTML.CreateButton);

        this.#HTML.UpdateButton = document.createElement("button");
        this.#HTML.UpdateButton.type = "button";
        this.#HTML.UpdateButton.style.backgroundImage = TBrowse.#Images.Edit;
        this.#HTML.UpdateButton.title = "Alterar registro (alt-a)";
        this.#HTML.UpdateButton.hidden = this.#readOnlyCud || this.#RowCount === 0;
        this.#HTML.UpdateButton.onmouseenter = () =>
            (TScreen.Message = "Alterar registro");
        this.#HTML.UpdateButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.UpdateButton.onclick = () => {
            if (!this.#enabled || this.#readOnlyCud)
                return;
            new TForm(this, TSystem.Actions.UPDATE, { masterForm: this.#masterForm }).Configure().then((form) => {
                if (form) form.Renderize();
            });
        };
        th.appendChild(this.#HTML.UpdateButton);

        this.#HTML.DeleteButton = document.createElement("button");
        this.#HTML.DeleteButton.type = "button";
        this.#HTML.DeleteButton.style.backgroundImage = TBrowse.#Images.Delete;
        this.#HTML.DeleteButton.title = "Excluir registro (alt-e)";
        this.#HTML.DeleteButton.hidden = this.#readOnlyCud || this.#RowCount === 0;
        this.#HTML.DeleteButton.onmouseenter = () =>
            (TScreen.Message = "Excluir registro");
        this.#HTML.DeleteButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.DeleteButton.onclick = () => {
            if (!this.#enabled || this.#readOnlyCud)
                return;
            new TForm(this, TSystem.Actions.DELETE, { masterForm: this.#masterForm }).Configure().then((form) => {
                if (form) form.Renderize();
            });
        };
        th.appendChild(this.#HTML.DeleteButton);

        this.#HTML.QueryButton = document.createElement("button");
        this.#HTML.QueryButton.type = "button";
        this.#HTML.QueryButton.style.backgroundImage = TBrowse.#Images.Query;
        this.#HTML.QueryButton.title = "Ver registro (alt-v)";
        this.#HTML.QueryButton.hidden = this.#RowCount === 0;
        this.#HTML.QueryButton.onmouseenter = () =>
            (TScreen.Message = "Ver registro");
        this.#HTML.QueryButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.QueryButton.onclick = () => {
            if (!this.#enabled)
                return;
            new TForm(this, TSystem.Actions.QUERY, { masterForm: this.#masterForm }).Configure().then((form) => {
                if (form) form.Renderize();
            });
        };
        th.appendChild(this.#HTML.QueryButton);

        const canFilterOrSearch = this.#RowCount >= 2;

        this.#HTML.SearchButton = document.createElement("button");
        this.#HTML.SearchButton.type = "button";
        this.#HTML.SearchButton.style.backgroundImage = TBrowse.#Images.Search;
        this.#HTML.SearchButton.title = "Pesquisar registro (alt-p)";
        this.#HTML.SearchButton.hidden = !canFilterOrSearch;
        this.#HTML.SearchButton.onmouseenter = () =>
            (TScreen.Message = "Filtrar registros");
        this.#HTML.SearchButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.SearchButton.onclick = async () => {
            const options = this.#masterForm ? { masterForm: this.#masterForm } : {};
            (await new TForm(this, TSystem.Actions.SEARCH, options).Configure()).Renderize();
        };
        th.appendChild(this.#HTML.SearchButton);


        this.#HTML.FilterButton = document.createElement("button");
        this.#HTML.FilterButton.type = "button";
        this.#HTML.FilterButton.style.backgroundImage = TBrowse.#Images.Filter;
        this.#HTML.FilterButton.title = "Filtrar registros (alt-f)";
        this.#HTML.FilterButton.hidden = !canFilterOrSearch;
        this.#HTML.FilterButton.onmouseenter = () =>
            (TScreen.Message = "Filtrar registros");
        this.#HTML.FilterButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.FilterButton.onclick = async () => {
            const options = this.#masterForm ? { masterForm: this.#masterForm } : {};
            (await new TForm(this, TSystem.Actions.FILTER, options).Configure()).Renderize();
        };
        th.appendChild(this.#HTML.FilterButton);

        this.#HTML.UnfilterButton = document.createElement("button");
        this.#HTML.UnfilterButton.type = "button";
        this.#HTML.UnfilterButton.style.backgroundImage = TBrowse.#Images.Unfilter;
        this.#HTML.UnfilterButton.title = `Limpar filtragem de registros (alt-l): ${this.Filter}`;
        this.#HTML.UnfilterButton.hidden = !filtered;
        this.#HTML.UnfilterButton.onmouseenter = () =>
            (TScreen.Message = "Limpar filtragem de registros");
        this.#HTML.UnfilterButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.UnfilterButton.onclick = async () => {
            this.#RecordSet.clearFilters();
            await this.Renderize(1);
        };
        th.appendChild(this.#HTML.UnfilterButton);

        this.#HTML.UnorderButton = document.createElement("button");
        this.#HTML.UnorderButton.type = "button";
        this.#HTML.UnorderButton.style.backgroundImage = TBrowse.#Images.Unorder;
        this.#HTML.UnorderButton.title = `Limpar ordenação de registros (alt-o): ${this.OrderBy}`;
        this.#HTML.UnorderButton.hidden = TConfig.IsEmpty(this.#RecordSet.orderBy);
        this.#HTML.UnorderButton.onmouseenter = () =>
            (TScreen.Message = "Limpar ordenação de registros");
        this.#HTML.UnorderButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.UnorderButton.onclick = () => {
            this.#RecordSet.clearOrderBy();
            this.Renderize();
        };
        th.appendChild(this.#HTML.UnorderButton);

        this.#HTML.ExitButton = document.createElement("button");
        this.#HTML.ExitButton.type = "button";
        this.#HTML.ExitButton.style.backgroundImage = TBrowse.#Images.Exit;
        this.#HTML.ExitButton.title = "Retornar ao menu principal (alt-x)";
        this.#HTML.ExitButton.hidden = this.#embedded;
        this.#HTML.ExitButton.onmouseenter = () =>
            (TScreen.Message = "Retornar ao menu principal");
        this.#HTML.ExitButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.ExitButton.onclick = () =>
            (TSystem.Action = `${TSystem.Actions.EXIT}/${TSystem.Actions.MENU}`);
        th.appendChild(this.#HTML.ExitButton);

        label = document.createElement("label");
        label.style.float = "right";
        label.innerHTML = `Total de Registros: ${this.#Rows.length}/${this.#RowCount
            }`;
        th.appendChild(label);
        tr.appendChild(th);

        this.#HTML.Foot.innerHTML = null;
        this.#HTML.Foot.appendChild(tr);
    }
    get Table() {
        return this.#Table;
    }
    get RecordSet() {
        return this.#RecordSet;
    }
    get SelectedRecord() {
        return this.#Data?.[this.#RowNumber] ?? null;
    }
    get Primarykeys() {
        const record = this.#Data[this.#RowNumber];
        return TSystem.GetPrimaryKeyValues(record, this.#Table) ?? {};
    }
    get OrderBy() {
        return this.#RecordSet.orderBy;
    }
    get Filter() {
        let filter = "";

        for (const [key, value] of this.#RecordSet.Filter) {
            if (this.#RecordSet.isTableFilterKey(key))
                continue;
            const part = TCondition.formatCriterion(key, value);
            if (part)
                filter += `${filter === "" ? "" : " AND "}${part}`;
        }
        return filter;
    }
    get HostElement() {
        return this.#HTML.Container;
    }
    get Container() {
        return this.#HTML.Container;
    }
}
