"use strict";

/**
 * Catálogo runtime de comparadores (Cmp): cada Symbol registra buildJs para montar predicados.
 * Resolução sempre por Symbol — Id é só FK no metadado.
 */
export default class TComparator {
    static #handlers = new Map();

    #Id = 0;
    #Symbol = "";
    #Description = "";
    #Arity = null;

    static #key(symbol) {
        return String(symbol ?? "").trim();
    }

    static register(symbol, handler) {
        if (!symbol || typeof handler?.buildJs !== "function")
            throw new Error("TComparator.register exige symbol e handler.buildJs.");
        this.#handlers.set(this.#key(symbol), handler);
    }

    static registerAlias(alias, targetSymbol) {
        const target = this.#handlers.get(this.#key(targetSymbol));
        if (!target)
            throw new Error(`TComparator.registerAlias: '${targetSymbol}' não registrado.`);
        this.#handlers.set(this.#key(alias), target);
    }

    static has(symbol) {
        return this.#handlers.has(this.#key(symbol));
    }

    static resolve(symbol) {
        return this.#handlers.get(this.#key(symbol)) ?? null;
    }

    static buildJs(comparator, left, right) {
        const symbol = typeof comparator === "object" && comparator !== null
            ? comparator.Symbol
            : comparator;
        const handler = TComparator.resolve(symbol);
        if (!handler?.buildJs)
            return "true";
        return handler.buildJs(left, right, { literal: TComparator.literal });
    }

    static parseValues(raw, comparator) {
        const text = String(raw ?? "").trim();
        const mode = comparator?.ValueMode;
        if (mode === "list" || mode === "between" || text.includes(";")) {
            return text.split(";")
                .map(part => part.trim())
                .filter(part => part !== "")
                .map(part => TComparator.#coerceLiteral(part));
        }
        return TComparator.#coerceLiteral(text);
    }

    static literal(value) {
        if (value === null || value === undefined)
            return "null";
        if (typeof value === "number")
            return Number.isFinite(value) ? String(value) : "null";
        if (typeof value === "boolean")
            return value ? "true" : "false";
        return JSON.stringify(String(value));
    }

    static #coerceLiteral(value) {
        if (value === "null")
            return null;
        if (value === "true")
            return true;
        if (value === "false")
            return false;
        const numeric = Number(value);
        if (!Number.isNaN(numeric) && String(numeric) === value)
            return numeric;
        return value;
    }

    static #valueMode(arity) {
        if (arity === null || arity === undefined || String(arity).trim() === "")
            return "list";
        const n = Number(arity);
        if (Number.isFinite(n) && n > 2)
            return "between";
        if (Number.isFinite(n) && n === 1)
            return "unary";
        return "single";
    }

    static #registerBuiltins() {
        const bin = (op) => ({
            sqlOperator: op,
            buildJs(left, right, { literal }) {
                return `${literal(left)} ${op} ${literal(right)}`;
            },
        });

        TComparator.register("<", bin("<"));
        TComparator.register("≤", bin("<="));
        TComparator.register("=", {
            sqlOperator: "=",
            buildJs(left, right, { literal }) {
                return `${literal(left)} === ${literal(right)}`;
            },
        });
        TComparator.register("≠", {
            sqlOperator: "<>",
            buildJs(left, right, { literal }) {
                return `${literal(left)} !== ${literal(right)}`;
            },
        });
        TComparator.register("≥", bin(">="));
        TComparator.register(">", bin(">"));

        TComparator.register("∈", {
            sqlOperator: "IN",
            buildJs(left, right, { literal }) {
                const leftLit = literal(left);
                const list = Array.isArray(right) ? right : [right];
                return `[${list.map(literal).join(", ")}].includes(${leftLit})`;
            },
        });

        TComparator.register("∉", {
            sqlOperator: "NOT IN",
            buildJs(left, right, { literal }) {
                const leftLit = literal(left);
                const list = Array.isArray(right) ? right : [right];
                return `![${list.map(literal).join(", ")}].includes(${leftLit})`;
            },
        });

        TComparator.register("⊃", {
            sqlOperator: "LIKE",
            buildJs(left, right, { literal }) {
                const leftLit = literal(left);
                const rightLit = literal(right);
                return `String(${leftLit} ?? "").includes(String(${rightLit} ?? ""))`;
            },
        });

        TComparator.register("⊅", {
            sqlOperator: "NOT LIKE",
            buildJs(left, right, { literal }) {
                const leftLit = literal(left);
                const rightLit = literal(right);
                return `!String(${leftLit} ?? "").includes(String(${rightLit} ?? ""))`;
            },
        });

        TComparator.register("∃", {
            sqlOperator: "BETWEEN",
            buildJs(left, right, { literal }) {
                const values = Array.isArray(right) ? right : [right, right];
                const leftLit = literal(left);
                const minLit = literal(values[0]);
                const maxLit = literal(values[1]);
                return `(${leftLit} >= ${minLit} && ${leftLit} <= ${maxLit})`;
            },
        });

        TComparator.register("∄", {
            sqlOperator: "NOT BETWEEN",
            buildJs(left, right, { literal }) {
                const values = Array.isArray(right) ? right : [right, right];
                const leftLit = literal(left);
                const minLit = literal(values[0]);
                const maxLit = literal(values[1]);
                return `(${leftLit} < ${minLit} || ${leftLit} > ${maxLit})`;
            },
        });

        TComparator.register("∅", {
            sqlOperator: "IS NULL",
            buildJs(left, _right, { literal }) {
                return `${literal(left)} == null`;
            },
        });

        TComparator.register("⊗", {
            sqlOperator: "IS NOT NULL",
            buildJs(left, _right, { literal }) {
                return `${literal(left)} != null`;
            },
        });
    }

    static {
        TComparator.#registerBuiltins();
    }

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

    get SqlComparator() {
        return TComparator.resolve(this.#Symbol)?.sqlOperator ?? "";
    }

    /** @deprecated Resolvido via registry; mantido só por compatibilidade. */
    get JsComparator() {
        return "";
    }

    /** @returns {"single"|"between"|"list"|"unary"} */
    get ValueMode() {
        return TComparator.#valueMode(this.#Arity);
    }

    /** BETWEEN: quantidade de valores = Arity - 1. */
    get BetweenSlotCount() {
        if (this.ValueMode !== "between")
            return null;
        const n = Number(this.#Arity);
        return Number.isFinite(n) ? n - 1 : null;
    }

    buildJs(left, right) {
        return TComparator.buildJs(this, left, right);
    }
}
