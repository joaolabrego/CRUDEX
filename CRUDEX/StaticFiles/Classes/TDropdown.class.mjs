"use strict";

import TCheckbox from "./TCheckbox.class.mjs";
import TSystem from "./TSystem.class.mjs";

export default class TDropdown {
    static Modes = {
        SINGLE: "single",
        MULTI: "multi",
        ADDABLE: "addable",
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
    #titleField = null;
    #placeholder = "";
    #minItems = 0;
    #maxItems = Infinity;
    #exactItems = null;
    #requireExact = false;
    #validItemCounts = null;
    #unique = true;
    #valueAs = "item";
    #required = false;
    #allowEmpty = false;
    #readOnly = false;
    #manualValues = [];
    #parseValue = null;
    #formatItem = null;
    #formatInput = null;

    #inputWrap = null;
    #input = null;
    #trigger = null;
    #plus = null;
    #icon = null;
    #list = null;
    #itemsBox = null;
    #prevBtn = null;
    #nextBtn = null;
    #listSearch = false;
    #handleOutside = null;
    #handleGlobal = null;
    #loader = null;
    #recordSet = null;
    #records = new Map();
    #query = "";
    #serverPage = 1;
    #serverPageCount = 1;
    #paginate = true;
    #collapseSelectionOnBlur = false;
    #inputEditing = false;

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

    constructor(container, options = {}) {
        if (!container)
            throw new Error("Container element is required.");

        TDropdown.#injectStyle();
        this.#container = container;
        this.#container.classList.add("tdropdown");
        if (options.mode === TDropdown.Modes.ADDABLE)
            this.#container.classList.add("tdropdown-addable");

        this.#mode = options.mode ?? TDropdown.Modes.SINGLE;
        this.#itemsPerPage = options.itemsPerPage ?? 5;
        this.#idField = options.idField ?? "Id";
        this.#labelField = options.labelField ?? "Name";
        this.#titleField = options.titleField ?? null;
        this.#placeholder = options.placeholder ?? "";
        if (options.containerClass)
            this.#container.classList.add(options.containerClass);
        this.#minItems = options.minItems ?? 0;
        this.#maxItems = options.maxItems ?? Infinity;
        this.#exactItems = options.exactItems ?? null;
        this.#requireExact = options.requireExact ?? false;
        this.#validItemCounts = options.validItemCounts ?? null;
        this.#unique = options.unique ?? true;
        this.#valueAs = options.valueAs ?? "item";
        this.#required = options.required ?? false;
        this.#allowEmpty = options.allowEmpty ?? !this.#required;
        this.#readOnly = options.readOnly ?? false;
        this.#parseValue = options.parseValue ?? null;
        this.#formatItem = options.formatItem ?? null;
        this.#formatInput = options.formatInput ?? null;
        this.#loader = options.loader ?? null;
        this.#paginate = options.paginate !== false;
        this.#collapseSelectionOnBlur = options.collapseSelectionOnBlur === true;
        this.#listSearch = options.listSearch === true || (this.#mode === TDropdown.Modes.MULTI && this.#loader != null);
        if (this.#mode === TDropdown.Modes.MULTI && this.#listSearch && options.collapseSelectionOnBlur !== false)
            this.#collapseSelectionOnBlur = true;

        if (options.paginate === false)
            this.#itemsPerPage = options.itemsPerPage ?? Number.MAX_SAFE_INTEGER;
        else if (options.itemsPerPage != null)
            this.#itemsPerPage = options.itemsPerPage;

        if (this.#mode === TDropdown.Modes.MULTI && this.#exactItems != null) {
            this.#maxItems = this.#exactItems;
            if (this.#requireExact)
                this.#minItems = this.#exactItems;
        }

        this.#catalog = (options.data ?? options.catalog ?? [])
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField))
            .filter(Boolean);

        this.#buildDom();
        this.#applyRequiredConstraints();
        this.#applyReadOnlyState();
        this.#bindEvents();

        if (options.value !== undefined && options.value !== null && options.value !== ""
            && !TCheckbox.isNullMarker(options.value)) {
            this.setValue(options.value, false);
        } else if (this.#isAddableMode())
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
        if (this.#input) {
            this.#input.value = "";
            this.#input.title = "";
            this.#input.classList.remove("tdropdown-collapsed");
        }
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

    static #normalizeItem(item, idField, labelField, titleField = null) {
        if (item === null || item === undefined)
            return null;
        if (typeof item === "string" || typeof item === "number")
            return { id: item, label: String(item), title: "", raw: item };
        const id = item[idField] ?? item.Id ?? item.ListItemId ?? item.id;
        const label = item[labelField] ?? item.ListItemValue ?? item.Name
            ?? item.ListItemName ?? item.label ?? String(id ?? "");
        const title = titleField
            ? (item[titleField] ?? item.Description ?? "")
            : "";
        return { id, label, title, raw: item };
    }

    #isAddableMode() {
        return this.#mode === TDropdown.Modes.ADDABLE;
    }

    #usesInputFilter() {
        return this.#mode === TDropdown.Modes.MULTI && this.#listSearch;
    }

