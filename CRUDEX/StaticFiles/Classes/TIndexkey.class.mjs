"use strict";

import TConfig from "./TConfig.class.mjs";
export default class TIndexkey {
    #Index = null;
    constructor(index, rowIndexkey) {
        if (index.ClassName !== "TIndex")
            throw new Error("Argumento index não é do tipo TIndex.");
        if (rowIndexkey.ClassName !== "Indexkey")
            throw new Error("Argumento rowIndexkey não é do tipo Indexkey.");
        TConfig.CreateProperties(rowIndexkey, this);
        this.#Index = index;
    }
    get Index() {
        return this.#Index;
    }
}