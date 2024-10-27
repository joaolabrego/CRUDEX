"use strict"

import TActions from "./TActions.class.mjs"
import TForm from "./TForm.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"
import TConfig from "./TConfig.class.mjs"

export default class TGrid {
    #FilterValues = {}
    #RowCount = 0
    #PageNumber = 1
    #PageCount = 0
    #RowNumber = 0
    #IsRendering = false
    #Rows = []
    #Data = null
    #Table = null
    #Recordset = null

    #OrderBy = ""

    #HTML = {
        Container: null,
        Table: null,
        Head: null,
        Body: null,
        Foot: null,
        NumberInput: null,
        CreateButton: null,
        UpdateButton: null,
        DeleteButton: null,
        QueryButton: null,
        FilterButton: null,
        UnorderButton: null,
        UnfilterButton: null,
        ExitButton: null,
        SelectedRow: null,
        Scroll: {
            Container: null,
            Track: null,
            Thumb: null,
        },
    }

    static #Style = ""
    static #Images = {
        Insert: "",
        Edit: "",
        Filter: "",
        Unfilter: "",
        Unorder: "",
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
        this.#HTML.Container = document.createElement("div")
        this.#HTML.Container.className = "container"
        this.#HTML.GridWrapper = document.createElement("div")
        this.#HTML.GridWrapper.className = "grid-wrapper"
        this.#CreateGrid(this.#HTML.GridWrapper)
        this.#CreateScrollBar()
        this.#HTML.Container.appendChild(this.#HTML.GridWrapper)
        this.#HTML.Container.appendChild(this.#HTML.Scroll.Container)
    }
    static Initialize(styles, images) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não são do tipo Styles.")
        if (images.ClassName !== "Images")
            throw new Error("Argumento images não são do tipo Images.")
        this.#Style = styles.Grid
        this.#Images.Delete = images.Delete
        this.#Images.Query = images.Query
        this.#Images.Edit = images.Edit
        this.#Images.Exit = images.Exit
        this.#Images.Filter = images.Filter
        this.#Images.Unfilter = images.Unfilter
        this.#Images.Unorder = images.Unorder
        this.#Images.Insert = images.Insert
    }
    #UpdateScrollThumbFromInputs() {
        if (this.#PageCount <= 1) {
            this.#HTML.Scroll.Thumb.style.top = "0px"
            return
        }
        let trackHeight = this.#HTML.Scroll.Track.clientHeight,
            maxTop = trackHeight - this.#HTML.Scroll.Thumb.clientHeight,
            scrollPosition = ((this.#PageNumber - 1) / (this.#PageCount - 1)) * maxTop

        this.#HTML.Scroll.Thumb.style.top = `${scrollPosition}px`
    }

    #CreateGrid(wrapper) {
        this.#HTML.Table = document.createElement("table")
        this.#HTML.Table.setAttribute('tabindex', '0')
        this.#HTML.Table.className = "grid box"
        this.#HTML.Table.onkeydown = event => {
            if (event.ctrlKey) {
                switch (event.key) {
                    case "i":
                        event.preventDefault()
                        if (!this.#HTML.CreateButton.hidden)
                            this.#HTML.CreateButton.click()
                        break
                    case "a":
                        event.preventDefault()
                        if (!this.#HTML.UpdateButton.hidden)
                            this.#HTML.UpdateButton.click()
                        break
                    case "e":
                        event.preventDefault()
                        if (!this.#HTML.DeleteButton.hidden)
                            this.#HTML.DeleteButton.click()
                        break
                    case "v":
                        event.preventDefault()
                        if (!this.#HTML.QueryButton.hidden)
                            this.#HTML.QueryButton.click()
                        break
                    case "f":
                        event.preventDefault()
                        if (!this.#HTML.FilterButton.hidden)
                            this.#HTML.FilterButton.click()
                        break
                    case "l":
                        event.preventDefault()
                        if (!this.#HTML.UnfilterButton.hidden)
                            this.#HTML.UnfilterButton.click()
                        break
                    case "o":
                        event.preventDefault()
                        if (!this.#HTML.UnorderButton.hidden)
                            this.#HTML.UnorderButton.click()
                        break
                    case "r":
                        event.preventDefault()
                        if (!this.#HTML.ExitButton.hidden)
                            this.#HTML.ExitButton.click()
                        break
                }
            }
            else {
                switch (event.key) {
                    case "ArrowUp":
                        if (this.#HTML.SelectedRow.rowIndex > 1)
                            this.#Rows[this.#HTML.SelectedRow.rowIndex - 2].click()
                        else if (this.#PageNumber === 1) {
                            this.Renderize(this.#PageCount)
                            this.#Rows[this.#Rows.length - 1].click()
                        }
                        else {
                            this.Renderize(this.#PageNumber - 1)
                            this.#Rows[this.#Rows.length - 1].click()
                        }
                        break
                    case "ArrowDown":
                        if (this.#HTML.SelectedRow.rowIndex < this.#Rows.length)
                            this.#Rows[this.#HTML.SelectedRow.rowIndex].click()
                        else if (this.#PageNumber === this.#PageCount) {
                            this.Renderize(1)
                            this.#Rows[0].click()
                        }
                        else {
                            this.Renderize(this.#PageNumber + 1)
                            this.#Rows[0].click()
                        }
                        break
                    case "PageUp":
                        if (this.#PageNumber > 1)
                            this.Renderize(this.#PageNumber - 1)
                        else
                            this.Renderize(this.#PageCount)
                        break
                    case "PageDown":
                        if (this.#PageNumber < this.#PageCount)
                            this.Renderize(this.#PageNumber + 1)
                        else
                            this.Renderize(1)
                        break
                    case "Enter":
                        this.#HTML.UpdateButton.click()
                        break
                }
            }
        }

        let style = document.createElement("style")
        style.innerText = TGrid.#Style
        this.#HTML.Table.appendChild(style)

        this.#HTML.Head = document.createElement("thead")
        this.#HTML.Table.appendChild(this.#HTML.Head)

        this.#HTML.Body = document.createElement("tbody")
        this.#HTML.Table.appendChild(this.#HTML.Body)

        this.#HTML.Foot = document.createElement("tfoot")
        this.#HTML.Table.appendChild(this.#HTML.Foot)

        wrapper.appendChild(this.#HTML.Table) // Adiciona o grid à div wrapper
    }
    #CreateScrollBar() {
        this.#HTML.Scroll.Container = document.createElement("div")
        this.#HTML.Scroll.Container.className = "scroll-container"

        this.#HTML.Scroll.Track = document.createElement("div")
        this.#HTML.Scroll.Track.className = "scroll-track"
        this.#HTML.Scroll.Container.appendChild(this.#HTML.Scroll.Track)

        this.#HTML.Scroll.Thumb = document.createElement("div")
        this.#HTML.Scroll.Thumb.className = "scroll-thumb"
        this.#HTML.Scroll.Track.appendChild(this.#HTML.Scroll.Thumb)
        this.#HTML.Scroll.Track.onmousemove = (event) => {
            if (event.buttons === 1) {
                let trackRect = this.#HTML.Scroll.Track.getBoundingClientRect();
                let newTop = event.clientY - trackRect.top;
                this.#UpdateScrollbarPosition(newTop);
            }
        }
        this.#HTML.Scroll.Track.onclick = (event) => {
            const trackRect = this.#HTML.Scroll.Track.getBoundingClientRect()
            const clickPosition = event.clientY - trackRect.top
            this.#UpdateScrollbarPosition(clickPosition - this.#HTML.Scroll.Thumb.offsetHeight / 2)
        }
    }
    #SyncHeightWithContainer() {
        let containerHeight = this.#HTML.Container.clientHeight,
            thumbHeight = Math.max((this.#Rows.length / this.#RowCount) * containerHeight, 5) // Mínimo de 5vmin

        this.#HTML.Scroll.Thumb.style.height = `${thumbHeight}vmin`
    }
    #UpdateScrollbarPosition(newTop) {
        let trackHeight = this.#HTML.Scroll.Track.clientHeight,
            thumbHeight = this.#HTML.Scroll.Thumb.clientHeight,
            maxTop = trackHeight - thumbHeight

        // Garantir que o `newTop` está dentro dos limites do track
        newTop = Math.max(0, Math.min(newTop, maxTop))
        this.#HTML.Scroll.Thumb.style.top = `${newTop}px`

        // Calcula a página baseada na posição do scroll-thumb
        const scrollPercentage = newTop / maxTop
        this.#PageNumber = Math.round(scrollPercentage * (this.#PageCount - 1)) + 1
        this.#HTML.NumberInput.value = this.#PageNumber
        this.#HTML.NumberInput.dispatchEvent(new Event("change"))
    }
    SaveFilters(record) {
        for (let key in this.#FilterValues)
            if (record.hasOwnProperty(key))
                this.#FilterValues[key] = TConfig.IsEmpty(record[key]) ? null : record[key]
    }
    ClearFilters() {
        for (let key in this.#FilterValues)
            this.#FilterValues[key] = null
    }
    IsFiltered() {
        for (let key in this.#FilterValues)
            if (this.#FilterValues[key] != null)
                return true

        return false
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
        if (this.#IsRendering)
            return
        this.#IsRendering = true
        try {
            this.#Data = await this.#ReadDataPage(pageNumber)
            this.#PageNumber = pageNumber
            this.#HTML.Scroll.Thumb.title = `Página ${pageNumber}`
            if (this.#RowCount > 1)
                TScreen.LastMessage = TScreen.Message = "Clique na linha que deseja selecionar."
            else
                TScreen.LastMessage = TScreen.Message = "Clique em um dos botões."
            TScreen.Title = `Manutenção de ${this.#Table.Description}`
            this.#BuildHtmlHead()
            this.#BuildHtmlBody(this.#Data)
            this.#BuildHtmlFoot()
            this.#SyncHeightWithContainer()
            TScreen.WithBackgroundImage = true
            TScreen.Main = this.#HTML.Container
            this.#HTML.Table.focus()
            this.#UpdateScrollThumbFromInputs()
        }
        catch (error) {
            TScreen.ShowError(error.Message, error.Action || `grid/${this.#Table.Database.Name}/${this.#Table.Name}`)
        }
        finally{
            this.#IsRendering = false
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
                th.IsOrdered = this.#OrderBy.includes(columnNameAsc) ? false : this.#OrderBy.includes(columnNameDesc) ? true : null
                th.innerHTML = column.Title + (th.IsOrdered === null ? "" : th.IsOrdered ? "&nbsp;\u25BC" : "&nbsp;\u25B2")
                th.onclick = (event) => {
                    if (TConfig.IsEmpty(event.target.IsOrdered)) {
                        this.#OrderBy += columnNameAsc
                        event.target.IsOrdered = false
                        event.target.innerHTML = `${column.Title}&nbsp;\u25B2` 
                    }
                    else if (event.target.IsOrdered === false) {
                        this.#OrderBy = this.#OrderBy.replace(columnNameAsc, columnNameDesc)
                        event.target.IsOrdered = true
                        event.target.innerHTML = `${column.Title}&nbsp;\u25BC`
                    }
                    else {
                        this.#OrderBy = this.#OrderBy.replace(columnNameDesc, "")
                        event.target.IsOrdered = null
                        event.target.innerHTML = column.Title
                    }
                    this.Renderize()
                }
                tr.appendChild(th)
                //if (column.ReferenceTableId && !this.#ReferenceRecordsets[column.ReferenceTableId])
                //   this.#ReferenceRecordsets[column.ReferenceTableId] = TSystem.GetTable(column.ReferenceTableId).ListTableRows()
            })
        this.#HTML.Head.innerHTML = null
        tr.title = "Clique 1 vez no cabeçalho da coluna para ordenar os registros em ordem ascendente, 2 vezes em ordem descendente e 3 vezes para cancelar a ordenação"
        this.#HTML.Head.appendChild(tr)
    }
    #BuildHtmlBody(dataPage) {
        this.#HTML.Body.innerHTML = null
        this.#Rows.length = 0
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
            tr.ondblclick = () => this.#HTML.UpdateButton.click()
            this.#Table.Columns.filter(column => column.IsGridable)
                .forEach(column => {
                    const td = document.createElement("td")

                    td.appendChild(this.#GetControl(column, row[column.Name]))
                    td.style = `text-align: ${column.Domain.Type.Category.HtmlInputAlign}`
                    tr.appendChild(td)
            })
            this.#HTML.Body.appendChild(tr)
            this,this.#Rows.push(tr)
            if (this.#RowNumber === index)
                tr.click()
        })
    }
    #BuildHtmlFoot() {
        let tr = document.createElement("tr"),
            th = document.createElement("th"),
            filtered = this.IsFiltered(),
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
            this.#HTML.NumberInput.onchange = (event) => {
                let value = Number(event.target.value)

                if (value > this.#PageCount)
                    event.target.value = this.#PageCount.toString()
                else if (value < 1)
                    event.target.value = "1"
                this.#HTML.NumberInput.value = event.target.value
                this.#PageNumber = value
                this.Renderize(value)

            }
            th.appendChild(this.#HTML.NumberInput)
        }

        this.#HTML.CreateButton = document.createElement("button")
        this.#HTML.CreateButton.type = "button"
        this.#HTML.CreateButton.style.backgroundImage = TGrid.#Images.Insert
        this.#HTML.CreateButton.title = "Incluir registro (ctrl-i)"
        this.#HTML.CreateButton.hidden = false
        this.#HTML.CreateButton.onmouseenter = () => TScreen.Message = "Incluir registro"
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
        this.#HTML.UpdateButton.title = "Alterar registro (ctrl-a)"
        this.#HTML.UpdateButton.hidden = this.#RowCount === 0
        this.#HTML.UpdateButton.onmouseenter = () => TScreen.Message = "Alterar registro"
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
        this.#HTML.DeleteButton.title = "Excluir registro (ctrl-e)"
        this.#HTML.DeleteButton.hidden = this.#RowCount === 0
        this.#HTML.DeleteButton.onmouseenter = () => TScreen.Message = "Excluir registro"
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
        this.#HTML.QueryButton.title = "Ver registro (ctrl-v)"
        this.#HTML.QueryButton.hidden = this.#RowCount === 0
        this.#HTML.QueryButton.onmouseenter = () => TScreen.Message = "Ver registro"
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
        this.#HTML.FilterButton.title = "Filtrar registros (ctrl-f)"
        this.#HTML.FilterButton.hidden = !filtered && this.#RowCount <= TSystem.RowsPerPage
        this.#HTML.FilterButton.onmouseenter = () => TScreen.Message = "Filtrar registros"
        this.#HTML.FilterButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.FilterButton.onclick = async () => {
            (await new TForm(this, TActions.FILTER).Configure()).Renderize()
        }
        th.appendChild(this.#HTML.FilterButton)

        this.#HTML.UnfilterButton = document.createElement("button")
        this.#HTML.UnfilterButton.type = "button"
        this.#HTML.UnfilterButton.style.backgroundImage = TGrid.#Images.Unfilter
        this.#HTML.UnfilterButton.title = `Limpar filtragem de registros (ctrl-l): ${this.Filter}`
        this.#HTML.UnfilterButton.hidden = !filtered
        this.#HTML.UnfilterButton.onmouseenter = () => TScreen.Message = "Limpar filtragem de registros"
        this.#HTML.UnfilterButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.UnfilterButton.onclick = () => {
            this.ClearFilters()
            this.Renderize()
        }
        th.appendChild(this.#HTML.UnfilterButton)

        this.#HTML.UnorderButton = document.createElement("button")
        this.#HTML.UnorderButton.type = "button"
        this.#HTML.UnorderButton.style.backgroundImage = TGrid.#Images.Unorder
        this.#HTML.UnorderButton.title = `Limpar ordenação de registros (ctrl-o): ${this.OrderBy}`
        this.#HTML.UnorderButton.hidden = TConfig.IsEmpty(this.#OrderBy)
        this.#HTML.UnorderButton.onmouseenter = () => TScreen.Message = "Limpar ordenação de registros"
        this.#HTML.UnorderButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.UnorderButton.onclick = () => {
            this.#OrderBy = ""
            this.Renderize()
        }
        th.appendChild(this.#HTML.UnorderButton)

        this.#HTML.ExitButton = document.createElement("button")
        this.#HTML.ExitButton.type = "button"
        this.#HTML.ExitButton.style.backgroundImage = TGrid.#Images.Exit
        this.#HTML.ExitButton.title = "Retornar ao menu principal (ctrl-r)"
        this.#HTML.ExitButton.hidden = false
        this.#HTML.ExitButton.onmouseenter = () => TScreen.Message = "Retornar ao menu principal"
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
            .forEach(column => primarykeys[column.Name] = this.#Data[this.#RowNumber][column.Name])

        return primarykeys
    }
    get OrderBy() {
        return this.#OrderBy.slice(0, -1)
    }
    get Filter() {
        var filter = ""

        for (let key in this.#FilterValues) {
            let value = this.#FilterValues[key]

            if (value !== null)
                filter += `${(filter === "" ? "" : " AND ")}${key} = '${value}'`
        }
        return filter
    }
    get Container() {
        return this.#HTML.Table
    }
}