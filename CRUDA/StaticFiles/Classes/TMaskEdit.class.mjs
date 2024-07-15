"use strict"

import TConfig from "./TConfig.class.mjs"

export default class TMaskEdit {
    static #numericMask = "#"
    static #alphabeticMask = "@"
    static #alphanumericMask = "*"
    static #dayMask = "d"
    static #monthMask = "M"
    static #yearMask = "y"
    static #hoursMask = "h"
    static #minutesMask = "m"
    static #secondsMask = "s"
    static #allMasks = this.#numericMask +
        this.#alphabeticMask +
        this.#alphanumericMask +
        this.#dayMask +
        this.#monthMask +
        this.#yearMask +
        this.#hoursMask +
        this.#minutesMask +
        this.#secondsMask

    static formatValueInput(input, masks, options = string.Empty, validatorFunction = null) {
        let cursorPosition = input.selectionStart,
            endOfText = input.selectionStart === input.value.length

        input.value = this.formatValue(input.value, masks, options)
        input.style.backgroundColor = validatorFunction && !validatorFunction() ? "red" : string.Empty
        input.selectionStart = input.selectionEnd = endOfText ? input.value.length : cursorPosition
    }

    static formatValue(value, masks, options = string.Empty) {
        let result = string.Empty,
            mask = string.Empty

        if (Array.isArray(masks))
            for (let i = 0; i < masks.length; i++) {
                mask = String(masks[i])
                if (mask.length >= value.length)
                    break
            }
        else
            mask = masks

        let rawMask = mask.replace(new RegExp(`[^${this.#allMasks}]`, "g"), string.Empty)

        value = value.replace(/[^0-9A-Za-z]/g, string.Empty)
        if (options.indexOf("upper") > -1)
            value = value.toUpperCase()
        else if (options.indexOf("lower") > -1)
            value = value.toLowerCase()
        for (let i = 0, j = 0; i < value.length && j < mask.length; j++) {
            if (mask[j] === this.#numericMask) {
                if (/[0-9]/.test(value[i]))
                    result += value[i++]
                else
                    break
            }
            else if (mask[j] === this.#alphabeticMask) {
                if (/[A-Za-z]/.test(value[i]))
                    result += value[i++]
                else
                    break
            }
            else if (mask[j] === this.#alphanumericMask) {
                if (/[A-Za-z0-9]/.test(value[i]))
                    result += value[i++]
                else
                    break
            }
            else if (mask[j] === this.#dayMask) {
                let indexDay = rawMask.indexOf(mask[j])

                if (i === indexDay) {
                    if (/[0-3]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else if (i === indexDay + 1) {
                    if (value[indexDay] < "3")
                        if (/[0-9]/.test(value[i]))
                            result += value[i++]
                        else
                            break
                    else if (/[0-1]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else
                    break
            }
            else if (mask[j] === this.#monthMask) {
                let indexMonth = rawMask.indexOf(mask[j])

                if (i === indexMonth) {
                    if (/[0-1]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else if (i === indexMonth + 1) {
                    let indexDay = rawMask.indexOf(this.#dayMask),
                        day = Number(value.slice(indexDay, indexDay + 2)),
                        month = value.slice(indexMonth, indexMonth + 2)

                    if (day === 31) {
                        if ("01;03;05;07;08;10;12".indexOf(month) > -1)
                            result += value[i++]
                        else
                            break
                    }
                    else if (month === "02") {
                        if (day < 30)
                            result += value[i++]
                        else
                            break
                    }
                    else if (value[indexMonth] === "0")
                        if (/[1-9]/.test(value[i]))
                            result += value[i++]
                        else
                            break
                    else if (/[0-2]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else
                    break
            }
            else if (mask[j] === this.#yearMask) {
                let indexYear = rawMask.indexOf(mask[j]),
                    lengthYear = mask.split(mask[j]).length - 1,
                    indexLastDigit = indexYear + (lengthYear < 4 ? 1 : 3)

                if (i < indexLastDigit) {
                    if (/[0-9]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else if (i === indexLastDigit) {
                    let year = Number(value.slice(indexYear, indexLastDigit + 1))

                    if (year) {
                        let indexDay = rawMask.indexOf(this.#dayMask)

                        if (value.slice(indexDay, indexDay + 4) === "2902")
                            if ((year % 100 ? year % 4 : year % 400) === 0)
                                result += value[i++]
                            else
                                break
                        else
                            result += value[i++]
                    }
                    else
                        break
                }
                else
                    break
            }
            else if (mask[j] === this.#hoursMask) {
                let indexHours = rawMask.indexOf(mask[j])

                if (i === indexHours) {
                    if (/[0-2]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else if (i === indexHours + 1) {
                    if (value[indexHours] < "2")
                        if (/[0-9]/.test(value[i]))
                            result += value[i++]
                        else
                            break
                    else if (/[0-3]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else
                    break
            }
            else if (mask[j] === this.#minutesMask || mask[j] === this.#secondsMask) {
                let index = rawMask.indexOf(mask[j])

                if (i === index || i === index + 2) {
                    if (/[0-5]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else if (i === index + 1 || i === index + 3) {
                    if (/[0-9]/.test(value[i]))
                        result += value[i++]
                    else
                        break
                }
                else if (/[0-9]/.test(value[i]))
                    result += value[i++]
                else
                    break
            }
            else
                result += mask[j]
        }

        return result
    }

    static decimalMask(precision, scale) {
        let length = precision - scale,
            groups = Math.trunc(length / 3),
            remaindigits = length % 3,
            mask = string.Empty

        if (groups) {
            mask = "###" + (TConfig.ThousandSeparator + "###").repeat(groups - 1)
        }
        if (remaindigits)
            mask = "#".repeat(remaindigits) + mask
        if (scale)
            mask += TConfig.decimalSeparator + "#".repeat(scale)

        return mask
    }

    static formatDecimalInput(input, precision = 12, scale = 2) {
        let cursorPosition = input.selectionStart,
            endOfText = input.selectionStart === input.value.length

        input.value = this.formatDecimal(input.value, precision, scale)
        input.selectionStart = input.selectionEnd = endOfText ? input.value.length : cursorPosition
    }

    static formatDecimal(value, precision, scale) {
        let decimalswithcomma = 0,
            signal = string.Empty,
            mask = string.Empty,
            groups = Math.trunc((precision - scale) / 3),
            remaindigits = (precision - scale) % 3,
            floatingpoint = -1

        if (groups) {
            mask = (TConfig.thousandSeparator + "###").repeat(groups)
        }
        if (remaindigits)
            mask = "#".repeat(remaindigits) + mask
        else
            mask = mask.slice(1)
        if (scale) {
            floatingpoint = mask.length
            mask += TConfig.decimalSeparator + "#".repeat(scale)
        }
        decimalswithcomma = floatingpoint === -1 ? 0 : mask.length - floatingpoint
        if (value[0] === TConfig.minusSignal) {
            signal = value.at(-1) === TConfig.minusSignal ? string.Empty : TConfig.minusSignal
            value = value.slice(1)
        }
        else
            signal = value.at(-1) === TConfig.minusSignal ? TConfig.minusSignal : string.Empty
        value = value.slice(0, mask.length).split(string.Empty).reverse().join(string.Empty)
        mask = mask.split(string.Empty).reverse().join(string.Empty)

        let result = this.formatValue(value.replace(/\D/g, string.Empty), mask)

        result = result.split(string.Empty).reverse().join(string.Empty)
        if (result.length > decimalswithcomma + 1)
            result = result.replace(/^0/g, string.Empty)
        else if (result.length < decimalswithcomma)
            result = "0," + "0".repeat(decimalswithcomma - result.length - 1) + result
        if (this.toFloat(result) > 0) {
            result = signal + result
            this.toFloat(result)
        }
        else
            result = string.Empty

        return result
    }

    static toFloat(value) {
        value = value.trim()
        if (value === string.Empty)
            return 0
        value = value.replaceAll(TConfig.ThousandSeparator, string.Empty)
            .replace(TConfig.DecimalSeparator, ".")
            .replace(/[^.0-9-]/g)

        return Number.parseFloat(value)
    }

    static toDate(value) {
        value = value.replace(/\D/g, string.Empty)

        let day = Number(value.slice(0, 2)),
            month = Number(value.slice(2, 4)),
            year = Number(value.slice(4, 8))

        return new Date(year, month - 1, day)
    }

    static toDateTime(value) {
        value = value.replace(/\D/g, string.Empty)

        let day = Number(value.slice(0, 2)),
            month = Number(value.slice(2, 4)),
            year = Number(value.slice(4, 8)),
            hours = Number(value.slice(8, 10)),
            minutes = Number(value.slice(10, 12)),
            seconds = Number(value.slice(12, 14))

        return new Date(year, month - 1, day, hours, minutes, seconds)
    }

    static toTime(value) {
        value = value.replace(/\D/g, string.Empty)

        let hours = Number(value.slice(0, 2)),
            minutes = Number(value.slice(2, 4)),
            seconds = Number(value.slice(4, 2))

        return new Date(1, 0, 1, hours, minutes, seconds)
    }

    static checkDigitParameters = {
        module: 11,
        factors: [],
        digitGreaterThanNine: "0",
        subtractDigitFromModule: false,
    }

    static checkDigit(value, parameters = TMask.checkDigitParameters) {
        let sum = 0,
            params = Object.assign(Object.assign({}, TMask.checkDigitParameters), parameters),
            testvalue = value.slice(0, params.factors.length),
            fullValue = value === testvalue,
            digit

        for (let i = testvalue.length; i > 0; --i) {
            let product = Number(testvalue[i - 1]) * params.factors[i - 1]
            while (fullValue && product > 9) {
                let parcel1 = Math.trunc(product / 10),
                    parcel2 = product % 10

                product = parcel1 + parcel2
            }
            sum += product
        }
        digit = sum % params.module
        if (fullValue)
            return !digit
        if (digit && params.subtractDigitFromModule)
            digit = params.module - digit
        if (digit > 9)
            digit = params.digitGreaterThanNine

        return `${testvalue}${digit}` === value.slice(0, params.factors.length + 1)
    }

    static validateCpfCnpj(input) {
        let value = input.value.replace(/[^0-9]/g, string.Empty)

        if (value.length === 8)
            return true
        else if (value.length === 11)
            return this.checkDigit(value, {
                module: 11,
                factors: [1, 2, 3, 4, 5, 6, 7, 8, 9]
            }) && this.checkDigit(value, {
                module: 11,
                factors: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
            })
        else if (value.length === 14)
            return (this.checkDigit(value, {
                module: 11,
                factors: [6, 7, 8, 9, 2, 3, 4, 5, 6, 7, 8, 9]
            })) && (this.checkDigit(value, {
                module: 11,
                factors: [5, 6, 7, 8, 9, 2, 3, 4, 5, 6, 7, 8, 9]
            }))
        else if (value.length)
            return false

        return true
    }

    static validateStateRegistration(input) {
        let value = input.value.replace(/[^0-9]/g, string.Empty)

        if (value.length === 12)
            return this.checkDigit(value, {
                module: 11,
                factors: [1, 3, 4, 5, 6, 7, 8, 10]
            }) && this.checkDigit(value, {
                module: 11,
                factors: [3, 2, 10, 9, 8, 7, 6, 5, 4, 3, 2]
            })
        else if (value.length)
            return false

        return true
    }

    static validateRG(input) {
        let value = input.value.replace(/[^0-9A-Z]/g, string.Empty)

        if (value.length === 9)
            return this.checkDigit(value, {
                module: 11,
                factors: [2, 3, 4, 5, 6, 7, 8, 9],
                digitGreaterThanNine: "X",
                subtractDigitFromModule: true
            })
        else if (value.length)
            return false

        return true
    }

    static validateCreditCard(input) {
        let value = input.value.replace(/[^0-9]/g, string.Empty)

        if (value.length === 16)
            return this.checkDigit(value, {
                module: 10,
                factors: [2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1]
            })
        else if (value.length)
            return false

        return true
    }
}