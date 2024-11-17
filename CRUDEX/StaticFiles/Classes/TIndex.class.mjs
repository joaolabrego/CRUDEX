"use strict";

import TConfig from "./TConfig.class.mjs";
export default class TIndex {
    #Indexkeys = [];
    #Table = null;
    constructor(table, rowIndex) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.");
        if (rowIndex.ClassName !== "Index")
            throw new Error("Argumento rowIndex não é do tipo Index.");
        TConfig.CreateProperties(rowIndex, this);
        this.#Table = table;
    }
    AddIndexkey(Indexkey) {
        if (Indexkey.ClassName !== "TIndexkey")
            throw new Error("Argumento Indexkey não é do tipo TIndexkey.");
        this.#Indexkeys.push(Indexkey);
    }
    get Table() {
        return this.#Table;
    }
}