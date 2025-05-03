"use strict";

class TCheckbox extends HTMLElement {
    static #Style = "";

    #State = 0;
    #Symbols = ["", "✔", "–", "?"];
    #AriaStates = ["false", "true", "mixed", "undefined"];
    #Tooltips = ["Não", "Sim", "Nulo", "Valor nulo"];
    #HTML = {
        Container: null,
        Box: null,
        Legend: null,
    };

    constructor() {
        super();

        let style = document.createElement("style");

        this.#HTML.Container = document.createElement("div");
        style.innerText = TCheckbox.#Style;

        this.#HTML.Container.appendChild(style);
    }
    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        TCheckbox.#Style = styles.Checkbox;
    }

    connectedCallback() {
        this.#HTML.Box = document.createElement("span");
        this.#HTML.Box.onclick = (event) => {
            event.preventDefault();
            this.#AdvanceState();
        };
        this.#HTML.Box.onkeydown = (event) => {
            if (event.key === " " || event.key === "Enter") {
                event.preventDefault();
                this.#AdvanceState();
            }
        };

        this.#HTML.Container.appendChild(this.#HTML.Box);

        this.#HTML.Legend = document.createElement("span");
        this.#HTML.Legend.textContent = this.textContent.trim();

        this.#HTML.Container.appendChild(this.#HTML.Legend);

        this.#Update();

        this.appendChild(this.#HTML.Container);
    };
    #Update() {
        this.#HTML.Box.textContent = this.#Symbols[this.#State];
        this.#HTML.Box.setAttribute("aria-checked", this.#AriaStates[this.#State]);
        this.#HTML.Box.setAttribute("title", this.#Tooltips[this.#State]);
    }
    #AdvanceState() {
        this.#State = (this.#State + 1) % 4;
        this.#Update();
    }
}

customElements.define("tri-checkbox", TriCheckbox);
