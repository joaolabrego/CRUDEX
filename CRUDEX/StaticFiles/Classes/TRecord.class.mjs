"use strict"

import TSystem from "./TSystem.class.mjs"

export default class TRecord
{
    #Recordset = null
    #Column = null
    #Value = null
    #Reference = null

    get ReferenceTables() {
        if (this.#ReferenceTables === null) {
            this.#ReferenceTables = []
            this.#Columns.filter(column => !TConfig.IsEmpty(column.ReferenceTableId))
                .forEach(column => {
                    this.#ReferenceTables.push(TSystem.GetTable(column.ReferenceTableId))
                })
        }

        return this.#ReferenceTables
    }

    constructor(recordset, column, record) {
        if (grid.ClassName !== "TRecordset")
            throw new Error("Argumento recordset não é do tipo TRecordset.")
        if (column.ClassName !== "TColumn")
            throw new Error("Argumento column não é do tipo TColumn.")
        if (record.ClassName === undefined)
            throw new Error("Argumento record não tem propriedade ClassName.")
        this.#Recordset = recordset
        this.#Column = column
        this.#Value = record[column.Name]

    }
}