"use strict";

import TSystem from "./TSystem.class.mjs";
import TConfig from "./TConfig.class.mjs";
export default class TType {
    #Category = null;
    constructor(rowType) {
        if (rowType.Kind !== "Type")
            throw new Error("Argumento rowType não é do tipo Type.");
        TConfig.CreateProperties(rowType, this);
        this.#Category = TSystem.GetCategory(rowType.CategoryId);
    }
    get Category() {
        return this.#Category;
    }
}