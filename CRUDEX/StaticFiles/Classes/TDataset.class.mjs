﻿"use strict"

import TRecord from "./TRecord.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TRecordSet {
    #Table = null
    #FixedFilter = {}
    #FilterValues = {}
    #RowCount = 0
    #PageNumber = 1
    #PageCount = 0
    #RowNumber = 0
    #OrderBy = ""
    #Data = []
    #References = {}
    constructor(table) {
        if (table.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Table = table
        this.#Table.Columns.filter(column => column.IsFilterable)
            .forEach(column => this.#FilterValues[column.Name] = null)
    }
    async #ReadPage(pageNumber) {
        let parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TActions.READ,
            InParams: {
                LoginId: TLogin.LoginId,
                RecordFilter: JSON.stringify(this.#FilterValues),
                OrderBy: this.OrderBy,
                PaddingGridLastPage: TSystem.PaddingGridLastPage,
            },
            OutParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
            },
        }

        let result = await TConfig.GetAPI(TActions.EXECUTE, parameters)

        this.#RowCount = result.Parameters.ReturnValue
        this.#PageNumber = result.Parameters.PageNumber
        this.#PageCount = result.Parameters.MaxPage
        if (result.Parameters.ReturnValue && this.#RowNumber >= result.Parameters.ReturnValue)
            this.#RowNumber = result.Parameters.ReturnValue - 1
        this.#References.length = 0

        Object.entries(result.DataSet).forEach(([, data], index) => {
            if (index) {
                data.forEach(datarow => {
                    let table = TSystem.GetTable(dataRow.ClassName),
                        record = new TRecord(this, datarow)

                    if (this.this.#References[table.Alias] === undefined)
                        this.this.#References[table.Alias] = []
                    this.this.#References[table.Alias].push(record)
                });
            }
        });
        globalThis.$ = new Proxy(this.#Table, {
            get: (target, key) => {
                const getColumn = (table, columnName) => {
                    let column = table.GetColumn(columnName)

                    if (column)
                        return column
                    if (table.ParentTableId)
                        return getColumn(TSystem.GetTable(table.ParentTableId), columnName)
                    throw new Error(`Nome de coluna '${columnName}' não existe.`)
                }

                return getColumn(target, key).Value
            },
            set: (target, key, value) => {
                let column = target.GetColumn(key)

                return column.Value = value
            }
        })


        return this.#Data = result.DataSet.Table
    }
    GetReferenceRow(tableId, valueId) {
        return this.#References[tableId].find(referenceRow => referenceRow.Id === valueId)
    }
    GoTop() {
        if (this.#PageNumber > 1)
            this.#ReadPage(1)
        this.RowNumber = this.#RowCount ? 1 : -1
    }
    GoNext() {
        this.#RowNumber++
        if (this.#RowNumber === this.#RowCount)
            this.GoTop()
        else if (this.#RowNumber === this.#Data.length) {
            this.#ReadPage(this.#PageNumber < this.#PageCount ? this.#PageNumber + 1 : 1)
            this.#RowNumber = 0
        }
        else
            ++this.#RowNumber

        return this.#RowNumber
    }
    GoBottom() {
        if (this.)
    }
    GoPrior() {
        if (this.#RowNumber === 0) {
            this.ReadPage(this.#PageNumber > 1 ? this.#PageNumber - 1 : this.#PageCount)
            this.#RowNumber = TSystem.RowsPerPage - 1
        }
        else
            --this.#RowNumber

        return this.#RowNumber
    }
    GoLastRow() {
        --this.#RowNumber
    }
    ClearOrderBy() {
        this.#OrderBy = ""
    }
    ToggleOrderDirection(column) {
        let ascendingColumnName = "[" + column.Name + "] ASC,",
            descendingColumnName = "[" + column.Name + "] DESC,",
            orderDirection = this.#OrderBy.includes(ascendingColumnName) ? false : this.#OrderBy.includes(descendingColumnName) ? true : null

        if (TConfig.IsEmpty(orderDirection)) {
            this.#OrderBy += ascendingColumnName
            orderDirection = false
        }
        else if (orderDirection === false) {
            this.#OrderBy = this.#OrderBy.replace(ascendingColumnName, descendingColumnName)
            orderDirection = true
        }
        else {
            this.#OrderBy = this.#OrderBy.replace(descendingColumnName, "")
            orderDirection = null
        }

        return orderDirection
    }
    ClearFilters() {
        Object.keys(this.#FilterValues).forEach(key => { this.#FilterValues[key] = this.#FixedFilter.hasOwnProperty(key) ? this.#FixedFilter[key] : null })
    }
    SaveFilters(record) {
        Object.keys(this.#FilterValues).forEach(key => { this.#FilterValues[key] = record.hasOwnProperty(key) ? record[key] : null })
    }
    IsFiltered() {
        for (let key in Object.keys(this.#FilterValues))
            if (!(this.#FixedFilter.hasOwnProperty(key) || this.#FilterValues[key] === null))
                return true

        return false;
    }
    async ReadRow(databaseName, tableName) {
        let parameters = {
            DatabaseName: databaseName,
            TableName: tableName,
            Action: TActions.READ,
            InParams: {
                LoginId: TLogin.LoginId,
                RecordFilter: JSON.stringify(this.Primarykeys),
                OrderBy: null,
                PaddingGridLastPage: false,
            },
            OutParams: {},
            IOParams: {
                PageNumber: 0,
                LimitRows: 0,
                MaxPage: 0,
            },
        }

        return (await TConfig.GetAPI(TActions.EXECUTE, parameters)).DataSet.Table[0]
    }
    get BOF() {
        return this.RowNumber < 0
    }
    get EOF() {
        return this.RowNumber > this.#RowCount
    }
    get OrderBy() {
        return this.#OrderBy.slice(0, -1)
    }
    get Filter() {
        var filter = ""

        for (let key in this.#FilterValues) {
            let value = this.#FilterValues[key]

            if (value !== null)
                filter += `${(filter === "" ? "" : " AND ")}${key} = '${value}'`
        }

        return filter;
    }
    get Table() {
        return this.#Table
    }
    get Record() {
        return this.#Data[this.#RowNumber]
    }
    get RowCount() {
        return this.#RowCount
    }
    get PageNumber() {
        return this.#PageNumber
    }
    get PageCount() {
        return this.#PageCount
    }
    get RowNumber() {
        return this.#RowNumber
    }
    get Data() {
        return this.#Data
    }
    get OrderBy() {
        return this.#OrderBy.slice(0, -1)
    }
}