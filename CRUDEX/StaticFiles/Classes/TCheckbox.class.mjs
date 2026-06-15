"use strict";

export default class TCheckbox {
    static Modes = {
        EDITION: "edition",
        CONDITION: "condition",
    };

    static States = {
        TRUE: "true",
        FALSE: "false",
        NULL: "null",
        EMPTY: "empty",
    };

    /** Marcador para condição IS NULL (distinto de ignorado). */
    static NULL_MARKER = Object.freeze({ __checkboxNull: true });

    static #Style = "";
    static #StyleInjected = false;

    #mode = TCheckbox.Modes.EDITION;
    #state = TCheckbox.States.EMPTY;
    #readOnly = false;
    #isRequired = false;
    #isTransparent = false;
    #nullAsEmpty = false;
    #name = "";
    #root = null;
    #button = null;
    #symbol = null;
    #hidden = null;
    #validityInput = null;
    #onChange = null;

    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        TCheckbox.#Style = styles.CheckBox ?? "";
    }

    static Create(container, options = {}) {
        return new TCheckbox(container, options);
    }

    static Edition(container, options = {}) {
        return new TCheckbox(container, { ...options, mode: TCheckbox.Modes.EDITION });
    }

    static Condition(container, options = {}) {
        return new TCheckbox(container, { ...options, mode: TCheckbox.Modes.CONDITION });
    }

    static isNullMarker(value) {
        return value?.constructor === Object && value.__checkboxNull === true;
    }

    static isIgnored(value) {
        return value === null || value === undefined;
    }

    static hasCondition(value) {
        return value === true || value === false || TCheckbox.isNullMarker(value);
    }

    static toFilterValue(value) {
        if (TCheckbox.isIgnored(value))
            return undefined;
        if (TCheckbox.isNullMarker(value))
            return null;
        return value;
    }

    static #injectStyle() {
        if (TCheckbox.#StyleInjected || !TCheckbox.#Style)
            return;
        const style = document.createElement("style");
        style.textContent = TCheckbox.#Style;
        document.head.appendChild(style);
        TCheckbox.#StyleInjected = true;
    }

    static #stateFromValue(value, mode, isRequired = false, readOnly = false, nullAsEmpty = false) {
        if (value === true)
            return TCheckbox.States.TRUE;
        if (value === false)
            return TCheckbox.States.FALSE;
        if (TCheckbox.isNullMarker(value))
            return TCheckbox.States.NULL;
        if (mode === TCheckbox.Modes.CONDITION && TCheckbox.isIgnored(value))
            return TCheckbox.States.EMPTY;
        if (nullAsEmpty && readOnly && TCheckbox.isIgnored(value))
            return TCheckbox.States.EMPTY;
        if (TCheckbox.isIgnored(value))
            return TCheckbox.States.NULL;
        return TCheckbox.States.NULL;
    }

    static #titles = {
        [TCheckbox.States.TRUE]: "sim",
        [TCheckbox.States.FALSE]: "não",
        [TCheckbox.States.NULL]: "nulo",
        [TCheckbox.States.EMPTY]: "vazio",
    };

    static #symbols = {
        [TCheckbox.States.TRUE]: "✓",
        [TCheckbox.States.FALSE]: "✗",
        [TCheckbox.States.NULL]: "–",
        [TCheckbox.States.EMPTY]: "\u00A0",
    };

    constructor(container, options = {}) {
        if (!container)
            throw new Error("Container element is required.");

        TCheckbox.#injectStyle();
        this.#mode = options.mode ?? TCheckbox.Modes.EDITION;
        this.#readOnly = options.readOnly ?? false;
        this.#isRequired = options.required ?? options.isRequired ?? false;
        this.#isTransparent = options.isTransparent ?? false;
        this.#nullAsEmpty = options.nullAsEmpty ?? false;
        this.#name = options.name ?? "";
        this.#onChange = options.onChange ?? null;

        this.#root = document.createElement("span");
        this.#root.className = "tcheckbox";
        this.#root.dataset.readonly = this.#readOnly ? "true" : "false";
        this.#root.dataset.required = this.#isRequired ? "true" : "false";
        this.#root.dataset.transparent = this.#isTransparent ? "true" : "false";

        this.#button = document.createElement("span");
        this.#button.className = "tcheckbox-button";
        this.#button.setAttribute("role", "checkbox");
        this.#button.tabIndex = this.#readOnly ? -1 : 0;

        this.#symbol = document.createElement("span");
        this.#button.appendChild(this.#symbol);
        this.#root.appendChild(this.#button);

        if (this.#name) {
            const hidden = document.createElement("input");
            hidden.type = "hidden";
            hidden.name = this.#name;
            this.#root.appendChild(hidden);
            this.#hidden = hidden;
        }

        if (this.#mode === TCheckbox.Modes.EDITION) {
            this.#validityInput = document.createElement("input");
            this.#validityInput.type = "text";
            this.#validityInput.tabIndex = -1;
            this.#validityInput.className = "tcheckbox-validity";
            this.#validityInput.setAttribute("aria-hidden", "true");
            this.#validityInput.autocomplete = "off";
            this.#root.appendChild(this.#validityInput);
        }

        this.#bindEvents();
        container.appendChild(this.#root);

        if (options.value !== undefined)
            this.setValue(options.value);
        else
            this.#applyState(this.#initialState());

        this.#applyRequiredConstraints();
    }

    #applyRequiredConstraints() {
        if (!this.#validityInput || this.#readOnly)
            return;
        if (this.#isRequired)
            this.#validityInput.setAttribute("required", "required");
        else
            this.#validityInput.removeAttribute("required");
    }

    #initialState() {
        if (this.#mode === TCheckbox.Modes.CONDITION)
            return TCheckbox.States.EMPTY;
        return TCheckbox.States.NULL;
    }

    #bindEvents() {
        this.#button.addEventListener("click", () => this.#advance());
        this.#button.addEventListener("keydown", (event) => {
            if (event.key === " " || event.key === "Enter") {
                event.preventDefault();
                this.#advance();
            }
        });
    }

    #cycle() {
        if (this.#mode === TCheckbox.Modes.CONDITION)
            return [TCheckbox.States.TRUE, TCheckbox.States.FALSE, TCheckbox.States.NULL, TCheckbox.States.EMPTY];
        if (this.#isRequired)
            return [TCheckbox.States.TRUE, TCheckbox.States.FALSE];
        return [TCheckbox.States.TRUE, TCheckbox.States.FALSE, TCheckbox.States.NULL];
    }

    #advance() {
        if (this.#readOnly)
            return;
        const cycle = this.#cycle();
        let index = cycle.indexOf(this.#state);
        if (index < 0)
            index = cycle.length - 1;
        const next = cycle[(index + 1) % cycle.length];
        this.#applyState(next);
        const value = this.#toValue();
        if (this.#hidden)
            this.#hidden.value = value === TCheckbox.NULL_MARKER ? "null" : String(value ?? "");
        if (this.#onChange)
            this.#onChange(value);
        this.#syncFormValidity();
        this.#root.dispatchEvent(new CustomEvent("change", {
            bubbles: true,
            detail: { value },
        }));
    }

    #toValue() {
        switch (this.#state) {
            case TCheckbox.States.TRUE:
                return true;
            case TCheckbox.States.FALSE:
                return false;
            case TCheckbox.States.NULL:
                return this.#mode === TCheckbox.Modes.CONDITION
                    ? TCheckbox.NULL_MARKER
                    : null;
            default:
                return null;
        }
    }

    #applyState(state) {
        this.#state = state;
        this.#root.dataset.state = this.#state;
        this.#symbol.textContent = TCheckbox.#symbols[this.#state];
        const title = this.#nullAsEmpty && this.#readOnly && this.#state === TCheckbox.States.EMPTY
            ? TCheckbox.#titles[TCheckbox.States.NULL]
            : TCheckbox.#titles[this.#state];
        this.#root.title = title;
        this.#button.title = title;
        this.#button.setAttribute("aria-checked",
            this.#state === TCheckbox.States.TRUE ? "true"
                : this.#state === TCheckbox.States.FALSE ? "false"
                    : "mixed");
    }

    setValue(value) {
        this.#applyState(TCheckbox.#stateFromValue(
            value, this.#mode, this.#isRequired, this.#readOnly, this.#nullAsEmpty));
        if (this.#hidden)
            this.#hidden.value = this.#toValue() === TCheckbox.NULL_MARKER ? "null" : String(this.#toValue() ?? "");
        this.#syncFormValidity();
    }

    #syncFormValidity() {
        if (this.#readOnly || this.#mode === TCheckbox.Modes.CONDITION) {
            this.#validityInput?.setCustomValidity("");
            this.#root.classList.remove("invalid");
            return;
        }
        const invalid = this.#isRequired && !this.isValid();
        if (this.#validityInput) {
            if (invalid)
                this.#validityInput.setCustomValidity("Informe um valor");
            else
                this.#validityInput.setCustomValidity("");
        }
        this.#root.classList.toggle("invalid", invalid);
    }

    isValid() {
        if (!this.#isRequired || this.#readOnly || this.#mode === TCheckbox.Modes.CONDITION)
            return true;
        return this.#state !== TCheckbox.States.NULL;
    }

    reportValidity() {
        this.#syncFormValidity();
        if (this.isValid())
            return true;
        const anchor = this.#validityInput;
        if (!anchor)
            return false;
        anchor.focus();
        anchor.reportValidity();
        return false;
    }

    syncFormValidity() {
        this.#syncFormValidity();
    }

    get validityInput() {
        return this.#validityInput ?? this.#hidden;
    }

    get IsRequired() {
        return this.#isRequired;
    }

    set IsRequired(value) {
        this.#isRequired = !!value;
        this.#root.dataset.required = this.#isRequired ? "true" : "false";
        this.#applyRequiredConstraints();
        if (this.#mode === TCheckbox.Modes.EDITION)
            this.#applyState(this.#state);
        this.#syncFormValidity();
    }

    get IsTransparent() {
        return this.#isTransparent;
    }

    set IsTransparent(value) {
        this.#isTransparent = !!value;
        this.#root.dataset.transparent = this.#isTransparent ? "true" : "false";
    }

    get value() {
        return this.#toValue();
    }

    get element() {
        return this.#root;
    }

    get input() {
        return this.#button;
    }

    get state() {
        return this.#state;
    }

    get mode() {
        return this.#mode;
    }
}
