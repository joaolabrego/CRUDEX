"use strict";

import TSystem from "./TSystem.class.mjs";

export default class TDropdown extends HTMLElement {
    static #Style = "";

    #Table = "";
    #Id = 0;
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
    constructor(databaseName, tableName, id) {
        let database = TSystem.GetDatabase(databaseName);

        if (!database)
            throw new Error("Banco-de-dados não encontrado.");
        this.#Table = database.GetTable(tableName);
        if (!this.#Table)
            throw new Error("Tabela de banco-de-dados não encontrada.");
        this.#Id = id;
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
        this.#HTML.Pagination.appendChild(this.#HTML.PrevButton);

        this.#HTML.NextButton = document.createElement("button");
        this.#HTML.NextButton.className = "prev-button"
        this.#HTML.NextButton.innerText = String.fromCharCode(9654);
        this.#HTML.Pagination.appendChild(this.#HTML.NextButton);
    }
}
customElements.define("t-dropdown", TDropdown);