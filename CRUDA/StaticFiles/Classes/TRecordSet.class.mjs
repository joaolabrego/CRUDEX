"use strict"

import TRecord from "./TRecord.mjs"
export default class TRecordSet {
    #PageNumber = 1
    #RowNumber = 0
    #RowCount = 0
    #PageCount = 0
    #EOF = false
    #BOF = false
    #Records = []
    #DataSet = null

    constructor(dataSet, recordRows) {
        if (dataSet.ClassName !== "TDataSet")
            throw new Error("Argumento dataSet não é do tipo TDataSet.")

        this.#DataSet = dataSet
        recordRows.forEach(recordRow => this.#Records.push(new TRecord(this, recordRow)));
        this.GoTop();
    }
    async ReadPage(pageNumber = this.#PageNumber) {
        let parameters = {
            InputParams: {},
            OutputParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
                PaddingBrowseLastPage: TSystem.PaddingBrowseLastPage,
            },
        }
        this.#Table.Columns.filter(column => column.IsFilterable)
            .forEach(column => parameters.InputParams[column.Name] = column.FilterValue)

        let res = await TConfig.GetAPI(`${this.#Table.Database.Name}/${this.#Table.Name}/read`, parameters)

        this.#RowCount = res.Parameters.ReturnValue
        this.#PageNumber = res.Parameters.PageNumber
        this.#PageCount = res.Parameters.MaxPage
        this.#RecordSets = res.Tables[0]
        if (res.Parameters.ReturnValue && this.#RowNumber >= res.Parameters.ReturnValue)
            this.RowNumber = res.Parameters.ReturnValue - 1

        return this
    }
    async ReadRows(filterKeys) {
        let parameters = {
            InputParams: filterKeys,
            OutputParams: {},
            IOParams: {
                PageNumber: 0,
                LimitRows: 0,
                MaxPage: 0,
                PaddingBrowseLastPage: false,
            },
        }
        let response = await TConfig.GetAPI(`${this.#Table.Database.Name}/${this.#Table.Name}/read`, parameters)

        return response.Tables[0]
    }
    GoTop(){
        this.#RowNumber = 0
        this.#BOF = this.#EOF = this.#Data.length === 0
    }
    GoBottom() {
        if (this.#Records.length) {
            this.#RowNumber = this.#Records.length - 1
            this.#EOF = false
        }
    }
    GoPrior() {
        if (this.#BOF)
            throw new Error("Tentativa de ultrapassar início de recordset.")
        if (this.#BOF = --this.#RowNumber < 0)
            ++this.#RowNumber
    }
    GoNext(){
        if (this.#EOF)
            throw new Error("Tentativa de ultrapassar final de recordset.")
        if (this.#EOF = ++this.#RowNumber === this.#Data.length)
            --this.#RowNumber
    }
    get PageNumber() {
        return this.#PageNumber
    }
    get RowNumber() {
        return this.#RowNumber
    }
    get RowCount() {
        return this.#RowCount
    }
    get PageCount() {
        return this.#PageCount
    }
    get Count() {
        return this.#Records.length
    }
    get DataSet() {
        return this.#DataSet
    }
    get Record() {
        if (this.#EOF || this.#BOF)
            return null

        return this.#Records[this.#RowNumber]
    }
    get BOF() {
        return this.#BOF
    }
    get EOF() {
        return this.#EOF
    }
}