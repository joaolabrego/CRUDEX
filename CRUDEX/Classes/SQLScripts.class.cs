using CRUDA_LIB;
using ExcelDataReader;
using System.Data;
using System.Text;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;
using TDataRows = System.Collections.Generic.List<System.Data.DataRow>;

namespace crudex.Classes
{
    public class SQLScripts
    {
        static readonly string DirectoryScripts = Path.Combine(Settings.Builder.Environment.ContentRootPath, Settings.Get("DIRECTORY_SCRIPTS"));
        static readonly string ReservedColumnNames = ";Data;ClassName;";
        public static async Task Generate(string systemName = "crudex", string databaseName = "crudex", bool saveInDisk = true, bool? isExcel = null, bool withInsertData = true)
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
            var associations = (dataSet.Tables["Associations"] ?? throw new Exception("Tabela Associations não existe.")).AsEnumerable().ToList();
            var uniques = (dataSet.Tables["Uniques"] ?? throw new Exception("Tabela Uniques não existe.")).AsEnumerable().ToList();
            var databaseTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("Tabela DatabasesTables não existe.")).AsEnumerable().ToList()
                .FindAll(row => Settings.ToLong(row["DatabaseId"]) == Settings.ToLong(database["Id"]));
            var references = new TDataRows();
            var firstTime = true;

            foreach (DataRow databaseTable in databaseTables)
            {
                var table = tables.First(table => Settings.ToLong(table["Id"]) == Settings.ToLong(databaseTable["TableId"]));

                if (firstTime)
                {
                    result.AppendLine(GetScriptCreateDatabase(database).ToString());
                    firstTime = false;
                }
                result.AppendLine(GetScriptCreateTable(table, columns, indexes, indexkeys, domains, types).ToString());
            }
            if (!firstTime)
            {
                if (systemName == "crudex")
                    result.AppendLine(GetScriptOthers().ToString());
                result.AppendLine(GetScriptTransactions().ToString());
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
            foreach (DataRow databaseTable in databaseTables)
            {
                var table = tables.First(table => Settings.ToLong(table["Id"]) == Settings.ToLong(databaseTable["TableId"]));

                result.AppendLine(GetScriptValidateTable(table, tables, columns, domains, types, indexes, indexkeys, uniques).ToString());
                result.AppendLine(GetScriptPersistTable(table, columns).ToString());
                result.AppendLine(GetScriptCommitTable(table, columns).ToString());
                result.AppendLine(GetScriptReadTable(table, columns, domains, types).ToString());
                result.AppendLine(GetScriptListTable(table, columns).ToString());
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
            var dataset = (await SQLProcedure.Execute(Settings.ConnectionString(),
                                               Settings.Get("SCRIPT_SYSTEM_PROCEDURE"),
                                               Config.ToDictionary(Config.ToDictionary(new
                                               {})))).DataSet;

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
            dataset.Tables[16].TableName = "Logins";
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
        private static StringBuilder GetScriptCreateDatabase(DataRow database)
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
            result.Append($"CREATE DATABASE [{databaseAlias}]\r\n");
            result.Append($"    CONTAINMENT = NONE\r\n");
            result.Append($"    ON PRIMARY\r\n");
            result.Append($"    (NAME = N'${databaseName}', FILENAME = N'{filename}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)\r\n");
            result.Append($"    LOG ON\r\n");
            result.Append($"    (NAME = N'${databaseName}_log', FILENAME = N'{filename}.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)\r\n");
            result.Append($"    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{databaseAlias}] SET COMPATIBILITY_LEVEL = 160\r\n");
            result.Append($"GO\r\n");
            result.Append($"IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))\r\n");
            result.Append($"    EXEC[{databaseAlias}].[dbo].[sp_fulltext_database] @action = 'enable'\r\n");
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
            result.Append($"CREATE SCHEMA crudex AUTHORIZATION [dbo]\r\n");
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
            result.Append($"Criar function [crudex].[HUNDREDS_IN_WORDS]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.HUNDREDS_IN_WORDS.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar function [crudex].[NUMBER_IN_WORDS]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.NUMBER_IN_WORDS.sql")));

