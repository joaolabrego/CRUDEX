using CRUDA_LIB;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using System.Data;
using System.Text;
using TDataRow = System.Collections.Generic.Dictionary<string, dynamic?>;
using TDataTable = System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, dynamic?>>;
using TDataSet = System.Collections.Generic.Dictionary<string,
                 System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, dynamic?>>>;
using CRUDA.Classes.Models;
using Microsoft.Extensions.Primitives;

namespace CRUDA.Classes
{
    public class Scripts
    {
        static readonly string DirectoryScripts = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_SCRIPTS"));
        static public void GenerateScript(string systemName, string databaseName)
        {
            var dataSet = ExcelToDictionary();
            var columns = dataSet["Columns"];
            var indexes = dataSet["Indexes"];
            var indexkeys = dataSet["Indexkeys"];
            var domains = dataSet["Domains"];
            var categories = dataSet["Categories"];
            var types = dataSet["Types"];
            var system = dataSet["Systems"].First(system => system["Name"] == systemName);
            var database = dataSet["Databases"].First(database => database["Name"] == databaseName);
            var databasesTables = dataSet["DatabasesTables"].Where(databaseTable => databaseTable["DatabaseId"] == database["Id"]);
            var tables = dataSet["Tables"];
            var filename = Path.Combine(DirectoryScripts, $"SCRIPT-{systemName.ToUpper()}-{databaseName.ToUpper()}.sql");
            var firstTime = true;

            using var stream = new StreamWriter(path: filename, append: false, encoding: Encoding.UTF8);
            foreach (var databaseTable in databasesTables)
            {
                var table = tables.First(table => table["Id"] == databaseTable["TableId"]);
                if (firstTime)
                {
                    stream.Write(GetCreateDatabaseScript(database));
                    stream.Write(GetCreatePrerequisites());
                    firstTime = false;
                }
                stream.Write(GetCreateTableScript(table, columns, indexes, indexkeys, domains, types));
                if (ToString(table["ProcedureCreate"]) != string.Empty)
                    stream.Write(GetCreateScript(table, tables, columns, domains, types, categories, indexes, indexkeys));
                //if (ToString(table["FunctionValid"]) != string.Empty)
                //    stream.Write(GetValidScript(table, columns, domains, types, categories, indexes, indexkeys));
                if (ToString(table["ProcedureUpdate"]) != string.Empty)
                    stream.Write(GetUpdateScript(table, columns, domains, types, categories, indexes, indexkeys));
                if (ToString(table["ProcedureDelete"]) != string.Empty)
                    stream.Write(GetDeleteScript(table, columns, domains, types, categories));
                if (ToString(table["ProcedureRead"]) != string.Empty)
                    stream.Write(GetReadScript(system, database, table, columns, domains, types, categories));
            }
            stream.Write(GetCreateReferencesScript(tables, columns));
            foreach (var table in tables)
                stream.Write(GetDmlScript(table, columns, domains, types, categories, dataSet[ToString(table["Name"])] ?? new DataTable()));
        }
        private static string GetCreateDatabaseScript(TDataRow database)
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
        private static string GetCreateTableScript(TDataRow table, TDataTable columns, TDataTable indexes, TDataTable indexkeys, TDataTable domains, TDataTable types)
        {
            var result = new StringBuilder();
            var columnsPrimaryKey = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);
            var listIndexes = indexes.Where(index => index["TableId"] == table["Id"]);
            var listReferences = columns.Where(column => column["ReferenceTableId"] = table["Id"]);
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
                foreach (var column in listColumns)
                {
                    TDataRow domain = domains.First(d => d["Id"] == column["DomainId"]);
                    TDataRow type = types.First(t => t["Id"] == domain["TypeId"]);

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
        private static string GetCreateReferencesScript(TDataTable tables, TDataTable columns)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["ReferenceTableId"] != null);
            var lastTableName = string.Empty;

            if (listColumns.Any())
            {
                foreach (var column in listColumns)
                {
                    var table = tables.First(table => table["Id"] == column["TableId"]);
                    var referencedTable = tables.First(table => table["Id"] == column["ReferenceTableId"]);
                    var primaryKey = columns.First(column => column["TableId"] == table["Id"] && ToBoolean(column["IsPrimarykey"]));
                    var foreignKeyName = $"FK_{table["Name"]}_{referencedTable["Name"]}";

                    if (table["Name"] != lastTableName)
                    {
                        result.AppendLine($"/**********************************************************************************");
                        result.AppendLine($"Criar referências de {table["Name"]})");
                        result.AppendLine($"**********************************************************************************/");
                        lastTableName = table["Name"];
                    }
                    result.AppendLine($"IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS " +
                                      $"WHERE CONSTRAINT_NAME = '{foreignKeyName}')");
                    result.AppendLine($"ALTER TABLE [dbo].[{table["Name"]}] DROP CONSTRAINT {foreignKeyName}");
                    result.AppendLine($"GO");
                    result.Append($"ALTER TABLE [dbo].[{table["Name"]}] WITH CHECK ");
                    result.Append($"ADD CONSTRAINT [{foreignKeyName}] ");
                    result.Append($"FOREIGN KEY([{column["Name"]}]) ");
                    result.AppendLine($"REFERENCES [dbo].[{referencedTable["Name"]}] ([{primaryKey["Name"]}])");
                    result.AppendLine($"GO");
                    result.AppendLine($"ALTER TABLE [dbo].[{table["Name"]}] CHECK CONSTRAINT [{foreignKeyName}]");
                    result.AppendLine($"GO");
                }
            }

