"use strict";

export default class TField {
    #Column = null;
    #LastValue = null;
    #Value = null;
    #Reference = null;
    constructor(column, value) {
        if (column.ClassName !== "TColumm")
            throw new Error("Argumento column n�o � do tipo TColumn.");
        this.#Column = column;
        this.#LastValue = this.#Value = value;
    }
    Reset() {
        this.#Value = this.#LastValue;
    }
    get Updated() {
        return this.#Value !== this.#LastValue;
    }
    get Column() {
        return this.#Column;
    }
    set Reference(reference) {
        if (reference.ClassName !== "TField")
            throw new Error("Argumento reference n�o � do tipo TField.");
        this.#Reference = reference;
    }
    get Reference() {
        return this.#Reference;
    }
    set Value(value) {
        this.#Value = value;
    }

    get Value() {
        return this.#Value;
    }
}
