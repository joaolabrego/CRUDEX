using CRUDEX.Classes;
using ExcelDataReader;
using System.Data;
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
            ], StringComparer.OrdinalIgnoreCase);
        public static async Task Generate(string systemName = "crudex", string databaseName = "crudex", bool saveInDisk = true, bool? isExcel = null, bool withInsertData = true, bool isDocker = true)
        {
            var result = new StringBuilder();
            var dataSet = (isExcel ?? systemName == "crudex") ? await ExcelToDataSet() : await GetDataSet();
            var system = (dataSet.Tables["Systems"] ?? throw new Exception("Tabela Systems não existe.")).AsEnumerable().ToList()
                .First(row => Settings.ToString(row["Name"]) == systemName);
            var database = (dataSet.Tables["Databases"] ?? throw new Exception("Tabela Databases não existe.")).AsEnumerable().ToList()
                .First(row => Settings.ToString(row["Name"]) == databaseName);
            var columns = (dataSet.Tables["Columns"] ?? throw new Exception("Tabela Columns não existe.")).AsEnumerable().ToList();
            var indexes = (dataSet.Tables["Indexes"] ?? throw new Exception("Tabela Indexes não existe.")).AsEnumerable().ToList();
            var indexkeys = (dataSet.Tables["Indexkeys"] ?? throw new Exception("Tabela Indexkeys não existe.")).AsEnumerable().ToList();
            var domains = (dataSet.Tables["Domains"] ?? throw new Exception("Tabela Domains não existe.")).AsEnumerable().ToList();
            var categories = (dataSet.Tables["Categories"] ?? throw new Exception("Tabela Categories não existe.")).AsEnumerable().ToList();
            var types = (dataSet.Tables["Types"] ?? throw new Exception("Tabela Types não existe.")).AsEnumerable().ToList();
            var tables = (dataSet.Tables["Tables"] ?? throw new Exception("Tabela Tables não existe.")).AsEnumerable().ToList();
            var unicities = (dataSet.Tables["Unicities"] ?? throw new Exception("Tabela Unicities não existe.")).AsEnumerable().ToList();
            var databaseTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("Tabela DatabasesTables não existe.")).AsEnumerable().ToList()
                .FindAll(row => Settings.ToLong(row["DatabaseId"]) == Settings.ToLong(database["Id"]));
            var references = new TDataRows();
            var firstTime = true;
            var databaseTableRows = GetDatabaseTableRows(databaseTables, tables, columns);

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
                result.AppendLine(GetScriptReadTable(table, columns, domains, types).ToString());
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

            return await Task.Run(() =>
            {
                return reader.AsDataSet(new ExcelDataSetConfiguration()
                {
                    ConfigureDataTable = _ => new ExcelDataTableConfiguration()
                    {
                        UseHeaderRow = true
                    }
                });
            });
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
            var domain = domains.First(domain => Settings.ToLong(domain["Id"]) == Settings.ToLong(column["DomainId"]));
            var type = types.First(type => Settings.ToLong(type["Id"]) == Settings.ToLong(domain["TypeId"]));
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
        private static void AppendReadFilterColumn(StringBuilder result, DataRow column, TDataRows domains, TDataRows types, string indent)
        {
            var name = column["Name"];
            var dataType = column["#DataType"];
            var validations = GetConstraints(column, domains, types);

            result.Append($"{indent}IF EXISTS(SELECT 1 FROM OPENJSON(@RecordFilterGrid, '$.Filter') WHERE [key] = '{name}' AND [type] = 0)\r\n");
            result.Append($"{indent}   OR EXISTS(SELECT 1 FROM OPENJSON(@RecordFilterGrid, '$.Fixed') WHERE [key] = '{name}' AND [type] = 0)\r\n");
            result.Append($"{indent}   OR EXISTS(SELECT 1 FROM OPENJSON(@RecordFilterTable) WHERE [key] = '{name}' AND [type] = 0)\r\n");
            result.Append($"{indent}   OR EXISTS(SELECT 1 FROM OPENJSON(@RecordFilterGrid) WHERE [key] = '{name}' AND [type] = 0)\r\n");
            result.Append($"{indent}    SET @Where = @Where + ' AND [T].[{name}] IS NULL'\r\n");
            result.Append($"{indent}ELSE IF @G_{name}_op IS NOT NULL BEGIN\r\n");
            if (validations.TryGetValue("Minimum", out dynamic? value))
            {
                result.Append($"{indent}    IF @G_{name}_op NOT IN (7, 8, 11, 12) AND @G_{name}_v IS NOT NULL AND @G_{name}_v < CAST('{value}' AS {dataType})\r\n");
                result.Append($"{indent}        THROW 51000, 'Valor de {name} deve ser maior que ou igual a ''{value}''', 1\r\n");
            }
            if (validations.TryGetValue("Maximum", out value))
            {
                result.Append($"{indent}    IF @G_{name}_op NOT IN (7, 8, 11, 12) AND @G_{name}_v IS NOT NULL AND @G_{name}_v > CAST('{value}' AS {dataType})\r\n");
                result.Append($"{indent}        THROW 51000, 'Valor de {name} deve ser menor que ou igual a ''{value}''', 1\r\n");
            }
            result.Append($"{indent}    DECLARE @opSql_{name} NVARCHAR(15)\r\n");
            result.Append($"{indent}    SELECT @opSql_{name} = CASE @G_{name}_op\r\n");
            result.Append($"{indent}        WHEN 1 THEN '<' WHEN 2 THEN '<=' WHEN 3 THEN '=' WHEN 4 THEN '<>'\r\n");
            result.Append($"{indent}        WHEN 5 THEN '>=' WHEN 6 THEN '>' WHEN 9 THEN 'LIKE' WHEN 10 THEN 'NOT LIKE'\r\n");
            result.Append($"{indent}        ELSE '=' END\r\n");
            result.Append($"{indent}    IF @G_{name}_op IN (7, 8) AND @G_{name}_vals IS NOT NULL\r\n");
            result.Append($"{indent}        SET @Where = @Where + ' AND [T].[{name}] ' + CASE WHEN @G_{name}_op = 7 THEN 'IN' ELSE 'NOT IN' END + ' (SELECT CAST([value] AS {dataType}) FROM OPENJSON(@{name}_vals))'\r\n");
            result.Append($"{indent}    ELSE IF @G_{name}_op IN (11, 12) AND @G_{name}_v1 IS NOT NULL AND @G_{name}_v2 IS NOT NULL\r\n");
            result.Append($"{indent}        SET @Where = @Where + ' AND [T].[{name}] ' + CASE WHEN @G_{name}_op = 11 THEN 'BETWEEN' ELSE 'NOT BETWEEN' END + ' @{name}_v1 AND @{name}_v2'\r\n");
            result.Append($"{indent}    ELSE IF @G_{name}_op = 9 AND @G_{name}_v IS NOT NULL\r\n");
            result.Append($"{indent}        SET @Where = @Where + ' AND [T].[{name}] LIKE ''%'' + @{name} + ''%'''\r\n");
            result.Append($"{indent}    ELSE IF @G_{name}_v IS NOT NULL\r\n");
            result.Append($"{indent}        SET @Where = @Where + ' AND [T].[{name}] ' + @opSql_{name} + ' @{name}'\r\n");
            result.Append($"{indent}END\r\n");
        }
        private static void AppendReadTableFilterColumn(StringBuilder result, DataRow column, TDataRows domains, TDataRows types, string valueVariable, string parameterName, string indent)
        {
            var name = column["Name"];
            var dataType = column["#DataType"];
            var validations = GetConstraints(column, domains, types);

            result.Append($"{indent}IF EXISTS(SELECT 1 FROM OPENJSON(@RecordFilterTable) WHERE [key] = '{name}' AND [type] = 0)\r\n");
            result.Append($"{indent}    SET @Where = @Where + ' AND [T].[{name}] IS NULL'\r\n");
            result.Append($"{indent}ELSE IF {valueVariable} IS NOT NULL BEGIN\r\n");
            if (validations.TryGetValue("Minimum", out dynamic? value))
            {
                result.Append($"{indent}    IF {valueVariable} < CAST('{value}' AS {dataType})\r\n");
                result.Append($"{indent}        THROW 51000, 'Valor de {name} deve ser maior que ou igual a ''{value}''', 1\r\n");
            }
            if (validations.TryGetValue("Maximum", out value))
            {
                result.Append($"{indent}    IF {valueVariable} > CAST('{value}' AS {dataType})\r\n");
                result.Append($"{indent}        THROW 51000, 'Valor de {name} deve ser menor que ou igual a ''{value}''', 1\r\n");
            }
            result.Append($"{indent}    SET @Where = @Where + ' AND [T].[{name}] = {parameterName}'\r\n");
            result.Append($"{indent}END\r\n");
        }
        private static void AppendReadSearchCondition(StringBuilder result, DataRow column, string indent)
        {
            var name = column["Name"];
            var dataType = Convert.ToString(column["#DataType"]) ?? string.Empty;
            var colRef = $"COALESCE([D].[{name}], [O].[{name}])";

            result.Append($"{indent}IF EXISTS(SELECT 1 FROM OPENJSON(@RecordSearch) WHERE [key] = '{name}' AND [type] = 0)\r\n");
            result.Append($"{indent}BEGIN\r\n");
            result.Append($"{indent}    IF @Where <> '' SET @Where = @Where + ' AND '\r\n");
            result.Append($"{indent}    SET @Where = @Where + '{colRef} IS NULL'\r\n");
            result.Append($"{indent}END\r\n");
            result.Append($"{indent}ELSE IF @S_{name}_op IS NOT NULL BEGIN\r\n");
            result.Append($"{indent}    DECLARE @opSqlS_{name} NVARCHAR(15)\r\n");
            result.Append($"{indent}    SELECT @opSqlS_{name} = CASE @S_{name}_op\r\n");
            result.Append($"{indent}        WHEN 1 THEN '<' WHEN 2 THEN '<=' WHEN 3 THEN '=' WHEN 4 THEN '<>'\r\n");
            result.Append($"{indent}        WHEN 5 THEN '>=' WHEN 6 THEN '>' WHEN 9 THEN 'LIKE' WHEN 10 THEN 'NOT LIKE'\r\n");
            result.Append($"{indent}        ELSE '=' END\r\n");
            result.Append($"{indent}    IF @Where <> '' SET @Where = @Where + ' AND '\r\n");
            result.Append($"{indent}    IF @S_{name}_op IN (7, 8)\r\n");
            result.Append($"{indent}        SET @Where = @Where + '{colRef} ' + CASE WHEN @S_{name}_op = 7 THEN 'IN' ELSE 'NOT IN' END + ' (SELECT CAST([value] AS {dataType}) FROM OPENJSON(@{name}_vals))'\r\n");
            result.Append($"{indent}    ELSE IF @S_{name}_op IN (11, 12)\r\n");
            result.Append($"{indent}        SET @Where = @Where + '{colRef} ' + CASE WHEN @S_{name}_op = 11 THEN 'BETWEEN' ELSE 'NOT BETWEEN' END + ' @{name}_v1 AND @{name}_v2'\r\n");
            result.Append($"{indent}    ELSE IF @S_{name}_op = 9\r\n");
            result.Append($"{indent}        SET @Where = @Where + '{colRef} LIKE ''%'' + @{name} + ''%'''\r\n");
            result.Append($"{indent}    ELSE\r\n");
            result.Append($"{indent}        SET @Where = @Where + '{colRef} ' + @opSqlS_{name} + ' @{name}'\r\n");
            result.Append($"{indent}END\r\n");
        }

        private static void AppendReadGridFilterDeclareVars(StringBuilder result, DataRow column, bool isSearch, bool declare)
        {
            var name = column["Name"];
            var dataType = column["#DataType"];
            var prefix = isSearch ? "S" : "G";
            var lead = declare ? "            DECLARE " : "                   ,";

            result.Append($"{lead}@{prefix}_{name}_op TINYINT\r\n");
            result.Append($"                   ,@{prefix}_{name}_v {dataType}\r\n");
            result.Append($"                   ,@{prefix}_{name}_vals NVARCHAR(MAX)\r\n");
            result.Append($"                   ,@{prefix}_{name}_v1 {dataType}\r\n");
            result.Append($"                   ,@{prefix}_{name}_v2 {dataType}\r\n");
        }

        private static void AppendReadGridFilterAssignVars(StringBuilder result, DataRow column, bool isSearch)
        {
            var name = column["Name"];
            var dataType = column["#DataType"];
            var prefix = isSearch ? "S" : "G";
            var jsonVariable = isSearch ? "@RecordSearch" : "@RecordFilterGrid";
            var dataTypeText = Convert.ToString(dataType) ?? string.Empty;
            var isText = dataTypeText.StartsWith("nvarchar", StringComparison.OrdinalIgnoreCase)
                || dataTypeText.StartsWith("varchar", StringComparison.OrdinalIgnoreCase)
                || string.Equals(dataTypeText, "ntext", StringComparison.OrdinalIgnoreCase)
                || string.Equals(dataTypeText, "text", StringComparison.OrdinalIgnoreCase);
            var defaultOp = isSearch && isText ? "9" : "3";
            var indent = isSearch ? "                " : "            ";

            if (!isSearch)
            {
                result.Append($"{indent}SELECT @{prefix}_{name}_op = TRY_CAST(JSON_VALUE({jsonVariable}, '$.Filter.{name}.op') AS TINYINT)\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_op IS NULL SELECT @{prefix}_{name}_op = TRY_CAST(JSON_VALUE({jsonVariable}, '$.Fixed.{name}.op') AS TINYINT)\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_op IS NULL SELECT @{prefix}_{name}_op = TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}.op') AS TINYINT)\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_op IS NULL AND JSON_VALUE({jsonVariable}, '$.Filter.{name}') IS NOT NULL AND JSON_QUERY({jsonVariable}, '$.Filter.{name}') IS NULL SET @{prefix}_{name}_op = 3\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_op IS NULL AND JSON_VALUE({jsonVariable}, '$.Fixed.{name}') IS NOT NULL AND JSON_QUERY({jsonVariable}, '$.Fixed.{name}') IS NULL SET @{prefix}_{name}_op = 3\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_op IS NULL AND JSON_VALUE({jsonVariable}, '$.{name}') IS NOT NULL AND JSON_QUERY({jsonVariable}, '$.{name}') IS NULL SET @{prefix}_{name}_op = 3\r\n");

                result.Append($"{indent}SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.Filter.{name}.value') AS {dataType})\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_v IS NULL SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.Fixed.{name}.value') AS {dataType})\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_v IS NULL SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}.value') AS {dataType})\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_v IS NULL SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.Filter.{name}') AS {dataType})\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_v IS NULL SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.Fixed.{name}') AS {dataType})\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_v IS NULL SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}') AS {dataType})\r\n");

                result.Append($"{indent}SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.Filter.{name}.value')\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_vals IS NULL SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.Fixed.{name}.value')\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_vals IS NULL SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.{name}.value')\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_vals IS NULL SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.Filter.{name}')\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_vals IS NULL SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.Fixed.{name}')\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_vals IS NULL SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.{name}')\r\n");
            }
            else
            {
                result.Append($"{indent}SELECT @{prefix}_{name}_op = TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}.op') AS TINYINT)\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_op IS NULL AND JSON_VALUE({jsonVariable}, '$.{name}') IS NOT NULL AND JSON_QUERY({jsonVariable}, '$.{name}') IS NULL SET @{prefix}_{name}_op = {defaultOp}\r\n");

                result.Append($"{indent}SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}.value') AS {dataType})\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_v IS NULL SELECT @{prefix}_{name}_v = TRY_CAST(JSON_VALUE({jsonVariable}, '$.{name}') AS {dataType})\r\n");

                result.Append($"{indent}SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.{name}.value')\r\n");
                result.Append($"{indent}IF @{prefix}_{name}_vals IS NULL SELECT @{prefix}_{name}_vals = JSON_QUERY({jsonVariable}, '$.{name}')\r\n");
            }

            result.Append($"{indent}SELECT @{prefix}_{name}_v1 = TRY_CAST(JSON_VALUE(@{prefix}_{name}_vals, '$[0]') AS {dataType})\r\n");
            result.Append($"{indent}SELECT @{prefix}_{name}_v2 = TRY_CAST(JSON_VALUE(@{prefix}_{name}_vals, '$[1]') AS {dataType})\r\n");
        }

        private static List<DataRow> GetDatabaseTableRows(TDataRows databaseTables, TDataRows tables, TDataRows columns)
        {
            var rows = new TDataRows();
            var seen = new HashSet<long>();

            foreach (var databaseTable in databaseTables)
            {
                var table = tables.First(row => Settings.ToLong(row["Id"]) == Settings.ToLong(databaseTable["TableId"]));
                var id = Settings.ToLong(table["Id"]);
                if (seen.Add(id))
                    rows.Add(table);
            }

            foreach (var table in tables)
            {
                var id = Settings.ToLong(table["Id"]);
                if (seen.Contains(id) || GetTableColumnRows(columns, table).Count == 0)
                    continue;
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

        private static void AppendReadExecutesqlParams(StringBuilder result, TDataRows filterableColumns, bool includeTableFilters, bool includeGridFilters, string indent)
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
                if (first)
                {
                    result.Append($"{indent},N'");
                    first = false;
                }
                else
                    result.Append(",");
                result.Append($"@{name} {dataType},@{name}_v1 {dataType},@{name}_v2 {dataType},@{name}_vals NVARCHAR(MAX)");
            }
            if (!first)
                result.Append($"'\r\n");
        }
        private static void AppendReadExecutesqlAssignments(StringBuilder result, TDataRows filterableColumns, bool includeTableFilters, bool includeGridFilters, string indent)
        {
            if (includeTableFilters)
                foreach (var column in filterableColumns)
                    result.Append($"{indent},@T_{column["Name"]} = @WT_{column["Name"]}\r\n");
            if (includeGridFilters)
                foreach (var column in filterableColumns)
                {
                    var name = column["Name"];
                    result.Append($"{indent},@{name} = @G_{name}_v\r\n");
                    result.Append($"{indent},@{name}_v1 = @G_{name}_v1\r\n");
                    result.Append($"{indent},@{name}_v2 = @G_{name}_v2\r\n");
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

        private static void AppendResolveCreateId(StringBuilder result, DataRow table, TDataRows columnRows, string systemName, string databaseName)
        {
            var idDataType = columnRows[0]["#DataType"];
            var tableName = Settings.ToString(table["Name"]);

            result.Append($"    IF @Action = 'create' AND @W_Id IS NULL BEGIN\r\n");
            result.Append($"        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS {idDataType})\r\n");
            result.Append($"            FROM [dbo].[Operations]\r\n");
            result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
            result.Append($"                  AND [TableName] = '{tableName}'\r\n");
            result.Append($"                  AND [Action] = 'create'\r\n");
            result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
            result.Append($"        IF @W_Id IS NULL BEGIN\r\n");
            result.Append($"            DECLARE @NewId BIGINT\r\n");
            AppendNewIdCall(result, systemName, databaseName, tableName, "@NewId");
            result.Append($"            SET @W_Id = CAST(@NewId AS {idDataType})\r\n");
            result.Append($"        END\r\n");
            result.Append($"        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)\r\n");
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
            var transactionTable = tables.First(row => string.Equals(Settings.ToString(row["Name"]), "Transactions", StringComparison.OrdinalIgnoreCase));
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
                    var required = $"{(constraints.TryGetValue("Required", out dynamic? value) ? value : "")}";
                    if (Settings.ToString(table["Name"]).Equals("Operations", StringComparison.OrdinalIgnoreCase)
                        && Settings.ToString(column["Name"]).Equals("ActualRecord", StringComparison.OrdinalIgnoreCase))
                        required = " NULL";
                    var autoIncrement = $"{(constraints.TryGetValue("AutoIncrement", out value) ? value : "")}";
                    var defaultValue = $"{(constraints.TryGetValue("Default", out value) ? value : "")}";
                    var range = $"{(constraints.TryGetValue("Range", out value) ? value : "")}";

                    if (firstTime)
                    {
                        var definition = $"[Id] {column["#DataType"]}{required}{defaultValue}{range}";
                        var message = $"Primeira coluna definida na tabela '{table["Name"]}' ";

                        if (!Settings.ToString(column["Name"]).ToLower().Equals("id"))
                            throw new Exception(message + "deve ter nome 'Id'.");
                        if (!Settings.ToString(column["#CategoryName"]).Equals("number"))
                            throw new Exception(message + "deve ser de categoria 'number'.");
                        if (!Settings.ToBoolean(constraints["AskPrimarykey"]))
                            throw new Exception(message + "deve permitir 'primary key'.");
                        if (!Settings.ToBoolean(column["IsPrimarykey"]))
                            throw new Exception(message + "deve ser 'primary key'.");
                        if (!Settings.ToBoolean(column["IsAutoIncrement"]))
                            throw new Exception(message + "deve ser 'auto increment'.");
                        result.Append($"CREATE TABLE [dbo].[{table["Name"]}]({definition}\r\n");
                        firstTime = false;
                    }
                    else if (ReservedColumnNames.Contains($"{Settings.ToString(column["Name"])}"))
                        throw new Exception($"Nome de coluna {column["Name"]} é reservado.");
                    else
                    {
                        var definition = $"[{column["Name"]}] {column["#DataType"]}{required}{defaultValue}{range}";
                        var message = $"Demais colunas definidas na tabela '{table["Name"]}' ";

                        if (Settings.ToString(column["Name"]).ToLower().Equals("id"))
                            throw new Exception(message + "não devem ter nome 'Id'.");
                        if (Settings.ToBoolean(column["IsPrimarykey"]))
                            throw new Exception(message + "não devem ser 'primary key'.");
                        if (Settings.ToBoolean(column["IsAutoIncrement"]))
                            throw new Exception(message + "não devem ser 'auto increment'.");
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
                result.Append($"ALTER TABLE [dbo].[{table["Name"]}] ADD CONSTRAINT PK_{table["Name"]} PRIMARY KEY CLUSTERED ([Id])\r\n");

                var indexRows = indexes.FindAll(index => Settings.ToLong(index["TableId"]) == Settings.ToLong(table["Id"]));

                if (indexRows.Count > 0)
                {
                    foreach (var index in indexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => Settings.ToLong(indexkey["IndexId"]) == Settings.ToLong(index["Id"]));

                        if (indexkeyRows.Count > 0)
                        {
                            firstTime = true;
                            foreach (var indexkey in indexkeyRows)
                            {
                                var column = columns.First(column => Settings.ToLong(column["Id"]) == Settings.ToLong(indexkey["ColumnId"]));
                                if (IsVirtualColumn(column))
                                    continue;
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
                    var primaryTable = tables.First(table => Settings.ToLong(table["Id"]) == Settings.ToLong(foreign["TableId"]));
                    var foreignTable = tables.First(table => Settings.ToLong(table["Id"]) == Settings.ToLong(foreign["ReferenceTableId"]));
                    var foreignKey = columns.First(column => Settings.ToLong(column["TableId"]) == Settings.ToLong(foreignTable["Id"]) && Settings.ToBoolean(column["IsPrimarykey"]));
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

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Inserir dados na tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                if (columnRows.Count > 0)
                {
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
                }
            }

            return result;
        }
        private static void AppendLoginCall(StringBuilder result, string loginIdVariable)
        {
            result.Append($"    DECLARE @LoginReturn BIGINT\r\n");
            result.Append($"\r\n");
            result.Append($"    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT\r\n");
            result.Append($"    SET {loginIdVariable} = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)\r\n");
            result.Append($"    IF {loginIdVariable} IS NULL\r\n");
            result.Append($"        THROW 51000, 'LoginId é requerido', 1\r\n");
            result.Append($"\r\n");
        }
        private static StringBuilder GetScriptPersistTable(DataRow table, TDataRows columns, string systemName, string databaseName)
        {
            var result = new StringBuilder();
            var columnRows = GetTableColumnRows(columns, table);
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);

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
                result.Append($"           ,@W_Id {physicalColumnRows[0]["#DataType"]}\r\n");
                result.Append($"\r\n");
                result.Append($"    IF @Action = 'delete'\r\n");
                result.Append($"        SET @W_Id = CAST(JSON_VALUE(@LastRecord, '$.Id') AS {physicalColumnRows[0]["#DataType"]})\r\n");
                result.Append($"    ELSE\r\n");
                result.Append($"        SET @W_Id = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS {physicalColumnRows[0]["#DataType"]})\r\n");
                result.Append($"\r\n");
                AppendResolveCreateId(result, table, physicalColumnRows, systemName, databaseName);
                result.Append($"    EXEC @TransactionId = [dbo].[{table["Alias"]}Validate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        SELECT @OperationId = [Id]\r\n");
                result.Append($"              ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"              ,@ActionAux = [Action]\r\n");
                result.Append($"              ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                  AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                result.Append($"                  AND CAST(JSON_VALUE(ISNULL([ActualRecord], [LastRecord]), '$.Id') AS {physicalColumnRows[0]["#DataType"]}) = @W_Id\r\n");
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                AppendNewOperationIdCall(result, systemName, databaseName, "@OperationId");
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
                result.Append($"        END ELSE IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END ELSE IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");
                result.Append($"        ELSE IF @ActionAux = 'delete'\r\n");
                result.Append($"            THROW 51000, 'Registro excluído nesta transação', 1\r\n");
                result.Append($"        ELSE IF @Action = 'create' BEGIN\r\n");
                result.Append($"            UPDATE [dbo].[Operations]\r\n");
                result.Append($"                SET [ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END\r\n");
                result.Append($"        ELSE IF @Action = 'update' BEGIN\r\n");
                result.Append($"            IF @ActionAux = 'create'\r\n");
                result.Append($"                EXEC [dbo].[{table["Alias"]}Validate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord\r\n");
                result.Append($"            UPDATE [dbo].[Operations]\r\n");
                result.Append($"                SET [ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END ELSE IF @ActionAux = 'create' BEGIN\r\n");
                result.Append($"            UPDATE [dbo].[Operations] \r\n");
                result.Append($"                SET [IsConfirmed] = 0\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            UPDATE [dbo].[Operations]\r\n");
                result.Append($"                SET [Action] = 'delete'\r\n");
                result.Append($"                   ,[LastRecord] = @LastRecord\r\n");
                result.Append($"                   ,[ActualRecord] = NULL\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END\r\n");
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
        private static void AppendOperationSubProcedureHeader(StringBuilder result, DataRow table, TDataRows columnRows, string procedureSuffix, string expectedAction)
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
            if (expectedAction == "delete")
                result.Append($"        DECLARE @W_Id {columnRows[0]["#DataType"]} = CAST(JSON_VALUE(@LastRecord, '$.Id') AS {columnRows[0]["#DataType"]})\r\n");
            else
                result.Append($"        DECLARE @W_Id {columnRows[0]["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS {columnRows[0]["#DataType"]})\r\n");
            result.Append($"\r\n");
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

            if (physicalColumnRows.Count > 0)
            {
                AppendOperationSubProcedureHeader(result, table, physicalColumnRows, "Create", "create");
                AppendWorkColumnVariables(result, physicalColumnRows);

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
                AppendOperationSubProcedureFooter(result);
            }

            return result;
        }
        private static StringBuilder GetScriptOperationUpdate(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);

            if (physicalColumnRows.Count > 0)
            {
                AppendOperationSubProcedureHeader(result, table, physicalColumnRows, "Update", "update");
                AppendWorkColumnVariables(result, physicalColumnRows);

                var firstTime = true;
                foreach (var column in physicalColumnRows)
                {
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
                result.Append($"            WHERE [Id] = @W_Id\r\n");
                AppendOperationSubProcedureFooter(result);
            }

            return result;
        }
        private static StringBuilder GetScriptOperationDelete(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);

            if (physicalColumnRows.Count > 0)
            {
                AppendOperationSubProcedureHeader(result, table, physicalColumnRows, "Delete", "delete");
                result.Append($"        DELETE FROM [dbo].[{table["Name"]}] WHERE [Id] = @W_Id\r\n");
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
                result.Append($"               ,@W_Id AS {physicalColumnRows[0]["#DataType"]}\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @Action = 'delete'\r\n");
                result.Append($"            SET @W_Id = CAST(JSON_VALUE(@LastRecord, '$.Id') AS {physicalColumnRows[0]["#DataType"]})\r\n");
                result.Append($"        ELSE\r\n");
                result.Append($"            SET @W_Id = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS {physicalColumnRows[0]["#DataType"]})\r\n");
                result.Append($"\r\n");
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

                var constraints = GetConstraints(physicalColumnRows[0], domains, types);

                result.Append($"        IF @W_Id IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                if (constraints.TryGetValue("Minimum", out dynamic? value))
                {
                    result.Append($"        IF @W_Id < CAST('{value}' AS {physicalColumnRows[0]["#DataType"]})\r\n");
                    result.Append($"            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a {value}', 1\r\n");
                }
                if (constraints.TryGetValue("Maximum", out value))
                {
                    result.Append($"        IF @W_Id < CAST('{value}' AS {physicalColumnRows[0]["#DataType"]})\r\n");
                    result.Append($"            THROW 51000, 'Valor de Id em @ActualRecord deve ser menor que ou igual a {value}', 1\r\n");
                }
                result.Append($"        IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [Id] = @W_Id");
                result.Append(") BEGIN\r\n");
                result.Append($"            IF @Action = 'create'\r\n");
                result.Append($"                THROW 51000, 'Chave-primária já existe em {table["Name"]}', 1\r\n");
                result.Append($"        END ELSE IF @Action = 'delete' AND EXISTS(SELECT 1\r\n");
                result.Append($"                                    FROM [dbo].[Operations]\r\n");
                result.Append($"                                    WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                                          AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                                          AND [IsConfirmed] IS NULL\r\n");
                result.Append($"                                          AND [Action] = 'create'\r\n");
                result.Append($"                                          AND CAST(JSON_VALUE(ISNULL([ActualRecord], [LastRecord]), '$.Id') AS {physicalColumnRows[0]["#DataType"]}) = @W_Id)\r\n");
                result.Append($"            SET @IsPendingCreate = 1\r\n");
                result.Append($"        ELSE IF @Action <> 'create'\r\n");
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
                        result.Append($"            IF EXISTS(SELECT 1 FROM [dbo].[{reference["#TableName"]}] WHERE [{reference["Name"]}] = @W_Id)\r\n");
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
                    if (validations.TryGetValue("Minimum", out value))
                    {
                        result.Append($"            IF {(isRequired ? string.Empty : $"@W_{column["Name"]} IS NOT NULL AND ")}@W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]})\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord deve ser maior que ou igual a {value}', 1\r\n");
                    }
                    if (validations.TryGetValue("Maximum", out value))
                    {
                        result.Append($"            IF {(isRequired ? string.Empty : $"@W_{column["Name"]} IS NOT NULL AND ")}@W_{column["Name"]} > CAST('{value}' AS {column["#DataType"]})\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord deve ser menor que ou igual a {value}', 1\r\n");
                    }
                    if (!Settings.IsNull(column["ReferenceTableId"]))
                    {
                        var referenceTable = tables.First(table => Settings.ToLong(table["Id"]) == Settings.ToLong(column["ReferenceTableId"]));
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
                    result.Append($"            IF @Action = 'create' BEGIN\r\n");
                    foreach (var index in uniqueIndexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => Settings.ToLong(indexkey["IndexId"]) == Settings.ToLong(index["Id"]));

                        firstTime = true;
                        foreach (var indexkey in indexkeyRows)
                        {
                            var column = columns.First(column => Settings.ToLong(column["Id"]) == Settings.ToLong(indexkey["ColumnId"]));
                            if (IsVirtualColumn(column))
                                continue;

                            if (firstTime)
                            {
                                result.Append($"                IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                firstTime = false;
                            }
                            else
                                result.Append($" AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
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

                        firstTime = true;
                        foreach (var indexkey in indexkeyRows)
                        {
                            var column = columns.First(column => Settings.ToLong(column["Id"]) == Settings.ToLong(indexkey["ColumnId"]));
                            if (IsVirtualColumn(column))
                                continue;

                            if (firstTime)
                            {
                                result.Append($"            ELSE IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                firstTime = false;
                            }
                            else
                                result.Append($" AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
                        result.Append($" AND [Id] <> @W_Id");
                        result.Append($")\r\n");
                        result.Append($"                THROW 51000, 'Chave única de {index["Name"]} já existe', 1\r\n");
                    }
                    foreach (var unique in uniqueRows)
                    {
                        result.Append($"            ELSE IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName1"]}] WHERE [{unique["#ColumnName1"]}] = @W_{unique["#ColumnName2"]} AND [Id] <> @W_Id)\r\n");
                        result.Append($"                THROW 51000, 'Unicidade cruzada de [{unique["#TableAlias1"]}].[{unique["#ColumnName1"]}] => [{unique["#TableAlias2"]}].[{unique["#ColumnName2"]}] já existe', 1\r\n");
                        if (Settings.ToBoolean(unique["IsBidirectional"]))
                        {
                            result.Append($"            ELSE IF EXISTS(SELECT 1 FROM [dbo].[{unique["#TableName2"]}] WHERE [{unique["#ColumnName2"]}] = @W_{unique["#ColumnName1"]} AND [Id] <> @W_Id)\r\n");
                            result.Append($"                THROW 51000, 'Unicidade cruzada de [{unique["#TableAlias2"]}].[{unique["#ColumnName2"]}] => [{unique["#TableAlias1"]}].[{unique["#ColumnName1"]}] já existe', 1\r\n");
                        }
                    }

                    result.Append($"            END\r\n");
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

        private static StringBuilder GetScriptReadTable(DataRow table, TDataRows columns, TDataRows domains, TDataRows types)
        {
            var result = new StringBuilder();
            var columnRows = GetTableColumnRows(columns, table);
            var physicalColumnRows = GetTableColumnRows(columns, table, physicalOnly: true);
            var listableColumns = columnRows.FindAll(row => Settings.ToBoolean(row["IsListable"]) && !IsVirtualColumn(row));
            DataRow? listableColumn = listableColumns.Count > 0 ? listableColumns[0] : null;

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Name"]}Read]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Name"]}Read]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Name"]}Read] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Name"]}Read](@Login NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@RecordFilterGrid NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@RecordFilterTable NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@RecordSearch NVARCHAR(MAX)\r\n");
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
                result.Append($"    DECLARE @LoginId BIGINT\r\n");
                AppendLoginCall(result, "@LoginId");
                result.Append($"    IF @RecordFilterGrid IS NULL\r\n");
                result.Append("            SET @RecordFilterGrid = '{}'\r\n");
                result.Append($"        ELSE IF ISJSON(@RecordFilterGrid) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @RecordFilterGrid não está no formato JSON', 1\r\n");
                result.Append($"        IF @RecordFilterTable IS NULL\r\n");
                result.Append("            SET @RecordFilterTable = '{}'\r\n");
                result.Append($"        ELSE IF ISJSON(@RecordFilterTable) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @RecordFilterTable não está no formato JSON', 1\r\n");
                result.Append($"        IF @RecordSearch IS NOT NULL AND ISJSON(@RecordSearch) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @RecordSearch não está no formato JSON', 1\r\n");
                result.Append($"        SET @OrderBy = TRIM(ISNULL(@OrderBy, ''))\r\n");
                result.Append($"        IF @OrderBy = ''\r\n");
                result.Append($"            SET @OrderBy = '[T].[Id] ASC'\r\n");
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
                result.Append($"            IF CHARINDEX('[T].[Id]', @OrderBy) = 0\r\n");
                result.Append($"                SET @OrderBy = @OrderBy + ', [T].[Id] ASC'\r\n");
                result.Append($"        END\r\n");
                if (listableColumn != null)
                {
                    result.Append($"        IF @IsActionList = 1\r\n");
                    result.Append($"            SET @OrderBy = '[T].[{listableColumn["Name"]}] ASC, [T].[Id] ASC'\r\n");
                    result.Append($"        DECLARE @PickerValue {listableColumn["#DataType"]} = NULL\r\n");
                }
                result.Append($"\r\n");
                result.Append($"        DECLARE @TransactionId BIGINT = (SELECT MAX([Id]) FROM [dbo].[Transactions] WHERE [SessionId] = @LoginId)\r\n");
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
                result.Append($"        CREATE UNIQUE INDEX [#tmpOperations] ON [#tmpOperations]([Id])\r\n");
                result.Append($"\r\n");

                var filterableColumns = physicalColumnRows.FindAll(column => Settings.ToBoolean(column["IsFilterable"]));
                var idDataType = physicalColumnRows[0]["#DataType"];

                result.Append($"        DECLARE @_ NVARCHAR(MAX) = (SELECT STRING_AGG(value, ',') FROM OPENJSON(@RecordFilterGrid, '$._'))\r\n");
                result.Append($"               ,@Where NVARCHAR(MAX) = ''\r\n");
                result.Append($"               ,@sql NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                if (filterableColumns.Count > 0)
                {
                    firstTime = true;
                    foreach (var column in filterableColumns)
                    {
                        if (firstTime)
                        {
                            result.Append($"        DECLARE @WT_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@RecordFilterTable, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"               ,@WT_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@RecordFilterTable, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                    }
                    result.Append($"\r\n");
                    foreach (var column in filterableColumns)
                        AppendReadTableFilterColumn(result, column, domains, types, $"@WT_{column["Name"]}", $"@T_{column["Name"]}", "        ");
                }
                if (listableColumn != null)
                {
                    result.Append($"        IF @IsActionList = 1 BEGIN\r\n");
                    result.Append($"            SET @PickerValue = CAST(JSON_VALUE(@RecordFilterGrid, '$.Picker.Value') AS {listableColumn["#DataType"]})\r\n");
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
                    AppendReadGridFilterDeclareVars(result, column, isSearch: false, declare: firstTime);
                    firstTime = false;
                }
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                foreach (var column in filterableColumns)
                    AppendReadGridFilterAssignVars(result, column, isSearch: false);
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                foreach (var column in filterableColumns)
                    AppendReadFilterColumn(result, column, domains, types, "            ");
                result.Append($"        END ELSE\r\n");
                result.Append($"            SET @Where = @Where + ' AND [T].[Id] IN (' + @_ + ')'\r\n");

                result.Append($"        CREATE TABLE [#tmpTable]([_] CHAR(1), [Recno] BIGINT, [Id] {idDataType})\r\n");
                result.Append($"        SET @sql = 'INSERT [#tmpTable]([_], [Recno], [Id])\r\n");
                result.Append($"                        SELECT [_]\r\n");
                result.Append($"                              ,[Recno]\r\n");
                result.Append($"                              ,[Id]\r\n");
                result.Append($"                            FROM (SELECT ''T'' AS [_]\r\n");
                result.Append($"                                        ,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS [Recno]\r\n");
                result.Append($"                                        ,[T].[Id]\r\n");
                result.Append($"                                    FROM [dbo].[{table["Name"]}] [T]\r\n");
                result.Append($"                                        LEFT JOIN [#tmpOperations] [#] ON [#].[Id] = [T].[Id]\r\n");
                result.Append($"                                    WHERE [#].[Id] IS NULL' + @Where + '\r\n");
                result.Append($"                                  UNION ALL\r\n");
                result.Append($"                                  SELECT ''O'' AS [_]\r\n");
                result.Append($"                                        ,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') + (SELECT COUNT(*) FROM [#tmpTable] [#] WHERE [#].[_] = ''T'') AS [Recno]\r\n");
                result.Append($"                                        ,[T].[Id]\r\n");
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
                    AppendReadExecutesqlParams(result, filterableColumns, includeTableFilters: true, includeGridFilters: true, "                               ");
                    AppendReadExecutesqlAssignments(result, filterableColumns, includeTableFilters: true, includeGridFilters: true, "                               ");
                }
                else
                    result.Append($"            EXEC sp_executesql @sql\r\n");

                result.Append($"        END ELSE BEGIN\r\n");
                if (filterableColumns.Count > 0)
                {
                    result.Append($"            EXEC sp_executesql @sql\r\n");
                    AppendReadExecutesqlParams(result, filterableColumns, includeTableFilters: true, includeGridFilters: false, "                               ");
                    AppendReadExecutesqlAssignments(result, filterableColumns, includeTableFilters: true, includeGridFilters: false, "                               ");
                }
                else
                    result.Append($"            EXEC sp_executesql @sql\r\n");
                result.Append($"        END\r\n");

                result.Append($"\r\n");
                result.Append($"        DECLARE @RowCount INT = @@ROWCOUNT\r\n");
                result.Append($"               ,@OffSet INT\r\n");
                result.Append($"\r\n");
                result.Append($"        CREATE UNIQUE INDEX [#tmpTable] ON [#tmpTable]([Id])\r\n");
                result.Append($"        IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\r\n");
                result.Append($"            SET @OffSet = 0\r\n");
                result.Append($"            SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END\r\n");
                result.Append($"            SET @PageNumber = 1\r\n");
                result.Append($"            SET @MaxPage = 1\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END\r\n");
                result.Append($"            DECLARE @SearchRecno BIGINT = NULL\r\n");
                result.Append($"            IF @RecordSearch IS NOT NULL BEGIN\r\n");

                if (filterableColumns.Count > 0)
                {
                    result.Append($"                DECLARE @Recno BIGINT\r\n");
                    foreach (var column in filterableColumns)
                        AppendReadGridFilterDeclareVars(result, column, isSearch: true, declare: false);
                }
                else
                    result.Append($"                DECLARE @Recno BIGINT\r\n");
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                foreach (var column in filterableColumns)
                    AppendReadGridFilterAssignVars(result, column, isSearch: true);
                if (filterableColumns.Count > 0)
                    result.Append($"\r\n");
                result.Append($"                SET @Where = ''\r\n");
                foreach (var column in filterableColumns)
                    AppendReadSearchCondition(result, column, "                ");
                result.Append($"                IF @Where <> '' BEGIN\r\n");
                result.Append($"                    SET @sql = N'SELECT TOP 1 @r = [#].[Recno]\r\n");
                result.Append($"                                    FROM [#tmpTable] [#]\r\n");
                result.Append($"                                        LEFT JOIN [dbo].[{table["Name"]}] [D] ON [D].[Id] = [#].[Id] AND [#].[_] = ''T''\r\n");
                result.Append($"                                        LEFT JOIN [#tmpOperations] [O] ON [O].[Id] = [#].[Id] AND [#].[_] = ''O''\r\n");
                result.Append($"                                    WHERE ' + @Where\r\n");
                if (filterableColumns.Count > 0)
                {
                    firstTime = true;
                    foreach (var column in filterableColumns)
                    {
                        var name = column["Name"];
                        var dataType = column["#DataType"];
                        if (firstTime)
                        {
                            result.Append($"                    EXEC sp_executesql @sql\r\n");
                            result.Append($"                                       ,N'@{name} {dataType},@{name}_v1 {dataType},@{name}_v2 {dataType},@{name}_vals NVARCHAR(MAX)");
                            firstTime = false;
                        }
                        else
                            result.Append($",@{name} {dataType},@{name}_v1 {dataType},@{name}_v2 {dataType},@{name}_vals NVARCHAR(MAX)");
                    }
                    result.Append($", @r BIGINT OUTPUT'\r\n");
                    foreach (var column in filterableColumns)
                    {
                        var name = column["Name"];
                        result.Append($"                                       ,@{name} = @S_{name}_v\r\n");
                        result.Append($"                                       ,@{name}_v1 = @S_{name}_v1\r\n");
                        result.Append($"                                       ,@{name}_v2 = @S_{name}_v2\r\n");
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
                result.Append($"                                INNER JOIN [dbo].[{table["Name"]}] [T] ON [T].[Id] = [#].[Id]\r\n");
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
                result.Append($"                                    INNER JOIN [#tmpOperations] [O] ON [O].[Id] = [#].[Id]\r\n");
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
    }
}