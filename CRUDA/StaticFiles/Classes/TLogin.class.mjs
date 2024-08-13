"use strict"

import TActions from "./TActions.class.mjs"
import TConfig from "./TConfig.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TLogin {
    static #LoginId = 0
    static #PublicKey = ""
    static #HTML = {
        Container: null,
        UserName: null,
        Password: null,
        Submit: null,
        Style: null,
    }
    static Initialize(styles) {
        if (styles.ClassName !== "Styles")
            throw new Error("Argumento styles não é do tipo Styles.")
        this.#HTML.Container = document.createElement("form")
        this.#HTML.Container.className = "login box"
        this.#HTML.Container.onkeyup = (event) => {
            if (event.key === "Enter")
                this.#HTML.Submit.click()
        }

        this.#HTML.Style = document.createElement("style")
        this.#HTML.Style.innerText = styles.Login
        this.#HTML.Container.appendChild(this.#HTML.Style)

        this.#HTML.UserName = document.createElement("input")
        this.#HTML.UserName.setAttribute("id", "textUserName")
        this.#HTML.UserName.setAttribute("type", "text")
        this.#HTML.UserName.setAttribute("title", "Digite seu nome de usuário")
        this.#HTML.UserName.setAttribute("placeholder", "username")
        this.#HTML.UserName.setAttribute("required", "true")
        this.#HTML.UserName.setAttribute("autocomplete", "off")
        this.#HTML.UserName.setAttribute("value", "adm")
        this.#HTML.UserName.onfocus = () => this.#HTML.UserName.select()
        this.#HTML.UserName.oninput = () => TScreen.UserName = this.#HTML.UserName.value

        this.#HTML.Container.appendChild(this.#HTML.UserName)

        this.#HTML.Password = document.createElement("input")
        this.#HTML.Password.setAttribute("id", "textPassword")
        this.#HTML.Password.setAttribute("type", "password")
        this.#HTML.Password.setAttribute("title", "Digite sua senha")
        this.#HTML.Password.setAttribute("placeholder", "password")
        this.#HTML.Password.setAttribute("required", "true")
        this.#HTML.Password.setAttribute("autocomplete", "off")
        this.#HTML.Password.setAttribute("value", "adm")
        this.#HTML.Password.onfocus = () => this.#HTML.Password.select()

        this.#HTML.Container.appendChild(this.#HTML.Password)

        this.#HTML.Submit = document.createElement("button")
        this.#HTML.Submit.setAttribute("type", "button")
        this.#HTML.Submit.setAttribute("title", "Clique para enviar nome e senha de usuário")
        this.#HTML.Submit.innerText = "Enviar"
        this.#HTML.Submit.onclick = (event) => {
            event.preventDefault()
            event.stopPropagation()
            if (this.#HTML.UserName.validity.valueMissing) {
                TScreen.ErrorMessage = "Nome do usuário é requerido."
                this.#HTML.UserName.focus()
            }
            else if (this.#HTML.Password.validity.valueMissing) {
                TScreen.ErrorMessage = "Senha do usuário é requerida."
                this.#HTML.Password.focus()
            }
            else {
                TConfig.GetAPI(TActions.LOGIN)
                    .then((result) => {
                        this.#LoginId = result.Parameters.ReturnValue
                        this.#PublicKey = result.Parameters.PublicKey
                        TSystem.Action = TActions.MENU
                    })
                    .catch(error => {
                        if (error.Action) {
                            TScreen.ErrorMessage = error.Message
                            this.#HTML.UserName.focus()
                        }
                        else {
                            TScreen.ErrorMessage = error.Message
                            if (error.Message.toLowerCase().indexOf("senha") === -1)
                                this.#HTML.UserName.focus()
                            else
                                this.#HTML.Password.focus()
                        }
                    })
            }
        }
        this.#HTML.Container.appendChild(this.#HTML.Submit)
    }
    static Renderize() {
        TScreen.Title = "Acesso do Usuário"
        TScreen.Message = "Digite seu login e senha de usuário."
        TScreen.Main = this.#HTML.Container
        this.#HTML.UserName.focus()
    }
    static Logout() {
        if (this.#LoginId)
            TConfig.GetAPI(TActions.LOGOUT)
                .then((result) => this.#LoginId = result.ReturnValue)
                .catch(error => TScreen.ShowError(error.Message, error.Action))
    }
    static set LoginId(value) {
        this.#LoginId = value
    }
    static get LoginId() {
        return this.#LoginId
    }
    static get PublicKey() {
        return this.#PublicKey
    }
    static set UserName(value) {
        this.#HTML.UserName.value = TScreen.UserName = value
    }
    static get UserName() {
        return this.#HTML.UserName.value
    }
    static set Password(value) {
        this.#HTML.Password.value = value
    }
    static get Password() {
        return this.#HTML.Password.value
    }
    static get PublicKey() {
        return this.#PublicKey
    }
}