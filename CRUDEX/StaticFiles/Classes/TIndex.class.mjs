"use strict";

import TConfig from "./TConfig.class.mjs";
import TTable from "./TTable.class.mjs";
import TIndexkey from "./TIndexkey.class.mjs";
export default class TIndex {
    #Indexkeys = [];
    #Table = null;
    constructor(table, rowIndex) {
        if (!table instanceof TTable)
            throw new Error("Argumento table não é do tipo TTable.");
        if (rowIndex.Kind !== "Index")
            throw new Error("Argumento rowIndex não é do tipo Index.");
        TConfig.CreateProperties(rowIndex, this);
        this.#Table = table;
    }
    AddIndexkey(Indexkey) {
        if (!Indexkey instanceof TIndexkey)
            throw new Error("Argumento Indexkey não é do tipo TIndexkey.");
        this.#Indexkeys.push(Indexkey);
    }
    get Table() {
        return this.#Table;
    }
}