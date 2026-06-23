"use strict";

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import XLSX from "xlsx";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const assetsDir = path.resolve(__dirname, "..");
const sourcePath = path.join(assetsDir, "CRUDEX_Novissimo.xlsm");
const oldPath = path.join(assetsDir, "CRUDEX.xlsm");
const outputPath = path.join(assetsDir, "CRUDEX_Novissimo_Col_booleans.xlsm");

const BOOL_COLS = [
    "IsRequired",
    "IsPrimaryKey",
    "IsAutoincrement",
    "IsFilterable",
    "IsEditable",
    "IsGridable",
    "IsListable",
    "IsEncrypted",
    "IsInWords",
    "IsVirtual",
];

const isEmpty = (value) => value === "" || value === null || value === undefined;

const toBool = (value) => {
    if (value === true || value === false)
        return value;
    if (value === 1 || value === "1" || value === "TRUE" || value === "true")
        return true;
    if (value === 0 || value === "0" || value === "FALSE" || value === "false")
        return false;
    return null;
};

const setDefault = (row, key, value) => {
    if (!isEmpty(row[key]))
        return;
    row[key] = value;
};

function buildOldLookup() {
    const wb = XLSX.readFile(oldPath);
    const columns = XLSX.utils.sheet_to_json(wb.Sheets.Columns);
    const tables = XLSX.utils.sheet_to_json(wb.Sheets.Tables);
    const tableById = Object.fromEntries(tables.map((row) => [row["*Id"] ?? row.Id, row]));
    const lookup = new Map();

    for (const row of columns) {
        const table = tableById[row.TableId];
        if (!table)
            continue;
        lookup.set(`${table.Name}|${row.Name}`, row);
    }

    return lookup;
}

function applyOldRow(target, oldRow) {
    const map = [
        ["IsRequired", "IsRequired"],
        ["IsPrimaryKey", "IsPrimarykey"],
        ["IsAutoincrement", "IsAutoIncrement"],
        ["IsFilterable", "IsFilterable"],
        ["IsEditable", "IsEditable"],
        ["IsGridable", "IsGridable"],
        ["IsInWords", "IsInWords"],
        ["IsVirtual", "IsVirtual"],
    ];

    for (const [novKey, oldKey] of map) {
        const value = toBool(oldRow[oldKey]);
        if (value !== null)
            setDefault(target, novKey, value);
    }
}

