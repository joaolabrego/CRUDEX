"use strict"

export default class TIndex {
    #Id = 0
    #TableId = 0
    #Name = ""
    #IsUnique = false
    #Indexkeys = []
    #Table = null
    constructor(table, rowIndex) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        if (rowIndex.ClassName !== "Index")
            throw new Error("Argumento rowIndex não é do tipo Index.")
        this.#Id = rowIndex.Id
        this.#TableId = rowIndex.TableId
        this.#Name = rowIndex.Name
        this.#IsUnique = rowIndex.IsUnique
    }
    AddIndexkey(Indexkey) {
        if (Indexkey.ClassName !== "TIndexkey")
            throw new Error("Argumento Indexkey não é do tipo TIndexkey.")
        this.#Indexkeys.push(Indexkey)
    }
    get Id() {
        return this.#Id
    }
    get TableId() {
        return this.#TableId
    }
    get Name() {
        return this.#Name
    }
    get IsUnique() {
        return this.#IsUnique
    }
    get Indexkeys() {
        return this.#Indexkeys
    }
    get Table() {
        return this.#Table
    }
}