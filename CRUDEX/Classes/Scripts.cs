using CRUDEX.Classes;
using ExcelDataReader;
using System.Data;
using System.Linq;
using System.Text;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;
using TDataRows = System.Collections.Generic.List<System.Data.DataRow>;

namespace crudex.Classes
{
    public class Scripts
    {
        static readonly string DirectoryScripts = Path.Combine(Settings.Builder.Environment.ContentRootPath, Settings.Get("DIRECTORY_SCRIPTS"));
        static readonly HashSet<string> ReservedColumnNames = new([
            "Data",
            "Kind",
            "ListItemValue",
            "_",
            "CreatedAt",
            "CreatedBy",
            "UpdatedAt",
            "UpdatedBy",
            "UniqueIdentifier",
            "PkSequence",
            ], StringComparer.OrdinalIgnoreCase);

        private static void AppendSqlIf(StringBuilder result, string indent, string keyword, string condition, string statement)
        {
            result.Append($"{indent}{keyword} {condition}\r\n");
            result.Append($"{indent}    {statement}\r\n");
        }

        private static void AppendSqlIf(StringBuilder result, string indent, string condition, string statement)
            => AppendSqlIf(result, indent, "IF", condition, statement);

        private static void AppendSqlElseIf(StringBuilder result, string indent, string condition, string statement)
            => AppendSqlIf(result, indent, "ELSE IF", condition, statement);

        private static void AppendSqlIfBlock(StringBuilder result, string indent, string keyword, string condition)
            => result.Append($"{indent}{keyword} {condition} BEGIN\r\n");

        private static void AppendSqlIfBlock(StringBuilder result, string indent, string condition)
            => AppendSqlIfBlock(result, indent, "IF", condition);

        private static void AppendSqlElseIfBlock(StringBuilder result, string indent, string condition)
            => AppendSqlIfBlock(result, indent, "ELSE IF", condition);

        private static void AppendSqlEnd(StringBuilder result, string indent)
            => result.Append($"{indent}END\r\n");

        private static string SqlCoalesce(string indent, IEnumerable<string> expressions)
        {
            var parts = expressions.ToList();
            if (parts.Count == 0)
                return "NULL";
            if (parts.Count == 1)
                return parts[0];
            var sb = new StringBuilder("COALESCE(");
            for (var i = 0; i < parts.Count; i++)
                sb.Append($"\r\n{indent}    {parts[i]}{(i < parts.Count - 1 ? "," : "")}");
            sb.Append($"\r\n{indent})");
            return sb.ToString();
        }

        private static void AppendSqlMultiAssign(StringBuilder result, string indent, params (string Variable, string Expression)[] assignments)
        {
            if (assignments.Length == 0)
                return;
            result.Append($"{indent}SELECT {assignments[0].Variable} = {assignments[0].Expression}");
            for (var i = 1; i < assignments.Length; i++)
                result.Append($"\r\n{indent}      ,{assignments[i].Variable} = {assignments[i].Expression}");
            result.Append("\r\n");
        }

        private static string FilterScalarDefaultOpCase(string jsonVariable, string name, long defaultOp) =>
            $"CASE WHEN JSON_VALUE({jsonVariable}, '$.{name}') IS NOT NULL AND JSON_QUERY({jsonVariable}, '$.{name}') IS NULL THEN {defaultOp} END";

        public static async Task Generate(string systemName = "crudex", string databaseName = "crudex", bool saveInDisk = true, bool? isExcel = null, bool withInsertData = true, bool isDocker = true)
        {
            var result = new StringBuilder();
            var dataSet = (isExcel ?? systemName == "crudex") ? await ExcelToDataSet() : await GetDataSet();
            var system = RequireRow(
                (dataSet.Tables["Systems"] ?? throw new Exception("Tabela Systems não existe.")).AsEnumerable(),
                row => Settings.ToString(row["Name"]) == systemName,
                $"System '{systemName}' não encontrado em Systems.");
            var database = RequireRow(
                (dataSet.Tables["Databases"] ?? throw new Exception("Tabela Databases não existe.")).AsEnumerable(),
                row => Settings.ToString(row["Name"]) == databaseName,
                $"Database '{databaseName}' não encontrado em Databases.");
            var columns = (dataSet.Tables["Columns"] ?? throw new Exception("Tabela Columns não existe.")).AsEnumerable().ToList();
            var indexes = (dataSet.Tables["Indexes"] ?? throw new Exception("Tabela Indexes não existe.")).AsEnumerable().ToList();
            var indexkeys = (dataSet.Tables["Indexkeys"] ?? throw new Exception("Tabela Indexkeys não existe.")).AsEnumerable().ToList();
            var domains = (dataSet.Tables["Domains"] ?? throw new Exception("Tabela Domains não existe.")).AsEnumerable().ToList();
            var categories = (dataSet.Tables["Categories"] ?? throw new Exception("Tabela Categories não existe.")).AsEnumerable().ToList();
            var types = (dataSet.Tables["Types"] ?? throw new Exception("Tabela Types não existe.")).AsEnumerable().ToList();
            var comparators = BuildComparators((dataSet.Tables["Comparators"] ?? throw new Exception("Tabela Comparators não existe.")).AsEnumerable().ToList());
            var rulesByCategory = BuildRulesByCategory((dataSet.Tables["Rules"] ?? throw new Exception("Tabela Rules não existe.")).AsEnumerable().ToList());
            var tables = (dataSet.Tables["Tables"] ?? throw new Exception("Tabela Tables não existe.")).AsEnumerable().ToList();
            var unicities = (dataSet.Tables["Unicities"] ?? throw new Exception("Tabela Unicities não existe.")).AsEnumerable().ToList();
            var databaseTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("Tabela DatabasesTables não existe.")).AsEnumerable().ToList()
                .FindAll(row => Settings.ToLong(row["DatabaseId"]) == Settings.ToLong(database["Id"]));
            var references = new TDataRows();
            var firstTime = true;
            var databaseTableRows = GetDatabaseTableRows(databaseTables, tables, columns);
            if (databaseTableRows.Count == 0)
                throw new Exception($"Database '{databaseName}' não possui tabelas em DatabasesTables.");
            if (comparators.Length == 0)
                throw new Exception("Comparators não possui registros.");

