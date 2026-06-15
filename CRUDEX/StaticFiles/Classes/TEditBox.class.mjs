"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TDropdown from "./TDropdown.class.mjs";
import TRecordSet from "./TRecordset.class.mjs";
import TCondition from "./TCondition.class.mjs";
import TMask from "./TMask.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TEditBox {
    #column = null;
    #root = null;
    #legend = null;
    #body = null;
    #checkboxHost = null;
    #control = null;
    #checkbox = null;
    #dropdown = null;
    #operatorSelect = null;
    #operatorShell = null;
    #operatorHost = null;
    #conditionValueDropdown = null;
    #betweenInputs = null;
    #conditionOp = TCondition.DEFAULT_OP;
    #isConditionField = false;
    #isReference = false;
    #isCheckboxInline = false;
    #isRequired = false;
    #editMask = null;
    #readOnly = false;
    #domainVariant = null;

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
        this.#isCheckboxInline = !this.#isReference
            && column.Domain.Type.Category.HtmlInputType === "checkbox";
        if (this.#isCheckboxInline)
            this.#buildCheckboxInlineShell();
        else {
            this.#buildFieldsetShell();
            this.#mountInner();
        }
    }

    #appendRequiredMarker(parent) {
        if (!this.#column.IsRequired)
            return;
        const required = document.createElement("span");
        required.textContent = " *";
        required.style.color = "red";
        required.style.fontSize = "1.5dvmin";
        required.style.fontWeight = "bold";
        required.title = "Indica valor requerido";
        parent.appendChild(required);
    }

    #buildCheckboxInlineShell() {
        this.#root = document.createElement("div");
        this.#root.className = "tedit-field tedit-checkbox tedit-checkbox-inline";

        const row = document.createElement("div");
        row.className = "tedit-checkbox-row";

        const caption = document.createElement("span");
        caption.className = "tedit-caption";
        caption.textContent = this.#column.Caption;
        this.#appendRequiredMarker(caption);

        const spacer = document.createElement("span");
        spacer.className = "tedit-checkbox-spacer";
        spacer.innerHTML = "&nbsp;&nbsp;&nbsp;";

        this.#checkboxHost = document.createElement("span");
        row.append(caption, spacer, this.#checkboxHost);
        this.#root.append(row);
    }

    #buildFieldsetShell() {
        this.#root = document.createElement("fieldset");
        this.#legend = document.createElement("legend");
        this.#legend.textContent = this.#column.Caption;
        this.#appendRequiredMarker(this.#legend);
        this.#root.appendChild(this.#legend);
        this.#body = document.createElement("div");
        this.#body.className = "tedit-body";
    }

    static #domainWidthCh(domain) {
        if (!domain)
            return null;
        const length = domain.Length ?? domain.Type?.MaxLength;
        if (length == null || length <= 0)
            return null;
        return Number(length);
    }

    static #editMaskForDomain(domain) {
        if (!domain)
            return null;
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

    static #widthChFromDomain(domain) {
        const editMask = TEditBox.#editMaskForDomain(domain);
        if (editMask?.placeholder) {
            const maskLength = String(editMask.placeholder).length;
            if (maskLength > 0)
                return maskLength;
        }
        return TEditBox.#domainWidthCh(domain);
    }

    #effectiveDomain() {
        return this.#domainVariant ?? this.#column.Domain;
    }

    #usesCheckboxControl() {
        if (this.#effectiveDomain().Type.Category.HtmlInputType !== "checkbox")
            return false;
        if (this.#domainVariant)
            return true;
        return this.#column.Domain.Type.Category.HtmlInputType === "checkbox";
    }

    #ensureCheckboxHost() {
        if (this.#checkboxHost)
            return;

        if (this.#domainVariant) {
            this.#body.replaceChildren();
            this.#checkboxHost = document.createElement("span");
            this.#body.appendChild(this.#checkboxHost);
            if (!this.#body.parentElement)
                this.#root.appendChild(this.#body);
        }
    }

    #releaseCheckbox() {
        this.#checkbox = null;
        if (this.#domainVariant)
            this.#checkboxHost = null;
    }

    #fieldWidthCh() {
        if (this.#isReference) {
            const refTable = TSystem.GetTable(this.#column.ReferenceTableId);
            const listable = refTable?.GetListableColumn();
            const domain = listable?.Domain ?? this.#effectiveDomain();
            return TEditBox.#widthChFromDomain(domain);
        }

        return TEditBox.#widthChFromDomain(this.#effectiveDomain());
    }

    static #FIELD_MAX_WIDTH_CH = 50;

    #applyControlWidth() {
        if (this.#isCheckboxInline || !this.#body)
            return;
        this.#body.style.maxWidth = `${TEditBox.#FIELD_MAX_WIDTH_CH}ch`;
        const ch = this.#fieldWidthCh();
        if (ch == null) {
            this.#body.style.width = "";
            return;
        }

        const capped = Math.min(ch, TEditBox.#FIELD_MAX_WIDTH_CH);
        // ch = caracteres visíveis; --field-h-chrome = padding (0.5×2) + border (0.1×2) do controlo.
        const width = `calc(${capped}ch + var(--field-h-chrome))`;
        this.#body.style.width = width;
    }

    #syncControlAlignment() {
        if (!this.#legend || !this.#body?.parentElement || this.#operatorHost)
            return;

        requestAnimationFrame(() => {
            const legendWidth = this.#legend.getBoundingClientRect().width;
            const bodyWidth = this.#body.getBoundingClientRect().width;

            if (legendWidth > bodyWidth)
                this.#body.style.marginLeft = `${(legendWidth - bodyWidth) / 2}px`;
            else
                this.#body.style.marginLeft = "";
        });
    }

    #mountInner() {
        const htmlInputType = this.#column.Domain.Type.Category.HtmlInputType;

        if (this.#isReference) {
            this.#root.appendChild(this.#body);
            return;
        }

        this.#control = this.#createNativeInput(htmlInputType);
        this.#body.appendChild(this.#control);
        this.#root.appendChild(this.#body);
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

    #isRequiredForAction(action) {
        return this.#column.IsRequired
            && action !== TSystem.Actions.FILTER
            && action !== TSystem.Actions.SEARCH;
    }

    #isConditionAction(action) {
        return action === TSystem.Actions.FILTER
            || action === TSystem.Actions.SEARCH;
    }

    #isConditionNullUi(control) {
        return control?.placeholder === "nulo";
    }

    #setConditionNullUi(control, isNull, editMask = null) {
        if (!control)
            return;
        control.placeholder = isNull
            ? "nulo"
            : (editMask?.placeholder ?? control.dataset.maskPlaceholder ?? "");
    }

    #toggleConditionNull(control, onChange, editMask = null) {
        if (this.#isConditionNullUi(control)) {
            this.#setConditionNullUi(control, false, editMask);
            onChange(this.#column.Name, null);
            return;
        }
        this.#setConditionNullUi(control, true, editMask);
        onChange(this.#column.Name, TCheckbox.NULL_MARKER);
    }

    #nativeValueState(control) {
        const value = control.value ?? "";
        if (!this.#editMask)
            return { empty: TConfig.IsEmpty(value), incomplete: false };
        const placeholder = this.#editMask.placeholder ?? "";
        const isNumber = this.#editMask.category === "number";
        const empty = isNumber
            ? !String(value).replace(/\D/g, "")
            : TConfig.IsEmpty(value);
        const incomplete = !isNumber && !!placeholder && value.length < placeholder.length;
        return { empty, incomplete };
    }

    #syncNativeValidity(control) {
        if (!control || this.#readOnly)
            control?.setCustomValidity("");
    }

    #applyValidationMessage(control) {
        if (!control || this.#readOnly || !this.#isRequired)
            return false;
        const caption = this.#column.Caption;
        const { empty, incomplete } = this.#nativeValueState(control);
        if (empty) {
            control.setCustomValidity(`Informe ${caption}`);
            return true;
        }
        if (incomplete) {
            control.setCustomValidity("Informe um valor completo");
            return true;
        }
        control.setCustomValidity("");
        return false;
    }

    #applyNativeConstraints(control, action, readOnly) {
        this.#readOnly = readOnly;
        this.#isRequired = this.#isRequiredForAction(action) && !readOnly;
        if (this.#isRequired)
            control.setAttribute("required", "required");
        else
            control.removeAttribute("required");
        this.#syncNativeValidity(control);
    }

    #bindValidityDismiss(control) {
        if (!control || this.#readOnly || control.dataset.crudexValidityDismiss === "true")
            return;
        control.dataset.crudexValidityDismiss = "true";
        const dismiss = () => control.setCustomValidity("");
        control.addEventListener("click", dismiss);
        control.addEventListener("input", dismiss);
        control.addEventListener("keydown", dismiss);
    }

    reportValidity() {
        if (this.#readOnly)
            return true;
        if (this.#dropdown) {
            if (!this.#isRequired || this.#dropdown.isValid()) {
                this.#dropdown.input?.setCustomValidity("");
                this.#dropdown.input?.classList.remove("invalid");
                return true;
            }
            const input = this.#dropdown.input;
            if (input?.hasAttribute("readonly") && input.dataset.crudexAutofillGuard)
                input.removeAttribute("readonly");
            input?.setCustomValidity(`Informe ${this.#column.Caption}`);
            input?.classList.add("invalid");
            input?.focus();
            input?.reportValidity();
            return false;
        }
        if (this.#checkbox) {
            if (!this.#isRequired || this.#checkbox.isValid()) {
                this.#checkbox.validityInput?.setCustomValidity("");
                this.#checkbox.syncFormValidity();
                return true;
            }
            const anchor = this.#checkbox.validityInput;
            if (!anchor)
                return false;
            anchor.setCustomValidity(`Informe ${this.#column.Caption}`);
            anchor.focus();
            anchor.reportValidity();
            return false;
        }
        if (this.#control) {
            if (this.#isRequired && this.#applyValidationMessage(this.#control)) {
                const unlock = this.#control.hasAttribute("readonly")
                    && this.#control.dataset.crudexAutofillGuard;
                if (unlock)
                    this.#control.removeAttribute("readonly");
                this.#control.focus();
                this.#control.reportValidity();
                return false;
            }
            this.#control.setCustomValidity("");
            return true;
        }
        return true;
    }

    #createNativeInput(htmlInputType) {
        if (htmlInputType === "textarea") {
            const control = document.createElement("textarea");
            control.rows = 2;
            return control;
        }

        const domain = this.#effectiveDomain();
        const editMask = this.#getEditMask();
        const control = document.createElement("input");

        if (editMask) {
            control.type = "text";
        } else if (htmlInputType === "number") {
            control.type = domain.Type.Category.HtmlInputType;
            control.min = domain.Minimum;
            control.max = domain.Maximum;
            control.step = 1 / 10 ** (domain.Decimals || 0);
        } else {
            control.type = htmlInputType;
        }

        if (editMask?.placeholder)
            control.maxLength = editMask.placeholder.length;
        else if (htmlInputType !== "number")
            control.maxLength = domain.Length ?? domain.Type?.MaxLength ?? 20;

        return control;
    }

    #getEditMask() {
        return TEditBox.#editMaskForDomain(this.#effectiveDomain());
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

        if (editMask.kind === "pattern")
            return TMask.ToRawValue(displayValue, editMask.mask, editMask.options);

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

    #applyEditMask(control, editMask, readOnly, onChange, action) {
        control.dataset.maskPlaceholder = editMask.placeholder;
        if (!this.#isConditionNullUi(control))
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
            if (TConfig.IsEmpty(control.value)) {
                onChange(
                    this.#column.Name,
                    this.#isConditionNullUi(control) ? TCheckbox.NULL_MARKER : null,
                );
                this.#syncNativeValidity(control);
                return;
            }
            if (this.#isConditionAction(action) && this.#isConditionNullUi(control))
                this.#setConditionNullUi(control, false, editMask);
            const parsed = this.#parseMaskedValue(editMask, control.value);
            onChange(this.#column.Name, parsed);
            this.#syncNativeValidity(control);
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

    #resolveReferencePickerValue(refTable, fkValue) {
        const id = TCondition.normalizeCriterionValue(fkValue);
        if (TConfig.IsEmpty(id) || TCheckbox.isNullMarker(id))
            return;
        const pkColumn = refTable.Columns.find(c => c.IsPrimarykey)?.Name ?? "Id";
        new TRecordSet(refTable, { showSpinner: false })
            .readOne({ [pkColumn]: id })
            .then((refRecord) => {
                if (!refRecord || !this.#dropdown)
                    return;
                const label = TEditBox.#getRefListLabel(refTable, refRecord) ?? String(id);
                this.#dropdown.setValue({ ListItemId: id, ListItemName: label }, false);
            })
            .catch(() => {});
    }

    #resolveReferencePickerValues(refTable, fkValues) {
        const dropdown = this.#conditionValueDropdown ?? this.#dropdown;
        const ids = (Array.isArray(fkValues) ? fkValues : [fkValues])
            .map(value => TCondition.normalizeCriterionValue(value))
            .filter(value => !TConfig.IsEmpty(value) && !TCheckbox.isNullMarker(value));
        if (!ids.length || !dropdown)
            return;

        const pkColumn = refTable.Columns.find(c => c.IsPrimarykey)?.Name ?? "Id";
        Promise.all(ids.map(id =>
            new TRecordSet(refTable, { showSpinner: false })
                .readOne({ [pkColumn]: id })
                .then((refRecord) => {
                    if (!refRecord)
                        return { ListItemId: id, ListItemName: String(id) };
                    const label = TEditBox.#getRefListLabel(refTable, refRecord) ?? String(id);
                    return { ListItemId: id, ListItemName: label };
                })
                .catch(() => ({ ListItemId: id, ListItemName: String(id) })),
        )).then((items) => {
            if (!dropdown)
                return;
            dropdown.setValue(items, false);
        });
    }

    #configureReferenceMulti(options, multiOptions = {}) {
        const { action, onConfirm, onCancel, onFirstInput, emit, parsed } = options;
        const refTable = TSystem.GetTable(this.#column.ReferenceTableId);
        const raw = parsed?.isNull ? TCheckbox.NULL_MARKER : (parsed?.value ?? null);
        const values = Array.isArray(raw)
            ? raw
            : (TConfig.IsEmpty(raw) ? [] : [raw]);
        const pageSize = 5;

        this.#conditionValueDropdown = TDropdown.Multi(this.#body, {
            allowEmpty: true,
            valueAs: "id",
            idField: "ListItemId",
            labelField: "ListItemName",
            itemsPerPage: pageSize,
            placeholder: "Selecionar...",
            value: TCheckbox.isNullMarker(raw) ? [] : values,
            nullCondition: TCheckbox.isNullMarker(raw),
            loader: (query, page) => TRecordSet.fetchPickerPage(refTable, {
                value: query,
                pageNumber: page,
                limitRows: pageSize,
            }),
            listSearch: true,
            ...multiOptions,
        });

        this.#conditionValueDropdown.element.addEventListener("change", (event) => {
            emit(event.detail.value);
        });

        this.#control = this.#conditionValueDropdown.input;
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel, (_name, value) => emit(value));
        onFirstInput?.(this.#control);

        if (!TCheckbox.isNullMarker(raw) && values.length)
            this.#resolveReferencePickerValues(refTable, values);
    }

    #configureReferenceBetween(options) {
        this.#configureReferenceMulti(options, {
            exactItems: 2,
            requireExact: true,
        });
    }

    #configureReferenceList(options) {
        this.#configureReferenceMulti(options);
    }

    #readBetweenInputValue(input) {
        const raw = input.value ?? "";
        if (TConfig.IsEmpty(raw))
            return null;
        if (this.#editMask)
            return this.#parseMaskedValue(this.#editMask, raw);
        return raw;
    }

    #configureBetweenInputs(options) {
        const { action, onConfirm, onCancel, onFirstInput, emit, parsed } = options;
        const raw = parsed?.isNull ? TCheckbox.NULL_MARKER : (parsed?.value ?? null);
        const values = Array.isArray(raw) ? raw : [];
        const domain = this.#effectiveDomain();
        const htmlInputType = domain.Type.Category.HtmlInputType;
        const editMask = this.#getEditMask();
        this.#editMask = editMask && !this.#readOnly ? editMask : null;

        const wrap = document.createElement("div");
        wrap.className = "tedit-between-row";

        const emitBetween = () => {
            const parts = this.#betweenInputs.map(input => this.#readBetweenInputValue(input));
            if (parts.every(part => part === null || part === undefined))
                emit(null);
            else
                emit(parts);
        };

        this.#betweenInputs = [];
        for (let i = 0; i < 2; i++) {
            const input = this.#createNativeInput(htmlInputType);
            input.name = `${this.#fieldInputName()}_${i}`;
            input.Column = this.#column;
            input.style.textAlign = domain.Type.Category.HtmlInputAlign;
            const rawVal = values[i];
            if (this.#editMask && rawVal != null && !TConfig.IsEmpty(rawVal))
                input.value = this.#formatRawValue(this.#editMask, rawVal);
            else
                input.value = rawVal ?? "";
            input.addEventListener("input", emitBetween);
            this.#bindControlKeys(input, action, onConfirm, onCancel, (_name, value) => {
                if (value === null)
                    emit(null);
            });
            input.onfocus = (event) => event.target.select();
            this.#betweenInputs.push(input);
        }

        const sep = document.createElement("span");
        sep.className = "tedit-between-sep";
        sep.textContent = " … ";
        wrap.append(this.#betweenInputs[0], sep, this.#betweenInputs[1]);
        this.#body.append(wrap);
        this.#control = this.#betweenInputs[0];
        onFirstInput?.(this.#control);
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

    #bindControlKeys(control, action, onConfirm, onCancel, onChange = null) {
        control.onkeydown = (event) => {
            if (event.key === "Enter" || event.key === "Tab") {
                event.preventDefault();
                const focusableElements = Array.from(document.querySelectorAll("input, textarea, .tcheckbox-button"));
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
            } else if (this.#isConditionAction(action) && !this.#column.IsRequired
                && (event.key === "Backspace" || event.key === "Delete")) {
                if (this.#checkbox?.mode === TCheckbox.Modes.CONDITION
                    && this.#checkbox.state === TCheckbox.States.NULL) {
                    event.preventDefault();
                    this.#checkbox.setValue(null);
                    onChange?.(this.#column.Name, null);
                    return;
                }
                if (event.target.value !== "")
                    return;
                event.preventDefault();
                this.#toggleConditionNull(event.target, onChange, this.#editMask);
            }
        };
    }

    #configureReference(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput, valueChange } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        this.#root.classList.remove("tedit-checkbox", "tedit-checkbox-inline");
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
        const isNullCondition = this.#isConditionAction(action) && TCheckbox.isNullMarker(fkValue);
        const value = !isNullCondition && listLabel != null && !TConfig.IsEmpty(fkValue)
            ? { ListItemId: fkValue, ListItemName: listLabel }
            : fkValue;
        const isRequired = this.#isRequiredForAction(action);
        const pageSize = 5;

        this.#readOnly = readOnly;
        this.#isRequired = isRequired && !readOnly;

        this.#body.replaceChildren();
        this.#dropdown = TDropdown.Single(this.#body, {
            catalog,
            value: isNullCondition ? null : (TConfig.IsEmpty(fkValue) ? null : value),
            nullCondition: isNullCondition,
            valueAs: "id",
            idField: "ListItemId",
            labelField: "ListItemName",
            itemsPerPage: pageSize,
            placeholder: "",
            required: isRequired,
            allowEmpty: !isRequired,
            readOnly,
            loader: readOnly ? null : (query, page) => TRecordSet.fetchPickerPage(refTable, {
                value: query,
                pageNumber: page,
                limitRows: pageSize,
            }),
        });

        this.#dropdown.element.addEventListener("change", (event) => {
            if (this.#isConditionNullUi(this.#dropdown.input))
                this.#setConditionNullUi(this.#dropdown.input, false);
            const value = event.detail.value ?? this.#dropdown.resolveCommittedValue?.();
            if (valueChange)
                valueChange(value);
            else
                onChange(this.#column.Name, value);
            this.#dropdown.syncFormValidity();
        });

        this.#control = this.#dropdown.input;
        this.#control.name = this.#fieldInputName();
        this.#disableBrowserAutofill(this.#control, readOnly);
        this.#control.Column = this.#column;
        this.#dropdown.syncFormValidity();
        this.#bindValidityDismiss(this.#control);
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel, onChange);
        this.#control.onfocus = (event) => event.target.select();
        onFirstInput?.(this.#control);

        if (!readOnly && !isNullCondition && listLabel == null && !TConfig.IsEmpty(fkValue))
            this.#resolveReferencePickerValue(refTable, fkValue);
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

        this.#root.classList.add("tedit-checkbox");
        this.#root.dataset.readonly = readOnly ? "true" : "false";
        if (this.#domainVariant)
            this.#ensureCheckboxHost();
        if (!this.#checkboxHost)
            throw new Error("Checkbox host is required.");

        this.#checkboxHost.replaceChildren();
        this.#checkbox = isCondition
            ? TCheckbox.Condition(this.#checkboxHost, checkboxOptions)
            : TCheckbox.Edition(this.#checkboxHost, { ...checkboxOptions, required: this.#column.IsRequired });

        this.#readOnly = readOnly;
        this.#isRequired = this.#column.IsRequired && !isCondition && !readOnly;
        this.#checkbox.syncFormValidity();
        this.#control = this.#checkbox.input;
        this.#disableBrowserAutofill(this.#control, readOnly);
        this.#control.Column = this.#column;
        this.#checkbox.element.TCheckbox = this.#checkbox;
        this.#bindCheckboxCaptionClick(readOnly);
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel, onChange);
        onFirstInput?.(this.#control);
    }

    #bindCheckboxCaptionClick(readOnly) {
        if (!this.#isCheckboxInline || readOnly)
            return;

        const advance = () => this.#checkbox?.advance();
        for (const element of this.#root.querySelectorAll(".tedit-caption, .tedit-checkbox-spacer")) {
            if (element.dataset.checkboxLabelBound === "true")
                continue;
            element.dataset.checkboxLabelBound = "true";
            element.addEventListener("click", advance);
        }
    }

    #configureNativeInput(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        this.#root.classList.remove("tedit-checkbox", "tedit-checkbox-inline");
        this.#releaseCheckbox();
        const domain = this.#effectiveDomain();
        const htmlInputType = domain.Type.Category.HtmlInputType;
        const editMask = this.#getEditMask();
        this.#editMask = editMask && !readOnly ? editMask : null;
        const useDisplayValue = action === TSystem.Actions.QUERY;
        const rawValue = useDisplayValue
            ? this.#getDisplayValue(record, sourceRecord)
            : record[this.#column.Name];
        const isNullCondition = this.#isConditionAction(action) && TCheckbox.isNullMarker(rawValue);

        const controlKind = htmlInputType === "textarea" ? "textarea" : "input";
        const needsNewControl = !this.#control
            || this.#control.closest(".tcheckbox")
            || this.#control.tagName.toLowerCase() !== controlKind;
        if (needsNewControl) {
            this.#control = this.#createNativeInput(htmlInputType);
            this.#body.replaceChildren(this.#control);
            if (!this.#body.parentElement)
                this.#root.appendChild(this.#body);
        }

        this.#control.name = this.#fieldInputName();
        this.#control.Column = this.#column;
        this.#control.readOnly = readOnly;
        this.#applyNativeConstraints(this.#control, action, readOnly);
        this.#disableBrowserAutofill(this.#control, readOnly);
        this.#control.style.textAlign = domain.Type.Category.HtmlInputAlign;

        if (editMask && !readOnly) {
            this.#control.value = isNullCondition ? "" : this.#formatRawValue(editMask, rawValue);
            this.#applyEditMask(this.#control, editMask, readOnly, onChange, action);
            if (isNullCondition)
                this.#setConditionNullUi(this.#control, true, editMask);
        } else {
            this.#control.oninput = null;
            this.#control.placeholder = isNullCondition ? "nulo" : "";
            delete this.#control.dataset.maskPlaceholder;
            delete this.#control.dataset.lastValidValue;
            if (!readOnly) {
                const notify = (event) => {
                    const value = event.target.value;
                    if (TConfig.IsEmpty(value)) {
                        onChange(
                            this.#column.Name,
                            this.#isConditionNullUi(event.target) ? TCheckbox.NULL_MARKER : null,
                        );
                    } else {
                        if (this.#isConditionAction(action) && this.#isConditionNullUi(event.target))
                            event.target.placeholder = "";
                        onChange(this.#column.Name, value);
                    }
                    this.#syncNativeValidity(this.#control);
                };
                this.#control.oninput = notify;
                this.#control.onchange = notify;
            } else {
                this.#control.oninput = null;
                this.#control.onchange = null;
            }
            this.#control.value = isNullCondition ? "" : (rawValue ?? "");
        }

        this.#bindControlKeys(this.#control, action, onConfirm, onCancel, onChange);
        this.#bindValidityDismiss(this.#control);
        this.#control.onfocus = (event) => event.target.select();
        onFirstInput?.(this.#control);
    }

    #ensureConditionShell() {
        if (this.#operatorHost)
            return;
        this.#root.classList.add("tedit-condition-field");
        this.#operatorHost = document.createElement("div");
        this.#operatorHost.className = "tedit-operator-host";
        const wrap = document.createElement("div");
        wrap.className = "tedit-condition-row";
        this.#body.classList.add("tedit-condition-value");
        this.#body.style.marginLeft = "";
        if (this.#body.parentElement === this.#root)
            this.#root.removeChild(this.#body);
        wrap.append(this.#operatorHost, this.#body);
        this.#root.appendChild(wrap);
    }

    #readConditionValuePart() {
        if (this.#betweenInputs) {
            const parts = this.#betweenInputs.map(input => this.#readBetweenInputValue(input));
            if (parts.every(part => part === null || part === undefined))
                return null;
            return parts;
        }
        if (this.#conditionValueDropdown)
            return this.#conditionValueDropdown.getValue();
        if (this.#dropdown)
            return this.#dropdown.resolveCommittedValue?.() ?? this.#dropdown.getValue();
        if (this.#checkbox?.mode === TCheckbox.Modes.CONDITION)
            return this.#checkbox.value;
        if (this.#control) {
            if (this.#isConditionNullUi(this.#control))
                return TCheckbox.NULL_MARKER;
            const raw = this.#control.value ?? "";
            if (TConfig.IsEmpty(raw))
                return null;
            if (this.#editMask)
                return this.#parseMaskedValue(this.#editMask, raw);
            return raw;
        }
        return null;
    }

    collectFilterValue(action) {
        if (!this.#isConditionAction(action))
            return undefined;
        if (this.#isCheckboxInline)
            return this.#checkbox?.value ?? null;
        if (!this.#operatorHost)
            return undefined;

        if (this.#operatorSelect)
            this.#conditionOp = Number(this.#operatorSelect.value);

        const valuePart = this.#readConditionValuePart();
        if (TCheckbox.isNullMarker(valuePart))
            return valuePart;
        return TCondition.pack(this.#conditionOp, valuePart);
    }

    #getConditionComparator() {
        return TSystem.GetComparator(this.#conditionOp);
    }

    #buildOperatorSelect(operators, selectedOp) {
        const shell = document.createElement("div");
        shell.className = "tedit-operator";

        const symbol = document.createElement("span");
        symbol.className = "tedit-operator-symbol";
        symbol.setAttribute("aria-hidden", "true");

        const select = document.createElement("select");
        select.className = "tedit-operator-select";
        select.title = "Operador de comparação — clique para alterar";

        for (const op of operators) {
            const option = document.createElement("option");
            option.value = String(op.Id);
            option.textContent = op.Symbol;
            if (op.Description)
                option.title = op.Description;
            select.append(option);
        }

        if (operators.some(op => op.Id === Number(selectedOp)))
            select.value = String(selectedOp);
        else if (operators.length > 0)
            select.value = String(operators[0].Id);

        shell.append(symbol, select);
        this.#syncOperatorSelectDisplay(shell);
        return shell;
    }

    #syncOperatorSelectDisplay(shell) {
        if (!shell)
            return;
        const select = shell.querySelector("select");
        const symbol = shell.querySelector(".tedit-operator-symbol");
        if (!select || !symbol)
            return;

        const text = select.options[select.selectedIndex]?.text ?? "";
        symbol.textContent = text;
        const ch = Math.max(1, text.length);
        const width = `calc(${ch}ch + 2 * var(--select-edge-inset) + 0.2dvmin)`;
        shell.style.width = width;
        shell.style.minWidth = width;
        shell.style.maxWidth = width;
    }

    #configureCondition(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput } = options;
        const category = this.#column.Domain.Type.Category;
        const defaultOp = action === TSystem.Actions.SEARCH
            ? TCondition.defaultOpForSearch(category.Name)
            : TCondition.DEFAULT_OP;
        const parsed = TCondition.parse(record[this.#column.Name], { defaultOp });
        const emit = (valuePart) => {
            if (TCheckbox.isNullMarker(valuePart))
                onChange(this.#column.Name, valuePart);
            else if (valuePart === null || valuePart === undefined
                || (Array.isArray(valuePart) && valuePart.length === 0))
                onChange(this.#column.Name, null);
            else
                onChange(this.#column.Name, TCondition.pack(this.#conditionOp, valuePart));
        };

        if (parsed.isNull)
            this.#conditionOp = defaultOp;
        else
            this.#conditionOp = parsed.op ?? defaultOp;

        const operators = TCondition.operatorsForCategory(category.Id);

        this.#operatorHost.replaceChildren();
        this.#operatorShell = this.#buildOperatorSelect(operators, this.#conditionOp);
        this.#operatorSelect = this.#operatorShell.querySelector("select");
        this.#operatorHost.append(this.#operatorShell);
        this.#operatorSelect.addEventListener("change", () => {
            this.#syncOperatorSelectDisplay(this.#operatorShell);
            this.#conditionOp = Number(this.#operatorSelect.value);
            const freshParsed = TCondition.parse(record[this.#column.Name], { defaultOp });
            this.#rebuildConditionValue({
                action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit,
                parsed: freshParsed,
            });
        });

        this.#rebuildConditionValue({
            action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit, parsed,
        });
    }

    #rebuildConditionValue(options) {
        const { action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit, parsed } = options;
        const comparator = this.#getConditionComparator();
        const mode = comparator?.ValueMode ?? "single";
        const raw = parsed?.isNull ? TCheckbox.NULL_MARKER : (parsed?.value ?? null);
        const innerRecord = { ...record, [this.#column.Name]: raw };
        const innerOnChange = (_name, value) => emit(value);

        this.#conditionValueDropdown = null;
        this.#betweenInputs = null;
        this.#control = null;
        this.#dropdown = null;
        this.#checkbox = null;
        this.#body.replaceChildren();

        if (mode === "between") {
            if (this.#isReference) {
                this.#configureReferenceBetween({
                    action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit, parsed,
                });
                return;
            }

            this.#configureBetweenInputs({
                action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit, parsed,
            });
            return;
        }

        if (mode === "list") {
            if (this.#isReference) {
                this.#configureReferenceList({
                    action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit, parsed,
                });
                return;
            }

            this.#conditionValueDropdown = TDropdown.Addable(this.#body, {
                allowEmpty: true,
                value: Array.isArray(raw) ? raw : (TConfig.IsEmpty(raw) ? [] : [raw]),
                nullCondition: TCheckbox.isNullMarker(raw),
            });
            this.#conditionValueDropdown.element.addEventListener("change", (event) => {
                emit(event.detail.value);
            });
            this.#control = this.#conditionValueDropdown.input;
            this.#bindControlKeys(this.#control, action, onConfirm, onCancel, innerOnChange);
            onFirstInput?.(this.#control);
            return;
        }

        if (this.#isReference)
            this.#configureReference({
                action, record: innerRecord, sourceRecord, onChange: innerOnChange,
                onConfirm, onCancel, onFirstInput, valueChange: emit,
            });
        else if (this.#usesCheckboxControl())
            this.#configureCheckbox({
                action, record: innerRecord, onChange: innerOnChange,
                onConfirm, onCancel, onFirstInput,
            });
        else
            this.#configureNativeInput({
                action, record: innerRecord, sourceRecord, onChange: innerOnChange,
                onConfirm, onCancel, onFirstInput,
            });
    }

    configure(options = {}) {
        const action = options.action;
        const onChange = options.onChange
            ?? ((name, value) => { options.record[name] = value; });

        if ("domainVariant" in options)
            this.#domainVariant = options.domainVariant;

        if (this.#isConditionAction(action) && !this.#isCheckboxInline) {
            this.#ensureConditionShell();
            this.#configureCondition({ ...options, onChange });
            this.#applyControlWidth();
            this.#syncControlAlignment();
            return this;
        }

        if (this.#isReference)
            this.#configureReference({ ...options, onChange });
        else if (this.#usesCheckboxControl())
            this.#configureCheckbox({ ...options, onChange });
        else
            this.#configureNativeInput({ ...options, onChange });

        this.#applyControlWidth();
        this.#syncControlAlignment();
        return this;
    }

    get element() {
        return this.#root;
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
