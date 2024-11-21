"use strict";

import TSystem from "./TSystem.class.mjs";

export default class TDropdown extends HTMLElement {
    static #Style = "";

    #Table = "";
    #HTML = {
        InputContainer: null,
        FilterInput: null,
        DropdownIcon: null,
        DropdownList: null,
        DropdownItems: null,
        Pagination: null,
        PrevButton: null,
        NextButton: null,
    };
    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        this.#Style = styles.DropDown;
    }
    constructor() {
        let tableAliasOrName = this.getAttribute("tableAliasOrName");

        if (!tableAliasOrName)
            throw new Error("Atributo tableAliasOrName não encontrado");
        this.#Table = TSystem.GetTable(tableAliasOrName);
        if (!this.#Table)
            throw new Error("Tabela de banco-de-dados não encontrada");
        this.#HTML.InputContainer = document.createDocumentFragment();
        this.#HTML.InputContainer.className = "input-container";

        let style = document.createElement("style");

        style.innerText = TDropdown.#Style;
        this.#HTML.InputContainer.appendChild(style);

        this.#HTML.FilterInput = document.createElement("input");
        this.#HTML.FilterInput.type = "text";
        this.#HTML.FilterInput.placeholder = "Type to filter...";
        this.#HTML.FilterInput.className = "filter-input";
        this.#HTML.InputContainer.appendChild(this.#HTML.Input);

        this.#HTML.DropdownIcon = document.createElement("span");
        this.#HTML.DropdownIcon.innerText = String.fromCharCode(9660);
        this.#HTML.DropdownIcon.className = "dropdown-icon";
        this.#HTML.InputContainer.appendChild(this.#HTML.DropdownIcon);

        this.#HTML.DropdownList = document.createElement("div");
        this.#HTML.DropdownList.className = "dropdown-list";
        this.#HTML.InputContainer.appendChild(this.#HTML.DropdownList);

        this.#HTML.DropdownItems = document.createElement("div");
        this.#HTML.DropdownItems.className = "dropdown-items"
        this.#HTML.DropdownList.appendChild(this.#HTML.DropdownItems);

        this.#HTML.Pagination = document.createElement("div");
        this.#HTML.Pagination.className = "pagination"
        this.#HTML.DropdownList.appendChild(this.#HTML.Pagination);

        this.#HTML.PrevButton = document.createElement("button");
        this.#HTML.PrevButton.className = "prev-button"
        this.#HTML.PrevButton.disabled = true
        this.#HTML.PrevButton.innerText = String.fromCharCode(9664);
        this.#HTML.PrevButton.tabIndex = -1;
        this.#HTML.Pagination.appendChild(this.#HTML.PrevButton);

        this.#HTML.NextButton = document.createElement("button");
        this.#HTML.NextButton.className = "prev-button"
        this.#HTML.NextButton.innerText = String.fromCharCode(9654);
        this.#HTML.NextButton.tabIndex = -1;
        this.#HTML.Pagination.appendChild(this.#HTML.NextButton);

        this.#HandleDropdownOpened = (event) => {
            if (event.detail.dropdown !== this) {
                this.#HideDropdown();
            }
        }

        this.#HandleClickOutside = (event) => {
            if (!this.contains(event.target)) {
                this.#HideDropdown();
            }
        }

        this.#HandleFocusChange = (event) => {
            if (!this.contains(event.target)) {
                this.#HideDropdown();
            }
        }

        super();
        this.attachShadow({ mode: "open" });
        this.#IsCloseDropdown = true;

        this.#CurrentPage = 0;
        this.#ItemsPerPage = 5;
        this.#Data = [];
        this.#FilteredData = [];

        this.shadowRoot.appendChild(this.#HTML.InputContainer)
    }
    connectedCallback() {
        window.addEventListener("dropdownOpened", (event) => this.#HandleDropdownOpened(event));
        document.addEventListener("mousedown", this.#HandleClickOutside.bind(this));

        this.#HTML.FilterInput.addEventListener("focus", () => {
            if (this.#HTML.FilterInput.value.trim()) {
                this.filterItems(this.#HTML.FilterInput.value.trim());
                this.#ShowDropdown();
                this.#IsCloseDropdown = false;
            }
        });

        this.#HTML.FilterInput.addEventListener("click", (e) => {
            e.stopPropagation();
            if (this.#IsCloseDropdown) {
                if (this.#HTML.DropdownList.classList.contains("open")) {
                    this.#HideDropdown(); // Oculta se já estiver aberta
                } else {
                    this.filterItems(this.#HTML.FilterInput.value.trim());
                    this.#ShowDropdown(); // Exibe se estiver oculta
                }
            }
            this.#IsCloseDropdown = true;
        });

        this.#HTML.FilterInput.addEventListener("blur", () => {
            if (this.#IsCloseDropdown)
                this.#HideDropdown();
            else
                this.#IsCloseDropdown = true;
        });

        this.#HTML.DropdownIcon.addEventListener("mousedown", (e) => {
            e.preventDefault();
            this.#HTML.FilterInput.focus();
            this.#HTML.FilterInput.click();
        });

        this.#HTML.FilterInput.addEventListener("input", (e) => {
            this.filterItems(e.target.value.trim());
            this.#ShowDropdown();
        });

        this.#HTML.PrevButton.addEventListener("click", () => this.#ChangePage(-1));
        this.#HTML.NextButton.addEventListener("click", () => this.#ChangePage(1));
        this.#HTML.DropdownList.addEventListener("mousedown", (e) =>
            e.preventDefault()
        );
    }

    disconnectedCallback() {
        document.removeEventListener("mousedown", this.#HandleClickOutside);
        document.removeEventListener("focusin", this.#HandleFocusChange);
        window.removeEventListener("dropdownOpened", this.#HandleDropdownOpened);
    }
    set dataSource(items) {
        this.#Data = items;
        this.#FilteredData = [...items];
        this.#RenderItems();
    }

    filterItems(query) {
        this.#FilteredData = this.#Data.filter((item) =>
            item.toLowerCase().includes(query.toLowerCase())
        );
        this.#CurrentPage = 0;
        this.#RenderItems();
    }

    #ChangePage(direction) {
        let totalPages = Math.ceil(this.#FilteredData.length / this.#ItemsPerPage);

        this.#CurrentPage = Math.min(Math.max(this.#CurrentPage + direction, 0), totalPages - 1);
        this.#RenderItems();
    }

    #RenderItems() {
        const start = this.#CurrentPage * this.#ItemsPerPage;
        const end = start + this.#ItemsPerPage;

        this.#HTML.DropdownItems.innerHTML = "";
        const pageItems = this.#FilteredData.slice(start, end);
        pageItems.forEach((item) => {
            const div = document.createElement("div");
            div.className = "dropdown-item";
            div.textContent = item;

            // Adiciona a classe 'selected' ao item correspondente ao valor do input
            if (item === this.#HTML.FilterInput.value) {
                div.classList.add("selected");
            }

            div.addEventListener("click", () => this.#SelectItem(item));
            this.#HTML.DropdownItems.appendChild(div);
        });

        this.#UpdatePagination();

        if (this.#FilteredData.length === 0) {
            this.#HideDropdown();
        }
    }

    #UpdatePagination() {
        let totalPages = Math.ceil(this.#FilteredData.length / this.#ItemsPerPage);

        this.#HTML.PrevButton.disabled = this.#CurrentPage === 0;
        this.#HTML.NextButton.disabled = this.#CurrentPage >= totalPages - 1;
        this.#HTML.Pagination.style.display = totalPages > 1 ? "flex" : "none";
    }

    #ShowDropdown() {
        let event = new CustomEvent("dropdownOpened", {
            detail: { dropdown: this },
            bubbles: true, // Permite a propagação do evento
        });
        window.dispatchEvent(event); // Dispara o evento globalmente

        this.#HTML.DropdownList.style.visibility = "hidden";
        this.#HTML.DropdownList.style.display = "block";

        let dropdownRect = this.#HTML.FilterInput.getBoundingClientRect(),
            listHeight = this.#HTML.DropdownList.scrollHeight,
            viewportHeight = window.innerHeight,
            spaceBelow = viewportHeight - dropdownRect.bottom,
            spaceAbove = dropdownRect.top;

        if (spaceBelow < listHeight && spaceAbove > listHeight) {
            this.#HTML.DropdownList.style.top = "auto";
            this.#HTML.DropdownList.style.bottom = `${dropdownRect.height}px`;
        } else {
            this.#HTML.DropdownList.style.top = `calc(100% + 0.8dvmin)`;
            this.#HTML.DropdownList.style.bottom = "auto";
        }
        this.#HTML.DropdownList.style.visibility = "visible";
        this.#HTML.DropdownList.classList.add("open");
    }

    #HideDropdown() {
        this.#HTML.DropdownList.classList.remove("open");
        this.#HTML.DropdownList.style.display = "none";
        this.#HTML.DropdownList.style.top = "";
        this.#HTML.DropdownList.style.bottom = "";
    }

    #SelectItem(item) {
        // Remove a classe 'selected' de todos os itens
        this.#HTML.DropdownItems.forEach((el) => el.classList.remove("selected"));

        // Adiciona a classe 'selected' ao item selecionado
        let selectedItem = Array.from(items).find((el) => el.textContent === item);

        if (selectedItem) {
            selectedItem.classList.add("selected");
        }
        this.#HTML.FilterInput.value = item;
        this.#HideDropdown();
    }
}
customElements.define("t-dropdown", TDropdown);