            return result.ToString();
        }
        private static string GetScriptParameters(string procedureName)
        {
            var result = new StringBuilder();

            result.AppendLine($"/**********************************************************************************");
            result.AppendLine($"Criar procedure {procedureName}");
            result.AppendLine($"**********************************************************************************/");
            result.AppendLine($"IF(SELECT object_id('{procedureName}', 'P')) IS NULL");
            result.AppendLine($"EXEC('CREATE PROCEDURE [dbo].[{procedureName}] AS PRINT 1')");
            result.AppendLine($"GO");
            result.AppendLine($"ALTER PROCEDURE[dbo].[{procedureName}](@Parameters VARCHAR(MAX)) AS");
            result.AppendLine($"BEGIN");
            result.AppendLine($"BEGIN TRY");
            result.AppendLine($"SET NOCOUNT ON");
            result.AppendLine($"SET TRANSACTION ISOLATION LEVEL READ COMMITTED");
            result.AppendLine($"DECLARE @ErrorMessage VARCHAR(255)");
            result.AppendLine($"IF ISJSON(@Parameters) = 0 BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))");
            result.AppendLine($"IF ISJSON(@Login) = 0 BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"EXEC [dbo].[P_Login] @Login");
            result.AppendLine($"DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))");
            result.AppendLine($",@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))");
            result.AppendLine($",@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))");
            result.AppendLine($",@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)");
            result.AppendLine($",@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))");
            result.AppendLine($",@TransactionId BIGINT");
            result.AppendLine($",@TableId BIGINT");
            result.AppendLine($",@Action VARCHAR(15)");
            result.AppendLine($",@ActualRecord VARCHAR(MAX)");
            result.AppendLine($",@IsConfirmed BIT");
            result.AppendLine($"SELECT @TransactionId = [TransactionId]");
            result.AppendLine($",@TableId = [TableId]");
            result.AppendLine($",@Action = [Action]");
            result.AppendLine($",@ActualRecord = [ActualRecord]");
            result.AppendLine($",@IsConfirmed = [IsConfirmed]");
            result.AppendLine($"FROM [dbo].[Operations]");
            result.AppendLine($"WHERE [Id] = @OperationId");
            result.AppendLine($"IF @@ROWCOUNT = 0 BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF @Action <> 'create' BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF @IsConfirmed IS NOT NULL BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Operação já ' + ");
            result.AppendLine($"CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF (SELECT [Name]");
            result.AppendLine($"FROM [dbo].[Tables]");
            result.AppendLine($"WHERE [Id] = @TableId) <> @TableName BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"DECLARE @SystemId BIGINT");
            result.AppendLine($",@DatabaseId BIGINT");
            result.AppendLine($"SELECT @SystemId = [SystemId]");
            result.AppendLine($",@DatabaseId = [DatabaseId]");
            result.AppendLine($",@IsConfirmed = [IsConfirmed]");
            result.AppendLine($"FROM [dbo].[Transactions]");
            result.AppendLine($"WHERE [Id] = @TransactionId");
            result.AppendLine($"IF @@ROWCOUNT = 0 BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF @IsConfirmed IS NOT NULL BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Transação já ' +");
            result.AppendLine($"CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF (SELECT [Name]");
            result.AppendLine($"FROM [dbo].[Systems]");
            result.AppendLine($"WHERE [Id] = @SystemId) <> @SystemName BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF (SELECT [Name]");
            result.AppendLine($"FROM [dbo].[Databases]");
            result.AppendLine($"WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");
            result.AppendLine($"IF NOT EXISTS(SELECT 1");
            result.AppendLine($"FROM [dbo].[DatabasesTables]");
            result.AppendLine($"WHERE [DatabaseId] = @DatabaseId");
            result.AppendLine($"AND [TableId] = @TableId) BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';");
            result.AppendLine($"THROW 51000, @ErrorMessage, 1");
            result.AppendLine($"END");

            return result.ToString();
        }
        private static string GetValidRange(TDataRow type, TDataRow domain, TDataRow column)
        {
            var result = new StringBuilder();
            var value = string.Empty;
            var valueMinimum = string.Empty;
            var valueMaximum = string.Empty;

            if ((value = valueMinimum = ToString(column["Minimum"])) == string.Empty)
                if ((value = valueMinimum = ToString(domain["Minimum"])) == string.Empty)
                    value = valueMinimum = ToString(type["Minimum"]);
            if (value != string.Empty)
            {
                var position = value.IndexOf('\'');

                value = value.Substring(position, value.LastIndexOf('\'') - position + 1);
                result.AppendLine($"IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.AppendLine($"@W_{column["Name"]} IS NOT NULL AND ");
                result.AppendLine($"@W_{column["Name"]} < {valueMinimum} BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} " +
                                  $"deve ser maior que ou igual à '{value}'.';");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.AppendLine($"END");
            }
            if ((value = valueMaximum = ToString(column["Maximum"])) == string.Empty)
                if ((value = valueMaximum = ToString(domain["Maximum"])) == string.Empty)
                    value = valueMaximum = ToString(type["Maximum"]);

            if (value != string.Empty)
            {
                var position = value.IndexOf('\'');

                value = value.Substring(position, value.LastIndexOf('\'') - position + 1);
                result.AppendLine($"IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.AppendLine($"@W_{column["Name"]} IS NOT NULL AND ");
                result.AppendLine($"@W_{column["Name"]} > {valueMaximum} BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} " +
                                  $"deve ser menor que ou igual à '{value}'.';\r\n");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.AppendLine($"END");
            }

            return result.ToString();
        }
        private static string GetScriptValidation(TDataRow type, TDataRow domain, TDataRow column)
        {
            var result = new StringBuilder();
            var columnName = ToString(column["Name"]);
            var columnIsRequired = ToBoolean(column["IsRequired"]);
            var value = string.Empty;
            var valueMinimum = string.Empty;
            var valueMaximum = string.Empty;

            if (columnIsRequired)
            {
                result.AppendLine($"IF @W_{columnName} IS NULL BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de {columnName} é requerido.';");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.AppendLine($"END");
            }
            if ((value = valueMinimum = ToString(column["Minimum"])) == string.Empty)
                if ((value = valueMinimum = ToString(domain["Minimum"])) == string.Empty)
                    value = valueMinimum = ToString(type["Minimum"]);
            if (value != string.Empty)
            {
                var position = value.IndexOf('\'');

                value = value.Substring(position, value.LastIndexOf('\'') - position + 1);
                result.Append($"IF ");
                if (!columnIsRequired)
                    result.Append($"@W_{columnName} IS NOT NULL AND ");
                result.AppendLine($"@W_{columnName} < {valueMinimum} BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} " +
                                  $"deve ser maior que ou igual à '{value}'.';");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.AppendLine($"END");
            }
            if ((value = valueMaximum = ToString(column["Maximum"])) == string.Empty)
                if ((value = valueMaximum = ToString(domain["Maximum"])) == string.Empty)
                    value = valueMaximum = ToString(type["Maximum"]);
            if (value != string.Empty)
            {
                var position = value.IndexOf('\'');

                value = value.Substring(position, value.LastIndexOf('\'') - position + 1);
                result.Append($"IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.Append($"@W_{column["Name"]} IS NOT NULL AND ");
                result.AppendLine($"@W_{column["Name"]} > {valueMaximum} BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} " +
                                  $"deve ser menor que ou igual à '{value}'.';");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.AppendLine($"END");
            }

            return result.ToString();
        }
        private static string GetScriptReferenceValidations(TDataRow column, TDataTable tables, TDataTable columns)
        {
            var result = new StringBuilder();
            var referencedTable = tables.First(table => table["Id"] == column["ReferenceTableId"]);
            var listPrimarykeys = columns.Where(column => column["TableId"] == referencedTable["Id"] &&
                                                          ToBoolean(column["IsPrimarykey"]));

            if (listPrimarykeys.Any())
            {
                var and = string.Empty;

                result.Append($"IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.Append($"@W_{column["Name"]} IS NOT NULL AND ");
                result.Append($"NOT EXISTS(SELECT 1 FROM [dbo].[{referencedTable["Name"]}] WHERE ");
                foreach (var primarykey in listPrimarykeys)
                {
                    result.Append($"{and}[{primarykey["Name"]}] = @W_{column["Name"]}");
                    and = "AND ";
                }
                result.AppendLine($") BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} " +
                                  $"não existe em {referencedTable["Name"]}';");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.Append($"END");
            }

            return result.ToString();
        }
        private static string GetScriptIndexValidations(TDataRow table, TDataTable indexes, TDataTable indexkeys)
        {
            var result = new StringBuilder();
            var listIndexes = indexes.Where(index => index["TableId"] == table["Id"]);
            /*
                    IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id) BEGIN
                        SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Columns.';
                        THROW 51000, @ErrorMessage, 1
                    END

            */
            if (listIndexes.Any())
            {
                foreach (var index in listIndexes)
                {
                    //var listIndexkeys = indexkeys.Where(indexkey => indexkey["IndexId"] == index["Id"]);

                    //var and = "";

                    //result.Append($"IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                    //foreach (var Indexkey in listIndexkeys)
                    //{
                    //    var column = listColumns.First(c => ToDouble(c["Id"]) == ToDouble(Indexkey["ColumnId"]));

                    //    sqlValids += $"{and}[{column["Name"]}] = @W_{column["Name"]}\r\n";
                    //    and = " AND ";
                    //}
                    //sqlValids += $") BEGIN\r\n";
                    //sqlValids += $"SET @ErrorMessage = @ErrorMessage + 'Chave única de índice {index["Name"]} já existe.';\r\n";
                    //sqlValids += $"THROW 51000, @ErrorMessage, 1\r\n";
                    //sqlValids += $"END\r\n";
                }
            }
            return result.ToString();
        }
        private static string GetCreateScript(TDataRow table, TDataTable tables, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories, TDataTable indexes, TDataTable indexkeys)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);
            

            if (listColumns.Any())
            {
                var sqlColumns = new StringBuilder();
                var sqlValues = new StringBuilder();
                var sqlValidations = new StringBuilder();
                var comma = string.Empty;
                var validation = string.Empty;

                result.Append(GetScriptParameters(table["ProcedureCreate"]));
                result.Append($"DECLARE ");
                foreach (var column in listColumns)
                {
                    var primaryTable = tables.First(table => table["Id"] == column["TableId"]);
                    var primaryKey = columns.First(column => ToBoolean(column["IsPrimarykey"]));

                    if (!ToBoolean(column["IsAutoIncrement"]))
                    {
                        var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                        var type = types.First(type => type["Id"] == domain["TypeId"]);
                        var category = categories.First(category => category["Id"] == type["CategoryId"]);
                        var typeName = GetDataType(type, domain);
                        var columnName = column["Name"];
                        
                        validation = GetScriptValidation(type, domain, column);
                        if (validation != string.Empty)
                            sqlValidations.Append(validation);
                        result.AppendLine($"{comma}@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})");
                        if (column["ReferenceTableId"] != null)
                        {
                            validation = GetScriptReferenceValidations(column, tables, columns);
                            if (validation != string.Empty)
                                sqlValidations.AppendLine(validation.ToString());
                        }
                        comma = ",";
                    }
                }
                if (sqlValidations.Length > 0)
                    result.Append(sqlValidations);
                sqlColumns.AppendLine($"{comma}[CreatedBy]");
                sqlValues.AppendLine($"{comma}@UserName");
                comma = ",";
                sqlColumns.AppendLine($"{comma}[CreatedAt]");
                sqlValues.AppendLine($"{comma}GETDATE()");


                result.AppendLine($"({sqlColumns})");
                result.AppendLine($"VALUES ({sqlValues})");
                result.AppendLine($"UPDATE[dbo].[Operations]");
                result.AppendLine($"SET[IsConfirmed] = 1,");
                result.AppendLine($"[UpdatedAt] = GETDATE(),");
                result.AppendLine($"[UpdatedBy] = @UserName");
                result.AppendLine($"WHERE[Id] = @OperationId");
                result.AppendLine($"RETURN @@ROWCOUNT");
                result.AppendLine($"END TRY");
                result.AppendLine($"BEGIN CATCH");
                result.AppendLine($"THROW");
                result.AppendLine($"END CATCH");
                result.AppendLine($"END");
                result.AppendLine("GO");
            }

            return result.ToString();
        }
        private static string GetUpdateScript(TDataRow table, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories, TDataTable indexes, TDataTable Indexkeys)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);

            if (listColumns.Any())
            {
                var sqlDeclare = new StringBuilder();
                var sqlValids = new StringBuilder();
                var sqlColumns = new StringBuilder();
                var where = new StringBuilder();
                var commaColumns = string.Empty;
                var commaDeclare = string.Empty;
                var typeName = string.Empty;
                var and = string.Empty;
                var listIndexes = indexes.Where(index => index["TableId"] == table["Id"] & ToBoolean(index["IsUnique"]));

                result.AppendLine($"/**********************************************************************************");
                result.AppendLine($"Criar procedure {table["ProcedureUpdate"]}");
                result.AppendLine($"**********************************************************************************/");
                result.AppendLine($"IF(SELECT object_id('{table["ProcedureUpdate"]}', 'P')) IS NULL");
                result.AppendLine($"EXEC('CREATE PROCEDURE [dbo].[{table["ProcedureUpdate"]}] AS PRINT 1')");
                result.AppendLine($"GO");
                result.AppendLine($"ALTER PROCEDURE[dbo].[{table["ProcedureUpdate"]}](");
                result.AppendLine($"@TransactionId BIGINT");
                sqlDeclare.AppendLine($"DECLARE ");
                foreach (var column in listColumns)
                {
                    if (!ToBoolean(column["IsAutoIncrement"]))
                    {
                        var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                        var type = types.First(type => type["Id"] == domain["TypeId"]);
                        var category = categories.First(category => category["Id"] == type["CategoryId"]);

                        typeName = GetDataType(type, domain);
                        if (ToBoolean(column["IsPrimarykey"]))
                        {
                            where.AppendLine($"{and}{column["Name"]} = @W_{column["Name"]}");
                            and = " AND ";
                        }
                        else
                        {
                            sqlColumns.AppendLine($"{commaColumns}[{column["Name"]}] = @W_{column["Name"]}");
                            commaColumns = ",";
                        }
                        if (ToBoolean(column["IsRequired"]))
                        {
                            sqlValids.AppendLine($"IF @W_{column["Name"]} IS NULL BEGIN");
                            sqlValids.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} é requerido.';");
                            sqlValids.AppendLine($"THROW 51000, @ErrorMessage, 1");
                            sqlValids.AppendLine($"END");
                        }
                        sqlValids.AppendLine(GetValidRange(type, domain, column));
                        sqlDeclare.AppendLine($"{commaDeclare}@W_{column["Name"]} {typeName} = CAST(JSON_VALUE(@Record, '$.{column["Name"]}') AS {typeName})");
                        commaDeclare = ",";
                    }
                }
                sqlColumns.AppendLine($"{commaColumns}[UpdatedAt] = GETDATE()");
                if (where.Length > 0)
                {
                    sqlValids.AppendLine($"IF NOT EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE {where}) BEGIN");
                    sqlValids.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela {table["Name"]}.';");
                    sqlValids.AppendLine($"THROW 51000, @ErrorMessage, 1");
                    sqlValids.AppendLine($"END");
                }
                if (listIndexes.Any())
                {
                    foreach (var index in listIndexes)
                    {
                        var listIndexkeys = Indexkeys.Where(indexkey => indexkey["IndexId"] == index["Id"]);

                        sqlValids.AppendLine($"IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE NOT ({where}) ");
                        foreach (var Indexkey in listIndexkeys)
                        {
                            var column = listColumns.First(column => column["Id"] == Indexkey["ColumnId"]);

                            sqlValids.AppendLine($"AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
                        sqlValids.AppendLine($") BEGIN");
                        sqlValids.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Chave única de índice {index["Name"]} já existe.';");
                        sqlValids.AppendLine($"THROW 51000, @ErrorMessage, 1");
                        sqlValids.AppendLine($"END");
                    }
                }
                result.AppendLine($") AS BEGIN");
                result.AppendLine(GetTransaction(Models.Actions.UPDATE));
                result.AppendLine($"BEGIN TRY");
                result.AppendLine($"SET NOCOUNT ON");
                result.AppendLine($"SET TRANSACTION ISOLATION LEVEL READ COMMITTED");
                result.AppendLine($"{sqlDeclare}");
                result.AppendLine($"{sqlValids}");
                result.AppendLine($"UPDATE [dbo].[{table["Name"]}] SET\r\n{sqlColumns}");
                result.AppendLine($"WHERE \r\n{where}");
                result.AppendLine($"RETURN @@ROWCOUNT");
                result.AppendLine($"END TRY");
                result.AppendLine("BEGIN CATCH");
                result.AppendLine("THROW");
                result.AppendLine("END CATCH");
                result.AppendLine("END");
                result.AppendLine("GO");
            }

            return result.ToString();
        }
        private static string GetDeleteScript(TDataRow table, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"] && ToBoolean(column["IsPrimarykey"]));

            if (listColumns.Any())
            {
                var sqlDeclare = new StringBuilder();
                var sqlValids = new StringBuilder();
                var where = new StringBuilder();
                var typeName = string.Empty;
                var and = string.Empty;

                result.AppendLine($"/**********************************************************************************");
                result.AppendLine($"Criar procedure {table["ProcedureDelete"]}");
                result.AppendLine($"**********************************************************************************/");
                result.AppendLine($"IF(SELECT object_id('{table["ProcedureDelete"]}', 'P')) IS NULL");
                result.AppendLine($"EXEC('CREATE PROCEDURE [dbo].[{table["ProcedureDelete"]}] AS PRINT 1')");
                result.AppendLine($"GO");
                result.AppendLine($"ALTER PROCEDURE[dbo].[{table["ProcedureDelete"]}](");
                result.AppendLine($"@UserName VARCHAR(25)\r\n,@Record VARCHAR(MAX)");
                sqlDeclare.AppendLine($"DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure {table["ProcedureDelete"]}: '");
                foreach (var column in listColumns)
                {
                    var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                    var type = types.First(type => type["Id"] == domain["TypeId"]);
                    var category = categories.First(category => category["Id"] == type["CategoryId"]);

                    typeName = GetDataType(type, domain);
                    sqlDeclare.AppendLine($",\r\n@W_{column["Name"]} {typeName} = CAST(JSON_VALUE(@Record, '$.{column["Name"]}') AS {typeName})");
                    where.AppendLine($"{and}{column["Name"]} = @W_{column["Name"]}");
                    and = " AND ";
                    sqlValids.AppendLine($"IF @W_{column["Name"]} IS NULL BEGIN");
                    sqlValids.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} é requerido.';");
                    sqlValids.AppendLine($"THROW 51000, @ErrorMessage, 1");
                    sqlValids.AppendLine($"END");
                    sqlValids.AppendLine(GetValidRange(type, domain, column));
                }
                sqlValids.AppendLine($"IF NOT EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE {where}) BEGIN");
                sqlValids.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela {table["Name"]}.';");
                sqlValids.AppendLine($"THROW 51000, @ErrorMessage, 1");
                sqlValids.AppendLine($"END");
                result.AppendLine($") AS BEGIN");
                result.AppendLine($"BEGIN TRY");
                result.AppendLine($"SET NOCOUNT ON");
                result.AppendLine($"SET TRANSACTION ISOLATION LEVEL READ COMMITTED");
                result.AppendLine($"{sqlDeclare}");
                result.AppendLine($"{sqlValids}");
                result.AppendLine($"DELETE FROM [dbo].[{table["Name"]}]");
                result.AppendLine($"WHERE {where}");
                result.AppendLine($"RETURN @@ROWCOUNT");
                result.AppendLine($"END TRY");
                result.AppendLine("BEGIN CATCH");
                result.AppendLine("THROW");
                result.AppendLine("END CATCH");
                result.AppendLine("END");
                result.AppendLine("GO");
            }

            return result.ToString();
        }
        private static string GetReadScript(TDataRow system, TDataRow database, TDataRow table, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories)
        {
            var sql = string.Empty;
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);

            if (listColumns.Any())
            {
                string sqlDeclare = string.Empty,
                    sqlValids = string.Empty,
                    sqlColumns = string.Empty,
                    sqlOrderBy = string.Empty,
                    sqlIndexTmp = string.Empty,
                    commaOrderBy = string.Empty,
                    sqlCreateTmp = string.Empty,
                    parameters = string.Empty,
                    typeName = string.Empty,
                    whereTab = string.Empty,
                    andWhereTab = string.Empty,
                    sqlDeleteTab = string.Empty,
                    sqlInsertTab = string.Empty,
                    comma = string.Empty,
                    sqlUpdateTab = string.Empty,
                    whereUpdateTab = string.Empty;
                dynamic valueMinimum,
                    valueMaximum,
                    value;

                sql += $"/**********************************************************************************\r\n";
                sql += $"Criar procedure {table["ProcedureRead"]}\r\n";
                sql += $"**********************************************************************************/\r\n";
                sql += $"IF(SELECT object_id('{table["ProcedureRead"]}', 'P')) IS NULL\r\n";
                sql += $"EXEC('CREATE PROCEDURE [dbo].[{table["ProcedureRead"]}] AS PRINT 1')\r\n";
                sql += $"GO\r\n";
                sql += $"ALTER PROCEDURE[dbo].[{table["ProcedureRead"]}](\r\n";

                sqlDeclare += $"DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure {table["ProcedureRead"]}: ',\r\n";
                sqlDeclare += $"@ROWCOUNT BIGINT,\r\n";
                sqlDeclare += $"@LoginId BIGINT,\r\n";
                sqlDeclare += $"@TableId BIGINT";

                if (ToBoolean(table["IsPaged"]))
                {
                    sqlDeclare += $",\r\n@offset INT";
                    parameters += $"@PageNumber INT OUT,\r\n";
                    parameters += $"@LimitRows BIGINT OUT,\r\n";
                    parameters += $"@MaxPage INT OUT,\r\n";
                    parameters += $"@PaddingGridLastPage BIT OUT,\r\n";
                }
                parameters += "@UserName VARCHAR(25),\r\n";
                parameters += $"@Record VARCHAR(MAX)";
                sqlCreateTmp += $"SELECT [Action] AS [_]";
                sqlDeleteTab += $"DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' ";
                sqlInsertTab += $"INSERT [dbo].[#tab] SELECT ";
                sqlUpdateTab += $"UPDATE [tab] SET";
                whereUpdateTab += $"[tmp].[_] = 'update' ";
                foreach (var column in listColumns)
                {
                    var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                    var type = types.First(type => type["Id"] == domain["TypeId"]);
                    var category = categories.First(category => category["Id"] == type["CategoryId"]);

                    typeName = GetDataType(type, domain);
                    if (ToBoolean(column["IsPrimarykey"]))
                    {
                        sqlOrderBy += $"{commaOrderBy}[tab].[{column["Name"]}]";
                        sqlIndexTmp += $"{commaOrderBy}[{column["Name"]}]";
                        commaOrderBy = ", ";
                        sqlDeleteTab += $"\r\nAND [tmp].[{column["Name"]}] = [tab].[{column["Name"]}]";
                        whereUpdateTab += $"\r\nAND [tmp].[{column["Name"]}] = [tab].[{column["Name"]}]";
                    }
                    if (ToBoolean(column["IsFilterable"]))
                    {
                        if (ToDouble(column["IsRequired"]) == 1)
                            whereTab += $"{andWhereTab}[tab].[{column["Name"]}] = ISNULL(@W_{column["Name"]}, [tab].[{column["Name"]}])\r\n";
                        else
                            whereTab += $"{andWhereTab}(@W_{column["Name"]} IS NULL OR [tab].[{column["Name"]}] = @W_{column["Name"]})\r\n";
                        andWhereTab = "AND ";
                        if ((value = valueMinimum = ToString(column["Minimum"])) == string.Empty)
                            if (value = valueMinimum = ToString(domain["Minimum"]) == string.Empty)
                                value = valueMinimum = ToString(type["Minimum"]);
                        if (value != string.Empty)
                        {
                            value = value.Substring(value.IndexOf('\''), value.LastIndexOf('\'') - value.IndexOf('\'') + 1);
                            sqlValids += $"IF @W_{column["Name"]} IS NOT NULL AND ";
                            sqlValids += $"@W_{column["Name"]} < {valueMinimum} BEGIN\r\n";
                            sqlValids += $"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} deve ser maior que ou igual à '{value}'.';\r\n";
                            sqlValids += $"THROW 51000, @ErrorMessage, 1\r\n";
                            sqlValids += $"END\r\n";
                        }
                        if ((value = valueMaximum = ToString(column["Maximum"])) == string.Empty)
                            if ((value = valueMaximum = ToString(domain["Maximum"])) == string.Empty)
                                value = valueMaximum = ToString(type["Maximum"]);
                            else
                                value = valueMaximum = ToString(domain["Maximum"]);
                        if (value != string.Empty)
                        {
                            value = value.Substring(value.IndexOf('\''), value.LastIndexOf('\'') - value.IndexOf('\'') + 1);
                            sqlValids += $"IF @W_{column["Name"]} IS NOT NULL AND ";
                            sqlValids += $"@W_{column["Name"]} > {valueMaximum.ToString()} BEGIN\r\n";
                            sqlValids += $"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} deve ser menor que ou igual à '{value}'.';\r\n";
                            sqlValids += $"THROW 51000, @ErrorMessage, 1\r\n";
                            sqlValids += $"END\r\n";
                        }
                        sqlDeclare += $",\r\n@W_{column["Name"]} {typeName} = CAST(JSON_VALUE(@Record, '$.{column["Name"]}') AS {typeName})";
                    }
                    sqlColumns += $"\r\n{comma}[tab].[{column["Name"]}]";
                    sqlCreateTmp += $"\r\n,CAST(JSON_VALUE([Record], '$.{column["Name"]}') AS {typeName}) AS [{column["Name"]}]";
                    sqlInsertTab += $"\r\n{comma}[{column["Name"]}]";
                    sqlUpdateTab += $"\r\n{comma}[tab].[{column["Name"]}] = [tmp].[{column["Name"]}]";
                    comma = ",";
                }
                sqlDeleteTab += $")";
                sqlInsertTab += $"\r\nFROM [dbo].[#tmp]\r\nWHERE [_] = 'create'";
                sqlUpdateTab += $"\r\nFROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]\r\nWHERE {whereUpdateTab}";
                sqlCreateTmp += $"\r\nINTO [dbo].[#tmp]";
                sqlCreateTmp += $"\r\nFROM [dbo].[Transactions]";
                sqlCreateTmp += $"\r\nWHERE [LoginId] = @LoginId";
                sqlCreateTmp += $"\r\nAND [TableId] = @TableId";
                sqlCreateTmp += $"\r\nAND [IsConfirmed] IS NULL";
                sql += $"{parameters}) AS BEGIN\r\n";
                sql += $"BEGIN TRY\r\n";
                sql += $"{sqlDeclare}\r\n";
                sql += $"SET NOCOUNT ON\r\n";
                sql += $"SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n";
                sql += $"{sqlValids}";
                sql += $"SELECT @LoginId = [LoginId],\r\n";
                sql += $"@TableId = [TableId],\r\n";
                sql += $"@ErrorMessage = [ErrorMessage]\r\n";
                sql += $"FROM [dbo].[TransactionsActions]('{system["Name"]}', '{database["Name"]}', '{table["Name"]}', @UserName, '{Models.Actions.CREATE}')\r\n";
                sql += $"IF @ErrorMessage IS NOT NULL\r\n";
                sql += $"THROW 51000, @ErrorMessage, 1\r\n";
                sql += $"{sqlCreateTmp}\r\n";
                sql += $"SELECT {sqlColumns}\r\n";
                sql += $"INTO[dbo].[#tab]\r\n";
                sql += $"FROM[dbo].[{table["Name"]}] [tab]\r\n";
                sql += $"WHERE {whereTab}";
                sql += $"ORDER BY {sqlOrderBy}\r\n";
                sql += $"SET @ROWCOUNT = @@ROWCOUNT\r\n";
                sql += $"{sqlDeleteTab}\r\n";
                sql += $"SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT\r\n";
                sql += $"{sqlInsertTab}\r\n";
                sql += $"SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT\r\n";
                sql += $"{sqlUpdateTab}\r\n";
                if (ToBoolean(table["IsPaged"]))
                {
                    sql += $"IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\r\n";
                    sql += $"SET @offset = 0\r\n";
                    sql += $"SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END\r\n";
                    sql += $"SET @PageNumber = 1\r\n";
                    sql += $"SET @MaxPage = 1\r\n";
                    sql += $"END ELSE BEGIN\r\n";
                    sql += $"SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END\r\n";
                    sql += $"IF ABS(@PageNumber) > @MaxPage\r\n";
                    sql += $"SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END\r\n";
                    sql += $"IF @PageNumber < 0\r\n";
                    sql += $"SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1\r\n";
                    sql += $"SET @offset = (@PageNumber - 1) * @LimitRows\r\n";
                    sql += $"IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT\r\n";
                    sql += $"SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END\r\n";
                    sql += $"END\r\n";
                };
                sql += $"SELECT 'Record{table["Alias"]}' AS [ClassName],{sqlColumns}\r\n";
                sql += $"FROM[dbo].[#tab] [tab]\r\n";
                sql += $"ORDER BY {sqlOrderBy}\r\n";
                if (ToBoolean(table["IsPaged"]))
                {
                    sql += $"OFFSET @offset ROWS\r\n";
                    sql += $"FETCH NEXT @LimitRows ROWS ONLY\r\n";
                }
                sql += $"RETURN @ROWCOUNT\r\n";
                sql += $"END TRY\r\n";
                sql += "BEGIN CATCH\r\n";
                sql += "THROW\r\n";
                sql += "END CATCH\r\n";
                sql += $"END\r\n";
                sql += $"GO\r\n";
            }

            return sql;
        }
        private static string GetDmlScript(TDataRow table, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories, TDataTable datatable)
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

                foreach (TDataRow row in datatable)
                {
                    cols = vals = comma = string.Empty;
                    foreach (TDataRow column in listColumns)
                    {
                        TDataRow domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                        TDataRow type = types.First(type => type["Id"] == domain["TypeId"]);
                        TDataRow category = categories.First(category => category["Id"] == type["CategoryId"]);

                        cols += $"{comma}\r\n[{column["Name"]}]";
                        value = row[ToString(column["Name"])];
                        if (ToString(category["Name"]) == "numeric")
                            value ??= null;
                        else if (ToString(category["Name"]) == "boolean")
                            value = value == null ? null : ToBoolean(value) ? 1 : 0;
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
        private static string GetDataType(TDataRow type, TDataRow domain)
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
        private static string GetTransaction(string action)
        {
            return $"DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '\r\n" +
                   $",@UserName VARCHAR(25)\r\n" +
                   $",@Record VARCHAR(MAX)\r\n" +
                   $"SELECT @UserName = [UserName]\r\n" +
                   $",@Record = [Record]\r\n" +
                   $",@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)\r\n" +
                   $"FROM [dbo].[TransactionsRead](@TransactionId, '{action}')\r\n " +
                   $"IF @ErrorMessage IS NULL\r\n" +
                   $"THROW 51000, @ErrorMessage, 1\r\n";
        }
        private static string GetValidRangeFuntion(TDataRow type, TDataRow domain, TDataRow column)
        {
            var result = new StringBuilder();
            var value = string.Empty;
            var valueMinimum = string.Empty;
            var valueMaximum = string.Empty;

            if ((value = valueMinimum = ToString(column["Minimum"])) == string.Empty)
                if ((value = valueMinimum = ToString(domain["Minimum"])) == string.Empty)
                    value = valueMinimum = ToString(type["Minimum"]);
            if (value != string.Empty)
            {
                var position = value.IndexOf('\'');

                value = value.Substring(position, value.LastIndexOf('\'') - position + 1);
                result.AppendLine($"ELSE IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.AppendLine($"@W_{column["Name"]} IS NOT NULL AND ");
                result.AppendLine($"@W_{column["Name"]} < {valueMinimum}\r\n");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} " +
                                  $"deve ser maior que ou igual à '{value}'.';");
            }
            if ((value = valueMaximum = ToString(column["Maximum"])) == string.Empty)
                if ((value = valueMaximum = ToString(domain["Maximum"])) == string.Empty)
                    value = valueMaximum = ToString(type["Maximum"]);

            if (value != string.Empty)
            {
                var position = value.IndexOf('\'');

                value = value.Substring(position, value.LastIndexOf('\'') - position + 1);
                result.AppendLine($"ELSE IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.AppendLine($"@W_{column["Name"]} IS NOT NULL AND ");
                result.AppendLine($"@W_{column["Name"]} > {valueMaximum}");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de @{column["Name"]} " +
                                  $"deve ser menor que ou igual à '{value}'.';");
            }

            return result.ToString();
        }
        private static bool ToBoolean(object? value)
        {
            if (value == DBNull.Value || value == null)
                return false;

            return Convert.ToBoolean(value);
        }
        private static bool IsDouble(object? value)
        {
            if (value == DBNull.Value || value == null)
                return false;

            return value.GetType() == typeof(double);
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
        private static bool IsString(object? value)
        {
            if (value == DBNull.Value || value == null)
                return false;

            return value.GetType() == typeof(string);
        }
        private static string ToString(object? value)
        {
            if (value == DBNull.Value || value == null)
                return string.Empty;

            return Convert.ToString(value) ?? string.Empty;
        }
        private static TDataSet ExcelToDictionary()
        {
            FileStream fs;
            var filename = Settings.Get("FILENAME_EXCEL");
            var fullFilename = Path.Combine(Directory.GetCurrentDirectory(), filename);
            var result = new TDataSet();

            try
            {
                IWorkbook wb;

                filename = filename.ToLower();
                if (filename.EndsWith(".xlsx") || filename.EndsWith(".xlsm"))
                {
                    fs = new FileStream(fullFilename, FileMode.Open, FileAccess.Read);
                    wb = new XSSFWorkbook(fs);
                }
                else if (filename.EndsWith(".xls"))
                {
                    fs = new FileStream(fullFilename, FileMode.Open, FileAccess.Read);
                    wb = new HSSFWorkbook(fs);
                }
                else
                    throw new Exception($"Extensão do arquivo {fullFilename} é inválida!");
                for (var sheetIndex = 0; sheetIndex < wb.NumberOfSheets; sheetIndex++)
                {
                    var ws = wb.GetSheetAt(sheetIndex);
                    var rowHeader = ws.GetRow(0);
                    var dataTable = new TDataTable();

                    if (ws.SheetName == "Domains")
                        Console.WriteLine("teste");
                    for (var rowIndex = 1; rowIndex <= ws.LastRowNum; rowIndex++)
                    {
                        var row = ws.GetRow(rowIndex);
                        var dr = new TDataRow();

                        for (var cellIndex = 0; cellIndex < rowHeader.LastCellNum; cellIndex++)
                        {
                            var cell = row.GetCell(cellIndex);
                            var columnName = rowHeader.GetCell(cellIndex).StringCellValue;

                            if (columnName.StartsWith('#'))
                                continue;
                            if (cell == null) 
                            {
                                dr.Add(columnName, null);
                                continue; 
                            }
                            dr.Add(columnName, cell.CellType switch
                            {
                                CellType.String => cell.StringCellValue,
                                CellType.Boolean => cell.BooleanCellValue,
                                CellType.Numeric => DateUtil.IsCellDateFormatted(cell) ? cell.DateCellValue : cell.NumericCellValue,
                                CellType.Formula => GetFormulaCellValue(cell),
                                _ => null,
                            });
                        }
                        dataTable.Add(dr);
                    }
                    result.Add(ws.SheetName, dataTable);
                }
                fs.Close();
            }
            catch
            {
                throw;
            }
            finally
            {
            }

            return result;
        }
        private static object? GetFormulaCellValue(ICell cell)
        {
            return cell.CachedFormulaResultType switch
            {
                CellType.String => cell.StringCellValue,
                CellType.Boolean => cell.BooleanCellValue,
                CellType.Numeric => DateUtil.IsCellDateFormatted(cell) ? cell.DateCellValue : cell.NumericCellValue,
                CellType.Error => FormulaError.ForInt(cell.ErrorCellValue).String,
                _ => cell.ToString(),
            };
        }
    }
}
