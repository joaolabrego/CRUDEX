"use strict";

export default class TScrollBar {
    static Orientations = {
        VERTICAL: "vertical",
        HORIZONTAL: "horizontal",
    };

    static #Style = "";
    static #StyleInjected = false;

    #root = null;
    #input = null;
    #orientation = TScrollBar.Orientations.VERTICAL;
    #onChange = null;
    #value = 1;

    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.");
        TScrollBar.#Style = styles.ScrollBar ?? "";
    }

    static Attach(container, options = {}) {
        return new TScrollBar(container, options);
    }

    static #injectStyle() {
        if (TScrollBar.#StyleInjected || !TScrollBar.#Style)
            return;
        const style = document.createElement("style");
        style.textContent = TScrollBar.#Style;
        document.head.appendChild(style);
        TScrollBar.#StyleInjected = true;
    }

    constructor(container, options = {}) {
        TScrollBar.#injectStyle();
        this.#orientation = options.orientation ?? TScrollBar.Orientations.VERTICAL;
        this.#onChange = options.onChange ?? null;

        this.#root = document.createElement("div");
        this.#root.className = "tscrollbar";
        this.#root.dataset.orientation = this.#orientation;

        this.#input = document.createElement("input");
        this.#input.type = "range";
        this.#input.className = "tscrollbar-range";
        this.#input.min = options.min ?? 1;
        this.#input.max = options.max ?? 1;
        this.#input.value = options.value ?? this.#input.min;
        this.#value = Number(this.#input.value);

        if (options.title)
            this.#input.title = options.title;

        this.#input.oninput = () => {
            const value = Math.trunc(Number(this.#input.value));
            if (value === this.#value)
                return;
            this.#value = value;
            if (this.#onChange)
                this.#onChange(value);
        };

        this.#root.appendChild(this.#input);

        if (container)
            container.appendChild(this.#root);
    }

    setRange(min, max, value = min) {
        this.#input.min = min;
        this.#input.max = max;
        this.#input.value = value;
        this.#value = Number(value);
    }

    setVisible(visible) {
        this.#root.classList.toggle("invisible", !visible);
    }

    setTitle(title) {
        this.#input.title = title ?? "";
        this.#root.title = title ?? "";
    }

    get value() {
        return this.#value;
    }

    set value(value) {
        this.#input.value = value;
        this.#value = Number(value);
    }

    get element() {
        return this.#root;
    }

    get input() {
        return this.#input;
    }

    get orientation() {
        return this.#orientation;
    }
}
