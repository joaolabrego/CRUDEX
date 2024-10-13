"use strict"

import TSystem from "./TSystem.class.mjs"

export default class TType {
    #Id = 0
    #CategoryId = 0
    #Name = ""
    #MaxLength = null
    #Minimum = ""
    #Maximum = ""
    #AskLength = false
    #AskDecimals = false
    #AskPrimarykey = false
    #AskAutoincrement = false
    #AskFilterable = false
    #AskGridable = false
    #AskCodification = false
    #AskFormula = false
    #AllowMaxLength = false
    #IsActive = false

    #Category = null

    constructor(rowType) {
        if (rowType.ClassName !== "Type")
            throw new Error("Argumento rowType não é do tipo Type.")
        this.#Id = rowType.Id
        this.#CategoryId = rowType.CategoryId
        this.#Name = rowType.Name
        this.#MaxLength = rowType.MaxLength 
        this.#Minimum = rowType.Minimum
        this.#Maximum = rowType.Maximum
        this.#AskLength = rowType.AskLength
        this.#AskDecimals = rowType.AskDecimals
        this.#AskPrimarykey = rowType.AskPrimarykey
        this.#AskAutoincrement = rowType.AskAutoincrement
        this.#AskFilterable = rowType.AskFilterable
        this.#AskGridable = rowType.AskGridable
        this.#AskCodification = rowType.AskCodification
        this.#AskFormula = rowType.AskFormula
        this.#AllowMaxLength = rowType.AllowMaxLength
        this.#IsActive = rowType.IsActive

        this.#Category = TSystem.GetCategory(this.#CategoryId)
    }
    get Id() {
        return this.#Id
    }
    set Id(value) {
        this.#Id = value
    }
    get CategoryId() {
        return this.#CategoryId
    }
    set CategoryId(value) {
        this.#CategoryId = value
    }
    get Name() {
        return this.#Name
    }
    set Name(value) {
        this.#Name = value
    }
    get MaxLength() {
        return this.#MaxLength
    }
    set MaxLength(value) {
        this.#MaxLength = value
    }
    set Minimum(value) {
        this.#Minimum = value
    }
    get Minimum() {
        return this.#Minimum
    }
    set Maximum(value) {
        this.#Maximum = value
    }
    get Maximum() {
        return this.#Maximum
    }
    get AskLength() {
        return this.#AskLength
    }
    set AskLength(value) {
        this.#AskLength = value
    }
    get AskDecimals() {
        return this.#AskDecimals
    }
    set AskDecimals(value) {
        this.#AskDecimals = value
    }
    get AskPrimarykey() {
        return this.#AskPrimarykey
    }
    set AskPrimarykey(value) {
        this.#AskPrimarykey = value
    }
    get AskAutoincrement() {
        return this.#AskAutoincrement
    }
    set AskAutoincrement(value) {
        this.#AskAutoincrement = value
    }
    get AskFilterable() {
        return this.#AskFilterable
    }
    set AskFilterable(value) {
        this.#AskFilterable = value
    }
    get AskFilterable() {
        return this.#AskFilterable
    }
    set AskFilterable(value) {
        this.#AskFilterable = value
    }
    get AskGridable() {
        return this.#AskGridable
    }
    set AskGridable(value) {
        this.#AskGridable = value
    }
    get AskCodification() {
        return this.#AskCodification
    }
    set AskCodification(value) {
        this.#AskCodification = value
    }
    get AskFormula() {
        return this.#AskFormula
    }
    set AskFormula(value) {
        this.#AskFormula = value
    }
    get AllowMaxLength() {
        return this.#AllowMaxLength
    }
    set AllowMaxLength(value) {
        this.#AllowMaxLength = value
    }
    get IsActive() {
        return this.#IsActive
    }
    get Category(){
        return this.#Category
    }
}