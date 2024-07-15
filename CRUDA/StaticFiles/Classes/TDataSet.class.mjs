"use strict"

import TActions from "./TActions.class.mjs"
import TUpdate from "./TUpdate.mjs"

export default class TDataSet {
    #Table = null
    #RecordSets = []
    #RecordChanges = []
    constructor(table) {
        if (database.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Table = table
    }
    AddCreate(record) {
        this.#Updates.push(new TUpdate(this, record, TActions.CREATE))
    }
    AddUpdate(record) {
        this.#Updates.push(new TUpdate(this, record, TActions.UPDATE))
    }
    AddDelete(record) {
        this.#Updates.push(new TUpdate(this, record, TActions.DELETE))
    }
    get Table() {
        return this.#Table
    }
    get RecordSets() {
        return this.#RecordSets
    }
    get RecordChanges() {
        return this.#RecordChanges
    }
}