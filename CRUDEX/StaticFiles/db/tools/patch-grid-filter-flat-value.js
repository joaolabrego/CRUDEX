"use strict";

const fs = require("fs");
const path = require("path");

const scriptPath = path.join(__dirname, "..", "SCRIPT-CRUDEX.sql");
let content = fs.readFileSync(scriptPath, "utf8");

function insertFlatValuePath(text) {
    return text.replace(
        /^(\s+)IF (@G_(\w+)_v IS NULL SELECT @G_\3_v = TRY_CAST\(JSON_VALUE\(@RecordFilterGrid, '\$\.Fixed\.\3\.value'\) AS ([^)]+)\)\r?\n)(?!\1IF @G_\3_v IS NULL SELECT @G_\3_v = TRY_CAST\(JSON_VALUE\(@RecordFilterGrid, '\$\.(\3)\.value')/gm,
        (_m, head, _full, col, type, indent) =>
            `${head}${indent}IF @G_${col}_v IS NULL SELECT @G_${col}_v = TRY_CAST(JSON_VALUE(@RecordFilterGrid, '$.${col}.value') AS ${type})\r\n`,
    ).replace(
        /^(\s+)IF (@G_(\w+)_vals IS NULL SELECT @G_\3_vals = JSON_QUERY\(@RecordFilterGrid, '\$\.Fixed\.\3\.value'\)\r?\n)(?!\1IF @G_\3_vals IS NULL SELECT @G_\3_vals = JSON_QUERY\(@RecordFilterGrid, '\$\.(\3)\.value')/gm,
        (_m, head, _full, col, indent) =>
            `${head}${indent}IF @G_${col}_vals IS NULL SELECT @G_${col}_vals = JSON_QUERY(@RecordFilterGrid, '$.${col}.value')\r\n`,
    );
}

content = insertFlatValuePath(content);
const count = (content.match(/JSON_VALUE\(@RecordFilterGrid, '\$\.(\w+)\.value'\)/g) ?? []).length;
fs.writeFileSync(scriptPath, content);
console.log(`Patched ${count} JSON_VALUE flat .value paths in SCRIPT-CRUDEX.sql`);
