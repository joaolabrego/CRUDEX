"use strict"

import TSystem from "./TSystem.class.mjs"

export default class TDomain {
	#Id = 0
	#TypeId = 0
	#MaskId = ""
	#Name = ""
	#Length = 0
	#Decimals = 0
	#ValidValues = ""
	#Default = ""
	#Minimum = ""
	#Maximum = ""
	#Codification = ""

	#Type = null

	constructor(rowDomain) {
		if (rowDomain.ClassName !== "Domain")
			throw new Error("Argumento rowDomain não é do tipo Domain.")
		this.#Id = rowDomain.Id
		this.#TypeId = rowDomain.TypeId
		this.#MaskId = rowDomain.MaskId
		this.#Name = rowDomain.Name
		this.#Length = rowDomain.Length
		this.#Decimals = rowDomain.Decimals
		this.#ValidValues = rowDomain.ValidValues
		this.#Default = rowDomain.Default
		this.#Minimum = rowDomain.Minimum
		this.#Maximum = rowDomain.Maximum
		this.#Codification = rowDomain.Codification

		this.#Type = TSystem.GetType(rowDomain.TypeId)
	}
	get Id() {
		return this.#Id
	}
	get TypeId() {
		return this.#TypeId
	}
	get MaskId(){
		return this.#MaskId
	}
	get Name() {
		return this.#Name
	}
	get Length() {
		return this.#Length
	}
	get Decimals() {
		return this.#Decimals
	}
	get ValidValues(){
		return this.#ValidValues
	}
	get Default() {
		return this.#Default
	}
	get Minimum() {
		return this.#Minimum
	}
	get Maximum() {
		return this.#Maximum
	}
	get Type() {
		return this.#Type
	}
	get Codification(){
		return this.#Codification
	}
}
