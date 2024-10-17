"use strict"

export default class TMask {
    #Id = 0
	#Name = ""
	#Mask = ""

    constructor(rowMask){
        if (rowMask.ClassName !== "Mask")
            throw new Error("Argumento rowMask não é do tipo Mask.")
        this.#Id = rowMask.Id
        this.#Name = rowMask.Name
        this.#Mask = rowMask.Mask
    }
    set Id(value){
        this.#Id = value
    }
    get Id(){
        return this.#Id
    }
    set Name(value){
        this.#Name = value
    }
    get Name(){
        return this.#Name
    }
    set Mask(value){
        this.#Mask = value
    }
    get Mask(){
        return this.#Mask
    }
}