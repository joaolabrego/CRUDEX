"use strict";

import TConfig from "./TConfig.class.mjs";
import TDatabase from "./TDatabase.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TColumn from "./TColumn.class.mjs";
import TIndex from "./TIndex.class.mjs";

export default class TTable {
    #Database = null;
    #Columns = [];
    #Indexes = [];
    #References = [];

    constructor(database, rowTable) {
        if (!database instanceof TDatabase)
            throw new Error("Argumento database não é do tipo TDatabase.");
        if (rowTable.Kind !== "Table")
            throw new Error("Argumento rowTable não é do tipo Table.");
        TConfig.CreateProperties(rowTable, this);
        this.#Database = database;
    }
    AddColumn(column) {
        if (!column instanceof TColumn)
            throw new Error("Argumento column não é do tipo TColumn.");
        this.#Columns.push(column);
    }
    GetColumn(columnNameOrAliasOrId) {
        if (typeof columnName === "string")
            return this.#Columns.find(column => column.Name === columnNameOrId || column.Alias === columnNameOrAliasOrId);

        return this.#Columns.find(column => column.Id === columnNameOrId);
    }
    AddIndex(index) {
        if (!index  instanceof TIndex)
            throw new Error("Argumento index não é do tipo TIndex.");
        this.#Indexes.push(index);
    }
    GetColumn(indexNameOrId) {
        if (typeof indexNameOrId === "string")
            return this.#Indexes.find(index => index.Name === indexNameOrId);

        return this.#Indexes.find(index => index.Id === indexNameOrId);
    }
    GetListableColumn() {
        return this.#Columns.find(column => column.IsListable);
    }
    get Columns() {
        return this.#Columns;
    }
    get References() {
        if (this.#References === null) {
            this.#References = [];
            this.#Columns.filter(column => !TConfig.IsEmpty(column.ReferenceTableId))
                .forEach(column => {
                    this.#References.push(TSystem.GetTable(column.ReferenceTableId));
                });
        }

        return this.#References;
    }
    get Database() {
        return this.#Database;
    }
}