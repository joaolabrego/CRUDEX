"use strict"

import TActions from "./TActions.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TConfig from "./TConfig.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TForm {
    #Action = ""
    #ReturnAction = ""
    static #Style = ""
    static #Images = {
        Confirm: "",
        Cancel: "",
        Exit: "",
    }
    #HTML = {
        FirstInput: null,
        Container: null,
        Form: null,
        ButtonsBar: null,
        ConfirmButton: null,
        CancelButton: null,
    }
    #Grid = null
    #Record = null

    constructor(grid, action) {
        if (grid.ClassName !== "TGrid")
            throw new Error("Argumento grid não é do tipo TGrid.")
        this.#Grid = grid
        this.#Action = action
        this.#ReturnAction = `grid/${this.#Grid.Table.Database.Name}/${this.#Grid.Table.Name}`
        this.#HTML.Container = document.createDocumentFragment()
        this.#BuildForm()
        this.#BuildButtonsBar()
    }
    static Initialize(styles, images) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")
        if (images.ClassName !== "Images")
            throw new Error("Argumento images não é do tipo Images.")
        this.#Style = styles.Form
        this.#Images.Confirm = images.Confirm
        this.#Images.Cancel = images.Cancel
        this.#Images.Exit = images.Exit
    }
    async #ReadRecord() {
        let parameters = {
            DatabaseName: this.#Grid.Table.Database.Name,
            TableName: this.#Grid.Table.Name,
            Action: TActions.READ,
            InParams: {
                LoginId: TLogin.LoginId,
                RecordFilter: JSON.stringify(this.#Grid.Primarykeys),
                OrderBy: null,
                PaddingGridLastPage: false,
            },
            OutParams: {},
            IOParams: {
                PageNumber: 0,
                LimitRows: 0,
                MaxPage: 0,
            },
        }

        return (await TConfig.GetAPI(TActions.EXECUTE, parameters)).DataSet.Table[0]
    }
    #GetCheckBox(column) {
        let control = document.createElement("input"),
            isEmptyValue = TConfig.IsEmpty(this.#Record[column.Name])

        control.type = column.Domain.Type.Category.HtmlInputType
        control.indeterminate = isEmptyValue
        control.checked = this.#Record[column.Name]
        control.title = isEmptyValue ? 'nulo' : control.checked ? "sim" : "não"
        control.onclick = (event) => {
            if (event.target.readOnly)
                return false

            let isEmptyValue = TConfig.IsEmpty(this.#Record[column.Name])

            if (isEmptyValue) {
                this.#Record[column.Name] = false
                isEmptyValue = false
            }
            else if (this.#Record[column.Name] === false)
                this.#Record[column.Name] = true
            else {
                this.#Record[column.Name] = null
                isEmptyValue = true
            }
            event.target.indeterminate = isEmptyValue
            event.target.checked = event.target.value = this.#Record[column.Name]
            event.target.title = event.target.indeterminate ? "nulo" : event.target.checked ? "sim" : "não"
        }

        return control
    }
    #GetTextArea() {
        let control = document.createElement("textarea")

        control.rows = 5
        control.cols = 50

        return control
    }
    #GetNumberInput(column) {
        let control = document.createElement("input")

        control.type = column.Domain.Type.Category.HtmlInputType
        control.min = column.Domain.Minimum
        control.max = column.Domain.Maximum
        control.step = 1 / 10 ** (column.Domain.Decimals || 0)

        return control
    }
    #GetTextInput(column) {
        let control = document.createElement("input")

        control.type = column.Domain.Type.Category.HtmlInputType
        control.size = column.Domain.Type.MaxLength ?? column.Domain.Length ?? 20
        control.maxLength = column.Domain.Length ?? 20

        return control
    }
    #GetControl(column, action) {
        let fieldset = document.createElement("fieldset"),
            legend = document.createElement("legend"),
            control

        legend.innerText = column.Caption
        if (column.IsRequired) {
            let span = document.createElement("span");

            span.textContent = " *"
            span.style.color = "red"
            span.style.fontSize = "1.5dvmin"
            span.style.fontWeight = "bold"
            span.title = "Indica valor requerido"
            legend.appendChild(span)
        }
        fieldset.appendChild(legend)
        switch (column.Domain.Type.Category.HtmlInputType) {
            case "checkbox":
                control = this.#GetCheckBox(column)
                break
            case "textarea":
                control = this.#GetTextArea(column)
                break
            case "number":
                control = this.#GetNumberInput(column)
                break
            case "text":
                control = this.#GetTextInput(column)
                break
        }
        control.onchange = event => {
            let value = event.target.type === "checkbox" ? eval(event.target.value) : event.target.value

            this.#Record[column.Name] = TConfig.IsEmpty(value) ? null : value
        }
        control.onkeydown = event => {
            if (event.key === "Enter" || event.key === "Tab") {
                event.preventDefault()

                let focusableElements = Array.from(document.querySelectorAll('input, textarea')),
                    currentIndex = focusableElements.indexOf(document.activeElement)

                if (currentIndex > -1 && currentIndex < focusableElements.length - 1)
                    focusableElements[currentIndex + 1].focus()
                else
                    focusableElements[0].focus()
            }
            else if (event.key === "Escape") {
                if (this.#Action == TActions.QUERY)
                    this.#HTML.ConfirmButton.click()
                else
                    this.#HTML.CancelButton.click()
            }
            else if (this.#Action == TActions.FILTER && !event.target.Column.IsRequired && (event.key == "Backspace" || event.key == "Delete")) {
                if (event.target.value === "") 
                    event.target.placeholder = event.target.placeholder ? "" : "null"
            }
        }
        control.name = column.Name
        control.Column = column
        control.onfocus = (event) => event.target.select()
        control.value = this.#Record[column.Name]
        control.readOnly = action === TActions.DELETE || action === TActions.QUERY
        control.style.textAlign = column.Domain.Type.Category.HtmlInputAlign
        if (!this.#HTML.FirstInput)
            this.#HTML.FirstInput = control
        fieldset.appendChild(control)
        //if (column.IsRequired)
        //    fieldset.appendChild(document.createTextNode(" *"))

        return fieldset
    }
    async Configure() {
        let columns = this.#Grid.Table.Columns

        this.#Record = {}
        switch (this.#Action) {
            case TActions.CREATE:
                columns = columns.filter(column => column.IsEditable)
                columns.forEach(column => this.#Record[column.Name] = null)
                break
            case TActions.FILTER:
                columns = columns.filter(column => column.IsFilterable)
                columns.forEach(column => this.#Record[column.Name] = this.#Grid.FilterValues[column.Name])
                break
            case TActions.UPDATE:
                columns = columns.filter(column => column.IsEditable)
                await this.#ReadRecord().then(record => this.#Record = record)
                break
            default:
                await this.#ReadRecord().then(record => this.#Record = record)
        }
       columns.forEach(column => {
            let control = this.#GetControl(column, this.#Action)

            this.#HTML.Form.appendChild(control)
        })

        return this
    }
    Renderize() {
        let title = "",
            message = ""

        switch (this.#Action) {
            case TActions.CREATE:
                title = "Inclusão"
                message = "Digite as informações e clique em confirmar para salvá-las..."
                break
            case TActions.UPDATE:
                title = "Alteração"
                message = "Altere as informações e clique em confirmar para salvá-las..."
                break
            case TActions.DELETE:
                title = "Exclusão"
                message = "Clique em confirmar para excluir..."
                break
            case TActions.FILTER:
                title = "Filtragem"
                message = "Digite as informações e clique em confirmar para filtrá-las..."
                break
            case TActions.QUERY:
                title = "Consulta"
                message = "Visualize as informações e clique sair para retornar..."
                break
        }
        TScreen.Title = `${title} de ${this.#Grid.Table.Description}`
        TScreen.LastMessage = TScreen.Message = message
        TScreen.WithBackgroundImage = false
        TScreen.Main = this.#HTML.Container
        //TScreen.AppendIntoMain(this.#Grid.Container)
        if (this.#HTML.FirstInput)
            this.#HTML.FirstInput.focus()
    }
    #BuildForm() {
        this.#HTML.Form = document.createElement("form")
        this.#HTML.Form.method = "post"
        this.#HTML.Form.className = "form"

        let style = document.createElement("style")

        style.innerText = TForm.#Style
        this.#HTML.Form.appendChild(style)
        this.#HTML.Container.appendChild(this.#HTML.Form)
    }
    #BuildButtonsBar() {
        this.#HTML.ButtonsBar = document.createElement("div")
        this.#HTML.ButtonsBar.className = "buttonsBar"

        this.#HTML.ConfirmButton = document.createElement("button")
        this.#HTML.ConfirmButton.className = "button box"
        if (this.#Action === TActions.QUERY) {
            this.#HTML.ConfirmButton.innerText = "Sair"
            this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Exit
        }
        else {
            this.#HTML.ConfirmButton.innerText = "Confirmar"
            this.#HTML.ConfirmButton.style.backgroundImage = TForm.#Images.Confirm
        }
        this.#HTML.ConfirmButton.type = "button"
        this.#HTML.ConfirmButton.onclick = async () => {
            if (this.#Action === TActions.FILTER) {
                this.#Grid.SaveFilters(this.#Record);
            }
            try {
                await this.#Grid.Renderize();
            } catch (error) {
                TScreen.ShowError(error.message, error.Action || this.#ReturnAction);
            }
        }
        this.#HTML.ButtonsBar.appendChild(this.#HTML.ConfirmButton)

        if (this.#Action !== TActions.QUERY) {
            this.#HTML.CancelButton = document.createElement("button")
            this.#HTML.CancelButton.innerText = "Cancelar"
            this.#HTML.CancelButton.className = "button box"
            this.#HTML.CancelButton.type = "reset"
            this.#HTML.CancelButton.style.backgroundImage = TForm.#Images.Cancel
            this.#HTML.CancelButton.onclick = async () => {
                try {
                    await this.#Grid.Renderize();
                } catch (error) {
                    TScreen.ShowError(error.message, error.Action || this.#ReturnAction);
                }
            }
            this.#HTML.ButtonsBar.appendChild(this.#HTML.CancelButton)
        }

        this.#HTML.Container.appendChild(this.#HTML.ButtonsBar)
    }
}