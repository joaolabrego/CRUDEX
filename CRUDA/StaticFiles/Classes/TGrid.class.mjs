"use strict"

import TActions from "./TActions.class.mjs"
import TForm from "./TForm.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"
import TConfig from "./TConfig.class.mjs"

export default class TGrid {
    #Table = null
    #FilterValues = {}
    #RowCount = 0
    #PageNumber = 1
    #PageCount = 0
    #RowNumber = 0
    #DataPage = null
    #OrderBy = ""

    #HTML = {
        Container: null,
        Head: null,
        Body: null,
        Foot: null,
        NumberInput: null,
        RangeInput: null,
        CreateButton: null,
        UpdateButton: null,
        DeleteButton: null,
        QueryButton: null,
        FilterButton: null,
        ExitButton: null,
        SelectedRow: null,
    }

    static #Style = ""
    static #Images = {
        Insert: "",
        Edit: "",
        Filter: "",
        Delete: "",
        Query: "",
        Exit: "",
    }
    constructor(databaseName, tableName) {
        let database = TSystem.GetDatabase(databaseName)

        if (!database)
            throw new Error("Banco-de-dados não encontrado.")
        this.#Table = database.GetTable(tableName)
        if (!this.#Table)
            throw new Error("Tabela de banco-de-dados não encontrada.")
        this.#HTML.Container = document.createElement("table")
        this.#HTML.Container.className = "grid box"

        let style = document.createElement("style")
        style.innerText = TGrid.#Style
        this.#HTML.Container.appendChild(style)

        this.#HTML.Head = document.createElement("thead")
        this.#HTML.Container.appendChild(this.#HTML.Head)

        this.#HTML.Body = document.createElement("tbody")
        this.#HTML.Container.appendChild(this.#HTML.Body)

        this.#HTML.Foot = document.createElement("tfoot")
        this.#HTML.Container.appendChild(this.#HTML.Foot)

        this.#Table.Columns.filter(column => column.IsFilterable)
            .forEach(column => this.#FilterValues[column.Name] = null)
    }
    static Initialize(styles, images) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")
        if (images.ClassName !== "Images")
            throw new Error("Argumento images não é do tipo Images.")
        this.#Style = styles.Grid
        this.#Images.Delete = images.Delete
        this.#Images.Query = images.Query
        this.#Images.Edit = images.Edit
        this.#Images.Exit = images.Exit
        this.#Images.Filter = images.Filter
        this.#Images.Insert = images.Insert
    }
    SaveFilters(record) {
        for (let key in this.#FilterValues)
            if (record.hasOwnProperty(key))
                this.#FilterValues[key] = TConfig.IsEmpty(record[key]) ? null : record[key]
    }
    async #ReadDataPage(pageNumber) {
        let parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TActions.READ,
            InputParams: {
                LoginId: TLogin.LoginId,
                RecordFilter: JSON.stringify(this.#FilterValues),
                OrderBy: this.OrderBy,
                PaddingGridLastPage: TSystem.PaddingGridLastPage,
            },
            OutputParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
            },
        }

        let result = await TConfig.GetAPI(TActions.EXECUTE, parameters)

        this.#RowCount = result.Parameters.ReturnValue
        this.#PageNumber = result.Parameters.PageNumber
        this.#PageCount = result.Parameters.MaxPage
        if (result.Parameters.ReturnValue && this.#RowNumber >= result.Parameters.ReturnValue)
            this.#RowNumber = tr.rowIndex - 1

        return result.DataSet.Table
    }
    async Renderize(pageNumber = this.#PageNumber) {
        TScreen.Title = `Manutenção de ${this.#Table.Description}`
        this.#ReadDataPage(pageNumber)
            .then((dataPage) => {
                this.#DataPage = dataPage
                if (this.#RowCount > 1)
                    TScreen.LastMessage = TScreen.Message = "Clique na linha que deseja selecionar."
                else
                    TScreen.LastMessage = TScreen.Message = "Clique em um dos botões."
                this.#BuildHtmlHead()
                this.#BuildHtmlBody(dataPage)
                this.#BuildHtmlFoot()
                TScreen.WithBackgroundImage = true
                TScreen.Main = this.#HTML.Container
            })
            .catch(error => {
                TScreen.ShowError(error.Message, error.Action || `grid/${this.#Table.Database.Name}/${this.#Table.Name}`)
            })
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
            htmlInputType = column.Domain.Type.Category.HtmlInputType

        if (htmlInputType === "checkbox") {
            control = document.createElement("input")
            if (TConfig.IsEmpty(value))
                control.hidden = "hidden"
            else {
                control.type = htmlInputType
                control.checked = value
                control.title = value ? "sim" : "não"
                control.readOnly = true
                control.onclick = () => false
            }
        }
        else {
            control = document.createTextNode(value ?? "")
        }

        return control
    }
    #BuildHtmlHead() {
        let tr = document.createElement("tr")

        this.#Table.Columns.filter(column => column.IsGridable)
            .forEach(column => {
                let th = document.createElement("th"),
                    columnNameAsc = "[" + column.Name + "] ASC,",
                    columnNameDesc = "[" + column.Name + "] DESC,"

                th.Name = column.Name
                th.Value = this.#OrderBy.includes(columnNameAsc) ? false : this.#OrderBy.includes(columnNameDesc) ? true : null
                th.innerHTML = column.Title + (th.Value === null ? "" : th.Value ? "&nbsp;\u25BC" : "&nbsp;\u25B2")
                th.onclick = (event) => {
                    let column = this.#Table.GetColumn(th.Name),
                        columnNameAsc = "[" + event.target.Name + "] ASC,",
                        columnNameDesc = "[" + event.target.Name + "] DESC,"

                    if (TConfig.IsEmpty(event.target.Value)) {
                        this.#OrderBy += columnNameAsc
                        event.target.Value = false
                        event.target.innerHTML = `${column.Title}&nbsp;\u25B2` 
                    }
                    else if (event.target.Value === false) {
                        this.#OrderBy = this.#OrderBy.replace(columnNameAsc, columnNameDesc)
                        event.target.Value = true
                        event.target.innerHTML = `${column.Title}&nbsp;\u25BC`
                    }
                    else {
                        this.#OrderBy = this.#OrderBy.replace(columnNameDesc, "")
                        event.target.Value = null
                        event.target.innerHTML = column.Title
                    }
                    this.Renderize()
                }
                tr.appendChild(th)
                //if (column.ReferenceTableId && !this.#ReferenceRecordsets[column.ReferenceTableId])
                //   this.#ReferenceRecordsets[column.ReferenceTableId] = TSystem.GetTable(column.ReferenceTableId).ListTableRows()
            })
        this.#HTML.Head.innerHTML = null
        tr.title = this.#OrderBy === "" ? "" : `Ordenação: ${this.OrderBy}`
        this.#HTML.Head.appendChild(tr)
    }
    #BuildHtmlBody(dataPage) {
        this.#HTML.Body.innerHTML = null
        dataPage.forEach((row, index) => {
            let tr = document.createElement("tr")

            tr.title = JSON.stringify(row).replace(/,/g, ",\n")
            tr.onclick = (event) => {
                this.#RowNumber = tr.rowIndex - 1
                if (this.#HTML.SelectedRow)
                    this.#HTML.SelectedRow.removeAttribute("style")
                this.#HTML.SelectedRow = event.currentTarget
                this.#HTML.SelectedRow.style = "background-color: var(--background-color-control);"
            }
            tr.ondblclick = () => this.#HTML.QueryButton.click()
            this.#Table.Columns.filter(column => column.IsGridable)
                .forEach(column => {
                    const td = document.createElement("td")

                    td.appendChild(this.#GetControl(column, row[column.Name]))
                    td.style = `text-align: ${column.Domain.Type.Category.HtmlInputAlign}`
                    tr.appendChild(td)
            })
            this.#HTML.Body.appendChild(tr)
            if (this.#RowNumber === index)
                tr.click()
        })
    }
    #OnChangeInput = (event) => {
        let value = Number(event.target.value)

        if (value > this.#PageCount)
            event.target.value = this.#PageCount.toString()
        else if (value < 1)
            event.target.value = "1"
        (event.target.className === "numberInput" ? this.#HTML.RangeInput : this.#HTML.NumberInput).value = event.target.value
        this.Renderize(value)
    }
    #BuildHtmlFoot() {
        let tr = document.createElement("tr"),
            th = document.createElement("th"),
            label

        th.colSpan = this.#Table.Columns.length.toString()
        if (this.#RowCount > TSystem.RowsPerPage) {
            label = document.createElement("p")
            label.style.float = "left"
            label.innerHTML = "Página:&nbsp;&nbsp;"

            th.appendChild(label)

            this.#HTML.NumberInput = document.createElement("input")
            this.#HTML.NumberInput.style.float = "left"
            this.#HTML.NumberInput.className = "numberInput"
            this.#HTML.NumberInput.type = "number"
            this.#HTML.NumberInput.value = this.#PageNumber.toString()
            this.#HTML.NumberInput.title = "Ir para página..."
            this.#HTML.NumberInput.min = "1"
            this.#HTML.NumberInput.max = this.#PageCount.toString()
            this.#HTML.NumberInput.onchange = this.#OnChangeInput

            th.appendChild(this.#HTML.NumberInput)

            label = document.createElement("label")
            label.style.float = "left"
            label.innerHTML = "&nbsp;&nbsp;"

            th.appendChild(label)

            this.#HTML.RangeInput = document.createElement("input")
            this.#HTML.RangeInput.style.float = "left"
            this.#HTML.RangeInput.className = "rangeInput"
            this.#HTML.RangeInput.type = "range"
            this.#HTML.RangeInput.tabindex = "-1"
            this.#HTML.RangeInput.value = this.#PageNumber.toString()
            this.#HTML.RangeInput.title = "Ir para página..."
            this.#HTML.RangeInput.min = "1"
            this.#HTML.RangeInput.max = this.#PageCount.toString()
            this.#HTML.RangeInput.onchange = this.#OnChangeInput

            th.appendChild(this.#HTML.RangeInput)
        }

        this.#HTML.CreateButton = document.createElement("button")
        this.#HTML.CreateButton.type = "button"
        this.#HTML.CreateButton.style.backgroundImage = TGrid.#Images.Insert
        this.#HTML.CreateButton.title = "Incluir registro"
        this.#HTML.CreateButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.CreateButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.CreateButton.onclick = () => {
            new TForm(this, TActions.CREATE).Configure()
                .then(form => {
                    if (form)
                        form.Renderize()
                })
        }
        th.appendChild(this.#HTML.CreateButton)

        this.#HTML.UpdateButton = document.createElement("button")
        this.#HTML.UpdateButton.type = "button"
        this.#HTML.UpdateButton.style.backgroundImage = TGrid.#Images.Edit
        this.#HTML.UpdateButton.title = "Alterar registro"
        this.#HTML.UpdateButton.hidden = this.#RowCount === 0
        this.#HTML.UpdateButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.UpdateButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.UpdateButton.onclick = () =>
            new TForm(this, TActions.UPDATE).Configure()
                .then(form => {
                    if (form)
                        form.Renderize()
                })
        th.appendChild(this.#HTML.UpdateButton)

        this.#HTML.DeleteButton = document.createElement("button")
        this.#HTML.DeleteButton.type = "button"
        this.#HTML.DeleteButton.style.backgroundImage = TGrid.#Images.Delete
        this.#HTML.DeleteButton.title = "Excluir registro"
        this.#HTML.DeleteButton.hidden = this.#RowCount === 0
        this.#HTML.DeleteButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.DeleteButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.DeleteButton.onclick = () =>
            new TForm(this, TActions.DELETE).Configure()
                .then(form => {
                    if (form)
                        form.Renderize()
                })
        th.appendChild(this.#HTML.DeleteButton)

        this.#HTML.QueryButton = document.createElement("button")
        this.#HTML.QueryButton.type = "button"
        this.#HTML.QueryButton.style.backgroundImage = TGrid.#Images.Query
        this.#HTML.QueryButton.title = "Consultar registro"
        this.#HTML.QueryButton.hidden = this.#RowCount === 0
        this.#HTML.QueryButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.QueryButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.QueryButton.onclick = () =>
            new TForm(this, TActions.QUERY).Configure()
                .then(form => {
                    if (form)
                        form.Renderize()
                })
        th.appendChild(this.#HTML.QueryButton)

        this.#HTML.FilterButton = document.createElement("button")
        this.#HTML.FilterButton.type = "button"
        this.#HTML.FilterButton.style.backgroundImage = TGrid.#Images.Filter
        this.#HTML.FilterButton.title = "Filtragem de registros"
        this.#HTML.FilterButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.FilterButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.FilterButton.onclick = () => {
            new TForm(this, TActions.FILTER).Configure()
                .then(form => {
                    if (form)
                        form.Renderize()
                })
        }
        th.appendChild(this.#HTML.FilterButton)

        this.#HTML.ExitButton = document.createElement("button")
        this.#HTML.ExitButton.type = "button"
        this.#HTML.ExitButton.style.backgroundImage = TGrid.#Images.Exit
        this.#HTML.ExitButton.title = "Retornar para menu principal"
        this.#HTML.ExitButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.ExitButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.ExitButton.onclick = () => TSystem.Action = `${TActions.EXIT}/${TActions.MENU}`
        th.appendChild(this.#HTML.ExitButton)

        label = document.createElement("label")
        label.style.float = "right"
        label.innerHTML = `Total de Registros: ${this.#RowCount}`
        th.appendChild(label)
        tr.appendChild(th)

        this.#HTML.Foot.innerHTML = null
        this.#HTML.Foot.appendChild(tr)
    }
    get Table() {
        return this.#Table
    }
    get FilterValues() {
        return this.#FilterValues
    }
    /**
     * @param {number} rowNumber
     */
    get Primarykeys() {
        let primarykeys = {}

        this.#Table.Columns.filter(column => column.IsPrimarykey)
            .forEach(column => primarykeys[column.Name] = this.#DataPage[this.#RowNumber][column.Name])

        return primarykeys
    }
    get OrderBy() {
        return this.#OrderBy.slice(0, -1)
    }
}