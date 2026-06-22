"use strict";

import TSystem from "./TSystem.class.mjs";

export default class TListValues {
    #data = [];
    #filtered = [];
    #records = [];
    #rowCount = 0;
    #pageNumber = 0;
    #pageCount = 0;
    #pageSize = 5;
    #absoluteRowIndex = -1;
    #searchValue = "";

    constructor(values, options = {}) {
        const separator = options.separator ?? ";";
        this.#pageSize = options.rowsPerPage ?? options.limitRows ?? TSystem.RowsPerDropdownPage;
        this.#data = TListValues.#parseValues(values, separator);
    }

    static #parseValues(values, separator) {
        if (values == null)
            return [];
        if (Array.isArray(values))
            return values.map(part => String(part).trim()).filter(part => part.length > 0);
        return String(values).split(separator)
            .map(part => part.trim())
            .filter(part => part.length > 0);
    }

    static #toPickerItem(value) {
        return {
            ListItemId: value,
            ListItemName: value,
        };
    }

    #applyFilter(value) {
        const needle = String(value ?? "").trim().toLowerCase();
        this.#searchValue = value ?? "";
        this.#filtered = needle
            ? this.#data.filter(item => item.toLowerCase().includes(needle))
            : [...this.#data];
        this.#rowCount = this.#filtered.length;
    }

    readPickerPage({ value = "", pageNumber = 1, limitRows = null, paddingGridLastPage = true } = {}) {
        const pageSize = limitRows ?? this.#pageSize;
        this.#pageSize = pageSize;
        this.#applyFilter(value);

        this.#pageCount = this.#rowCount === 0 ? 0 : Math.ceil(this.#rowCount / pageSize);
        const maxPage = Math.max(1, this.#pageCount);
        const page = Math.min(Math.max(1, pageNumber), maxPage);
        let start = (page - 1) * pageSize;
        if (paddingGridLastPage && start + pageSize > this.#rowCount)
            start = this.#rowCount > pageSize ? this.#rowCount - pageSize : 0;
        const slice = this.#filtered.slice(start, start + pageSize);

        this.#pageNumber = this.#rowCount === 0 ? 1 : page;
        this.#records = slice.map(item => TListValues.#toPickerItem(item));
        this.#absoluteRowIndex = -1;

        return this;
    }

    goPage(pageNumber = 1) {
        return this.readPickerPage({
            value: this.#searchValue,
            pageNumber,
            limitRows: this.#pageSize,
        });
    }

    static async readPickerPage(values, { value = "", pageNumber = 1, limitRows = TSystem.RowsPerDropdownPage, separator = ";", paddingGridLastPage = true } = {}) {
        const listValues = new TListValues(values, { separator, rowsPerPage: limitRows });
        listValues.readPickerPage({ value, pageNumber, limitRows, paddingGridLastPage });
        return {
            items: listValues.records,
            records: listValues.records,
            listValues,
            recordSet: listValues,
            pageNumber: listValues.pageNumber,
            pageCount: listValues.pageCount,
            rowCount: listValues.rowCount,
        };
    }

    #localIndex() {
        if (this.#absoluteRowIndex < 0)
            return -1;
        return this.#absoluteRowIndex - (this.#pageNumber - 1) * this.#pageSize;
    }

    #ensureRowIndex(absoluteIndex) {
        if (this.#rowCount === 0) {
            this.#absoluteRowIndex = -1;
            return;
        }
        if (absoluteIndex < 0) {
            this.#absoluteRowIndex = -1;
            return;
        }
        if (absoluteIndex >= this.#rowCount) {
            this.#absoluteRowIndex = this.#rowCount;
            return;
        }
        const page = Math.floor(absoluteIndex / this.#pageSize) + 1;
        if (page !== this.#pageNumber || this.#records.length === 0)
            this.readPickerPage({ value: this.#searchValue, pageNumber: page, limitRows: this.#pageSize });
        this.#absoluteRowIndex = absoluteIndex;
    }

    goTop() {
        this.#ensureRowIndex(0);
    }

    goBottom() {
        this.#ensureRowIndex(this.#rowCount - 1);
    }

    nextRow() {
        this.#ensureRowIndex(this.#absoluteRowIndex < 0 ? 0 : this.#absoluteRowIndex + 1);
    }

    priorRow() {
        this.#ensureRowIndex(this.#absoluteRowIndex < 0 ? 0 : this.#absoluteRowIndex - 1);
    }

    goRow(absoluteIndex) {
        this.#ensureRowIndex(absoluteIndex);
    }

    BOF() {
        return this.#absoluteRowIndex < 0;
    }

    EOF() {
        return this.#rowCount === 0 || this.#absoluteRowIndex >= this.#rowCount;
    }

    get data() {
        return [...this.#data];
    }

    get record() {
        if (this.BOF() || this.EOF())
            return null;
        const local = this.#localIndex();
        return local >= 0 && local < this.#records.length ? this.#records[local] : null;
    }

    get records() {
        return this.#records;
    }

    get rowCount() {
        return this.#rowCount;
    }

    get pageNumber() {
        return this.#pageNumber;
    }

    get pageCount() {
        return this.#pageCount;
    }

    get rowNumber() {
        if (this.BOF())
            return 0;
        if (this.EOF())
            return this.#rowCount + 1;
        return this.#absoluteRowIndex + 1;
    }
}
