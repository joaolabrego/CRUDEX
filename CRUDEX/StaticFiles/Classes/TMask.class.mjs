"use strict";

import TConfig from "./TConfig.class.mjs";
export default class TMask {
    static #ThousandSeparator = TConfig.ThousandSeparator;
    static #DecimalSeparator = TConfig.DecimalSeparator;
    static #MinusSignal = TConfig.MinusSignal;
    static #NumericMask = "#";
    static #AlphabeticMask = "@";
    static #AlphaNumericMask = "*";
    static #DayMask = "d";
    static #MonthMask = "M";
    static #YearMask = "y";
    static #HoursMask = "h";
    static #MinutesMask = "m";
    static #SecondsMask = "s";
    static #AllMasks =
        this.#NumericMask +
        this.#AlphabeticMask +
        this.#AlphaNumericMask +
        this.#DayMask +
        this.#MonthMask +
        this.#YearMask +
        this.#HoursMask +
        this.#MinutesMask +
        this.#SecondsMask;
    static CheckDigitParameters = {
        Module: 11,
        Factors: [],
        DigitGreaterThanNine: "0",
        SubtractFromModule: false,
    };

    constructor(rowMask) {
        if (rowMask.Kind !== "Mask")
            throw new Error("Argumento rowMask não é do tipo Mask.");
        TConfig.CreateProperties(rowMask, this);
    }

    static FormatInputValue(
        input,
        masks,
        options = "",
        validatorFunction = null
    ) {
        let cursorPosition = input.selectionStart,
            endOfText = input.selectionStart === input.value.length;

        if (input.type !== "text") {
            input.type = "text";
            cursorPosition = input.value.length;
        }
        input.value = this.#FormatValue(input.value, masks, options);
        input.style.backgroundColor = validatorFunction && !validatorFunction() ? "red" : "";
        input.selectionStart = input.selectionEnd = endOfText ? input.value.length : cursorPosition;
    }

