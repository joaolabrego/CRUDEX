// mascaras.js

// Regex base para CPF
const regexCPF_Total = /^\d{3}\.\d{3}\.\d{3}-\d{2}$/;

// Regex parcial POSICIONAL — só aceita separadores nas posições corretas
const regexCPF_Parcial = /^\d{0,3}(\.\d{0,3}(\.\d{0,3}(-\d{0,2})?)?)?$/;

const testes = [
    "A", "12", "123", "123.", "123-4", "123.45", "123.456",
    "123.456.7", "123.456.78", "123.456.789-", "123.456.789-0", "123.456.789-09"
];

for (const valor of testes) {
    const parcial = regexCPF_Parcial.test(valor);
    const total = regexCPF_Total.test(valor);
    console.log(`${valor.padEnd(15)} → parcial: ${String(parcial).padEnd(5)} | total: ${total}`);
}
