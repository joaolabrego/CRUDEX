export default class TCrypto {
    #CryptoKey = ""
    static #CRYPTOPREFIX = "encrypted"
    static #CHARSET = "0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz+*&%$#!?.:=@<>,;/[]{}()"
    static #DEFAULT_LENGTH = 100
    static #DELIMITER_VALUE = String.fromCharCode(5);

    constructor(cryptoKey = TCrypto.GenerateCryptokey()) {
        this.#CryptoKey = cryptoKey
    }
    static #GetChar() {
        let position = Math.trunc(Math.random() * this.#CHARSET.length)

        return this.#CHARSET.slice(position, position + 1)
    }
    static GenerateCryptokey(length = this.#DEFAULT_LENGTH) {
        let result = ""

        for (let i = 0; i < length; i++)
            result += this.#GetChar()

        return result
    }
    IsEncrypted(value) {
        return value.length >= TCrypto.#CRYPTOPREFIX.length && value.slice(0, TCrypto.#CRYPTOPREFIX.length) === TCrypto.#CRYPTOPREFIX
    }
    Encrypt(value, keys = this.#CryptoKey) {
        const SPACE = " ".charCodeAt(0)
        let factor = -1,
            prefix = TCrypto.#CRYPTOPREFIX,
            result = "",
            encrypted = this.IsEncrypted(value)

        if (encrypted) {
            factor = 1
            value = value.slice(prefix.length)
            prefix = ""
        }
        else {
            if (value.includes(TCrypto.#DELIMITER_VALUE))
                throw new Error("Valor não pode conter delimitador de valores.")
            value += TCrypto.#DELIMITER_VALUE;
            for (let i = value.length; i <= TCrypto.#DEFAULT_LENGTH; i++)
                value += TCrypto.#GetChar()
        }
        for (let i = 0; i < value.length; i++) {
            let ascii = value.charCodeAt(i)

            if (ascii >= SPACE) { // mantém controles intactos.
                ascii -= SPACE // desconsidera controles (caracteres de 1 a 31).
                ascii += keys.charCodeAt(i % keys.length) * factor
                ascii %= 256 - SPACE // 256 - 32 caracteres desconsiderados.
                if (ascii < 0)
                    ascii += (256 - SPACE)
                ascii += SPACE // reajusta para caracteres normais.
            }
            result += String.fromCharCode(ascii)
        }
        if (encrypted)
            result = result.slice(0, result.indexOf(TCrypto.#DELIMITER_VALUE))

        return prefix + result
    }
    get CryptoKey() {
        return this.#CryptoKey
    }
}