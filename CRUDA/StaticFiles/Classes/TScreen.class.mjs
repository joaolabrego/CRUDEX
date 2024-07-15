"use strict"

import TConfig from "./TConfig.class.mjs"
import TDialog from "./TDialog.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TScreen {
    static #LastMessage = string.Empty
    static #Message = string.Empty
    static #BackgroundImage = string.Empty
    static #BlinkMessage = false
    static #Timeout = null
    static #HTML = {
        Container: null,
        Date: null,
        UserName: null,
        Title: null,
        Time: null,
        Main: null,
        Message: null,
    }

    static Initialize(styles, images, withBackgroundImage) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")
        if (images.ClassName !== "Images")
            throw new Error("Argumento images não é do tipo Images.")
        this.#HTML.Container = document.createDocumentFragment()

        let style = document.createElement("style")

        style.innerText = styles.Screen
        this.#HTML.Container.appendChild(style)

        let header = document.createElement("header")
        header.className = "box header"

        let span = document.createElement("span")
        span.textContent = TSystem.ClientName

        header.appendChild(span)

        span = document.createElement("span")
        span.textContent = `${TSystem.Name} - ${TSystem.Description}`

        header.appendChild(span)

        this.#HTML.Date = document.createElement("span")

        header.appendChild(this.#HTML.Date)

        this.#HTML.UserName = document.createElement("span")
        this.#HTML.UserName.textContent = TLogin.UserName
        header.appendChild(this.#HTML.UserName)

        this.#HTML.Title = document.createElement("span")
        header.appendChild(this.#HTML.Title)

        this.#HTML.Time = document.createElement("span")
        header.appendChild(this.#HTML.Time)

        this.#HTML.Container.appendChild(header)

        this.#HTML.Main = document.createElement("main")
        this.#HTML.Main.className = "box main"
        this.#HTML.Container.appendChild(this.#HTML.Main)

        this.#BackgroundImage = withBackgroundImage ? images.Background : null
        this.WithBackgroundImage = withBackgroundImage       

        this.#HTML.Message = document.createElement("footer")
        this.#HTML.Message.innerText = this.#Message
        this.#HTML.Message.className = "box footer"

        this.#HTML.Container.appendChild(this.#HTML.Message)
    }

    static Renderize() {
        document.body.innerHTML = null
        document.body.appendChild(this.#HTML.Container)
        this.Message = string.Empty
        this.#Update()
    }

    static #Update() {
        let now = new Date(),
            localdate = now.toLocaleDateString(TConfig.Locale).toUpperCase(),
            localtime = now.toLocaleTimeString(TConfig.Locale).toUpperCase()
        
        if (this.#HTML.Date.innerText.toUpperCase() !== localdate)
            this.#HTML.Date.innerText = localdate

        if (this.#HTML.Time.innerText.toUpperCase() !== localtime)
            this.#HTML.Time.innerText = localtime

        if (this.#BlinkMessage && this.#HTML.Message.innerText)
            this.#HTML.Message.innerText = string.Empty
        else if (this.#HTML.Message.innerText.toUpperCase() !== this.#Message.toUpperCase())
            this.#HTML.Message.innerText = this.#Message

        if (this.#Timeout)
            clearTimeout(this.#Timeout)
        this.#Timeout = setTimeout(() => this.#Update(), 250)
    }
    static ShowQuestion(message, yesAction, notAction) {
        TDialog.Show("question", message, yesAction, notAction)
    }
    static ShowAlert(message, okAction, timeout = null) {
        TDialog.Show("alert", message, okAction, null, timeout)
    }
    static ShowError(message, okAction, timeout = null) {
        TDialog.Show("error", message, okAction, null, timeout)
    }
    static set Main(value) {
        this.#HTML.Main.innerHTML = null
        this.#HTML.Main.appendChild(TDialog.Container)
        this.#HTML.Main.appendChild(value)
    }
    static get Main() {
        return this.#HTML.Main
    }
    static set LastMessage(value) {
        this.#LastMessage = value
    }
    static get LastMessage() {
        return this.#LastMessage
    }
    /**
     * @param {string} value
     */
    static set Title(value) {
        this.#HTML.Title.innerText = value
    }
    /**
     * @param {string} value
     */
    static set Message(value) {
        this.#Message = this.#HTML.Message.innerText = value
        this.#HTML.Message.className = this.#HTML.Message.className.replace(/ errorMessage/g, string.Empty)
        this.#BlinkMessage = false
    }
    /**
     * @param {string} value
     */
    static set ErrorMessage(value) {
        this.#Message = this.#HTML.Message.innerText = value
        this.#HTML.Message.className += " errorMessage"
        this.#BlinkMessage = true
    }
    static set UserName(value) {
        this.#HTML.UserName.innerText = value
    }
    /**
     * @param {boolean} value
     */
    static set WithBackgroundImage(value) {
        this.#HTML.Main.style.backgroundImage = value ? this.#BackgroundImage : null
    }
}