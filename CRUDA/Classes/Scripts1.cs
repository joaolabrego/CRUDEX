using ClosedXML.Excel;
using CRUDA.Classes.Models;
using CRUDA_LIB;
using System.Data;
using System.Text;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA.Classes
{
    public class Scripts1
    {
        static readonly string DirectoryScripts = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_SCRIPTS"));
        public static void GenerateScript(string systemName, string databaseName)
        {
            try
            {
                var dataSet = ExcelToDataSet();
                var columns = (dataSet.Tables["Columns"] ?? throw new Exception("Tabela Columns não existe.")).Select();
                var indexes = (dataSet.Tables["Indexes"] ?? throw new Exception("Tabela Indexes não existe.")).Select();
                var indexkeys = (dataSet.Tables["Indexkeys"] ?? throw new Exception("Tabela Indexkeys não existe.")).Select();
                var domains = (dataSet.Tables["Domains"] ?? throw new Exception("Tabela Domains não existe.")).Select();
                var categories = (dataSet.Tables["Categories"] ?? throw new Exception("Tabela Categories não existe.")).Select();
                var types = (dataSet.Tables["Types"] ?? throw new Exception("Tabela Types não existe.")).Select();
                var system = (dataSet.Tables["Systems"] ?? throw new Exception("Tabela Systems não existe.")).Select($"Name = '{systemName}'")[0];
                var database = (dataSet.Tables["Databases"] ?? throw new Exception("Tabela Databases não existe.")).Select($"Name = '{databaseName}'")[0];
                var databasesTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("Tabela DatabasesTables não existe.")).Select($"DatabaseId =  {database["Id"]}");
                var tables = (dataSet.Tables["Tables"] ?? throw new Exception("Tabela Tables não existe.")).Select();
                var filename = Path.Combine(DirectoryScripts, $"SCRIPT-{systemName.ToUpper()}-{databaseName.ToUpper()}.sql");
                var firstTime = true;
                using var stream = new StreamWriter(path: filename, append: false, encoding: Encoding.UTF8);
                foreach (DataRow databaseTable in databasesTables)
                {
                    var table = tables.First(table => Convert.ToInt64(table["Id"]) == Convert.ToInt64(databaseTable["TableId"]));
                    if (firstTime)
                    {
                        stream.Write(GetCreateDatabase(database));
                        stream.Write(GetCreatePrerequisites());
                        firstTime = false;
                    }
                    stream.Write(GetCreateTable(table, columns, indexes, indexkeys, domains, types));
                    stream.Write(GetCommit(table, tables, columns, domains, types, categories, indexes, indexkeys));
                }
                stream.Write(GetCreateReferences(tables, columns));
                foreach (var table in tables)
                    stream.Write(GetDmlScript(table, columns, domains, types, categories, (dataSet.Tables[ToString(table["Name"])] ?? new DataTable()).Select()));
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
        private static string GetDataType(DataRow type, DataRow domain)
        {
            var result = string.Empty;

            result += type["Name"];
            if (ToDouble(domain["Length"]) > 0)
            {
                result += $"({domain["Length"]}";
                if (ToDouble(domain["Decimals"]) > 0)
                    result += ($", {domain["Decimals"]}");
                result += $")";
            }
            else if (ToBoolean(type["AllowMaxLength"]))
                result += $"(MAX)";

            return result;
        }
        private static bool ToBoolean(object? value)
        {
            if (value == DBNull.Value || value == null)
                return false;

            return Convert.ToBoolean(value);
        }
        private static double ToDouble(object? value)
        {
            if (value == DBNull.Value || value == null)
                return 0.0;

            var strValue = value.ToString();

            if (string.IsNullOrEmpty(strValue) || string.IsNullOrWhiteSpace(strValue))
                return 0.0;

            return Convert.ToDouble(value);
        }
        private static string ToString(object? value)
        {
            if (value == DBNull.Value || value == null)
                return string.Empty;

            return Convert.ToString(value) ?? string.Empty;
        }
        private static TDictionary GetValidations(DataRow type, DataRow domain, DataRow column)
        {
            var result = new TDictionary();
            var columnName = ToString(column["Name"]);
            var value = string.Empty;

            if (ToBoolean(column["IsRequired"]))
                result.Add("IsRequired", "");
            if ((value = ToString(column["Minimum"])) == string.Empty)
                if ((value = ToString(domain["Minimum"])) == string.Empty)
                    value = ToString(type["Minimum"]);
            if (value != string.Empty)
                result.Add("Minimum", value);
            if ((value = ToString(column["Maximum"])) == string.Empty)
                if ((value = ToString(domain["Maximum"])) == string.Empty)
                    value = ToString(type["Maximum"]);
            if (value != string.Empty)
                result.Add("Maximum", value);

            return result;
        }

        private static string GetCreateDatabase(DataRow database)
        {
            var result = new StringBuilder();
            var name = database["Name"];
            var alias = database["Alias"];

            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar banco-de-dados {name}");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine($"USE [master]");
            result.AppendLine($"SET NOCOUNT ON");
            result.AppendLine($"IF EXISTS(SELECT 1 FROM sys.databases where name = '{alias}')");
            result.AppendLine($"DROP DATABASE {alias}");
            result.AppendLine($"GO");
            result.AppendLine($"CREATE DATABASE [{alias}]");
            result.AppendLine($"CONTAINMENT = NONE");
            result.AppendLine($"ON PRIMARY");
            result.AppendLine($"(NAME = N'cruda', FILENAME = N'{database["Folder"]}{name}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)");
            result.AppendLine($"LOG ON");
            result.AppendLine($"(NAME = N'cruda_log', FILENAME = N'{database["Folder"]}{name}_log.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)");
            result.AppendLine($"WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET COMPATIBILITY_LEVEL = 160");
            result.AppendLine($"GO");
            result.AppendLine($"IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))");
            result.AppendLine($"BEGIN");
            result.AppendLine($"EXEC[{alias}].[dbo].[sp_fulltext_database] @action = 'enable'");
            result.AppendLine($"END");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ANSI_NULL_DEFAULT OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ANSI_NULLS OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ANSI_PADDING OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ANSI_WARNINGS OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ARITHABORT OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET AUTO_CLOSE OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET AUTO_SHRINK OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET AUTO_UPDATE_STATISTICS ON");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET CURSOR_CLOSE_ON_COMMIT OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET CURSOR_DEFAULT  GLOBAL");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET CONCAT_NULL_YIELDS_NULL OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET NUMERIC_ROUNDABORT OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET QUOTED_IDENTIFIER OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET RECURSIVE_TRIGGERS OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET  DISABLE_BROKER");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET AUTO_UPDATE_STATISTICS_ASYNC OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET DATE_CORRELATION_OPTIMIZATION OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET TRUSTWORTHY OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ALLOW_SNAPSHOT_ISOLATION ON");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET PARAMETERIZATION SIMPLE");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET READ_COMMITTED_SNAPSHOT OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET HONOR_BROKER_PRIORITY OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET RECOVERY SIMPLE");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET  MULTI_USER");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET PAGE_VERIFY CHECKSUM");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET DB_CHAINING OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF)");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET TARGET_RECOVERY_TIME = 60 SECONDS");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET DELAYED_DURABILITY = DISABLED");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET ACCELERATED_DATABASE_RECOVERY = OFF");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET QUERY_STORE = ON");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER DATABASE[{alias}] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)");
            result.AppendLine($"GO");
            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Início da criação dos scripts");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine($"USE [{alias}]");
            result.AppendLine($"GO");
            result.AppendLine($"SET ANSI_NULLS ON");
            result.AppendLine($"GO");
            result.AppendLine($"SET QUOTED_IDENTIFIER ON");
            result.AppendLine($"GO");

            return result.ToString();
        }
        private static string GetCreatePrerequisites()
        {
            var result = new StringBuilder();

            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar function F_IsEquals");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine(File.ReadAllText(Path.Combine(DirectoryScripts, "F_IsEquals.sql")));
            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar function F_NumberInWordsOfHundreds");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine(File.ReadAllText(Path.Combine(DirectoryScripts, "F_NumberInWordsOfHundreds.sql")));
            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar function F_NumberInWords");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine(File.ReadAllText(Path.Combine(DirectoryScripts, "F_NumberInWords.sql")));
            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar stored procedure P_Config");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine(File.ReadAllText(Path.Combine(DirectoryScripts, "P_Config.sql")));
            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar stored procedure P_GenerateId");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine(File.ReadAllText(Path.Combine(DirectoryScripts, "P_GenerateId.sql")));
            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar stored procedure P_Login");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine(File.ReadAllText(Path.Combine(DirectoryScripts, "P_Login.sql")));

            return result.ToString();
        }
        private static DataSet ExcelToDataSet()
        {
            var workbook = new XLWorkbook(Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("FILENAME_EXCEL")));
            var dataSet = new DataSet();

            foreach (IXLWorksheet worksheet in workbook.Worksheets)
            {
                var dataTable = new DataTable(worksheet.Name);
                var usedRange = worksheet.RangeUsed();

                foreach (IXLCell cell in usedRange.Row(1).Cells(1, usedRange.ColumnCount()))
                    dataTable.Columns.Add(cell.GetValue<string>());
                for (int rowIndex = 2; rowIndex <= usedRange.RowCount(); rowIndex++) // Começar do 2 porque a linha 1 é o cabeçalho
                {
                    var row = usedRange.Row(rowIndex);
                    object[] rowData = new object[usedRange.ColumnCount()];

                    for (int colIndex = 1; colIndex <= usedRange.ColumnCount(); colIndex++)
                        rowData[colIndex - 1] = row.Cell(colIndex).CachedValue;
                    dataTable.Rows.Add(rowData);
                }
                dataSet.Tables.Add(dataTable);
            }

            return dataSet;
        }
        private static string GetCreateTable(DataRow table, DataRow[] columns, DataRow[] indexes, DataRow[] indexkeys, DataRow[] domains, DataRow[] types)
        {
            var result = new StringBuilder();
            var columnsPrimaryKey = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);
            var listIndexes = indexes.Where(index => index["TableId"] == table["Id"]);
            var listReferences = columns.Where(column => column["ReferenceTableId"] == table["Id"]);
            var commaPrimarykey = string.Empty;
            var commaColunms = string.Empty;
            var typeName = string.Empty;

            if (listColumns.Any())
            {
                result.AppendLine($"/**********************************************************************************");
                result.AppendLine($"Criar tabela {table["Name"]}");
                result.AppendLine($"**********************************************************************************/");
                result.AppendLine($"IF (SELECT object_id('[dbo].[{table["Name"]}]', 'U')) IS NOT NULL");
                result.AppendLine($"DROP TABLE [dbo].[{table["Name"]}]");
                result.AppendLine($"CREATE TABLE [dbo].[{table["Name"]}](");
                foreach (DataRow column in listColumns)
                {
                    var domain = domains.First(d => d["Id"] == column["DomainId"]);
                    var type = types.First(t => t["Id"] == domain["TypeId"]);

                    typeName = GetDataType(type, domain);
                    result.AppendLine($"{commaColunms}[{column["Name"]}] {typeName} " +
                                      $"{(ToBoolean(column["IsRequired"]) ? "NOT NULL" : "NULL")}");
                    if (ToBoolean(column["IsPrimarykey"]))
                    {
                        columnsPrimaryKey.Append($"{commaPrimarykey}[{column["Name"]}]");
                        commaPrimarykey = ",";
                    }
                    commaColunms = ",";
                }
                result.AppendLine($",[CreatedAt] datetime NOT NULL");
                result.AppendLine($",[CreatedBy] varchar(25) NOT NULL");
                result.AppendLine($",[UpdatedAt] datetime NULL");
                result.AppendLine($",[UpdatedBy] varchar(25) NULL)");
            }
            if (columnsPrimaryKey.Length > 0)
                result.AppendLine($"ALTER TABLE [dbo].[{table["Name"]}] ADD CONSTRAINT PK_{table["Name"]} " +
                                  $"PRIMARY KEY CLUSTERED ({columnsPrimaryKey})");
            if (listIndexes.Any())
            {
                foreach (var index in listIndexes)
                {
                    var listIndexkeys = indexkeys.Where(indexkey => indexkey["IndexId"] == index["Id"]);

                    result.Append($"CREATE ");
                    if (ToBoolean(index["IsUnique"]))
                        result.Append($"UNIQUE ");
                    result.Append($"INDEX [{index["Name"]}] ON [dbo].[{table["Name"]}](");
                    commaColunms = string.Empty;

                    if (listIndexkeys.Any())
                    {
                        foreach (var indexkey in listIndexkeys)
                        {
                            var column = listColumns.First(column => column["Id"] == indexkey["ColumnId"]);

                            result.Append($"{commaColunms}[{column["Name"]}] " +
                                          $"{(ToBoolean(indexkey["IsDescending"]) ? "DESC" : "ASC")}");
                            commaColunms = ",";
                        }
                        result.AppendLine($")");
                    }
                }
            }
            result.AppendLine($"GO");

            return result.ToString();
        }
        private static string GetCreateReferences(DataRow[] tables, DataRow[] columns)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["ReferenceTableId"] != null);
            var lastTableName = string.Empty;

            if (listColumns.Any())
            {
                foreach (var column in listColumns)
                {
                    var primaryTable = tables.First(table => table["Id"] == column["TableId"]);
                    var referencedTable = tables.First(table => table["Id"] == column["ReferenceTableId"]);
                    var referencedPrimarykey = columns.First(column => column["TableId"] == referencedTable["Id"] && ToBoolean(column["IsPrimarykey"]));
                    var foreignKeyName = $"FK_{primaryTable["Name"]}_{referencedTable["Name"]}";

                    if (primaryTable["Name"].ToString() != lastTableName)
                    {
                        result.AppendLine($"/**********************************************************************************");
                        result.AppendLine($"Criar referências de {primaryTable["Name"]})");
                        result.AppendLine($"**********************************************************************************/");
                        lastTableName = primaryTable["Name"].ToString();
                    }
                    result.AppendLine($"IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS " +
                                      $"WHERE CONSTRAINT_NAME = '{foreignKeyName}')");
                    result.AppendLine($"ALTER TABLE [dbo].[{primaryTable["Name"]}] DROP CONSTRAINT {foreignKeyName}");
                    result.AppendLine($"GO");
                    result.Append($"ALTER TABLE [dbo].[{primaryTable["Name"]}] WITH CHECK ");
                    result.Append($"ADD CONSTRAINT [{foreignKeyName}] ");
                    result.Append($"FOREIGN KEY([{column["Name"]}]) ");
                    result.AppendLine($"REFERENCES [dbo].[{referencedTable["Name"]}] ([{referencedPrimarykey["Name"]}])");
                    result.AppendLine($"GO");
                    result.AppendLine($"ALTER TABLE [dbo].[{primaryTable["Name"]}] CHECK CONSTRAINT [{foreignKeyName}]");
                    result.AppendLine($"GO");
                }
            }

            return result.ToString();
        }
        private static string GetDmlScript(DataRow table, DataRow[] columns, DataRow[] domains, DataRow[] types, DataRow[] categories, DataRow[] datatable)
        {
            string sql = string.Empty,
                comma,
                cols,
                vals;
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);
            dynamic? value;

            if (listColumns.Any())
            {
                sql += $"/**********************************************************************************\r\n";
                sql += $"Inserir dados na tabela {table["Name"]}\r\n";
                sql += $"**********************************************************************************/\r\n";
                sql += $"GO\r\n";

                foreach (var row in datatable)
                {
                    cols = vals = comma = string.Empty;
                    foreach (var column in listColumns)
                    {
                        var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                        var type = types.First(type => type["Id"] == domain["TypeId"]);
                        var category = categories.First(category => category["Id"] == type["CategoryId"]);

                        cols += $"{comma}\r\n[{column["Name"]}]";
                        value = row[ToString(column["Name"])];
                        if (ToString(category["Name"]) == "numeric")
                            value ??= null;
                        else if (ToString(category["Name"]) == "boolean")
                            value = value == null ? null : value ? 1 : 0;
                        if ((value = ToString(value)) == string.Empty)
                            value = "NULL";
                        else if (!"undefined;date;datetime;time;".Contains($"{ToString(category["Name"])};"))
                            value = $"'{value}'";
                        vals += $"{comma}\r\n{value}";
                        comma = ", ";
                    }
                    cols += $"{comma}\r\nCreatedAt,\r\nCreatedBy";
                    vals += $"{comma}\r\nGETDATE(),\r\n'adm'";

                    sql += $"INSERT INTO [dbo].[{table["Name"]}] ({cols}) VALUES ({vals})\r\nGO\r\n";
                }
            }

            return sql;
        }
        private static string GetCommit(DataRow table, DataRow[] tables, DataRow[] columns, DataRow[] domains, DataRow[] types, DataRow[] categories, DataRow[] indexes, DataRow[] indexkeys)
        {
            var result = new StringBuilder();

            result.AppendLine($"IF(SELECT object_id('[dbo].[{table["Name"]}Commit]', 'P')) IS NULL");
            result.AppendLine($"    EXEC('CREATE PROCEDURE [dbo].[{table["Name"]}Commit] AS PRINT 1')");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER PROCEDURE[dbo].[{table["Name"]}Commit](@OperationId BIGINT) AS BEGIN");
            result.AppendLine($"    BEGIN TRY");
            result.AppendLine($"        SET NOCOUNT ON");
            result.AppendLine($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED");
            result.AppendLine($"");
            result.AppendLine($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '");
            result.AppendLine($"");
            result.AppendLine($"        IF @OperationId IS NULL BEGIN");
            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';");
            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"        END");
            result.AppendLine($"");
            result.AppendLine($"        DECLARE @TransactionId BIGINT,");
            result.AppendLine($"                ,@LastRecord VARCHAR(MAX)");
            result.AppendLine($"                ,@ActualRecord VARCHAR(MAX)");
            result.AppendLine($"                ,@IsConfirmed BIT");
            result.AppendLine($"                ,@Action VARCHAR(15)");
            result.AppendLine($"");
            result.AppendLine($"        SELECT @TransactionId = [TransactionId]");
            result.AppendLine($"              ,@LastRecord = [LastRecord]");
            result.AppendLine($"              ,@ActualRecord = [ActualRecord]");
            result.AppendLine($"              ,@IsConfirmed = [IsConfirmed]");
            result.AppendLine($"              ,@Action = [Action]");
            result.AppendLine($"            FROM [dbo].[Operations]");
            result.AppendLine($"            WHERE [Id] = @OperationId");
            result.AppendLine($"        IF @TransactionId IS NULL BEGIN");
            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';");
            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"        END");
            result.AppendLine($"        IF @IsConfirmed IS NOT NULL BEGIN");
            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';");
            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"        END");
            result.AppendLine($"        IF @Action NOT IN ('create', 'update', 'delete') BEGIN");
            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';");
            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"        END");
            result.AppendLine($"");
            result.AppendLine($"        DECLARE @LoginId BIGINT");
            result.AppendLine($"");
            result.AppendLine($"        SELECT @LoginId = [LoginId]");
            result.AppendLine($"              ,@IsConfirmed = [IsConfirmed]");
            result.AppendLine($"            FROM [dbo].[Transactions]");
            result.AppendLine($"            WHERE [Id] = @TransactionId");
            result.AppendLine($"        IF @LoginId IS NULL BEGIN");
            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';");
            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"        END");
            result.AppendLine($"        IF @IsConfirmed IS NOT NULL BEGIN");
            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';");
            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"        END");
            result.AppendLine($"");
            {
                var columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == Convert.ToInt64(table["Id"]) && ToBoolean(row["IsPrimarykey"]) && !ToBoolean(row["IsAutoIncrement"]));

                if (columnRows.Any())
                {
                    var separator = String.Empty;
                    var firstTime = true;

                    foreach (var columnRow in columnRows)
                    {
                        var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"]));
                        var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"]));

                        if (firstTime)
                        {
                            result.AppendLine($"    DECLARE @W_{columnRow["Name"]} {typeRow["Name"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {typeRow["Name"]})");
                            firstTime = false;
                        }
                        else
                            result.AppendLine($"               ,@W_{columnRow["Name"]} {typeRow["Name"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {typeRow["Name"]})");
                    }

                    columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == Convert.ToInt64(table["Id"]) && !ToBoolean(row["IsPrimarykey"]) && !ToBoolean(row["IsAutoIncrement"]));
                    foreach (var columnRow in columnRows)
                    {
                        var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"]));
                        var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"]));
                        var validation = GetValidations(typeRow, domainRow, columnRow);

                        if (validation.ContainsKey("IsRequired"))
                        {
                            result.AppendLine($"        IF @W_{columnRow["Name"]} IS NULL BEGIN");
                            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Valor de [{columnRow["Name"]}] é requerido.';");
                            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
                            result.AppendLine($"        END");
                        }

                        if (validation.TryGetValue("Minimum", out dynamic? value))
                        {
                            result.AppendLine($"        IF @W_{columnRow["Name"]} < CAST('{value}' AS {GetDataType(typeRow, domainRow)}) BEGIN");
                            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Valor de [{columnRow["Name"]}] deve ser maior que ou igual à ''{value}''.';");
                            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
                            result.AppendLine($"        END");
                        }
                        if (validation.TryGetValue("Maximum", out value))
                        {
                            result.AppendLine($"        IF @W_{columnRow["Name"]} > CAST('{value}' AS {GetDataType(typeRow, domainRow)}) BEGIN");
                            result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Valor de [{columnRow["Name"]}] deve ser menor que ou igual à ''{value}''.';");
                            result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
                            result.AppendLine($"        END");
                        }
                    }
                    {
                        separator = string.Empty;
                        result.Append($"        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE ");
                        foreach (var columnRow in columnRows)
                        {
                            result.Append($"{separator}[{columnRow["Name"]}] = @W_{columnRow["Name"]}");
                            separator = " AND ";
                        }
                        result.AppendLine($") BEGIN");
                        result.AppendLine($"            IF @Action = '{Actions.CREATE}' BEGIN);");
                        result.AppendLine($"                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela {table["Name"]}.';");
                        result.AppendLine($"                THROW 51000, @ErrorMessage, 1");
                        result.AppendLine($"            END");
                        result.AppendLine($"        END ELSE IF @Action <> '{Actions.CREATE}' BEGIN");
                        result.AppendLine($"            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela {table["Name"]}.';");
                        result.AppendLine($"            THROW 51000, @ErrorMessage, 1");
                        result.AppendLine($"        END");
                        result.AppendLine($"        IF @Action <> '{Actions.DELETE}' BEGIN");
                        columnRows = columns.Where(row => !ToBoolean(row["IsPrimarykey"]) && !ToBoolean(row["IsAutoIncrement"]));
                        separator = String.Empty;
                        firstTime = true;
                        foreach (var columnRow in columnRows)
                        {
                            var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"]));
                            var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"]));

                            if (firstTime)
                            {
                                result.Append($"                DECLARE ");
                                firstTime = false;
                            }
                            result.AppendLine($"                    {separator}@W_{columnRow["Name"]} {typeRow["Name"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {typeRow["Name"]})");
                            separator = ",";
                        }
                        foreach (var columnRow in columnRows)
                        {
                            var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"]));
                            var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"]));
                            var validation = GetValidations(typeRow, domainRow, columnRow);

                            if (validation.ContainsKey("IsRequired"))
                            {
                                result.AppendLine($"            IF @W_{columnRow["Name"]} IS NULL BEGIN");
                                result.AppendLine($"                SET @ErrorMessage = @ErrorMessage + 'Valor de [{columnRow["Name"]}] é requerido.';");
                                result.AppendLine($"                THROW 51000, @ErrorMessage, 1");
                                result.AppendLine($"            END");
                            }

                            if (validation.TryGetValue("Minimum", out dynamic? value))
                            {
                                result.AppendLine($"            IF @W_{columnRow["Name"]} < CAST('{value}' AS {GetDataType(typeRow, domainRow)}) BEGIN");
                                result.AppendLine($"                SET @ErrorMessage = @ErrorMessage + 'Valor de [{columnRow["Name"]}] deve ser maior que ou igual à ''{value}''.';");
                                result.AppendLine($"                THROW 51000, @ErrorMessage, 1");
                                result.AppendLine($"            END");
                            }
                            if (validation.TryGetValue("Maximum", out value))
                            {
                                result.AppendLine($"            IF @W_{columnRow["Name"]} > CAST('{value}' AS {GetDataType(typeRow, domainRow)}) BEGIN");
                                result.AppendLine($"                SET @ErrorMessage = @ErrorMessage + 'Valor de [{columnRow["Name"]}] deve ser menor que ou igual à ''{value}''.';");
                                result.AppendLine($"                THROW 51000, @ErrorMessage, 1");
                                result.AppendLine($"            END");
                            }
                        }

                        var indexRows = indexes.Where(index => index["TableId"] == table["Id"]);

                        result.AppendLine($"            IF @Action = 'create' BEGIN");
                        foreach (var indexRow in indexRows)
                        {
                            var indexkeyRows = indexkeys.Where(row => Convert.ToInt64(row["IndexId"]) == Convert.ToInt64(indexRow["Id"]));

                            result.Append($"                    IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                            separator = string.Empty;
                            foreach (var indexkeyRow in indexkeyRows)
                            {
                                var columnRow = domains.First(row => Convert.ToInt64(row["Id"]) == Convert.ToInt64(indexkeyRow["ColumnId"]));

                                result.Append($"[{separator}{columnRow["Name"]}] = @W_{columnRow["Name"]}");
                                separator = " AND ";
                            }
                            result.AppendLine();
                            result.AppendLine($") BEGIN");
                            result.AppendLine($"                        SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe.';");
                            result.AppendLine($"                        THROW 51000, @ErrorMessage, 1");
                            result.AppendLine($"                    END");
                        }



                    }
                }
            }

            return result.ToString();
        }
    }
}
