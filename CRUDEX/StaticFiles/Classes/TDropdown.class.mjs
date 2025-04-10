"use strict";

export default class FilterableDropdown {
    constructor(container, { data = [], itemsPerPage = 5 } = {}) {
        if (!container) throw new Error("Container element is required.");

        /* ------------- estado ------------- */
        this.container = container;
        this.data = [...data];
        this.filteredData = [...data];
        this.itemsPerPage = itemsPerPage;
        this.currentPage = 0;
        this._closeByBlur = true;

        /* ------------- DOM ------------- */
        this._buildDom();
        this._bindEvents();
        this._renderItems();
    }

    /* ================================================================
       CONSTRUÇÃO DA INTERFACE (sem templates)
    ==================================================================*/
    _buildDom() {
        /* wrapper */
        this.container.classList.add("filterable-dropdown-wrapper");
        Object.assign(this.container.style, { display: "inline-block", position: "relative", fontFamily: "inherit" });

        /* folha de estilo isolada (opcional) */
        const style = document.createElement("style");
        style.textContent = `
      .fd-input{width:100%;height:2.8dvmin;padding:.5dvmin;border:.1dvmin solid #000;border-radius:.1dvmin;box-sizing:border-box}
      .fd-icon{position:absolute;top:50%;right:.5dvmin;transform:translateY(-50%);cursor:pointer;font-size:2dvmin;color:#888;user-select:none}
      .fd-list{position:absolute;top:calc(100% + .8dvmin);left:0;right:0;max-height:100dvmin;overflow-y:auto;background:#fff;display:none;box-shadow:0 .8dvmin 1.6dvmin rgba(0,0,0,.2);z-index:100}
      .fd-list.open{display:block}
      .fd-item{padding:.5dvmin;cursor:pointer}
      .fd-item:hover{background:#f0f0f0}
      .fd-item.selected{background:#007bff;color:#fff}
      .fd-pagination{display:flex;justify-content:space-between;padding:.5dvmin;background:#f9f9f9}
      .fd-pagination button{border:none;background:none;cursor:pointer;font-size:2dvmin;color:#007bff}
      .fd-pagination button[disabled]{color:#ccc;cursor:not-allowed;pointer-events:none}
    `;
        this.container.append(style);

        /* input + ícone */
        const inputContainer = document.createElement("div");
        inputContainer.style.position = "relative";
        this.container.append(inputContainer);

        this.input = document.createElement("input");
        this.input.type = "text";
        this.input.placeholder = "Type to filter...";
        this.input.className = "fd-input";
        inputContainer.append(this.input);

        this.icon = document.createElement("span");
        this.icon.className = "fd-icon";
        this.icon.textContent = "▼";
        inputContainer.append(this.icon);

        /* lista suspensa */
        this.list = document.createElement("div");
        this.list.className = "fd-list";
        inputContainer.append(this.list);

        this.itemsBox = document.createElement("div");
        this.list.append(this.itemsBox);

        /* paginação */
        const pagination = document.createElement("div");
        pagination.className = "fd-pagination";
        this.list.append(pagination);

        this.prevBtn = document.createElement("button");
        this.prevBtn.textContent = "◄";
        this.prevBtn.disabled = true;
        pagination.append(this.prevBtn);

        this.nextBtn = document.createElement("button");
        this.nextBtn.textContent = "►";
        pagination.append(this.nextBtn);
    }

