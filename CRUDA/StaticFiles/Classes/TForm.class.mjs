"use strict"

import TActions from "./TActions.class.mjs"
import TScreen from "./TScreen.class.mjs"

export default class TForm {
    #Browse = null

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

    constructor(browse, action) {
        if (browse.ClassName !== "TBrowse")
            throw new Error("Argumento browse não é do tipo TBrowse.")
        this.#Browse = browse
        this.#Action = action
        this.#ReturnAction = `browsebro/${this.#Browse.Table.Database.Name}/${this.#Browse.Table.Name}`
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
    async Configure() {
        if (this.#Action === TActions.CREATE)
            this.#Browse.Table.ClearValues()
        else if (this.#Action === TActions.FILTER)
            this.#Browse.Table.MoveFilters()
        this.#Browse.Table.Columns.forEach(column => {
            this.#HTML.Form.appendChild(column.GetFormControl(this.#Action))
            if (!(this.#HTML.FirstInput || column.InputControl.readOnly)) {
                this.#HTML.FirstInput = column.InputControl
            }
        })

        return this
    }

    Renderize() {
        let title = ""
        let message = ""

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
        TScreen.Title = `${title} de ${this.#Browse.Table.Description}`
        TScreen.LastMessage = TScreen.Message = message
        TScreen.WithBackgroundImage = false
        TScreen.Main = this.#HTML.Container
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
        this.#HTML.ConfirmButton.onclick = () => {
            if (this.#Action === TActions.FILTER)
                this.#Browse.Table.SaveFilters()
            this.#Browse.Renderize()
                .catch(error => TScreen.ShowError(error.Message, error.Action || this.#ReturnAction))
        }

        this.#HTML.ButtonsBar.appendChild(this.#HTML.ConfirmButton)

        if (this.#Action !== TActions.QUERY) {
            this.#HTML.CancelButton = document.createElement("button")
            this.#HTML.CancelButton.innerText = "Cancelar"
            this.#HTML.CancelButton.className = "button box"
            this.#HTML.CancelButton.type = "reset"
            this.#HTML.CancelButton.style.backgroundImage = TForm.#Images.Cancel
            this.#HTML.CancelButton.onclick = () => {
                if (this.#Action === TActions.FILTER)
                    this.#Browse.Table.Columns.forEach(column =>
                        column.FilterValue = column.LastValue)
                this.#Browse.Renderize()
                    .catch(error => TScreen.ShowError(error.Message, error.Action || this.#ReturnAction))
            }
            this.#HTML.ButtonsBar.appendChild(this.#HTML.CancelButton)
        }

        this.#HTML.Container.appendChild(this.#HTML.ButtonsBar)
    }
}