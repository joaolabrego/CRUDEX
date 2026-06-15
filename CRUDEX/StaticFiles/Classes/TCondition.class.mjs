"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TCondition {
    static DEFAULT_OP = 3;
    static SEARCH_TEXT_OP = 9;

    static isCriterion(value) {
        return typeof value === "object"
            && value !== null
            && !TCheckbox.isNullMarker(value)
            && Object.hasOwn(value, "op");
    }

    static hasActiveValue(value) {
        return TCondition.willApplyFilter(value);
    }

    /** Critério que entra no JSON enviado ao Read (IS NULL usa null explícito). */
    static willApplyFilter(value) {
        if (TCheckbox.isIgnored(value))
            return false;
        if (TCheckbox.isNullMarker(value))
            return true;
        return TCondition.toFilterPayload(value) !== undefined;
    }

    /** Valor persistido em FilterValues — descarta {op} sem value. */
    static normalizeStoredFilter(value) {
        if (TCheckbox.isIgnored(value) || TConfig.IsEmpty(value))
            return null;
        if (TCheckbox.isNullMarker(value))
            return value;
        if (TCondition.isCriterion(value)) {
            const sorted = {
                op: Number(value.op),
                value: TCondition.sortBetweenValues(
                    value.op,
                    TCondition.normalizeCriterionValue(value.value),
                ),
            };
            return TCondition.toFilterPayload(sorted) === undefined ? null : sorted;
        }
        if (typeof value === "object" && value !== null)
            return null;
        return value;
    }

    static defaultOpForSearch(categoryName) {
        const name = (categoryName ?? "").toLowerCase();
        if (name === "string" || name === "text")
            return TCondition.SEARCH_TEXT_OP;
        return TCondition.DEFAULT_OP;
    }

    static parse(raw, { defaultOp = TCondition.DEFAULT_OP } = {}) {
        if (TCheckbox.isNullMarker(raw))
            return { op: null, value: raw, isNull: true };
        if (TCondition.isCriterion(raw))
            return { op: Number(raw.op), value: raw.value ?? null, isNull: false };
        if (TCheckbox.isIgnored(raw) || TConfig.IsEmpty(raw))
            return { op: null, value: null, isNull: false };
        return { op: defaultOp, value: raw, isNull: false };
    }

    static normalizeCriterionValue(value) {
        if (value === null || value === undefined || Array.isArray(value))
            return value;
        if (typeof value !== "object" || TCheckbox.isNullMarker(value))
            return value;
        if (TCondition.isCriterion(value))
            return TCondition.normalizeCriterionValue(value.value);
        if (Object.hasOwn(value, "ListItemId"))
            return value.ListItemId;
        if (Object.hasOwn(value, "Id"))
            return value.Id;
        if (Object.hasOwn(value, "id"))
            return value.id;
        return value;
    }

    static #compareRangeValues(a, b) {
        const na = Number(a);
        const nb = Number(b);
        if (!Number.isNaN(na) && !Number.isNaN(nb))
            return na - nb;
        return String(a).localeCompare(String(b), undefined, { numeric: true, sensitivity: "base" });
    }

    static sortBetweenValues(op, value) {
        if (!Array.isArray(value) || value.length < 2)
            return value;
        const comparator = TSystem.GetComparator(op);
        if (comparator?.ValueMode !== "between")
            return value;
        return [...value].sort(TCondition.#compareRangeValues);
    }

    static pack(op, value) {
        if (TCheckbox.isNullMarker(value))
            return value;
        if (op === null || op === undefined)
            return null;
        value = TCondition.normalizeCriterionValue(value);
        if (value === null || value === undefined)
            return null;
        if (Array.isArray(value) && value.length === 0)
            return null;
        if (typeof value === "string" && TConfig.IsEmpty(value))
            return null;
        value = TCondition.sortBetweenValues(op, value);
        return { op: Number(op), value };
    }

    static toFilterPayload(value) {
        if (TCheckbox.isIgnored(value))
            return undefined;
        if (TCheckbox.isNullMarker(value))
            return null;
        if (TCondition.isCriterion(value)) {
            const normalized = {
                op: Number(value.op),
                value: TCondition.sortBetweenValues(
                    value.op,
                    TCondition.normalizeCriterionValue(value.value),
                ),
            };
            if (normalized.value === null || normalized.value === undefined)
                return undefined;
            if (Array.isArray(normalized.value) && normalized.value.length === 0)
                return undefined;
            if (typeof normalized.value === "string" && TConfig.IsEmpty(normalized.value))
                return undefined;
            return normalized;
        }
        if (TConfig.IsEmpty(value))
            return undefined;
        return value;
    }

    static formatCriterion(key, value, comparators = null) {
        if (!TCondition.willApplyFilter(value))
            return "";
        if (TCheckbox.isNullMarker(value))
            return `${key} IS NULL`;
        if (typeof value === "object" && value !== null) {
            if (TCheckbox.isNullMarker(value.ListItemId))
                return `${key} IS NULL`;
            if (TCondition.isCriterion(value)) {
                const op = TSystem.GetComparator(value.op) ?? comparators?.find(c => c.Id === Number(value.op));
                const symbol = op?.Symbol ?? String(value.op);
                let val = TCondition.normalizeCriterionValue(value.value);
                val = TCondition.sortBetweenValues(value.op, val);
                if (val === null || val === undefined)
                    return `${key} ${symbol}`;
                if (Array.isArray(val))
                    return `${key} ${symbol} (${val.join(", ")})`;
                return `${key} ${symbol} '${val}'`;
            }
        }
        if (value === true)
            return `${key} = sim`;
        if (value === false)
            return `${key} = não`;
        return `${key} = '${value}'`;
    }

    static operatorsForCategory(categoryId) {
        const rules = TSystem.GetRulesForCategory(categoryId);
        const seen = new Set();
        const result = [];
        for (const rule of rules) {
            const comparator = TSystem.GetComparator(rule.ComparatorId);
            if (!comparator || seen.has(comparator.Id) || !comparator.Symbol?.trim())
                continue;
            seen.add(comparator.Id);
            result.push(comparator);
        }
        return result;
    }
}
