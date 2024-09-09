"use strict"

import TActions from "./TActions.class.mjs"
import TConfig from "./TConfig.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TTablePage {
    #PageNumber = 1
    #RowNumber = 0
    #RowCount = 0
    #PageCount = 0

    #Data = null
    #Table = null
    constructor(nameOrAliasOrId, tableName) {
        let database = TSystem.GetDatabase(nameOrAliasOrId)

        if (database === null)
            throw new Error("Banco-de-dados não encontrado.")
        this.#Table = database.GetTable(tableName)
        if (this.#Table === null)
            throw new Error("Tabela de banco-de-dados não encontrada.")
    }
    async Read(pageNumber = this.#PageNumber) {
        let parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TActions.READ,
            InputParams: {},
            OutputParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
                PaddingBrowseLastPage: TSystem.PaddingBrowseLastPage,
            },
        }
        this.#Columns.filter(column => column.IsFilterable)
            .forEach(column => parameters.InputParams[column.Name] = column.FilterValue)

        let res = await TConfig.GetAPI(TActions.EXECUTE, parameters)

        this.#RowCount = res.Parameters.ReturnValue
        this.#PageNumber = res.Parameters.PageNumber
        this.#PageCount = res.Parameters.MaxPage
        this.#Recordset = res.Tables[0]
        if (res.Parameters.ReturnValue && this.#RowNumber >= res.Parameters.ReturnValue)
            this.RowNumber = res.Parameters.ReturnValue - 1

        return this
    }
    Primarykeys() {
        let primarykeys = {}

        this.#Columns.filter(column => column.IsPrimarykey)
            .forEach(primarykey => primarykeys[primarykey.Name] = this.#Recordset[this.#RowNumber][primarykey.Name])

        return primarykeys
    }
    get Row() {
        return this.#Recordset[this.#RowNumber]
    }
    get RowCount() {
        return this.#RowCount
    }
    get PageNumber() {
        return this.#PageNumber
    }
    set RowNumber(value) {
        this.#RowNumber = value
        this.MoveValues()
    }
    get RowNumber() {
        return this.#RowNumber
    }
    get PageCount() {
        return this.#PageCount
    }
}