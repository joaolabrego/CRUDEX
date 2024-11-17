"use strict"

import TSystem from "./TSystem.class.mjs"
import TConfig from "./TConfig.class.mjs"
export default class TColumn {
    #LastValue = null
    #Value = null
    #FilterValue = null
    #Table = null
    #Domain = null
    #InputControl = null
    constructor(table, rowColumn) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        if (rowColumn.ClassName !== "Column")
            throw new Error("Argumento rowColumn não é do tipo Column.")
        TConfig.CreateProperties(rowColumn, this)
        this.#Table = table
        this.#Domain = TSystem.GetDomain(rowColumn.DomainId)
    }
    SetValue(value) {
        let categoryName = this.#Domain.Type.Category.Name

        if (categoryName !== typeof value) {
            if (categoryName === "number")
                value = Number(value)
            else if (categoryName === "boolean")
                value = new Boolean(value)
            else if (categoryName === "date" || categoryName === "datetime" || categoryName === "time")
                value = new Date(`${categoryName === "time" ? "1900-01-01 " : ""}${value}`)
            else
                value = String(value)


        }
    }
    set LastValue(value) {
        this.#LastValue = value
    }
    get LastValue() {
        return this.#LastValue
    }
    set Value(value) {
        this.#Value = value
    }
    get Value() {
        return this.#Value
    }
    set FilterValue(value) {
        this.#FilterValue = value
    }
    get FilterValue() {
        return this.#FilterValue
    }
    get Table() {
        return this.#Table
    }
    get Domain() {
        return this.#Domain
    }
    get InputControl() {
        return this.#InputControl
    }
}