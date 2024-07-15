"use strict"

export default class TNumberInWords {
	static ToWords(value, CurrencyInSingular = "Real", CurrencyInPlural = "Reais", CentsInSingular = "Centavo", CentsInPlural = "Centavos") {
		let minus = value < 0 ? "menos " : string.Empty
        let unidades = [string.Empty, "Um", "Dois", "Três", "Quatro", "Cinco", "Seis", "Sete", "Oito", "Nove", "Dez", "Onze", "Doze", "Treze",
            "Quatorze", "Quinze", "Dezesseis", "Dezessete", "Dezoito", "Dezenove"]
        let dezenas = [string.Empty, string.Empty, "Vinte", "Trinta", "Quarenta", "Cinqüenta", "Sessenta", "Setenta", "Oitenta", "Noventa"]
        let centenas = [string.Empty, "Cento", "Duzentos", "Trezentos", "Quatrocentos", "Quinhentos", "Seiscentos", "Setecentos", "Oitocentos", "Novecentos"]
        let potenciasSingular = [string.Empty, " Mil", " Milhão", " Bilhão", " Trilhão", " Quatrilhão"]
        let potenciasPlural = [string.Empty, " Mil", " Milhões", " Bilhões", " Trilhões", " Quatrilhões"]

        value = Math.abs(Math.trunc(value).toString().padStart(18, "0"))
        for (let position = 0; position < value.length; position += 3){
            let partial = parseInt(value.slice(position, 3))

            if (partial){
                
            }
            


        }


	}
}