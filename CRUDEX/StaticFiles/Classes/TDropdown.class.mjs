"use strict";

import TCheckbox from "./TCheckbox.class.mjs";

export default class TDropdown {
    static Modes = {
        SINGLE: "single",
        MULTI: "multi",
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
    #unique = true;
    #valueAs = "item";
    #required = false;
    #allowEmpty = false;
    #readOnly = false;

    #inputWrap = null;
    #input = null;
    #trigger = null;
    #icon = null;
    #list = null;
    #itemsBox = null;
    #prevBtn = null;
    #nextBtn = null;
    #listSearchInput = null;
    #selectionTip = null;
    #listSearch = false;
    #handleOutside = null;
    #handleGlobal = null;
    #loader = null;
    #recordSet = null;
    #records = new Map();
    #query = "";
    #serverPage = 1;
    #serverPageCount = 1;
    #serverRowCount = 0;
    #unselectedCache = [];
    #unselectedCacheThroughPage = 0;
    #renderPass = false;
    #paginate = true;
    #listFocusIndex = -1;
    #itemSourcePages = new Map();
    #pendingFocusKey = null;

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
        this.#titleField = options.titleField ?? null;
        this.#placeholder = options.placeholder ?? "";
        if (options.containerClass)
            this.#container.classList.add(options.containerClass);
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
        this.#paginate = options.paginate !== false;
        this.#listSearch = options.listSearch === true || (this.#mode === TDropdown.Modes.MULTI && this.#loader != null);

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

        if (options.nullCondition) {
            this.#clearSingle();
            if (this.#input)
                this.#input.placeholder = "nulo";
        } else if (options.value !== undefined && options.value !== null && options.value !== ""
            && !TCheckbox.isNullMarker(options.value)) {
            this.setValue(options.value, false);
        } else
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

    #buildDom() {
        this.#inputWrap = document.createElement("div");
        this.#inputWrap.className = "tdropdown-input-wrap";
        this.#container.append(this.#inputWrap);

        if (this.#mode === TDropdown.Modes.MULTI) {
            this.#input = document.createElement("input");
            this.#input.type = "text";
            this.#input.className = "tdropdown-input tdropdown-multi-input";
            this.#input.readOnly = true;
            this.#input.placeholder = this.#placeholder || "Selecionar...";
            this.#input.autocomplete = "off";
            this.#inputWrap.append(this.#input);

            this.#selectionTip = document.createElement("div");
            this.#selectionTip.className = "tdropdown-selection-tip";
            this.#selectionTip.hidden = true;
            this.#inputWrap.append(this.#selectionTip);
        } else {
            this.#input = document.createElement("input");
            this.#input.type = "text";
            this.#input.className = "tdropdown-input";
            this.#input.placeholder = this.#placeholder;
            this.#input.autocomplete = "off";
            this.#inputWrap.append(this.#input);
        }

        this.#icon = document.createElement("span");
        this.#icon.className = "tdropdown-icon";
        this.#icon.textContent = "▼";
        this.#inputWrap.append(this.#icon);

        this.#list = document.createElement("div");
        this.#list.className = "tdropdown-list";
        this.#inputWrap.append(this.#list);

        if (this.#mode === TDropdown.Modes.MULTI && this.#listSearch) {
            const searchWrap = document.createElement("div");
            searchWrap.className = "tdropdown-list-search";
            this.#listSearchInput = document.createElement("input");
            this.#listSearchInput.type = "text";
            this.#listSearchInput.className = "tdropdown-list-search-input";
            this.#listSearchInput.placeholder = "Filtrar...";
            this.#listSearchInput.autocomplete = "off";
            this.#listSearchInput.readOnly = false;
            searchWrap.append(this.#listSearchInput);
            this.#list.append(searchWrap);
        }

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
    }

    #applyRequiredConstraints() {
        if (!this.#input || this.#readOnly)
            return;
        this.#input.removeAttribute("required");
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
        if (this.#listSearchInput)
            this.#listSearchInput.readOnly = false;
        this.#hideList();
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
            if (this.#mode === TDropdown.Modes.MULTI) {
                this.#input.addEventListener("click", (e) => {
                    e.stopPropagation();
                    this.dismissValidityBalloon();
                    void this.#toggleList();
                });
                this.#input.addEventListener("keydown", (e) => this.#onMultiInputKeyDown(e));
                this.#input.addEventListener("beforeinput", (e) => e.preventDefault());
                this.#input.addEventListener("paste", (e) => e.preventDefault());
                this.#input.addEventListener("blur", () => {
                    requestAnimationFrame(() => {
                        if (!this.#container.contains(document.activeElement))
                            this.#hideList();
                    });
                });
                this.#inputWrap.addEventListener("mouseenter", () => this.#showSelectionTip());
                this.#inputWrap.addEventListener("mouseleave", () => this.#hideSelectionTip());
            } else {
                this.#input.addEventListener("input", (e) => {
                    this.dismissValidityBalloon();
                    void this.#filterItems(e.target.value.trim());
                    this.#showList();
                });
                this.#input.addEventListener("click", (e) => {
                    e.stopPropagation();
                    void this.#toggleList();
                });
                this.#input.addEventListener("blur", () => {
                    this.#commitPendingInput(false);
                    this.#revertInput();
                    this.#hideList();
                    this.#updateValidity();
                });
            }
        }

        if (this.#trigger) {
            this.#trigger.addEventListener("click", (e) => {
                e.stopPropagation();
                this.dismissValidityBalloon();
                void this.#toggleList();
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

        this.#list.addEventListener("mousedown", (e) => {
            if (e.target.closest("input, textarea, button, select"))
                return;
            e.preventDefault();
        });

        if (this.#listSearchInput && !this.#readOnly) {
            this.#listSearchInput.addEventListener("input", (e) => {
                void this.#filterItems(e.target.value.trim());
            });
            this.#listSearchInput.addEventListener("keydown", (e) => this.#onListSearchKeyDown(e));
        }
    }

    async #filterItems(query) {
        this.#query = query;
        if (this.#loader) {
            await this.#loadServerPage(1);
            return;
        }
        const needle = query.toLowerCase();
        this.#filtered = needle
            ? this.#catalog.filter(item => item.label.toLowerCase().includes(needle))
            : [...this.#catalog];
        this.#currentPage = 0;
        this.#renderItems();
    }

    async #changePage(delta) {
        if (this.#loader && this.#mode === TDropdown.Modes.MULTI) {
            const pages = this.#multiDisplayPageCount();
            if (delta > 0 && this.#currentPage >= pages - 1)
                return;
            if (delta < 0 && this.#currentPage <= 0)
                return;
            this.#currentPage = Math.min(Math.max(this.#currentPage + delta, 0), pages - 1);
            this.#listFocusIndex = 0;
            await this.#prepareMultiDisplayPage();
            this.#renderItems();
            return;
        }
        if (this.#loader) {
            const next = this.#serverPage + delta;
            if (next < 1 || next > this.#serverPageCount)
                return;
            await this.#loadServerPage(next);
            return;
        }
        const pages = Math.max(1, Math.ceil(this.#filtered.length / this.#itemsPerPage));
        this.#currentPage = Math.min(Math.max(this.#currentPage + delta, 0), pages - 1);
        this.#listFocusIndex = 0;
        this.#renderItems();
    }

    #mergeCatalog(items) {
        for (const item of items) {
            if (!this.#catalog.some(c => c.id == item.id))
                this.#catalog.push(item);
        }
    }

    #resetUnselectedCache() {
        this.#unselectedCache = [];
        this.#unselectedCacheThroughPage = 0;
    }

    #ingestServerResult(page, result, items) {
        this.#serverPage = result.pageNumber ?? page;
        this.#serverPageCount = Math.max(1, result.pageCount ?? 1);
        this.#serverRowCount = Number(result.rowCount ?? this.#serverRowCount ?? 0);
        this.#filtered = items;
        this.#mergeCatalog(items);
        this.#mergeRecordSet(result);
        if (this.#selected.length)
            this.#mergeCatalog(this.#selected);

        if (this.#mode !== TDropdown.Modes.MULTI)
            return;

        const pinnedKeys = new Set(this.#pinnedSelectedItems().map(item => this.#itemKey(item)));
        const unselected = items.filter(item => !pinnedKeys.has(this.#itemKey(item)));
        if (page > this.#unselectedCacheThroughPage) {
            if (this.#unselectedCacheThroughPage === 0)
                this.#unselectedCache = unselected;
            else
                this.#appendUnselectedToCache(unselected);
            this.#unselectedCacheThroughPage = page;
        }
    }

    #appendUnselectedToCache(items) {
        const seen = new Set(this.#unselectedCache.map(item => this.#itemKey(item)));
        for (const item of items) {
            const key = this.#itemKey(item);
            if (seen.has(key))
                continue;
            this.#unselectedCache.push(item);
            seen.add(key);
        }
    }

    #allServerPagesCached() {
        return this.#unselectedCacheThroughPage >= this.#serverPageCount;
    }

    #canLoadMoreUnselected() {
        return !this.#allServerPagesCached();
    }

    async #ensureUnselectedCacheThrough(neededEnd) {
        while (this.#unselectedStream().length < neededEnd && this.#canLoadMoreUnselected()) {
            const before = this.#unselectedCacheThroughPage;
            const page = before + 1;
            const result = await this.#loader(this.#query, page);
            const items = (result.items ?? [])
                .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField))
                .filter(Boolean);
            this.#ingestServerResult(page, result, items);
            if (this.#unselectedCacheThroughPage === before)
                break;
        }
    }

    async #prepareMultiDisplayPage() {
        if (this.#mode !== TDropdown.Modes.MULTI || !this.#loader)
            return;
        const neededEnd = this.#unselectedNeededForDisplay();
        if (neededEnd > 0)
            await this.#ensureUnselectedCacheThrough(neededEnd);
    }

    #unselectedNeededForDisplay() {
        const pageSize = this.#itemsPerPage;
        const start = this.#currentPage * pageSize;
        const pinnedLen = this.#pinnedSelectedItems().length;
        const sliceStart = this.#paddedVirtualSliceStart(start, pageSize);
        const unselectedOffset = Math.max(0, sliceStart - pinnedLen);
        return unselectedOffset + pageSize;
    }

    #paddedVirtualSliceStart(start, length) {
        if (!this.#loader || this.#currentPage < this.#multiDisplayPageCount() - 1)
            return start;
        const count = this.#multiVirtualSlice(start, length).length;
        if (count >= length || count === 0)
            return start;
        return Math.max(0, start - (length - count));
    }

    async #loadServerPage(page, { resetDisplayPage = true } = {}) {
        const result = await this.#loader(this.#query, page);
        const items = (result.items ?? [])
            .map(item => TDropdown.#normalizeItem(item, this.#idField, this.#labelField, this.#titleField))
            .filter(Boolean);
        if (resetDisplayPage) {
            this.#currentPage = 0;
            this.#resetUnselectedCache();
        }
        this.#ingestServerResult(page, result, items);
        if (this.#mode !== TDropdown.Modes.MULTI)
            this.#currentPage = 0;
        this.#renderItems();
        if (this.#pendingFocusKey) {
            const focusKey = this.#pendingFocusKey;
            this.#pendingFocusKey = null;
            this.#focusItemByKey(focusKey);
        }
    }

    #mergeRecordSet(result) {
        if (!result?.recordSet)
            return;
        this.#recordSet = result.recordSet;
        for (const record of result.records ?? result.recordSet.records ?? [])
            this.#records.set(record.Id, record);
    }

    #itemKey(item) {
        return `${item.id}\0${item.label}`;
    }

    #pinnedSelectedItems() {
        return [...this.#selected];
    }

    #focusItemByKey(key) {
        const index = this.#pageItems().findIndex(item => this.#itemKey(item) === key);
        this.#listFocusIndex = index >= 0 ? index : 0;
        this.#syncListFocus();
    }

    #targetPageForDeselectedItem(item, storedPage) {
        if (storedPage != null)
            return storedPage;
        if (this.#loader)
            return this.#serverNaturalPageForItem(item);
        return this.#clientNaturalPageForItem(item);
    }

    #clientNaturalPageForItem(item) {
        const key = this.#itemKey(item);
        const pool = this.#filtered.filter(i => !this.#isSelected(i) || this.#itemKey(i) === key);
        const index = pool.findIndex(i => this.#itemKey(i) === key);
        if (index < 0)
            return this.#currentPage;
        return Math.floor(index / this.#itemsPerPage);
    }

    #serverNaturalPageForItem(item) {
        const key = this.#itemKey(item);
        const needle = this.#query.trim().toLowerCase();
        let pool = this.#catalog.filter(i => !needle || i.label.toLowerCase().includes(needle));
        pool = pool.filter(i => !this.#isSelected(i) || this.#itemKey(i) === key);
        pool.sort((a, b) => a.label.localeCompare(b.label, undefined, { sensitivity: "base" }));
        const index = pool.findIndex(i => this.#itemKey(i) === key);
        if (index < 0)
            return 1;
        return Math.floor(index / this.#itemsPerPage) + 1;
    }

    #multiVirtualList() {
        const pinned = this.#pinnedSelectedItems();
        const pinnedKeys = new Set(pinned.map(item => this.#itemKey(item)));
        const rest = this.#filtered.filter(item => !pinnedKeys.has(this.#itemKey(item)));
        return [...pinned, ...rest];
    }

    #multiVirtualLength() {
        const pinnedLen = this.#pinnedSelectedItems().length;
        if (!this.#loader)
            return this.#multiVirtualList().length;
        const unselectedLen = this.#unselectedStream().length;
        if (this.#allServerPagesCached())
            return pinnedLen + unselectedLen;
        return Math.max(pinnedLen + unselectedLen, this.#serverRowCount);
    }

    #multiDisplayPageCount() {
        return Math.ceil(this.#multiVirtualLength() / this.#itemsPerPage) || 1;
    }

    #unselectedStream() {
        const pinnedKeys = new Set(this.#pinnedSelectedItems().map(item => this.#itemKey(item)));
        if (this.#loader)
            return this.#unselectedCache.filter(item => !pinnedKeys.has(this.#itemKey(item)));
        const pinned = this.#pinnedSelectedItems();
        return this.#filtered.filter(item => !pinnedKeys.has(this.#itemKey(item)));
    }

    #multiVirtualSlice(start, length) {
        const end = start + length;
        const pinned = this.#pinnedSelectedItems();
        const selectedPart = start < pinned.length
            ? pinned.slice(start, Math.min(end, pinned.length))
            : [];
        const need = length - selectedPart.length;
        if (need <= 0)
            return selectedPart;
        const unselectedOffset = Math.max(0, start - pinned.length);
        const unselectedPart = this.#unselectedStream()
            .slice(unselectedOffset, unselectedOffset + need);
        return [...selectedPart, ...unselectedPart];
    }

    #displayPageForDeselectedItem(item) {
        const key = this.#itemKey(item);
        const pinnedLen = this.#selected.length;
        const unselectedOffset = this.#unselectedOffsetForItem(item);
        if (unselectedOffset < 0)
            return this.#currentPage;
        const virtualIndex = pinnedLen + unselectedOffset;
        return Math.floor(virtualIndex / this.#itemsPerPage);
    }

    #unselectedOffsetForItem(item) {
        const key = this.#itemKey(item);
        const needle = this.#query.trim().toLowerCase();
        let pool = this.#catalog.filter(i => !needle || i.label.toLowerCase().includes(needle));
        pool = pool.filter(i => !this.#isSelected(i) || this.#itemKey(i) === key);
        pool.sort((a, b) => a.label.localeCompare(b.label, undefined, { sensitivity: "base" }));
        return pool.findIndex(i => this.#itemKey(i) === key);
    }

    #displayOrderedItems() {
        if (this.#mode !== TDropdown.Modes.MULTI)
            return this.#filtered;
        if (this.#loader)
            return this.#multiVirtualSlice(0, this.#multiVirtualLength());
        return this.#multiVirtualList();
    }

    #pageItems() {
        if (this.#mode !== TDropdown.Modes.MULTI) {
            if (this.#loader || !this.#paginate)
                return this.#filtered;
            const start = this.#currentPage * this.#itemsPerPage;
            return this.#filtered.slice(start, start + this.#itemsPerPage);
        }
        if (!this.#paginate)
            return this.#multiVirtualSlice(0, Number.MAX_SAFE_INTEGER);
        const start = this.#currentPage * this.#itemsPerPage;
        const sliceStart = this.#paddedVirtualSliceStart(start, this.#itemsPerPage);
        return this.#multiVirtualSlice(sliceStart, this.#itemsPerPage);
    }

    #resetListFocus() {
        this.#listFocusIndex = -1;
    }

    #syncListFocus() {
        const rows = [...this.#itemsBox.querySelectorAll(".tdropdown-item")];
        rows.forEach((row, index) => {
            row.classList.toggle("tdropdown-item-focused", index === this.#listFocusIndex);
            if (index === this.#listFocusIndex)
                row.scrollIntoView({ block: "nearest" });
        });
    }

    #moveListFocus(delta) {
        const rows = this.#itemsBox.querySelectorAll(".tdropdown-item");
        if (!rows.length)
            return;
        if (this.#listFocusIndex < 0)
            this.#listFocusIndex = 0;
        else
            this.#listFocusIndex = Math.min(Math.max(this.#listFocusIndex + delta, 0), rows.length - 1);
        this.#syncListFocus();
    }

    #activateFocusedItem() {
        const pageItems = this.#pageItems();
        const item = pageItems[this.#listFocusIndex];
        if (!item)
            return;
        if (this.#mode === TDropdown.Modes.MULTI)
            this.#toggleSelected(item);
    }

    #onMultiInputKeyDown(e) {
        if (this.#readOnly)
            return;

        if (this.#list.classList.contains("open")) {
            if (e.key === "Escape") {
                e.preventDefault();
                this.#hideList();
                return;
            }
            if (e.key === "ArrowDown") {
                e.preventDefault();
                this.#moveListFocus(1);
                return;
            }
            if (e.key === "ArrowUp") {
                e.preventDefault();
                this.#moveListFocus(-1);
                return;
            }
            if (e.key === " " || e.key === "Enter") {
                e.preventDefault();
                this.#activateFocusedItem();
            }
            return;
        }

        if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            void this.#openList();
            return;
        }

        if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey)
            e.preventDefault();
    }

    #onListSearchKeyDown(e) {
        e.stopPropagation();
        if (this.#mode !== TDropdown.Modes.MULTI)
            return;

        if (e.key === "Escape") {
            e.preventDefault();
            this.#hideList();
            this.#input?.focus();
            return;
        }
        if (e.key === "ArrowDown") {
            e.preventDefault();
            this.#moveListFocus(1);
            return;
        }
        if (e.key === "ArrowUp") {
            e.preventDefault();
            this.#moveListFocus(-1);
            return;
        }
        if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            this.#activateFocusedItem();
        }
    }

    #renderItems() {
        if (this.#mode === TDropdown.Modes.MULTI && this.#loader && !this.#renderPass) {
            const neededEnd = this.#unselectedNeededForDisplay();
            if (neededEnd > this.#unselectedStream().length && this.#canLoadMoreUnselected()) {
                this.#renderPass = true;
                void this.#ensureUnselectedCacheThrough(neededEnd).then(() => {
                    this.#renderPass = false;
                    this.#renderItems();
                });
                return;
            }
        }

        const pageItems = this.#pageItems();

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

            if (this.#mode === TDropdown.Modes.SINGLE) {
                row.addEventListener("click", () => this.#selectSingle(item));
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
        const emptyResults = this.#multiVirtualLength() === 0
            && this.#pinnedSelectedItems().length === 0;
        const keepOpenWhileFiltering = this.#list.classList.contains("open")
            && this.#query.trim() !== "";
        if (emptyResults && !keepOpenWhileFiltering)
            this.#hideList();
        else if (this.#mode === TDropdown.Modes.MULTI && this.#list.classList.contains("open")) {
            const count = this.#itemsBox.querySelectorAll(".tdropdown-item").length;
            if (count === 0)
                this.#listFocusIndex = -1;
            else if (this.#listFocusIndex < 0 || this.#listFocusIndex >= count)
                this.#listFocusIndex = 0;
            this.#syncListFocus();
        }
    }

    #updatePagination() {
        if (!this.#paginate) {
            this.#prevBtn.parentElement.style.display = "none";
            return;
        }
        if (this.#loader && this.#mode === TDropdown.Modes.MULTI) {
            const pages = this.#multiDisplayPageCount();
            this.#prevBtn.disabled = this.#currentPage === 0;
            this.#nextBtn.disabled = this.#currentPage >= pages - 1;
            this.#prevBtn.parentElement.style.display = pages > 1 ? "flex" : "none";
            return;
        }
        if (this.#loader) {
            this.#prevBtn.disabled = this.#serverPage <= 1;
            this.#nextBtn.disabled = this.#serverPage >= this.#serverPageCount;
            this.#prevBtn.parentElement.style.display = this.#serverPageCount > 1 ? "flex" : "none";
            return;
        }
        const pages = this.#multiDisplayPageCount();
        this.#prevBtn.disabled = this.#currentPage === 0;
        this.#nextBtn.disabled = this.#currentPage >= pages - 1;
        this.#prevBtn.parentElement.style.display = pages > 1 ? "flex" : "none";
    }

    #showList() {
        if (this.#readOnly)
            return;
        this.#hideSelectionTip();
        if (this.#mode === TDropdown.Modes.MULTI && this.#listFocusIndex < 0)
            this.#listFocusIndex = 0;
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

        this.#list.style.visibility = "visible";
        this.#list.classList.add("open");
        if (this.#listSearchInput) {
            this.#listSearchInput.readOnly = false;
            this.#listSearchInput.focus();
        } else if (this.#mode === TDropdown.Modes.MULTI) {
            this.#syncListFocus();
            this.#input?.focus();
        }
    }

    #hideList() {
        this.#list.classList.remove("open");
        this.#list.style.display = "none";
        this.#list.style.top = "";
        this.#list.style.bottom = "";
        this.#resetListFocus();
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
        if (this.#listSearchInput)
            this.#listSearchInput.value = "";
        if (this.#loader)
            await this.#loadServerPage(1);
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
        const key = this.#itemKey(item);
        if (this.#isSelected(item)) {
            const storedPage = this.#itemSourcePages.get(key);
            this.#selected = this.#selected.filter(s => !(s.id === item.id && s.label === item.label));
            this.#itemSourcePages.delete(key);
            this.#updateTriggerLabel();
            const targetPage = this.#targetPageForDeselectedItem(item, storedPage);
            this.#pendingFocusKey = key;
            if (this.#loader && this.#mode === TDropdown.Modes.MULTI) {
                this.#currentPage = storedPage ?? this.#displayPageForDeselectedItem(item);
                this.#pendingFocusKey = null;
                this.#resetUnselectedCache();
                void this.#prepareMultiDisplayPage().then(() => {
                    this.#renderItems();
                    this.#focusItemByKey(key);
                });
            } else if (this.#loader)
                void this.#loadServerPage(targetPage, { resetDisplayPage: false });
            else {
                this.#currentPage = targetPage;
                this.#renderItems();
                this.#pendingFocusKey = null;
                this.#focusItemByKey(key);
            }
        } else {
            if (this.#selected.length >= this.#maxItems)
                return;
            const sourcePage = this.#currentPage;
            this.#selected.push(item);
            this.#itemSourcePages.set(key, sourcePage);
            this.#updateTriggerLabel();
            if (this.#loader && this.#mode === TDropdown.Modes.MULTI) {
                this.#resetUnselectedCache();
                void this.#prepareMultiDisplayPage().then(() => this.#renderItems());
            } else
                this.#renderItems();
        }
        this.#emitChange();
        this.#updateValidity();
    }

    #showSelectionTip() {
        if (!this.#selectionTip || !this.#selected.length || this.#list.classList.contains("open"))
            return;
        this.#selectionTip.textContent = this.#selected.map(item => item.label).join("\n");
        this.#selectionTip.hidden = false;
    }

    #hideSelectionTip() {
        if (this.#selectionTip)
            this.#selectionTip.hidden = true;
    }

    #updateTriggerLabel() {
        if (this.#mode !== TDropdown.Modes.MULTI || !this.#input)
            return;
        const labels = this.#selected.map(s => s.label);
        this.#input.value = labels.length ? labels.join(", ") : "";
        this.#input.title = labels.length ? labels.join(", ") : "";
        if (this.#selectionTip) {
            this.#selectionTip.textContent = labels.join("\n");
            this.#selectionTip.hidden = true;
        }
    }

    #emitChange() {
        this.#container.dispatchEvent(new CustomEvent("change", {
            detail: { value: this.getValue(), valid: this.isValid() },
            bubbles: true,
        }));
    }

    #refresh() {
        if (!this.#loader)
            this.#filtered = [...this.#catalog];
        this.#updateTriggerLabel();
        this.#updateValidity();
        if (!this.#loader)
            this.#renderItems();
    }

    #updateValidity() {
        const valid = this.isValid();
        this.syncFormValidity();
        const invalid = !valid && (this.#required || this.#requireExact);
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
        } else {
            const list = Array.isArray(value) ? value : (value ? [value] : []);
            this.#selected = list
                .map(item => this.#resolveItem(item))
                .filter(Boolean);
            this.#itemSourcePages.clear();
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

        const count = this.#selected.length;

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
        const invalid = (this.#required || this.#requireExact) && !this.isValid();
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
        if ((this.#required || this.#requireExact) && !this.isValid()) {
            target.setCustomValidity(message);
            return target.reportValidity();
        }
        target.setCustomValidity("");
        return true;
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
