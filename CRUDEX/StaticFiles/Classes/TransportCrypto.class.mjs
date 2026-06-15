"use strict";

const AES_KEY_SIZE = 32;
const IV_SIZE = 12;
const TAG_SIZE = 16;
const ENVELOPE_VERSION = 1;

export default class TransportCrypto {
    static #serverPublicKey = null;
    static #clientPrivateKey = null;
    static #clientPublicKeySpki = null;
    static #sessionKey = null;
    static #sessionKeyBytes = null;
    static #sessionKeyB64 = null;

    static get SessionKeyB64() {
        return this.#sessionKeyB64;
    }

    static get ClientRsaPublicKeySpki() {
        return this.#clientPublicKeySpki;
    }

    static async Initialize(serverPublicKeySpki) {
        if (!serverPublicKeySpki)
            throw new Error("Chave pública RSA do servidor ausente no config.");
        const serverSpki = this.#base64ToBytes(serverPublicKeySpki);
        this.#serverPublicKey = await crypto.subtle.importKey(
            "spki",
            serverSpki,
            { name: "RSA-OAEP", hash: "SHA-256" },
            false,
            ["encrypt"],
        );
        const keyPair = await crypto.subtle.generateKey(
            {
                name: "RSA-OAEP",
                modulusLength: 2048,
                publicExponent: new Uint8Array([1, 0, 1]),
                hash: "SHA-256",
            },
            true,
            ["encrypt", "decrypt"],
        );
        this.#clientPrivateKey = keyPair.privateKey;
        const clientSpki = await crypto.subtle.exportKey("spki", keyPair.publicKey);
        this.#clientPublicKeySpki = this.#bytesToBase64(new Uint8Array(clientSpki));
    }

    static async beginSession() {
        const key = crypto.getRandomValues(new Uint8Array(AES_KEY_SIZE));
        this.#sessionKeyBytes = key;
        this.#sessionKey = await crypto.subtle.importKey(
            "raw",
            key,
            { name: "AES-GCM", length: 256 },
            false,
            ["encrypt", "decrypt"],
        );
        this.#sessionKeyB64 = this.#bytesToBase64(key);
    }

    static clearSession() {
        this.#sessionKey = null;
        this.#sessionKeyBytes = null;
        this.#sessionKeyB64 = null;
    }

    static isEncryptedEnvelope(value) {
        if (typeof value !== "string" || !value.trim().startsWith("{"))
            return false;
        try {
            const envelope = JSON.parse(value);
            return envelope?.v === ENVELOPE_VERSION && typeof envelope.d === "string";
        } catch {
            return false;
        }
    }

    static async encrypt(plaintext) {
        const aesKey = await this.#requireSessionKey();
        const iv = crypto.getRandomValues(new Uint8Array(IV_SIZE));
        const plainBytes = new TextEncoder().encode(plaintext);
        const cipher = await crypto.subtle.encrypt(
            { name: "AES-GCM", iv, tagLength: TAG_SIZE * 8 },
            aesKey,
            plainBytes,
        );
        const cipherBytes = new Uint8Array(cipher);
        const tag = cipherBytes.slice(cipherBytes.length - TAG_SIZE);
        const data = cipherBytes.slice(0, cipherBytes.length - TAG_SIZE);
        const ek = await this.#wrapAesForServer(this.#sessionKeyBytes ?? await this.#exportSessionKeyBytes());
        return JSON.stringify({
            v: ENVELOPE_VERSION,
            ek,
            iv: this.#bytesToBase64(iv),
            t: this.#bytesToBase64(tag),
            d: this.#bytesToBase64(data),
        });
    }

    static async decrypt(envelopeJson) {
        const envelope = typeof envelopeJson === "string"
            ? JSON.parse(envelopeJson)
            : envelopeJson;
        if (envelope?.v !== ENVELOPE_VERSION)
            throw new Error("Versão de envelope de criptografia não suportada.");
        if (!envelope.ek)
            throw new Error("Campo ek é requerido no envelope criptografado.");
        const aesKey = await this.#unwrapAesFromServer(envelope.ek);
        const iv = this.#base64ToBytes(envelope.iv);
        const tag = this.#base64ToBytes(envelope.t);
        const data = this.#base64ToBytes(envelope.d);
        const cipher = new Uint8Array(data.length + tag.length);
        cipher.set(data);
        cipher.set(tag, data.length);
        const plain = await crypto.subtle.decrypt(
            { name: "AES-GCM", iv, tagLength: TAG_SIZE * 8 },
            aesKey,
            cipher,
        );
        return new TextDecoder().decode(plain);
    }

    static async #requireSessionKey() {
        if (!this.#sessionKey)
            throw new Error("Chave de sessão ausente.");
        return this.#sessionKey;
    }

    static async #exportSessionKeyBytes() {
        if (this.#sessionKeyBytes)
            return this.#sessionKeyBytes;
        const raw = await crypto.subtle.exportKey("raw", await this.#requireSessionKey());
        return new Uint8Array(raw);
    }

    static async #wrapAesForServer(aesKeyBytes) {
        if (!this.#serverPublicKey)
            throw new Error("Chave pública RSA do servidor não inicializada.");
        const wrapped = await crypto.subtle.encrypt(
            { name: "RSA-OAEP" },
            this.#serverPublicKey,
            aesKeyBytes,
        );
        return this.#bytesToBase64(new Uint8Array(wrapped));
    }

    static async #unwrapAesFromServer(ekBase64) {
        if (!this.#clientPrivateKey)
            throw new Error("Chave privada RSA do cliente não inicializada.");
        const wrapped = this.#base64ToBytes(ekBase64);
        const raw = await crypto.subtle.decrypt(
            { name: "RSA-OAEP" },
            this.#clientPrivateKey,
            wrapped,
        );
        return crypto.subtle.importKey(
            "raw",
            raw,
            { name: "AES-GCM", length: 256 },
            false,
            ["encrypt", "decrypt"],
        );
    }

    static #bytesToBase64(bytes) {
        let binary = "";
        for (let i = 0; i < bytes.length; i++)
            binary += String.fromCharCode(bytes[i]);
        return btoa(binary);
    }

    static #base64ToBytes(base64) {
        const binary = atob(base64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++)
            bytes[i] = binary.charCodeAt(i);
        return bytes;
    }
}