    /* ================================================================
       EVENTOS
    ==================================================================*/
    _bindEvents() {
        /* clique no ícone */
        this.icon.addEventListener("mousedown", e => {
            e.preventDefault();
            this.input.focus();
            this._toggleList();
        });

        /* digitação */
        this.input.addEventListener("input", e => {
            this._filterItems(e.target.value.trim());
            this._showList();
        });

        /* foco / clique no input */
        this.input.addEventListener("focus", () => {
            if (this.input.value.trim()) {
                this._filterItems(this.input.value.trim());
                this._showList();
                this._closeByBlur = false;
            }
        });

        this.input.addEventListener("click", e => {
            e.stopPropagation();
            if (this._closeByBlur) {
                this.list.classList.contains("open") ? this._hideList() : this._showList();
            }
            this._closeByBlur = true;
        });

        this.input.addEventListener("blur", () => {
            if (this._closeByBlur) this._hideList();
            this._closeByBlur = true;
        });

        /* paginação */
        this.prevBtn.addEventListener("click", () => this._changePage(-1));
        this.nextBtn.addEventListener("click", () => this._changePage(1));

        /* clique fora */
        document.addEventListener("mousedown", this._handleOutside = e => {
            if (!this.container.contains(e.target)) this._hideList();
        });

        /* coordenar com outros dropdowns */
        window.addEventListener("dropdownOpened", this._handleGlobal = e => {
            if (e.detail.dropdown !== this) this._hideList();
        });

        /* impedir blur dentro da lista */
        this.list.addEventListener("mousedown", e => e.preventDefault());
    }

    /* ================================================================
       LÓGICA
    ==================================================================*/
    _filterItems(query) {
        this.filteredData = this.data.filter(i => i.toLowerCase().includes(query.toLowerCase()));
        this.currentPage = 0;
        this._renderItems();
    }

    _changePage(delta) {
        const pages = Math.ceil(this.filteredData.length / this.itemsPerPage);
        this.currentPage = Math.min(Math.max(this.currentPage + delta, 0), pages - 1);
        this._renderItems();
    }

    _renderItems() {
        const start = this.currentPage * this.itemsPerPage;
        const end = start + this.itemsPerPage;

        this.itemsBox.replaceChildren();            // limpa
        this.filteredData.slice(start, end).forEach(item => {
            const div = document.createElement("div");
            div.className = "fd-item";
            div.textContent = item;
            if (item === this.input.value) div.classList.add("selected");
            div.addEventListener("click", () => this._selectItem(item));
            this.itemsBox.append(div);
        });

        this._updatePagination();
        if (this.filteredData.length === 0) this._hideList();
    }

    _updatePagination() {
        const pages = Math.ceil(this.filteredData.length / this.itemsPerPage);
        this.prevBtn.disabled = this.currentPage === 0;
        this.nextBtn.disabled = this.currentPage >= pages - 1;
        this.prevBtn.parentElement.style.display = pages > 1 ? "flex" : "none";
    }

    /* ---------- visibilidade ---------- */
    _showList() {
        window.dispatchEvent(new CustomEvent("dropdownOpened", { detail: { dropdown: this }, bubbles: true }));

        this.list.style.visibility = "hidden";
        this.list.style.display = "block";

        const rect = this.input.getBoundingClientRect();
        const h = this.list.scrollHeight;
        const below = window.innerHeight - rect.bottom;
        const above = rect.top;

        if (below < h && above > h) {
            this.list.style.top = "auto";
            this.list.style.bottom = `${rect.height}px`;
        } else {
            this.list.style.top = `calc(100% + .8dvmin)`;
            this.list.style.bottom = "auto";
        }

        this.list.style.visibility = "visible";
        this.list.classList.add("open");
    }

    _hideList() {
        this.list.classList.remove("open");
        this.list.style.display = "none";
        this.list.style.top = "";
        this.list.style.bottom = "";
    }

    _toggleList() {
        this.list.classList.contains("open") ? this._hideList() : this._showList();
    }

    _selectItem(item) {
        this.itemsBox.querySelectorAll(".fd-item").forEach(el =>
            el.classList.toggle("selected", el.textContent === item)
        );
        this.input.value = item;
        this._hideList();
    }

    /* ================================================================
       API PÚBLICA
    ==================================================================*/
    setData(array) {
        this.data = [...array];
        this._filterItems(this.input.value.trim());
    }

    destroy() {
        document.removeEventListener("mousedown", this._handleOutside);
        window.removeEventListener("dropdownOpened", this._handleGlobal);
        this.container.replaceChildren();           // remove tudo
    }
}
