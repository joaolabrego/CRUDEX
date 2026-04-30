"use strict";

import TForm from "./TForm.class.mjs";
import TLogin from "./TLogin.class.mjs";
import TScreen from "./TScreen.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TConfig from "./TConfig.class.mjs";

export default class TGrid {
    #FilterValues = {};
    #SearchValues = {};
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
    #References = [];
    #Table = null;

    #OrderBy = "";

    #HTML = {
        Container: null,
        Range: null,
        Table: null,
        Head: null,
        Body: null,
        Foot: null,
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
    constructor(databaseName, tableName) {
        let database = TSystem.GetDatabase(databaseName);

        if (!database) throw new Error("Banco-de-dados não encontrado.");
        this.#Table = database.GetTable(tableName);
        if (!this.#Table)
            throw new Error("Tabela de banco-de-dados não encontrada.");
        this.#HTML.Container = document.createElement("div");
        this.#HTML.Container.className = "container";
        this.#CreateGrid();
        this.#CreateRange();
        this.#HTML.Container.appendChild(this.#HTML.Range);
        this.#Table.Columns.filter((column) => column.IsFilterable).forEach(
            column => this.#FilterValues[column.Name] = this.#SearchValues = null);
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

        style.textContent = TGrid.#Style;
        this.#HTML.Table.appendChild(style);

        this.#HTML.Head = document.createElement("thead");
        this.#HTML.Table.appendChild(this.#HTML.Head);

        this.#HTML.Body = document.createElement("tbody");
        this.#HTML.Table.appendChild(this.#HTML.Body);

        this.#HTML.Foot = document.createElement("tfoot");
        this.#HTML.Table.appendChild(this.#HTML.Foot);

        this.#HTML.Container.appendChild(this.#HTML.Table);
    };

    #CreateRange() {
        this.#HTML.Range = document.createElement("input");
        this.#HTML.Range.type = "range";
        this.#HTML.Range.className = "vertical-range";
        this.#HTML.Range.min = 1;
        this.#HTML.Range.max = this.#PageCount;
        this.#HTML.Range.oninput = () => {
            if (this.#HTML.Range.value != this.#PageNumber)
                this.Renderize(Math.trunc(this.#HTML.Range.value));
        }
    }
    SaveFilters(record) {
        for (let key in this.#FilterValues)
            if (record.hasOwnProperty(key))
                this.#FilterValues[key] = TConfig.IsEmpty(record[key])
                    ? null
                    : record[key];
    }
    ClearFilters() {
        for (let key in this.#FilterValues) this.#FilterValues[key] = null;
    }
    IsFiltered() {
        for (let key in this.#FilterValues)
            if (this.#FilterValues[key] != null) return true;

        return false;
    }
    SaveSearchs(record) {
        for (let key in this.#SearchValues)
            if (record.hasOwnProperty(key))
                this.#SearchValues[key] = TConfig.IsEmpty(record[key])
                    ? null
                    : record[key];
    }
    ClearSearches() {
        for (let key in this.#SearchValues) this.#SearchValues[key] = null;
    }
    IsSearched() {
        for (let key in this.#SearchValues)
            if (this.#SearchValues[key] != null) return true;

        return false;
    }
    async #ReadDataPage(pageNumber) {
        let parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TSystem.Actions.READ,
            InParams: {
                LoginId: TLogin.LoginId,
                RecordFilter: JSON.stringify(this.#FilterValues),
                //RecordSearch: this.IsSearched() ? JSON.stringify(this.#SearchValues) : null,
                OrderBy: this.OrderBy,
                PaddingGridLastPage: TSystem.PaddingGridLastPage,
                IsActionList: false,
            },
            OutParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
            },
        };

        let result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, parameters);

        this.#RowCount = result.Parameters.ReturnValue;
        this.#HTML.Range.min = 1;
        this.#HTML.Range.value = this.#PageNumber = result.Parameters.PageNumber;
        this.#HTML.Range.max = this.#PageCount = result.Parameters.MaxPage;
        if (result.Parameters.ReturnValue && this.#RowNumber >= result.Parameters.ReturnValue)
            this.#RowNumber = result.Parameters.ReturnValue - 1;
        this.#References.length = 0;
        Object.entries(result.DataSet).forEach(([, table], index) => {
            if (index) {
                table.forEach((rowTable) => {
                    if (
                        !this.#References.find(
                            (row) =>
                                row.ClassName === rowTable.ClassName && row.Id === rowTable.Id
                        )
                    ) {
                        this.#References.push(rowTable);
                    }
                });
            }
        });

        return result.DataSet.Table;
    }
    async Renderize(pageNumber = this.#PageNumber) {
        if (this.#IsRendering) return;
        this.#IsRendering = true;
        try {
            this.#Data = await this.#ReadDataPage(pageNumber);
            this.#PageNumber = pageNumber;
            if (this.#RowCount > 1)
                TScreen.LastMessage = TScreen.Message =
                    "Clique na linha que deseja selecionar.";
            else
                TScreen.LastMessage = TScreen.Message = "Clique em um dos botões.";
            TScreen.Title = `Manutenção de ${this.#Table.Description}`;
            this.#BuildHtmlHead();
            this.#BuildHtmlBody();
            this.#BuildHtmlFoot();
            TScreen.WithBackgroundImage = true;
            TScreen.Main = this.#HTML.Container;
            this.#HTML.Table.focus();
            if (this.#RowCount <= TSystem.RowsPerPage)
                this.#HTML.Range.classList.add("invisible");
            else
                this.#HTML.Range.classList.remove("invisible");
            this.#HTML.Range.title = `Página atual: ${pageNumber}`;
        } catch (error) {
            TScreen.ShowError(
                error.message || error.Message,
                error.Action || `grid/${this.#Table.Database.Name}/${this.#Table.Name}`
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
        let control,
            htmlInputType = column.Domain.Type.Category.HtmlInputType;

        if (htmlInputType === "checkbox") {
            control = document.createElement("input");
            if (TConfig.IsEmpty(value))
                control.hidden = "hidden";
            else {
                control.type = htmlInputType;
                control.checked = value;
                control.title = value ? "sim" : "não";
                control.readOnly = true;
                control.onclick = () => false;
            }
        } else {
            control = document.createTextNode(value ?? "");
        }

        return control;
    }
    #BuildHtmlHead() {
        let tr = document.createElement("tr");

        this.#Table.Columns.filter((column) => column.IsGridable).forEach(
            (column) => {
                let th = document.createElement("th"),
                    columnNameAsc = "[" + column.Name + "] ASC,",
                    columnNameDesc = "[" + column.Name + "] DESC,";

                th.Name = column.Name;
                th.IsOrdered = this.#OrderBy.includes(columnNameAsc)
                    ? false
                    : this.#OrderBy.includes(columnNameDesc)
                        ? true
                        : null;
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
                    if (TConfig.IsEmpty(event.target.IsOrdered)) {
                        this.#OrderBy += columnNameAsc;
                        event.target.IsOrdered = false;
                        event.target.innerHTML = `${column.Title}&nbsp;\u25B2`;
                        this.#ColumnTitle = "Clique aqui para ordenar em ordem decrescente";
                    } else if (event.target.IsOrdered === false) {
                        this.#OrderBy = this.#OrderBy.replace(
                            columnNameAsc,
                            columnNameDesc
                        );
                        event.target.IsOrdered = true;
                        event.target.innerHTML = `${column.Title}&nbsp;\u25BC`;
                        this.#ColumnTitle = "Clique aqui para cancelar ordenação";
                    } else {
                        this.#OrderBy = this.#OrderBy.replace(columnNameDesc, "");
                        event.target.IsOrdered = null;
                        event.target.innerHTML = column.Title;
                        this.#ColumnTitle = null;
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
                    this.#HTML.SelectedRow.removeAttribute("style");
                this.#HTML.SelectedRow = event.currentTarget;
                this.#HTML.SelectedRow.scrollIntoView({ behavior: 'auto', block: 'nearest' });
                this.#HTML.SelectedRow.style =
                    "background-color: var(--background-color-control);";
            };
            tr.ondblclick = () => this.#HTML.UpdateButton.click();
            this.#Table.Columns.filter((column) => column.IsGridable).forEach(
                (column) => {
                    const td = document.createElement("td");

                    td.appendChild(this.#GetControl(column, row[column.Name]));
                    td.style = `text-align: ${column.Domain.Type.Category.HtmlInputAlign}`;
                    tr.appendChild(td);
                }
            );
            this.#HTML.Body.appendChild(tr);
            this, this.#Rows.push(tr);
            if (this.#RowNumber === index) tr.click();
        });
    }
    #BuildHtmlFoot() {
        let tr = document.createElement("tr"),
            th = document.createElement("th"),
            filtered = this.IsFiltered(),
            label;

        th.colSpan = this.#Table.Columns.length.toString();
        label = document.createElement("label");
        label.style.float = "left";
        label.innerHTML = "Página:&nbsp;&nbsp;";
        label.hidden = this.#RowCount <= TSystem.RowsPerPage;

        th.appendChild(label);

        this.#HTML.NumberInput = document.createElement("input");
        this.#HTML.NumberInput.style.float = "left";
        this.#HTML.NumberInput.className = "numberInput";
        this.#HTML.NumberInput.type = "number";
        this.#HTML.NumberInput.value = Math.floor(this.#PageNumber).toString();
        this.#HTML.NumberInput.title = "Ir para página...";
        this.#HTML.NumberInput.hidden = this.#RowCount <= TSystem.RowsPerPage;
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
        this.#HTML.CreateButton.style.backgroundImage = TGrid.#Images.Insert;
        this.#HTML.CreateButton.title = "Incluir registro (alt-i)";
        this.#HTML.CreateButton.hidden = false;
        this.#HTML.CreateButton.onmouseenter = () =>
            (TScreen.Message = "Incluir registro");
        this.#HTML.CreateButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.CreateButton.onclick = () => {
            new TForm(this, TSystem.Actions.CREATE).Configure().then((form) => {
                if (form) form.Renderize();
            });
        };
        th.appendChild(this.#HTML.CreateButton);

        this.#HTML.UpdateButton = document.createElement("button");
        this.#HTML.UpdateButton.type = "button";
        this.#HTML.UpdateButton.style.backgroundImage = TGrid.#Images.Edit;
        this.#HTML.UpdateButton.title = "Alterar registro (alt-a)";
        this.#HTML.UpdateButton.hidden = this.#RowCount === 0;
        this.#HTML.UpdateButton.onmouseenter = () =>
            (TScreen.Message = "Alterar registro");
        this.#HTML.UpdateButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.UpdateButton.onclick = () =>
            new TForm(this, TSystem.Actions.UPDATE).Configure().then((form) => {
                if (form) form.Renderize();
            });
        th.appendChild(this.#HTML.UpdateButton);

        this.#HTML.DeleteButton = document.createElement("button");
        this.#HTML.DeleteButton.type = "button";
        this.#HTML.DeleteButton.style.backgroundImage = TGrid.#Images.Delete;
        this.#HTML.DeleteButton.title = "Excluir registro (alt-e)";
        this.#HTML.DeleteButton.hidden = this.#RowCount === 0;
        this.#HTML.DeleteButton.onmouseenter = () =>
            (TScreen.Message = "Excluir registro");
        this.#HTML.DeleteButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.DeleteButton.onclick = () =>
            new TForm(this, TSystem.Actions.DELETE).Configure().then((form) => {
                if (form) form.Renderize();
            });
        th.appendChild(this.#HTML.DeleteButton);

        this.#HTML.QueryButton = document.createElement("button");
        this.#HTML.QueryButton.type = "button";
        this.#HTML.QueryButton.style.backgroundImage = TGrid.#Images.Query;
        this.#HTML.QueryButton.title = "Ver registro (alt-v)";
        this.#HTML.QueryButton.hidden = this.#RowCount === 0;
        this.#HTML.QueryButton.onmouseenter = () =>
            (TScreen.Message = "Ver registro");
        this.#HTML.QueryButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.QueryButton.onclick = () =>
            new TForm(this, TSystem.Actions.QUERY).Configure().then((form) => {
                if (form) form.Renderize();
            });
        th.appendChild(this.#HTML.QueryButton);

        this.#HTML.SearchButton = document.createElement("button");
        this.#HTML.SearchButton.type = "button";
        this.#HTML.SearchButton.style.backgroundImage = TGrid.#Images.Search;
        this.#HTML.SearchButton.title = "Pesquisar registro (alt-p)";
        this.#HTML.SearchButton.hidden =
            !filtered && this.#RowCount <= TSystem.RowsPerPage;
        this.#HTML.SearchButton.onmouseenter = () =>
            (TScreen.Message = "Filtrar registros");
        this.#HTML.SearchButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.SearchButton.onclick = async () => {
            (await new TForm(this, TSystem.Actions.SEARCH).Configure()).Renderize();
        };
        th.appendChild(this.#HTML.SearchButton);


        this.#HTML.FilterButton = document.createElement("button");
        this.#HTML.FilterButton.type = "button";
        this.#HTML.FilterButton.style.backgroundImage = TGrid.#Images.Filter;
        this.#HTML.FilterButton.title = "Filtrar registros (alt-f)";
        this.#HTML.FilterButton.hidden =
            !filtered && this.#RowCount <= TSystem.RowsPerPage;
        this.#HTML.FilterButton.onmouseenter = () =>
            (TScreen.Message = "Filtrar registros");
        this.#HTML.FilterButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.FilterButton.onclick = async () => {
            (await new TForm(this, TSystem.Actions.FILTER).Configure()).Renderize();
        };
        th.appendChild(this.#HTML.FilterButton);

        this.#HTML.UnfilterButton = document.createElement("button");
        this.#HTML.UnfilterButton.type = "button";
        this.#HTML.UnfilterButton.style.backgroundImage = TGrid.#Images.Unfilter;
        this.#HTML.UnfilterButton.title = `Limpar filtragem de registros (alt-l): ${this.Filter}`;
        this.#HTML.UnfilterButton.hidden = !filtered;
        this.#HTML.UnfilterButton.onmouseenter = () =>
            (TScreen.Message = "Limpar filtragem de registros");
        this.#HTML.UnfilterButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.UnfilterButton.onclick = () => {
            this.ClearFilters();
            this.Renderize();
        };
        th.appendChild(this.#HTML.UnfilterButton);

        this.#HTML.UnorderButton = document.createElement("button");
        this.#HTML.UnorderButton.type = "button";
        this.#HTML.UnorderButton.style.backgroundImage = TGrid.#Images.Unorder;
        this.#HTML.UnorderButton.title = `Limpar ordenação de registros (alt-o): ${this.OrderBy}`;
        this.#HTML.UnorderButton.hidden = TConfig.IsEmpty(this.#OrderBy);
        this.#HTML.UnorderButton.onmouseenter = () =>
            (TScreen.Message = "Limpar ordenação de registros");
        this.#HTML.UnorderButton.onmouseleave = () =>
            (TScreen.Message = TScreen.LastMessage);
        this.#HTML.UnorderButton.onclick = () => {
            this.#OrderBy = "";
            this.Renderize();
        };
        th.appendChild(this.#HTML.UnorderButton);

        this.#HTML.ExitButton = document.createElement("button");
        this.#HTML.ExitButton.type = "button";
        this.#HTML.ExitButton.style.backgroundImage = TGrid.#Images.Exit;
        this.#HTML.ExitButton.title = "Retornar ao menu principal (alt-x)";
        this.#HTML.ExitButton.hidden = false;
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
    get FilterValues() {
        return this.#FilterValues;
    }
    get Primarykeys() {
        return { Id: this.#Data[this.#RowNumber]["Id"] };
    }
    get OrderBy() {
        return this.#OrderBy.slice(0, -1);
    }
    get Filter() {
        var filter = "";

        for (let key in this.#FilterValues) {
            let value = this.#FilterValues[key];

            if (value !== null)
                filter += `${filter === "" ? "" : " AND "}${key} = '${value}'`;
        }
        return filter;
    }
    get Container() {
        return this.#HTML.Table;
    }
}
