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
                if (ToString(table["ProcedureUpdate"]) != string.Empty)
                    stream.Write(GetUpdateScript(table, tables, columns, domains, types, categories, indexes, indexkeys));
                if (ToString(table["ProcedureDelete"]) != string.Empty)
                    stream.Write(GetDeleteScript(table, tables, columns, domains, types, categories, indexes, indexkeys));
                if (ToString(table["ProcedureRead"]) != string.Empty)
                    stream.Write(GetReadScript(table, tables, columns, domains, types, categories, indexes, indexkeys));
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
        private static string GetScriptParameters(string procedureName, string actionName)
        {
            var result = new StringBuilder();
            var actionDescription = (actionName == Actions.CREATE ? "inclusão" : 
                                     actionName == Actions.UPDATE ? "alteração" : 
                                     actionName == Actions.DELETE ? "exclusão" : 
                                     "consulta");

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
            result.AppendLine($"BEGIN TRANSACTION");
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
            result.AppendLine($"IF @Action <> '{actionName}' BEGIN");
            result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Operação não é de {actionDescription}.';");
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
            if (actionName == Actions.READ)
            {
                result.AppendLine($"DECLARE @PageNumber INT --OUT");
                result.AppendLine($",@LimitRows BIGINT --OUT");
                result.AppendLine($",@MaxPage INT --OUT");
                result.AppendLine($",@PaddingGridLastPage BIT --OUT");
                result.AppendLine($",@RowCount BIGINT");
                result.AppendLine($",@LoginId BIGINT");
                result.AppendLine($",@OffSet INT");
            }

            return result.ToString();
        }
        private static string GetScriptValidations(TDataRow type, TDataRow domain, TDataRow column)
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
            var primarykey = columns.First(column => column["TableId"] == referencedTable["Id"] && ToBoolean(column["IsPrimarykey"]));

            if (primarykey != null)
            {
                result.Append($"IF ");
                if (!ToBoolean(column["IsRequired"]))
                    result.Append($"@W_{column["Name"]} IS NOT NULL AND ");
                result.Append($"NOT EXISTS(SELECT 1 FROM [dbo].[{referencedTable["Name"]}] WHERE ");
                result.Append($"[{primarykey["Name"]}] = @W_{column["Name"]}");
                result.AppendLine($") BEGIN");
                result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} " +
                                  $"não existe em {referencedTable["Name"]}';");
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.Append($"END");
            }

            return result.ToString();
        }
        private static string GetScriptPrimarykeyValidation(TDataRow table, TDataTable columns, bool isCreateAction = false)
        {
            var result = new StringBuilder();
            var primarykey = columns.First(column => column["TableId"] == table["Id"] && ToBoolean(column["IsPrimarykey"]));

            if (primarykey != null)
            {
                if (isCreateAction)
                {
                    result.Append($"IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                    result.Append($"[{primarykey["Name"]}] = @W_{primarykey["Name"]}");
                    result.AppendLine($") BEGIN");
                    result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela {table["Name"]}.';");
                }
                else
                {
                    result.Append($"IF NOT EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                    result.Append($"[{primarykey["Name"]}] = @W_{primarykey["Name"]}");
                    result.AppendLine($") BEGIN");
                    result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela {table["Name"]}.';");
                }
                result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                result.AppendLine($"END");
            }

            return result.ToString();
        }
        private static string GetScriptIndexValidations(TDataRow table, TDataTable columns, TDataTable indexes, TDataTable indexkeys)
        {
            var result = new StringBuilder();
            var listIndexes = indexes.Where(index => index["TableId"] == table["Id"]);

            if (listIndexes.Any())
            {
                foreach (var index in listIndexes)
                {
                    var listIndexkeys = indexkeys.Where(indexkey => indexkey["IndexId"] == index["Id"]);
                    var and = string.Empty;

                    result.Append($"IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE ");
                    foreach (var Indexkey in listIndexkeys)
                    {
                        var column = columns.First(column => column["Id"] == Indexkey["ColumnId"]);

                        result.Append($"{and}[{column["Name"]}] = @W_{column["Name"]}");
                        and = " AND ";
                    }
                    result.AppendLine($") BEGIN");
                    result.AppendLine($"SET @ErrorMessage = @ErrorMessage + 'Chave única do índice {index["Name"]} já existe.';");
                    result.AppendLine($"THROW 51000, @ErrorMessage, 1");
                    result.AppendLine($"END");
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
                var commaColumnsValues = string.Empty;
                var validation = string.Empty;

                result.Append(GetScriptParameters(table["ProcedureCreate"], Actions.CREATE));
                result.Append($"DECLARE ");
                foreach (var column in listColumns)
                {
                    if (!ToBoolean(column["IsAutoIncrement"]))
                    {
                        var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                        var type = types.First(type => type["Id"] == domain["TypeId"]);
                        var category = categories.First(category => category["Id"] == type["CategoryId"]);
                        var typeName = GetDataType(type, domain);
                        var columnName = column["Name"];
                        
                        validation = GetScriptValidations(type, domain, column);
                        if (validation != string.Empty)
                            sqlValidations.Append(validation);
                        result.AppendLine($"{comma}@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})");
                        if (column["ReferenceTableId"] != null)
                        {
                            validation = GetScriptReferenceValidations(column, tables, columns);
                            if (validation != string.Empty)
                                sqlValidations.AppendLine(validation.ToString());
                        }
                        if (!ToBoolean(column["IsAutoIncrement"]))
                        {
                            sqlColumns.AppendLine($"{commaColumnsValues}[{columnName}]");
                            sqlValues.AppendLine($"{commaColumnsValues}@W_{columnName}");
                            commaColumnsValues = ",";
                        }
                        comma = ",";
                    }
                }
                sqlColumns.AppendLine(",[CreatedAt]");
                sqlColumns.AppendLine(",[CreatedBy]");
                sqlValues.AppendLine(",GETDATE()");
                sqlValues.AppendLine(",@UserName");
                validation = GetScriptPrimarykeyValidation(table, columns, true);
                if (validation != string.Empty)
                    sqlValidations.Append(validation);
                validation = GetScriptIndexValidations(table, columns, indexes, indexkeys);
                if (validation != string.Empty)
                    sqlValidations.Append(validation);
                if (sqlValidations.Length > 0)
                    result.Append(sqlValidations);
                result.AppendLine($"INSERT INTO [dbo].[{table["Name"]}] ({sqlColumns})");
                result.AppendLine($"VALUES ({sqlValues})");
                result.AppendLine($"UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId");
                result.AppendLine($"RETURN 1");
                result.AppendLine($"END TRY");
                result.AppendLine($"BEGIN CATCH");
                result.AppendLine($"THROW");
                result.AppendLine($"END CATCH");
                result.AppendLine($"END");
                result.AppendLine("GO");
            }

            return result.ToString();
        }
        private static string GetUpdateScript(TDataRow table, TDataTable tables, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories, TDataTable indexes, TDataTable indexkeys)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);

            if (listColumns.Any())
            {
                var sqlAssignments = new StringBuilder();
                var sqlValidations = new StringBuilder();
                var sqlWhere = new StringBuilder();
                var comma = string.Empty;
                var commaAssignments = string.Empty;
                var and = string.Empty;
                var validation = string.Empty;

                result.Append(GetScriptParameters(table["ProcedureUpdate"], Actions.UPDATE));
                result.Append($"DECLARE ");
                foreach (var column in listColumns)
                {
                    var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                    var type = types.First(type => type["Id"] == domain["TypeId"]);
                    var category = categories.First(category => category["Id"] == type["CategoryId"]);
                    var typeName = GetDataType(type, domain);
                    var columnName = column["Name"];

                    validation = GetScriptValidations(type, domain, column);
                    if (validation != string.Empty)
                        sqlValidations.Append(validation);
                    result.AppendLine($"{comma}@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})");
                    comma = ",";
                    if (column["ReferenceTableId"] != null)
                    {
                        validation = GetScriptReferenceValidations(column, tables, columns);
                        if (validation != string.Empty)
                            sqlValidations.AppendLine(validation.ToString());
                    }
                    if (ToBoolean(column["IsPrimarykey"]))
                    {
                        sqlWhere.AppendLine($"{and}[{columnName}] = @W_{columnName}");
                        and = "AND ";
                    }
                    else if (!ToBoolean(column["IsAutoIncrement"]))
                    {
                        sqlAssignments.AppendLine($"{commaAssignments}[{columnName}] = @W_{columnName}");
                        commaAssignments = ",";
                    }
                }
                if (sqlWhere.Length == 0)
                    throw new Exception("Tabela não possui chave-primária.");
                if (sqlAssignments.Length == 0)
                    throw new Exception("Tabela não possui colunas atualizáveis.");
                sqlAssignments.AppendLine(",[UpdatedAt] = GETDATE()");
                sqlAssignments.AppendLine(",[UpdatedBy] = @UserName");
                validation = GetScriptPrimarykeyValidation(table, columns);
                if (validation != string.Empty)
                    sqlValidations.Append(validation);
                validation = GetScriptIndexValidations(table, columns, indexes, indexkeys);
                if (validation != string.Empty)
                    sqlValidations.Append(validation);
                if (sqlValidations.Length > 0)
                    result.Append(sqlValidations);
                result.AppendLine($"UPDATE [dbo].[{table["Name"]}]");
                result.Append($"SET {sqlAssignments}");
                result.Append($"WHERE {sqlWhere}");
                result.AppendLine($"UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId");
                result.AppendLine($"RETURN 1");
                result.AppendLine($"END TRY");
                result.AppendLine($"BEGIN CATCH");
                result.AppendLine($"THROW");
                result.AppendLine($"END CATCH");
                result.AppendLine($"END");
                result.AppendLine("GO");
            }

            return result.ToString();
        }
        private static string GetDeleteScript(TDataRow table, TDataTable tables, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories, TDataTable indexes, TDataTable indexkeys)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"] && ToBoolean(column["IsPrimarykey"]));

            if (listColumns.Any())
            {
                var sqlWhere = new StringBuilder();
                var sqlValidations = new StringBuilder();
                var comma = string.Empty;
                var and = string.Empty;
                var validation = string.Empty;

                result.Append(GetScriptParameters(table["ProcedureDelete"], Actions.DELETE));
                result.Append($"DECLARE ");
                foreach (var column in listColumns)
                {
                    var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                    var type = types.First(type => type["Id"] == domain["TypeId"]);
                    var category = categories.First(category => category["Id"] == type["CategoryId"]);
                    var typeName = GetDataType(type, domain);
                    var columnName = column["Name"];

                    validation = GetScriptValidations(type, domain, column);
                    if (validation != string.Empty)
                        sqlValidations.Append(validation);
                    result.AppendLine($"{comma}@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})");
                    comma = ",";
                    sqlWhere.AppendLine($"{and}[{columnName}] = @W_{columnName}");
                    and = "AND ";
                }
                if (sqlValidations.Length > 0)
                    sqlValidations.Append(sqlValidations);
                validation = GetScriptPrimarykeyValidation(table, columns);
                if (validation != string.Empty)
                    sqlValidations.Append(validation);
                if (sqlValidations.Length > 0)
                    result.Append(sqlValidations);
                result.AppendLine($"DELETE FROM [dbo].[{table["Name"]}]");
                result.Append($"WHERE {sqlWhere}");
                result.AppendLine($"UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId");
                result.AppendLine($"RETURN 1");
                result.AppendLine($"END TRY");
                result.AppendLine($"BEGIN CATCH");
                result.AppendLine($"THROW");
                result.AppendLine($"END CATCH");
                result.AppendLine($"END");
                result.AppendLine("GO");
            }

            return result.ToString();
        }
        private static string GetReadScript(TDataRow table, TDataTable tables, TDataTable columns, TDataTable domains, TDataTable types, TDataTable categories, TDataTable indexes, TDataTable indexkeys)
        {
            var result = new StringBuilder();
            var listColumns = columns.Where(column => column["TableId"] == table["Id"]);

            if (listColumns.Any())
            {
                var sqlColumns = new StringBuilder();
                var sqlWhere = new StringBuilder();
                var sqlValidations = new StringBuilder();
                var sqlOperations = new StringBuilder();
                var sqlIndexOperations = new StringBuilder();
                var sqlInnerJoinOperations = new StringBuilder();
                var sqlInsertOperations = new StringBuilder();
                var comma = string.Empty;
                var andWhere = string.Empty;
                var andInnerJoin = string.Empty;
                var validation = string.Empty;

                result.Append(GetScriptParameters(table["ProcedureRead"], Actions.READ));
                result.Append($"DECLARE ");
                sqlOperations.AppendLine("SELECT [Action] AS [_]");
                sqlInsertOperations.Append($"INSERT [dbo].[#{table["Name"]}] SELECT ");
                foreach (var column in listColumns)
                {
                    var domain = domains.First(domain => domain["Id"] == column["DomainId"]);
                    var type = types.First(type => type["Id"] == domain["TypeId"]);
                    var category = categories.First(category => category["Id"] == type["CategoryId"]);
                    var typeName = GetDataType(type, domain);
                    var columnName = column["Name"];

                    validation = GetScriptValidations(type, domain, column);
                    if (validation != string.Empty)
                        sqlValidations.Append(validation);
                    result.AppendLine($"{comma}@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})");
                    if (column["ReferenceTableId"] != null)
                    {
                        validation = GetScriptReferenceValidations(column, tables, columns);
                        if (validation != string.Empty)
                            sqlValidations.AppendLine(validation.ToString());
                    }
                    sqlColumns.AppendLine($"{comma}[{columnName}]");
                    sqlOperations.AppendLine($",CAST(JSON_VALUE([ActualRecord], '{columnName}') AS {typeName}) AS [{columnName}]");
                    sqlInsertOperations.AppendLine($"{comma}[{columnName}]");
                    if (ToBoolean(column["IsPrimarykey"]))
                    {
                        if (sqlIndexOperations.Length == 0)
                            sqlIndexOperations.Append($"CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_]");
                        sqlIndexOperations.Append($", [{columnName}]");
                        if (sqlInnerJoinOperations.Length == 0)
                            sqlInnerJoinOperations.Append($"INNER JOIN [dbo].[#{table["Name"]}] [{table["Name"]}] ON ");
                        sqlInnerJoinOperations.Append($"[{table["Name"]}].[{columnName}] = [Operations].[{columnName}]");
                    }
                    if (ToBoolean(column["IsFilterable"]))
                    {
                        if (ToBoolean(column["IsRequired"]))
                            sqlWhere.AppendLine($"{andWhere}[{columnName}] = ISNULL(@W_{columnName}, [{columnName}])");
                        else
                            sqlWhere.AppendLine($"{andWhere}(@W_{columnName} IS NULL OR [{columnName}] = @W_{columnName})");
                        andWhere = "AND ";
                    }
                    comma = ",";
                }
                sqlOperations.AppendLine($"INTO [dbo].[#Operations]");
                sqlOperations.AppendLine($"FROM [dbo].[Operations]");
                sqlOperations.AppendLine($"WHERE [TransactionId] = @TransactionId");
                sqlOperations.AppendLine($"AND [TableId] = @TableId");
                sqlOperations.AppendLine($"AND [IsConfirmed] IS NULL");
                sqlInsertOperations.AppendLine($"FROM [dbo].[#Operations]");
                sqlInsertOperations.AppendLine($"WHERE [_] = '{Actions.CREATE}'");
                sqlInsertOperations.AppendLine($"SET @RowCount = @RowCount + @@ROWCOUNT");
                if (sqlIndexOperations.Length == 0)
                    throw new Exception("Tabela não contém chave-primária.");
                sqlOperations.AppendLine($"{sqlIndexOperations})");
                validation = GetScriptIndexValidations(table, columns, indexes, indexkeys);
                if (validation != string.Empty)
                    sqlValidations.Append(validation);
                if (sqlValidations.Length > 0)
                    result.Append(sqlValidations);
                result.Append(sqlOperations);
                result.Append($"SELECT {sqlColumns}");
                result.AppendLine($"INTO[dbo].[#{table["Name"]}]");
                result.AppendLine($"FROM [dbo].[{table["Name"]}]");
                result.Append($"WHERE {sqlWhere}");
                result.AppendLine("SET @RowCount = @@ROWCOUNT");
                result.AppendLine($"DELETE [{table["Name"]}]");
                result.AppendLine($"FROM [dbo].[#Operations] [Operations]");
                result.AppendLine($"INNER JOIN [dbo].[#{table["Name"]}] [{table["Name"]}] ON [{table["Name"]}].[Id] = [Operations].[Id]");
                result.AppendLine($"WHERE [Operations].[_] = '{Actions.DELETE}'");
                result.AppendLine("SET @RowCount = @RowCount - @@ROWCOUNT");
                result.Append(sqlInsertOperations);
                result.AppendLine($"UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId");
                result.AppendLine($"RETURN 1");
                result.AppendLine($"END TRY");
                result.AppendLine($"BEGIN CATCH");
                result.AppendLine($"THROW");
                result.AppendLine($"END CATCH");
                result.AppendLine($"END");
                result.AppendLine("GO");
            }

            return result.ToString();
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
