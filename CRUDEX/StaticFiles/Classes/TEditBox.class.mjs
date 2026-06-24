"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TConfig from "./TConfig.class.mjs";
import TDropdown from "./TDropdown.class.mjs";
import TListValues from "./TListValues.class.mjs";
import TRecordSet from "./TRecordset.class.mjs";
import TCondition from "./TCondition.class.mjs";
import TMask from "./TMask.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TProperty from "./TProperty.class.mjs";
import TCategoryHtml from "./TCategoryHtml.class.mjs";

export default class TEditBox {
    static #operatorMenuCloseBound = false;

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
    #conditionOp = TCondition.DEFAULT_OP;
    #isConditionField = false;
    #isReference = false;
    #isCheckboxInline = false;
    #isRequired = false;
    #editMask = null;
    #readOnly = false;
    #domainVariant = null;
    #behaviorBaseline = null;
    #behaviorHooks = null;
    #behaviorMaskSpec = null;
    #behaviorContainerClass = "";
    #behaviorContainerStyle = "";

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
        this.#isReference = TSystem.IsFkColumn(column);
        this.#isCheckboxInline = !this.#isReference
            && TCategoryHtml.isCheckbox(column.Domain.Type.Category);
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

    static #editMaskFromSpec(spec, domain) {
        const text = String(spec ?? "").trim();
        if (!text)
            return null;

        const maskRow = TSystem.GetMaskByName(text);
        if (maskRow) {
            const variant = domain ? { ...domain, MaskId: maskRow.Id } : { MaskId: maskRow.Id, Type: { Category: { Name: "string" } }, Decimals: 0 };
            return TEditBox.#editMaskForDomain(variant);
        }

        const category = domain?.Type?.Category?.Name ?? "string";
        return {
            kind: "pattern",
            mask: text,
            options: domain?.Codification ?? "",
            placeholder: text,
            category,
        };
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

