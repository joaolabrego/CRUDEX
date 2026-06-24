"use strict";

import TConfig from "./TConfig.class.mjs";
import TCategoryHtml from "./TCategoryHtml.class.mjs";
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
            const refTable = TSystem.GetReferencePkTable(column);
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

    getBrowseValue(column) {
        const value = this[column.Name];
        const refTable = TSystem.GetReferencePkTable(column);
        if (!refTable)
            return value ?? "";

        const alias = refTable.Alias || refTable.Name;
        const ref = this.references[alias];
        if (!ref)
            return value ?? "";

        const listable = refTable.GetListableColumn();
        if (listable) {
            const listValue = ref[listable.Name];
            if (!TConfig.IsEmpty(listValue))
                return listValue;
        }
        return TSystem.GetPrimaryKeyScalar(ref, refTable) ?? value ?? "";
    }

    getBrowseAlign(column) {
        const refTable = TSystem.GetReferencePkTable(column);
        if (!refTable)
            return TCategoryHtml.getAlign(column.Domain.Type.Category);

        const alias = refTable.Alias || refTable.Name;
        const ref = this.references[alias];
        const listable = refTable.GetListableColumn();

        if (ref && listable) {
            const listValue = ref[listable.Name];
            if (!TConfig.IsEmpty(listValue))
                return TCategoryHtml.getAlign(listable.Domain.Type.Category);
        }
        return TCategoryHtml.getAlign(column.Domain.Type.Category);
    }
}
