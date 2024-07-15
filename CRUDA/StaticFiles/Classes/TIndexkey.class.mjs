"use strict"

export default class TIndexkey {
    #Id = 0
    #IndexId = 0
    #Sequence = 0
    #ColumnId = 0
    #IsDescending = false
    
    #Index = null
    constructor(index, rowIndexkey) {
        if (index.ClassName !== "TIndex")
            throw new Error("Argumento index não é do tipo TIndex.")
        if (rowIndexkey.ClassName !== "RecordIndexkey")
            throw new Error("Argumento rowIndexkey não é do tipo Indexkey.")
        this.#Id = rowIndexkey.Id
        this.#IndexId = rowIndexkey.IndexId
        this.#Sequence = rowIndexkey.Sequence
        this.#ColumnId = rowIndexkey.ColumnId
        this.#IsDescending = rowIndexkey.IsDescending
        this.#Index = index
    }
    get Id() {
        return this.#Id
    }
    get IndexId() {
        return this.#IndexId
    }
    get Sequence() {
        return this.#Sequence
    }
    get ColumnId() {
        return this.#ColumnId
    }
    get IsDescending() {
        return this.#IsDescending
    }
    get Index() {
        return this.#Index
    }
}