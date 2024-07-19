"use strict"

export default class TDatabase {
    #Id = 0
    #Name = ""
    #Description = ""
    #Alias = ""
    #Folder = ""

    #Tables = []
    constructor(rowDatabase) {
        if (rowDatabase.ClassName !== "RecordDatabase")
            throw new Error("Argumento rowDatabase não é do tipo Database.")
        this.#Id = rowDatabase.Id
        this.#Name = rowDatabase.Name
        this.#Description = rowDatabase.Description
        this.#Alias = rowDatabase.Alias
        this.#Folder = rowDatabase.Folder
    }
    AddTable(table) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Tables.push(table)
    }
    GetTable(tablename) {
        return this.#Tables.find(table => table.Name === tablename)
    }
    get Id() {
        return this.#Id
    }
    get Name() {
        return this.#Name
    }
    get Description() {
        return this.#Description
    }
    get Alias() {
        return this.#Alias
    }
    get Folder() {
        return this.#Folder
    }
    get Tables() {
        return this.#Tables
    }
}