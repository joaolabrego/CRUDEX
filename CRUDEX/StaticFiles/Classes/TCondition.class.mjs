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
            && Object.hasOwn(value, "comparator");
    }

    static hasActiveValue(value) {
        return TCondition.willApplyFilter(value);
    }

    /** Critério que entra no JSON enviado ao Read (IS NULL usa null explícito no payload). */
    static willApplyFilter(value) {
        if (TCheckbox.isIgnored(value))
            return false;
        if (TCheckbox.isNullMarker(value))
            return true;
        return TCondition.toFilterPayload(value) !== undefined;
    }

    /** Valor persistido no recordset — undefined = sem critério; NULL_MARKER = IS NULL. */
    static normalizeStoredFilter(value) {
        if (TCheckbox.isIgnored(value) || TConfig.IsEmpty(value))
            return undefined;
        if (TCheckbox.isNullMarker(value))
            return value;
        if (TCondition.isCriterion(value)) {
            const sorted = {
                comparator: Number(value.comparator),
                value: TCondition.sortBetweenValues(
                    value.comparator,
                    TCondition.normalizeCriterionValue(value.value),
                ),
            };
            return TCondition.toFilterPayload(sorted) === undefined ? undefined : sorted;
        }
        if (typeof value === "object" && value !== null)
            return undefined;
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
            return { comparator: null, value: raw, isNull: true };
        if (TCondition.isCriterion(raw))
            return { comparator: Number(raw.comparator), value: raw.value ?? null, isNull: false };
        if (TCheckbox.isIgnored(raw) || TConfig.IsEmpty(raw))
            return { comparator: null, value: null, isNull: false };
        return { comparator: defaultOp, value: raw, isNull: false };
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

    static sortBetweenValues(comparator, value) {
        if (!Array.isArray(value) || value.length < 2)
            return value;
        const cmp = TSystem.GetComparator(comparator);
        if (cmp?.ValueMode !== "between")
            return value;
        return [...value].sort(TCondition.#compareRangeValues);
    }

    static isBetweenPartial(comparator, value) {
        const cmp = typeof comparator === "object" && comparator?.BetweenSlotCount != null
            ? comparator
            : TSystem.GetComparator(comparator);
        const slots = cmp?.BetweenSlotCount;
        if (slots == null || !Array.isArray(value))
            return false;
        return value.length > 0 && value.length < slots;
    }

    static isBetweenComplete(comparator, value) {
        const cmp = typeof comparator === "object" && comparator?.BetweenSlotCount != null
            ? comparator
            : TSystem.GetComparator(comparator);
        const slots = cmp?.BetweenSlotCount;
        return slots != null && Array.isArray(value) && value.length === slots;
    }

    static pack(comparator, value) {
        if (TCheckbox.isNullMarker(value))
            return value;
        if (comparator === null || comparator === undefined)
            return null;
        value = TCondition.normalizeCriterionValue(value);
        if (value === null || value === undefined)
            return null;
        if (Array.isArray(value) && value.length === 0)
            return null;
        if (typeof value === "string" && TConfig.IsEmpty(value))
            return null;
        value = TCondition.sortBetweenValues(comparator, value);
        return { comparator: Number(comparator), value };
    }

    static toFilterPayload(value) {
        if (TCheckbox.isIgnored(value))
            return undefined;
        if (TCheckbox.isNullMarker(value))
            return null;
        if (TCondition.isCriterion(value)) {
            const normalized = {
                comparator: Number(value.comparator),
                value: TCondition.sortBetweenValues(
                    value.comparator,
                    TCondition.normalizeCriterionValue(value.value),
                ),
            };
            if (normalized.value === null || normalized.value === undefined)
                return undefined;
            if (Array.isArray(normalized.value) && normalized.value.length === 0)
                return undefined;
            const cmp = TSystem.GetComparator(normalized.comparator);
            if (TCondition.isBetweenPartial(cmp, normalized.value))
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
                const cmp = TSystem.GetComparator(value.comparator) ?? comparators?.find(c => c.Id === Number(value.comparator));
                const symbol = cmp?.Symbol ?? String(value.comparator);
                let val = TCondition.normalizeCriterionValue(value.value);
                val = TCondition.sortBetweenValues(value.comparator, val);
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
