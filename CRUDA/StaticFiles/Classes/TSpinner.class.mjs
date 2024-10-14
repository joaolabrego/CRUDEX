"use strict"

export default class TSpinner {
    static #Container = null

    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")

        let style = document.createElement("style")

        debugger
        style.innerText = styles.Spinner
        this.#Container = document.createElement("dialog")
        this.#Container.appendChild(style)
        this.#Container.className = "dialog"
    }
    static Show() {
        this.#Container.showModal()
    }
    static Hide() {
        this.#Container.close()
    }
    static get Container() {
        return this.#Container
    }
}
