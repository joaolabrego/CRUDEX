"use strict";

export default class TDropdown {
    static Modes = {
        SINGLE: "single",
        MULTI: "multi",
        ADDABLE: "addable",
        CARDINALITY: "cardinality",
    };

    static #Style = "";
    static #StyleInjected = false;

    #container = null;
    #mode = TDropdown.Modes.SINGLE;
    #catalog = [];
    #filtered = [];
    #selected = [];
    #itemsPerPage = 5;
    #currentPage = 0;
    #idField = "Id";
    #labelField = "Name";
    #placeholder = "";
    #minItems = 0;
    #maxItems = Infinity;
    #exactItems = null;
    #requireExact = false;
    #unique = true;
    #valueAs = "item";
    #required = false;
    #allowEmpty = false;
    #readOnly = false;
    #manualValues = [];

    #inputWrap = null;
    #input = null;
    #trigger = null;
    #plus = null;
    #icon = null;
    #list = null;
    #itemsBox = null;
    #prevBtn = null;
    #nextBtn = null;
    #hint = null;
    #handleOutside = null;
    #handleGlobal = null;
    #loader = null;
    #recordSet = null;
    #records = new Map();
    #query = "";
    #serverPage = 1;
    #serverPageCount = 1;

    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        TDropdown.#Style = styles.DropDown ?? "";
    }

    static Create(container, options = {}) {
        return new TDropdown(container, options);
    }

    static Single(container, options = {}) {
        return new TDropdown(container, { ...options, mode: TDropdown.Modes.SINGLE });
    }

    static Multi(container, options = {}) {
        return new TDropdown(container, { ...options, mode: TDropdown.Modes.MULTI });
    }

    static Addable(container, options = {}) {
        return new TDropdown(container, { ...options, mode: TDropdown.Modes.ADDABLE });
    }

    static Cardinality(container, options = {}) {
        return new TDropdown(container, { ...options, mode: TDropdown.Modes.CARDINALITY });
    }

    constructor(container, options = {}) {
        if (!container)
            throw new Error("Container element is required.");

        TDropdown.#injectStyle();
        this.#container = container;
        this.#container.classList.add("tdropdown");

        this.#mode = options.mode ?? TDropdown.Modes.SINGLE;
        this.#itemsPerPage = options.itemsPerPage ?? 5;
        this.#idField = options.idField ?? "Id";
        this.#labelField = options.labelField ?? "Name";
        this.#placeholder = options.placeholder ?? "";
        this.#minItems = options.minItems ?? 0;
        this.#maxItems = options.maxItems ?? Infinity;
        this.#exactItems = options.exactItems ?? null;
        this.#requireExact = options.requireExact ?? false;
        this.#unique = options.unique ?? true;
        this.#valueAs = options.valueAs ?? "item";
        this.#required = options.required ?? false;
        this.#allowEmpty = options.allowEmpty ?? !this.#required;
        this.#readOnly = options.readOnly ?? false;
        this.#loader = options.loader ?? null;

        if (this.#mode === TDropdown.Modes.CARDINALITY && this.#exactItems != null) {
            this.#maxItems = this.#exactItems;
            if (this.#requireExact)
                this.#minItems = this.#exactItems;
        }

        this.#catalog = (options.data ?? options.catalog ?? [])
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField))
            .filter(Boolean);

        this.#buildDom();
        this.#applyReadOnlyState();
        this.#bindEvents();

        if (options.value !== undefined && options.value !== null && options.value !== "")
            this.setValue(options.value);
        else if (this.#isAddableMode())
            this.#manualValues = [];
        else
            this.#clearSingle();

        this.#refresh();
    }

    static #emptyItem() {
        return { id: null, label: "", raw: null, isEmpty: true };
    }

    #clearSingle() {
        this.#selected = [];
        if (this.#input)
            this.#input.value = "";
    }

    static #injectStyle() {
        if (TDropdown.#StyleInjected || !TDropdown.#Style)
            return;
        const style = document.createElement("style");
        style.dataset.crudex = "tdropdown";
        style.textContent = TDropdown.#Style;
        document.head.append(style);
        TDropdown.#StyleInjected = true;
    }

    static #normalizeItem(item, idField, labelField) {
        if (item === null || item === undefined)
            return null;
        if (typeof item === "string" || typeof item === "number")
            return { id: item, label: String(item), raw: item };
        const id = item[idField] ?? item.Id ?? item.ListItemId ?? item.id;
        const label = item[labelField] ?? item.ListItemValue ?? item.Name
            ?? item.ListItemName ?? item.label ?? String(id ?? "");
        return { id, label, raw: item };
    }

    #isListMode() {
        return this.#mode === TDropdown.Modes.MULTI
            || this.#mode === TDropdown.Modes.ADDABLE
            || this.#mode === TDropdown.Modes.CARDINALITY;
    }

    #isAddableMode() {
        return this.#mode === TDropdown.Modes.ADDABLE
            || this.#mode === TDropdown.Modes.CARDINALITY;
    }

    #buildDom() {
        this.#inputWrap = document.createElement("div");
        this.#inputWrap.className = "tdropdown-input-wrap";
        this.#container.append(this.#inputWrap);

        if (this.#mode === TDropdown.Modes.MULTI) {
            this.#trigger = document.createElement("button");
            this.#trigger.type = "button";
            this.#trigger.className = "tdropdown-trigger";
            this.#trigger.textContent = this.#placeholder || "Selecionar...";
            this.#inputWrap.append(this.#trigger);
        } else {
            this.#input = document.createElement("input");
            this.#input.type = "text";
            this.#input.className = "tdropdown-input";
            this.#input.placeholder = this.#placeholder;
            this.#input.autocomplete = "off";
            this.#inputWrap.append(this.#input);

            if (this.#isAddableMode()) {
                this.#plus = document.createElement("span");
                this.#plus.className = "tdropdown-plus";
                this.#plus.title = "Adicionar";
                this.#plus.textContent = "+";
                this.#inputWrap.append(this.#plus);
            }
        }

        this.#icon = document.createElement("span");
        this.#icon.className = "tdropdown-icon";
        this.#icon.textContent = "▼";
        this.#inputWrap.append(this.#icon);

        this.#list = document.createElement("div");
        this.#list.className = "tdropdown-list";
        this.#inputWrap.append(this.#list);

        this.#itemsBox = document.createElement("div");
        this.#list.append(this.#itemsBox);

        const pagination = document.createElement("div");
        pagination.className = "tdropdown-pagination";
        this.#list.append(pagination);

        this.#prevBtn = document.createElement("button");
        this.#prevBtn.type = "button";
        this.#prevBtn.textContent = "◄";
        this.#prevBtn.disabled = true;
        pagination.append(this.#prevBtn);

        this.#nextBtn = document.createElement("button");
        this.#nextBtn.type = "button";
        this.#nextBtn.textContent = "►";
        pagination.append(this.#nextBtn);

        if (this.#mode === TDropdown.Modes.CARDINALITY) {
            this.#hint = document.createElement("div");
            this.#hint.className = "tdropdown-hint";
            this.#container.append(this.#hint);
        }
    }

    #applyReadOnlyState() {
        if (!this.#readOnly)
            return;
        this.#container.classList.add("tdropdown-readonly");
        if (this.#input) {
            this.#input.readOnly = true;
            this.#input.placeholder = "";
        }
        if (this.#icon)
            this.#icon.style.visibility = "hidden";
        if (this.#plus)
            this.#plus.style.visibility = "hidden";
        this.#hideList();
    }

    #bindEvents() {
        const openControl = this.#input ?? this.#trigger;

        if (!this.#readOnly) {
            this.#icon.addEventListener("mousedown", (e) => {
                e.preventDefault();
                openControl?.focus();
                this.#toggleList();
            });
        }

        if (this.#input && !this.#readOnly) {
            this.#input.addEventListener("input", (e) => {
                void this.#filterItems(e.target.value.trim());
                this.#showList();
            });
            this.#input.addEventListener("click", (e) => {
                e.stopPropagation();
                void this.#toggleList();
            });
            this.#input.addEventListener("blur", () => {
                this.#revertInput();
                this.#hideList();
            });
        }

        if (this.#trigger) {
            this.#trigger.addEventListener("click", (e) => {
                e.stopPropagation();
                this.#toggleList();
            });
        }

        if (this.#plus) {
            this.#plus.addEventListener("mousedown", (e) => {
                e.preventDefault();
                this.#addFromInput();
            });
            this.#input.addEventListener("keydown", (e) => {
                if (e.key === "Enter") {
                    e.preventDefault();
                    if (this.#isAddableMode())
                        this.#addFromInput();
                }
            });
        }

        this.#prevBtn.addEventListener("click", () => this.#changePage(-1));
        this.#nextBtn.addEventListener("click", () => this.#changePage(1));

        document.addEventListener("mousedown", this.#handleOutside = (e) => {
            if (!this.#container.contains(e.target))
                this.#hideList();
        });

        window.addEventListener("dropdownOpened", this.#handleGlobal = (e) => {
            if (e.detail.dropdown !== this)
                this.#hideList();
        });

        this.#list.addEventListener("mousedown", (e) => e.preventDefault());
    }

    #sourceItems() {
        if (this.#isAddableMode())
            return this.#manualValues.map(v => TDropdown.#normalizeItem(v, this.#idField, this.#labelField));
        return this.#catalog;
    }

    async #filterItems(query) {
        this.#query = query;
        if (this.#loader) {
            await this.#loadServerPage(1);
            return;
        }
        const source = this.#isAddableMode() ? this.#sourceItems() : this.#catalog;
        const needle = query.toLowerCase();
        this.#filtered = needle
            ? source.filter(item => item.label.toLowerCase().includes(needle))
            : [...source];
        this.#currentPage = 0;
        this.#renderItems();
    }

    async #changePage(delta) {
        if (this.#loader) {
            const next = this.#serverPage + delta;
            if (next < 1 || next > this.#serverPageCount)
                return;
            await this.#loadServerPage(next);
            return;
        }
        const pages = Math.max(1, Math.ceil(this.#filtered.length / this.#itemsPerPage));
        this.#currentPage = Math.min(Math.max(this.#currentPage + delta, 0), pages - 1);
        this.#renderItems();
    }

    #mergeCatalog(items) {
        for (const item of items) {
            if (!this.#catalog.some(c => c.id == item.id))
                this.#catalog.push(item);
        }
    }

    async #loadServerPage(page) {
        const result = await this.#loader(this.#query, page);
        this.#serverPage = result.pageNumber ?? page;
        this.#serverPageCount = Math.max(1, result.pageCount ?? 1);
        const items = (result.items ?? [])
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField))
            .filter(Boolean);
        this.#filtered = items;
        this.#mergeCatalog(items);
        this.#mergeRecordSet(result);
        if (this.#selected[0])
            this.#mergeCatalog(this.#selected);
        this.#currentPage = 0;
        this.#renderItems();
    }

    #mergeRecordSet(result) {
        if (!result?.recordSet)
            return;
        this.#recordSet = result.recordSet;
        for (const record of result.records ?? result.recordSet.records ?? [])
            this.#records.set(record.Id, record);
    }

    #renderItems() {
        const start = this.#currentPage * this.#itemsPerPage;
        const end = start + this.#itemsPerPage;
        const pageItems = this.#loader
            ? this.#filtered
            : this.#filtered.slice(start, end);

        this.#itemsBox.replaceChildren();

        if (this.#allowEmpty && this.#mode === TDropdown.Modes.SINGLE) {
            const emptyRow = document.createElement("div");
            emptyRow.className = "tdropdown-item";
            const emptyLabel = document.createElement("div");
            emptyLabel.className = "tdropdown-label";
            emptyLabel.textContent = "";
            emptyRow.append(emptyLabel);
            emptyRow.addEventListener("click", () => this.#selectSingle(TDropdown.#emptyItem()));
            this.#itemsBox.append(emptyRow);
        }

        pageItems.forEach((item) => {
            const row = document.createElement("div");
            row.className = "tdropdown-item";

            if (this.#mode === TDropdown.Modes.MULTI) {
                const check = document.createElement("input");
                check.type = "checkbox";
                check.className = "tdropdown-check";
                check.checked = this.#isSelected(item);
                check.addEventListener("change", (e) => {
                    e.stopPropagation();
                    this.#toggleSelected(item);
                });
                row.append(check);
            }

            const label = document.createElement("div");
            label.className = "tdropdown-label";
            label.textContent = item.label;
            row.append(label);

            if (this.#isAddableMode()) {
                const del = document.createElement("button");
                del.type = "button";
                del.className = "tdropdown-del";
                del.title = "Remover";
                del.textContent = "−";
                del.addEventListener("click", (e) => {
                    e.stopPropagation();
                    this.#removeManual(item.label);
                });
                row.append(del);
            }

            if (this.#mode === TDropdown.Modes.SINGLE) {
                row.addEventListener("click", () => this.#selectSingle(item));
            } else if (this.#isAddableMode()) {
                row.addEventListener("click", () => {
                    if (this.#input)
                        this.#input.value = item.label;
                    this.#hideList();
                });
            } else {
                row.addEventListener("click", (e) => {
                    if (e.target.type !== "checkbox")
                        this.#toggleSelected(item);
                });
            }

            this.#itemsBox.append(row);
        });

        this.#updatePagination();
        if (this.#filtered.length === 0)
            this.#hideList();
    }

    #updatePagination() {
        if (this.#loader) {
            this.#prevBtn.disabled = this.#serverPage <= 1;
            this.#nextBtn.disabled = this.#serverPage >= this.#serverPageCount;
            this.#prevBtn.parentElement.style.display = this.#serverPageCount > 1 ? "flex" : "none";
            return;
        }
        const pages = Math.ceil(this.#filtered.length / this.#itemsPerPage) || 1;
        this.#prevBtn.disabled = this.#currentPage === 0;
        this.#nextBtn.disabled = this.#currentPage >= pages - 1;
        this.#prevBtn.parentElement.style.display = pages > 1 ? "flex" : "none";
    }

    #showList() {
        if (this.#readOnly)
            return;
        window.dispatchEvent(new CustomEvent("dropdownOpened", {
            detail: { dropdown: this },
            bubbles: true,
        }));

        const anchor = this.#input ?? this.#trigger;
        this.#list.style.visibility = "hidden";
        this.#list.style.display = "block";

        const rect = anchor.getBoundingClientRect();
        const height = this.#list.scrollHeight;
        const below = window.innerHeight - rect.bottom;
        const above = rect.top;

        if (below < height && above > height) {
            this.#list.style.top = "auto";
            this.#list.style.bottom = `${anchor.offsetHeight}px`;
        } else {
            this.#list.style.top = "calc(100% + .8dvmin)";
            this.#list.style.bottom = "auto";
        }

        this.#list.style.visibility = "visible";
        this.#list.classList.add("open");
    }

    #hideList() {
        this.#list.classList.remove("open");
        this.#list.style.display = "none";
        this.#list.style.top = "";
        this.#list.style.bottom = "";
    }

    #revertInput() {
        if (this.#mode !== TDropdown.Modes.SINGLE || !this.#input)
            return;
        this.#query = "";
        if (this.#selected[0])
            this.#input.value = this.#selected[0].label;
        else
            this.#input.value = "";
    }

    async #openList() {
        this.#query = "";
        if (this.#loader)
            await this.#loadServerPage(1);
        else if (!this.#isAddableMode())
            this.#filtered = [...this.#catalog];
        this.#showList();
    }

    #toggleList() {
        if (this.#list.classList.contains("open")) {
            this.#hideList();
            return;
        }
        void this.#openList();
    }

    #isSelected(item) {
        return this.#selected.some(s => s.id === item.id && s.label === item.label);
    }

    #selectSingle(item) {
        if (item?.isEmpty) {
            this.#clearSingle();
            this.#hideList();
            this.#renderItems();
            this.#emitChange();
            this.#updateValidity();
            return;
        }
        this.#selected = [item];
        if (this.#input)
            this.#input.value = item.label;
        this.#hideList();
        this.#emitChange();
        this.#updateValidity();
    }

    #toggleSelected(item) {
        if (this.#isSelected(item))
            this.#selected = this.#selected.filter(s => !(s.id === item.id && s.label === item.label));
        else
            this.#selected.push(item);
        this.#updateTriggerLabel();
        this.#renderItems();
        this.#emitChange();
        this.#updateValidity();
    }

    #updateTriggerLabel() {
        if (!this.#trigger)
            return;
        const labels = this.#selected.map(s => s.label);
        this.#trigger.textContent = labels.length
            ? labels.join(", ")
            : (this.#placeholder || "Selecionar...");
    }

    #sanitize(value) {
        return (value ?? "").trim();
    }

    #existsManual(value) {
        const needle = value.toLowerCase();
        return this.#unique && this.#manualValues.some(v => String(v).toLowerCase() === needle);
    }

    #addFromInput() {
        const value = this.#sanitize(this.#input?.value);
        if (!value)
            return;
        if (this.#existsManual(value))
            return;
        if (this.#manualValues.length >= this.#maxItems)
            return;

        const catalogHit = this.#catalog.find(c => c.label.toLowerCase() === value.toLowerCase());
        this.#manualValues.push(catalogHit ? catalogHit.raw : value);
        this.#manualValues.sort((a, b) => String(a).localeCompare(String(b), undefined, { sensitivity: "base" }));

        if (this.#input) {
            this.#input.value = "";
            this.#filterItems("");
        }
        this.#showList();
        this.#emitChange();
        this.#updateValidity();
    }

    #removeManual(label) {
        const needle = label.toLowerCase();
        const before = this.#manualValues.length;
        this.#manualValues = this.#manualValues.filter(v => {
            const item = TDropdown.#normalizeItem(v, this.#idField, this.#labelField);
            return item.label.toLowerCase() !== needle;
        });
        if (this.#manualValues.length !== before) {
            this.#filterItems(this.#input?.value.trim() ?? "");
            if (this.#filtered.length === 0 && this.#currentPage > 0)
                this.#changePage(-1);
            this.#emitChange();
            this.#updateValidity();
        }
    }

    #emitChange() {
        this.#container.dispatchEvent(new CustomEvent("change", {
            detail: { value: this.getValue(), valid: this.isValid() },
            bubbles: true,
        }));
    }

    #refresh() {
        if (this.#isAddableMode())
            void this.#filterItems(this.#input?.value.trim() ?? "");
        else if (!this.#loader)
            this.#filtered = [...this.#catalog];
        this.#updateTriggerLabel();
        this.#updateValidity();
        if (!this.#loader)
            this.#renderItems();
    }

    #updateValidity() {
        const valid = this.isValid();
        this.syncFormValidity();
        if (this.#input)
            this.#input.classList.toggle("invalid", !valid);
        if (this.#hint) {
            const count = this.#manualValues.length;
            const target = this.#exactItems ?? this.#minItems;
            this.#hint.textContent = this.#requireExact && this.#exactItems != null
                ? `Informe exatamente ${this.#exactItems} item(ns). Atual: ${count}.`
                : `Mínimo ${this.#minItems}, máximo ${this.#maxItems}. Atual: ${count}.`;
            this.#hint.classList.toggle("invalid", !valid);
        }
    }

    #exportItem(item) {
        if (!item)
            return null;
        return this.#valueAs === "id" ? item.id : item;
    }

    setCatalog(data) {
        this.#catalog = (data ?? [])
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField))
            .filter(Boolean);
        if (this.#itemsBox)
            this.#refresh();
    }

    #resolveItem(item) {
        if (item === null || item === undefined)
            return null;
        if (typeof item === "object")
            return TDropdown.#normalizeItem(item, this.#idField, this.#labelField);
        const hit = this.#catalog.find(c => c.id == item);
        if (hit)
            return hit;
        return TDropdown.#normalizeItem(item, this.#idField, this.#labelField);
    }

    setValue(value) {
        if (this.#mode === TDropdown.Modes.SINGLE) {
            const item = Array.isArray(value) ? value[0] : value;
            if (item === null || item === undefined || item === "") {
                this.#clearSingle();
            } else {
                const resolved = this.#resolveItem(item);
                this.#selected = resolved ? [resolved] : [];
                if (this.#input)
                    this.#input.value = this.#selected[0]?.label ?? "";
            }
        } else if (this.#isAddableMode()) {
            this.#manualValues = Array.isArray(value) ? [...value] : (value ? [value] : []);
        } else {
            const list = Array.isArray(value) ? value : (value ? [value] : []);
            this.#selected = list
                .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField))
                .filter(Boolean);
            this.#updateTriggerLabel();
        }
        this.#refresh();
        this.#emitChange();
    }

    getValue() {
        if (this.#mode === TDropdown.Modes.SINGLE)
            return this.#exportItem(this.#selected[0] ?? null);
        if (this.#isAddableMode())
            return this.#manualValues.map(v => {
                const item = TDropdown.#normalizeItem(v, this.#idField, this.#labelField);
                return this.#valueAs === "id" ? item.id : (typeof v === "object" ? v : item);
            });
        return this.#selected.map(item => this.#exportItem(item));
    }

    getValues() {
        return this.getValue();
    }

    isValid() {
        if (this.#mode === TDropdown.Modes.SINGLE) {
            if (!this.#required)
                return true;
            return this.#selected.length === 1;
        }

        const count = this.#isAddableMode() ? this.#manualValues.length : this.#selected.length;

        if (this.#exactItems != null && this.#requireExact)
            return count === this.#exactItems;
        if (this.#requireExact && this.#minItems === this.#maxItems)
            return count === this.#minItems;
        return count >= this.#minItems && count <= this.#maxItems;
    }

    syncFormValidity() {
        if (!this.#input || this.#readOnly) {
            this.#input?.setCustomValidity("");
            return;
        }
        if (this.#required && !this.isValid())
            this.#input.setCustomValidity("Informe um valor.");
        else
            this.#input.setCustomValidity("");
    }

    get element() {
        return this.#container;
    }

    get input() {
        return this.#input ?? this.#trigger;
    }

    get recordSet() {
        return this.#recordSet;
    }

    get records() {
        return this.#records;
    }

    getRecord(id) {
        return this.#records.get(id) ?? null;
    }

    destroy() {
        document.removeEventListener("mousedown", this.#handleOutside);
        window.removeEventListener("dropdownOpened", this.#handleGlobal);
        this.#container.replaceChildren();
        this.#container.classList.remove("tdropdown");
    }
}