    static #parseValidValues(domain) {
        const raw = domain?.ValidValues;
        if (TConfig.IsEmpty(raw))
            return null;
        const items = new TListValues(String(raw)).data;
        return items.length ? items : null;
    }

    #domainValidValues() {
        return TEditBox.#parseValidValues(this.#column.Domain);
    }

    #effectiveDomain() {
        return this.#domainVariant ?? this.#column.Domain;
    }

    #usesValidValuesDropdown() {
        return !this.#isReference && this.#domainValidValues() != null;
    }

    #usesCheckboxControl() {
        if (this.#usesValidValuesDropdown())
            return false;
        if (!TCategoryHtml.isCheckbox(this.#effectiveDomain().Type.Category))
            return false;
        if (this.#domainVariant)
            return true;
        return TCategoryHtml.isCheckbox(this.#column.Domain.Type.Category);
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

    #getRefTable() {
        return TSystem.GetReferencePkTable(this.#column);
    }

    static #listableColumnWidthCh(refTable) {
        const listable = refTable?.GetListableColumn();
        if (!listable?.Domain)
            return null;
        const length = listable.Domain.Length ?? listable.Domain.Type?.MaxLength;
        if (length == null || length <= 0)
            return null;
        return Number(length);
    }

    /** Largura do dropdown FK: Length da coluna listável (Name), nunca máscara do domínio do Id. */
    static #referenceDropdownWidthCh(refTable) {
        const fromListable = TEditBox.#listableColumnWidthCh(refTable);
        if (fromListable != null)
            return fromListable;
        return TEditBox.#FIELD_MAX_WIDTH_CH;
    }

    #fieldWidthCh() {
        if (this.#isReference)
            return TEditBox.#referenceDropdownWidthCh(this.#getRefTable());

        if (this.#usesValidValuesDropdown()) {
            const values = this.#domainValidValues();
            if (values?.length) {
                const longest = values.reduce((max, value) => Math.max(max, String(value).length), 0);
                if (longest > 0)
                    return Math.min(TEditBox.#FIELD_MAX_WIDTH_CH, longest);
            }
        }

        return TEditBox.#widthChFromDomain(this.#effectiveDomain());
    }

    static #FIELD_MAX_WIDTH_CH = 45;

    /** Espaço reservado à direita: botão ▼ (+ padding) no dropdown single/multi. */
    static #DROPDOWN_ICON_CH = 3;

    static #ADDABLE_ICON_CH = 5;

    #dropdownChromeCh() {
        if (this.#body?.classList.contains("tedit-addable-value"))
            return TEditBox.#ADDABLE_ICON_CH;
        if (this.#dropdown || this.#conditionValueDropdown || this.#body?.querySelector(".tdropdown"))
            return TEditBox.#DROPDOWN_ICON_CH;
        return 0;
    }

    #applyControlWidth(options = {}) {
        if (this.#isCheckboxInline || !this.#body)
            return;
        const chromeCh = this.#dropdownChromeCh();
        this.#body.style.maxWidth = chromeCh > 0
            ? `calc(${TEditBox.#FIELD_MAX_WIDTH_CH}ch + var(--field-h-chrome) + ${chromeCh}ch)`
            : `${TEditBox.#FIELD_MAX_WIDTH_CH}ch`;
        const ch = this.#fieldWidthCh();
        if (ch == null) {
            this.#body.style.width = "";
            return;
        }

        const capped = Math.min(ch, TEditBox.#FIELD_MAX_WIDTH_CH);
        const width = `calc(${capped + chromeCh}ch + var(--field-h-chrome))`;
        this.#body.style.width = width;
        for (const dropdown of this.#body.querySelectorAll(".tdropdown")) {
            dropdown.style.maxWidth = this.#body.style.maxWidth;
            dropdown.style.width = "100%";
        }
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
        if (this.#isReference || this.#usesValidValuesDropdown()) {
            this.#root.appendChild(this.#body);
            return;
        }

        const htmlInputType = TCategoryHtml.getInputType(this.#column.Domain.Type.Category);
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

    #normalizeConditionParsed(raw, defaultOp, categoryId) {
        const parsed = TCondition.parse(raw, { defaultOp });
        if (!parsed.isNull)
            return parsed;
        const isNullOp = TCondition.operatorsForCategory(categoryId).find((op) => {
            const cmp = TSystem.GetComparator(op.Id);
            return cmp?.ValueMode === "unary"
                && /^IS\s+NULL$/i.test(String(cmp.Symbol ?? "").trim());
        });
        if (isNullOp)
            return { comparator: isNullOp.Id, value: null, isNull: false };
        return { comparator: defaultOp, value: null, isNull: false };
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
        if (this.#conditionValueDropdown) {
            if (this.#conditionValueDropdown.isValid()) {
                this.#conditionValueDropdown.dismissValidityBalloon();
                this.#conditionValueDropdown.syncFormValidity();
                return true;
            }
            const values = this.#conditionValueDropdown.getValue();
            const cmp = this.#getConditionComparator();
            const betweenPartial = TCondition.isBetweenPartial(cmp, values);
            const slots = cmp?.BetweenSlotCount;
            const message = betweenPartial && slots != null
                ? `Informe os ${slots} valores do intervalo`
                : `Informe ${this.#column.Caption}`;
            this.#conditionValueDropdown.validityInput?.focus();
            return this.#conditionValueDropdown.reportValidity(message);
        }
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
            control.type = "number";
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
                onChange(this.#column.Name, null);
                this.#syncNativeValidity(control);
                return;
            }
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

    #formatAddableMaskedInput(control, editMask) {
        const lastValid = control.dataset.lastValidValue ?? "";
        const rawInput = control.value;
        const rejectInput = () => {
            this.#restoreInputValue(control, lastValid, {
                start: control.selectionStart ?? 0,
                end: control.selectionEnd ?? 0,
            });
        };

        if (editMask.kind === "decimal")
            TMask.FormatDecimalInput(control, editMask.precision, editMask.scale);
        else
            TMask.FormatInputValue(control, editMask.mask, editMask.options);

        if (rawInput === "") {
            control.dataset.lastValidValue = "";
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
    }

    #bindAddableInputMask(control, editMask) {
        control.dataset.maskPlaceholder = editMask.placeholder;
        control.placeholder = editMask.placeholder;
        control.dataset.lastValidValue = control.value ?? "";
        control.maxLength = editMask.placeholder.length;

        control.addEventListener("beforeinput", () => {
            control.dataset.savedSelection = JSON.stringify({
                start: control.selectionStart ?? 0,
                end: control.selectionEnd ?? 0,
            });
        });

        return () => this.#formatAddableMaskedInput(control, editMask);
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
        return ref.ListItemValue ?? ref.Name ?? TSystem.GetPrimaryKeyScalar(ref, refTable) ?? null;
    }

    #getRefKeyPair() {
        return TSystem.GetReferenceKeyPair(this.#column);
    }

    #resolveReferencePickerValue(refTable, fkValue) {
        const id = TCondition.normalizeCriterionValue(fkValue);
        if (TConfig.IsEmpty(id) || TCheckbox.isNullMarker(id))
            return;
        const keyPair = this.#getRefKeyPair();
        const pkColumn = keyPair?.pkColumn;
        if (!pkColumn)
            return;
        new TRecordSet(refTable, { showSpinner: false })
            .readOne({ [pkColumn.Name]: id })
            .then((refRecord) => {
                if (!refRecord || !this.#dropdown)
                    return;
                const current = TCondition.normalizeCriterionValue(this.#dropdown.getValue());
                if (String(current ?? "") !== String(id))
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

        const keyPair = this.#getRefKeyPair();
        const pkColumn = keyPair?.pkColumn;
        if (!pkColumn || !dropdown)
            return;

        Promise.all(ids.map(id =>
            new TRecordSet(refTable, { showSpinner: false })
                .readOne({ [pkColumn.Name]: id })
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
            const expected = new Set(ids.map(id => String(id)));
            const current = new Set((dropdown.getValue() ?? []).map(id => String(id)));
            if (expected.size !== current.size || [...expected].some(id => !current.has(id)))
                return;
            dropdown.setValue(items, false);
        });
    }

    #configureReferenceMulti(options, multiOptions = {}) {
        const { action, onConfirm, onCancel, onFirstInput, emit, parsed } = options;
        const refTable = this.#getRefTable();
        const raw = parsed?.value ?? null;
        const values = Array.isArray(raw)
            ? raw
            : (TConfig.IsEmpty(raw) ? [] : [raw]);
        const pageSize = TSystem.RowsPerDropdownPage;

        this.#conditionValueDropdown = TDropdown.Multi(this.#body, {
            allowEmpty: true,
            valueAs: "id",
            idField: "ListItemId",
            labelField: "ListItemName",
            itemsPerPage: pageSize,
            placeholder: "Selecionar...",
            value: values,
            loader: (query, page) => TRecordSet.readPickerPage(refTable, {
                value: query,
                pageNumber: page,
                limitRows: pageSize,
            }),
            ...multiOptions,
        });

        this.#conditionValueDropdown.element.addEventListener("change", (event) => {
            emit(event.detail.value);
        });

        this.#control = this.#conditionValueDropdown.input;
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel, (_name, value) => emit(value));
        onFirstInput?.(this.#control);

        if (values.length)
            this.#resolveReferencePickerValues(refTable, values);
    }

    #configureReferenceBetween(options) {
        const slots = this.#getConditionComparator()?.BetweenSlotCount ?? 2;
        this.#configureReferenceMulti(options, {
            exactItems: slots,
            requireExact: true,
        });
    }

    #configureReferenceList(options) {
        this.#configureReferenceMulti(options);
    }

    #configureScalarAddableList(options) {
        const {
            action, onConfirm, onCancel, onFirstInput, emit, parsed,
            maxItems = Infinity,
            validItemCounts = null,
            betweenSlots = null,
        } = options;
        const raw = parsed?.value ?? null;
        const editMask = this.#getEditMask();
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        const hasMask = editMask && !readOnly;

        this.#body.classList.add("tedit-addable-value");

        this.#conditionValueDropdown = TDropdown.Addable(this.#body, {
            allowEmpty: true,
            maxItems,
            validItemCounts,
            collapseSelectionOnBlur: betweenSlots != null,
            placeholder: hasMask ? (editMask.placeholder ?? "") : "Type to add",
            value: Array.isArray(raw) ? raw : (TConfig.IsEmpty(raw) ? [] : [raw]),
            parseValue: (text) => {
                if (TConfig.IsEmpty(text))
                    return null;
                if (editMask)
                    return this.#parseMaskedValue(editMask, text);
                return text;
            },
            formatItem: (value) => {
                if (value == null || value === "")
                    return "";
                if (editMask)
                    return this.#formatRawValue(editMask, value);
                return String(value);
            },
        });

        const input = this.#conditionValueDropdown.input;
        if (input) {
            const domain = this.#effectiveDomain();
            const align = TCategoryHtml.getAlign(domain.Type.Category);
            input.dataset.textAlign = align;
            if (hasMask)
                this.#conditionValueDropdown.setFormatInput(this.#bindAddableInputMask(input, editMask));
        }

        this.#conditionValueDropdown.element.addEventListener("change", (event) => {
            const values = event.detail.value;
            if (!Array.isArray(values) || values.length === 0) {
                emit(null);
                return;
            }
            if (betweenSlots != null) {
                emit(TCondition.isBetweenComplete(this.#conditionOp, values)
                    ? TCondition.sortBetweenValues(this.#conditionOp, values)
                    : null);
                return;
            }
            emit(values);
        });
        this.#control = this.#conditionValueDropdown.input;
        this.#bindControlKeys(this.#control, action, onConfirm, onCancel, (_name, value) => emit(value));
        onFirstInput?.(this.#control);
        this.#applyControlWidth({ addable: true });
    }

    #getDisplayValue(record, sourceRecord) {
        const value = record[this.#column.Name];

        const refTable = this.#getRefTable();
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
                if (event.key === "Enter" && control.closest(".tdropdown-addable"))
                    return;
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
                }
            }
        };
    }

    #singlePickerDropdownOptions(catalog, value, required, readOnly, loader = null) {
        return {
            catalog,
            value,
            valueAs: "id",
            idField: "ListItemId",
            labelField: "ListItemName",
            itemsPerPage: TSystem.RowsPerDropdownPage,
            placeholder: "Selecionar...",
            required,
            allowEmpty: !required,
            readOnly,
            loader: readOnly ? null : loader,
        };
    }

    #finishSinglePickerDropdown({ action, readOnly, onChange, onConfirm, onCancel, onFirstInput, valueChange }) {
        this.#dropdown.element.addEventListener("change", (event) => {
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
    }

    #configureReference(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput, valueChange } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        this.#root.classList.remove("tedit-checkbox", "tedit-checkbox-inline");
        const refTable = this.#getRefTable();
        const alias = refTable?.Alias || refTable?.Name;
        const ref = sourceRecord?.references?.[alias];
        const listLabel = TEditBox.#getRefListLabel(refTable, ref);
        const catalog = [];

        if (ref) {
            const keyPair = this.#getRefKeyPair();
            const listItemId = keyPair?.pkColumn
                ? ref[keyPair.pkColumn.Name]
                : TSystem.GetPrimaryKeyScalar(ref, refTable);
            catalog.push({
                ListItemId: listItemId,
                ListItemName: listLabel,
            });
        }

        const fkValue = record[this.#column.Name];
        const value = listLabel != null && !TConfig.IsEmpty(fkValue)
            ? { ListItemId: fkValue, ListItemName: listLabel }
            : fkValue;
        const isRequired = this.#isRequiredForAction(action);

        this.#readOnly = readOnly;
        this.#isRequired = isRequired && !readOnly;

        this.#body.replaceChildren();
        this.#dropdown = TDropdown.Single(this.#body, this.#singlePickerDropdownOptions(
            catalog,
            TConfig.IsEmpty(fkValue) ? null : value,
            isRequired,
            readOnly,
            (query, page) => TRecordSet.readPickerPage(refTable, {
                value: query,
                pageNumber: page,
                limitRows: TSystem.RowsPerDropdownPage,
            }),
        ));

        this.#finishSinglePickerDropdown({
            action, readOnly, onChange, onConfirm, onCancel, onFirstInput, valueChange,
        });

        if (!readOnly && listLabel == null && !TConfig.IsEmpty(fkValue))
            this.#resolveReferencePickerValue(refTable, fkValue);
    }

    #configureValidValues(options) {
        const { action, record, onChange, onConfirm, onCancel, onFirstInput } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        const isCondition = this.#isConditionAction(action);
        const values = this.#domainValidValues();
        if (!values)
            throw new Error("ValidValues do domínio não definidos.");
        const rawValue = record[this.#column.Name];
        const catalog = [];
        if (!TConfig.IsEmpty(rawValue)) {
            catalog.push({
                ListItemId: rawValue,
                ListItemName: String(rawValue),
            });
        }
        const validValuesRaw = this.#column.Domain?.ValidValues ?? "";
        const isRequired = this.#column.IsRequired && !isCondition && !readOnly;

        this.#readOnly = readOnly;
        this.#isRequired = isRequired;
        this.#root.classList.remove("tedit-checkbox", "tedit-checkbox-inline");
        this.#body.replaceChildren();
        this.#dropdown = TDropdown.Single(this.#body, this.#singlePickerDropdownOptions(
            catalog,
            TConfig.IsEmpty(rawValue) ? null : rawValue,
            isRequired,
            readOnly,
            (query, page) => TListValues.readPickerPage(validValuesRaw, {
                value: query,
                pageNumber: page,
                limitRows: TSystem.RowsPerDropdownPage,
            }),
        ));

        this.#finishSinglePickerDropdown({
            action, readOnly, onChange, onConfirm, onCancel, onFirstInput,
        });
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
        if (this.#usesValidValuesDropdown()) {
            this.#configureValidValues(options);
            return;
        }

        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput } = options;
        const readOnly = action === TSystem.Actions.DELETE || action === TSystem.Actions.QUERY;
        this.#root.classList.remove("tedit-checkbox", "tedit-checkbox-inline");
        this.#releaseCheckbox();
        const domain = this.#effectiveDomain();
        const htmlInputType = TCategoryHtml.getInputType(domain.Type.Category);
        const editMask = this.#getEditMask();
        this.#editMask = editMask && !readOnly ? editMask : null;
        const useDisplayValue = action === TSystem.Actions.QUERY;
        const rawValue = useDisplayValue
            ? this.#getDisplayValue(record, sourceRecord)
            : record[this.#column.Name];

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
        this.#control.style.textAlign = TCategoryHtml.getAlign(domain.Type.Category);

        if (editMask && !readOnly) {
            this.#control.value = this.#formatRawValue(editMask, rawValue);
            this.#applyEditMask(this.#control, editMask, readOnly, onChange, action);
        } else {
            this.#control.oninput = null;
            this.#control.placeholder = "";
            delete this.#control.dataset.maskPlaceholder;
            delete this.#control.dataset.lastValidValue;
            if (!readOnly) {
                const notify = (event) => {
                    const value = event.target.value;
                    if (TConfig.IsEmpty(value))
                        onChange(this.#column.Name, null);
                    else
                        onChange(this.#column.Name, value);
                    this.#syncNativeValidity(this.#control);
                };
                this.#control.oninput = notify;
                this.#control.onchange = notify;
            } else {
                this.#control.oninput = null;
                this.#control.onchange = null;
            }
            this.#control.value = rawValue ?? "";
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
        if (this.#conditionValueDropdown)
            return this.#conditionValueDropdown.getValue();
        if (this.#dropdown)
            return this.#dropdown.resolveCommittedValue?.() ?? this.#dropdown.getValue();
        if (this.#checkbox?.mode === TCheckbox.Modes.CONDITION)
            return this.#checkbox.value;
        if (this.#control) {
            const raw = this.#control.value ?? "";
            if (TConfig.IsEmpty(raw))
                return null;
            if (this.#editMask)
                return this.#parseMaskedValue(this.#editMask, raw);
            return raw;
        }
        return null;
    }

    collectRecordValue() {
        if (this.#isConditionField || this.element.style.display === "none")
            return undefined;
        if (this.#checkbox && this.#checkbox.mode !== TCheckbox.Modes.CONDITION)
            return this.#checkbox.value;
        if (this.#dropdown)
            return this.#dropdown.resolveCommittedValue?.() ?? this.#dropdown.getValue();
        if (this.#control) {
            const raw = this.#control.value ?? "";
            if (TConfig.IsEmpty(raw))
                return null;
            if (this.#editMask) {
                const parsed = this.#parseMaskedValue(this.#editMask, raw);
                return TConfig.IsEmpty(parsed) ? null : parsed;
            }
            return raw;
        }
        return undefined;
    }

    collectFilterValue(action) {
        if (!this.#isConditionAction(action))
            return undefined;
        if (this.#isCheckboxInline)
            return this.#checkbox?.value ?? null;
        if (!this.#operatorHost)
            return undefined;

        if (this.#operatorSelect)
            this.#conditionOp = Number(this.#operatorSelect.dataset.value);

        if (this.#conditionValueDropdown && !this.#conditionValueDropdown.isValid())
            return null;

        const comparator = this.#getConditionComparator();
        if (comparator?.ValueMode === "unary")
            return TCondition.pack(this.#conditionOp, null);

        const valuePart = this.#readConditionValuePart();
        return TCondition.pack(this.#conditionOp, valuePart);
    }

    #getConditionComparator() {
        return TSystem.GetComparator(this.#conditionOp);
    }

    #bindOperatorMenuClose() {
        if (TEditBox.#operatorMenuCloseBound)
            return;
        TEditBox.#operatorMenuCloseBound = true;
        document.addEventListener("click", () => {
            for (const shell of document.querySelectorAll(".tedit-operator.open")) {
                shell.classList.remove("open");
                shell.querySelector(".tedit-operator-menu")?.setAttribute("hidden", "");
            }
        });
    }

    #buildOperatorSelect(operators, selectedOp) {
        this.#bindOperatorMenuClose();

        const shell = document.createElement("button");
        shell.type = "button";
        shell.className = "tedit-operator";
        shell.title = "Operador de comparação — clique para alterar";

        const symbol = document.createElement("span");
        symbol.className = "tedit-operator-symbol";
        symbol.setAttribute("aria-hidden", "true");

        const menu = document.createElement("div");
        menu.className = "tedit-operator-menu";
        menu.hidden = true;
        menu.setAttribute("role", "listbox");

        let selectedId = operators.some(op => op.Id === Number(selectedOp))
            ? Number(selectedOp)
            : (operators[0]?.Id ?? TCondition.DEFAULT_OP);

        for (const op of operators) {
            const item = document.createElement("button");
            item.type = "button";
            item.className = "tedit-operator-item";
            item.dataset.value = String(op.Id);
            item.textContent = op.Symbol;
            item.setAttribute("role", "option");
            if (op.Description)
                item.title = op.Description;
            if (op.Id === selectedId)
                item.classList.add("selected");
            item.addEventListener("click", (event) => {
                event.stopPropagation();
                shell.dataset.value = String(op.Id);
                for (const entry of menu.querySelectorAll(".tedit-operator-item"))
                    entry.classList.toggle("selected", entry === item);
                shell.classList.remove("open");
                menu.hidden = true;
                this.#syncOperatorSelectDisplay(shell);
                shell.dispatchEvent(new Event("change", { bubbles: true }));
            });
            menu.append(item);
        }

        shell.dataset.value = String(selectedId);
        shell.addEventListener("click", (event) => {
            event.stopPropagation();
            const willOpen = !shell.classList.contains("open");
            for (const other of document.querySelectorAll(".tedit-operator.open")) {
                other.classList.remove("open");
                other.querySelector(".tedit-operator-menu")?.setAttribute("hidden", "");
            }
            shell.classList.toggle("open", willOpen);
            menu.hidden = !willOpen;
            if (willOpen)
                this.#syncOperatorSelectDisplay(shell);
        });

        shell.append(symbol, menu);
        this.#syncOperatorSelectDisplay(shell);
        return shell;
    }

    #applyOperatorShellWidth(shell, width) {
        shell.style.width = width;
        shell.style.minWidth = width;
        shell.style.maxWidth = width;
        const menu = shell.querySelector(".tedit-operator-menu");
        if (menu) {
            menu.style.width = width;
            menu.style.minWidth = width;
            menu.style.maxWidth = width;
        }
    }

    /** Mede botão e lista sem largura fixa — usa o item mais largo. */
    #measureOperatorBlockWidthPx(shell) {
        const menu = shell.querySelector(".tedit-operator-menu");
        if (!menu)
            return null;
        const prev = {
            hidden: menu.hidden,
            visibility: menu.style.visibility,
            position: menu.style.position,
            pointerEvents: menu.style.pointerEvents,
            menuWidth: menu.style.width,
            menuMinWidth: menu.style.minWidth,
            menuMaxWidth: menu.style.maxWidth,
            shellWidth: shell.style.width,
            shellMinWidth: shell.style.minWidth,
            shellMaxWidth: shell.style.maxWidth,
        };
        menu.hidden = false;
        menu.style.visibility = "hidden";
        menu.style.position = "absolute";
        menu.style.pointerEvents = "none";
        menu.style.width = "auto";
        menu.style.minWidth = "auto";
        menu.style.maxWidth = "none";
        shell.style.width = "auto";
        shell.style.minWidth = "auto";
        shell.style.maxWidth = "none";
        let px = shell.offsetWidth;
        const itemWidths = [];
        for (const entry of menu.querySelectorAll(".tedit-operator-item")) {
            itemWidths.push({ entry, width: entry.style.width });
            entry.style.width = "auto";
            px = Math.max(px, entry.offsetWidth);
        }
        px = Math.max(px, menu.offsetWidth);
        for (const { entry, width } of itemWidths)
            entry.style.width = width;
        menu.hidden = prev.hidden;
        menu.style.visibility = prev.visibility;
        menu.style.position = prev.position;
        menu.style.pointerEvents = prev.pointerEvents;
        menu.style.width = prev.menuWidth;
        menu.style.minWidth = prev.menuMinWidth;
        menu.style.maxWidth = prev.menuMaxWidth;
        shell.style.width = prev.shellWidth;
        shell.style.minWidth = prev.shellMinWidth;
        shell.style.maxWidth = prev.shellMaxWidth;
        return px > 0 ? px : null;
    }

    #syncOperatorSelectDisplay(shell) {
        if (!shell)
            return;
        const symbol = shell.querySelector(".tedit-operator-symbol");
        if (!symbol)
            return;

        const selectedId = shell.dataset.value;
        const item = shell.querySelector(`.tedit-operator-item[data-value="${selectedId}"]`)
            ?? shell.querySelector(".tedit-operator-item");
        const text = item?.textContent ?? "";
        symbol.textContent = text;
        const measuredPx = this.#measureOperatorBlockWidthPx(shell);
        if (measuredPx)
            this.#applyOperatorShellWidth(shell, `${measuredPx}px`);
        else {
            const ch = Math.max(1, text.length);
            this.#applyOperatorShellWidth(shell, `calc(${ch + 2}ch + 0.2dvmin)`);
        }
    }

    #configureCondition(options) {
        const { action, record, sourceRecord, onChange, onConfirm, onCancel, onFirstInput } = options;
        const category = this.#column.Domain.Type.Category;
        const defaultOp = action === TSystem.Actions.SEARCH
            ? TCondition.defaultOpForSearch(category.Name)
            : TCondition.DEFAULT_OP;
        const parsed = this.#normalizeConditionParsed(record[this.#column.Name], defaultOp, category.Id);
        const emit = (valuePart) => {
            if (valuePart === null || valuePart === undefined
                || (Array.isArray(valuePart) && valuePart.length === 0))
                onChange(this.#column.Name, null);
            else
                onChange(this.#column.Name, TCondition.pack(this.#conditionOp, valuePart));
        };

        this.#conditionOp = parsed.comparator ?? defaultOp;

        const operators = TCondition.operatorsForCategory(category.Id);

        this.#operatorHost.replaceChildren();
        this.#operatorShell = this.#buildOperatorSelect(operators, this.#conditionOp);
        this.#operatorSelect = this.#operatorShell;
        this.#operatorHost.append(this.#operatorShell);
        this.#operatorSelect.addEventListener("change", () => {
            this.#syncOperatorSelectDisplay(this.#operatorShell);
            const previousMode = this.#getConditionComparator()?.ValueMode ?? "single";
            this.#conditionOp = Number(this.#operatorSelect.dataset.value);
            const newMode = this.#getConditionComparator()?.ValueMode ?? "single";

            let parsedForRebuild;
            if (previousMode !== newMode) {
                emit(null);
                parsedForRebuild = { comparator: this.#conditionOp, value: null, isNull: false };
            } else {
                parsedForRebuild = this.#normalizeConditionParsed(record[this.#column.Name], defaultOp, category.Id);
            }

            this.#rebuildConditionValue({
                action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit,
                parsed: parsedForRebuild,
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
        const raw = parsed?.value ?? null;
        const innerRecord = { ...record, [this.#column.Name]: raw };
        const innerOnChange = (_name, value) => emit(value);

        this.#conditionValueDropdown = null;
        this.#control = null;
        this.#dropdown = null;
        this.#checkbox = null;
        this.#body.classList.remove("tedit-addable-value");
        this.#body.replaceChildren();

        if (mode === "unary")
            return;

        if (mode === "between") {
            if (this.#isReference) {
                this.#configureReferenceBetween({
                    action, record, sourceRecord, onConfirm, onCancel, onFirstInput, emit, parsed,
                });
                return;
            }

            const slots = comparator.BetweenSlotCount;
            this.#configureScalarAddableList({
                action, onConfirm, onCancel, onFirstInput, emit, parsed,
                maxItems: slots,
                validItemCounts: [0, slots],
                betweenSlots: slots,
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

            this.#configureScalarAddableList({
                action, onConfirm, onCancel, onFirstInput, emit, parsed,
            });
            return;
        }

        if (this.#isReference)
            this.#configureReference({
                action, record: innerRecord, sourceRecord, onChange: innerOnChange,
                onConfirm, onCancel, onFirstInput, valueChange: emit,
            });
        else if (this.#usesValidValuesDropdown())
            this.#configureValidValues({
                action, record: innerRecord, onChange: innerOnChange,
                onConfirm, onCancel, onFirstInput,
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
            this.#captureBehaviorBaseline();
            return this;
        }

        if (this.#isReference)
            this.#configureReference({ ...options, onChange });
        else if (this.#usesValidValuesDropdown())
            this.#configureValidValues({ ...options, onChange });
        else if (this.#usesCheckboxControl())
            this.#configureCheckbox({ ...options, onChange });
        else
            this.#configureNativeInput({ ...options, onChange });

        this.#applyControlWidth();
        this.#syncControlAlignment();
        this.#behaviorHooks = {
            onChange: options.onChange
                ?? ((name, value) => { options.record[name] = value; }),
            action: options.action,
            readOnly: this.#readOnly,
        };
        this.#captureBehaviorBaseline();
        return this;
    }

    #captureBehaviorBaseline() {
        const control = this.#control;
        this.#behaviorContainerClass = this.#root.className;
        this.#behaviorContainerStyle = this.#root.style.cssText;
        this.#behaviorBaseline = {
            display: this.#root.style.display,
            fieldDisabled: this.#rootFieldDisabled(),
            containerClass: this.#behaviorContainerClass,
            containerStyle: this.#behaviorContainerStyle,
            readOnly: this.#readOnly,
            required: this.#isRequired,
            placeholder: control?.placeholder ?? "",
            value: control?.value ?? null,
            maskSpec: this.#behaviorMaskSpec,
        };
    }

    #rootFieldDisabled() {
        if (this.#root.tagName === "FIELDSET")
            return this.#root.disabled;
        return this.#root.dataset.behaviorDisabled === "true";
    }

    resetBehaviorProperties() {
        if (!this.#behaviorBaseline)
            return;

        const baseline = this.#behaviorBaseline;
        this.#root.style.display = baseline.display;
        this.applyContainerEnabled(!baseline.fieldDisabled);
        this.#root.className = baseline.containerClass;
        this.#root.style.cssText = baseline.containerStyle;
        this.#behaviorMaskSpec = baseline.maskSpec;
        if (this.#control) {
            this.#control.required = baseline.required;
            if (baseline.readOnly)
                this.#control.setAttribute("readonly", "readonly");
            else
                this.#control.removeAttribute("readonly");
            if ("placeholder" in this.#control)
                this.#control.placeholder = baseline.placeholder;
        }
    }

    #setFieldDisabled(disabled) {
        if (this.#root.tagName === "FIELDSET") {
            this.#root.disabled = disabled;
            return;
        }
        this.#root.dataset.behaviorDisabled = disabled ? "true" : "false";
    }

    applyContainerEnabled(enabled) {
        this.#setFieldDisabled(!enabled);
    }

    get containerEnabled() {
        return !this.#rootFieldDisabled();
    }

    applyContainerHidden(hidden) {
        this.#root.style.display = hidden
            ? "none"
            : (this.#behaviorBaseline?.display ?? "");
    }

    get containerHidden() {
        return this.#root.style.display === "none";
    }

    applyContainerClass(className) {
        this.#root.className = className ?? "";
    }

    get containerClass() {
        return this.#root.className;
    }

    applyContainerStyle(style) {
        this.#root.style.cssText = style ?? "";
    }

    get containerStyle() {
        return this.#root.style.cssText;
    }

    applyControlReadonly(readOnly) {
        if (!this.#control)
            return;
        if (readOnly)
            this.#control.setAttribute("readonly", "readonly");
        else
            this.#control.removeAttribute("readonly");
    }

    get controlReadonly() {
        return this.#control?.hasAttribute("readonly") ?? false;
    }

    applyControlRequired(required) {
        if (this.#control)
            this.#control.required = required;
    }

    get controlRequired() {
        return this.#control?.required ?? false;
    }

    applyControlValue(value) {
        if (this.#control)
            this.#control.value = value ?? "";
    }

    get controlValue() {
        return this.#control?.value ?? null;
    }

    applyControlAttribute(name, value) {
        if (!this.#control)
            return;
        if (value === null || value === undefined || value === "")
            this.#control.removeAttribute(name);
        else
            this.#control.setAttribute(name, value);
    }

    controlAttribute(name) {
        return this.#control?.getAttribute(name) ?? "";
    }

    applyBehaviorMask(spec) {
        if (!this.#control || !this.#behaviorHooks?.onChange || this.#behaviorHooks.readOnly)
            return;

        const editMask = TEditBox.#editMaskFromSpec(spec, this.#effectiveDomain());
        if (!editMask)
            return;

        this.#behaviorMaskSpec = spec;
        this.#editMask = editMask;
        const rawValue = this.#control.value ?? "";
        this.#control.value = this.#formatRawValue(editMask, rawValue);
        this.#applyEditMask(
            this.#control,
            editMask,
            false,
            this.#behaviorHooks.onChange,
            this.#behaviorHooks.action,
        );
    }

    get behaviorMaskSpec() {
        return this.#behaviorMaskSpec;
    }

    applyBehavior(propertyId, value) {
        const property = TSystem.GetProperty(propertyId);
        if (!property?.Name)
            return;
        TProperty.apply(this, property.Name, value);
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
