"use strict"

import TActions from "./TActions.class.mjs"
import TConfig from "./TConfig.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TTable {
    #Id = 0
    #Name = ""
    #Alias = ""
    #Description = ""
    #ParentTableId = 0
    #IsPaged = false
    #LastId = 0

    #PageNumber = 1
    #RowNumber = 0
    #RowCount = 0
    #PageCount = 0

    #Database = null
    #Recordset = null
    #DataSet = null
    #ParentTable = null
    #Columns = []
    #Indexes = []

    constructor(database, rowTable) {
        if (database.ClassName !== "TDatabase")
            throw new Error("Argumento database não é do tipo TDatabase.")
        if (rowTable.ClassName !== "RecordTable")
            throw new Error("Argumento rowTable não é do tipo Table.")
        this.#Id = rowTable.Id
        this.#Name = rowTable.Name
        this.#Alias = rowTable.Alias
        this.#Description = rowTable.Description
        this.#ParentTableId = rowTable.ParentTableId
        this.#IsPaged = rowTable.IsPaged
        this.#LastId = rowTable.LastId
        this.#Database = database
    }
    AddColumn(column) {
        if (column.ClassName !== "TColumn")
            throw new Error("Argumento column não é do tipo TColumn.")
        this.#Columns.push(column)
    }
    AddIndex(index) {
        if (index.ClassName !== "TIndex")
            throw new Error("Argumento index não é do tipo TIndex.")
        this.#Indexes.push(index)
    }
    MoveValues(row = this.#Recordset[this.#RowNumber]) {
        this.#Columns.forEach(column => column.LastValue = column.Value = row[column.Name])
    }
    ClearValues(withDefaultValues = true) {
        this.#Columns.forEach(column => column.LastValue = column.Value = (column.Domain.Default && withDefaultValues ? eval(column.Domain.Default) : null))
    }
    RestoreValues() {
        this.#Columns.forEach(column => column.Value = column.LastValue)
    }
    MoveFilters() {
        this.#Columns.forEach(column => column.LastValue = column.Value = column.FilterValue)
    }
    ClearFilters() {
        this.#Columns.forEach(column => column.FilterValue = null)
    }
    RestoreFilters() {
        this.#Columns.forEach(column => column.FilterValue = column.LastValue)
    }
    SaveFilters() {
        this.#Columns.forEach(column => column.FilterValue = TConfig.IsEmpty(column.FilterValue) ? null : column.Value)
    }
    async ReadTablePage(pageNumber = this.#PageNumber) {
        let parameters = {
            DatabaseName: this.#Database.Name,
            TableName: this.#Name,
            Action: TActions.READ,
            InputParams: {},
            OutputParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: TSystem.RowsPerPage,
                MaxPage: 0,
                PaddingGridLastPage: TSystem.PaddingGridLastPage,
            },
        }
        this.#Columns.filter(column => column.IsFilterable)
            .forEach(column => parameters.InputParams[column.Name] = column.FilterValue)
        parameters.InputParams = {
            UserName: TLogin.UserName,
            Record: JSON.stringify(parameters.InputParams),
        }
        let res = await TConfig.GetAPI(TActions.EXECUTE, parameters)

        this.#RowCount = res.Parameters.ReturnValue
        this.#PageNumber = res.Parameters.PageNumber
        this.#PageCount = res.Parameters.MaxPage
        this.#Recordset = res.Tables[0]
        if (res.Parameters.ReturnValue && this.#RowNumber >= res.Parameters.ReturnValue)
            this.RowNumber = res.Parameters.ReturnValue - 1

        return this
    }
    async ReadTableRows(filterKeys) {
        let parameters = {
            InputParams: filterKeys,
            OutputParams: {},
            IOParams: {
                PageNumber: 0,
                LimitRows: 0,
                MaxPage: 0,
                PaddingGridLastPage: false,
            },
        }
        let response = await TConfig.GetAPI(`${this.#Database.Name}/${this.#Name}/read`, parameters)

        return response.Tables[0]
    }
    GetColumn(columnname) {
        return this.#Columns.find(column => column.Name === columnname)
    }
    Primarykeys() {
        let primarykeys = {}

        this.#Columns.filter(column => column.IsPrimarykey)
            .forEach(primarykey => primarykeys[primarykey.Name] = this.#Recordset[this.#RowNumber][primarykey.Name])

        return primarykeys
    }
    get Id() {
        return this.#Id
    }
    get Name() {
        return this.#Name
    }
    get Description() {
        return this.#Description
    }
    get Alias() {
        return this.#Alias
    }
    get ParentTableId() {
        return this.#ParentTableId
    }
    set ParentTableId(value) {
        this.#ParentTableId = value
        this.#ParentTableId = value ? TSystem.GetTable(value) : null
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
    get Columns() {
        return this.#Columns
    }
    get Database() {
        return this.#Database
    }
    get Recordset() {
        return this.#Recordset
    }
    get IsPaged(){
        return this.#IsPaged
    }
    get LastId(){
        return this.#LastId
    }
}