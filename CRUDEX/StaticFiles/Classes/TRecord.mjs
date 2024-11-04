"use strict"

import TSystem from "./TSystem.class.mjs"

export default class TRecord {
    #Column = null
    #Data = null
    #Recordset = null
    constructor(recordset, record) {
        if (recordset.ClassName !== "TRecordSet")
            throw new Error("Argumento recordset não é do tipo TRecordset.")
        if (record === null)
            throw new Error("Argumento record é requerido.")
        if (record.ClassName === 'undefined')
            throw new Error("Propriedade ClassName do argumento record é indefinida.")
        this.#Recordset = recordset
        this.#Column = 
        this.#Data = record
    }
}