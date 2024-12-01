"use strict"

import TActions from "./TActions.class.mjs"
import TForm from "./TForm.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TBrowse {
    #Table = null
    #ReferenceRecordsets = []

    #HTML = {
        Container: null,
        Head: null,
        Body: null,
        Foot: null,
        NumberPage: null,
        RangePage: null,
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
    constructor(table) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#HTML.Container = document.createElement("table")
        this.#HTML.Container.className = "grid box"

        let style = document.createElement("style")
        style.innerText = TBrowse.#Style
        this.#HTML.Container.appendChild(style)

        this.#HTML.Head = document.createElement("thead")
        this.#HTML.Container.appendChild(this.#HTML.Head)

        this.#HTML.Body = document.createElement("tbody")
        this.#HTML.Container.appendChild(this.#HTML.Body)

        this.#HTML.Foot = document.createElement("tfoot")
        this.#HTML.Container.appendChild(this.#HTML.Foot)

        this.#Table = table
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

    #OnChangeInput = (event) => {
        let control = event.target.className === "NumberPage" ? this.#HTML.RangePage : this.#HTML.NumberPage

        if (Number(event.target.value) > this.#Table.PageCount)
            event.target.value = this.#Table.PageCount.toString()
        else if (Number(event.target.value) < 1) {
            event.target.value = "1"
        }
        control.value = event.target.value
        this.Renderize(Number(event.target.value))
    }

    async Renderize(page) {
        TScreen.Title = `Manutenção de ${this.#Table.Description}`
        this.#Table.ReadTablePage(page)
            .then(() => {
                if (this.#Table.RowCount > 1)
                    TScreen.LastMessage = TScreen.Message = "Clique na linha que deseja selecionar."
                else
                    TScreen.LastMessage = TScreen.Message = "Clique em um dos botões."
                this.#BuildHtmlHead()
                this.#BuildHtmlBody()
                this.#BuildHtmlFoot()
                TScreen.WithBackgroundImage = true
                TScreen.Main = this.#HTML.Container
            })
            .catch(error => {
                TScreen.ShowError(error.Message, error.Action || `grid/${this.#Table.Database.Name}/${this.#Table.Name}`)
            })
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
    }

    #BuildHtmlHead() {
        const tr = document.createElement("tr")

        this.#Table.Columns.filter(column => column.IsBrowseable)
            .forEach(column => {
                const th = document.createElement("th")

                th.innerText = column.Title
                tr.appendChild(th)
                //if (column.ReferenceTableId && !this.#ReferenceRecordsets[column.ReferenceTableId])
                //   this.#ReferenceRecordsets[column.ReferenceTableId] = TSystem.GetTable(column.ReferenceTableId).ListTableRows()
            })
        this.#HTML.Head.innerHTML = null
        this.#HTML.Head.appendChild(tr)
    }

    #BuildHtmlBody() {
        this.#HTML.Body.innerHTML = null
        this.#Table.Recordset.forEach((row, index) => {
            let tr = document.createElement("tr")

            tr.title = JSON.stringify(row).replace(/,/g, ",\n")
            tr.onclick = (event) => {
                this.#Table.RowNumber = tr.rowIndex - 1
                if (this.#HTML.SelectedRow)
                    this.#HTML.SelectedRow.removeAttribute("style")
                this.#HTML.SelectedRow = event.currentTarget
                this.#HTML.SelectedRow.style = "background-color: var(--background-color-control);"
            }
            tr.ondblclick = () => this.#HTML.QueryButton.click()
            this.#Table.Columns.filter(column => column.IsBrowseable)
                .forEach(column => {
                    const td = document.createElement("td")

                    td.appendChild(column.GeTBrowseControl(row[column.Name]))
                    td.style = `text-align: ${column.Domain.Type.InputAlign}`
                    tr.appendChild(td)
            })
            this.#HTML.Body.appendChild(tr)
            if (this.#Table.RowNumber === index)
                tr.click()
        })
    }

    #BuildHtmlFoot() {
        let tr = document.createElement("tr"),
            th = document.createElement("th"),
            p

        th.colSpan = this.#Table.Columns.length.toString()
        if (this.#Table.RowCount > TSystem.RowsPerPage) {
            p = document.createElement("p")
            p.style.float = "left"
            p.innerHTML = "Página:&nbsp;&nbsp;"

            th.appendChild(p)

            this.#HTML.NumberPage = document.createElement("input")
            this.#HTML.NumberPage.id = "NumberPage"
            this.#HTML.NumberPage.style.float = "left"
            this.#HTML.NumberPage.className = "numberPage"
            this.#HTML.NumberPage.type = "number"
            this.#HTML.NumberPage.value = this.#Table.PageNumber.toString()
            this.#HTML.NumberPage.title = "Ir para página..."
            this.#HTML.NumberPage.min = "1"
            this.#HTML.NumberPage.max = this.#Table.PageCount.toString()
            this.#HTML.NumberPage.onchange = this.#OnChangeInput

            th.appendChild(this.#HTML.NumberPage)

            p = document.createElement("p")
            p.style.float = "left"
            p.innerHTML = "&nbsp;&nbsp;"

            th.appendChild(p)

            this.#HTML.RangePage = document.createElement("input")
            this.#HTML.RangePage.id = "RangePage"
            this.#HTML.RangePage.style.float = "left"
            this.#HTML.RangePage.className = "rangePage"
            this.#HTML.RangePage.type = "range"
            this.#HTML.RangePage.tabindex = "-1"
            this.#HTML.RangePage.value = this.#Table.PageNumber.toString()
            this.#HTML.RangePage.title = "Ir para página..."
            this.#HTML.RangePage.min = "1"
            this.#HTML.RangePage.max = this.#Table.PageCount.toString()
            this.#HTML.RangePage.onchange = this.#OnChangeInput

            th.appendChild(this.#HTML.RangePage)
        }

        this.#HTML.CreateButton = document.createElement("button")

        this.#HTML.CreateButton.type = "button"
        this.#HTML.CreateButton.style.backgroundImage = TBrowse.#Images.Insert
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
        this.#HTML.UpdateButton.style.backgroundImage = TBrowse.#Images.Edit
        this.#HTML.UpdateButton.title = "Alterar registro"
        this.#HTML.UpdateButton.hidden = this.#Table.RowCount === 0
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
        this.#HTML.DeleteButton.style.backgroundImage = TBrowse.#Images.Delete
        this.#HTML.DeleteButton.title = "Excluir registro"
        this.#HTML.DeleteButton.hidden = this.#Table.RowCount === 0
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
        this.#HTML.QueryButton.style.backgroundImage = TBrowse.#Images.Query
        this.#HTML.QueryButton.title = "Consultar registro"
        this.#HTML.QueryButton.hidden = this.#Table.RowCount === 0
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
        this.#HTML.FilterButton.style.backgroundImage = TBrowse.#Images.Filter
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
        this.#HTML.ExitButton.style.backgroundImage = TBrowse.#Images.Exit
        this.#HTML.ExitButton.title = "Retornar para menu principal"
        this.#HTML.ExitButton.onmouseenter = event => TScreen.Message = event.currentTarget.title
        this.#HTML.ExitButton.onmouseleave = () => TScreen.Message = TScreen.LastMessage
        this.#HTML.ExitButton.onclick = () => TSystem.Action = `${TActions.EXIT}/${TActions.MENU}`
        th.appendChild(this.#HTML.ExitButton)

        p = document.createElement("p")
        p.style.float = "right"
        p.innerHTML = `Total de Registros: ${this.#Table.RowCount}`
        th.appendChild(p)
        tr.appendChild(th)

        this.#HTML.Foot.innerHTML = null
        this.#HTML.Foot.appendChild(tr)
    }
    get Table() {
        return this.#Table
    }
    get ReferenceRecordsets() {
        return this.#ReferenceRecordsets
    }
}