    #buildDom() {
        this.#inputWrap = document.createElement("div");
        this.#inputWrap.className = "tdropdown-input-wrap";
        this.#container.append(this.#inputWrap);

        if (this.#mode === TDropdown.Modes.MULTI && !this.#usesInputFilter()) {
            this.#trigger = document.createElement("button");
            this.#trigger.type = "button";
            this.#trigger.className = "tdropdown-trigger";
            this.#trigger.textContent = this.#placeholder || "Selecionar...";
            this.#inputWrap.append(this.#trigger);
        } else {
            this.#input = document.createElement("input");
            this.#input.type = "text";
            this.#input.className = "tdropdown-input";
            this.#input.placeholder = this.#usesInputFilter()
                ? (this.#placeholder || "Selecionar...")
                : this.#placeholder;
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
        this.#itemsBox.className = "tdropdown-items";
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
    }

    #applyRequiredConstraints() {
        if (!this.#input || this.#readOnly)
            return;
        this.#input.removeAttribute("required");
    }

    #applyReadOnlyState() {
        this.#container.classList.toggle("tdropdown-readonly", this.#readOnly);
        if (this.#input) {
            if (this.#readOnly) {
                this.#input.readOnly = true;
                this.#input.placeholder = "";
            } else {
                this.#input.removeAttribute("readonly");
            }
        }
        if (this.#icon)
            this.#icon.style.visibility = this.#readOnly ? "hidden" : "";
        if (this.#plus)
            this.#plus.hidden = this.#readOnly;
        if (this.#readOnly)
            this.#hideList();
    }

    setReadOnly(readOnly) {
        const next = readOnly === true;
        if (this.#readOnly === next)
            return;
        this.#readOnly = next;
        this.#applyReadOnlyState();
    }

    get readOnly() {
        return this.#readOnly;
    }

    #bindEvents() {
        const openControl = this.#input ?? this.#trigger;

        if (!this.#readOnly) {
            this.#container.addEventListener("mousedown", () => this.dismissValidityBalloon());
            this.#icon.addEventListener("mousedown", (e) => {
                e.preventDefault();
                openControl?.focus();
                this.#toggleList();
            });
        }

        if (this.#input && !this.#readOnly) {
            this.#input.addEventListener("input", (e) => {
                this.dismissValidityBalloon();
                if (this.#formatInput)
                    this.#formatInput(this.#input);
                void this.#filterItems(e.target.value.trim());
                this.#showList();
            });
            this.#input.addEventListener("focus", () => {
                if (!this.#collapseSelectionOnBlur)
                    return;
                if (!this.#isAddableMode() && !this.#usesInputFilter())
                    return;
                this.#inputEditing = true;
                this.#clearInputForEdit();
            });
            this.#input.addEventListener("click", (e) => {
                e.stopPropagation();
                void this.#toggleList();
            });
            this.#input.addEventListener("blur", () => {
                if (this.#usesInputFilter()) {
                    this.#inputEditing = false;
                    this.#query = "";
                    this.#applyFilterInputDisplay();
                    this.#hideList();
                    this.#updateValidity();
                    return;
                }
                if (this.#collapseSelectionOnBlur && this.#isAddableMode()) {
                    this.#inputEditing = false;
                    this.#applyCollapsedInput();
                    this.#hideList();
                    this.#updateValidity();
                    return;
                }
                if (this.#mode === TDropdown.Modes.SINGLE) {
                    this.#finishSingleBlur();
                    return;
                }
                this.#commitPendingInput(false);
                this.#revertInput();
                this.#hideList();
                this.#updateValidity();
            });
        }

        if (this.#trigger) {
            if (this.#collapseSelectionOnBlur) {
                const beginTriggerEdit = () => {
                    this.#inputEditing = true;
                    this.#trigger.textContent = "";
                    this.#trigger.title = "";
                    this.#trigger.classList.remove("tdropdown-collapsed");
                };
                this.#trigger.addEventListener("mousedown", beginTriggerEdit);
                this.#trigger.addEventListener("focus", beginTriggerEdit);
                this.#trigger.addEventListener("blur", () => {
                    this.#inputEditing = false;
                    this.#updateTriggerLabel();
                });
            }
            this.#trigger.addEventListener("click", (e) => {
                e.stopPropagation();
                this.dismissValidityBalloon();
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
        if (this.#isAddableMode()) {
            return this.#manualValues.map((value) => {
                const label = this.#formatItem ? this.#formatItem(value) : String(value ?? "");
                return { id: value, label, raw: value };
            });
        }
        return this.#catalog;
    }

    #parseInputValue(display) {
        const text = this.#sanitize(display);
        if (!text)
            return null;
        if (this.#parseValue) {
            const parsed = this.#parseValue(text);
            return parsed === null || parsed === undefined ? null : parsed;
        }
        return text;
    }

    #existsManual(value) {
        if (!this.#unique)
            return false;
        return this.#manualValues.some(v => v == value);
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
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField))
            .filter(Boolean);
        this.#filtered = items;
        this.#mergeCatalog(items);
        this.#mergeRecordSet(result);
        if (this.#selected.length)
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
            : this.#paginate
                ? this.#filtered.slice(start, end)
                : this.#filtered;

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
            const selected = this.#isSelected(item);
            const atMax = this.#selected.length >= this.#maxItems;

            if (this.#mode === TDropdown.Modes.MULTI) {
                const check = document.createElement("input");
                check.type = "checkbox";
                check.className = "tdropdown-check";
                check.checked = selected;
                check.disabled = atMax && !selected;
                check.addEventListener("change", (e) => {
                    e.stopPropagation();
                    this.#toggleSelected(item);
                });
                row.append(check);
                if (atMax && !selected)
                    row.classList.add("tdropdown-item-disabled");
            }

            const label = document.createElement("div");
            label.className = "tdropdown-label";
            label.textContent = item.label;
            if (item.title)
                row.title = item.title;
            row.append(label);

            if (this.#isAddableMode()) {
                const del = document.createElement("button");
                del.type = "button";
                del.className = "tdropdown-del";
                del.title = "Remover";
                del.textContent = "−";
                del.addEventListener("mousedown", (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    this.#removeManual(item.raw);
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
                    if (e.target.type === "checkbox")
                        return;
                    if (!selected && atMax)
                        return;
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
        if (!this.#paginate) {
            this.#prevBtn.parentElement.style.display = "none";
            return;
        }
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
        const openUp = below < height && above > height;

        if (openUp) {
            this.#list.style.top = "auto";
            this.#list.style.bottom = `${anchor.offsetHeight}px`;
        } else {
            this.#list.style.top = "calc(100% + .8dvmin)";
            this.#list.style.bottom = "auto";
        }

        this.#itemsBox.classList.toggle(
            "tdropdown-items-open-up-reverse",
            openUp && TSystem.ReverseItemsWhenOpenUp,
        );

        this.#list.style.visibility = "visible";
        this.#list.classList.add("open");
    }

    #hideList() {
        this.#list.classList.remove("open");
        this.#list.style.display = "none";
        this.#list.style.top = "";
        this.#list.style.bottom = "";
        this.#itemsBox.classList.remove("tdropdown-items-open-up-reverse");
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
        this.#query = this.#input?.value.trim() ?? "";
        if (this.#loader)
            await this.#loadServerPage(1);
        else if (this.#isAddableMode())
            void this.#filterItems(this.#input?.value.trim() ?? "");
        else
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
        if (this.#input) {
            this.#input.value = item.label;
            this.#input.title = item.title ?? "";
        }
        this.#hideList();
        this.#emitChange();
        this.#updateValidity();
    }

    #toggleSelected(item) {
        if (this.#isSelected(item))
            this.#selected = this.#selected.filter(s => !(s.id === item.id && s.label === item.label));
        else {
            if (this.#selected.length >= this.#maxItems)
                return;
            this.#selected.push(item);
        }
        this.#updateTriggerLabel();
        this.#renderItems();
        this.#emitChange();
        this.#updateValidity();
    }

    #updateTriggerLabel() {
        if (!this.#trigger)
            return;
        if (this.#collapseSelectionOnBlur && this.#inputEditing)
            return;
        const labels = this.#selected.map(s => s.label);
        const full = labels.join(", ");
        this.#trigger.textContent = full || (this.#placeholder || "Selecionar...");
        this.#trigger.title = full;
        this.#trigger.classList.toggle("tdropdown-collapsed", !!full);
    }

    #sanitize(value) {
        return (value ?? "").trim();
    }

    #formatSelectedLabels() {
        if (this.#isAddableMode()) {
            return this.#manualValues
                .map(value => (this.#formatItem ? this.#formatItem(value) : String(value ?? "")))
                .filter(label => label !== "")
                .join(", ");
        }
        return this.#selected.map(item => item.label).join(", ");
    }

    #applyFilterInputDisplay() {
        if (!this.#input)
            return;
        const full = this.#formatSelectedLabels();
        if (full) {
            this.#input.value = full;
            this.#input.title = full;
            this.#input.classList.add("tdropdown-collapsed");
        } else {
            this.#input.value = "";
            this.#input.title = "";
            this.#input.classList.remove("tdropdown-collapsed");
            this.#query = "";
        }
    }

    #applyCollapsedInput() {
        if (!this.#input || !this.#collapseSelectionOnBlur)
            return;
        this.#applyFilterInputDisplay();
    }

    #clearInputForEdit() {
        if (!this.#input)
            return;
        this.#input.value = "";
        this.#input.title = "";
        this.#input.classList.remove("tdropdown-collapsed");
    }

    #addFromInput() {
        const parsed = this.#parseInputValue(this.#input?.value);
        if (parsed === null)
            return;
        if (this.#existsManual(parsed))
            return;
        if (this.#manualValues.length >= this.#maxItems)
            return;

        this.#manualValues.push(parsed);
        this.#manualValues.sort((a, b) => {
            const na = Number(a);
            const nb = Number(b);
            if (!Number.isNaN(na) && !Number.isNaN(nb))
                return na - nb;
            const la = this.#formatItem ? this.#formatItem(a) : String(a);
            const lb = this.#formatItem ? this.#formatItem(b) : String(b);
            return la.localeCompare(lb, undefined, { numeric: true, sensitivity: "base" });
        });

        if (this.#input) {
            this.#input.value = "";
            this.#filterItems("");
        }
        this.#showList();
        this.#emitChange();
        this.#updateValidity();
        this.#syncPlusVisibility();
    }

    #removeManual(raw) {
        const before = this.#manualValues.length;
        this.#manualValues = this.#manualValues.filter(v => v != raw);
        if (this.#manualValues.length !== before) {
            this.#filterItems(this.#input?.value.trim() ?? "");
            if (this.#filtered.length === 0 && this.#currentPage > 0)
                this.#changePage(-1);
            this.#emitChange();
            this.#updateValidity();
            this.#syncPlusVisibility();
        }
    }

    #emitChange() {
        this.#container.dispatchEvent(new CustomEvent("change", {
            detail: { value: this.getValue(), valid: this.isValid() },
            bubbles: true,
        }));
    }

    #syncPlusVisibility() {
        if (!this.#plus || !this.#isAddableMode())
            return;
        this.#plus.hidden = this.#manualValues.length >= this.#maxItems;
    }

    #refresh() {
        if (this.#isAddableMode())
            void this.#filterItems(this.#input?.value.trim() ?? "");
        else if (!this.#loader)
            this.#filtered = [...this.#catalog];
        this.#updateTriggerLabel();
        if (this.#collapseSelectionOnBlur && this.#input && document.activeElement !== this.#input
            && (this.#isAddableMode() || this.#usesInputFilter()))
            this.#applyFilterInputDisplay();
        this.#updateValidity();
        this.#syncPlusVisibility();
        if (!this.#loader)
            this.#renderItems();
    }

    #tracksValidity() {
        return this.#required || this.#requireExact || this.#validItemCounts != null;
    }

    #updateValidity() {
        const valid = this.isValid();
        this.syncFormValidity();
        const invalid = !valid && this.#tracksValidity();
        if (this.#input)
            this.#input.classList.toggle("invalid", invalid);
        if (this.#trigger)
            this.#trigger.classList.toggle("invalid", invalid);
    }

    #exportItem(item) {
        if (!item)
            return null;
        return this.#valueAs === "id" ? item.id : item;
    }

    #findItemByLabel(text) {
        const needle = text.trim();
        if (!needle)
            return null;
        const pool = [...this.#catalog];
        for (const item of this.#filtered) {
            if (!pool.some(entry => entry.id == item.id && entry.label === item.label))
                pool.push(item);
        }
        const exact = pool.filter(item => item.label === needle);
        if (exact.length === 1)
            return exact[0];
        const lower = needle.toLowerCase();
        const ci = pool.filter(item => item.label.toLowerCase() === lower);
        return ci.length === 1 ? ci[0] : null;
    }

    #finishSingleBlur() {
        const text = this.#sanitize(this.#input?.value);
        const selectedLabel = this.#selected[0]?.label ?? "";

        if (!text) {
            if (this.#selected.length) {
                this.#clearSingle();
                this.#emitChange();
            }
        } else if (text === selectedLabel) {
            // valor já confirmado
        } else {
            const match = this.#findItemByLabel(text);
            if (match) {
                this.#selected = [match];
                this.#input.value = match.label;
                this.#input.title = match.title ?? "";
                this.#emitChange();
            } else if (this.#selected.length) {
                this.#clearSingle();
                this.#emitChange();
            } else {
                this.#clearSingle();
            }
        }

        this.#hideList();
        this.#updateValidity();
    }

    #commitPendingInput(emitChange = true) {
        if (this.#mode !== TDropdown.Modes.SINGLE || !this.#input || this.#readOnly)
            return false;
        if (this.#hasSelectedId()) {
            const label = this.#selected[0].label ?? "";
            if (label === this.#input.value.trim())
                return false;
        }
        const match = this.#findItemByLabel(this.#input.value);
        if (!match)
            return false;
        this.#selected = [match];
        this.#input.value = match.label;
        this.#input.title = match.title ?? "";
        if (emitChange)
            this.#emitChange();
        return true;
    }

    resolveCommittedValue() {
        this.#commitPendingInput(false);
        return this.getValue();
    }

    setCatalog(data) {
        this.#catalog = (data ?? [])
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField))
            .filter(Boolean);
        if (this.#itemsBox)
            this.#refresh();
    }

    #resolveItem(item) {
        if (item === null || item === undefined)
            return null;
        if (typeof item === "object")
            return TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField);
        const hit = this.#catalog.find(c => c.id == item);
        if (hit)
            return hit;
        return TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField);
    }

    setValue(value, emitChange = true) {
        if (this.#mode === TDropdown.Modes.SINGLE) {
            const item = Array.isArray(value) ? value[0] : value;
            if (item === null || item === undefined || item === ""
                || TCheckbox.isNullMarker(item)) {
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
                .map(item => this.#resolveItem(item))
                .filter(Boolean);
            if (this.#selected.length)
                this.#mergeCatalog(this.#selected);
            this.#updateTriggerLabel();
        }
        this.#refresh();
        if (emitChange)
            this.#emitChange();
    }

    getValue() {
        if (this.#mode === TDropdown.Modes.SINGLE)
            return this.#exportItem(this.#selected[0] ?? null);
        if (this.#isAddableMode())
            return this.#manualValues.map(v => {
                if (this.#valueAs === "id") {
                    const item = TDropdown.#normalizeItem(v, this.#idField, this.#labelField, this.#titleField);
                    return item.id;
                }
                return v;
            });
        return this.#selected.map(item => this.#exportItem(item));
    }

    getValues() {
        return this.getValue();
    }

    #hasSelectedId() {
        const id = this.#selected[0]?.id;
        return id !== null && id !== undefined && id !== "";
    }

    isValid() {
        if (this.#mode === TDropdown.Modes.SINGLE) {
            if (!this.#required)
                return true;
            return this.#selected.length === 1 && this.#hasSelectedId();
        }

        const count = this.#isAddableMode() ? this.#manualValues.length : this.#selected.length;

        if (this.#validItemCounts)
            return this.#validItemCounts.includes(count);
        if (this.#exactItems != null && this.#requireExact)
            return count === this.#exactItems;
        if (this.#requireExact && this.#minItems === this.#maxItems)
            return count === this.#minItems;
        return count >= this.#minItems && count <= this.#maxItems;
    }

    syncFormValidity() {
        if (this.#readOnly) {
            this.#input?.setCustomValidity("");
            this.#input?.classList.remove("invalid");
            this.#trigger?.classList.remove("invalid");
            return;
        }
        const invalid = this.#tracksValidity() && !this.isValid();
        if (this.#input)
            this.#input.classList.toggle("invalid", invalid);
        if (this.#trigger)
            this.#trigger.classList.toggle("invalid", invalid);
    }

    dismissValidityBalloon() {
        const target = this.#input ?? this.#trigger;
        target?.setCustomValidity("");
    }

    reportValidity(message = "Informe um valor") {
        const target = this.#input ?? this.#trigger;
        if (!target)
            return true;
        this.syncFormValidity();
        if (this.#tracksValidity() && !this.isValid()) {
            target.setCustomValidity(message);
            return target.reportValidity();
        }
        target.setCustomValidity("");
        return true;
    }

    setFormatInput(handler) {
        this.#formatInput = handler ?? null;
    }

    get element() {
        return this.#container;
    }

    get input() {
        return this.#input ?? this.#trigger;
    }

    get validityInput() {
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
