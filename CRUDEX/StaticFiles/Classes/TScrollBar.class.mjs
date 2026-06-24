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
    #baseTitle = "";

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
            this.setTitle(options.title);

        this.#input.oninput = () => {
            const value = Math.trunc(Number(this.#input.value));
            if (value === this.#value)
                return;
            this.#value = value;
            if (this.#onChange)
                this.#onChange(value);
        };

        this.#input.addEventListener("mousemove", (event) => this.#showPageAtPointer(event));
        this.#input.addEventListener("mouseleave", () => this.#restoreTitle());

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
        this.#baseTitle = title ?? "";
        this.#restoreTitle();
    }

    #restoreTitle() {
        this.#input.title = this.#baseTitle;
        this.#root.title = this.#baseTitle;
    }

    #showPageAtPointer(event) {
        const page = this.#pageFromPointer(event);
        const title = `Página: ${page}`;
        this.#input.title = title;
        this.#root.title = title;
    }

    #pageFromPointer(event) {
        const min = Number(this.#input.min);
        const max = Number(this.#input.max);
        if (max <= min)
            return min;

        const rect = this.#input.getBoundingClientRect();
        const size = this.#orientation === TScrollBar.Orientations.HORIZONTAL
            ? rect.width || 1
            : rect.height || 1;
        let ratio = this.#orientation === TScrollBar.Orientations.HORIZONTAL
            ? (event.clientX - rect.left) / size
            : (event.clientY - rect.top) / size;

        ratio = Math.max(0, Math.min(1, ratio));
        return Math.min(max, Math.max(min, Math.round(min + ratio * (max - min))));
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
