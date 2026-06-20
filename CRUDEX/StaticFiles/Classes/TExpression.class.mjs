"use strict";

import TConfig from "./TConfig.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TExpression {
    static evaluate(expressionId, record) {
        const conditions = TSystem.GetConditionsForExpression(expressionId);
        if (!conditions.length)
            return false;

        const parts = [];
        for (const condition of conditions) {
            const connector = (condition.Connector ?? "").trim().toUpperCase();
            if (connector)
                parts.push(connector === "OR" ? "||" : "&&");
            if (condition.LeftParenthesis)
                parts.push(condition.LeftParenthesis);
            parts.push(TExpression.#buildAtomic(condition, record));
            if (condition.RightParenthesis)
                parts.push(condition.RightParenthesis);
        }

        try {
            return !!TConfig.Evaluate(parts.join(" "));
        } catch (error) {
            console.error("Erro ao avaliar expressão:", expressionId, error);
            return false;
        }
    }

    static #buildAtomic(condition, record) {
        const comparator = TSystem.GetComparator(condition.ComparatorId);
        if (!comparator)
            return "true";

        const left = TExpression.#columnValue(condition.LeftColumnId, record);
        const jsOp = String(comparator.JsComparator ?? comparator.Symbol ?? "").trim();
        const sqlOp = String(comparator.SqlComparator ?? "").trim().toUpperCase();

        let right = null;
        if (condition.RightColumnId)
            right = TExpression.#columnValue(condition.RightColumnId, record);
        else if (condition.RightValues != null && String(condition.RightValues).trim() !== "")
            right = TExpression.#parseRightValues(condition.RightValues, comparator);

        if (jsOp === "includes" || jsOp === "!includes") {
            const leftLit = TExpression.#literal(left);
            if (Array.isArray(right)) {
                const list = `[${right.map(TExpression.#literal).join(", ")}]`;
                const expr = `${list}.includes(${leftLit})`;
                return jsOp.startsWith("!") ? `!(${expr})` : expr;
            }
            const rightLit = TExpression.#literal(right);
            const expr = `String(${leftLit} ?? "").includes(String(${rightLit} ?? ""))`;
            return jsOp.startsWith("!") ? `!(${expr})` : expr;
        }

        if (jsOp === "&&" || jsOp === "||") {
            const values = Array.isArray(right) ? right : [right, right];
            const leftLit = TExpression.#literal(left);
            const minLit = TExpression.#literal(values[0]);
            const maxLit = TExpression.#literal(values[1]);
            if (jsOp === "&&")
                return `(${leftLit} >= ${minLit} && ${leftLit} <= ${maxLit})`;
            return `(${leftLit} < ${minLit} || ${leftLit} > ${maxLit})`;
        }

        if (sqlOp === "IS NULL" || sqlOp === "IS NOT NULL" || jsOp.includes("null"))
            return `${TExpression.#literal(left)}${jsOp.startsWith(" ") ? jsOp : ` ${jsOp}`}`;

        const leftLit = TExpression.#literal(left);
        const rightLit = TExpression.#literal(right);
        return `${leftLit} ${jsOp} ${rightLit}`;
    }

    static #columnValue(columnId, record) {
        if (columnId == null)
            return null;
        const column = TSystem.GetColumn(columnId);
        if (!column)
            return null;
        return record[column.Name] ?? null;
    }

    static #parseRightValues(raw, comparator) {
        const text = String(raw).trim();
        const mode = comparator?.ValueMode;
        if (mode === "list" || mode === "between" || text.includes(";")) {
            return text.split(";")
                .map(part => part.trim())
                .filter(part => part !== "")
                .map(part => TExpression.#coerceLiteral(part));
        }
        return TExpression.#coerceLiteral(text);
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

    static #literal(value) {
        if (value === null || value === undefined)
            return "null";
        if (typeof value === "number")
            return Number.isFinite(value) ? String(value) : "null";
        if (typeof value === "boolean")
            return value ? "true" : "false";
        return JSON.stringify(String(value));
    }
}
