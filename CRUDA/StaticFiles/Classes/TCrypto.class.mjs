export default class TCrypto {
    #CryptoKey = string.Empty
    static #CRYPTOPREFIX = "encrypted"
    static #CHARSET = "0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz+*&%$#!?.:=@<>,;/[]{}()"
    static #DEFAULT_LENGTH = 100

    constructor(cryptoKey = TCrypto.#GenerateCryptokey()) {
        this.#CryptoKey = cryptoKey
    }
    static #GetChar() {
        let position = Math.trunc(Math.random() * this.#CHARSET.length)

        return this.#CHARSET.slice(position, position + 1)
    }
    static #GenerateCryptokey(length = this.#DEFAULT_LENGTH) {
        let result = string.Empty

        for (let i = 0; i < length; i++) {
            result += this.#GetChar()
        }

        return result
    }
    IsEncrypted(value) {
        return value.length >= TCrypto.#CRYPTOPREFIX.length && value.slice(0, TCrypto.#CRYPTOPREFIX.length) === TCrypto.#CRYPTOPREFIX
    }
    Encrypt(value, keys = this.#CryptoKey) {
        const SPACE = " ".charCodeAt(0)
        let factor = -1,
            prefix = TCrypto.#CRYPTOPREFIX,
            result = string.Empty,
            encrypted = this.IsEncrypted(value)

        if (encrypted) {
            factor = 1
            value = value.slice(prefix.length)
            prefix = string.Empty
        }
        else {
            for (let i = 0; i < value.length; i++) {
                if (value[i] === "#")
                    throw new Error("Encrypt: Valor não pode conter #.")
            }
            value += "#";
            for (let i = value.length; i <= TCrypto.#DEFAULT_LENGTH; i++) {
                value += TCrypto.#GetChar()
            }
            value = btoa(value)
        }
        for (let i = 0; i < value.length; i++) {
            let ascii = value.charCodeAt(i)

            if (ascii >= SPACE) { // mantém controles intactos.
                ascii -= SPACE // desconsidera controles (caracteres de 1 a 31).
                ascii += keys.charCodeAt(i % keys.length) * factor
                ascii %= (256 - SPACE) // 256 - 32 caracteres desconsiderados.
                if (ascii < 0)
                    ascii += (256 - SPACE)
                ascii += SPACE // reajusta para caracteres normais.
            }
            result += String.fromCharCode(ascii)
        }
        if (encrypted) {
            result = atob(result)
            result = result.slice(0, result.indexOf("#"))
        }

        return prefix + result
    }
    get CryptoKey() {
        return this.#CryptoKey
    }
}