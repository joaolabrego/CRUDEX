"use strict";

import TConfig from "./TConfig.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TList {
    static async fetchPage(table, { value = "", pageNumber = 1, limitRows = 5 } = {}) {
        const parameters = {
            DatabaseName: table.Database.Name,
            TableName: table.Name,
            Action: TSystem.Actions.LIST,
            InParams: {
                Value: value ?? "",
                PaddingGridLastPage: false,
            },
            OutParams: {},
            IOParams: {
                PageNumber: pageNumber,
                LimitRows: limitRows,
                MaxPage: 0,
            },
        };

        const result = await TConfig.GetAPI(TSystem.Actions.EXECUTE, parameters, false);

        return {
            items: result.DataSet?.Table ?? [],
            pageNumber: Number(result.Parameters?.PageNumber ?? pageNumber),
            pageCount: Number(result.Parameters?.MaxPage ?? 1),
            rowCount: Number(result.Parameters?.ReturnValue ?? 0),
        };
    }
}
