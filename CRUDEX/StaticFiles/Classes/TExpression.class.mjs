"use strict";

import TConfig from "./TConfig.class.mjs";
import TComparator from "./TComparator.class.mjs";
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

        let right = null;
        if (condition.RightColumnId)
            right = TExpression.#columnValue(condition.RightColumnId, record);
        else if (condition.RightValues != null && String(condition.RightValues).trim() !== "")
            right = TComparator.parseValues(condition.RightValues, comparator);

        return TComparator.buildJs(comparator, left, right);
    }

    static #columnValue(columnId, record) {
        if (columnId == null)
            return null;
        const column = TSystem.GetColumn(columnId);
        if (!column)
            return null;
        return record[column.Name] ?? null;
    }
}
