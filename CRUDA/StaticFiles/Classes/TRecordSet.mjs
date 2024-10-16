"use strict"

export default class TRecordSet {
    #Table = null
    #FilterValues = {}
    #RowCount = 0
    #PageNumber = 1
    #PageCount = 0
    #RowNumber = 0
    #Data = null
    #OrderBy = ""

    constructor(table) {
        if (grid.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Table = table
        this.#Table.Columns.filter(column => column.IsFilterable)
            .forEach(column => this.#FilterValues[column.Name] = null)
    }
    AddOrderBy(column, value) {

    }
    ClearFilters() {
        Object.keys(this.#FilterValues).forEach(key => this.#FilterValues[key] = null)
    }
    SaveFilters(record) {
        Object.keys(this.#FilterValues).forEach(key => this.#FilterValues[key] = record.hasOwnProperty(key) ? (TConfig.IsEmpty(record[key]) ? null : record[key]) : null)
    }
    IsFiltered() {
        for (let key in Object.keys(this.#FilterValues))
            if (this.#FilterValues[key] != null)
                return true

        return false;
    }
    async ReadPage(pageNumber) {
        let parameters = {
            DatabaseName: this.#Table.Database.Name,
            TableName: this.#Table.Name,
            Action: TActions.READ,
            InputParams: {
                LoginId: TLogin.LoginId,
                RecordFilter: JSON.stringify(this.#FilterValues),
                OrderBy: this.OrderBy,
                PaddingGridLastPage: TSystem.PaddingGridLastPage,
            },
            OutputParams: {},
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

        return result.DataSet.Table
    }

    get Table(){
        return this.#Table
    }
}