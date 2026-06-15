"use strict";

export default class TComparator {
    #Id = 0;
    #Symbol = "";
    #Description = "";
    #Arity = null;

    constructor(row) {
        this.#Id = Number(row.Id);
        this.#Symbol = row.Symbol ?? "";
        this.#Description = row.Description ?? row.Name ?? "";
        this.#Arity = row.Arity ?? null;
    }

    get Id() {
        return this.#Id;
    }

    get Symbol() {
        return this.#Symbol;
    }

    get Description() {
        return this.#Description;
    }

    get Arity() {
        return this.#Arity;
    }

    /** @returns {"single"|"between"|"list"} */
    get ValueMode() {
        const arity = this.#Arity;
        if (arity === null || arity === undefined || String(arity).trim() === "")
            return "list";
        if (String(arity) === "3")
            return "between";
        return "single";
    }
}
