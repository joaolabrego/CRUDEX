"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TRecord from "./TRecord.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TTable from "./TTable.class.mjs";
import TTransaction from "./TTransaction.class.mjs";

export default class TRecordSet {
    #Table = null;
    #FixedFilter = {};
    #FilterValues = {};
    #SearchValues = {};
    #RowCount = 0;
    #PageNumber = 0;
    #PageCount = 0;
    #PageSize = 0;
    #AbsoluteRowIndex = -1;
    #OrderBy = "";
    #Records = [];

    constructor(table) {
        if (!(table instanceof TTable))
            throw new Error("Argumento table não é do tipo TTable.");
        this.#Table = table;
        table.Columns.filter(column => column.IsFilterable)
            .forEach(column => {
                this.#FilterValues[column.Name] = null;
                this.#SearchValues[column.Name] = null;
            });
    }

    #appendFilterValue(filter, key, value) {
        const filterValue = TCheckbox.toFilterValue(value);
        if (filterValue !== undefined)
            filter[key] = filterValue;
        else if (!TCheckbox.isIgnored(value) && !TConfig.IsEmpty(value))
            filter[key] = value;
    }

    async goPage(pageNumber = 1) {
        const filter = {};
        for (const [key, value] of Object.entries(this.#FilterValues))
            this.#appendFilterValue(filter, key, value);
        for (const [key, value] of Object.entries(this.#SearchValues))
            this.#appendFilterValue(filter, key, value);

        const parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TSystem.Actions.READ,
            InParams: {
                RecordFilter: JSON.stringify(filter),
                OrderBy: this.orderBy,
                PaddingGridLastPage: TSystem.PaddingGridLastPage,
                IsActionList: false,
            },
            OutParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
            },
        };

        const result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, parameters);
        const { main: mainRows, refs } = TConfig.ParseReadDataSet(result.DataSet);
        const refLookup = TRecordSet.#BuildRefLookup(refs);

        this.#RowCount = Number(result.Parameters?.ReturnValue ?? 0);
        this.#PageNumber = Number(result.Parameters?.PageNumber ?? pageNumber);
        this.#PageCount = Number(result.Parameters?.MaxPage ?? 0);
        this.#PageSize = mainRows.length;
        this.#Records = mainRows.map(row => new TRecord(this.#Table, row, refLookup));

        if (this.#AbsoluteRowIndex >= 0) {
            const pageStart = (this.#PageNumber - 1) * TSystem.RowsPerPage;
            if (this.#AbsoluteRowIndex < pageStart || this.#AbsoluteRowIndex >= pageStart + this.#Records.length)
                this.#AbsoluteRowIndex = this.#RowCount > 0 ? pageStart : -1;
        }

        return this.#Records;
    }

    async readOne(recordFilter) {
        const parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TSystem.Actions.READ,
            InParams: {
                RecordFilter: JSON.stringify(recordFilter),
                OrderBy: null,
                PaddingGridLastPage: false,
                IsActionList: false,
            },
            OutParams: {},
            IOParams: {
                PageNumber: 0,
                LimitRows: 0,
                MaxPage: 0,
            },
        };

        const result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, parameters);
        const { main, refs } = TConfig.ParseReadDataSet(result.DataSet);
        const refLookup = TRecordSet.#BuildRefLookup(refs);
        const row = main[0];

        return row ? new TRecord(this.#Table, row, refLookup) : null;
    }

    #executeParameters(action, inParams = {}, ioParams = {}, table = null) {
        const target = table ?? this.#Table;
        return {
            DatabaseName: target.Database.Name,
            TableName: target.Name,
            Action: action,
            InParams: inParams,
            OutParams: {},
            IOParams: ioParams,
        };
    }

    async #callExecute(parameters) {
        return await TConfig.GetAPI(TSystem.Actions.EXECUTE, parameters);
    }

    async saveRecord(formAction, actualRecord, lastRecord = null) {
        await TTransaction.save(this.#Table, formAction, actualRecord, lastRecord);
    }

    static #BuildRefLookup(refs) {
        const lookup = {};
        if (!refs)
            return lookup;

        for (const [name, rows] of Object.entries(refs)) {
            if (!Array.isArray(rows))
                continue;
            for (const row of rows) {
                const alias = row.ClassName ?? row.Kind ?? name;
                if (!lookup[alias])
                    lookup[alias] = new Map();
                if (row.Id !== undefined && row.Id !== null)
                    lookup[alias].set(row.Id, row);
            }
        }
        return lookup;
    }

    #LocalIndex() {
        if (this.#AbsoluteRowIndex < 0)
            return -1;
        return this.#AbsoluteRowIndex - (this.#PageNumber - 1) * TSystem.RowsPerPage;
    }

    async #EnsureRowIndex(absoluteIndex) {
        if (this.#RowCount === 0) {
            this.#AbsoluteRowIndex = -1;
            return;
        }
        if (absoluteIndex < 0) {
            this.#AbsoluteRowIndex = -1;
            return;
        }
        if (absoluteIndex >= this.#RowCount) {
            this.#AbsoluteRowIndex = this.#RowCount;
            return;
        }
        const page = Math.floor(absoluteIndex / TSystem.RowsPerPage) + 1;
        if (page !== this.#PageNumber || this.#Records.length === 0)
            await this.goPage(page);
        this.#AbsoluteRowIndex = absoluteIndex;
    }

    async goTop() {
        if (this.#RowCount === 0) {
            this.#AbsoluteRowIndex = -1;
            return null;
        }
        await this.#EnsureRowIndex(0);
        return this.record;
    }

    async goBottom() {
        if (this.#RowCount === 0) {
            this.#AbsoluteRowIndex = -1;
            return null;
        }
        await this.#EnsureRowIndex(this.#RowCount - 1);
        return this.record;
    }

    async goRow(rowNumber) {
        await this.#EnsureRowIndex(rowNumber - 1);
        return this.record;
    }

    async nextRow() {
        await this.#EnsureRowIndex(this.#AbsoluteRowIndex + 1);
        return this.record;
    }

    async priorRow() {
        await this.#EnsureRowIndex(this.#AbsoluteRowIndex - 1);
        return this.record;
    }

    clearFilters() {
        for (const key of Object.keys(this.#FilterValues))
            this.#FilterValues[key] = this.#FixedFilter[key] ?? null;
    }

    clearSearch() {
        for (const key of Object.keys(this.#SearchValues))
            this.#SearchValues[key] = null;
    }

    setFilter(record) {
        for (const key of Object.keys(this.#FilterValues))
            this.#FilterValues[key] = Object.hasOwn(record, key) ? record[key] : null;
    }

    setSearch(record) {
        for (const key of Object.keys(this.#SearchValues))
            this.#SearchValues[key] = Object.hasOwn(record, key) ? record[key] : null;
    }

    setFixedFilter(record) {
        this.#FixedFilter = { ...record };
    }

    isFiltered() {
        return Object.keys(this.#FilterValues).some(key => {
            if (Object.hasOwn(this.#FixedFilter, key))
                return false;
            const value = this.#FilterValues[key];
            return TCheckbox.hasCondition(value) || !TConfig.IsEmpty(value);
        });
    }

    isSearched() {
        return Object.keys(this.#SearchValues).some(key => {
            const value = this.#SearchValues[key];
            return TCheckbox.hasCondition(value) || !TConfig.IsEmpty(value);
        });
    }

    clearOrderBy() {
        this.#OrderBy = "";
    }

    setOrderByRaw(orderBy) {
        this.#OrderBy = orderBy ?? "";
    }

    toggleOrderDirection(column) {
        const ascending = `[${column.Name}] ASC,`;
        const descending = `[${column.Name}] DESC,`;
        let orderDirection = this.#OrderBy.includes(ascending)
            ? false
            : this.#OrderBy.includes(descending)
                ? true
                : null;

        if (orderDirection === null) {
            this.#OrderBy += ascending;
            orderDirection = false;
        } else if (orderDirection === false) {
            this.#OrderBy = this.#OrderBy.replace(ascending, descending);
            orderDirection = true;
        } else {
            this.#OrderBy = this.#OrderBy.replace(descending, "");
            orderDirection = null;
        }

        return orderDirection;
    }

    BOF() {
        return this.#AbsoluteRowIndex < 0;
    }

    EOF() {
        return this.#RowCount === 0 || this.#AbsoluteRowIndex >= this.#RowCount;
    }

    get orderBy() {
        return this.#OrderBy.endsWith(",") ? this.#OrderBy.slice(0, -1) : this.#OrderBy;
    }

    get Table() {
        return this.#Table;
    }

    get record() {
        if (this.BOF() || this.EOF())
            return null;
        const local = this.#LocalIndex();
        return local >= 0 && local < this.#Records.length ? this.#Records[local] : null;
    }

    get records() {
        return this.#Records;
    }

    get rowCount() {
        return this.#RowCount;
    }

    get pageNumber() {
        return this.#PageNumber;
    }

    get pageCount() {
        return this.#PageCount;
    }

    get rowNumber() {
        if (this.BOF())
            return 0;
        if (this.EOF())
            return this.#RowCount + 1;
        return this.#AbsoluteRowIndex + 1;
    }
}