function inferBooleans(row, tableName) {
    const name = String(row.Name ?? "");
    const category = String(row["#CategoryName"] ?? "").toLowerCase();
    const isFk = /Id$/i.test(name) && name !== "Id";
    const isAsk = name.startsWith("Ask");
    const isMetaBoolean = category === "boolean"
        || name === "IsActive"
        || /^Is[A-Z]/.test(name);

    if (name === "Id") {
        setDefault(row, "IsRequired", true);
        setDefault(row, "IsPrimaryKey", true);
        setDefault(row, "IsAutoincrement", true);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", false);
        setDefault(row, "IsGridable", false);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        setDefault(row, "IsVirtual", false);
        return;
    }

    setDefault(row, "IsPrimaryKey", false);
    setDefault(row, "IsAutoincrement", false);

    if (isAsk) {
        setDefault(row, "IsRequired", true);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (name === "Name" || name === "Symbol") {
        setDefault(row, "IsRequired", true);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", true);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (name === "Description") {
        setDefault(row, "IsRequired", false);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (isFk) {
        setDefault(row, "IsRequired", name !== "ParentEnvironmentId");
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (name === "Sequence") {
        setDefault(row, "IsRequired", true);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (isMetaBoolean) {
        setDefault(row, "IsRequired", false);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (category === "text" || category === "string") {
        const longText = /^(Default|Minimum|Maximum|ValidChars|ValidValues|ListValues|Mask|Modificators|Logo|Script|URL|Message|Action|Caption|Provider|PackageName|PackageVersion)$/i.test(name);
        setDefault(row, "IsRequired", false);
        setDefault(row, "IsFilterable", !longText);
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", !longText);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    if (category === "number") {
        setDefault(row, "IsRequired", false);
        setDefault(row, "IsFilterable", !/^(Minimum|Maximum)$/i.test(name));
        setDefault(row, "IsEditable", true);
        setDefault(row, "IsGridable", true);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        if (tableName === "Types" && /Minimum|Maximum/i.test(name))
            setDefault(row, "IsFilterable", false);
        return;
    }

    if (["Sessions", "Transactions", "Operations", "Permissions", "Properties", "Behaviors", "Urls", "Scripts"].includes(tableName)) {
        setDefault(row, "IsRequired", true);
        setDefault(row, "IsFilterable", true);
        setDefault(row, "IsEditable", false);
        setDefault(row, "IsGridable", false);
        setDefault(row, "IsListable", false);
        setDefault(row, "IsEncrypted", false);
        setDefault(row, "IsInWords", false);
        return;
    }

    setDefault(row, "IsRequired", false);
    setDefault(row, "IsFilterable", true);
    setDefault(row, "IsEditable", true);
    setDefault(row, "IsGridable", true);
    setDefault(row, "IsListable", false);
    setDefault(row, "IsEncrypted", false);
    setDefault(row, "IsInWords", false);
    setDefault(row, "IsVirtual", false);
}

function buildHeaderIndex(ws) {
    const range = XLSX.utils.decode_range(ws["!ref"] ?? "A1:A1");
    const index = new Map();
    for (let column = range.s.c; column <= range.e.c; column++) {
        const header = ws[XLSX.utils.encode_cell({ r: range.s.r, c: column })]?.v;
        if (header)
            index.set(String(header), column);
    }
    return { index, dataStartRow: range.s.r + 1 };
}

function writeBoolCell(ws, row, column, value) {
    const address = XLSX.utils.encode_cell({ r: row, c: column });
    ws[address] = { t: "b", v: Boolean(value) };
}

function main() {
    if (!fs.existsSync(sourcePath))
        throw new Error(`Fonte não encontrada: ${sourcePath}`);

    fs.copyFileSync(sourcePath, outputPath);

    const oldLookup = fs.existsSync(oldPath) ? buildOldLookup() : new Map();
    const sourceWb = XLSX.readFile(sourcePath, { cellDates: true });
    const outputWb = XLSX.readFile(outputPath, { cellFormula: true, cellDates: true });
    const tblRows = XLSX.utils.sheet_to_json(sourceWb.Sheets.Tbl);
    const tableById = Object.fromEntries(tblRows.map((row) => [row["*Id"] ?? row.Id, row]));
    const rows = XLSX.utils.sheet_to_json(sourceWb.Sheets.Col, { defval: "" });
    const ws = outputWb.Sheets.Col;
    const { index: headerIndex, dataStartRow } = buildHeaderIndex(ws);

    for (const colName of BOOL_COLS) {
        if (!headerIndex.has(colName))
            throw new Error(`Coluna ausente na aba Col: ${colName}`);
    }

    let patched = 0;
    for (let i = 0; i < rows.length; i++) {
        const row = { ...rows[i] };
        const table = tableById[row.TableId];
        const tableName = table?.Name ?? "";
        const oldRow = oldLookup.get(`${tableName}|${row.Name}`);
        if (oldRow)
            applyOldRow(row, oldRow);
        inferBooleans(row, tableName);

        const sheetRow = dataStartRow + i;
        for (const colName of BOOL_COLS) {
            const sourceValue = rows[i][colName];
            const value = isEmpty(sourceValue) ? row[colName] : sourceValue;
            if (isEmpty(value))
                continue;
            writeBoolCell(ws, sheetRow, headerIndex.get(colName), value);
            if (isEmpty(sourceValue))
                patched++;
        }
    }

    XLSX.writeFile(outputWb, outputPath, { bookType: "xlsm" });

    console.log(`Gerado: ${outputPath}`);
    console.log(`Linhas Col: ${rows.length}`);
    console.log(`Células booleanas preenchidas: ${patched}`);
    console.log("Fórmulas # preservadas — apenas colunas Is* foram alteradas.");
}

main();
