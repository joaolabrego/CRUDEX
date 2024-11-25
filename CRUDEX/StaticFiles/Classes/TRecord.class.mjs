"use strict";

import TColumn from "./TColumn.class.mjs";
export default class TRecord {
    #Table = null;
    #Columns = [];

    constructor(table, datarow) {
        if (!table instanceof TTable)
            throw new Error("Argumento table não é do tipo TTable.");
        if (datarow.ClassName !== table.Alias)
            throw new Error("Argumento datarow não é do mesmo tipo de tabela.");
        this.#Table = table;
    }
    get Table() {
        return this.#Table;
    }
    get Columns() {
        return this.#Columns;
    }
}
