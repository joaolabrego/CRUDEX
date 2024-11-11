"use strict"

import TConfig from "./TConfig.class.mjs"
export default class TDatabase {
    #Tables = []
    constructor(rowDatabase) {
        if (rowDatabase.ClassName !== "Database")
            throw new Error("Argumento rowDatabase não é do tipo Database.")
        TConfig.CreateProperties(rowDatabase, this)
    }
    AddTable(table) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Tables.push(table)
    }
    GetTable(tableNameOrId) {
        if (typeof tableNameOrId === "string")
            return this.#Tables.find(table => table.Name === tableNameOrId)

        return this.#Tables.find(table => table.Id === tableNameOrId)
    }
    get Tables() {
        return this.#Tables
    }
}