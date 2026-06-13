"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TDropdown from "./TDropdown.class.mjs";
import TList from "./TList.class.mjs";
import TMask from "./TMask.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TEditBox {
    #column = null;
    #fieldset = null;
    #legend = null;
    #body = null;
    #checkboxHost = null;
    #control = null;
    #checkbox = null;
    #dropdown = null;
    #isReference = false;

    static Create(column, container = null) {
        const edit = new TEditBox(column);
        if (container)
            container.appendChild(edit.element);
        return edit;
    }

    constructor(column) {
        if (!column)
            throw new Error("Argumento column é requerido.");
        this.#column = column;
        this.#isReference = !TConfig.IsEmpty(column.ReferenceTableId);
        this.#buildShell();
        this.#mountInner();
    }

    #buildShell() {
        this.#fieldset = document.createElement("fieldset");
        this.#legend = document.createElement("legend");
        this.#legend.textContent = this.#column.Caption;

        if (this.#column.IsRequired) {
            const required = document.createElement("span");
            required.textContent = " *";
            required.style.color = "red";
            required.style.fontSize = "1.5dvmin";
            required.style.fontWeight = "bold";
            required.title = "Indica valor requerido";
            this.#legend.appendChild(required);
        }

        this.#fieldset.appendChild(this.#legend);
        this.#body = document.createElement("div");
        this.#body.className = "tedit-body";
        this.#body.style.width = "100%";
    }

    #mountInner() {
        const htmlInputType = this.#column.Domain.Type.Category.HtmlInputType;

        if (htmlInputType === "checkbox") {
            this.#checkboxHost = document.createElement("span");
            const spacer = document.createElement("span");
            spacer.innerHTML = "&nbsp;&nbsp;&nbsp;";
            this.#legend.appendChild(spacer);
            this.#legend.appendChild(this.#checkboxHost);
            return;
        }

        if (this.#isReference) {
            this.#fieldset.appendChild(this.#body);
            return;
        }

        this.#control = this.#createNativeInput(htmlInputType);
        this.#body.appendChild(this.#control);
        this.#fieldset.appendChild(this.#body);
    }

    #disableBrowserAutofill(control, keepReadOnly = false) {
        control.setAttribute("autocomplete", "off");
        control.setAttribute("autocorrect", "off");
        control.setAttribute("autocapitalize", "off");
        control.setAttribute("spellcheck", "false");
        control.setAttribute("data-lpignore", "true");
        control.setAttribute("data-1p-ignore", "");
        if (keepReadOnly || control.dataset.crudexAutofillGuard)
            return;
        control.dataset.crudexAutofillGuard = "1";
        control.setAttribute("readonly", "readonly");
        const unlock = () => {
            control.removeAttribute("readonly");
        };
        control.addEventListener("mousedown", unlock, { once: true });
        control.addEventListener("keydown", unlock, { once: true });
    }

    #fieldInputName() {
        return `cx_${this.#column.Name}`;
    }

    #createNativeInput(htmlInputType) {
        if (htmlInputType === "textarea") {
            const control = document.createElement("textarea");
            control.rows = 2;
            control.cols = 50;
            return control;
        }

        const editMask = this.#getEditMask();
        const control = document.createElement("input");

        if (editMask) {
            control.type = "text";
            if (editMask.placeholder)
                control.maxLength = editMask.placeholder.length;
        } else if (htmlInputType === "number") {
            control.type = this.#column.Domain.Type.Category.HtmlInputType;
            control.min = this.#column.Domain.Minimum;
            control.max = this.#column.Domain.Maximum;
            control.step = 1 / 10 ** (this.#column.Domain.Decimals || 0);
        } else {
            control.type = htmlInputType;
        }

        if (htmlInputType !== "number" || editMask) {
            control.size = this.#column.Domain.Type.MaxLength ?? this.#column.Domain.Length ?? 20;
            control.maxLength = this.#column.Domain.Length ?? 20;
        }

        return control;
    }

    #getEditMask() {
        const domain = this.#column.Domain;
        const category = domain.Type.Category.Name;
        const scale = domain.Decimals ?? 0;

        if (scale > 0 && category === "number") {
            const precision = domain.Length ?? domain.Type.MaxLength ?? 12;
            return {
                kind: "decimal",
                precision,
                scale,
                placeholder: TConfig.GetNumericMask(precision, scale),
                category,
            };
        }

        if (!TConfig.IsEmpty(domain.MaskId)) {
            const maskRow = TSystem.GetMask(domain.MaskId);
            if (maskRow?.Mask) {
                let mask = maskRow.Mask;
                if (typeof mask === "string" && mask.includes("|"))
                    mask = mask.split("|").map(part => part.trim());
                const placeholder = Array.isArray(mask) ? mask[mask.length - 1] : mask;

                if (!Array.isArray(mask) && category === "number" && TMask.IsNumericMask(mask)) {
                    const scale = domain.Decimals ?? 0;
                    return {
                        kind: "decimal",
                        precision: TMask.CountNumericMaskDigits(mask),
                        scale,
                        placeholder,
                        category,
                    };
                }

                return {
                    kind: "pattern",
                    mask,
                    options: domain.Codification ?? "",
                    placeholder,
                    category,
                };
            }
        }

        if (category === "number" && domain.Length) {
            const placeholder = TConfig.GetNumericMask(domain.Length, 0);
            return {
                kind: "decimal",
                precision: domain.Length,
                scale: 0,
                placeholder,
                category,
            };
        }

        return null;
    }

    #rawToMaskDigits(value, category) {
        const date = value instanceof Date ? value : new Date(value);
        if (Number.isNaN(date.getTime()))
            return String(value).replace(/\D/g, "");
        const pad = (part) => String(part).padStart(2, "0");
        if (category === "date" || category === "datetime") {
            let digits = pad(date.getDate()) + pad(date.getMonth() + 1) + String(date.getFullYear()).padStart(4, "0");
            if (category === "datetime")
                digits += pad(date.getHours()) + pad(date.getMinutes()) + pad(date.getSeconds());
            return digits;
        }
        if (category === "time")
            return pad(date.getHours()) + pad(date.getMinutes()) + pad(date.getSeconds());
        return String(value).replace(/\D/g, "");
    }

    #formatRawValue(editMask, rawValue) {
        if (TConfig.IsEmpty(rawValue))
            return "";

        const scratch = document.createElement("input");
        scratch.type = "text";

        if (editMask.kind === "decimal") {
            scratch.value = String(rawValue).replace(".", TConfig.DecimalSeparator);
            TMask.FormatDecimalInput(scratch, editMask.precision, editMask.scale);
            return scratch.value;
        }

        if (editMask.category === "number")
            scratch.value = String(rawValue).replace(/\D/g, "");
        else if (editMask.category === "date" || editMask.category === "datetime" || editMask.category === "time")
            scratch.value = this.#rawToMaskDigits(rawValue, editMask.category);
        else
            scratch.value = String(rawValue);

        TMask.FormatInputValue(scratch, editMask.mask, editMask.options);
        return scratch.value;
    }

    #parseMaskedValue(editMask, displayValue) {
        if (TConfig.IsEmpty(displayValue))
            return null;

        if (editMask.kind === "decimal")
            return TMask.ToFloat(displayValue);

        if (editMask.category === "number")
            return TMask.ToFloat(displayValue);
        if (editMask.category === "date")
            return TMask.ToDate(displayValue);
        if (editMask.category === "datetime")
            return TMask.ToDateTime(displayValue);

        return displayValue;
    }

    #rejectsMaskInput(editMask, rawInput, lastValid) {
        if (rawInput === "" || rawInput === lastValid)
            return false;

        if (editMask.kind === "decimal" || editMask.category === "number") {
            const lastDigits = lastValid.replace(/\D/g, "");
            const rawDigits = rawInput.replace(/\D/g, "");
            if (rawDigits !== lastDigits)
                return false;
            return /[A-Za-z]/.test(rawInput);
        }

        return false;
    }

    #restoreInputValue(control, value, selection) {
        control.value = value;
        const start = Math.min(selection.start, value.length);
        const end = Math.min(selection.end, value.length);
        control.setSelectionRange(start, end);
    }

    #applyEditMask(control, editMask, readOnly, onChange) {
        control.dataset.maskPlaceholder = editMask.placeholder;
        control.placeholder = editMask.placeholder;
        control.dataset.lastValidValue = control.value;

        if (readOnly)
            return;

        let savedSelection = { start: 0, end: 0 };

        control.addEventListener("beforeinput", () => {
            savedSelection = {
                start: control.selectionStart ?? 0,
                end: control.selectionEnd ?? 0,
            };
        });

        const notify = () => {
            const parsed = this.#parseMaskedValue(editMask, control.value);
            onChange(this.#column.Name, TConfig.IsEmpty(control.value) ? null : parsed);
        };

        control.oninput = () => {
            const lastValid = control.dataset.lastValidValue ?? "";
            const rawInput = control.value;
            const rejectInput = () => {
                this.#restoreInputValue(control, lastValid, savedSelection);
            };

            if (editMask.kind === "decimal")
                TMask.FormatDecimalInput(control, editMask.precision, editMask.scale);
            else
                TMask.FormatInputValue(control, editMask.mask, editMask.options);

            if (rawInput === "") {
                control.dataset.lastValidValue = "";
                notify();
                return;
            }

            if (control.value === "" && lastValid !== "") {
                rejectInput();
                return;
            }

            if (this.#rejectsMaskInput(editMask, rawInput, lastValid)) {
                rejectInput();
                return;
            }

            control.dataset.lastValidValue = control.value;
            notify();
        };
        control.onchange = null;
    }

    static #getRefListLabel(refTable, ref) {
        if (!ref)
            return null;
        const listable = refTable.GetListableColumn();
        if (listable) {
            const listValue = ref[listable.Name];
            if (!TConfig.IsEmpty(listValue))
                return listValue;
        }
        return ref.ListItemValue ?? ref.Name ?? ref.Id ?? null;
    }

    #getDisplayValue(record, sourceRecord) {
        const value = record[this.#column.Name];

        if (TConfig.IsEmpty(this.#column.ReferenceTableId))
            return value ?? "";
        const refTable = TSystem.GetTable(this.#column.ReferenceTableId);
        if (!refTable)
            return value ?? "";
        const alias = refTable.Alias || refTable.Name;
        const ref = sourceRecord?.references?.[alias];

        if (!ref)
            return value ?? "";
        return TEditBox.#getRefListLabel(refTable, ref) ?? value ?? "";
    }

    #bindControlKeys(control, action, onConfirm, onCancel) {
        control.onkeydown = (event) => {
            if (event.key === "Enter" || event.key === "Tab") {
                event.preventDefault();
                const focusableElements = Array.from(document.querySelectorAll("input, textarea"));
                const currentIndex = focusableElements.indexOf(document.activeElement);

                if (currentIndex > -1 && currentIndex < focusableElements.length - 1)
                    focusableElements[currentIndex + 1].focus();
                else
                    focusableElements[0]?.focus();
            } else if (event.key === "Escape") {
                event.preventDefault();
                if (action === TSystem.Actions.QUERY)
                    onConfirm?.();
                else
                    onCancel?.();
            } else if (action === TSystem.Actions.FILTER && !this.#column.IsRequired
                && (event.key === "Backspace" || event.key === "Delete")) {
                if (event.target.value === "") {
                    event.preventDefault();
                    const maskPh = event.target.dataset.maskPlaceholder ?? "";
                    event.target.placeholder = event.target.placeholder === "nulo"
                        ? maskPh
                        : "nulo";
                }
            }
        };
    }

    #configureReference(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        const refTable = TSystem.GetTable(this.#column.ReferenceTableId);
        const alias = refTable.Alias || refTable.Name;
        const ref = sourceRecord?.references?.[alias];
        const listLabel = TEditBox.#getRefListLabel(refTable, ref);
        const catalog = [];

        if (ref)
            catalog.push({
                ListItemId: ref.Id,
                ListItemName: listLabel,
            });

        const fkValue = record[this.#column.Name];
        const value = listLabel != null && !TConfig.IsEmpty(fkValue)
            ? { ListItemId: fkValue, ListItemName: listLabel }
            : fkValue;
        const isRequired = this.#column.IsRequired
            && action !== TSystem.Actions.FILTER
            && action !== TSystem.Actions.SEARCH;
        const pageSize = 5;

        this.#body.replaceChildren();
        this.#dropdown = TDropdown.Single(this.#body, {
            catalog,
            value: TConfig.IsEmpty(fkValue) ? null : value,
            valueAs: "id",
            idField: "ListItemId",
            labelField: "ListItemName",
            itemsPerPage: pageSize,
            placeholder: "",
            required: isRequired,
            allowEmpty: !isRequired,
            readOnly,
            loader: readOnly ? null : (query, page) => TList.fetchPage(refTable, {
                value: query,
                pageNumber: page,
                limitRows: pageSize,
            }),
        });

        this.#dropdown.element.addEventListener("change", (event) => {
            onChange(this.#column.Name, event.detail.value);
        });

        this.#control = this.#dropdown.input;
        this.#control.name = this.#fieldInputName();
        this.#disableBrowserAutofill(this.#control, readOnly);
        this.#control.Column = this.#column;
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel);
        this.#control.onfocus = (event) => event.target.select();
        onFirstInput?.(this.#control);
    }

    #configureCheckbox(options) {
        const { action, record, onChange, onConfirm, onCancel, onFirstInput } = options;
        const isCondition = action === TSystem.Actions.FILTER || action === TSystem.Actions.SEARCH;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        const checkboxOptions = {
            value: record[this.#column.Name],
            readOnly,
            name: this.#column.Name,
            onChange: (value) => onChange(this.#column.Name, value),
        };

        this.#checkbox = isCondition
            ? TCheckbox.Condition(this.#checkboxHost, checkboxOptions)
            : TCheckbox.Edition(this.#checkboxHost, { ...checkboxOptions, required: this.#column.IsRequired });

        this.#control = this.#checkbox.input;
        this.#disableBrowserAutofill(this.#control, readOnly);
        this.#control.Column = this.#column;
        this.#checkbox.element.TCheckbox = this.#checkbox;
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel);
        onFirstInput?.(this.#control);
    }

    #configureNativeInput(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        const editMask = this.#getEditMask();
        const useDisplayValue = action === TSystem.Actions.QUERY;
        const rawValue = useDisplayValue
            ? this.#getDisplayValue(record, sourceRecord)
            : record[this.#column.Name];

        if (!this.#control) {
            this.#control = this.#createNativeInput(this.#column.Domain.Type.Category.HtmlInputType);
            this.#body.replaceChildren(this.#control);
            if (!this.#body.parentElement)
                this.#fieldset.appendChild(this.#body);
        }

        this.#control.name = this.#fieldInputName();
        this.#control.Column = this.#column;
        this.#control.readOnly = readOnly;
        this.#disableBrowserAutofill(this.#control, readOnly);
        this.#control.style.textAlign = this.#column.Domain.Type.Category.HtmlInputAlign;

        if (editMask && !readOnly) {
            this.#control.value = this.#formatRawValue(editMask, rawValue);
            this.#applyEditMask(this.#control, editMask, readOnly, onChange);
        } else {
            this.#control.oninput = null;
            this.#control.placeholder = "";
            delete this.#control.dataset.maskPlaceholder;
            delete this.#control.dataset.lastValidValue;
            if (!readOnly) {
                this.#control.onchange = (event) => {
                    const value = event.target.value;
                    onChange(this.#column.Name, TConfig.IsEmpty(value) ? null : value);
                };
            } else
                this.#control.onchange = null;
            this.#control.value = rawValue ?? "";
        }

        this.#bindControlKeys(this.#control, action, onConfirm, onCancel);
        this.#control.onfocus = (event) => event.target.select();
        onFirstInput?.(this.#control);
    }

    configure(options = {}) {
        const action = options.action;
        const onChange = options.onChange
            ?? ((name, value) => { options.record[name] = value; });

        if (this.#isReference)
            this.#configureReference({ ...options, onChange });
        else if (this.#column.Domain.Type.Category.HtmlInputType === "checkbox")
            this.#configureCheckbox({ ...options, onChange });
        else
            this.#configureNativeInput({ ...options, onChange });

        return this;
    }

    get element() {
        return this.#fieldset;
    }

    get input() {
        return this.#control;
    }

    get column() {
        return this.#column;
    }

    get dropdown() {
        return this.#dropdown;
    }

    get checkbox() {
        return this.#checkbox;
    }
}
