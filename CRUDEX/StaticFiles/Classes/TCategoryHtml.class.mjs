"use strict";

/** Mapeamento categoria → controle HTML (substitui HtmlInputType / HtmlInputAlign em metadado). */
export default class TCategoryHtml {
    static #normalize(category) {
        if (!category)
            return "";
        if (typeof category === "string")
            return category.toLowerCase();
        return String(category.Name ?? "").toLowerCase();
    }

    static getInputType(category) {
        switch (TCategoryHtml.#normalize(category)) {
            case "string":
                return "text";
            case "number":
                return "number";
            case "date":
                return "date";
            case "datetime":
                return "datetime-local";
            case "time":
                return "time";
            case "boolean":
                return "checkbox";
            case "text":
                return "textarea";
            case "image":
            case "binary":
                return "file";
            default:
                return "text";
        }
    }

    static getAlign(category) {
        return TCategoryHtml.#normalize(category) === "number" ? "right" : "left";
    }

    static isCheckbox(category) {
        return TCategoryHtml.getInputType(category) === "checkbox";
    }

    static isStringCategory(category) {
        return TCategoryHtml.#normalize(category) === "string";
    }
}
