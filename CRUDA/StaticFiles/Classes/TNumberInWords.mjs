"use strict"

export default class TNumberInWords {
	static ToWords(value, CurrencyInSingular = "Real", CurrencyInPlural = "Reais", CentsInSingular = "Centavo", CentsInPlural = "Centavos") {
		let minus = value < 0 ? "menos " : ""
        let unidades = ["", "Um", "Dois", "Três", "Quatro", "Cinco", "Seis", "Sete", "Oito", "Nove", "Dez", "Onze", "Doze", "Treze",
            "Quatorze", "Quinze", "Dezesseis", "Dezessete", "Dezoito", "Dezenove"]
        let dezenas = ["", "", "Vinte", "Trinta", "Quarenta", "Cinqüenta", "Sessenta", "Setenta", "Oitenta", "Noventa"]
        let centenas = ["", "Cento", "Duzentos", "Trezentos", "Quatrocentos", "Quinhentos", "Seiscentos", "Setecentos", "Oitocentos", "Novecentos"]
        let potenciasSingular = ["", " Mil", " Milhão", " Bilhão", " Trilhão", " Quatrilhão"]
        let potenciasPlural = ["", " Mil", " Milhões", " Bilhões", " Trilhões", " Quatrilhões"]

        value = Math.abs(Math.trunc(value).toString().padStart(18, "0"))
        for (let position = 0; position < value.length; position += 3){
            let partial = parseInt(value.slice(position, 3))

            if (partial){
                
            }
            


        }


	}
}