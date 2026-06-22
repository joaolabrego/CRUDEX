"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TCondition from "./TCondition.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TRecord from "./TRecord.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TTable from "./TTable.class.mjs";
import TTransaction from "./TTransaction.class.mjs";

export default class TRecordSet {
    #Table = null;
    #Filter = new Map();
    #tableFilterKeys = new Set();
    #filterableKeys = [];
    #Search = new Map();
    #RowCount = 0;
    #PageNumber = 0;
    #PageCount = 0;
    #PageSize = 0;
    #AbsoluteRowIndex = -1;
    #OrderBy = "";
    #Records = [];
    #showSpinner = true;
    #rowsPerPage = 0;

    constructor(table, options = {}) {
        if (!(table instanceof TTable))
            throw new Error("Argumento table não é do tipo TTable.");
        this.#Table = table;
        this.#showSpinner = options.showSpinner !== false;
        this.#rowsPerPage = options.rowsPerPage ?? TSystem.RowsPerPage;
        this.#filterableKeys = table.Columns.filter(column => column.IsFilterable).map(column => column.Name);
        if (options.tableFilter)
            this.setTableFilter(options.tableFilter);
    }

    #setCriterion(map, key, value) {
        const normalized = this.#normalizeCriterionValue(value);
        if (TCondition.willApplyFilter(normalized))
            map.set(key, normalized);
        else
            map.delete(key);
    }

    #appendFilterValue(filter, key, value) {
        if (TCheckbox.hasCondition(value)) {
            const filterValue = TCheckbox.toFilterValue(value);
            if (filterValue !== undefined)
                filter[key] = filterValue;
            return;
        }
        const stored = TCondition.normalizeStoredFilter(value);
        const filterValue = TCondition.toFilterPayload(stored);
        if (filterValue !== undefined)
            filter[key] = filterValue;
    }

    #buildPayload(map) {
        const payload = {};

        for (const [key, value] of map)
            this.#appendFilterValue(payload, key, value);

        return payload;
    }

    #readParameters(inParams, ioParams) {
        return {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TSystem.Actions.READ,
            InParams: inParams,
            OutParams: {},
            IOParams: ioParams,
        };
    }

    #applyPageResult(result, pageNumber) {
        const { main: mainRows, refs } = TConfig.ParseReadDataSet(result.DataSet);
        const refLookup = TRecordSet.#BuildRefLookup(refs);

        this.#RowCount = Number(result.Parameters?.ReturnValue ?? 0);
        this.#PageNumber = Number(result.Parameters?.PageNumber ?? pageNumber);
        this.#PageCount = Number(result.Parameters?.MaxPage ?? 0);
        this.#PageSize = mainRows.length;
        this.#Records = mainRows.map(row => new TRecord(this.#Table, row, refLookup));

        return mainRows;
    }

    async goPage(pageNumber = 1) {
        const result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, this.#readParameters({
            Filter: JSON.stringify(this.#buildPayload(this.#Filter)),
            Search: JSON.stringify(this.#buildPayload(this.#Search)),
            OrderBy: this.orderBy,
            PaddingGridLastPage: TSystem.PaddingGridLastPage,
            IsActionList: false,
        }, {
            PageNumber: pageNumber,
            LimitRows: this.#rowsPerPage,
            MaxPage: 0,
        }), this.#showSpinner);

        this.#applyPageResult(result, pageNumber);

        if (this.#AbsoluteRowIndex >= 0) {
            const pageStart = (this.#PageNumber - 1) * this.#rowsPerPage;
            if (this.#AbsoluteRowIndex < pageStart || this.#AbsoluteRowIndex >= pageStart + this.#Records.length)
                this.#AbsoluteRowIndex = this.#RowCount > 0 ? pageStart : -1;
        }

        return this.#Records;
    }

    static #toPickerItem(table, record) {
        const listable = table.GetListableColumn();
        const label = listable
            ? record.getBrowseValue(listable)
            : (record.ListItemValue ?? record.Name ?? TSystem.GetPrimaryKeyScalar(record, table));
        return {
            ListItemId: TSystem.GetPrimaryKeyScalar(record, table),
            ListItemName: label,
            record,
        };
    }

    async readPickerPage({ value = "", pageNumber = 1, limitRows = null } = {}) {
        const pageSize = limitRows ?? this.#rowsPerPage;
        const listable = this.#Table.GetListableColumn();
        const result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, this.#readParameters({
            Filter: JSON.stringify({ Picker: { Value: value ?? "" } }),
            Search: "{}",
            OrderBy: listable ? `[${listable.Name}]` : "",
            PaddingGridLastPage: true,
            IsActionList: true,
        }, {
            PageNumber: pageNumber,
            LimitRows: pageSize,
            MaxPage: 0,
        }), this.#showSpinner);

        this.#applyPageResult(result, pageNumber);
        this.#AbsoluteRowIndex = -1;

        return this;
    }

    static async readPickerPage(table, { value = "", pageNumber = 1, limitRows = TSystem.RowsPerDropdownPage, showSpinner = false } = {}) {
        const recordSet = new TRecordSet(table, { showSpinner, rowsPerPage: limitRows });
        await recordSet.readPickerPage({ value, pageNumber, limitRows });
        return {
            items: recordSet.records.map(record => TRecordSet.#toPickerItem(table, record)),
            records: recordSet.records,
            recordSet,
            pageNumber: recordSet.pageNumber,
            pageCount: recordSet.pageCount,
            rowCount: recordSet.rowCount,
        };
    }

    async readOne(recordFilter) {
        const result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, this.#readParameters({
            Filter: JSON.stringify(recordFilter ?? {}),
            Search: "{}",
            OrderBy: null,
            PaddingGridLastPage: false,
            IsActionList: false,
        }, {
            PageNumber: 0,
            LimitRows: 0,
            MaxPage: 0,
        }), this.#showSpinner);

        const { main, refs } = TConfig.ParseReadDataSet(result.DataSet);
        const refLookup = TRecordSet.#BuildRefLookup(refs);
        const row = main[0];

        return row ? new TRecord(this.#Table, row, refLookup) : null;
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
                const refTable = TSystem.GetTable(alias);
                const key = refTable
                    ? TSystem.GetPrimaryKeyScalar(row, refTable)
                    : (row.Id ?? null);
                if (key !== undefined && key !== null)
                    lookup[alias].set(key, row);
            }
        }
        return lookup;
    }

    #LocalIndex() {
        if (this.#AbsoluteRowIndex < 0)
            return -1;
        return this.#AbsoluteRowIndex - (this.#PageNumber - 1) * this.#rowsPerPage;
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
        const page = Math.floor(absoluteIndex / this.#rowsPerPage) + 1;
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

    #normalizeCriterionValue(value) {
        if (typeof value === "object" && value !== null
            && !TCheckbox.hasCondition(value) && !TCondition.isCriterion(value))
            return undefined;
        if (TCheckbox.hasCondition(value))
            return value;
        return TCondition.normalizeStoredFilter(value);
    }

    #updateCriteria(map, record, { removeMissing = false, skipTableKeys = false } = {}) {
        for (const key of this.#filterableKeys) {
            if (skipTableKeys && this.#tableFilterKeys.has(key))
                continue;
            if (!Object.hasOwn(record, key)) {
                if (removeMissing)
                    map.delete(key);
                continue;
            }
            this.#setCriterion(map, key, record[key]);
        }
    }

    clearFilters() {
        for (const key of this.#Filter.keys()) {
            if (!this.#tableFilterKeys.has(key))
                this.#Filter.delete(key);
        }
    }

    clearSearch() {
        TConfig.ClearObject(this.#Search);
    }

    saveFilter(record) {
        this.#updateCriteria(this.#Filter, record, { skipTableKeys: true });
    }

    saveSearch(record) {
        this.#updateCriteria(this.#Search, record);
    }

    setFilter(record) {
        this.#updateCriteria(this.#Filter, record, { removeMissing: true, skipTableKeys: true });
    }

    setSearch(record) {
        this.#updateCriteria(this.#Search, record, { removeMissing: true });
    }

    setTableFilter(record) {
        for (const key of this.#tableFilterKeys)
            this.#Filter.delete(key);
        this.#tableFilterKeys.clear();

        for (const [key, value] of Object.entries(record ?? {})) {
            this.#tableFilterKeys.add(key);
            this.#Filter.set(key, value);
        }
    }

    isFiltered() {
        return this.#filterableKeys.some(key => {
            if (this.#tableFilterKeys.has(key))
                return false;
            return TCondition.willApplyFilter(this.#Filter.get(key));
        });
    }

    isSearched() {
        return this.#filterableKeys.some(key =>
            TCondition.willApplyFilter(this.#Search.get(key)));
    }

    isTableFilterKey(key) {
        return this.#tableFilterKeys.has(key);
    }

    #orderByClause(column, direction) {
        return `[${column.Name}] ${direction},`;
    }

    getColumnOrder(column) {
        if (this.#OrderBy.includes(this.#orderByClause(column, "ASC")))
            return false;
        if (this.#OrderBy.includes(this.#orderByClause(column, "DESC")))
            return true;
        return null;
    }

    clearOrderBy() {
        this.#OrderBy = "";
    }

    setOrderByRaw(orderBy) {
        this.#OrderBy = orderBy ?? "";
    }

    toggleOrderDirection(column) {
        const ascending = this.#orderByClause(column, "ASC");
        const descending = this.#orderByClause(column, "DESC");
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

    get Filter() {
        return this.#Filter;
    }

    get Search() {
        return this.#Search;
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
