"use strict";

import TActions from "./TActions.class.mjs";
import TLogin from "./TLogin.class.mjs";
import TScreen from "./TScreen.class.mjs";
import TSystem from "./TSystem.class.mjs";
import TSpinner from "./TSpinner.class.mjs";

export default class TConfig {
    static #Locale = null;
    static #DecimalSeparator = null;
    static #ThousandSeparator = null;
    static #MinusSignal = null;
    static #DateSeparator = null;
    static #TimeSeparator = null;
    static #YearDigits = null;;
    static #DateFormat = null;
    static #DateTimeFormat = null;
    static #TimeFormat = null;
    static #IdleTimeInMinutesLimit = 0;
    static #Timer = null;

    static async GetAPI(action, parameters = {}, showSpinner = true) {
        let result,
            body = {},
            request = {},
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
            url = `${location}/${action}`;
        if (action !== TActions.CONFIG) {
            if (showSpinner)
                TSpinner.Show();
            if (action === TActions.LOGIN || action === TActions.CHANGE) {
                body.Login = {
                    Action: action,
                    SystemName: TSystem.Name,
                    UserName: TLogin.UserName,
                    Password: TLogin.Password,
                    NewPassword: parameters.NewPassword ?? null,
                    RetypedPassword: parameters.RetypedPassword ?? null,
                };
                if (action === TActions.CHANGE)
                    parameters = {};
            }
            else {
                request.LoginId = TLogin.LoginId;
                body.Login = {
                    Action: action == TActions.LOGOUT ? action : TActions.AUTHENTICATE,
                    SystemName: TSystem.Name,
                    UserName: TLogin.UserName,
                    Password: TLogin.Password,
                    LoginId: TLogin.LoginId,
                    NewPassword: null,
                    RetypedPassword: null,
                };
            }
        }
        body.Parameters = parameters;
        request.Request = JSON.stringify(body);
        if (action === TActions.LOGOUT && navigator.sendBeacon) {
            result = navigator.sendBeacon(url, new Blob([JSON.stringify(request)], { type: 'application/json' })) ? {} : { ClassName: "Error", Message: "Erro ao enviar LOGOUT via sendBeacon." };
        } else {
            let response = await fetch(url, {
                method: "POST",
                headers,
                body: JSON.stringify(request),
            });
            result = JSON.parse((await response.json()).Response);
        }
        if (showSpinner && action !== TActions.CONFIG)
            TSpinner.Hide();
        if (result.ClassName === "Error")
            throw result;

        return result;
    }
    static SetIdleTime(activate = true) {
        const setEvents = (value) => window.onload = window.onmousemove = window.onmousedown = window.ontouchstart = window.onclick = window.onbeforeinput = value;
        const resetTimer = () => {
            clearTimeout(this.#Timer);
            this.#Timer = setTimeout(() => {
                clearTimeout(this.#Timer);
                TScreen.ShowAlert(`Sistema ocioso por mais de ${this.#IdleTimeInMinutesLimit} minuto(s).`, TActions.RELOAD, 10000);
            }, this.#IdleTimeInMinutesLimit * 60000);
        };
        if (activate) {
            setEvents(resetTimer);
            resetTimer();
        }
        else {
            setEvents(null);
            clearTimeout(this.#Timer);
        }
    }
    static IsEmpty(value) {
        return value === null || value === undefined || String(value).trim() === "";
    }
    static CreateProperties(origin, target) {
        for (let [key, value] of Object.entries(origin)) {
            let propertyName = `#${key}`;

            if (key !== "ClassName") {
                target[propertyName] = value;
                Object.defineProperty(target, key, {
                    get() { return target[propertyName]; },
                });
            }
        }

        return target;
    }
    static Evaluate(expression) {
        return eval(expression);
    }
    static EvaluateTableExpression(expression, table) {
        const resolveColumnValue = (table, columnName) => {
            let column = table.GetColumn(columnName);

            if (column)
                return column.Value;

            // Se a coluna não existir na tabela atual, verifica na tabela pai.
            if (table.ParentTableId) {
                const parentTable = TSystem.GetTable(table.ParentTableId);
                return resolveColumnValue(parentTable, columnName);
            }

            // Se a coluna não foi encontrada, lança um erro.
            throw new Error(`Nome de coluna '${columnName}' não existe.`);
        };

        try {
            // Cria uma função dinâmica para avaliar a expressão.
            const func = new Function('$', `return ${expression};`);
            return func(new Proxy(table, {
                get: (_, columnName) => resolveColumnValue(table, columnName),
            }));
        } catch (error) {
            console.error('Erro ao avaliar expressão:', error);
            return undefined;
        }
    }
    static get Locale() {
        return this.#Locale ??= navigator.languages?.[0] ?? navigator.language;
    }
    static get DecimalSeparator() {
        return this.#DecimalSeparator ??= (0.1).toLocaleString(this.Locale).replace(/\d/g, "");
    }
    static get ThousandSeparator() {
        return this.#ThousandSeparator ??= (1000).toLocaleString(this.Locale).replace(/\d/g, "");
    }
    static get MinusSignal() {
        return this.#MinusSignal ??= (-1).toLocaleString(this.Locale).replace(/\d/g, "");
    }
    static get DateSeparator() {
        return this.#DateSeparator ??= (new Date(1900, 0, 1)).toLocaleDateString(this.Locale).replace(/\d/g, "").trim()[0] || "/";
    }
    static get TimeSeparator() {
        return this.#TimeSeparator ??= (new Date(1900, 0, 1)).toLocaleTimeString(this.Locale).replace(/[\dAPMapm\s]/g, "").trim()[0] || ":";
    }
    static get YearDigits() {
        return this.#YearDigits ??= /\b\d{4}\b/.test(new Date(1900, 0, 1).toLocaleDateString(this.Locale)) ? 4 : 2;
    }
    static get DateFormat() {
        if (this.#DateFormat)
            return this.#DateFormat;

        let parts = new Date(2025, 11, 10).toLocaleDateString(this.Locale).match(/\d+/g),
            dateSeparator = this.DateSeparator,
            yearDigits = this.YearDigits;

        if (!parts || parts.length < 3)
            return this.#DateFormat = `dd${dateSeparator}MM${dateSeparator}${yearDigits === 4 ? "yyyy" : "yy"}`;

        if (parts[0] === "10")
            this.#DateFormat = "dd";
        else if (parts[0] === "12")
            this.#DateFormat = "MM";
        else
            this.#DateFormat = yearDigits === 4 ? "yyyy" : "yy";

        if (parts[1] === "10")
            this.#DateFormat += dateSeparator + "dd";
        else if (parts[1] === "12")
            this.#DateFormat += dateSeparator + "MM";
        else
            this.#DateFormat += dateSeparator + (yearDigits === 4 ? "yyyy" : "yy");

        if (parts[2] === "10")
            this.#DateFormat += dateSeparator + "dd";
        else if (parts[2] === "12")
            this.#DateFormat += dateSeparator + "MM";
        else
            this.#DateFormat += dateSeparator + (yearDigits === 4 ? "yyyy" : "yy");

        return this.#DateFormat;
    }

    static get TimeFormat() {
        if (this.#TimeFormat)
            return this.#TimeFormat;

        let parts = new Date(2025, 11, 10, 23, 40, 50).toLocaleTimeString(this.Locale).match(/\d+/g),
            timeSeparator = this.TimeSeparator;

        if (!parts || parts.length < 3)
            return this.#TimeFormat = `hh${timeSeparator}mm${timeSeparator}ss`;

        if (parts[0] === "23")
            this.#TimeFormat = "hh";
        else if (parts[0] === "40")
            this.#TimeFormat = "mm";
        else
            this.#TimeFormat = "ss";

        if (parts[1] === "23")
            this.#TimeFormat += timeSeparator + "hh";
        else if (parts[1] === "40")
            this.#TimeFormat += timeSeparator + "mm";
        else
            this.#TimeFormat += timeSeparator + "ss";

        if (parts[2] === "23")
            this.#TimeFormat += timeSeparator + "hh";
        else if (parts[2] === "40")
            this.#TimeFormat += timeSeparator + "mm";
        else
            this.#TimeFormat += timeSeparator + "ss";

        return this.#TimeFormat;
    }

    static get DateTimeFormat() {
        return this.#DateTimeFormat ??= `${this.DateFormat} ${this.TimeFormat}`;
    }

    /**
     * @param {number} value
     */
    static set IdleTimeInMinutesLimit(value) {
        this.#IdleTimeInMinutesLimit = value;
    }
}