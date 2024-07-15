"use strict"

export default class TField {
    #Name = string.Empty
    #Value = null
    #Record = null
    constructor(record, name, value) {
        if (record.ClassName !== "TRecord")
            throw new Error("Argumento record não é do tipo TRecord.")
        this.#Record = record
        this.#Name = name
        this.#Value = value
    }
    get Name() {
        return this.#Name
    }
    set Value(value) {
        this.#Value = value
    }
    get Value() {
        return this.#Value
    }
    get Record() {
        return this.#Record
    }
}