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
    static columnNameAsc = "[" + column.Name + "] ASC,"
    static columnNameDesc = "[" + column.Name + "] DESC,"

    constructor(table) {
        if (grid.ClassName !== "TTable")
            throw new Error("Argumento table não é do tipo TTable.")
        this.#Table = table
        this.#Table.Columns.filter(column => column.IsFilterable)
            .forEach(column => this.#FilterValues[column.Name] = null)
    }
    ClearOrderBy() {
        this.#OrderBy = ""
    }
    IsOrdered() {
        return this.#OrderBy.includes(columnNameAsc) ? false : this.#OrderBy.includes(columnNameDesc) ? true : null
    }
    ToggleOrdered() {
        let isOrdered = this.IsOrdered()

        if (TConfig.IsEmpty(isOrdered)) {
            this.#OrderBy += columnNameAsc
            isOrdered = false
        }
        else if (isOrdered === false) {
            this.#OrderBy = this.#OrderBy.replace(columnNameAsc, columnNameDesc)
            isOrdered = true
        }
        else {
            this.#OrderBy = this.#OrderBy.replace(columnNameDesc, "")
            isOrdered = null
        }

        return isOrdered
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
    get Primarykeys() {
        let primarykeys = {}

        this.#Table.Columns.filter(column => column.IsPrimarykey)
            .forEach(column => primarykeys[column.Name] = this.#DataPage[this.#RowNumber][column.Name])

        return primarykeys
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
        return this.#OrderBy
    }
}

}