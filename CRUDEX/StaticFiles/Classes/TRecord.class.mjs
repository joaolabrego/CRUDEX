"use strict"

import TField from "./TField.class.mjs"
export default class TRecord {
    #Recordset = null
    #Fields = []

    constructor(recordset, datarow) {
        if (recordset.ClassName !== "TRecordset")
            throw new Error("Argumento recordset não é do tipo TRecordset.")
        if (datarow.ClassName === recordset.Table.Alias)
            throw new Error("Argumento datarow não é do mesmo tipo da tabela.")
        this.#Recordset = recordset
        recordset.Table.Columns.forEach(column => this.#Fields.push(new TField(column, datarow[column.Name])))
    }
    get Recordset() {
        return this.#Recordset
    }
    get Fields() {
        return this.#Fields
    }
}
