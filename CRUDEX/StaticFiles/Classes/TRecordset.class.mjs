"use strict";

import TDataset from "./TDataset.class.mjs";
import TField from "./TField.class.mjs";
import TRecord from "./TRecord.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TRecordset {
    #Dataset = null;
    #FixedFilter = {};
    #FilterValues = {};
    #Data = [];
    #References = {};
    constructor(dataset) {
        if (!dataset instanceof TDataset)
            throw new Error("Argumento dataset não é do tipo TDataset.");
        this.#Dataset = dataset;
        this.#Table.Columns.filter(column => column.IsFilterable)
            .forEach(column => this.#FilterValues[column.Name] = null);
    }
}