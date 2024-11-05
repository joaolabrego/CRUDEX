"use strict"

import TActions from "./TActions.class.mjs"
import TConfig from "./TConfig.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TTable {
    #Database = null
    #Columns = []
    #Indexes = []
    #ReferenceTables = null

    constructor(database, rowTable) {
        if (database.ClassName !== "TDatabase")
            throw new Error("Argumento database não é do tipo TDatabase.")
        if (rowTable.ClassName !== "Table")
            throw new Error("Argumento rowTable não é do tipo Table.")
        TConfig.CreateProperties(rowTable, this)
        this.#Database = database
    }
    AddColumn(column) {
        if (column.ClassName !== "TColumn")
            throw new Error("Argumento column não é do tipo TColumn.")
        this.#Columns.push(column)
    }
    AddIndex(index) {
        if (index.ClassName !== "TIndex")
            throw new Error("Argumento index não é do tipo TIndex.")
        this.#Indexes.push(index)
    }
    get Columns() {
        return this.#Columns
    }
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
    get Database() {
        return this.#Database
    }
}