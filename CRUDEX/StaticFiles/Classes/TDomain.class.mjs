"use strict"

import TSystem from "./TSystem.class.mjs"
import TConfig from "./TConfig.class.mjs"
export default class TDomain {
	#Type = null
	constructor(rowDomain) {
		if (rowDomain.ClassName !== "Domain")
			throw new Error("Argumento rowDomain não é do tipo Domain.")
		TConfig.CreateProperties(rowDomain, this)
		this.#Type = TSystem.GetType(rowDomain.TypeId)
	}
	get Type() {
		return this.#Type
	}
}
