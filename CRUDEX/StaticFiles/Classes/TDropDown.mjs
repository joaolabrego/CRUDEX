"use strict"

import TSystem from "./TSystem.class.mjs"

export default class DropDown {
    
    #Table = ""
    #Id = 0
    #HTML = {
        Container: null,
        Dialog: null,
        Input: null,
        Table: null,
    }
    static #Style = ""
    #Grid = null

    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")
        this.#Style = styles.DropDown
    }
    constructor(databaseName, tableName, id) {
        let database = TSystem.GetDatabase(databaseName)

        if (!database)
            throw new Error("Banco-de-dados não encontrado.")
        this.#Table = database.GetTable(tableName)
        if (!this.#Table)
            throw new Error("Tabela de banco-de-dados não encontrada.")
        this.#Id = id
        this.#HTML.Container = document.createDocumentFragment()

        let style = document.createElement("style")

        style.innerText = DropDown.#Style
        this.#HTML.Container.appendChild(style)
        this.#HTML.Container.className = "container"

        let input = document.createElement("input")

        input.type = "text"
        input.placeholder = "Selecione uma opção..."
        input.readOnly = true
        input.className = "input"

        this.#HTML.Container.appendChild(this.#HTML.Input)

        let span = document.createElement("span")

        span.innerText = String.fromCharCode(9660)
        span.className = "arrow"

        this.#HTML.Container.appendChild(span)

        this.#HTML.Dialog = document.createElement("dialog")
        this.#HTML.Dialog.className = "dialog"

        this.#HTML.Input = document.createElement("input")
        this.#HTML.Input.type = "text"
        this.#HTML.Input.placeholder = "Digite para filtrar..."

        this.#HTML.Dialog.appendChild(this.#HTML.Input)

        this.#HTML.Table = document.createElement("table")
        this.#HTML.Dialog.appendChild(this.#HTML.Table)

        this.#HTML.Container.appendChild(this.#HTML.Dialog)
    }
}