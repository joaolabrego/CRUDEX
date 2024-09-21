let Z = 18;

let camadas = [];

camadas["K"] = 0;
camadas["L"] = 0;
camadas["M"] = 0;
camadas["N"] = 0;
camadas["O"] = 0;
camadas["P"] = 0;
camadas["Q"] = 0;

let linusPauling = [];

linusPauling[0] = ["K", 2];
linusPauling[1] = ["L", 2];
linusPauling[2] = ["M", 2];
linusPauling[3] = ["L", 6];
linusPauling[4] = ["N", 2];
linusPauling[5] = ["M", 6];
linusPauling[6] = ["O", 2];
linusPauling[7] = ["N", 6];
linusPauling[8] = ["M", 10];
linusPauling[9] = ["O", 2];
linusPauling[10] = ["N", 6];
linusPauling[11] = ["M", 10];
linusPauling[12] = ["P", 2];
linusPauling[13] = ["O", 6];
linusPauling[14] = ["Q", 2];
linusPauling[15] = ["P", 6];
linusPauling[16] = ["O", 10];
linusPauling[17] = ["N", 14];
linusPauling[18] = ["Q", 6];
linusPauling[19] = ["P", 10];
linusPauling[20] = ["O", 14];


let total = 0;
for (let subnivel of linusPauling) {
    if (total + subnivel[1] > Z) {
        camadas[subnivel[0]] += (Z - total)
        break;
    }
    camadas[subnivel[0]] += subnivel[1]
    total += subnivel[1];
};
console.log(camadas)