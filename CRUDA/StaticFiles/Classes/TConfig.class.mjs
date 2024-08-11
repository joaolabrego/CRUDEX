"use strict"

import TActions from "./TActions.class.mjs"
import TCrypto from "./TCrypto.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"

export default class TConfig {
    static #Locale = ""
    static #DecimalSeparator = ""
    static #ThousandSeparator = ""
    static #MinusSignal = ""
    static #IdleTimeInMinutesLimit = 0
    static #Timer = null
    static #Crypto = new TCrypto()

    static async GetAPI(action, parameters = {}) {
        let cryptoKey,
            body = {},
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/json",
            }

        if (action === TActions.CONFIG) {
            cryptoKey = headers.PublicKey = this.#Crypto.CryptoKey
        }
        else if (action === TActions.LOGIN) {
            headers.PublicKey = cryptoKey = TLogin.PublicKey
            body.Login = {
                Action: action,
                SystemName: TSystem.Name,
                UserName: TLogin.UserName,
                Password: TLogin.Password,
                PublicKey: TLogin.PublicKey
            }
        }
        else {
            headers.PublicKey = cryptoKey = TLogin.PublicKey
            headers.LoginId = TLogin.LoginId
            body.Login = {
                Action: action == TActions.LOGOUT ? action : TActions.AUTHENTICATE,
                SystemName: TSystem.Name,
                UserName: TLogin.UserName,
                Password: TLogin.Password,
            }
        }
        body.Parameters = parameters

        let crypto = new TCrypto(cryptoKey)
        const response = await fetch(`${location}/${action}`, {
            method: "POST",
            headers,
            body: JSON.stringify({ Request: crypto.Encrypt(JSON.stringify(body)) }),
        })

        let result = JSON.parse(crypto.Encrypt((await response.json()).Response))

        if (result.ClassName === "Error")
            throw result

        return result
    }
    static SetIdleTime(activate = true) {
        const setEvents = (value) => window.onload = window.onmousemove = window.onmousedown = window.ontouchstart = window.onclick = window.onbeforeinput = value
        const resetTimer = () => {
            clearTimeout(this.#Timer)
            this.#Timer = setTimeout(() => {
                clearTimeout(this.#Timer)
                TScreen.ShowAlert(`Sistema ocioso por mais de ${this.#IdleTimeInMinutesLimit} minuto(s).`, TActions.RELOAD, 10000)
            }, this.#IdleTimeInMinutesLimit * 60000)
        }
        if (activate) {
            setEvents(resetTimer)
            resetTimer()
        }
        else {
            setEvents(null)
            clearTimeout(this.#Timer)
        }
    }
    static get Locale() {
        if (this.#Locale)
            return this.#Locale

        return this.#Locale = navigator.languages && navigator.languages.length ? navigator.languages[0] : navigator.language
    }
    static get DecimalSeparator() {
        if (this.#DecimalSeparator)
            return this.#DecimalSeparator

        return this.#DecimalSeparator = (0.1).toLocaleString(this.Locale).replace(/\d/g, "")
    }
    static get ThousandSeparator() {
        if (this.#ThousandSeparator)
            return this.#ThousandSeparator

        return this.#ThousandSeparator = (1000).toLocaleString(this.Locale).replace(/\d/g, "")
    }
    static get MinusSignal() {
        if (this.#MinusSignal)
            return this.#MinusSignal

        return this.#MinusSignal = (-1).toLocaleString(this.Locale).replace(/\d/g, "")
    }
    static set IdleTimeInMinutesLimit(value) {
        this.#IdleTimeInMinutesLimit = value
    }
    static get Crypto() {
        return this.#Crypto
    }
}