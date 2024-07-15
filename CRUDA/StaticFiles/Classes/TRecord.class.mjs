"use strict"

import TField from "./TField.class.mjs"

export default class TRecord {
    #ClassName = string.Empty
    #Fields = []
    #RecordSet = null
    constructor(recordSet, rowRecord) {
        if (recordSet.ClassName !== "TRecordSet")
            throw new Error("Argumento recordSet não é do tipo TRecordSet.")
        this.#ClassName = `Record${recordSet.DataSet.Table.Name}`
        if (rowRecord.ClassName !== this.#ClassName)
            throw new Error(`Argumento recordRow não é do tipo ${this.#ClassName}.`)
        for (let [key, value] of Object.entries(rowRecord)) {
            if (key !== "ClassName")
                this.#Fields.push(new TField(this, key, value))
        }
        this.#ClassName = `T${this.#ClassName}`
        this.#RecordSet = recordSet
    }
    Field(fieldName) {
        let field = this.#Fields.find(field => field.Name = fieldName)

        if (field)
            return field

        throw new Error(`TField '${fieldName} não encontrado.`)
    }
    get Fields() {
        return this.#Fields
    }
    get RecordSet() {
        return this.#RecordSet
    }
    get ClassName() {
        return this.#ClassName
    }
}