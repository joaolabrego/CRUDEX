"use strict"

export default class TRecord {
    #Table = null
    #Fields = []

    constructor(table) {
        if (recordset.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Table = table
    }
    AddField(field) {
        if (field.ClassName !== "TField")
            throw new Error("Argumento field não é do tipo TField.")
        this.#Fields.push(field)
    };
    GetField() {
        return this.#Fields
    }
    get Table() {
        return this.#Table
    }
}
