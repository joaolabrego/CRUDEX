"use strict"

import TActions from "./TActions.class.mjs"
import TCrypto from "./TCrypto.class.mjs"
import TLogin from "./TLogin.class.mjs"
import TScreen from "./TScreen.class.mjs"
import TSystem from "./TSystem.class.mjs"
import TSpinner from "./TSpinner.class.mjs"

export default class TConfig {
    static #Locale = ""
    static #DecimalSeparator = ""
    static #ThousandSeparator = ""
    static #MinusSignal = ""
    static #IdleTimeInMinutesLimit = 0
    static #Timer = null

    static async GetAPI(action, parameters = {}, showSpinner = true) {
        let result,
            crypto,
            body = {},
            request = {},
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
            url = `${location}/${action}`

        if (action === TActions.CONFIG) {
            request.PublicKey = TCrypto.GenerateCryptokey()
            crypto = new TCrypto(request.PublicKey)
        } else {
            if (showSpinner)
                TSpinner.Show()
            if (action === TActions.LOGIN) {
                request.PublicKey = TCrypto.GenerateCryptokey()
                body.Login = {
                    Action: action,
                    SystemName: TSystem.Name,
                    UserName: TLogin.UserName,
                    Password: TLogin.Password,
                    PublicKey: request.PublicKey,
                }
                crypto = new TCrypto(request.PublicKey)
            }
            else {
                request.LoginId = TLogin.LoginId
                body.Login = {
                    Action: action == TActions.LOGOUT ? action : TActions.AUTHENTICATE,
                    SystemName: TSystem.Name,
                    UserName: TLogin.UserName,
                    Password: TLogin.Password,
                    LoginId: TLogin.LoginId,
                }
                crypto = new TCrypto(TLogin.PublicKey)
            }
        }
        body.Parameters = parameters
        request.Request = crypto.EncryptDecrypt(JSON.stringify(body))
        if (action === TActions.LOGOUT && navigator.sendBeacon) {
            result = navigator.sendBeacon(url, JSON.stringify(request)) ? {} : { ClassName: "Error", Message: "Erro ao enviar LOGOUT via sendBeacon." }
        } else {
            let response = await fetch(url, {
                method: "POST",
                headers,
                body: JSON.stringify(request),
            })
            result = JSON.parse(crypto.EncryptDecrypt((await response.json()).Response))
        }
        if (showSpinner && action !== TActions.CONFIG)
            TSpinner.Hide()
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
    static IsEmpty(value) {
        return value === null || value === undefined || String(value).trim() === ""
    }
    static CreateProperties(origin, target) {
        for (let [key, value] of Object.entries(origin)) {
            let propertyName = `#${key}`

            if (key !== "ClassName") {
                target[propertyName] = value
                Object.defineProperty(target, key, {
                    get() { return target[propertyName]; },
                });
            }
        }

        return target
    }
    static Evaluate(JSexpression) {
        return eval(JSexpression)
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
    /**
     * @param {number} value
     */
    static set IdleTimeInMinutesLimit(value) {
        this.#IdleTimeInMinutesLimit = value
    }
}