            return result;
        }
        private static StringBuilder GetScriptTransactions()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [crudex].[IS_EQUAL]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.IS_EQUAL.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [crudex].[JSON_EXTRACT]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.JSON_EXTRACT.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [crudex].TransactionBegin]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.TransactionBegin.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [crudex].[TransactionCommit]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.TransactionCommit.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [crudex].[TransactionRollback]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "crudex.TransactionRollback.sql")));

            return result;
        }
        private static StringBuilder GetScriptCreateTable(DataRow table, TDataRows columns, TDataRows indexes, TDataRows indexkeys, TDataRows domains, TDataRows types)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(column => Settings.ToLong(column["TableId"]) == Settings.ToLong(table["Id"]));
            
            if (columnRows.Count > 0)
            {
                var firstTime = true;
                var isListable = false;

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF (SELECT object_id('[dbo].[{table["Name"]}]', 'U')) IS NOT NULL\r\n");
                result.Append($"    DROP TABLE [dbo].[{table["Name"]}]\r\n");

                foreach (DataRow column in columnRows)
                {
                    var constraints = GetConstraints(column, domains, types);
                    var required = $"{(constraints.TryGetValue("Required", out dynamic? value) ? value : "")}";
                    var autoIncrement = $"{(constraints.TryGetValue("AutoIncrement", out value) ? value : "")}";
                    var defaultValue = $"{(constraints.TryGetValue("Default", out value) ? value : "")}";
                    var range = $"{(constraints.TryGetValue("Range", out value) ? value : "")}";
                    var definition = $"[{column["Name"]}] {column["#DataType"]}{required}{defaultValue}{range}";

                    if (firstTime)
                    {
                        var message = $"Primeira coluna definida na tabela '{table["Name"]}' ";

                        if (!Settings.ToString(column["Name"]).Equals("Id"))
                            throw new Exception(message + "deve ter nome 'Id'.");
                        if (!Settings.ToBoolean(constraints["AskPrimarykey"]))
                            throw new Exception(message + "deve permitir 'primary key'.");
                        if (!Settings.ToBoolean(column["IsPrimarykey"]))
                            throw new Exception(message + "deve ser 'primary key'.");
                        if (!Settings.ToBoolean(column["IsAutoIncrement"]))
                            throw new Exception(message + "deve ser 'auto increment'.");
                        result.Append($"CREATE TABLE [dbo].[{table["Name"]}]({definition}\r\n");
                        firstTime = false;
                    }
                    else if (ReservedColumnNames.Contains($";{Settings.ToString(column["Name"])};", StringComparison.InvariantCultureIgnoreCase))
                        throw new Exception($"Nome de coluna {column["Name"]} é reservado.");
                    else
                    {
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
                result.Append($"                                    ,[UpdatedBy] nvarchar(25) NULL)\r\n");
                result.Append($"ALTER TABLE [dbo].[{table["Name"]}] ADD CONSTRAINT PK_{table["Name"]} PRIMARY KEY CLUSTERED ([{columns[0]["Name"]}])\r\n");

                var indexRows = indexes.FindAll(index => Settings.ToLong(index["TableId"]) == Settings.ToLong(table["Id"]));

                if (indexRows.Count > 0)
                {
                    foreach (var index in indexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => Settings.ToLong(indexkey["IndexId"]) == Settings.ToLong(index["Id"]));

                        if (indexkeyRows.Count > 0)
                        {
                            firstTime = true;
                            foreach (var indexkey in indexkeyRows)                            {
                                var column = columns.First(column => Settings.ToLong(column["Id"]) == Settings.ToLong(indexkey["ColumnId"]));
                                var definition = $"[{column["Name"]}] {(Settings.ToBoolean(indexkey["IsDescending"]) ? "DESC" : "ASC")}";

                                if (firstTime)
                                {
                                    result.Append($"CREATE {(Settings.ToBoolean(index["IsUnique"]) ? "UNIQUE" : "")} INDEX [{index["Name"]}] ON [dbo].[{table["Name"]}]({definition}");
                                    firstTime = false;
                                }
                                else
                                    result.Append($", {definition}");
                            }
                            result.Append($")\r\n");
                        }
                    }
                    result.Append($"GO\r\n");
                }
            }

            return result;
        }
        private static StringBuilder GetScriptReferences(TDataRows tables, TDataRows columns)
        {
            var result = new StringBuilder();
            var lastTableName = string.Empty;
            var foreignColumns = columns.FindAll(column => Settings.ToString(column["ReferenceTableId"]) != string.Empty);

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
        private static StringBuilder GetScriptInsertTable(DataRow table, TDataRows columns, TDataRows dataRows)
        {
            var result = new StringBuilder();

            if (dataRows.Count > 0)
            {
                var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"]));

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
                                value = $"CAST('{value}' AS {data["#DataType"]})";
                            else
                                value = $"CAST('{value}' AS {column["#DataType"]})";
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
        private static StringBuilder GetScriptPersistTable(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Persist]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Persist]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Persist] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Alias"]}Persist](@LoginId BIGINT\r\n");
                result.Append($"                                              ,@UserName NVARCHAR(25)\r\n");
                result.Append($"                                              ,@Action NVARCHAR(15)\r\n");
                result.Append($"                                              ,@OriginalRecord NVARCHAR(max)\r\n");
                result.Append($"                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN\r\n");
                result.Append($"    DECLARE @TRANCOUNT INT = @@TRANCOUNT\r\n");
                result.Append($"           ,@ErrorMessage NVARCHAR(255)\r\n");
                result.Append($"\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @TransactionId BIGINT\r\n");
                result.Append($"               ,@OperationId BIGINT\r\n");
                result.Append($"               ,@CreatedBy NVARCHAR(25)\r\n");
                result.Append($"               ,@ActionAux NVARCHAR(15)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"               ,@W_Id {columnRows[0]["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.Id') AS {columnRows[0]["#DataType"]})\r\n");
                result.Append($"\r\n");
                result.Append($"        BEGIN TRANSACTION\r\n");
                result.Append($"        SAVE TRANSACTION [SavePoint]\r\n");
                result.Append($"        EXEC @TransactionId = [dbo].[{table["Alias"]}Validate] @LoginId, @UserName, @Action, @OriginalRecord, @ActualRecord\r\n");
                result.Append($"        SELECT @OperationId = [Id]\r\n");
                result.Append($"              ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"              ,@ActionAux = [Action]\r\n");
                result.Append($"              ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                  AND [TableName] = 'Columns'\r\n");
                result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                result.Append($"                  AND CAST([crudex].[JSON_EXTRACT]([ActualRecord], '$.Id') AS {columnRows[0]["#DataType"]}) = @W_Id\r\n");
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                result.Append($"            INSERT INTO [dbo].[Operations] ([TransactionId]\r\n");
                result.Append($"                                             ,[TableName]\r\n");
                result.Append($"                                             ,[Action]\r\n");
                result.Append($"                                             ,[OriginalRecord]\r\n");
                result.Append($"                                             ,[ActualRecord]\r\n");
                result.Append($"                                             ,[IsConfirmed]\r\n");
                result.Append($"                                             ,[CreatedAt]\r\n");
                result.Append($"                                             ,[CreatedBy])\r\n");
                result.Append($"                                       VALUES(@TransactionId\r\n");
                result.Append($"                                             ,'{table["Name"]}'\r\n");
                result.Append($"                                             ,@Action\r\n");
                result.Append($"                                             ,@OriginalRecord\r\n");
                result.Append($"                                             ,@ActualRecord\r\n");
                result.Append($"                                             ,NULL\r\n");
                result.Append($"                                             ,GETDATE()\r\n");
                result.Append($"                                             ,@UserName)\r\n");
                result.Append($"            SET @OperationId = @@IDENTITY\r\n");
                result.Append($"        END ELSE IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END ELSE IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");
                result.Append($"        ELSE IF @ActionAux = 'delete'\r\n");
                result.Append($"            THROW 51000, 'Registro excluído nesta transação', 1\r\n");
                result.Append($"        ELSE IF @Action = 'create'\r\n");
                result.Append($"            THROW 51000, 'Registro já existe nesta transação', 1\r\n");
                result.Append($"        ELSE IF @Action = 'update' BEGIN\r\n");
                result.Append($"            IF @ActionAux = 'create'\r\n");
                result.Append($"                EXEC [dbo].[{table["Alias"]}Validate] @LoginId, @UserName, 'create', NULL, @ActualRecord\r\n");
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
                result.Append($"                   ,[OriginalRecord] = @OriginalRecord\r\n");
                result.Append($"                   ,[ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END\r\n");
                result.Append($"        COMMIT TRANSACTION\r\n");
                result.Append($"\r\n");
                result.Append($"        RETURN CAST(@OperationId AS BIGINT)\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        IF @@TRANCOUNT > @TRANCOUNT BEGIN\r\n");
                result.Append($"            ROLLBACK TRANSACTION [SavePoint];\r\n");
                result.Append($"            COMMIT TRANSACTION\r\n");
                result.Append($"        END;\r\n");
                result.Append($"        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));\r\n");
                result.Append($"        THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static StringBuilder GetScriptCommitTable(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Commit]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Commit]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Commit] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Alias"]}Commit](@LoginId BIGINT\r\n");
                result.Append($"                                             ,@UserName NVARCHAR(25)\r\n");
                result.Append($"                                             ,@OperationId BIGINT) AS BEGIN\r\n");
                result.Append($"    DECLARE @TRANCOUNT INT = @@TRANCOUNT\r\n");
                result.Append($"            ,@ErrorMessage NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @TransactionId BIGINT\r\n");
                result.Append($"               ,@TransactionIdAux BIGINT\r\n");
                result.Append($"               ,@TableName NVARCHAR(25)\r\n");
                result.Append($"               ,@Action NVARCHAR(15)\r\n");
                result.Append($"               ,@CreatedBy NVARCHAR(25)\r\n");
                result.Append($"               ,@OriginalRecord NVARCHAR(max)\r\n");
                result.Append($"               ,@ActualRecord NVARCHAR(max)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"\r\n");
                result.Append($"        BEGIN TRANSACTION\r\n");
                result.Append($"        SAVE TRANSACTION [SavePoint]\r\n");
                result.Append($"        IF @LoginId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @LoginId requerido', 1\r\n");
                result.Append($"        IF @UserName IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @UserName requerido', 1\r\n");
                result.Append($"        IF @OperationId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @OperationId requerido', 1\r\n");
                result.Append($"        SELECT @TransactionId = [TransactionId]\r\n");
                result.Append($"               ,@TableName = [TableName]\r\n");
                result.Append($"               ,@Action = [Action]\r\n");
                result.Append($"               ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"               ,@OriginalRecord = [OriginalRecord]\r\n");
                result.Append($"               ,@ActualRecord = [ActualRecord]\r\n");
                result.Append($"               ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [Id] = @OperationId\r\n");
                result.Append($"        IF @@ROWCOUNT = 0\r\n");
                result.Append($"            THROW 51000, 'Operação inexistente', 1\r\n");
                result.Append($"        IF @TableName <> '{table["Name"]}'\r\n");
                result.Append($"            THROW 51000, 'Tabela da operação é inválida', 1\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");
                result.Append($"        EXEC @TransactionIdAux = [dbo].[{table["Alias"]}Validate] @LoginId, @UserName, @Action, @OriginalRecord, @ActualRecord\r\n");
                result.Append($"        IF @TransactionId <> @TransactionIdAux\r\n");
                result.Append($"            THROW 51000, 'Transação da operação é inválida', 1\r\n");
                result.Append($"        DECLARE @W_Id {columnRows[0]["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.Id') AS {columnRows[0]["#DataType"]})\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @Action = 'delete'\r\n");
                result.Append($"            DELETE FROM [dbo].[{table["Name"]}] WHERE [Id] = @W_Id\r\n");

                var nonpkColumnRows = columnRows.FindAll(row => !Settings.ToBoolean(row["IsPrimarykey"]));
                var firstTime = true;

                if (nonpkColumnRows.Count > 0)
                {
                    foreach (var column in nonpkColumnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"        ELSE BEGIN\r\n");
                            result.Append($"\r\n");
                            result.Append($"            DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                   ,@W_{column["Name"]} {column["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                    }
                    result.Append($"\r\n");
                }
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            IF @Action = 'create'\r\n");
                        result.Append($"                INSERT INTO [dbo].[{table["Name"]}] ([{column["Name"]}]\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                                ,[{column["Name"]}]\r\n");
                }
                result.Append($"                                                ,[CreatedAt]\r\n");
                result.Append($"                                                ,[CreatedBy])\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"                                          VALUES (@W_{column["Name"]}\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                                 ,@W_{column["Name"]}\r\n");
                }
                result.Append($"                                                 ,GETDATE()\r\n");
                result.Append($"                                                 ,@UserName)\r\n");
                result.Append($"            ELSE\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"                UPDATE [dbo].[{table["Name"]}] SET [{column["Name"]}] = @W_{column["Name"]}\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                              ,[{column["Name"]}] = @W_{column["Name"]}\r\n");
                }
                result.Append($"                                              ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                                              ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                    WHERE [Id] = @W_Id\r\n");
                result.Append($"        END\r\n");
                result.Append($"        UPDATE [dbo].[Operations]\r\n");
                result.Append($"            SET [IsConfirmed] = 1\r\n");
                result.Append($"                ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                ,[UpdatedBy] = @UserName\r\n");
                result.Append($"            WHERE [Id] = @OperationId\r\n");
                result.Append($"        COMMIT TRANSACTION\r\n");
                result.Append("\r\n");
                result.Append($"        RETURN @TransactionId\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        IF @@TRANCOUNT > @TRANCOUNT BEGIN\r\n");
                result.Append($"            ROLLBACK TRANSACTION [SavePoint];\r\n");
                result.Append($"            COMMIT TRANSACTION\r\n");
                result.Append($"        END;\r\n");
                result.Append($"        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));\r\n");
                result.Append($"        THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static StringBuilder GetScriptValidateTable(DataRow table, TDataRows tables, TDataRows columns, TDataRows domains, TDataRows types, TDataRows indexes, TDataRows indexkeys, TDataRows uniques)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Validate]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Validate]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Validate] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Alias"]}Validate](@LoginId BIGINT\r\n");
                result.Append($"                                               ,@UserName NVARCHAR(25)\r\n");
                result.Append($"                                               ,@Action NVARCHAR(15)\r\n");
                result.Append($"                                               ,@OriginalRecord NVARCHAR(max)\r\n");
                result.Append($"                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN\r\n");
                result.Append($"    DECLARE @ErrorMessage NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"        IF @LoginId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @LoginId é requerido', 1\r\n");
                result.Append($"        IF @UserName IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @UserName é requerido', 1\r\n");
                result.Append($"        IF @Action IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @Action é requerido', 1\r\n");
                result.Append($"        IF @Action NOT IN ('create', 'update', 'delete')\r\n");
                result.Append($"            THROW 51000, 'Valor de @Action é inválido', 1\r\n");
                result.Append($"        IF @ActualRecord IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @ActualRecord é requerido', 1\r\n");
                result.Append($"        IF ISJSON(@ActualRecord) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1\r\n");
                result.Append($"        DECLARE @TransactionId BIGINT = (SELECT MAX([Id]) FROM [dbo].[Transactions] WHERE [LoginId] = @LoginId)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"               ,@CreatedBy NVARCHAR(25)\r\n");
                result.Append($"               ,@W_Id AS {columnRows[0]["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.Id') AS {columnRows[0]["#DataType"]})\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @TransactionId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Não existe transação para este @LoginId', 1\r\n");
                result.Append($"        SELECT @IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"              ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"            FROM [dbo].[Transactions]\r\n");
                result.Append($"            WHERE [Id] = @TransactionId\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1;\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @UserName <> @CreatedBy\r\n");
                result.Append($"            THROW 51000, 'Erro grave de segurança', 1\r\n");

                var constraints = GetConstraints(columnRows[0], domains, types);

                result.Append($"        IF @W_Id IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = 'Valor de {columnRows[0]["Name"]} em @ActualRecord é requerido.';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                if (constraints.TryGetValue("Minimum", out dynamic? value))
                {
                    result.Append($"        IF @W_Id < CAST('{value}' AS {columnRows[0]["#DataType"]})\r\n");
                    result.Append($"            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a {value}', 1\r\n");
                }
                if (constraints.TryGetValue("Maximum", out value))
                {
                    result.Append($"        IF @W_Id < CAST('{value}' AS {columnRows[0]["#DataType"]})\r\n");
                    result.Append($"            THROW 51000, 'Valor de Id em @ActualRecord deve ser menor que ou igual a {value}', 1\r\n");
                }
                result.Append($"        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_Id");
                result.Append(") BEGIN\r\n");
                result.Append($"            IF @Action = 'create'\r\n");
                result.Append($"                THROW 51000, 'Chave-primária já existe em {table["Name"]}', 1\r\n");
                result.Append($"        END ELSE IF @Action <> 'create'\r\n");
                result.Append($"            THROW 51000, 'Chave-primária não existe em {table["Name"]}', 1\r\n");
                result.Append($"        IF @Action <> 'create' BEGIN\r\n");
                result.Append($"            IF @OriginalRecord IS NULL\r\n");
                result.Append($"                THROW 51000, 'Valor de @OriginalRecord é requerido', 1\r\n");
                result.Append($"            IF ISJSON(@OriginalRecord) = 0\r\n");
                result.Append($"                THROW 51000, 'Valor de @OriginalRecord não está no formato JSON', 1\r\n");

                var firstTime = true;

                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            IF @Action = 'update'\r\n");
                        firstTime = false;
                    }
                    result.Append($"                AND [crudex].[IS_EQUAL]([crudex].[JSON_EXTRACT](@ActualRecord, '$.{column["Name"]}'), [crudex].[JSON_EXTRACT](@OriginalRecord, '$.{column["Name"]}'), '{column["#TypeName"]}') = 1\r\n");
                }
                result.Append($"                THROW 51000, 'Nenhuma alteração feita no registro', 1\r\n");
                firstTime = true;
                foreach (var column in columnRows)
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
                        result.Append($"[{column["Name"]}] = [crudex].[JSON_EXTRACT](@OriginalRecord, '$.{column["Name"]}')");
                    else
                        result.Append($"[crudex].[IS_EQUAL]([{column["Name"]}], [crudex].[JSON_EXTRACT](@OriginalRecord, '$.{column["Name"]}'), '{column["#TypeName"]}') = 1");
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
                        result.Append($"            IF EXISTS(SELECT 1 FROM [dbo].[{reference["#TableName"]}] WHERE [{reference["Name"]}] = @W_{columnRows[0]["Name"]})\r\n");
                        result.Append($"                THROW 51000, 'Chave-primária referenciada em {reference["#TableName"]}', 1\r\n");
                    }
                    result.Append($"        END ELSE BEGIN\r\n");
                }
                else
                    result.Append($"        IF @Action <> 'delete' BEGIN\r\n");
                result.Append($"\r\n");

                var nopkColumnRows = columnRows.FindAll(column => !Settings.ToBoolean(column["IsPrimarykey"]));

                firstTime = true;
                foreach (var column in nopkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                   ,@W_{column["Name"]} {column["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
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
                        var pkColumn = columns.First(col => Settings.ToLong(col["TableId"]) == Settings.ToLong(referenceTable["Id"]) && Settings.ToBoolean(col["IsPrimarykey"]));

                        result.Append($"            IF NOT EXISTS(SELECT 1 FROM [dbo].[{referenceTable["Name"]}] WHERE [{pkColumn["Name"]}] = @W_{column["Name"]})\r\n");
                        result.Append($"                THROW 51000, 'Valor de {column["Name"]} em @ActualRecord inexiste em {referenceTable["Name"]}', 1\r\n");
                    }
                }
                var uniqueRows = uniques.FindAll(unique => Settings.ToLong(unique["#TableId1"]) == Settings.ToLong(table["Id"]) ||
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
                result.Append($"        RETURN @TransactionId\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));\r\n");
                result.Append($"        THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static readonly List<long> ProcessedTableIds = [];
        private static StringBuilder GetReferenceQueries(DataRow reference, TDataRows columns, TDictionary tmpNames, string tableName = "#result")
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(reference["ReferenceTableId"]));
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
            foreach ( var column in columnRows)
            {
                if (firstTime)
                {
                    if (spaces != "")
                        result.Append($"        INSERT INTO [{tmpName}]\r\n");
                        
                    result.Append($"{spaces}        SELECT DISTINCT '{column["#TableAlias"]}' AS ClassName\r\n");
                    firstTime = false;
                }
                result.Append($"{spaces}              ,[R].[{column["Name"]}]\r\n");
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
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Name"]}Read]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Name"]}Read]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Name"]}Read] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE [dbo].[{table["Name"]}Read](@LoginId BIGINT\r\n");
                result.Append($"                                          ,@RecordFilter NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@OrderBy NVARCHAR(MAX)\r\n");
                result.Append($"                                          ,@PaddingGridLastPage BIT\r\n");
                result.Append($"                                          ,@PageNumber INT OUT\r\n");
                result.Append($"                                          ,@LimitRows INT OUT\r\n");
                result.Append($"                                          ,@MaxPage INT OUT\r\n");
                result.Append($"                                          ,@ReturnValue BIGINT OUT) AS BEGIN\r\n");
                result.Append($"    DECLARE @ErrorMessage NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"        IF @LoginId IS NULL\r\n");
                result.Append($"            THROW 51000, 'Valor de @LoginId é requerido', 1\r\n");
                result.Append($"        IF @RecordFilter IS NULL\r\n");
                result.Append("            SET @RecordFilter = '{}'\r\n");
                result.Append($"        ELSE IF ISJSON(@RecordFilter) = 0\r\n");
                result.Append($"            THROW 51000, 'Valor de @RecordFilter não está no formato JSON', 1\r\n");
                result.Append($"        SET @OrderBy = TRIM(ISNULL(@OrderBy, ''))\r\n");
                result.Append($"        IF @OrderBy = ''\r\n");
                result.Append($"            SET @OrderBy = '[Id]'\r\n");
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
                result.Append($"            SELECT @OrderBy = STRING_AGG('[' + TRIM(CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)\r\n");
                result.Append($"                                                         WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)\r\n");
                result.Append($"                                                         ELSE TRIM([value])\r\n");
                result.Append($"                                                    END) + '] ' + \r\n");
                result.Append($"                                                    CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN 'DESC'\r\n");
                result.Append($"                                                         WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN 'ASC'\r\n");
                result.Append($"                                                         ELSE 'ASC'\r\n");
                result.Append($"                                                    END, ', ')\r\n");
                result.Append($"                FROM STRING_SPLIT(@OrderBy, ',')\r\n");
                result.Append($"        END\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @TransactionId BIGINT = (SELECT MAX([Id]) FROM [dbo].[Transactions] WHERE [LoginId] = @LoginId)\r\n");
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
                    result.Append($"              ,CAST([crudex].[JSON_EXTRACT]([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                }
                result.Append($"            INTO [#tmpOperations]\r\n");
                result.Append($"            FROM [dbo].[Operations]\r\n");
                result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                  AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                result.Append($"        CREATE UNIQUE INDEX [#tmpOperations] ON [#tmpOperations]([{columnRows[0]["Name"]}]");
                result.Append($")\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @_ NVARCHAR(MAX) = (SELECT STRING_AGG(value, ',') FROM OPENJSON(@RecordFilter, '$._'))\r\n");
                result.Append($"               ,@Where NVARCHAR(MAX) = ''\r\n");
                result.Append($"               ,@sql NVARCHAR(MAX)\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @_ IS NULL BEGIN\r\n");

                var filterableColumns = columnRows.FindAll(column => Settings.ToBoolean(column["IsFilterable"]));

                firstTime = true;
                foreach (var column in filterableColumns)
                {
                    if (firstTime)
                    {
                        result.Append($"            DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@RecordFilter, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                   ,@W_{column["Name"]} {column["#DataType"]} = CAST([crudex].[JSON_EXTRACT](@RecordFilter, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                }
                result.Append($"\r\n");
                foreach (var column in filterableColumns)
                {
                    var validations = GetConstraints(column, domains, types);

                    result.Append($"            IF @W_{column["Name"]} IS NOT NULL BEGIN\r\n");
                    if (validations.TryGetValue("Minimum", out dynamic? value))
                    {
                        result.Append($"                IF @W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]})\r\n");
                        result.Append($"                    THROW 51000, 'Valor de {column["Name"]} deve ser maior que ou igual a ''{value}''', 1\r\n");
                    }
                    if (validations.TryGetValue("Maximum", out value))
                    {
                        result.Append($"                IF @W_{column["Name"]} > CAST('{value}' AS {column["#DataType"]})\r\n");
                        result.Append($"                    THROW 51000, 'Valor de {column["Name"]} deve ser menor que ou igual a ''{value}''', 1\r\n");
                    }
                    result.Append($"                SET @Where = @Where + ' AND [T].[{column["Name"]}] = @{column["Name"]}'\r\n");
                    result.Append($"            END\r\n");
                }
                result.Append($"        END ELSE\r\n");
                result.Append($"            SET @Where = ' AND [T].[Id] IN (' + @_ + ')'\r\n");
                result.Append($"        SET @sql = 'INSERT [#tmpTable]\r\n");
                result.Append($"                        SELECT ''T'' AS [_]\r\n");
                result.Append($"                              ,[T].[Id]\r\n");
                result.Append($"                            FROM [dbo].[{table["Name"]}] [T]\r\n");
                result.Append($"                                LEFT JOIN [#tmpOperations] [#] ON [#].[Id] = [T].[Id]");
                result.Append($"\r\n");
                result.Append($"                            WHERE [#].[{columnRows[0]["Name"]}] IS NULL' + @Where + '\r\n");
                result.Append($"                        UNION ALL\r\n");
                result.Append($"                            SELECT ''O'' AS [_]\r\n");
                result.Append($"                                  ,[T].[{columnRows[0]["Name"]}]\r\n");
                result.Append($"                                FROM [#tmpOperations] [T]\r\n");
                result.Append($"                                WHERE [T].[_] <> ''delete''' + @Where\r\n");
                result.Append($"        CREATE TABLE [#tmpTable]([_] CHAR(1)");
                result.Append($", [{columnRows[0]["Name"]}] {columnRows[0]["#DataType"]}");
                result.Append($")\r\n");
                result.Append($"        IF @_ IS NULL\r\n");
                firstTime = true;
                foreach (var column in filterableColumns)
                {
                    if (firstTime)
                    {
                        result.Append($"            EXEC sp_executesql @sql\r\n");
                        result.Append($"                               ,N'@{column["Name"]} {column["#DataType"]}");
                        firstTime = false;
                    }
                    else
                    {
                        result.Append($"\r\n");
                        result.Append($"                               ,@{column["Name"]} {column["#DataType"]}");
                    }
                }
                result.Append($"'\r\n");
                foreach (var column in filterableColumns)
                    result.Append($"                           ,@{column["Name"]} = @W_{column["Name"]}\r\n");
                result.Append($"        ELSE\r\n");
                result.Append($"            EXEC sp_executesql @sql\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @RowCount INT = @@ROWCOUNT\r\n");
                result.Append($"               ,@OffSet INT\r\n");
                result.Append($"\r\n");
                result.Append($"        CREATE UNIQUE INDEX [#tmpTable] ON [#tmpTable]([{columnRows[0]["Name"]}]");
                result.Append($")\r\n");
                result.Append($"        IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\r\n");
                result.Append($"            SET @OffSet = 0\r\n");
                result.Append($"            SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END\r\n");
                result.Append($"            SET @PageNumber = 1\r\n");
                result.Append($"            SET @MaxPage = 1\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END\r\n");
                result.Append($"            IF ABS(@PageNumber) > @MaxPage\r\n");
                result.Append($"                SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END\r\n");
                result.Append($"            IF @PageNumber < 0\r\n");
                result.Append($"                SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1\r\n");
                result.Append($"            SET @OffSet = (@PageNumber - 1) * @LimitRows\r\n");
                result.Append($"            IF @PaddingGridLastPage = 1 AND @OffSet + @LimitRows > @RowCount\r\n");
                result.Append($"                SET @OffSet = CASE WHEN @RowCount > @LimitRows THEN @RowCount - @LimitRows ELSE 0 END\r\n");
                result.Append($"        END\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT TOP 0 CAST(NULL AS NVARCHAR(50)) AS [ClassName]\r\n");
                        firstTime = false;
                    }
                    result.Append($"                    ,CAST(NULL AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                }
                result.Append($"            INTO [#result]\r\n");

                result.Append($"        SET @sql = 'INSERT #result\r\n");
                result.Append($"                        SELECT ''{table["Alias"]}'' AS [ClassName]\r\n");
                foreach (var column in columnRows)
                    result.Append($"                              ,[T].[{column["Name"]}]\r\n");
                result.Append($"                            FROM [#tmpTable] [#]\r\n");
                result.Append($"                                INNER JOIN [dbo].[{table["Name"]}] [T] ON [T].[Id] = [#].[Id]\r\n");
                result.Append($"                            WHERE [#].[_] = ''T''\r\n");
                result.Append($"                        UNION ALL\r\n");
                result.Append($"                            SELECT ''{table["Alias"]}'' AS [ClassName]\r\n");
                foreach (var column in columnRows)
                    result.Append($"                                  ,[O].[{column["Name"]}]\r\n");
                result.Append($"                                FROM [#tmpTable] [#]\r\n");
                result.Append($"                                    INNER JOIN [#tmpOperations] [O] ON [O].[Id] = [#].[Id]\r\n");
                result.Append($"                                WHERE [#].[_] = ''O''\r\n");
                result.Append($"                        ORDER BY ' + @OrderBy + '\r\n");
                result.Append($"                        OFFSET ' + CAST(@offset AS NVARCHAR(20)) + ' ROWS\r\n");
                result.Append($"                        FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'\r\n");
                result.Append($"        EXEC sp_executesql @sql\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT [ClassName]\r\n");
                        firstTime = false;
                    }
                    result.Append($"              ,[{column["Name"]}]\r\n");
                }
                result.Append($"            FROM [#result]\r\n");

                var references = columnRows.FindAll(column => !Settings.IsNull(column["ReferenceTableId"]));
                var tmpTemps = new TDictionary();

                foreach (var reference in references)
                {
                    ProcessedTableIds.Clear();
                    result.Append(GetReferenceQueries(reference, columns, tmpTemps));
                }
                foreach (var item in tmpTemps)
                    result.Append($"        SELECT [{item.Key}].* FROM [{item.Value}] AS [{item.Key}]\r\n");
                
                result.Append($"        SET @ReturnValue = @RowCount\r\n");
                result.Append($"\r\n");
                result.Append($"        RETURN 0\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));\r\n");
                result.Append($"        THROW 51000, @ErrorMessage, 1;\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static StringBuilder GetScriptListTable(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                var listableColumns = columnRows.FindAll(row => Settings.ToBoolean(row["IsListable"]));

                if (listableColumns.Count > 0)
                {
                    var listableColumn = listableColumns[0];

                    result.Append($"/**********************************************************************************\r\n");
                    result.Append($"Criar stored procedure [dbo].[{table["Name"]}List]\r\n");
                    result.Append($"**********************************************************************************/\r\n");
                    result.Append($"IF(SELECT object_id('[dbo].[{table["Name"]}List]', 'P')) IS NULL\r\n");
                    result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Name"]}List] AS PRINT 1')\r\n");
                    result.Append($"GO\r\n");
                    result.Append($"ALTER PROCEDURE [dbo].[{table["Name"]}List](@Value NVARCHAR(MAX)\r\n");
                    result.Append($"                                          ,@PaddingGridLastPage BIT\r\n");
                    result.Append($"                                          ,@PageNumber INT OUT\r\n");
                    result.Append($"                                          ,@LimitRows INT OUT\r\n");
                    result.Append($"                                          ,@MaxPage INT OUT\r\n");
                    result.Append($"                                          ,@ReturnValue BIGINT OUT) AS BEGIN\r\n");
                    result.Append($"    DECLARE @ErrorMessage NVARCHAR(MAX)\r\n");
                    result.Append($"\r\n");
                    result.Append($"    BEGIN TRY\r\n");
                    result.Append($"        SET NOCOUNT ON\r\n");
                    result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                    result.Append($"        IF @Value IS NULL\r\n");
                    result.Append($"            SET @Value = ''\r\n");

                    result.Append($"        SELECT [Id]\r\n");
                    result.Append($"            INTO [#query]\r\n");
                    result.Append($"            FROM [dbo].[{table["Name"]}]\r\n");
                    result.Append($"            WHERE [{listableColumn["Name"]}] LIKE '%' + @Value + '%'\r\n");
                    result.Append($"            ORDER BY [{listableColumn["Name"]}]\r\n");
                    result.Append($"\r\n");
                    result.Append($"        DECLARE @RowCount INT = @@ROWCOUNT\r\n");
                    result.Append($"               ,@OffSet INT\r\n");
                    result.Append($"               ,@sql NVARCHAR(MAX)\r\n");
                    result.Append($"\r\n");
                    result.Append($"        CREATE UNIQUE INDEX [#unqQuery] ON [#query]([Id])\r\n");
                    result.Append($"        IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\r\n");
                    result.Append($"            SET @OffSet = 0\r\n");
                    result.Append($"            SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END\r\n");
                    result.Append($"            SET @PageNumber = 1\r\n");
                    result.Append($"            SET @MaxPage = 1\r\n");
                    result.Append($"        END ELSE BEGIN\r\n");
                    result.Append($"            SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END\r\n");
                    result.Append($"            IF ABS(@PageNumber) > @MaxPage\r\n");
                    result.Append($"                SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END\r\n");
                    result.Append($"            IF @PageNumber < 0\r\n");
                    result.Append($"                SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1\r\n");
                    result.Append($"            SET @OffSet = (@PageNumber - 1) * @LimitRows\r\n");
                    result.Append($"            IF @PaddingGridLastPage = 1 AND @OffSet + @LimitRows > @RowCount\r\n");
                    result.Append($"                SET @OffSet = CASE WHEN @RowCount > @LimitRows THEN @RowCount - @LimitRows ELSE 0 END\r\n");
                    result.Append($"        END\r\n");
                    result.Append($"        SET @sql = 'SELECT [T].[Id]\r\n");
                    result.Append($"                          ,[T].[{listableColumn["Name"]}]\r\n");
                    result.Append($"                       FROM [#query] [Q]\r\n");
                    result.Append($"                           INNER JOIN [dbo].[{table["Name"]}] [T] ON [T].[Id] = [Q].[Id]\r\n");
                    result.Append($"                       ORDER BY [T].[{listableColumn["Name"]}]\r\n");
                    result.Append($"                       OFFSET ' + CAST(@offset AS NVARCHAR(20)) + ' ROWS\r\n");
                    result.Append($"                       FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'\r\n");
                    result.Append($"        EXEC sp_executesql @sql\r\n");
                    result.Append($"        SET @ReturnValue = @RowCount\r\n");
                    result.Append($"\r\n");
                    result.Append($"        RETURN 0\r\n");
                    result.Append($"    END TRY\r\n");
                    result.Append($"    BEGIN CATCH\r\n");
                    result.Append($"        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));\r\n");
                    result.Append($"        THROW 51000, @ErrorMessage, 1\r\n");
                    result.Append($"    END CATCH\r\n");
                    result.Append($"END\r\n");
                    result.Append($"GO\r\n");
                }
            }

            return result;
        }
    }
}