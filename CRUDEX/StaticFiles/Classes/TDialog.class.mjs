"use strict"

import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TDialog {
    static #Images = null
    static #Timer = null

    static #HTML = {
        Container: null,
        Image: null,
        Message: null,
        Confirm: null,
        Cancel: null,
        Style: null,
    }

    static Initialize(styles, images) {
        this.#HTML.Container = document.createElement("dialog")
        this.#HTML.Container.className = "box dialog"

        this.#HTML.Style = document.createElement("style")
        this.#HTML.Style.innerText = styles.Dialog
        this.#HTML.Container.appendChild(this.#HTML.Style)

        this.#HTML.Image = document.createElement("img")
        this.#HTML.Image.alt = "Imagem"

        this.#HTML.Container.appendChild(this.#HTML.Image)

        this.#HTML.Message = document.createElement("p")

        this.#HTML.Container.appendChild(this.#HTML.Message)

        this.#HTML.Confirm = document.createElement("button")
        this.#HTML.Confirm.type = "button"
        this.#HTML.Confirm.innerText = "Confirmar"

        this.#HTML.Container.appendChild(this.#HTML.Confirm)

        this.#HTML.Cancel = document.createElement("button")
        this.#HTML.Cancel.type = "button"
        this.#HTML.Cancel.innerText = "Cancelar"

        this.#HTML.Container.appendChild(this.#HTML.Cancel)

        this.#Images = {
            Question: images.Question,
            Alert: images.Alert,
            Error: images.Error,
        }
    }

    static Show(type, message, confirmAction = null, cancelAction = null, timeout = null) {
        this.#HTML.Message.innerText = message
        this.#HTML.Confirm.onclick = () => {
            clearTimeout(this.#Timer)
            if (confirmAction)
                TSystem.Action = confirmAction
            this.#HTML.Container.close()
        }
        if (type === "question") {
            this.#HTML.Image.src = this.#Images.Question
            this.#HTML.Confirm.innerText = "Sim"
            this.#HTML.Cancel.innerText = "Não"
            this.#HTML.Cancel.removeAttribute("hidden")
            this.#HTML.Cancel.onclick = () => {
                if (cancelAction)
                    TSystem.Action = cancelAction
                this.#HTML.Container.close()
            }
        }
        else {
            this.#HTML.Image.src = type === "error" ? this.#Images.Error : this.#Images.Alert
            this.#HTML.Confirm.innerText = "Ok"
            this.#HTML.Cancel.hidden = "hidden"
            if (timeout) {
                clearTimeout(this.#Timer)
                this.#Timer = setTimeout(() => this.#HTML.Confirm.click(), timeout)
            }
        }
        this.#HTML.Container.showModal()
    }
    static get Container() {
        return this.#HTML.Container
    }
}