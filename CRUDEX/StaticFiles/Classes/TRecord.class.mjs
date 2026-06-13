"use strict";

import TConfig from "./TConfig.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TTable from "./TTable.class.mjs";

export default class TRecord {
    #Table = null;
    references = {};

    constructor(table, datarow, refLookup = {}) {
        if (!(table instanceof TTable))
            throw new Error("Argumento table não é do tipo TTable.");
        this.#Table = table;
        for (const [key, value] of Object.entries(datarow)) {
            if (key !== "Kind" && key !== "ListItemValue" && key !== "ClassName")
                this[key] = value;
        }
        for (const column of table.Columns) {
            if (TConfig.IsEmpty(column.ReferenceTableId))
                continue;
            const refTable = TSystem.GetTable(column.ReferenceTableId);
            if (!refTable)
                continue;
            const alias = refTable.Alias || refTable.Name;
            const fk = datarow[column.Name];
            if (fk === null || fk === undefined)
                continue;
            const row = TRecord.#LookupRef(refLookup, refTable, fk);
            if (row)
                this.references[alias] = row;
        }
    }

    static #LookupRef(refLookup, refTable, fk) {
        for (const key of [refTable.Alias, refTable.Name]) {
            if (!key)
                continue;
            const row = refLookup[key]?.get(fk);
            if (row)
                return row;
        }
        return null;
    }

    get Table() {
        return this.#Table;
    }
}
