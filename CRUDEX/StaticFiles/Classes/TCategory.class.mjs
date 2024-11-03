"use strict"

import TConfig from "./TConfig.class.mjs"
export default class TCategory {
	constructor(rowCategory) {
		if (rowCategory.ClassName !== "Category")
			throw new Error("Argumento rowCategory não é do tipo Category.")
		TConfig.CreateProperties(rowCategory, this)
	}
}