    static CountNumericMaskDigits(mask) {
        return String(mask).split("").filter(ch => ch === this.#NumericMask).length;
    }

    static IsNumericMask(mask) {
        if (Array.isArray(mask))
            return false;
        const text = String(mask);
        for (const ch of text) {
            if (ch === this.#NumericMask)
                continue;
            if (ch === this.#ThousandSeparator)
                continue;
            if (ch === this.#DecimalSeparator)
                continue;
            return false;
        }
        return text.includes(this.#NumericMask);
    }

    static #FormatValue(value, masks, options = "") {
        let result = "",
            mask = "";

        if (Array.isArray(masks))
            for (let i = 0; i < masks.length; i++) {
                mask = String(masks[i]);
                if (mask.length >= value.length)
                    break;
            }
        else mask = masks;

        let rawMask = mask.replace(new RegExp(`[^${this.#AllMasks}]`, "g"), "");

        value = value.replace(/[^0-9A-Za-z]/g, "");
        options = options.toLowerCase();
        if (options.includes("upper"))
            value = value.toUpperCase();
        else if (options.includes("lower"))
            value = value.toLowerCase();
        for (let i = 0, j = 0; i < value.length && j < mask.length; j++) {
            if (mask[j] === this.#NumericMask) {
                if (/[0-9]/.test(value[i]))
                    result += value[i++];
                else
                    break;
            } else if (mask[j] === this.#AlphabeticMask) {
                if (/[A-Za-z]/.test(value[i]))
                    result += value[i++];
                else
                    break;
            } else if (mask[j] === this.#AlphaNumericMask) {
                if (/[A-Za-z0-9]/.test(value[i]))
                    result += value[i++];
                else
                    break;
            } else if (mask[j] === this.#DayMask) {
                let indexDay = rawMask.indexOf(mask[j]);

                if (i === indexDay) {
                    if (/[0-3]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else if (i === indexDay + 1) {
                    if (value[indexDay] < "3")
                        if (/[0-9]/.test(value[i]))
                            result += value[i++];
                        else
                            break;
                    else if (/[0-1]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else
                    break;
            } else if (mask[j] === this.#MonthMask) {
                let indexMonth = rawMask.indexOf(mask[j]);

                if (i === indexMonth) {
                    if (/[0-1]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else if (i === indexMonth + 1) {
                    let indexDay = rawMask.indexOf(this.#DayMask),
                        day = Number(value.slice(indexDay, indexDay + 2)),
                        month = value.slice(indexMonth, indexMonth + 2);

                    if (day === 31) {
                        if ("01;03;05;07;08;10;12".indexOf(month) > -1)
                            result += value[i++];
                        else
                            break;
                    } else if (month === "02") {
                        if (day < 30)
                            result += value[i++];
                        else
                            break;
                    } else if (value[2] === "0")
                        if (/[1-9]/.test(value[i]))
                            result += value[i++];
                        else
                            break;
                    else if (/[0-2]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else
                    break;
            } else if (mask[j] === this.#YearMask) {
                let indexYear = rawMask.indexOf(mask[j]),
                    lengthYear = mask.split(mask[j]).length - 1,
                    indexLastDigit = indexYear + (lengthYear < 4 ? 1 : 3);

                if (i < indexLastDigit) {
                    if (/[0-9]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else if (i === indexLastDigit) {
                    let year = Number(value.slice(indexYear, indexLastDigit + 1));

                    if (year) {
                        let indexDay = rawMask.indexOf(this.#DayMask);

                        if (value.slice(indexDay, indexDay + 4) === "2902")
                            if ((year % 100 ? year % 4 : year % 400) === 0)
                                result += value[i++];
                            else
                                break;
                        else
                            result += value[i++];
                    } else
                        break;
                } else
                    break;
            } else if (mask[j] === this.#HoursMask) {
                let indexHours = rawMask.indexOf(mask[j]);

                if (i === indexHours) {
                    if (/[0-2]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else if (i === indexHours + 1) {
                    if (value[indexHours] < "2")
                        if (/[0-9]/.test(value[i]))
                            result += value[i++];
                        else break;
                    else if (/[0-3]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else
                    break;
            } else if (
                mask[j] === this.#MinutesMask ||
                mask[j] === this.#SecondsMask
            ) {
                let index = rawMask.indexOf(mask[j]);

                if (i === index || i === index + 2) {
                    if (/[0-5]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else if (i === index + 1 || i === index + 3) {
                    if (/[0-9]/.test(value[i]))
                        result += value[i++];
                    else
                        break;
                } else if (/[0-9]/.test(value[i]))
                    result += value[i++];
                else
                    break;
            } else
                result += mask[j];
        }

        return result;
    }

    static FormatDecimalInput(input, precision = 12, scale = 2) {
        let cursorPosition = input.selectionStart,
            endOfText = input.selectionStart === input.value.length;

        if (input.type !== "text") {
            input.type = "text";
            cursorPosition = input.value.length;
        }
        input.value = this.#FormatDecimal(input.value, precision, scale);
        input.selectionStart = input.selectionEnd = endOfText
            ? input.value.length
            : cursorPosition;
    }

    static #FormatDecimal(value, precision, scale) {
        let decimalswithcomma = 0,
            signal = "",
            mask = "",
            groups = Math.trunc((precision - scale) / 3),
            remaindigits = (precision - scale) % 3,
            floatingpoint = -1;

        if (groups) {
            mask = (this.#ThousandSeparator + "###").repeat(groups);
        }
        if (remaindigits)
            mask = "#".repeat(remaindigits) + mask;
        else
            mask = mask.slice(1);
        if (scale) {
            floatingpoint = mask.length;
            mask += this.#DecimalSeparator + "#".repeat(scale);
        }
        decimalswithcomma = floatingpoint === -1 ? 0 : mask.length - floatingpoint;
        if (value[0] === this.#MinusSignal) {
            signal = value.at(-1) === this.#MinusSignal ? "" : this.#MinusSignal;
            value = value.slice(1);
        } else
            signal = value.at(-1) === this.#MinusSignal ? this.#MinusSignal : "";
        value = value.slice(0, mask.length).split("").reverse().join("");
        mask = mask.split("").reverse().join("");

        let result = this.#FormatValue(value.replace(/\D/g, ""), mask);

        result = result.split("").reverse().join("");
        if (result.length > decimalswithcomma + 1)
            result = result.replace(/^0/g, "");
        else if (result.length < decimalswithcomma)
            result = "0," + "0".repeat(decimalswithcomma - result.length - 1) + result;
        if (this.ToFloat(result) > 0) {
            result = signal + result;
            this.ToFloat(result);
        } else
            result = "";

        return result;
    }

    static ToFloat(value) {
        value = value.trim();
        if (value === "")
            return 0;
        value = value.replaceAll(this.#ThousandSeparator, "").replace(this.#DecimalSeparator, ".").replace(/[^.0-9-]/g);

        return Number.parseFloat(value);
    }

    static ToDate(value) {
        value = value.replace(/\D/g, "");

        let day = Number(value.slice(0, 2)),
            month = Number(value.slice(2, 4)),
            year = Number(value.slice(4, 8));

        return new Date(year, month - 1, day);
    }

    static ToDateTime(value) {
        value = value.replace(/\D/g, "");

        let day = Number(value.slice(0, 2)),
            month = Number(value.slice(2, 4)),
            year = Number(value.slice(4, 8)),
            hours = Number(value.slice(8, 10)),
            minutes = Number(value.slice(10, 12)),
            seconds = Number(value.slice(12, 14));

        return new Date(year, month - 1, day, hours, minutes, seconds);
    }

    static CheckDigit(value, parameters = TMask.CheckDigitParameters) {
        let sum = 0,
            params = Object.assign(
                Object.assign({}, TMask.CheckDigitParameters),
                parameters
            ),
            testvalue = value.slice(0, params.Factors.length),
            fullValue = value === testvalue,
            digit;

        for (let i = testvalue.length; i > 0; --i) {
            let product = Number(testvalue[i - 1]) * params.Factors[i - 1];
            while (fullValue && product > 9) {
                let parcel1 = Math.trunc(product / 10),
                    parcel2 = product % 10;

                product = parcel1 + parcel2;
            }
            sum += product;
        }
        digit = sum % params.Module;
        if (fullValue)
            return !digit;
        if (digit && params.SubtractFromModule)
            digit = params.Module - digit;
        if (digit > 9) digit = params.DigitGreaterThanNine;

        return (`${testvalue}${digit}` === value.slice(0, params.Factors.length + 1));
    }
}