            foreach (var table in databaseTableRows)
            {
                if (firstTime)
                {
                    result.AppendLine(GetScriptCreateDatabase(database, isDocker).ToString());
                    firstTime = false;
                }

                result.AppendLine(GetScriptCreateTable(table, columns, indexes, indexkeys, domains, types).ToString());
            }
            if (!firstTime)
            {
                if (systemName == "crudex")
                    result.AppendLine(GetScriptOthers().ToString());
                result.AppendLine(GetScriptTransactions(tables, systemName, databaseName).ToString());
            }
            result.AppendLine(GetScriptReferences(tables, columns).ToString());
            if (withInsertData)
            {
                foreach (var table in tables)
                {
                    var datatable = (dataSet.Tables[Settings.ToString(table["Name"])] ?? throw new Exception($"Tabela {table["Name"]} não encontrada")).AsEnumerable().ToList();

                    result.AppendLine(GetScriptInsertTable(table, columns, datatable).ToString());
                }
            }
            foreach (var table in databaseTableRows)
            {
                result.AppendLine(GetScriptValidateTable(table, tables, columns, domains, types, indexes, indexkeys, unicities).ToString());
                result.AppendLine(GetScriptPersistTable(table, columns, systemName, databaseName).ToString());
                if (!HasDedicatedApiCreateProcedure(table))
                {
                    result.AppendLine(GetScriptOperationCreate(table, columns).ToString());
                    result.AppendLine(GetScriptOperationUpdate(table, columns).ToString());
                    result.AppendLine(GetScriptOperationDelete(table, columns).ToString());
                }
                result.AppendLine(GetScriptReadTable(table, columns, domains, types, comparators, rulesByCategory).ToString());
            }
            if (saveInDisk)
            {
                var filename = Path.Combine(DirectoryScripts, $"SCRIPT-{databaseName.ToUpper()}.sql");

                using var stream = new StreamWriter(path: filename, append: false, encoding: Encoding.UTF8);
                await stream.WriteAsync(result);
            }
        }
        private static async Task<DataSet> ExcelToDataSet()
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
            var filePath = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("FILENAME_EXCEL"));

            await using var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.None, 4096, useAsync: true);
            using var reader = ExcelReaderFactory.CreateReader(stream);

            var dataset = await Task.Run(() =>
            {
                return reader.AsDataSet(new ExcelDataSetConfiguration()
                {
                    ConfigureDataTable = _ => new ExcelDataTableConfiguration()
                    {
                        UseHeaderRow = true
                    }
                });
            });
            ApplyPrimaryKeysFromExcelHeaders(dataset);
            StripPrimaryKeyMarkersFromExcelDataSet(dataset);
            return dataset;
        }
        private static async Task<DataSet> GetDataSet()
        {
            var dataset = (await Procedure.Execute(Settings.ConnectionString(),
                                               "[dbo].[ScriptSystem]",
                                               Config.ToDictionary(Config.ToDictionary(new
                                               { })))).DataSet;

            dataset.Tables[0].TableName = "Categories";
            dataset.Tables[1].TableName = "Types";
            dataset.Tables[2].TableName = "Masks";
            dataset.Tables[3].TableName = "Domains";
            dataset.Tables[4].TableName = "Systems";
            dataset.Tables[5].TableName = "Menus";
            dataset.Tables[6].TableName = "Users";
            dataset.Tables[7].TableName = "SystemsUsers";
            dataset.Tables[8].TableName = "Connections";
            dataset.Tables[9].TableName = "Databases";
            dataset.Tables[10].TableName = "SystemsDatabases";
            dataset.Tables[11].TableName = "Tables";
            dataset.Tables[12].TableName = "DatabasesTables";
            dataset.Tables[13].TableName = "Columns";
            dataset.Tables[14].TableName = "Indexes";
            dataset.Tables[15].TableName = "Indexkeys";
            dataset.Tables[16].TableName = "Sessions";
            dataset.Tables[17].TableName = "Transactions";
            dataset.Tables[18].TableName = "Operations";

            return dataset;
        }
        private static TDictionary GetConstraints(DataRow column, TDataRows domains, TDataRows types)
        {
            var result = new TDictionary();
            var columnName = Settings.ToString(column["Name"]);
            var domain = RequireRow(domains, row => Settings.ToLong(row["Id"]) == Settings.ToLong(column["DomainId"]),
                $"DomainId {column["DomainId"]} não encontrado para coluna '{columnName}'.");
            var type = RequireRow(types, row => Settings.ToLong(row["Id"]) == Settings.ToLong(domain["TypeId"]),
                $"TypeId {domain["TypeId"]} não encontrado para coluna '{columnName}'.");
            string value;

            result.Add("AskPrimarykey", type["AskPrimarykey"]);
            if (Settings.ToBoolean(column["IsPrimarykey"]) || Settings.ToBoolean(column["IsRequired"]))
                result.Add("Required", " NOT NULL");
            else
                result.Add("Required", " NULL");
            if (Settings.ToBoolean(column["IsAutoIncrement"]))
                result.Add("AutoIncrement", " IDENTITY(1,1)");
            if ((value = Settings.ToString(column["Default"])) != string.Empty)
                result.Add("Default", $" DEFAULT CAST('{value}' AS {column["#DataType"]})");
            if ((value = Settings.ToString(column["Minimum"] ?? domain["Minimum"] ?? type["Minimum"])) != string.Empty)
            {
                result.Add("Range", $" CHECK ([{column["Name"]}] >= CAST('{value}' AS {column["#DataType"]}))");
                result.Add("Minimum", value);
            }
            if ((value = Settings.ToString(column["Maximum"] ?? domain["Maximum"] ?? type["Maximum"])) != string.Empty)
            {
                if (result.ContainsKey("Range"))
                    result["Range"] += $" AND [{column["Name"]}] <= CAST('{value}' AS {column["#DataType"]}))";
                else
                    result.Add("Range", $" CHECK ([{column["Name"]}] <= CAST('{value}' AS {column["#DataType"]}))");
                result.Add("Maximum", value);
            }

            return result;
        }
        private static TDictionary[] GetAllowedComparatorsForColumn(Dictionary<long, List<long>> rulesByCategory, TDictionary[] comparators, DataRow column, TDataRows domains, TDataRows types)
        {
            var columnName = Settings.ToString(column["Name"]);
            var domain = RequireRow(domains, row => Settings.ToLong(row["Id"]) == Settings.ToLong(column["DomainId"]),
                $"DomainId {column["DomainId"]} não encontrado para coluna '{columnName}'.");
            var type = RequireRow(types, row => Settings.ToLong(row["Id"]) == Settings.ToLong(domain["TypeId"]),
                $"TypeId {domain["TypeId"]} não encontrado para coluna '{columnName}'.");
            var categoryId = Settings.ToLong(type["CategoryId"]);
            if (!rulesByCategory.TryGetValue(categoryId, out var allowed) || allowed.Count == 0)
                throw new Exception($"Categoria {categoryId} do tipo '{type["Name"]}' (coluna '{columnName}') não possui regras em Rules.");
            var allowedSet = allowed.ToHashSet();
            var filtered = comparators.Where(item => allowedSet.Contains(Settings.ToLong(item["Id"]))).ToArray();
            if (filtered.Length == 0)
                throw new Exception($"Categoria {categoryId} (coluna '{columnName}') não possui comparadores válidos em Comparators.");
            return filtered;
        }

        private static bool CategoryAllowsBetweenFilter(Dictionary<long, List<long>> rulesByCategory, TDictionary[] comparators, DataRow column, TDataRows domains, TDataRows types) =>
            GetAllowedComparatorsForColumn(rulesByCategory, comparators, column, domains, types).Any(IsBetweenComparator);

        private static void AppendReadFilterColumn(StringBuilder result, DataRow column, bool needsBetweenSlots, string indent)
        {
            var name = column["Name"];
            var dataType = Convert.ToString(column["#DataType"]) ?? string.Empty;
            var isPrimaryKey = Settings.ToBoolean(column["IsPrimarykey"]);

            if (!isPrimaryKey)
            {
                result.Append($"{indent}IF EXISTS(SELECT 1 FROM OPENJSON(@Filter) WHERE [key] = '{name}' AND [type] = 0)\r\n");
                result.Append($"{indent}    SET @Where = @Where + ' AND [T].[{name}] IS NULL'\r\n");
                result.Append($"{indent}ELSE\r\n");
            }
            AppendComparatorPredicateFromMetadata(result, indent, $"@G_{name}_comparator", $"[T].[{name}]", dataType, Settings.ToString(name), isSearch: false, needsBetweenSlots);
        }
        private static void AppendReadTableFilterColumn(StringBuilder result, DataRow column, TDataRows domains, TDataRows types, string valueVariable, string parameterName, string indent)
        {
            var name = column["Name"];
            var isPrimaryKey = Settings.ToBoolean(column["IsPrimarykey"]);

            if (!isPrimaryKey)
            {
                result.Append($"{indent}IF EXISTS(SELECT 1 FROM OPENJSON(@Filter) WHERE [key] = '{name}' AND [type] = 0)\r\n");
                result.Append($"{indent}    SET @Where = @Where + ' AND [T].[{name}] IS NULL'\r\n");
                result.Append($"{indent}ELSE IF {valueVariable} IS NOT NULL BEGIN\r\n");
            }
            else
                result.Append($"{indent}IF {valueVariable} IS NOT NULL BEGIN\r\n");
            result.Append($"{indent}    SET @Where = @Where + ' AND [T].[{name}] = {parameterName}'\r\n");
            result.Append($"{indent}END\r\n");
        }
        private static void AppendReadSearchCondition(StringBuilder result, DataRow column, bool needsBetweenSlots, string indent)
        {
            var name = column["Name"];
            var dataType = Convert.ToString(column["#DataType"]) ?? string.Empty;
            var isPrimaryKey = Settings.ToBoolean(column["IsPrimarykey"]);
            var colRef = $"COALESCE([D].[{name}], [O].[{name}])";

            if (!isPrimaryKey)
            {
                result.Append($"{indent}IF EXISTS(SELECT 1 FROM OPENJSON(@Search) WHERE [key] = '{name}' AND [type] = 0) BEGIN\r\n");
                result.Append($"{indent}    IF @Where <> '' SET @Where = @Where + ' AND '\r\n");
                result.Append($"{indent}    SET @Where = @Where + '{colRef} IS NULL'\r\n");
                result.Append($"{indent}END ELSE\r\n");
            }
            AppendComparatorPredicateFromMetadata(result, indent, $"@S_{name}_comparator", colRef, dataType, Settings.ToString(name), isSearch: true, needsBetweenSlots);
        }

        private static void AppendReadGridFilterDeclareVars(StringBuilder result, DataRow column, bool isSearch, bool declare, bool needsBetweenSlots)
        {
            var name = column["Name"];
            var dataType = column["#DataType"];
            var prefix = isSearch ? "S" : "G";
            var lead = declare ? "            DECLARE " : "                   ,";

            result.Append($"{lead}@{prefix}_{name}_comparator TINYINT\r\n");
            result.Append($"                   ,@{prefix}_{name}_v {dataType}\r\n");
            result.Append($"                   ,@{prefix}_{name}_vals NVARCHAR(MAX)\r\n");
            if (needsBetweenSlots)
            {
                result.Append($"                   ,@{prefix}_{name}_v1 {dataType}\r\n");
                result.Append($"                   ,@{prefix}_{name}_v2 {dataType}\r\n");
            }
        }

        private static void AppendReadGridFilterAssignVars(StringBuilder result, DataRow column, bool isSearch, TDictionary[] comparators, Dictionary<long, List<long>> rulesByCategory, TDataRows domains, TDataRows types)
        {
            var name = column["Name"];
            var dataType = column["#DataType"];
            var prefix = isSearch ? "S" : "G";
            var jsonVariable = isSearch ? "@Search" : "@Filter";
            var defaultOp = GetDefaultComparatorId(comparators, rulesByCategory, column, domains, types, isSearch);
            var indent = isSearch ? "                " : "            ";
            var comparatorVar = $"@{prefix}_{name}_comparator";
            var valueVar = $"@{prefix}_{name}_v";
            var valuesVar = $"@{prefix}_{name}_vals";
            var columnName = Settings.ToString(name);
            var needsBetweenSlots = CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types);

            AppendSqlMultiAssign(result, indent,
                (comparatorVar, SqlCoalesce(indent,
                [
                    $"TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}.comparator') AS TINYINT)",
                    FilterScalarDefaultOpCase(jsonVariable, columnName, defaultOp),
                ])),
                (valueVar, SqlCoalesce(indent,
                [
                    $"TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}.value') AS {dataType})",
                    $"TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}') AS {dataType})",
                ])),
                (valuesVar, SqlCoalesce(indent,
                [
                    $"JSON_QUERY({jsonVariable}, '$.{name}.value')",
                    $"JSON_QUERY({jsonVariable}, '$.{name}')",
                ])));

            if (needsBetweenSlots)
            {
                AppendSqlMultiAssign(result, indent,
                    ($"@{prefix}_{name}_v1", $"TRY_CAST(JSON_VALUE({valuesVar}, '$[0]') AS {dataType})"),
                    ($"@{prefix}_{name}_v2", $"TRY_CAST(JSON_VALUE({valuesVar}, '$[1]') AS {dataType})"));
            }
        }

        private static DataRow RequireRow(IEnumerable<DataRow> rows, Func<DataRow, bool> predicate, string message) =>
            rows.FirstOrDefault(predicate) ?? throw new Exception(message);

        private static void RequireNotEmpty<T>(ICollection<T> items, string message)
        {
            if (items.Count == 0)
                throw new Exception(message);
        }

        private static void RequireComparatorIds(string listIds, string comparatorType)
        {
            if (listIds == string.Empty)
                throw new Exception($"Comparators: nenhum comparador do tipo '{comparatorType}' encontrado no metadado.");
        }

        private static string TableName(DataRow table) => Settings.ToString(table["Name"]);

        private static List<DataRow> GetDatabaseTableRows(TDataRows databaseTables, TDataRows tables, TDataRows columns)
        {
            var rows = new TDataRows();
            var seen = new HashSet<long>();

            foreach (var databaseTable in databaseTables)
            {
                var table = RequireRow(tables, row => Settings.ToLong(row["Id"]) == Settings.ToLong(databaseTable["TableId"]),
                    $"DatabasesTables referencia TableId {databaseTable["TableId"]} inexistente em Tables.");
                if (GetTableColumnRows(columns, table).Count == 0)
                    throw new Exception($"Tabela '{table["Name"]}' em DatabasesTables não possui colunas cadastradas em Columns.");
                var id = Settings.ToLong(table["Id"]);
                if (seen.Add(id))
                    rows.Add(table);
            }

            foreach (var table in tables)
            {
                var id = Settings.ToLong(table["Id"]);
                if (seen.Contains(id))
                    continue;
                if (GetTableColumnRows(columns, table).Count == 0)
                    throw new Exception($"Tabela '{table["Name"]}' não possui colunas cadastradas em Columns.");
                rows.Add(table);
                seen.Add(id);
            }

            return rows;
        }

        static bool IsInWordsColumn(DataRow column) => Settings.ToBoolean(column["IsInWords"]);

        static bool IsVirtualColumn(DataRow column) =>
            column.Table.Columns.Contains("IsVirtual") && Settings.ToBoolean(column["IsVirtual"]);

        static List<DataRow> GetTableColumnRows(TDataRows columns, DataRow table, bool physicalOnly = false) =>
            columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"])
                && (!physicalOnly || !IsVirtualColumn(row)));

        static string ResolveColumnName(DataTable table, string columnName)
        {
            if (table.Columns.Contains(columnName))
                return columnName;

            var prefixedMatches = table.Columns.Cast<DataColumn>()
                .Where(column => string.Equals(NormalizeColumnHeader(column.ColumnName), columnName, StringComparison.OrdinalIgnoreCase))
                .ToList();
            if (prefixedMatches.Count == 1)
                return prefixedMatches[0].ColumnName;
            if (prefixedMatches.Count > 1)
                throw new Exception($"Column '{columnName}' is ambiguous in table {table.TableName}.");

            var availableColumns = string.Join(", ", table.Columns.Cast<DataColumn>().Select(column => column.ColumnName));
            throw new Exception($"Column '{columnName}' does not belong to table {table.TableName}. Columns: [{availableColumns}]");
        }

        static object? GetRowValue(DataRow row, string columnName) =>
            row[ResolveColumnName(row.Table, columnName)];

        static void SetRowValue(DataRow row, string columnName, object? value) =>
            row[ResolveColumnName(row.Table, columnName)] = value ?? DBNull.Value;

        static string NormalizeColumnHeader(string header)
        {
            var value = (header ?? string.Empty).Trim();
            return value.StartsWith("*") ? value[1..].Trim() : value;
        }

        static bool IsMarkedPrimaryKeyHeader(string header) =>
            !string.IsNullOrWhiteSpace(header) && header.TrimStart().StartsWith("*");

        static void StripPrimaryKeyMarkersFromDataTable(DataTable table)
        {
            foreach (var column in table.Columns.Cast<DataColumn>().ToList())
            {
                var normalized = NormalizeColumnHeader(column.ColumnName);
                if (!string.Equals(column.ColumnName, normalized, StringComparison.Ordinal))
                    column.ColumnName = normalized;
            }
        }

        static void StripPrimaryKeyMarkersFromExcelDataSet(DataSet dataset)
        {
            foreach (DataTable table in dataset.Tables)
                StripPrimaryKeyMarkersFromDataTable(table);
        }

        static void ApplyPrimaryKeysFromExcelHeaders(DataSet dataset)
        {
            var tables = (dataset.Tables["Tables"] ?? throw new Exception("Tabela Tables não existe.")).AsEnumerable().ToList();
            var columns = (dataset.Tables["Columns"] ?? throw new Exception("Tabela Columns não existe.")).AsEnumerable().ToList();
            var columnsTable = dataset.Tables["Columns"]!;
            var pkSequenceByColumn = new Dictionary<DataRow, long>();

            foreach (var table in tables)
            {
                var worksheetName = Settings.ToString(GetRowValue(table, "Name"));
                if (string.IsNullOrWhiteSpace(worksheetName))
                    throw new Exception("Tabela em Tables sem Name definido.");

                var tableId = Settings.ToLong(GetRowValue(table, "Id"));
                var tableColumns = columns.FindAll(row => Settings.ToLong(GetRowValue(row, "TableId")) == tableId);
                if (tableColumns.Count == 0)
                    throw new Exception($"Tabela '{worksheetName}' não possui colunas cadastradas em Columns.");

                if (!dataset.Tables.Contains(worksheetName))
                    throw new Exception($"Aba de dados '{worksheetName}' não encontrada no Excel.");

                var worksheet = dataset.Tables[worksheetName]!;

                foreach (var row in tableColumns)
                    pkSequenceByColumn.Remove(row);

                var pkHeaders = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var dataHeaders = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                long pkSequence = 0;
                foreach (DataColumn headerColumn in worksheet.Columns.Cast<DataColumn>())
                {
                    var header = $"{headerColumn.ColumnName}".Trim();
                    if (header == string.Empty || header.StartsWith("#"))
                        continue;

                    var normalizedHeader = NormalizeColumnHeader(header);
                    var row = tableColumns.FirstOrDefault(column =>
                        string.Equals(Settings.ToString(GetRowValue(column, "Name")), normalizedHeader, StringComparison.OrdinalIgnoreCase)
                        || string.Equals(Settings.ToString(GetRowValue(column, "Name")), header, StringComparison.OrdinalIgnoreCase));

                    if (row == null)
                        throw new Exception($"Coluna '{normalizedHeader}' na aba '{worksheetName}' não está cadastrada em Columns.");

                    dataHeaders.Add(normalizedHeader);

                    if (IsMarkedPrimaryKeyHeader(header))
                    {
                        if (!Settings.ToBoolean(GetRowValue(row, "IsPrimarykey")))
                            throw new Exception($"Coluna '{normalizedHeader}' da tabela '{worksheetName}' está marcada com '*' na aba de dados, mas IsPrimarykey não está definido em Columns.");

                        if (!Settings.ToBoolean(GetRowValue(row, "IsRequired")))
                            throw new Exception($"Coluna '{normalizedHeader}' da tabela '{worksheetName}' está marcada com '*' na aba de dados, mas IsRequired não está definido em Columns.");

                        pkHeaders.Add(normalizedHeader);
                        pkSequenceByColumn[row] = ++pkSequence;
                    }
                    else if (Settings.ToBoolean(GetRowValue(row, "IsPrimarykey")))
                        throw new Exception($"Coluna '{normalizedHeader}' da tabela '{worksheetName}' não está marcada com '*' na aba de dados, mas IsPrimarykey está definido em Columns.");

                    SetRowValue(row, "Name", normalizedHeader);
                }

                foreach (var row in tableColumns.Where(row => Settings.ToBoolean(GetRowValue(row, "IsPrimarykey"))))
                {
                    var name = Settings.ToString(GetRowValue(row, "Name"));
                    if (!Settings.ToBoolean(GetRowValue(row, "IsRequired")))
                        throw new Exception($"Coluna '{name}' da tabela '{worksheetName}' tem IsPrimarykey em Columns, mas IsRequired não está definido.");
                    if (!pkHeaders.Contains(name))
                        throw new Exception($"Coluna '{name}' tem IsPrimarykey em Columns, mas não está marcada com '*' na aba '{worksheetName}'.");
                }

                foreach (var row in tableColumns.Where(row => !IsVirtualColumn(row)))
                {
                    var name = Settings.ToString(GetRowValue(row, "Name"));
                    if (!dataHeaders.Contains(name))
                        throw new Exception($"Coluna '{name}' cadastrada em Columns para '{worksheetName}', mas não existe na aba de dados.");
                }

                var physicalColumnRows = tableColumns.FindAll(row => !IsVirtualColumn(row));
                ValidateAutoIncrementPrimaryKeyRules(worksheetName, physicalColumnRows, GetPrimaryKeyColumnRows(physicalColumnRows));
            }

            if (!columnsTable.Columns.Contains("PkSequence"))
                columnsTable.Columns.Add("PkSequence", typeof(long));

            foreach (var row in columns)
                row["PkSequence"] = pkSequenceByColumn.TryGetValue(row, out var sequence) ? sequence : DBNull.Value;
        }

        static void ValidateAutoIncrementPrimaryKeyRules(string tableName, TDataRows physicalColumnRows, List<DataRow> primaryColumns)
        {
            var autoIncrementColumns = physicalColumnRows.FindAll(column => Settings.ToBoolean(column["IsAutoIncrement"]));
            if (autoIncrementColumns.Count == 0)
                return;

            if (autoIncrementColumns.Count > 1)
            {
                var names = string.Join(", ", autoIncrementColumns.Select(column => Settings.ToString(column["Name"])));
                throw new Exception($"Tabela '{tableName}' possui mais de uma coluna com autoincrement ({names}).");
            }

            var autoIncrementColumn = autoIncrementColumns[0];
            var autoIncrementName = Settings.ToString(autoIncrementColumn["Name"]);

            if (!Settings.ToBoolean(autoIncrementColumn["IsPrimarykey"]))
                throw new Exception($"Coluna '{autoIncrementName}' da tabela '{tableName}' tem autoincrement, mas não é primary key.");

            if (primaryColumns.Count != 1)
                throw new Exception($"Tabela '{tableName}' com autoincrement deve ter exatamente uma primary key, a coluna '{autoIncrementName}'.");

            if (!string.Equals(Settings.ToString(primaryColumns[0]["Name"]), autoIncrementName, StringComparison.OrdinalIgnoreCase))
                throw new Exception($"Tabela '{tableName}' com autoincrement deve ter como única primary key a coluna '{autoIncrementName}'.");
        }

        static List<DataRow> GetPrimaryKeyColumnRows(TDataRows physicalColumnRows) =>
            physicalColumnRows
                .FindAll(row => Settings.ToBoolean(row["IsPrimarykey"]))
                .OrderBy(row => row.Table.Columns.Contains("PkSequence") && row["PkSequence"] != DBNull.Value
                    ? Settings.ToLong(row["PkSequence"])
                    : Settings.ToLong(row["Sequence"]))
                .ToList();

        static string PkVariableName(DataRow column) => $"@W_{column["Name"]}";

        static DataRow? GetAutoIncrementPrimaryKeyColumn(TDataRows primaryColumns) =>
            primaryColumns.FirstOrDefault(column => Settings.ToBoolean(column["IsAutoIncrement"]));

        static bool HasAutoIncrementPrimaryKey(TDataRows primaryColumns) =>
            GetAutoIncrementPrimaryKeyColumn(primaryColumns) != null;

        static void AppendIdentityInsertOn(StringBuilder result, string tableName, string indent) =>
            result.Append($"{indent}SET IDENTITY_INSERT [dbo].[{tableName}] ON\r\n");

        static void AppendIdentityInsertOff(StringBuilder result, string tableName, string indent) =>
            result.Append($"{indent}SET IDENTITY_INSERT [dbo].[{tableName}] OFF\r\n");

        static string BuildColumnDefinition(DataRow column, TDictionary constraints)
        {
            var required = $"{(constraints.TryGetValue("Required", out dynamic? value) ? value : "")}";
            var autoIncrement = $"{(constraints.TryGetValue("AutoIncrement", out value) ? value : "")}";
            var defaultValue = string.IsNullOrEmpty(autoIncrement)
                ? $"{(constraints.TryGetValue("Default", out value) ? value : "")}"
                : string.Empty;
            var range = $"{(constraints.TryGetValue("Range", out value) ? value : "")}";
            return $"[{column["Name"]}] {column["#DataType"]}{autoIncrement}{required}{defaultValue}{range}";
        }

        static void AppendPrimaryKeyVariableDeclarations(StringBuilder result, TDataRows primaryColumns, string jsonVariable, string indent, bool useDeclare = true)
        {
            var firstTime = true;
            foreach (var column in primaryColumns)
            {
                var variable = PkVariableName(column);
                var line = $"{variable} {column["#DataType"]} = CAST(JSON_VALUE({jsonVariable}, '$.{column["Name"]}') AS {column["#DataType"]})";
                if (firstTime)
                {
                    result.Append($"{indent}{(useDeclare ? "DECLARE " : "SET ")}{line}\r\n");
                    firstTime = false;
                }
                else
                    result.Append($"{indent}       ,{line}\r\n");
            }
            if (!firstTime && useDeclare)
                result.Append($"\r\n");
        }

        static void AppendPrimaryKeyVariableAssignments(StringBuilder result, TDataRows primaryColumns, string jsonVariable, string indent)
        {
            foreach (var column in primaryColumns)
            {
                var variable = PkVariableName(column);
                result.Append($"{indent}SET {variable} = CAST(JSON_VALUE({jsonVariable}, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
            }
            if (primaryColumns.Count > 0)
                result.Append($"\r\n");
        }

        static void AppendPrimaryKeyWhereClause(StringBuilder result, TDataRows primaryColumns, string tableAlias, string variablePrefix = "@W_", string linePrefix = "", string firstConditionPrefix = "")
        {
            var firstTime = true;
            foreach (var column in primaryColumns)
            {
                var columnName = Settings.ToString(column["Name"]);
                var columnRef = string.IsNullOrEmpty(tableAlias)
                    ? $"[{columnName}]"
                    : $"[{tableAlias}].[{columnName}]";
                var condition = $"{columnRef} = {variablePrefix}{columnName}";
                if (firstTime)
                {
                    result.Append($"{linePrefix}{firstConditionPrefix}{condition}");
                    firstTime = false;
                }
                else
                    result.Append($"{linePrefix}      AND {condition}");
            }
        }

        static void AppendPrimaryKeyJsonMatchClause(StringBuilder result, TDataRows primaryColumns, string jsonExpression, string variablePrefix = "@W_", string linePrefix = "", string firstConditionPrefix = "")
        {
            var firstTime = true;
            foreach (var column in primaryColumns)
            {
                var columnName = Settings.ToString(column["Name"]);
                var condition = $"CAST(JSON_VALUE({jsonExpression}, '$.{columnName}') AS {column["#DataType"]}) = {variablePrefix}{columnName}";
                if (firstTime)
                {
                    result.Append($"{linePrefix}{firstConditionPrefix}{condition}");
                    firstTime = false;
                }
                else
                    result.Append($"{linePrefix}      AND {condition}");
            }
        }

        static void AppendPrimaryKeyExcludeCurrentRow(StringBuilder result, TDataRows primaryColumns, string tableAlias, string variablePrefix = "@W_", string linePrefix = "")
        {
            if (primaryColumns.Count == 0)
                return;
            if (primaryColumns.Count == 1)
            {
                var columnName = Settings.ToString(primaryColumns[0]["Name"]);
                var columnRef = string.IsNullOrEmpty(tableAlias)
                    ? $"[{columnName}]"
                    : $"[{tableAlias}].[{columnName}]";
                result.Append($"{linePrefix} AND {columnRef} <> {variablePrefix}{columnName}");
                return;
            }

            result.Append($"{linePrefix} AND NOT (");
            AppendPrimaryKeyWhereClause(result, primaryColumns, tableAlias, variablePrefix);
            result.Append(")");
        }

        static string BuildPrimaryKeyIndexColumns(TDataRows primaryColumns) =>
            string.Join(", ", primaryColumns.Select(column => $"[{column["Name"]}]"));

        static string BuildPrimaryKeyJoinClause(TDataRows primaryColumns, string leftAlias, string rightAlias, string rightPrefix = "")
        {
            var parts = primaryColumns.Select(column =>
            {
                var columnName = Settings.ToString(column["Name"]);
                return $"[{leftAlias}].[{columnName}] = [{rightAlias}].[{rightPrefix}{columnName}]";
            });
            return string.Join(" AND ", parts);
        }

        static string BuildDefaultOrderBy(TDataRows primaryColumns, string tableAlias) =>
            string.Join(", ", primaryColumns.Select(column => $"[{tableAlias}].[{column["Name"]}] ASC"));

        static string BuildPrimaryKeyColumnDefinitions(TDataRows primaryColumns) =>
            string.Join(", ", primaryColumns.Select(column => $"[{column["Name"]}] {column["#DataType"]}"));

        static string BuildPrimaryKeySelectList(TDataRows primaryColumns, string tableAlias) =>
            string.Join("\r\n", primaryColumns.Select(column => $"                              ,[{tableAlias}].[{column["Name"]}]"));

        static string BuildPrimaryKeyInsertList(TDataRows primaryColumns) =>
            string.Join(", ", primaryColumns.Select(column => $"[{column["Name"]}]"));

        static string BuildPrimaryKeyGridFilterClause(TDataRows primaryColumns) =>
            primaryColumns.Count == 1
                ? $"[T].[{primaryColumns[0]["Name"]}] IN (' + @_ + ')"
                : $"[T].[{primaryColumns[0]["Name"]}] IN (' + @_ + ')";

        static string InWordsColumnName(object columnName) => $"{columnName}InWords";

        static void AppendReadInWordsColumnFromJson(StringBuilder result, DataRow column)
        {
            if (!IsInWordsColumn(column))
                return;
            var dataType = column["#DataType"];
            result.Append($"              ,CAST([dbo].[NUMBER_IN_WORDS](CAST(JSON_VALUE(ISNULL([ActualRecord], [LastRecord]), '$.{column["Name"]}') AS {dataType})) AS NVARCHAR(MAX)) AS [{InWordsColumnName(column["Name"])}]\r\n");
        }

        static void AppendReadInWordsColumnFromAlias(StringBuilder result, DataRow column, string alias, string indent = "                              ")
        {
            if (!IsInWordsColumn(column))
                return;
            var dataType = column["#DataType"];
            result.Append($"{indent},CAST([dbo].[NUMBER_IN_WORDS](CAST([{alias}].[{column["Name"]}] AS {dataType})) AS NVARCHAR(MAX)) AS [{InWordsColumnName(column["Name"])}]\r\n");
        }

        static void AppendReadInWordsResultSchema(StringBuilder result, DataRow column, string indent = "                    ")
        {
            if (!IsInWordsColumn(column))
                return;
            result.Append($"{indent},CAST(NULL AS NVARCHAR(MAX)) AS [{InWordsColumnName(column["Name"])}]\r\n");
        }

        static void AppendReadInWordsJsonOutput(StringBuilder result, DataRow column, string indent = "                      ")
        {
            if (!IsInWordsColumn(column))
                return;
            result.Append($"{indent},[{InWordsColumnName(column["Name"])}]\r\n");
        }

        private static void AppendReadExecutesqlParams(StringBuilder result, TDataRows filterableColumns, bool includeTableFilters, bool includeGridFilters, TDictionary[] comparators, Dictionary<long, List<long>> rulesByCategory, TDataRows domains, TDataRows types, string indent)
        {
            if (!includeTableFilters && !includeGridFilters)
                return;

            var first = true;
            foreach (var column in filterableColumns)
            {
                if (!includeTableFilters)
                    break;
                if (first)
                {
                    result.Append($"{indent},N'");
                    first = false;
                }
                else
                    result.Append(",");
                result.Append($"@T_{column["Name"]} {column["#DataType"]}");
            }
            foreach (var column in filterableColumns)
            {
                if (!includeGridFilters)
                    break;
                var name = column["Name"];
                var dataType = column["#DataType"];
                var needsBetweenSlots = CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types);
                if (first)
                {
                    result.Append($"{indent},N'");
                    first = false;
                }
                else
                    result.Append(",");
                result.Append($"@{name} {dataType}");
                if (needsBetweenSlots)
                    result.Append($",@{name}_v1 {dataType},@{name}_v2 {dataType}");
                result.Append($",@{name}_vals NVARCHAR(MAX)");
            }
            if (!first)
                result.Append($"'\r\n");
        }
        private static void AppendReadExecutesqlAssignments(StringBuilder result, TDataRows filterableColumns, bool includeTableFilters, bool includeGridFilters, TDictionary[] comparators, Dictionary<long, List<long>> rulesByCategory, TDataRows domains, TDataRows types, string indent)
        {
            if (includeTableFilters)
                foreach (var column in filterableColumns)
                    result.Append($"{indent},@T_{column["Name"]} = @WT_{column["Name"]}\r\n");
            if (includeGridFilters)
                foreach (var column in filterableColumns)
                {
                    var name = column["Name"];
                    var needsBetweenSlots = CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types);
                    result.Append($"{indent},@{name} = @G_{name}_v\r\n");
                    if (needsBetweenSlots)
                    {
                        result.Append($"{indent},@{name}_v1 = @G_{name}_v1\r\n");
                        result.Append($"{indent},@{name}_v2 = @G_{name}_v2\r\n");
                    }
                    result.Append($"{indent},@{name}_vals = @G_{name}_vals\r\n");
                }
        }
        private static StringBuilder GetScriptCreateDatabase(DataRow database, bool isDocker)
        {
            var result = new StringBuilder();
            var folder = database["Folder"].ToString() ?? string.Empty;
            var databaseName = database["Name"];
            var databaseAlias = database["Alias"];
            var filename = Path.Combine(folder, Settings.ToString(databaseName));

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar banco-de-dados {databaseName}\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"USE [master]\r\n");
            result.Append($"SET NOCOUNT ON\r\n");
            result.Append($"IF EXISTS(SELECT 1 FROM sys.databases where name = '{databaseAlias}')\r\n");
            result.Append($"    DROP DATABASE {databaseAlias}\r\n");
            result.Append($"GO\r\n");
            if (isDocker)
                result.Append($"CREATE DATABASE [{databaseAlias}]\r\n");
            else
            {
            result.Append($"CREATE DATABASE [{databaseAlias}]\r\n");
            result.Append($"    CONTAINMENT = NONE\r\n");
            result.Append($"    ON PRIMARY\r\n");
            result.Append($"    (NAME = N'${databaseName}', FILENAME = N'{filename}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)\r\n");
            result.Append($"    LOG ON\r\n");
            result.Append($"    (NAME = N'${databaseName}_log', FILENAME = N'{filename}.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)\r\n");
            result.Append($"    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF\r\n");
            }
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET COMPATIBILITY_LEVEL = 160\r\n");
            result.Append($"GO\r\n");
            result.Append($"IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))\r\n");
            result.Append($"    EXEC [dbo].[sp_fulltext_database] @action = 'enable'\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ANSI_NULL_DEFAULT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ANSI_NULLS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ANSI_PADDING OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ANSI_WARNINGS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ARITHABORT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET AUTO_CLOSE OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET AUTO_SHRINK OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET AUTO_UPDATE_STATISTICS ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET CURSOR_CLOSE_ON_COMMIT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET CURSOR_DEFAULT  GLOBAL\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET CONCAT_NULL_YIELDS_NULL OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET NUMERIC_ROUNDABORT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET QUOTED_IDENTIFIER OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET RECURSIVE_TRIGGERS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET  DISABLE_BROKER\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET AUTO_UPDATE_STATISTICS_ASYNC OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET DATE_CORRELATION_OPTIMIZATION OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET TRUSTWORTHY OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ALLOW_SNAPSHOT_ISOLATION ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET PARAMETERIZATION SIMPLE\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET READ_COMMITTED_SNAPSHOT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET HONOR_BROKER_PRIORITY OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET RECOVERY SIMPLE\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET  MULTI_USER\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET PAGE_VERIFY CHECKSUM\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET DB_CHAINING OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF)\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET TARGET_RECOVERY_TIME = 60 SECONDS\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET DELAYED_DURABILITY = DISABLED\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET ACCELERATED_DATABASE_RECOVERY = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET QUERY_STORE = ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), " +
                          $"DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, " +
                          $"SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)\r\n");
            result.Append($"GO\r\n");
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Início da criação dos scripts\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"USE [{databaseAlias}]\r\n");
            result.Append($"GO\r\n");
            result.Append($"SET ANSI_NULLS ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"SET QUOTED_IDENTIFIER ON\r\n");
            result.Append($"GO\r\n");

            return result;
        }
        private static StringBuilder GetScriptOthers()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[Config]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.Config.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[NewId]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.NewId.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[NewOperationId]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.NewOperationId.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[Login]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.Login.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[GetPublicKey]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.GetPublicKey.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[ScriptSystem]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.ScriptSystem.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar function [dbo].[HUNDREDS_IN_WORDS]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.HUNDREDS_IN_WORDS.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar function [dbo].[NUMBER_IN_WORDS]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.NUMBER_IN_WORDS.sql")));

            return result;
        }
        private static void AppendNewOperationIdCall(StringBuilder result, string systemName, string databaseName, string variableName)
        {
            result.Append($"            EXEC [dbo].[NewOperationId] '{systemName}', '{databaseName}', {variableName} OUT\r\n");
        }

        private static void AppendNewIdCall(StringBuilder result, string systemName, string databaseName, string tableName, string variableName)
        {
            result.Append($"    EXEC [dbo].[NewId] '{systemName}', '{databaseName}', '{tableName}', {variableName} OUT\r\n");
        }

        private static void AppendResolveCreateId(StringBuilder result, DataRow table, TDataRows primaryColumns, string systemName, string databaseName)
        {
            var autoIncrementColumn = GetAutoIncrementPrimaryKeyColumn(primaryColumns);
            if (autoIncrementColumn == null)
                return;

            var columnName = Settings.ToString(autoIncrementColumn["Name"]);
            var dataType = autoIncrementColumn["#DataType"];
            var variableName = PkVariableName(autoIncrementColumn);
            var tableName = Settings.ToString(table["Name"]);

            result.Append($"    IF @Action = 'create' AND {variableName} IS NULL BEGIN\r\n");
            result.Append($"        SELECT {variableName} = CAST(JSON_VALUE([ActualRecord], '$.{columnName}') AS {dataType})\r\n");
            result.Append($"            FROM [dbo].[Operations]\r\n");
            result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
            result.Append($"                  AND [TableName] = '{tableName}'\r\n");
            result.Append($"                  AND [Action] = 'create'\r\n");
            result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
            result.Append($"        IF {variableName} IS NULL BEGIN\r\n");
            result.Append($"            DECLARE @NewId BIGINT\r\n");
            AppendNewIdCall(result, systemName, databaseName, tableName, "@NewId");
            result.Append($"            SET {variableName} = CAST(@NewId AS {dataType})\r\n");
            result.Append($"        END\r\n");
            result.Append($"        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.{columnName}', {variableName})\r\n");
            result.Append($"    END\r\n");
            result.Append($"\r\n");
        }

        // {Alias}Create da API (ex.: abrir Trs) colide com {Alias}Create do commit (GetScriptOperationCreate).
        private static bool HasDedicatedApiCreateProcedure(DataRow table)
            => string.Equals(Settings.ToString(table["Name"]), "Transactions", StringComparison.OrdinalIgnoreCase);

        private static string BuildAliasProcedure(string alias, string action)
            => $"{alias}{char.ToUpper(action[0])}{action[1..].ToLower()}";

        private static string GetTransactionTableAlias(TDataRows tables)
        {
            foreach (var row in tables)
            {
                if (Settings.ToString(row["Name"]) == "Transactions")
                    return Settings.ToString(row["Alias"]);
            }

            throw new Exception("Tabela Transactions não encontrada nos metadados.");
        }

        private static string LoadRenamedProcedureScript(string fileName, string legacyProcedureName, string schema, string alias, string action, string legacySchema = "dbo")
        {
            var sql = File.ReadAllText(Path.Combine(DirectoryScripts, fileName));
            var legacyQualified = $"[{legacySchema}].[{legacyProcedureName}]";
            var newShort = BuildAliasProcedure(alias, action);
            var newQualified = $"[{schema}].[{newShort}]";

            return sql
                .Replace(legacyQualified, newQualified, StringComparison.OrdinalIgnoreCase)
                .Replace($"[{legacyProcedureName}]", $"[{newShort}]", StringComparison.OrdinalIgnoreCase)
                .Replace(legacyProcedureName, newShort, StringComparison.OrdinalIgnoreCase);
        }
        private static StringBuilder GetScriptAliasCreate(DataRow table, string systemName, string databaseName)
        {
            var alias = Settings.ToString(table["Alias"]);
            var tableName = Settings.ToString(table["Name"]);
            var procedureName = BuildAliasProcedure(alias, "create");
            var result = new StringBuilder();

            result.Append($"IF(SELECT object_id('[dbo].[{procedureName}]', 'P')) IS NULL\r\n");
            result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{procedureName}] AS PRINT 1')\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER PROCEDURE[dbo].[{procedureName}](@SessionId BIGINT\r\n");
            result.Append($"                                         ,@UserName VARCHAR(25)\r\n");
            result.Append($"                                         ,@ReturnValue BIGINT OUT) AS BEGIN\r\n");
            result.Append($"    SET NOCOUNT ON\r\n");
            result.Append($"    SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
            result.Append($"    IF @SessionId IS NULL\r\n");
            result.Append($"        THROW 51000, 'Valor de @SessionId é requerido', 1\r\n");
            result.Append($"    IF @UserName IS NULL\r\n");
            result.Append($"        THROW 51000, 'Valor de @UserName é requerido', 1\r\n");
            result.Append($"    IF EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [SessionId] = @SessionId AND [IsConfirmed] IS NULL)\r\n");
            result.Append($"        THROW 51000, 'Há transação pendente neste @SessionId', 1\r\n");
            result.Append($"\r\n");
            result.Append($"    DECLARE @TransactionId BIGINT\r\n");
            result.Append($"\r\n");
            AppendNewIdCall(result, systemName, databaseName, tableName, "@TransactionId");
            AppendIdentityInsertOn(result, tableName, "    ");
            result.Append($"    INSERT [dbo].[{tableName}] ([Id]\r\n");
            result.Append($"                                ,[SessionId]\r\n");
            result.Append($"                                ,[IsConfirmed]\r\n");
            result.Append($"                                ,[CreatedAt]\r\n");
            result.Append($"                                ,[CreatedBy])\r\n");
            result.Append($"                            VALUES (@TransactionId\r\n");
            result.Append($"                                   ,@SessionId\r\n");
            result.Append($"                                   ,NULL\r\n");
            result.Append($"                                   ,GETDATE()\r\n");
            result.Append($"                                   ,@UserName)\r\n");
            AppendIdentityInsertOff(result, tableName, "    ");
            result.Append($"    SET @ReturnValue = @TransactionId\r\n");
            result.Append($"\r\n");
            result.Append($"    RETURN 0\r\n");
            result.Append($"END\r\n");
            result.Append($"GO\r\n");

            return result;
        }

        private static StringBuilder GetScriptTransactions(TDataRows tables, string systemName, string databaseName)
        {
            var result = new StringBuilder();
            var alias = GetTransactionTableAlias(tables);
            var transactionTable = RequireRow(tables, row => string.Equals(Settings.ToString(row["Name"]), "Transactions", StringComparison.OrdinalIgnoreCase),
                "Tabela Transactions não encontrada nos metadados.");
            var createProcedure = $"[dbo].[{BuildAliasProcedure(alias, "create")}]";
            var commitProcedure = $"[dbo].[{BuildAliasProcedure(alias, "commit")}]";
            var rollbackProcedure = $"[dbo].[{BuildAliasProcedure(alias, "rollback")}]";

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar function [dbo].[IS_EQUAL]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.IS_EQUAL.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure {createProcedure}\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(GetScriptAliasCreate(transactionTable, systemName, databaseName).ToString());
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure {commitProcedure}\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(LoadRenamedProcedureScript("dbo.TransactionCommit.sql", "TransactionCommit", "dbo", alias, "commit"));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure {rollbackProcedure}\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(LoadRenamedProcedureScript("dbo.TransactionRollback.sql", "TransactionRollback", "dbo", alias, "rollback"));

            return result;
        }
        private static StringBuilder GetScriptCreateTable(DataRow table, TDataRows columns, TDataRows indexes, TDataRows indexkeys, TDataRows domains, TDataRows types)
        {
            var result = new StringBuilder();
            var columnRows = GetTableColumnRows(columns, table);
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            var tableName = TableName(table);
            RequireNotEmpty(columnRows, $"Tabela '{tableName}' não possui colunas cadastradas em Columns.");
            RequireNotEmpty(physicalColumnRows, $"Tabela '{tableName}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{tableName}' deve ter ao menos uma coluna 'primary key'.");
            ValidateAutoIncrementPrimaryKeyRules(tableName, physicalColumnRows, primaryColumns);

            if (columnRows.Count > 0)
            {
                var firstTime = true;
                var isListable = false;

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF (SELECT object_id('[dbo].[{table["Name"]}]', 'U')) IS NOT NULL\r\n");
                result.Append($"    DROP TABLE [dbo].[{table["Name"]}]\r\n");

                foreach (DataRow column in physicalColumnRows)
                {
                    var constraints = GetConstraints(column, domains, types);
                    string definition;
                    if (Settings.ToString(table["Name"]).Equals("Operations", StringComparison.OrdinalIgnoreCase)
                        && Settings.ToString(column["Name"]).Equals("ActualRecord", StringComparison.OrdinalIgnoreCase))
                        definition = $"[{column["Name"]}] {column["#DataType"]} NULL";
                    else
                        definition = BuildColumnDefinition(column, constraints);

                    if (firstTime)
                    {
                        result.Append($"CREATE TABLE [dbo].[{table["Name"]}]({definition}\r\n");
                        firstTime = false;
                    }
                    else if (ReservedColumnNames.Contains($"{Settings.ToString(column["Name"])}"))
                        throw new Exception($"Nome de coluna {column["Name"]} é reservado.");
                    else
                    {
                        var message = $"Coluna definida na tabela '{table["Name"]}' ";

                        if (Settings.ToBoolean(column["IsListable"]))
                        {
                            if (isListable)
                                throw new Exception(message + " não devem ter mais de uma coluna listável.");
                            if (!Settings.ToString(column["#CategoryName"]).Equals("string"))
                                throw new Exception(message + " devem ser de categoria 'string'.");
                            isListable = true;
                        }

                        result.Append($"                                    ,{definition}\r\n");
                    }
                }
                result.Append($"                                    ,[CreatedAt] datetime NOT NULL\r\n");
                result.Append($"                                    ,[CreatedBy] nvarchar(25) NOT NULL\r\n");
                result.Append($"                                    ,[UpdatedAt] datetime NULL\r\n");
                result.Append($"                                    ,[UpdatedBy] nvarchar(25) NULL\r\n");
                result.Append($"                                    ,[ClientId] bigint NOT NULL DEFAULT 1\r\n");
                result.Append($"                                    ,[UniqueIdentifier] nvarchar(40) NOT NULL DEFAULT NEWID())\r\n");
                result.Append($"ALTER TABLE [dbo].[{table["Name"]}] ADD CONSTRAINT PK_{table["Name"]} PRIMARY KEY CLUSTERED ({string.Join(", ", primaryColumns.Select(row => $"[{row["Name"]}]"))})\r\n");

                var indexRows = indexes.FindAll(index => Settings.ToLong(index["TableId"]) == Settings.ToLong(table["Id"]));

                if (indexRows.Count > 0)
                {
                    foreach (var index in indexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => Settings.ToLong(indexkey["IndexId"]) == Settings.ToLong(index["Id"]));
                        if (indexkeyRows.Count == 0)
                            throw new Exception($"Índice '{index["Name"]}' da tabela '{tableName}' não possui colunas em Indexkeys.");

                        if (indexkeyRows.Count > 0)
                        {
                            firstTime = true;
                            foreach (var indexkey in indexkeyRows)
                            {
                                var column = RequireRow(columns, item => Settings.ToLong(item["Id"]) == Settings.ToLong(indexkey["ColumnId"]),
                                    $"Indexkeys referencia ColumnId {indexkey["ColumnId"]} inexistente em Columns.");
                                if (IsVirtualColumn(column))
                                    throw new Exception($"Índice '{index["Name"]}' da tabela '{table["Name"]}' referencia coluna virtual '{column["Name"]}'.");
                                var definition = $"[{column["Name"]}] {(Settings.ToBoolean(indexkey["IsDescending"]) ? "DESC" : "ASC")}";

                                if (firstTime)
                                {
                                    var isUnique = Settings.ToBoolean(index["IsUnique"]);

                                    result.Append($"CREATE {(isUnique ? "UNIQUE" : "")} INDEX [{index["Name"]}] ON [dbo].[{table["Name"]}]([ClientId] ASC, {definition}");
                                    firstTime = false;
                                }
                                else
                                    result.Append($", {definition}");
                            }
                            if (firstTime)
                                throw new Exception($"Índice '{index["Name"]}' da tabela '{table["Name"]}' não possui colunas físicas.");
                            result.Append($")\r\n");
                        }
                    }
                    result.Append($"CREATE UNIQUE INDEX [UNQ_{table["Name"]}_UniqueIdentifier] ON [dbo].[{table["Name"]}]([UniqueIdentifier] ASC)\r\n");
                    result.Append($"GO\r\n");
                }
            }

            return result;
        }
        private static StringBuilder GetScriptReferences(TDataRows tables, TDataRows columns)
        {
            var result = new StringBuilder();
            var lastTableName = string.Empty;
            var foreignColumns = columns.FindAll(column => Settings.ToString(column["ReferenceTableId"]) != string.Empty && !IsVirtualColumn(column));

            if (foreignColumns.Count > 0)
            {
                foreach (var foreign in foreignColumns)
                {
                    var primaryTable = RequireRow(tables, item => Settings.ToLong(item["Id"]) == Settings.ToLong(foreign["TableId"]),
                        $"Columns referencia TableId {foreign["TableId"]} inexistente em Tables.");
                    var foreignTable = RequireRow(tables, item => Settings.ToLong(item["Id"]) == Settings.ToLong(foreign["ReferenceTableId"]),
                        $"Columns referencia ReferenceTableId {foreign["ReferenceTableId"]} inexistente em Tables.");
                    var foreignKeyCandidates = columns.FindAll(column => Settings.ToLong(column["TableId"]) == Settings.ToLong(foreignTable["Id"]) && Settings.ToBoolean(column["IsPrimarykey"]));
                    if (foreignKeyCandidates.Count == 0)
                        throw new Exception($"Tabela referenciada '{foreignTable["Name"]}' não possui primary key para FK de '{foreign["Name"]}'.");
                    if (foreignKeyCandidates.Count > 1)
                        throw new Exception($"FK '{primaryTable["Name"]}_{foreignTable["Name"]}' não suporta primary key composta na tabela '{foreignTable["Name"]}'.");
                    var foreignKey = foreignKeyCandidates[0];
                    var foreignName = $"FK_{primaryTable["Name"]}_{foreignTable["Name"]}";

                    if (primaryTable["Name"].ToString() != lastTableName)
                    {
                        result.Append($"/**********************************************************************************\r\n");
                        result.Append($"Criar referências de [dbo].[{primaryTable["Name"]}]\r\n");
                        result.Append($"**********************************************************************************/\r\n");
                        lastTableName = primaryTable["Name"].ToString();
                    }
                    result.Append($"IF EXISTS(SELECT 1 FROM [sys].[foreign_keys] WHERE [name] = '{foreignName}')\r\n");
                    result.Append($"    ALTER TABLE [dbo].[{primaryTable["Name"]}] DROP CONSTRAINT {foreignName}\r\n");
                    result.Append($"GO\r\n");
                    result.Append($"ALTER TABLE [dbo].[{primaryTable["Name"]}] WITH CHECK \r\n");
                    result.Append($"    ADD CONSTRAINT [{foreignName}] \r\n");
                    result.Append($"    FOREIGN KEY([{foreign["Name"]}]) \r\n");
                    result.Append($"    REFERENCES [dbo].[{foreignTable["Name"]}] ([{foreignKey["Name"]}])\r\n");
                    result.Append($"GO\r\n");
                    result.Append($"ALTER TABLE [dbo].[{primaryTable["Name"]}] CHECK CONSTRAINT [{foreignName}]\r\n");
                    result.Append($"GO\r\n");
                }
            }

            return result;
        }
        private static bool IsUnicodeSqlType(string? dataType) =>
            !string.IsNullOrWhiteSpace(dataType)
            && dataType.TrimStart().StartsWith("n", StringComparison.OrdinalIgnoreCase);

        private static string FormatSqlCast(string literal, string dataType)
        {
            var escaped = literal.Replace("'", "''");
            var prefix = IsUnicodeSqlType(dataType) ? "N" : "";
            return $"CAST({prefix}'{escaped}' AS {dataType})";
        }

        private static StringBuilder GetScriptInsertTable(DataRow table, TDataRows columns, TDataRows dataRows)
        {
            var result = new StringBuilder();

            if (dataRows.Count > 0)
            {
                var columnRows = GetTableColumnRows(columns, table, physicalOnly: true);
                var primaryColumns = GetPrimaryKeyColumnRows(columnRows);
                RequireNotEmpty(columnRows, $"Tabela '{TableName(table)}' possui dados no Excel, mas não possui colunas físicas em Columns.");

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Inserir dados na tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                if (HasAutoIncrementPrimaryKey(primaryColumns))
                    AppendIdentityInsertOn(result, Settings.ToString(table["Name"]), string.Empty);
                    foreach (var data in dataRows)
                    {
                        var firstTime = true;

                        foreach (var column in columnRows)
                        {
                            if (firstTime)
                            {
                                result.Append($"INSERT INTO [dbo].[{table["Name"]}] ([{column["Name"]}]\r\n");
                                firstTime = false;
                            }
                            else
                                result.Append($"                                ,[{column["Name"]}]\r\n");
                        }
                        result.Append($"                                ,[CreatedAt]\r\n");
                        result.Append($"                                ,[CreatedBy]\r\n");
                        result.Append($"                                ,[UpdatedAt]\r\n");
                        result.Append($"                                ,[UpdatedBy])\r\n");
                        firstTime = true;
                        foreach (var column in columnRows)
                        {
                            var categoryName = Settings.ToString(column["#CategoryName"]);
                            var columnName = Settings.ToString(column["Name"]);
                            dynamic? value = data[columnName];

                            if (categoryName == "numeric")
                                value ??= null;
                            else if (categoryName == "boolean")
                                value = Settings.IsNull(value) ? null : value ? 1 : 0;
                            if ((value = Settings.ToString(value)) == string.Empty)
                                value = "NULL";
                            else if (categoryName == "undefined")
                            value = FormatSqlCast(Settings.ToString(value), Settings.ToString(data["#DataType"]));
                            else
                            value = FormatSqlCast(Settings.ToString(value), Settings.ToString(column["#DataType"]));
                            if (firstTime)
                            {
                                result.Append($"                         VALUES ({value}");
                                firstTime = false;
                            }
                            else
                            {
                                result.Append("\r\n");
                                result.Append($"                                ,{value}");
                            }
                        }
                        result.Append($"\r\n");
                        result.Append($"                                ,GETDATE()\r\n");
                        result.Append($"                                ,'crudex'\r\n");
                        result.Append($"                                ,NULL\r\n");
                        result.Append($"                                ,NULL)\r\n");
                        result.Append($"GO\r\n");
                    }
                if (HasAutoIncrementPrimaryKey(primaryColumns))
                    AppendIdentityInsertOff(result, Settings.ToString(table["Name"]), string.Empty);
            }

            return result;
        }
        private static void AppendLoginCall(StringBuilder result, string sessionIdVariable)
        {
            result.Append($"    DECLARE @LoginReturn BIGINT\r\n");
            result.Append($"\r\n");
            result.Append($"    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT\r\n");
            result.Append($"    SET {sessionIdVariable} = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)\r\n");
            result.Append($"    IF {sessionIdVariable} IS NULL\r\n");
            result.Append($"        THROW 51000, 'SessionId é requerido', 1\r\n");
            result.Append($"\r\n");
        }
        private static StringBuilder GetScriptPersistTable(DataRow table, TDataRows columns, string systemName, string databaseName)
        {
            var result = new StringBuilder();
            var columnRows = GetTableColumnRows(columns, table);
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            RequireNotEmpty(physicalColumnRows, $"Tabela '{TableName(table)}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{TableName(table)}' deve ter ao menos uma coluna 'primary key'.");

            if (physicalColumnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Persist]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Persist]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Persist] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Alias"]}Persist](@Login NVARCHAR(MAX)\r\n");
                result.Append($"                                              ,@TransactionId BIGINT\r\n");
                result.Append($"                                              ,@Action NVARCHAR(15)\r\n");
                result.Append($"                                              ,@LastRecord NVARCHAR(max)\r\n");
                result.Append($"                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN\r\n");
                result.Append($"    DECLARE @ErrorMessage NVARCHAR(255)\r\n");
                result.Append($"\r\n");
                result.Append($"    SET NOCOUNT ON\r\n");
                result.Append($"    SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"    DECLARE @SessionId BIGINT\r\n");
                result.Append($"           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))\r\n");
                AppendLoginCall(result, "@SessionId");
                result.Append($"    DECLARE @OperationId BIGINT\r\n");
                result.Append($"               ,@CreatedBy NVARCHAR(25)\r\n");
                result.Append($"               ,@ActionAux NVARCHAR(15)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                foreach (var column in primaryColumns)
                    result.Append($"               ,{PkVariableName(column)} {column["#DataType"]}\r\n");
                result.Append($"\r\n");
                result.Append($"    IF @Action = 'delete' BEGIN\r\n");
                AppendPrimaryKeyVariableAssignments(result, primaryColumns, "@LastRecord", "        ");
                result.Append($"    END ELSE BEGIN\r\n");
                AppendPrimaryKeyVariableAssignments(result, primaryColumns, "@ActualRecord", "        ");
                result.Append($"    END\r\n");
                AppendResolveCreateId(result, table, primaryColumns, systemName, databaseName);
                result.Append($"    EXEC @TransactionId = [dbo].[{table["Alias"]}Validate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        SELECT @OperationId = [Id]\r\n");
                result.Append($"              ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"              ,@ActionAux = [Action]\r\n");
                result.Append($"              ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                  AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                result.Append($"                  AND ");
                AppendPrimaryKeyJsonMatchClause(result, primaryColumns, "ISNULL([ActualRecord], [LastRecord])");
                result.Append($"\r\n");
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                AppendNewOperationIdCall(result, systemName, databaseName, "@OperationId");
                AppendIdentityInsertOn(result, "Operations", "            ");
                result.Append($"            INSERT INTO [dbo].[Operations] ([Id]\r\n");
                result.Append($"                                             ,[TransactionId]\r\n");
                result.Append($"                                             ,[TableName]\r\n");
                result.Append($"                                             ,[Action]\r\n");
                result.Append($"                                             ,[LastRecord]\r\n");
                result.Append($"                                             ,[ActualRecord]\r\n");
                result.Append($"                                             ,[IsConfirmed]\r\n");
                result.Append($"                                             ,[CreatedAt]\r\n");
                result.Append($"                                             ,[CreatedBy])\r\n");
                result.Append($"                                       VALUES(@OperationId\r\n");
                result.Append($"                                             ,@TransactionId\r\n");
                result.Append($"                                             ,'{table["Name"]}'\r\n");
                result.Append($"                                             ,@Action\r\n");
                result.Append($"                                             ,@LastRecord\r\n");
                result.Append($"                                             ,@ActualRecord\r\n");
                result.Append($"                                             ,NULL\r\n");
                result.Append($"                                             ,GETDATE()\r\n");
                result.Append($"                                             ,@UserName)\r\n");
                AppendIdentityInsertOff(result, "Operations", "            ");
                result.Append($"        END ELSE IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        ELSE IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");
                result.Append($"        ELSE IF @ActionAux = 'delete'\r\n");
                result.Append($"            THROW 51000, 'Registro excluído nesta transação', 1\r\n");
                result.Append($"        ELSE IF @Action = 'create'\r\n");
                result.Append($"            UPDATE [dbo].[Operations]\r\n");
                result.Append($"                SET [ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        ELSE IF @Action = 'update' BEGIN\r\n");
                result.Append($"            IF @ActionAux = 'create'\r\n");
                result.Append($"                EXEC [dbo].[{table["Alias"]}Validate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord\r\n");
                result.Append($"            UPDATE [dbo].[Operations]\r\n");
                result.Append($"                SET [ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END\r\n");
                result.Append($"        ELSE IF @ActionAux = 'create'\r\n");
                result.Append($"            UPDATE [dbo].[Operations] \r\n");
                result.Append($"                SET [IsConfirmed] = 0\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        ELSE\r\n");
                result.Append($"            UPDATE [dbo].[Operations]\r\n");
                result.Append($"                SET [Action] = 'delete'\r\n");
                result.Append($"                   ,[LastRecord] = @LastRecord\r\n");
                result.Append($"                   ,[ActualRecord] = NULL\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"\r\n");
                result.Append($"    RETURN CAST(@OperationId AS BIGINT)\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static void AppendWorkColumnVariables(StringBuilder result, TDataRows columnRows, bool skipPrimaryKey = true)
        {
            var firstTime = true;

            foreach (var column in columnRows)
            {
                if (IsVirtualColumn(column))
                    continue;
                if (skipPrimaryKey && Settings.ToBoolean(column["IsPrimarykey"]))
                    continue;

                if (firstTime)
                {
                    result.Append($"        DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                    firstTime = false;
                }
                else
                    result.Append($"               ,@W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
            }
            if (!firstTime)
                result.Append($"\r\n");
        }
        private static void AppendOperationSubProcedureHeader(StringBuilder result, DataRow table, TDataRows primaryColumns, string procedureSuffix, string expectedAction)
            {
                result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[{table["Alias"]}{procedureSuffix}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
            result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}{procedureSuffix}]', 'P')) IS NULL\r\n");
            result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}{procedureSuffix}] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
            result.Append($"ALTER PROCEDURE [dbo].[{table["Alias"]}{procedureSuffix}](@Login NVARCHAR(MAX)\r\n");
                result.Append($"                                             ,@OperationId BIGINT) AS BEGIN\r\n");
            result.Append($"    DECLARE @ErrorMessage NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
            result.Append($"    SET NOCOUNT ON\r\n");
            result.Append($"    SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
            result.Append($"    DECLARE @SessionId BIGINT\r\n");
            result.Append($"           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))\r\n");
            AppendLoginCall(result, "@SessionId");
            result.Append($"    DECLARE @TransactionId BIGINT\r\n");
                result.Append($"               ,@TransactionIdAux BIGINT\r\n");
                result.Append($"               ,@TableName NVARCHAR(25)\r\n");
                result.Append($"               ,@Action NVARCHAR(15)\r\n");
                result.Append($"               ,@CreatedBy NVARCHAR(25)\r\n");
                result.Append($"               ,@LastRecord NVARCHAR(max)\r\n");
                result.Append($"               ,@ActualRecord NVARCHAR(max)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"\r\n");
            result.Append($"    IF @OperationId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @OperationId requerido', 1\r\n");
                result.Append($"        SELECT @TransactionId = [TransactionId]\r\n");
                result.Append($"               ,@TableName = [TableName]\r\n");
                result.Append($"               ,@Action = [Action]\r\n");
                result.Append($"               ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"               ,@LastRecord = [LastRecord]\r\n");
                result.Append($"               ,@ActualRecord = [ActualRecord]\r\n");
                result.Append($"               ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [Id] = @OperationId\r\n");
                result.Append($"        IF @@ROWCOUNT = 0\r\n");
                result.Append($"            THROW 51000, 'Operação inexistente', 1\r\n");
                result.Append($"        IF @TableName <> '{table["Name"]}'\r\n");
                result.Append($"            THROW 51000, 'Tabela da operação é inválida', 1\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
            result.Append($"            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");
            result.Append($"        IF @Action <> '{expectedAction}'\r\n");
            result.Append($"            THROW 51000, 'Ação da operação é inválida para {procedureSuffix}', 1\r\n");
            result.Append($"        EXEC @TransactionIdAux = [dbo].[{table["Alias"]}Validate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        IF @TransactionId <> @TransactionIdAux\r\n");
                result.Append($"            THROW 51000, 'Transação da operação é inválida', 1\r\n");
            AppendPrimaryKeyVariableDeclarations(result, primaryColumns, expectedAction == "delete" ? "@LastRecord" : "@ActualRecord", "        ");
        }
        private static void AppendOperationSubProcedureFooter(StringBuilder result)
        {
            result.Append($"        UPDATE [dbo].[Operations]\r\n");
            result.Append($"            SET [IsConfirmed] = 1\r\n");
            result.Append($"                ,[UpdatedAt] = GETDATE()\r\n");
            result.Append($"                ,[UpdatedBy] = @UserName\r\n");
            result.Append($"            WHERE [Id] = @OperationId\r\n");
            result.Append("\r\n");
            result.Append($"    RETURN @TransactionId\r\n");
            result.Append($"END\r\n");
            result.Append($"GO\r\n");
        }
        private static StringBuilder GetScriptOperationCreate(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            RequireNotEmpty(physicalColumnRows, $"Tabela '{TableName(table)}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{TableName(table)}' deve ter ao menos uma coluna 'primary key'.");

            if (physicalColumnRows.Count > 0)
            {
                AppendOperationSubProcedureHeader(result, table, primaryColumns, "Create", "create");
                AppendWorkColumnVariables(result, physicalColumnRows);

                var tableName = Settings.ToString(table["Name"]);
                if (HasAutoIncrementPrimaryKey(primaryColumns))
                    AppendIdentityInsertOn(result, tableName, "        ");

                var firstTime = true;
                foreach (var column in physicalColumnRows)
                    {
                        if (firstTime)
                        {
                        result.Append($"        INSERT INTO [dbo].[{table["Name"]}] ([{column["Name"]}]\r\n");
                            firstTime = false;
                        }
                        else
                        result.Append($"                                            ,[{column["Name"]}]\r\n");
                    }
                result.Append($"                                            ,[CreatedAt]\r\n");
                result.Append($"                                            ,[CreatedBy])\r\n");
                firstTime = true;
                foreach (var column in physicalColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"                                      VALUES (@W_{column["Name"]}\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                             ,@W_{column["Name"]}\r\n");
                }
                result.Append($"                                             ,GETDATE()\r\n");
                result.Append($"                                             ,@UserName)\r\n");
                if (HasAutoIncrementPrimaryKey(primaryColumns))
                    AppendIdentityInsertOff(result, tableName, "        ");
                AppendOperationSubProcedureFooter(result);
            }

            return result;
        }
        private static StringBuilder GetScriptOperationUpdate(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            RequireNotEmpty(physicalColumnRows, $"Tabela '{TableName(table)}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{TableName(table)}' deve ter ao menos uma coluna 'primary key'.");

            if (physicalColumnRows.Count > 0)
            {
                AppendOperationSubProcedureHeader(result, table, primaryColumns, "Update", "update");
                AppendWorkColumnVariables(result, physicalColumnRows);

                var firstTime = true;
                foreach (var column in physicalColumnRows)
                {
                    if (Settings.ToBoolean(column["IsAutoIncrement"]))
                        continue;
                    if (firstTime)
                    {
                        result.Append($"        UPDATE [dbo].[{table["Name"]}] SET [{column["Name"]}] = @W_{column["Name"]}\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                          ,[{column["Name"]}] = @W_{column["Name"]}\r\n");
                }
                result.Append($"                                          ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                                          ,[UpdatedBy] = @UserName\r\n");
                result.Append($"            WHERE ");
                AppendPrimaryKeyWhereClause(result, primaryColumns, string.Empty, "@W_", firstConditionPrefix: string.Empty);
                result.Append($"\r\n");
                AppendOperationSubProcedureFooter(result);
            }

            return result;
        }
        private static StringBuilder GetScriptOperationDelete(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            RequireNotEmpty(physicalColumnRows, $"Tabela '{TableName(table)}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{TableName(table)}' deve ter ao menos uma coluna 'primary key'.");

            if (physicalColumnRows.Count > 0)
            {
                AppendOperationSubProcedureHeader(result, table, primaryColumns, "Delete", "delete");
                result.Append($"        DELETE FROM [dbo].[{table["Name"]}] WHERE ");
                AppendPrimaryKeyWhereClause(result, primaryColumns, string.Empty, "@W_", firstConditionPrefix: string.Empty);
                result.Append($"\r\n");
                result.Append($"\r\n");
                AppendOperationSubProcedureFooter(result);
            }

            return result;
        }
        private static StringBuilder GetScriptValidateTable(DataRow table, TDataRows tables, TDataRows columns, TDataRows domains, TDataRows types, TDataRows indexes, TDataRows indexkeys, TDataRows unicities)
        {
            var result = new StringBuilder();
            var columnRows = GetTableColumnRows(columns, table);
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            RequireNotEmpty(columnRows, $"Tabela '{TableName(table)}' não possui colunas cadastradas em Columns.");
            RequireNotEmpty(physicalColumnRows, $"Tabela '{TableName(table)}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{TableName(table)}' deve ter ao menos uma coluna 'primary key'.");

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Validate]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Validate]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Validate] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Alias"]}Validate](@SessionId BIGINT\r\n");
                result.Append($"                                               ,@TransactionId BIGINT\r\n");
                result.Append($"                                               ,@UserName NVARCHAR(25)\r\n");
                result.Append($"                                               ,@Action NVARCHAR(15)\r\n");
                result.Append($"                                               ,@LastRecord NVARCHAR(max)\r\n");
                result.Append($"                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN\r\n");
                result.Append($"    DECLARE @ErrorMessage NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                result.Append($"    SET NOCOUNT ON\r\n");
                result.Append($"    SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"    IF @SessionId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @SessionId é requerido', 1\r\n");
                result.Append($"        IF @UserName IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @UserName é requerido', 1\r\n");
                result.Append($"        IF @Action IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @Action é requerido', 1\r\n");
                result.Append($"        IF @Action NOT IN ('create', 'update', 'delete')\r\n");
                result.Append($"            THROW 51000, 'Valor de @Action é inválido', 1\r\n");
                result.Append($"        IF @Action = 'delete' BEGIN\r\n");
                result.Append($"            IF @LastRecord IS NULL\r\n");
                result.Append($"                THROW 51000, 'Valor de @LastRecord é requerido', 1\r\n");
                result.Append($"            IF ISJSON(@LastRecord) = 0\r\n");
                result.Append($"                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            IF @ActualRecord IS NULL\r\n");
                result.Append($"                THROW 51000, 'Valor de @ActualRecord é requerido', 1\r\n");
                result.Append($"            IF ISJSON(@ActualRecord) = 0\r\n");
                result.Append($"                THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @TransactionId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @TransactionId é requerido', 1\r\n");
                result.Append($"        DECLARE @IsConfirmed BIT\r\n");
                result.Append($"               ,@CreatedBy NVARCHAR(25)\r\n");
                result.Append($"               ,@IsPendingCreate BIT = 0\r\n");
                foreach (var column in primaryColumns)
                    result.Append($"               ,{PkVariableName(column)} {column["#DataType"]}\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @Action = 'delete' BEGIN\r\n");
                AppendPrimaryKeyVariableAssignments(result, primaryColumns, "@LastRecord", "            ");
                result.Append($"        END ELSE BEGIN\r\n");
                AppendPrimaryKeyVariableAssignments(result, primaryColumns, "@ActualRecord", "            ");
                result.Append($"        END\r\n");
                result.Append($"        SELECT @IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"              ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"            FROM [dbo].[Transactions]\r\n");
                result.Append($"            WHERE [Id] = @TransactionId\r\n");
                result.Append($"                  AND [SessionId] = @SessionId\r\n");
                result.Append($"        IF @@ROWCOUNT = 0\r\n");
                result.Append($"            THROW 51000, 'Transação inexistente', 1\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1;\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");

                foreach (var column in primaryColumns)
                {
                    var columnName = Settings.ToString(column["Name"]);
                    result.Append($"        IF {PkVariableName(column)} IS NULL BEGIN\r\n");
                    result.Append($"            SET @ErrorMessage = 'Valor de {columnName} em @ActualRecord é requerido.';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                    var constraints = GetConstraints(column, domains, types);
                if (constraints.TryGetValue("Minimum", out dynamic? value))
                {
                        result.Append($"        IF {PkVariableName(column)} < CAST('{value}' AS {column["#DataType"]})\r\n");
                        result.Append($"            THROW 51000, 'Valor de {columnName} em @ActualRecord deve ser maior que ou igual a {value}', 1\r\n");
                }
                if (constraints.TryGetValue("Maximum", out value))
                {
                        result.Append($"        IF {PkVariableName(column)} > CAST('{value}' AS {column["#DataType"]})\r\n");
                        result.Append($"            THROW 51000, 'Valor de {columnName} em @ActualRecord deve ser menor que ou igual a {value}', 1\r\n");
                    }
                }
                result.Append($"        IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                AppendPrimaryKeyWhereClause(result, primaryColumns, string.Empty, "@W_", firstConditionPrefix: string.Empty);
                result.Append(") AND @Action = 'create'\r\n");
                result.Append($"            THROW 51000, 'Chave-primária já existe em {table["Name"]}', 1\r\n");
                result.Append($"        ELSE IF @Action = 'delete' AND EXISTS(SELECT 1\r\n");
                result.Append($"                                    FROM [dbo].[Operations]\r\n");
                result.Append($"                                    WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                                          AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                                          AND [IsConfirmed] IS NULL\r\n");
                result.Append($"                                          AND [Action] = 'create'\r\n");
                result.Append($"                                          AND ");
                AppendPrimaryKeyJsonMatchClause(result, primaryColumns, "ISNULL([ActualRecord], [LastRecord])", linePrefix: "                                          ");
                result.Append($")\r\n");
                result.Append($"            SET @IsPendingCreate = 1\r\n");
                result.Append($"        ELSE IF @Action <> 'create' AND NOT EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                AppendPrimaryKeyWhereClause(result, primaryColumns, string.Empty, "@W_", firstConditionPrefix: string.Empty);
                result.Append(")\r\n");
                result.Append($"            THROW 51000, 'Chave-primária não existe em {table["Name"]}', 1\r\n");
                result.Append($"        IF @Action <> 'create' AND @IsPendingCreate = 0 BEGIN\r\n");
                result.Append($"            IF @LastRecord IS NULL\r\n");
                result.Append($"                THROW 51000, 'Valor de @LastRecord é requerido', 1\r\n");
                result.Append($"            IF ISJSON(@LastRecord) = 0\r\n");
                result.Append($"                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1\r\n");

                var firstTime = true;
                foreach (var column in physicalColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            IF NOT EXISTS(SELECT 1\r\n");
                        result.Append($"                            FROM [dbo].[{table["Name"]}]\r\n");
                        result.Append($"                            WHERE ");
                        firstTime = false;
                    }
                    else
                    {
                        result.Append($"\r\n");
                        result.Append($"                                  AND ");
                    }
                    if (Settings.ToBoolean(column["IsRequired"]))
                        result.Append($"[{column["Name"]}] = JSON_VALUE(@LastRecord, '$.{column["Name"]}')");
                    else
                        result.Append($"[dbo].[IS_EQUAL]([{column["Name"]}], JSON_VALUE(@LastRecord, '$.{column["Name"]}'), '{column["#TypeName"]}') = 1");
                }
                result.Append($")\r\n");
                firstTime = true;
                foreach (var column in physicalColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            AND NOT EXISTS(SELECT 1\r\n");
                        result.Append($"                            FROM [dbo].[Operations]\r\n");
                        result.Append($"                            WHERE [TransactionId] = @TransactionId\r\n");
                        result.Append($"                                  AND [TableName] = '{table["Name"]}'\r\n");
                        result.Append($"                                  AND [IsConfirmed] IS NULL\r\n");
                        result.Append($"                                  AND ");
                        firstTime = false;
                    }
                    else
                    {
                        result.Append($"\r\n");
                        result.Append($"                                  AND ");
                    }
                    if (Settings.ToBoolean(column["IsRequired"]))
                        result.Append($"JSON_VALUE(ISNULL([ActualRecord], [LastRecord]), '$.{column["Name"]}') = JSON_VALUE(@LastRecord, '$.{column["Name"]}')");
                    else
                        result.Append($"[dbo].[IS_EQUAL](JSON_VALUE(ISNULL([ActualRecord], [LastRecord]), '$.{column["Name"]}'), JSON_VALUE(@LastRecord, '$.{column["Name"]}'), '{column["#TypeName"]}') = 1");
                }
                result.Append($")\r\n");
                result.Append($"                THROW 51000, 'Registro de {table["Name"]} alterado por outro usuário', 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"\r\n");

                var referenceRows = columns.FindAll(column => Settings.ToLong(column["ReferenceTableId"]) == Settings.ToLong(table["Id"]));

                if (referenceRows.Count > 0)
                {
                    result.Append($"        IF @Action = 'delete' BEGIN\r\n");
                    foreach (var reference in referenceRows)
                    {
                        result.Append($"            IF EXISTS(SELECT 1 FROM [dbo].[{reference["#TableName"]}] WHERE [{reference["Name"]}] = {PkVariableName(primaryColumns[0])})\r\n");
                        result.Append($"                THROW 51000, 'Chave-primária referenciada em {reference["#TableName"]}', 1\r\n");
                    }
                    result.Append($"        END\r\n");
                }
                result.Append($"        IF @Action IN ('create', 'update') BEGIN\r\n");
                result.Append($"\r\n");

                var nopkColumnRows = physicalColumnRows.FindAll(column => !Settings.ToBoolean(column["IsPrimarykey"]));

                firstTime = true;
                foreach (var column in nopkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                   ,@W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                }
                result.Append($"\r\n");
                foreach (var column in nopkColumnRows)
                {
                    var validations = GetConstraints(column, domains, types);
                    var isRequired = Settings.ToBoolean(column["IsRequired"]);

                    if (isRequired)
                    {
                        result.Append($"            IF @W_{column["Name"]} IS NULL\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord é requerido.', 1\r\n");
                    }
                    if (validations.TryGetValue("Minimum", out dynamic? constraintValue))
                    {
                        result.Append($"            IF {(isRequired ? string.Empty : $"@W_{column["Name"]} IS NOT NULL AND ")}@W_{column["Name"]} < CAST('{constraintValue}' AS {column["#DataType"]})\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord deve ser maior que ou igual a {constraintValue}', 1\r\n");
                    }
                    if (validations.TryGetValue("Maximum", out constraintValue))
                    {
                        result.Append($"            IF {(isRequired ? string.Empty : $"@W_{column["Name"]} IS NOT NULL AND ")}@W_{column["Name"]} > CAST('{constraintValue}' AS {column["#DataType"]})\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord deve ser menor que ou igual a {constraintValue}', 1\r\n");
                    }
                    if (!Settings.IsNull(column["ReferenceTableId"]))
                    {
                        var referenceTable = RequireRow(tables, item => Settings.ToLong(item["Id"]) == Settings.ToLong(column["ReferenceTableId"]),
                            $"Columns referencia ReferenceTableId {column["ReferenceTableId"]} inexistente em Tables.");
                        var fkVariable = $"@W_{column["Name"]}";
                        var existsPrefix = isRequired ? string.Empty : $"{fkVariable} IS NOT NULL AND ";

                        result.Append($"            IF {existsPrefix}NOT EXISTS(SELECT 1 FROM [dbo].[{referenceTable["Name"]}] WHERE [Id] = {fkVariable})\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord inexiste em {referenceTable["Name"]}', 1\r\n");
                    }
                }
                var uniqueRows = unicities.FindAll(unique => Settings.ToLong(unique["#TableId1"]) == Settings.ToLong(table["Id"]) ||
                                                           (Settings.ToBoolean(unique["IsBidirectional"]) &&
                                                            Settings.ToLong(unique["#TableId2"]) == Settings.ToLong(table["Id"])));
                var uniqueIndexRows = indexes.FindAll(index => Settings.ToLong(index["TableId"]) == Settings.ToLong(table["Id"]) && Settings.ToBoolean(index["IsUnique"]));

                if (uniqueIndexRows.Count > 0 || uniqueRows.Count > 0)
                {
                    var firstUpdateUniqueCheck = true;
                    result.Append($"            IF @Action = 'create' BEGIN\r\n");
                    foreach (var index in uniqueIndexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => Settings.ToLong(indexkey["IndexId"]) == Settings.ToLong(index["Id"]));
                        if (indexkeyRows.Count == 0)
                            throw new Exception($"Índice único '{index["Name"]}' da tabela '{table["Name"]}' não possui colunas em Indexkeys.");

                        firstTime = true;
                        foreach (var indexkey in indexkeyRows)
                        {
                            var column = RequireRow(columns, item => Settings.ToLong(item["Id"]) == Settings.ToLong(indexkey["ColumnId"]),
                                $"Indexkeys referencia ColumnId {indexkey["ColumnId"]} inexistente em Columns.");
                            if (IsVirtualColumn(column))
                                throw new Exception($"Índice único '{index["Name"]}' da tabela '{table["Name"]}' referencia coluna virtual '{column["Name"]}'.");

                            if (firstTime)
                            {
                                result.Append($"                IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                firstTime = false;
                            }
                            else
                                result.Append($" AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
                        if (firstTime)
                            throw new Exception($"Índice único '{index["Name"]}' da tabela '{table["Name"]}' não possui colunas físicas.");
                        result.Append($")\r\n");
                        result.Append($"                    THROW 51000, 'Chave única de {index["Name"]} já existe', 1\r\n");
                    }
                    foreach (var unique in uniqueRows)
                    {
                        result.Append($"                IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName1"]}] WHERE [{unique["#ColumnName1"]}] = @W_{unique["#ColumnName2"]})\r\n");
                        result.Append($"                    THROW 51000, 'Unicidade cruzada de [{unique["#TableAlias1"]}].[{unique["#ColumnName1"]}] => [{unique["#TableAlias2"]}].[{unique["#ColumnName2"]}] já existe', 1\r\n");
                        if (Settings.ToBoolean(unique["IsBidirectional"]))
                        {
                            result.Append($"                IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName2"]}] WHERE [{unique["#ColumnName2"]}] = @W_{unique["#ColumnName1"]})\r\n");
                            result.Append($"                    THROW 51000, 'Unicidade cruzada de [{unique["#TableAlias2"]}].[{unique["#ColumnName2"]}] => [{unique["#TableAlias1"]}].[{unique["#ColumnName1"]}] já existe', 1\r\n");
                        }
                    }
                    foreach (var index in uniqueIndexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => Settings.ToLong(indexkey["IndexId"]) == Settings.ToLong(index["Id"]));
                        if (indexkeyRows.Count == 0)
                            throw new Exception($"Índice único '{index["Name"]}' da tabela '{table["Name"]}' não possui colunas em Indexkeys.");

                        firstTime = true;
                        foreach (var indexkey in indexkeyRows)
                        {
                            var column = RequireRow(columns, item => Settings.ToLong(item["Id"]) == Settings.ToLong(indexkey["ColumnId"]),
                                $"Indexkeys referencia ColumnId {indexkey["ColumnId"]} inexistente em Columns.");
                            if (IsVirtualColumn(column))
                                throw new Exception($"Índice único '{index["Name"]}' da tabela '{table["Name"]}' referencia coluna virtual '{column["Name"]}'.");

                            if (firstTime)
                            {
                                if (firstUpdateUniqueCheck)
                                {
                                    result.Append($"            END ELSE IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                    firstUpdateUniqueCheck = false;
                                }
                                else
                                result.Append($"            ELSE IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                firstTime = false;
                            }
                            else
                                result.Append($" AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
                        if (firstTime)
                            throw new Exception($"Índice único '{index["Name"]}' da tabela '{table["Name"]}' não possui colunas físicas.");
                        result.Append($" AND ");
                        AppendPrimaryKeyExcludeCurrentRow(result, primaryColumns, string.Empty, "@W_", string.Empty);
                        result.Append($") \r\n");
                        result.Append($"                THROW 51000, 'Chave única de {index["Name"]} já existe', 1\r\n");
                    }
                    foreach (var unique in uniqueRows)
                    {
                        if (firstUpdateUniqueCheck)
                        {
                            result.Append($"            END ELSE IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName1"]}] WHERE [{unique["#ColumnName1"]}] = @W_{unique["#ColumnName2"]}");
                            firstUpdateUniqueCheck = false;
                        }
                        else
                            result.Append($"            ELSE IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName1"]}] WHERE [{unique["#ColumnName1"]}] = @W_{unique["#ColumnName2"]}");
                        AppendPrimaryKeyExcludeCurrentRow(result, primaryColumns, string.Empty, "@W_", string.Empty);
                        result.Append($") \r\n");
                        result.Append($"                THROW 51000, 'Unicidade cruzada de [{unique["#TableAlias1"]}].[{unique["#ColumnName1"]}] => [{unique["#TableAlias2"]}].[{unique["#ColumnName2"]}] já existe', 1\r\n");
                        if (Settings.ToBoolean(unique["IsBidirectional"]))
                        {
                            result.Append($"            ELSE IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName2"]}] WHERE [{unique["#ColumnName2"]}] = @W_{unique["#ColumnName1"]}");
                            AppendPrimaryKeyExcludeCurrentRow(result, primaryColumns, string.Empty, "@W_", string.Empty);
                            result.Append($") \r\n");
                            result.Append($"                THROW 51000, 'Unicidade cruzada de [{unique["#TableAlias2"]}].[{unique["#ColumnName2"]}] => [{unique["#TableAlias1"]}].[{unique["#ColumnName1"]}] já existe', 1\r\n");
                        }
                    }
                }
                result.Append($"        END\r\n");
                result.Append($"\r\n");
                result.Append($"    RETURN @TransactionId\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static readonly List<long> ProcessedTableIds = [];
        private static StringBuilder GetReferenceQueries(DataRow reference, TDataRows columns, TDictionary tmpNames, string tableName = "#result")
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(reference["ReferenceTableId"]) && !IsVirtualColumn(row));
            var firstTime = true;
            var referenceTableName = Settings.ToString(reference["#ReferenceTableName"]);
            var spaces = "";
            string tmpName;

            if (tmpNames.TryGetValue(referenceTableName, out dynamic? value))
            {
                tmpName = Settings.ToString(value);
                spaces = new string(' ', 4);
            }
            else
                tmpNames.Add(referenceTableName, tmpName = $"#{referenceTableName}");
            ProcessedTableIds.Add(Settings.ToLong(reference["TableId"]));
            foreach (var column in columnRows)
            {
                if (firstTime)
                {
                    if (spaces != "")
                        result.Append($"        INSERT INTO [{tmpName}]\r\n");

                    result.Append($"{spaces}        SELECT DISTINCT '{column["#TableAlias"]}' AS [Kind]\r\n");
                    firstTime = false;
                }
                result.Append($"{spaces}              ,[R].[{column["Name"]}]\r\n");
                AppendReadInWordsColumnFromAlias(result, column, "R", $"{spaces}              ");
            }
            if (spaces == "")
                result.Append($"{spaces}            INTO [{tmpName}]\r\n");
            result.Append($"{spaces}            FROM [{tableName}] [T]\r\n");
            result.Append($"{spaces}                INNER JOIN [dbo].[{referenceTableName}] [R] ON [R].[Id] = [T].[{reference["Name"]}]\r\n");
            if (spaces != "")
                result.Append($"{spaces}            WHERE NOT EXISTS(SELECT 1 FROM [{tmpName}] WHERE [Id] = [R].[Id])\r\n");
            result.Append($"{spaces}            ORDER BY [R].[Id]\r\n");
            if (spaces == "")
                result.Append($"        CREATE UNIQUE INDEX [{tmpName}] ON [{tmpName}](Id)\r\n");

            var subReferences = columns.FindAll(column => !Settings.IsNull(column["ReferenceTableId"]) &&
                                                          Settings.ToLong(column["TableId"]) == Settings.ToLong(reference["ReferenceTableId"]));

            foreach (var subReference in subReferences)
            {
                if (!ProcessedTableIds.Contains(Settings.ToLong(subReference["TableId"])))
                {
                    result.Append(GetReferenceQueries(subReference, columns, tmpNames, tmpName));
                }
            }

            return result;
        }

        private static StringBuilder GetScriptReadTable(DataRow table, TDataRows columns, TDataRows domains, TDataRows types, TDictionary[] comparators, Dictionary<long, List<long>> rulesByCategory)
        {
            var result = new StringBuilder();
            var columnRows = GetTableColumnRows(columns, table);
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var primaryColumns = GetPrimaryKeyColumnRows(physicalColumnRows);
            var listableColumns = columnRows.FindAll(row => Settings.ToBoolean(row["IsListable"]) && !IsVirtualColumn(row));
            DataRow? listableColumn = listableColumns.Count > 0 ? listableColumns[0] : null;
            var defaultOrderBy = BuildDefaultOrderBy(primaryColumns, "T");
            var primaryKeyIndexColumns = BuildPrimaryKeyIndexColumns(primaryColumns);
            var primaryKeyColumnDefinitions = BuildPrimaryKeyColumnDefinitions(primaryColumns);
            var primaryKeyGridFilter = BuildPrimaryKeyGridFilterClause(primaryColumns);
            RequireNotEmpty(columnRows, $"Tabela '{TableName(table)}' não possui colunas cadastradas em Columns.");
            RequireNotEmpty(physicalColumnRows, $"Tabela '{TableName(table)}' não possui colunas físicas em Columns.");
            RequireNotEmpty(primaryColumns, $"Tabela '{TableName(table)}' deve ter ao menos uma coluna 'primary key'.");

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Name"]}Read]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Name"]}Read]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Name"]}Read] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Name"]}Read](@Login NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@Filter NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@Search NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@OrderBy NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@PaddingGridLastPage BIT\r\n");
                result.Append($"                                          ,@IsActionList BIT\r\n");
                result.Append($"                                          ,@PageNumber INT OUT\r\n");
                result.Append($"                                          ,@LimitRows INT OUT\r\n");
                result.Append($"                                          ,@MaxPage INT OUT\r\n");
                result.Append($"                                          ,@ReturnValue BIGINT OUT) AS BEGIN\r\n");
                result.Append($"\r\n");
                result.Append($"    SET NOCOUNT ON\r\n");
                result.Append($"    SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"    DECLARE @SessionId BIGINT\r\n");
                AppendLoginCall(result, "@SessionId");
                result.Append($"        IF @Filter IS NULL\r\n");
                result.Append("            SET @Filter = '{}'\r\n");
                result.Append($"        ELSE IF ISJSON(@Filter) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @Filter não está no formato JSON', 1\r\n");
                result.Append($"        IF @Search IS NULL\r\n");
                result.Append("            SET @Search = '{}'\r\n");
                result.Append($"        ELSE IF ISJSON(@Search) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @Search não está no formato JSON', 1\r\n");
                result.Append($"        SET @OrderBy = TRIM(ISNULL(@OrderBy, ''))\r\n");
                result.Append($"        IF @OrderBy = ''\r\n");
                result.Append($"            SET @OrderBy = '{defaultOrderBy}'\r\n");
                result.Append($"        ELSE BEGIN\r\n");
                result.Append($"            SET @OrderBy = REPLACE(REPLACE(@OrderBy, '[', ''), ']', '')\r\n");
                result.Append($"            IF EXISTS(SELECT 1 \r\n");
                result.Append($"                         FROM (SELECT CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)\r\n");
                result.Append($"                                           WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)\r\n");
                result.Append($"                                           ELSE TRIM([value])\r\n");
                result.Append($"                                      END AS [ColumnName]\r\n");
                result.Append($"                                  FROM STRING_SPLIT(@OrderBy, ',')) AS [O]\r\n");
                result.Append($"                                      LEFT JOIN (SELECT [#1].[name] AS ColumnName\r\n");
                result.Append($"                                                    FROM [sys].[columns] [#1]\r\n");
                result.Append($"                                                        INNER JOIN [sys].[tables] [#2] ON [#1].[object_id] = [#2].[object_id]\r\n");
                result.Append($"                                                    WHERE [#2].[name] = '{table["Name"]}') AS [T] ON [T].[ColumnName] = [O].[ColumnName]\r\n");
                result.Append($"                         WHERE [T].[ColumnName] IS NULL)\r\n");
                result.Append($"                THROW 51000, 'Nome de coluna em @OrderBy é inválido', 1\r\n");
                result.Append($"            SELECT @OrderBy = STRING_AGG('[T].[' + TRIM(CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)\r\n");
                result.Append($"                                                         WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)\r\n");
                result.Append($"                                                         ELSE TRIM([value])\r\n");
                result.Append($"                                                    END) + '] ' + \r\n");
                result.Append($"                                                    CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN 'DESC'\r\n");
                result.Append($"                                                         WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN 'ASC'\r\n");
                result.Append($"                                                         ELSE 'ASC'\r\n");
                result.Append($"                                                    END, ', ')\r\n");
                result.Append($"                FROM STRING_SPLIT(@OrderBy, ',')\r\n");
                result.Append($"        END\r\n");
                if (listableColumn != null)
                {
                    result.Append($"        IF @IsActionList = 1\r\n");
                    result.Append($"            SET @OrderBy = '[T].[{listableColumn["Name"]}] ASC, {defaultOrderBy}'\r\n");
                    result.Append($"        DECLARE @PickerValue {listableColumn["#DataType"]} = NULL\r\n");
                }
                result.Append($"\r\n");
                result.Append($"        DECLARE @TransactionId BIGINT = (SELECT MAX([Id]) FROM [dbo].[Transactions] WHERE [SessionId] = @SessionId)\r\n");
                result.Append($"\r\n");
                result.Append($"        IF NOT EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [Id] = @TransactionId AND [IsConfirmed] IS NULL)\r\n");
                result.Append($"            SET @TransactionId = NULL\r\n");

                var firstTime = true;

                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT [Action] AS [_]\r\n");
                        firstTime = false;
                    }
                    result.Append($"              ,CAST(JSON_VALUE(ISNULL([ActualRecord], [LastRecord]), '$.{column["Name"]}') AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                    AppendReadInWordsColumnFromJson(result, column);
                }
                result.Append($"            INTO [#tmpOperations]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                  AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                result.Append($"        CREATE UNIQUE INDEX [#tmpOperations] ON [#tmpOperations]({primaryKeyIndexColumns})\r\n");
                result.Append($"\r\n");

                var filterableColumns = physicalColumnRows.FindAll(column => Settings.ToBoolean(column["IsFilterable"]));

                result.Append($"        DECLARE @_ NVARCHAR(MAX) = (SELECT STRING_AGG(value, ',') FROM OPENJSON(@Filter, '$._'))\r\n");
                result.Append($"               ,@Where NVARCHAR(MAX) = ''\r\n");
                result.Append($"               ,@ComparatorPredicate NVARCHAR(MAX)\r\n");
                result.Append($"               ,@sql NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                if (filterableColumns.Count > 0)
                {
                firstTime = true;
                foreach (var column in filterableColumns)
                {
                    if (firstTime)
                    {
                            result.Append($"        DECLARE @WT_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@Filter, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                            result.Append($"               ,@WT_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@Filter, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                }
                result.Append($"\r\n");
                foreach (var column in filterableColumns)
                        AppendReadTableFilterColumn(result, column, domains, types, $"@WT_{column["Name"]}", $"@T_{column["Name"]}", "        ");
                }
                if (listableColumn != null)
                {
                    result.Append($"        IF @IsActionList = 1 BEGIN\r\n");
                    result.Append($"            SET @PickerValue = CAST(JSON_VALUE(@Filter, '$.Picker.Value') AS {listableColumn["#DataType"]})\r\n");
                    result.Append($"            IF @PickerValue IS NULL\r\n");
                    result.Append($"                SET @PickerValue = ''\r\n");
                    result.Append($"            SET @Where = @Where + ' AND [T].[{listableColumn["Name"]}] LIKE ''%'' + @PickerValue + ''%'''\r\n");
                    result.Append($"        END ELSE IF @_ IS NULL BEGIN\r\n");
                }
                else
                    result.Append($"        IF @_ IS NULL BEGIN\r\n");

                firstTime = true;
                foreach (var column in filterableColumns)
                {
                    AppendReadGridFilterDeclareVars(result, column, isSearch: false, declare: firstTime, CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types));
                    firstTime = false;
                }
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                foreach (var column in filterableColumns)
                    AppendReadGridFilterAssignVars(result, column, isSearch: false, comparators, rulesByCategory, domains, types);
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                foreach (var column in filterableColumns)
                    AppendReadFilterColumn(result, column, CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types), "            ");
                result.Append($"        END ELSE\r\n");
                result.Append($"            SET @Where = @Where + ' AND {primaryKeyGridFilter}'\r\n");
                result.Append($"\r\n");
                result.Append($"        CREATE TABLE [#tmpTable]([_] CHAR(1), [Recno] BIGINT, {primaryKeyColumnDefinitions})\r\n");
                result.Append($"        SET @sql = 'INSERT [#tmpTable]([_], [Recno], {BuildPrimaryKeyInsertList(primaryColumns)})\r\n");
                result.Append($"                        SELECT [_]\r\n");
                result.Append($"                              ,[Recno]\r\n");
                result.Append($"{BuildPrimaryKeySelectList(primaryColumns, "U")}\r\n");
                result.Append($"                            FROM (SELECT ''T'' AS [_]\r\n");
                result.Append($"                                        ,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS [Recno]\r\n");
                result.Append($"{BuildPrimaryKeySelectList(primaryColumns, "T")}\r\n");
                result.Append($"                                    FROM [dbo].[{table["Name"]}] [T]\r\n");
                result.Append($"                                        LEFT JOIN [#tmpOperations] [#] ON {BuildPrimaryKeyJoinClause(primaryColumns, "T", "#")}\r\n");
                result.Append($"                                    WHERE [#].[{primaryColumns[0]["Name"]}] IS NULL' + @Where + '\r\n");
                result.Append($"                                  UNION ALL\r\n");
                result.Append($"                                  SELECT ''O'' AS [_]\r\n");
                result.Append($"                                        ,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') + (SELECT COUNT(*) FROM [#tmpTable] [#] WHERE [#].[_] = ''T'') AS [Recno]\r\n");
                result.Append($"{BuildPrimaryKeySelectList(primaryColumns, "T")}\r\n");
                result.Append($"                                    FROM [#tmpOperations] [T]\r\n");
                result.Append($"                                    WHERE [T].[_] <> ''delete''' + @Where + ') AS [U]\r\n");
                result.Append($"                            ORDER BY [Recno]'\r\n");

                if (listableColumn != null)
                    result.Append($"        IF @IsActionList = 1 BEGIN\r\n");
                else
                    result.Append($"        IF @_ IS NULL BEGIN\r\n");

                if (listableColumn != null)
                {
                    result.Append($"            EXEC sp_executesql @sql\r\n");
                    if (filterableColumns.Count > 0)
                    {
                        result.Append($"                               ,N'@PickerValue {listableColumn["#DataType"]}");
                foreach (var column in filterableColumns)
                            result.Append($",@T_{column["Name"]} {column["#DataType"]}");
                        result.Append($"'\r\n");
                        result.Append($"                               ,@PickerValue = @PickerValue\r\n");
                        foreach (var column in filterableColumns)
                            result.Append($"                               ,@T_{column["Name"]} = @WT_{column["Name"]}\r\n");
                    }
                    else
                    {
                        result.Append($"                               ,N'@PickerValue {listableColumn["#DataType"]}'\r\n");
                        result.Append($"                               ,@PickerValue = @PickerValue\r\n");
                    }
                    result.Append($"        END ELSE IF @_ IS NULL BEGIN\r\n");
                }

                if (filterableColumns.Count > 0)
                    {
                        result.Append($"            EXEC sp_executesql @sql\r\n");
                    AppendReadExecutesqlParams(result, filterableColumns, includeTableFilters: true, includeGridFilters: true, comparators, rulesByCategory, domains, types, "                               ");
                    AppendReadExecutesqlAssignments(result, filterableColumns, includeTableFilters: true, includeGridFilters: true, comparators, rulesByCategory, domains, types, "                               ");
                    }
                    else
                    result.Append($"            EXEC sp_executesql @sql\r\n");

                result.Append($"        END ELSE BEGIN\r\n");
                if (filterableColumns.Count > 0)
                {
                    result.Append($"            EXEC sp_executesql @sql\r\n");
                    AppendReadExecutesqlParams(result, filterableColumns, includeTableFilters: true, includeGridFilters: false, comparators, rulesByCategory, domains, types, "                               ");
                    AppendReadExecutesqlAssignments(result, filterableColumns, includeTableFilters: true, includeGridFilters: false, comparators, rulesByCategory, domains, types, "                               ");
                }
                else
                result.Append($"            EXEC sp_executesql @sql\r\n");
                result.Append($"        END\r\n");

                result.Append($"\r\n");
                result.Append($"        DECLARE @RowCount INT = @@ROWCOUNT\r\n");
                result.Append($"               ,@OffSet INT\r\n");
                result.Append($"\r\n");
                result.Append($"        CREATE UNIQUE INDEX [#tmpTable] ON [#tmpTable]({primaryKeyIndexColumns})\r\n");
                result.Append($"        IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\r\n");
                result.Append($"            SET @OffSet = 0\r\n");
                result.Append($"            SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END\r\n");
                result.Append($"            SET @PageNumber = 1\r\n");
                result.Append($"            SET @MaxPage = 1\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END\r\n");
                result.Append($"            DECLARE @SearchRecno BIGINT = NULL\r\n");
                result.Append($"            IF EXISTS(SELECT 1 FROM OPENJSON(@Search)) BEGIN\r\n");

                if (filterableColumns.Count > 0)
                {
                    result.Append($"                DECLARE @Recno BIGINT\r\n");
                    foreach (var column in filterableColumns)
                        AppendReadGridFilterDeclareVars(result, column, isSearch: true, declare: false, CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types));
                }
                else
                    result.Append($"                DECLARE @Recno BIGINT\r\n");
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                foreach (var column in filterableColumns)
                    AppendReadGridFilterAssignVars(result, column, isSearch: true, comparators, rulesByCategory, domains, types);
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                result.Append($"                SET @Where = ''\r\n");
                foreach (var column in filterableColumns)
                    AppendReadSearchCondition(result, column, CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types), "                ");
                result.Append($"                IF @Where <> '' BEGIN\r\n");
                result.Append($"                    SET @sql = N'SELECT TOP 1 @r = [#].[Recno]\r\n");
                result.Append($"                                    FROM [#tmpTable] [#]\r\n");
                result.Append($"                                        LEFT JOIN [dbo].[{table["Name"]}] [D] ON {BuildPrimaryKeyJoinClause(primaryColumns, "D", "#")} AND [#].[_] = ''T''\r\n");
                result.Append($"                                        LEFT JOIN [#tmpOperations] [O] ON {BuildPrimaryKeyJoinClause(primaryColumns, "O", "#")} AND [#].[_] = ''O''\r\n");
                result.Append($"                                    WHERE ' + @Where\r\n");
                if (filterableColumns.Count > 0)
                {
                    firstTime = true;
                    foreach (var column in filterableColumns)
                    {
                        var name = column["Name"];
                        var dataType = column["#DataType"];
                        var needsBetweenSlots = CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types);
                        if (firstTime)
                        {
                            result.Append($"                    EXEC sp_executesql @sql\r\n");
                            result.Append($"                                       ,N'@{name} {dataType}");
                            firstTime = false;
                        }
                        else
                            result.Append($",@{name} {dataType}");
                        if (needsBetweenSlots)
                            result.Append($",@{name}_v1 {dataType},@{name}_v2 {dataType}");
                        result.Append($",@{name}_vals NVARCHAR(MAX)");
                    }
                    result.Append($", @r BIGINT OUTPUT'\r\n");
                    foreach (var column in filterableColumns)
                    {
                        var name = column["Name"];
                        var needsBetweenSlots = CategoryAllowsBetweenFilter(rulesByCategory, comparators, column, domains, types);
                        result.Append($"                                       ,@{name} = @S_{name}_v\r\n");
                        if (needsBetweenSlots)
                        {
                            result.Append($"                                       ,@{name}_v1 = @S_{name}_v1\r\n");
                            result.Append($"                                       ,@{name}_v2 = @S_{name}_v2\r\n");
                        }
                        result.Append($"                                       ,@{name}_vals = @S_{name}_vals\r\n");
                    }
                    result.Append($"                                       ,@r = @Recno OUTPUT\r\n");
                }
                else
                    result.Append($"                    EXEC sp_executesql @sql, N'@r BIGINT OUTPUT', @r = @Recno OUTPUT\r\n");
                result.Append($"                    SET @PageNumber = CASE WHEN ISNULL(@Recno, 0) > 0 THEN ((@Recno - 1) / @LimitRows) + 1 ELSE @MaxPage END\r\n");
                result.Append($"                    IF ISNULL(@Recno, 0) > 0 SET @SearchRecno = @Recno\r\n");
                result.Append($"                END\r\n");
                result.Append($"            END\r\n");
                result.Append($"            IF ABS(@PageNumber) > @MaxPage\r\n");
                result.Append($"                SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END\r\n");
                result.Append($"            ELSE IF @PageNumber < 0\r\n");
                result.Append($"                SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1\r\n");
                result.Append($"            SET @OffSet = (@PageNumber - 1) * @LimitRows\r\n");
                result.Append($"            IF @PaddingGridLastPage = 1 AND @SearchRecno IS NULL AND @OffSet + @LimitRows > @RowCount\r\n");
                result.Append($"                SET @OffSet = CASE WHEN @RowCount > @LimitRows THEN @RowCount - @LimitRows ELSE 0 END\r\n");
                result.Append($"        END\r\n");

                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT TOP 0 CAST(NULL AS NVARCHAR(50)) AS [Kind]\r\n");
                        result.Append($"                    ,CAST(NULL AS BIGINT) AS [Recno]\r\n");
                        firstTime = false;
                    }
                    result.Append($"                    ,CAST(NULL AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                    if (!IsVirtualColumn(column))
                        AppendReadInWordsResultSchema(result, column);
                }
                result.Append($"            INTO [#result]\r\n");

                result.Append($"        SET @sql = 'INSERT [#result]\r\n");
                result.Append($"                        SELECT ''{table["Alias"]}'' AS [Kind]\r\n");
                result.Append($"                              ,[#].[Recno]\r\n");
                foreach (var column in columnRows)
                {
                    if (IsVirtualColumn(column))
                        result.Append($"                              ,CAST(NULL AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                    else
                    {
                    result.Append($"                              ,[T].[{column["Name"]}]\r\n");
                        AppendReadInWordsColumnFromAlias(result, column, "T");
                    }
                }
                result.Append($"                            FROM [#tmpTable] [#]\r\n");
                result.Append($"                                INNER JOIN [dbo].[{table["Name"]}] [T] ON {BuildPrimaryKeyJoinClause(primaryColumns, "T", "#")}\r\n");
                result.Append($"                            WHERE [#].[_] = ''T''\r\n");
                result.Append($"                        UNION ALL\r\n");
                result.Append($"                            SELECT ''{table["Alias"]}'' AS [Kind]\r\n");
                result.Append($"                                  ,[#].[Recno]\r\n");
                foreach (var column in columnRows)
                {
                    result.Append($"                                  ,[O].[{column["Name"]}]\r\n");
                    if (!IsVirtualColumn(column))
                        AppendReadInWordsColumnFromAlias(result, column, "O", "                                  ");
                }
                result.Append($"                                FROM [#tmpTable] [#]\r\n");
                result.Append($"                                    INNER JOIN [#tmpOperations] [O] ON {BuildPrimaryKeyJoinClause(primaryColumns, "O", "#")}\r\n");
                result.Append($"                                WHERE [#].[_] = ''O''\r\n");
                result.Append($"                        ORDER BY [Recno]\r\n");
                result.Append($"                        OFFSET ' + CAST(@OffSet AS NVARCHAR(20)) + ' ROWS\r\n");
                result.Append($"                        FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'\r\n");
                result.Append($"        EXEC sp_executesql @sql\r\n");

                var references = physicalColumnRows.FindAll(column => !Settings.IsNull(column["ReferenceTableId"]));
                var tmpTemps = new TDictionary();

                foreach (var reference in references)
                {
                    ProcessedTableIds.Clear();
                    result.Append(GetReferenceQueries(reference, columns, tmpTemps));
                }

                result.Append($"        SELECT (SELECT [Kind]\r\n");
                foreach (var column in columnRows)
                {
                    result.Append($"                      ,[{column["Name"]}]\r\n");
                    if (!IsVirtualColumn(column))
                        AppendReadInWordsJsonOutput(result, column);
                    if (Settings.ToBoolean(column["IsListable"]))
                        result.Append($"                      ,[{column["Name"]}] AS [ListItemValue]\r\n");
                }
                result.Append($"                    FROM [#result] FOR JSON PATH) AS [result]\r\n");
                foreach (var item in tmpTemps)
                    result.Append($"              ,ISNULL((SELECT [{item.Key}].* FROM [{item.Value}] AS [{item.Key}] FOR JSON PATH), '[]') AS [{item.Key}]\r\n");

                result.Append($"        SET @ReturnValue = @RowCount\r\n");
                result.Append($"\r\n");
                result.Append($"    RETURN 0\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }

        static TDictionary[] BuildComparators(TDataRows rows) =>
            rows.OrderBy(row => Settings.ToLong(row["Id"])).Select(row =>
            {
                var id = Settings.ToLong(row["Id"]);
                var sqlComparator = GetComparatorSqlComparator(row);
                var arity = row.Table.Columns.Contains("Arity") ? row["Arity"] : DBNull.Value;
                ValidateComparatorSqlComparator(sqlComparator, arity, id);
                return new TDictionary
                {
                    ["Id"] = id,
                    ["Symbol"] = Settings.ToString(row["Symbol"]),
                    ["Description"] = Settings.ToString(row["Description"]),
                    ["Arity"] = Settings.IsNull(arity) || string.IsNullOrWhiteSpace(Settings.ToString(arity)) ? null : Settings.ToLong(arity),
                    ["SqlComparator"] = sqlComparator,
                };
            }).ToArray();

        static Dictionary<long, List<long>> BuildRulesByCategory(TDataRows rows) =>
            rows.GroupBy(row => Settings.ToLong(row["CategoryId"]))
                .ToDictionary(group => group.Key, group => group.Select(row => Settings.ToLong(row["ComparatorId"])).Distinct().ToList());

        static long GetEqualityComparatorId(TDictionary[] comparators) =>
            Settings.ToLong(FindComparator(comparators, item => string.Equals(Settings.ToString(item["Symbol"]), "=", StringComparison.Ordinal), "comparador de igualdade (=)")["Id"]);

        static long GetLikeComparatorId(TDictionary[] comparators) =>
            Settings.ToLong(FindComparator(comparators, item => string.Equals(Settings.ToString(item["Description"]), "LIKE", StringComparison.OrdinalIgnoreCase), "comparador LIKE")["Id"]);

        static TDictionary FindComparator(TDictionary[] comparators, Func<TDictionary, bool> predicate, string description) =>
            comparators.FirstOrDefault(predicate) ?? throw new Exception($"Comparators: {description} não encontrado no metadado.");

        static long GetDefaultComparatorId(TDictionary[] comparators, Dictionary<long, List<long>> rulesByCategory, DataRow column, TDataRows domains, TDataRows types, bool isSearch)
        {
            var columnName = Settings.ToString(column["Name"]);
            var domain = RequireRow(domains, row => Settings.ToLong(row["Id"]) == Settings.ToLong(column["DomainId"]),
                $"DomainId {column["DomainId"]} não encontrado para coluna '{columnName}'.");
            var type = RequireRow(types, row => Settings.ToLong(row["Id"]) == Settings.ToLong(domain["TypeId"]),
                $"TypeId {domain["TypeId"]} não encontrado para coluna '{columnName}'.");
            var categoryId = Settings.ToLong(type["CategoryId"]);
            var equalityId = GetEqualityComparatorId(comparators);
            var likeId = GetLikeComparatorId(comparators);
            var preferredId = isSearch && Settings.ToBoolean(type["IsLikeable"]) ? likeId : equalityId;

            if (!rulesByCategory.TryGetValue(categoryId, out var allowed) || allowed.Count == 0)
                throw new Exception($"Categoria {categoryId} do tipo '{type["Name"]}' (coluna '{columnName}') não possui regras em Rules.");

            if (allowed.Contains(preferredId))
                return preferredId;

            throw new Exception($"Comparador padrão {preferredId} não permitido para coluna '{columnName}' (categoria {categoryId}). Permitidos: {string.Join(", ", allowed)}.");
        }

        static string FormatComparatorIds(TDictionary[] comparators, params Func<TDictionary, bool>[] filters) =>
            string.Join(", ", comparators.Where(item => filters.Any(filter => filter(item))).Select(item => Settings.ToLong(item["Id"])));

        static bool IsNullArity(object? arity) =>
            Settings.IsNull(arity) || string.IsNullOrWhiteSpace(Settings.ToString(arity));

        static bool IsListComparator(TDictionary comparator) =>
            IsNullArity(comparator["Arity"]);

        static bool IsBetweenComparator(TDictionary comparator) =>
            !IsNullArity(comparator["Arity"]) && Settings.ToLong(comparator["Arity"]) > 2;

        static bool IsBinaryComparator(TDictionary comparator) =>
            !IsNullArity(comparator["Arity"]) && Settings.ToLong(comparator["Arity"]) == 2;

        static bool IsUnaryComparator(TDictionary comparator) =>
            !IsNullArity(comparator["Arity"]) && Settings.ToLong(comparator["Arity"]) == 1;

        static readonly HashSet<string> ListSqlComparators = new(StringComparer.OrdinalIgnoreCase) { "IN", "NOT IN" };
        static readonly HashSet<string> BinarySqlComparators = new(StringComparer.OrdinalIgnoreCase) { "<", "<=", "=", "<>", ">=", ">", "LIKE", "NOT LIKE" };
        static readonly HashSet<string> BetweenSqlComparators = new(StringComparer.OrdinalIgnoreCase) { "BETWEEN", "NOT BETWEEN" };
        static readonly HashSet<string> UnarySqlComparators = new(StringComparer.OrdinalIgnoreCase) { "IS NULL", "IS NOT NULL" };

        static string GetComparatorSqlComparator(DataRow row)
        {
            var id = Settings.ToLong(row["Id"]);
            if (row.Table.Columns.Contains("SqlComparator"))
            {
                var sqlComparator = Settings.ToString(row["SqlComparator"]).Trim();
                if (!string.IsNullOrWhiteSpace(sqlComparator))
                    return sqlComparator;
            }

            if (row.Table.Columns.Contains("SqlCode") || row.Table.Columns.Contains("CodeSQL"))
                return DeriveSqlComparatorFromSqlCode(GetLegacyComparatorSqlCode(row), id);

            throw new Exception($"Comparators (Id {id}): SqlComparator é obrigatório no metadado.");
        }

        static string GetLegacyComparatorSqlCode(DataRow row)
        {
            var id = Settings.ToLong(row["Id"]);
            var sqlCode = row.Table.Columns.Contains("SqlCode")
                ? Settings.ToString(row["SqlCode"])
                : Settings.ToString(row["CodeSQL"]);

            if (string.IsNullOrWhiteSpace(sqlCode))
                throw new Exception($"Comparators (Id {id}): SqlComparator é obrigatório no metadado.");

            return sqlCode.Trim();
        }

        static string DeriveSqlComparatorFromSqlCode(string sqlCode, long id)
        {
            var patterns = new (string Pattern, string Comparator)[]
            {
                ("%1 NOT BETWEEN %2 AND %3", "NOT BETWEEN"),
                ("%1 BETWEEN %2 AND %3", "BETWEEN"),
                ("%1 NOT IN %2", "NOT IN"),
                ("%1 IN %2", "IN"),
                ("%1 NOT LIKE %2", "NOT LIKE"),
                ("%1 LIKE %2", "LIKE"),
                ("%1 IS NOT NULL", "IS NOT NULL"),
                ("%1 IS NULL", "IS NULL"),
                ("%1 <> %2", "<>"),
                ("%1 <= %2", "<="),
                ("%1 >= %2", ">="),
                ("%1 < %2", "<"),
                ("%1 > %2", ">"),
                ("%1 = %2", "="),
            };

            foreach (var (pattern, comparator) in patterns)
            {
                if (string.Equals(sqlCode, pattern, StringComparison.OrdinalIgnoreCase))
                    return comparator;
            }

            throw new Exception($"Comparators (Id {id}): SqlCode legado '{sqlCode}' não mapeia para SqlComparator.");
        }

        static void ValidateComparatorSqlComparator(string sqlComparator, object? arity, long id)
        {
            if (IsNullArity(arity))
            {
                if (!ListSqlComparators.Contains(sqlComparator))
                    throw new Exception($"Comparators (Id {id}): SqlComparator '{sqlComparator}' inválido para Arity NULL (esperado IN ou NOT IN).");
                return;
            }

            var arityValue = Settings.ToLong(arity);
            if (arityValue > 2)
            {
                if (!BetweenSqlComparators.Contains(sqlComparator))
                    throw new Exception($"Comparators (Id {id}): SqlComparator '{sqlComparator}' inválido para Arity {arityValue} (esperado BETWEEN ou NOT BETWEEN).");
                return;
            }

            if (arityValue == 1)
            {
                if (!UnarySqlComparators.Contains(sqlComparator))
                    throw new Exception($"Comparators (Id {id}): SqlComparator '{sqlComparator}' inválido para Arity 1 (esperado IS NULL ou IS NOT NULL).");
                return;
            }

            if (arityValue == 2)
            {
                if (!BinarySqlComparators.Contains(sqlComparator))
                    throw new Exception($"Comparators (Id {id}): SqlComparator '{sqlComparator}' inválido para Arity 2.");
                return;
            }

            throw new Exception($"Comparators (Id {id}): Arity '{arityValue}' não suportado.");
        }

        static string EscapeSqlStringLiteral(string value) =>
            value.Replace("'", "''");

        static string BuildComparatorPredicateCaseExpression(string columnRef, string parameterName, string dataType, bool needsBetweenSlots)
        {
            var column = EscapeSqlStringLiteral(columnRef);
            var betweenBranch = needsBetweenSlots
                ? $"        WHEN [C].[Arity] > 2 THEN '{column} ' + [C].[SqlComparator] + ' @{parameterName}_v1 AND @{parameterName}_v2'\r\n"
                : string.Empty;
            return $@"CASE
        WHEN [C].[Arity] IS NULL THEN '{column} ' + [C].[SqlComparator] + ' (SELECT CAST([value] AS {dataType}) FROM OPENJSON(@{parameterName}_vals))'
{betweenBranch}        WHEN [C].[Arity] = 1 THEN '{column} ' + [C].[SqlComparator]
        ELSE '{column} ' + [C].[SqlComparator] + ' @{parameterName}'
    END";
        }

        static string BuildComparatorArityReadyCondition(string valueVarPrefix, bool needsBetweenSlots)
        {
            var betweenBranch = needsBetweenSlots
                ? $"               OR ([C].[Arity] > 2 AND {valueVarPrefix}v1 IS NOT NULL AND {valueVarPrefix}v2 IS NOT NULL)\r\n"
                : string.Empty;
            return $@"(([C].[Arity] IS NULL AND {valueVarPrefix}vals IS NOT NULL)
{betweenBranch}               OR ([C].[Arity] = 2 AND {valueVarPrefix}v IS NOT NULL)
               OR ([C].[Arity] = 1))";
        }

        static void AppendComparatorPredicateFromMetadata(StringBuilder result, string indent, string opVariable, string columnRef, string dataType, string parameterName, bool isSearch, bool needsBetweenSlots)
        {
            var valueVarPrefix = opVariable.Replace("_comparator", "_", StringComparison.Ordinal);
            var predicateCase = BuildComparatorPredicateCaseExpression(columnRef, parameterName, dataType, needsBetweenSlots);
            var arityReady = BuildComparatorArityReadyCondition(valueVarPrefix, needsBetweenSlots);

            result.Append($"{indent}IF {opVariable} IS NOT NULL BEGIN\r\n");
            if (isSearch)
                result.Append($"{indent}    IF @Where <> '' SET @Where = @Where + ' AND '\r\n");
            result.Append($"{indent}    SELECT @ComparatorPredicate = {predicateCase}\r\n");
            result.Append($"{indent}        FROM [dbo].[Comparators] [C]\r\n");
            result.Append($"{indent}        WHERE [C].[Id] = {opVariable}\r\n");
            result.Append($"{indent}              AND {arityReady}\r\n");
            if (isSearch)
                result.Append($"{indent}    SET @Where = @Where + ISNULL(@ComparatorPredicate, '')\r\n");
            else
                result.Append($"{indent}    IF @ComparatorPredicate IS NOT NULL SET @Where = @Where + ' AND ' + @ComparatorPredicate\r\n");
            result.Append($"{indent}END\r\n");
        }
    }
}