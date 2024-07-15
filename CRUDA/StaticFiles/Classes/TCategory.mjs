export default class TCategory {
	#Id = 0
	#Name = string.Empty
	#HtmlInputType = string.Empty
	#HtmlInputAlign = string.Empty
	#AskEncrypted = false
	#AskMask = false
	#AskListable = false
	#AskDefault = false
	#AskMinimum = false
	#AskMaximum = false

	constructor(rowCategory) {
		if (rowCategory.ClassName !== "RecordCategory")
			throw new Error("Argumento rowCategory não é do tipo Category.")
		this.#Id = rowCategory.Id
		this.#Name = rowCategory.Name
		this.#HtmlInputType = rowCategory.HtmlInputType
		this.#HtmlInputAlign = rowCategory.HtmlInputAlign
		this.#AskEncrypted = rowCategory.AskEncrypted
		this.#AskMask = rowCategory.AskMask
		this.#AskListable = rowCategory.AskListable
		this.#AskDefault = rowCategory.AskDefault
		this.#AskMinimum = rowCategory.AskMinimum
		this.#AskMaximum = rowCategory.AskMaximum
	}

	get Id(){
		return this.#Id
	}
	get Name(){
		return this.#Name
	}
	get HtmlInputType(){
		return this.#HtmlInputType
	}
	get HtmlInputAlign(){
		return this.#HtmlInputAlign
	}
	get AskEncrypted(){
		return this.#AskEncrypted
	}
	get AskMask(){
		return this.#AskMask
	}
	get AskListable(){
		return this.#AskListable
	}
	get AskDefault(){
		return this.#AskDefault
	}
	get AskMinimum(){
		return this.#AskMinimum
	}
	get AskMaximum(){
		return this.#AskMaximum
	}
}