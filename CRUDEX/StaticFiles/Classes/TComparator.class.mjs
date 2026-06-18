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
        const n = Number(arity);
        if (Number.isFinite(n) && n > 2)
            return "between";
        return "single";
    }

    /** BETWEEN: quantidade de valores = Arity - 1. */
    get BetweenSlotCount() {
        if (this.ValueMode !== "between")
            return null;
        const n = Number(this.#Arity);
        return Number.isFinite(n) ? n - 1 : null;
    }
}
