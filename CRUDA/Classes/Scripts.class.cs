using CRUDA_LIB;
using ExcelDataReader;
using System.Data;
using System.Text;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;
using TDataRows = System.Collections.Generic.List<System.Data.DataRow>;

namespace CRUDA.Classes
{
    public class Scripts
    {
        static readonly string DirectoryScripts = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_SCRIPTS"));
        public static void GenerateScript(string systemName, string databaseName)
        {
            var dataSet = ExcelToDataSet();
            var columns = (dataSet.Tables["Columns"] ?? throw new Exception("GenerateScript: Tabela Columns não existe.")).AsEnumerable().ToList();
            var indexes = (dataSet.Tables["Indexes"] ?? throw new Exception("GenerateScript: Tabela Indexes não existe.")).AsEnumerable().ToList();
            var indexkeys = (dataSet.Tables["Indexkeys"] ?? throw new Exception("GenerateScript: Tabela Indexkeys não existe.")).AsEnumerable().ToList();
            var domains = (dataSet.Tables["Domains"] ?? throw new Exception("GenerateScript: Tabela Domains não existe.")).AsEnumerable().ToList();
            var categories = (dataSet.Tables["Categories"] ?? throw new Exception("GenerateScript: Tabela Categories não existe.")).AsEnumerable().ToList();
            var types = (dataSet.Tables["Types"] ?? throw new Exception("GenerateScript: Tabela Types não existe.")).AsEnumerable().ToList();
            var system = (dataSet.Tables["Systems"] ?? throw new Exception("GenerateScript: Tabela Systems não existe.")).AsEnumerable().ToList()
                .First(row => ToString(row["Name"]) == systemName);
            var database = (dataSet.Tables["Databases"] ?? throw new Exception("GenerateScript: Tabela Databases não existe.")).AsEnumerable().ToList()
                .First(row => ToString(row["Name"]) == databaseName);
            var databasesTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("GenerateScript: Tabela DatabasesTables não existe.")).AsEnumerable().ToList()
                .FindAll(row => ToLong(row["DatabaseId"]) == ToLong(database?["Id"]));
            var tables = (dataSet.Tables["Tables"] ?? throw new Exception("GenerateScript: Tabela Tables não existe.")).AsEnumerable().ToList();
            var filename = Path.Combine(DirectoryScripts, $"SCRIPT-{databaseName.ToUpper()}.sql");
            var firstTime = true;

            using var stream = new StreamWriter(path: filename, append: false, encoding: Encoding.UTF8);
            foreach (DataRow databaseTable in databasesTables)
            {
                var table = tables.First(table => ToLong(table["Id"]) == ToLong(databaseTable["TableId"]));
                if (firstTime)
                {
                    stream.Write(GetScriptCreateDatabase(database));
                    if (systemName == "cruda")
                        stream.Write(GetScriptOthers());
                    stream.Write(GetScriptTransactions());
                    stream.Write(GetScriptCreateTableTransactions());
                    stream.Write(GetScriptCreateTableOperations());
                    firstTime = false;
                }
                stream.Write(GetScriptCreateTable(table, columns, indexes, indexkeys));
                stream.Write(GetScriptValidateTable(table, tables, columns, domains, types, indexes, indexkeys));
                stream.Write(GetScriptPersistTable(table, columns));
                stream.Write(GetScriptCommitTable(table, columns));
                stream.Write(GetScriptReadTable(table, columns, domains, types));
            }
            stream.Write(GetScriptReferences(tables, columns));
            foreach (var table in tables)
            {
                var datatable = (dataSet.Tables[ToString(table["Name"])] ?? throw new Exception($"GenerateScript: Tabela {table["Name"]} não encontrada")).AsEnumerable().ToList();

                stream.Write(GetScriptInsertTable(table, columns, domains, types, categories, datatable));
            }
        }
        public static DataSet ExcelToDataSet()
        {
            using var stream = File.Open(Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("FILENAME_EXCEL")), FileMode.Open, FileAccess.Read);
            using var reader = ExcelReaderFactory.CreateReader(stream);

            return reader.AsDataSet(new ExcelDataSetConfiguration()
            {
                ConfigureDataTable = _ => new ExcelDataTableConfiguration()
                {
                    UseHeaderRow = true
                }
            });
        }
        private static bool IsNull(object? value)
        {
            return value == DBNull.Value || value == null;
        }
        private static bool ToBoolean(object? value)
        {
            if (IsNull(value))
                return false;

            return Convert.ToBoolean(Convert.ToUInt16(value));
        }
        private static long ToLong(object? value)
        {
            if (IsNull(value))
                return 0;

            return Convert.ToInt64((value ?? 0).ToString());
        }
        private static double ToDouble(object? value)
        {
            if (IsNull(value))
                return 0.0;

            return Convert.ToDouble(value ?? 0);
        }
        private static string ToString(object? value)
        {
            if (IsNull(value))
                return string.Empty;

            return Convert.ToString(value) ?? string.Empty;
        }
        private static TDictionary GetValidations(DataRow column, TDataRows domains, TDataRows types)
        {
            var result = new TDictionary();
            string value;
            var domain = domains.First(domain => ToLong(domain["Id"]) == ToLong(column["DomainId"]));
            var type = types.First(type => ToLong(type["Id"]) == ToLong(domain["TypeId"]));

            if (ToBoolean(column["IsRequired"]))
                result.Add("IsRequired", true);
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
        private static StringBuilder GetScriptCreateDatabase(DataRow database)
        {
            var result = new StringBuilder();
            var folder = database["Folder"].ToString() ?? string.Empty;
            var filename = Path.Combine(folder, ToString(database["Name"]));

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar banco-de-dados {database["Name"]}\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"USE [master]\r\n");
            result.Append($"SET NOCOUNT ON\r\n");
            result.Append($"IF EXISTS(SELECT 1 FROM sys.databases where name = '{database["Alias"]}')\r\n");
            result.Append($"    DROP DATABASE {database["Alias"]}\r\n");
            result.Append($"GO\r\n");
            result.Append($"CREATE DATABASE [{database["Alias"]}]\r\n");
            result.Append($"    CONTAINMENT = NONE\r\n");
            result.Append($"    ON PRIMARY\r\n");
            result.Append($"    (NAME = N'cruda', FILENAME = N'{filename}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)\r\n");
            result.Append($"    LOG ON\r\n");
            result.Append($"    (NAME = N'cruda_log', FILENAME = N'{filename}.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)\r\n");
            result.Append($"    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET COMPATIBILITY_LEVEL = 160\r\n");
            result.Append($"GO\r\n");
            result.Append($"IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))\r\n");
            result.Append($"    EXEC[{database["Alias"]}].[dbo].[sp_fulltext_database] @action = 'enable'\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ANSI_NULL_DEFAULT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ANSI_NULLS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ANSI_PADDING OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ANSI_WARNINGS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ARITHABORT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET AUTO_CLOSE OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET AUTO_SHRINK OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET AUTO_UPDATE_STATISTICS ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET CURSOR_CLOSE_ON_COMMIT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET CURSOR_DEFAULT  GLOBAL\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET CONCAT_NULL_YIELDS_NULL OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET NUMERIC_ROUNDABORT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET QUOTED_IDENTIFIER OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET RECURSIVE_TRIGGERS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET  DISABLE_BROKER\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET AUTO_UPDATE_STATISTICS_ASYNC OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET DATE_CORRELATION_OPTIMIZATION OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET TRUSTWORTHY OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ALLOW_SNAPSHOT_ISOLATION ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET PARAMETERIZATION SIMPLE\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET READ_COMMITTED_SNAPSHOT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET HONOR_BROKER_PRIORITY OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET RECOVERY SIMPLE\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET  MULTI_USER\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET PAGE_VERIFY CHECKSUM\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET DB_CHAINING OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF)\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET TARGET_RECOVERY_TIME = 60 SECONDS\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET DELAYED_DURABILITY = DISABLED\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET ACCELERATED_DATABASE_RECOVERY = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET QUERY_STORE = ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), " +
                          $"DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, " +
                          $"SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)\r\n");
            result.Append($"GO\r\n");
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Início da criação dos scripts\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"USE [{database["Alias"]}]\r\n");
            result.Append($"GO\r\n");
            result.Append($"SET ANSI_NULLS ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"SET QUOTED_IDENTIFIER ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"CREATE SCHEMA cruda AUTHORIZATION [dbo]\r\n");
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
            result.Append($"Criar stored procedure [dbo].[GenerateId]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.GenerateId.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[Login]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.Login.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [dbo].[GetPublicKey]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.GetPublicKey.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar function [dbo].[NumberInWordsOfHundreds]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.NumberInWordsOfHundreds.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar function [dbo].[NumberInWords]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "dbo.NumberInWords.sql")));

            return result;
        }
        private static StringBuilder GetScriptTransactions()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [cruda].[IsEquals]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.IsEquals.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [cruda].TransactionBegin]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.TransactionBegin.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [cruda].[TransactionCommit]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.TransactionCommit.sql")));
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar stored procedure [cruda].[TransactionRollback]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.TransactionRollback.sql")));

            return result;
        }
        private static StringBuilder GetScriptCreateTableTransactions()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar tabela [cruda].[Transactions]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"IF (SELECT object_id('[cruda].[Transactions]', 'U')) IS NOT NULL\r\n");
            result.Append($"    DROP TABLE [cruda].[Transactions]\r\n");
            result.Append($"CREATE TABLE [cruda].[Transactions]([Id] [int] IDENTITY(1,1) NOT NULL\r\n");
            result.Append($"                                   ,[LoginId] [bigint] NOT NULL\r\n");
            result.Append($"                                   ,[IsConfirmed] [bit] NULL\r\n");
            result.Append($"                                   ,[CreatedAt] datetime NOT NULL\r\n");
            result.Append($"                                   ,[CreatedBy] varchar(25) NOT NULL\r\n");
            result.Append($"                                   ,[UpdatedAt] datetime NULL\r\n");
            result.Append($"                                   ,[UpdatedBy] varchar(25) NULL)\r\n");
            result.Append($"ALTER TABLE [cruda].[Transactions] ADD CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED([Id])\r\n");
            result.Append($"CREATE INDEX [IDX_Transactions_LoginId_IsConfirmed] ON [cruda].[Transactions]([LoginId], [IsConfirmed])\r\n");
            result.Append($"GO\r\n");

            return result;
        }
        private static StringBuilder GetScriptCreateTableOperations()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar tabela [cruda].[Operations]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"IF (SELECT object_id('[cruda].[Operations]', 'U')) IS NOT NULL\r\n");
            result.Append($"    DROP TABLE [cruda].[Operations]\r\n");
            result.Append($"CREATE TABLE [cruda].[Operations]([Id] [int] IDENTITY(1,1) NOT NULL\r\n");
            result.Append($"                                 ,[TransactionId] [int] NOT NULL\r\n");
            result.Append($"                                 ,[TableName] [varchar](25) NOT NULL\r\n");
            result.Append($"                                 ,[Action] [varchar](15) NOT NULL\r\n");
            result.Append($"                                 ,[LastRecord] [varchar](max) NULL\r\n");
            result.Append($"                                 ,[ActualRecord] [varchar](max) NOT NULL\r\n");
            result.Append($"                                 ,[IsConfirmed] [bit] NULL\r\n");
            result.Append($"                                 ,[CreatedAt] datetime NOT NULL\r\n");
            result.Append($"                                 ,[CreatedBy] varchar(25) NOT NULL\r\n");
            result.Append($"                                 ,[UpdatedAt] datetime NULL\r\n");
            result.Append($"                                 ,[UpdatedBy] varchar(25) NULL)\r\n");
            result.Append($"ALTER TABLE [cruda].[Operations] ADD CONSTRAINT PK_Operations PRIMARY KEY CLUSTERED([Id])\r\n");
            result.Append($"CREATE INDEX [IDX_Operations_TransactionId_TableName_Action_IsConfirmed] ON [cruda].[Operations]([TransactionId], [TableName], [Action], [IsConfirmed])\r\n");
            result.Append($"GO\r\n");

            return result;
        }
        private static StringBuilder GetScriptCreateTable(DataRow table, TDataRows columns, TDataRows indexes, TDataRows indexkeys)
        {
            var result = new StringBuilder();
            var firstTime = true;
            var columnRows = columns.FindAll(column => ToLong(column["TableId"]) == ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF (SELECT object_id('[dbo].[{table["Name"]}]', 'U')) IS NOT NULL\r\n");
                result.Append($"    DROP TABLE [dbo].[{table["Name"]}]\r\n");

                foreach (DataRow column in columnRows)
                {
                    var typeName = ToString(column["#DataType"]);
                    var definition = $"[{column["Name"]}] {typeName} {(ToBoolean(column["IsAutoIncrement"]) ? "IDENTITY(1,1) " : "")}{(ToBoolean(column["IsRequired"]) ? "NOT NULL" : "NULL")}";

                    if (firstTime)
                    {
                        result.Append($"CREATE TABLE [dbo].[{table["Name"]}]({definition}\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                    ,{definition}\r\n");
                }
                result.Append($"                                    ,[CreatedAt] datetime NOT NULL\r\n");
                result.Append($"                                    ,[CreatedBy] varchar(25) NOT NULL\r\n");
                result.Append($"                                    ,[UpdatedAt] datetime NULL\r\n");
                result.Append($"                                    ,[UpdatedBy] varchar(25) NULL)\r\n");
                firstTime = true;

                var pkColumnRows = columns.FindAll(column => ToLong(column["TableId"]) == ToLong(table["Id"]) && ToBoolean(column["IsPrimarykey"]));

                if (pkColumnRows.Count > 0)
                {
                    foreach (DataRow pkColumnRow in pkColumnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"ALTER TABLE [dbo].[{table["Name"]}] ADD CONSTRAINT PK_{table["Name"]} PRIMARY KEY CLUSTERED ([{pkColumnRow["Name"]}]");
                            firstTime = false;
                        }
                        else
                            result.Append($", [{pkColumnRow["Name"]}]");
                    }
                    result.Append($")\r\n");
                }

                var indexRows = indexes.FindAll(index => ToLong(index["TableId"]) == ToLong(table["Id"]));

                if (indexRows.Count > 0)
                {
                    foreach (var index in indexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => ToLong(indexkey["IndexId"]) == ToLong(index["Id"]));

                        if (indexkeyRows.Count > 0)
                        {
                            firstTime = true;
                            foreach (var indexkey in indexkeyRows)
                            {
                                var column = columns.First(column => ToLong(column["Id"]) == ToLong(indexkey["ColumnId"]));
                                var definition = $"[{column["Name"]}] {(ToBoolean(indexkey["IsDescending"]) ? "DESC" : "ASC")}";

                                if (firstTime)
                                {
                                    result.Append($"CREATE {(ToBoolean(index["IsUnique"]) ? "UNIQUE" : "")} INDEX [{index["Name"]}] ON [dbo].[{table["Name"]}]({definition}");
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
            var foreignRows = columns.FindAll(column => ToString(column["ReferenceTableId"]) != string.Empty);

            if (foreignRows.Count > 0)
            {
                foreach (var foreign in foreignRows)
                {
                    var primaryTable = tables.First(table => ToLong(table["Id"]) == ToLong(foreign["TableId"]));
                    var foreignTable = tables.First(table => ToLong(table["Id"]) == ToLong(foreign["ReferenceTableId"]));
                    var foreignKey = columns.First(column => ToLong(column["TableId"]) == ToLong(foreignTable["Id"]) && ToBoolean(column["IsPrimarykey"]));
                    var foreignName = $"FK_{primaryTable["Name"]}_{foreignTable["Name"]}";

                    if (primaryTable["Name"].ToString() != lastTableName)
                    {
                        result.Append($"/**********************************************************************************\r\n");
                        result.Append($"Criar referências de [dbo].[{primaryTable["Name"]}]\r\n");
                        result.Append($"**********************************************************************************/\r\n");
                        lastTableName = primaryTable["Name"].ToString();
                    }
                    result.Append($"IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = '{foreignName}')\r\n");
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
        private static StringBuilder GetScriptInsertTable(DataRow table, TDataRows columns, TDataRows domains, TDataRows types, TDataRows categories, TDataRows dataRows)
        {
            var result = new StringBuilder();

            if (dataRows.Count > 0)
            {
                var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]));

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
                            var domain = domains.First(domain => ToLong(domain["Id"]) == ToLong(column["DomainId"]));
                            var type = types.First(type => ToLong(type["Id"]) == ToLong(domain["TypeId"]));
                            var category = categories.First(category => ToLong(category["Id"]) == ToLong(type["CategoryId"]));
                            var categoryName = ToString(category["Name"]);
                            var columnName = ToString(column["Name"]);
                            dynamic? value = data[columnName];

                            if (categoryName == "numeric")
                                value ??= null;
                            else if (categoryName == "boolean")
                                value = IsNull(value) ? null : value ? 1 : 0;
                            if ((value = ToString(value)) == string.Empty)
                                value = "NULL";
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
                        result.Append($"                                ,'admnistrator'\r\n");
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
            var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Persist]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Persist]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Persist] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE[dbo].[{table["Alias"]}Persist](@LoginId BIGINT\r\n");
                result.Append($"                                              ,@UserName VARCHAR(25)\r\n");
                result.Append($"                                              ,@Action VARCHAR(15)\r\n");
                result.Append($"                                              ,@LastRecord VARCHAR(max)\r\n");
                result.Append($"                                              ,@ActualRecord VARCHAR(max)) AS BEGIN\r\n");
                result.Append($"    DECLARE @TranCount INT = @@TRANCOUNT\r\n");
                result.Append($"\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [{table["Alias"]}Persist]: '\r\n");
                result.Append($"               ,@TransactionId INT\r\n");
                result.Append($"               ,@OperationId INT\r\n");
                result.Append($"               ,@CreatedBy VARCHAR(25)\r\n");
                result.Append($"               ,@ActionAux VARCHAR(15)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"\r\n");
                result.Append($"        BEGIN TRANSACTION\r\n");
                result.Append($"        SAVE TRANSACTION [SavePoint]\r\n");
                result.Append($"        EXEC @TransactionId = [dbo].[{table["Alias"]}Validate] @LoginId, @UserName, @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        IF @TransactionId = 0\r\n");
                result.Append($"            GOTO EXIT_PROCEDURE\r\n");
                result.Append($"\r\n");

                var pkColumnRows = columnRows.FindAll(row => ToBoolean(row["IsPrimarykey"]));
                var firstTime = true;

                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"               ,@W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                }
                result.Append($"\r\n");
                firstTime = true;
                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT @OperationId = [Id]\r\n");
                        result.Append($"              ,@CreatedBy = [CreatedBy]\r\n");
                        result.Append($"              ,@ActionAux = [Action]\r\n");
                        result.Append($"              ,@IsConfirmed = [IsConfirmed]\r\n");
                        result.Append($"            FROM [cruda].[Operations]\r\n");
                        result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                        result.Append($"                  AND [TableName] = 'Columns'\r\n");
                        result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                                        firstTime = false;
                    }
                    result.Append($"                  AND CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]}) = @W_{column["Name"]}\r\n");
                }
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                result.Append($"            INSERT INTO [cruda].[Operations] ([TransactionId]\r\n");
                result.Append($"                                             ,[TableName]\r\n");
                result.Append($"                                             ,[Action]\r\n");
                result.Append($"                                             ,[LastRecord]\r\n");
                result.Append($"                                             ,[ActualRecord]\r\n");
                result.Append($"                                             ,[IsConfirmed]\r\n");
                result.Append($"                                             ,[CreatedAt]\r\n");
                result.Append($"                                             ,[CreatedBy])\r\n");
                result.Append($"                                       VALUES(@TransactionId\r\n");
                result.Append($"                                             ,'{table["Name"]}'\r\n");
                result.Append($"                                             ,@Action\r\n");
                result.Append($"                                             ,@LastRecord\r\n");
                result.Append($"                                             ,@ActualRecord\r\n");
                result.Append($"                                             ,NULL\r\n");
                result.Append($"                                             ,GETDATE()\r\n");
                result.Append($"                                             ,@UserName)\r\n");
                result.Append($"            SET @OperationId = @@IDENTITY\r\n");
                result.Append($"        END IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END ELSE IF @UserName <> @CreatedBy BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END ELSE IF @ActionAux = 'delete' BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Registro excluído nesta transação';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END ELSE IF @Action = 'create' BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Registro já existe nesta transação';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END ELSE IF @Action = 'update' BEGIN\r\n");
                result.Append($"            UPDATE [cruda].[Operations]\r\n");
                result.Append($"                SET [ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END ELSE IF @ActionAux = 'create' BEGIN\r\n");
                result.Append($"            UPDATE [cruda].[Operations] \r\n");
                result.Append($"                SET [IsConfirmed] = 0\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            UPDATE [cruda].[Operations]\r\n");
                result.Append($"                SET [Action] = 'delete'\r\n");
                result.Append($"                   ,[LastRecord] = @LastRecord\r\n");
                result.Append($"                   ,[ActualRecord] = @ActualRecord\r\n");
                result.Append($"                   ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                   ,[UpdatedBy] = @UserName\r\n");
                result.Append($"                WHERE [Id] = @OperationId\r\n");
                result.Append($"        END\r\n");
                result.Append($"\r\n");
                result.Append($"        EXIT_PROCEDURE:\r\n");
                result.Append($"\r\n");
                result.Append($"        COMMIT TRANSACTION\r\n");
                result.Append($"\r\n");
                result.Append($"        RETURN CAST(@OperationId AS INT)\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        IF @@TRANCOUNT > @TranCount BEGIN\r\n");
                result.Append($"            ROLLBACK TRANSACTION [SavePoint];\r\n");
                result.Append($"            COMMIT TRANSACTION\r\n");
                result.Append($"        END;\r\n");
                result.Append($"        THROW\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static StringBuilder GetScriptCommitTable(DataRow table, TDataRows columns)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Commit]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Commit]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Commit] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE[dbo].[{table["Alias"]}Commit](@LoginId BIGINT\r\n");
                result.Append($"                                             ,@UserName VARCHAR(25)\r\n");
                result.Append($"                                             ,@OperationId INT) AS BEGIN\r\n");
                result.Append($"    DECLARE @TranCount INT = @@TRANCOUNT\r\n");
                result.Append($"\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [{table["Alias"]}Commit]: '\r\n");
                result.Append($"               ,@TransactionId INT\r\n");
                result.Append($"               ,@TransactionIdAux INT\r\n");
                result.Append($"               ,@TableName VARCHAR(25)\r\n");
                result.Append($"               ,@Action VARCHAR(15)\r\n");
                result.Append($"               ,@CreatedBy VARCHAR(25)\r\n");
                result.Append($"               ,@LastRecord VARCHAR(max)\r\n");
                result.Append($"               ,@ActualRecord VARCHAR(max)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"\r\n");
                result.Append($"        BEGIN TRANSACTION\r\n");
                result.Append($"        SAVE TRANSACTION [SavePoint]");
                result.Append($"        IF @OperationId IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @OperationId requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        SELECT @TransactionIdAux = [TransactionId]\r\n");
                result.Append($"               ,@TableName = [TableName]\r\n");
                result.Append($"               ,@Action = [Action]\r\n");
                result.Append($"               ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"               ,@LastRecord = [LastRecord]\r\n");
                result.Append($"               ,@ActualRecord = [ActualRecord]\r\n");
                result.Append($"               ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [cruda].[Operations]\r\n");
                result.Append($"            WHERE [Id] = @OperationId\r\n");
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Operação inexistente';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @TableName <> '{table["Name"]}' BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @UserName <> @CreatedBy BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Operação inexistente';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        EXEC @TransactionId = [dbo].[{table["Alias"]}Validate] @LoginId, @UserName, @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        IF @TransactionId = 0\r\n");
                result.Append($"            GOTO EXIT_PROCEDURE\r\n");
                result.Append($"        IF @TransactionIdAux <> @TransactionId BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");

                var pkColumnRows = columnRows.FindAll(row => ToBoolean(row["IsPrimarykey"]));
                var firstTime = true;

                if (pkColumnRows.Count > 0)
                {
                    foreach (var column in pkColumnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"        DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"               ,@W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                    }
                    result.Append($"\r\n");
                    firstTime = true;
                    foreach (var column in pkColumnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"        IF @Action = 'delete'\r\n");
                            result.Append($"            DELETE FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                                                  AND [{column["Name"]}] = @W_{column["Name"]}\r\n");
                    }
                }

                var nonpkColumnRows = columnRows.FindAll(row => !ToBoolean(row["IsPrimarykey"]));

                firstTime = true;
                if (nonpkColumnRows.Count > 0)
                {
                    foreach (var column in nonpkColumnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"        ELSE BEGIN\r\n");
                            result.Append($"\r\n");
                            result.Append($"            DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                   ,@W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
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
                firstTime = true;
                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"                    WHERE [{column["Name"]}] = @W_{column["Name"]}\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                          AND [{column["Name"]}] = @W_{column["Name"]}\r\n");
                }
                result.Append($"        END\r\n");
                result.Append($"\r\n");
                result.Append($"        EXIT_PROCEDURE:\r\n");
                result.Append($"\r\n");
                result.Append($"        UPDATE [cruda].[Operations]\r\n");
                result.Append($"            SET [IsConfirmed] = 1\r\n");
                result.Append($"                ,[UpdatedAt] = GETDATE()\r\n");
                result.Append($"                ,[UpdatedBy] = @UserName\r\n");
                result.Append($"            WHERE [Id] = @OperationId\r\n");
                result.Append($"        COMMIT TRANSACTION\r\n");
                result.Append("\r\n");
                result.Append($"        RETURN 1\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        IF @@TRANCOUNT > @TranCount BEGIN\r\n");
                result.Append($"            ROLLBACK TRANSACTION [SavePoint];\r\n");
                result.Append($"            COMMIT TRANSACTION\r\n");
                result.Append($"        END;\r\n");
                result.Append($"        THROW\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
        private static StringBuilder GetScriptValidateTable(DataRow table, TDataRows tables, TDataRows columns, TDataRows domains, TDataRows types, TDataRows indexes, TDataRows indexkeys)
        {
            var result = new StringBuilder();
            var firstTime = true;
            var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Alias"]}Validate]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Alias"]}Validate]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Alias"]}Validate] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE[dbo].[{table["Alias"]}Validate](@LoginId BIGINT\r\n");
                result.Append($"                                               ,@UserName VARCHAR(25)\r\n");
                result.Append($"                                               ,@Action VARCHAR(15)\r\n");
                result.Append($"                                               ,@LastRecord VARCHAR(max)\r\n");
                result.Append($"                                               ,@ActualRecord VARCHAR(max)) AS BEGIN\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [{table["Alias"]}Validate]: '\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @LoginId IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @LoginId é requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @Action IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @Action é requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @Action NOT IN ('create', 'update', 'delete') BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @Action é inválido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @ActualRecord IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @ActualRecord é requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF ISJSON(@ActualRecord) = 0 BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @ActualRecord não está no formato JSON';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @Action <> 'create' BEGIN\r\n");
                result.Append($"            IF @LastRecord IS NULL BEGIN\r\n");
                result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Valor de @LastRecord é requerido';\r\n");
                result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"            END\r\n");
                result.Append($"            IF ISJSON(@LastRecord) = 0 BEGIN\r\n");
                result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Valor de @LastRecord não está no formato JSON';\r\n");
                result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"            END\r\n");
                foreach(var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            IF @Action = 'update'\r\n");
                        firstTime = false;
                    }
                    result.Append($"                AND [cruda].[IsEquals](CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]}), CAST(JSON_VALUE(@LastRecord, '$.{column["Name"]}') AS {column["#DataType"]})) = 1\r\n");
                }
                result.Append($"                RETURN 0\r\n");
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
                    if (ToBoolean(column["IsRequired"]))
                        result.Append($"[{column["Name"]}] = CAST(JSON_VALUE(@LastRecord, '$.{column["Name"]}') AS {column["#DataType"]})");
                    else
                        result.Append($"[cruda].[IsEquals]([{column["Name"]}], CAST(JSON_VALUE(@LastRecord, '$.{column["Name"]}') AS {column["#DataType"]})) = 1");
                }
                result.Append($") BEGIN\r\n");
                result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Registro de {table["Name"]} alterado por outro usuário';\r\n");
                result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"            END\r\n");
                result.Append($"        END\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @TransactionId INT\r\n");
                result.Append($"                ,@IsConfirmed BIT\r\n");
                result.Append($"                ,@CreatedBy VARCHAR(25)\r\n");
                result.Append($"\r\n");
                result.Append($"        SELECT @TransactionId = [Id]\r\n");
                result.Append($"               ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"               ,@CreatedBy = [CreatedBy]\r\n");
                result.Append($"            FROM [cruda].[Transactions]\r\n");
                result.Append($"            WHERE [Id] = (SELECT MAX([Id]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)\r\n");
                result.Append($"        IF @@ROWCOUNT = 0 BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Não existe transação para valor de @LoginId';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @UserName <> @CreatedBy BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");

                var pkColumnRows = columnRows.FindAll(column => ToBoolean(column["IsPrimarykey"]));

                firstTime = true;
                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"\r\n");
                        result.Append($"        DECLARE @W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"               ,W_{column["Name"]} AS {column["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                }
                result.Append($"\r\n");
                foreach (var column in pkColumnRows)
                {
                    var validations = GetValidations(column, domains, types);
                    var isRequired = validations.ContainsKey("IsRequired");

                    result.Append($"        IF @W_{column["Name"]} IS NULL BEGIN\r\n");
                    result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} em @ActualRecord é requerido.';\r\n");
                    result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                    result.Append($"        END\r\n");

                    if (validations.TryGetValue("Minimum", out dynamic? value))
                    {
                        result.Append($"        IF @W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]}) BEGIN\r\n");
                        result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} em @ActualRecord deve ser maior que ou igual à {value}';\r\n");
                        result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"        END\r\n");
                    }
                    if (validations.TryGetValue("Maximum", out value))
                    {
                        result.Append($"        IF @W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]}) BEGIN\r\n");
                        result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} em @ActualRecord deve ser menor que ou igual à {value}';\r\n");
                        result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"        END\r\n");
                    }
                }
                firstTime = true;
                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE {column["Name"]} = @W_{column["Name"]}");
                        firstTime = false;
                    }
                    else
                        result.Append($" AND {column["Name"]} = @W_{column["Name"]})");
                }
                
                var pkColumn = columnRows.First(col => ToLong(col["TableId"]) == ToLong(table["Id"]) && ToBoolean(col["IsPrimarykey"]));

                result.Append($") BEGIN\r\n");
                result.Append($"            IF @Action = 'create' BEGIN\r\n");
                result.Append($"               SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe em {table["Name"]}';\r\n");
                result.Append($"               THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"            END\r\n");
                result.Append($"        END ELSE IF @Action <> 'create' BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe em {table["Name"]}';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");

                var referenceRows = columnRows.FindAll(column => ToLong(column["ReferenceTableId"]) == ToLong(table["Id"]));

                if (referenceRows.Count > 0)
                {
                    result.Append($"    IF @Action = 'delete' BEGIN\r\n");
                    foreach (var reference in referenceRows)
                    {
                        result.Append($"            IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{reference["Name"]}] = @W_{pkColumnRows[0]["Name"]}) BEGIN\r\n");
                        result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Chave-primária referenciada em {table["Name"]}';\r\n");
                        result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"            END\r\n");
                    }
                    result.Append($"        END ELSE BEGIN\r\n");
                }
                else
                    result.Append($"        IF @Action <> 'delete' BEGIN\r\n");
                result.Append($"\r\n");

                var nopkColumnRows = columnRows.FindAll(column => !ToBoolean(column["IsPrimarykey"]));

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
                    var validations = GetValidations(column, domains, types);
                    var isRequired = validations.ContainsKey("IsRequired");

                    if (isRequired)
                    {
                        result.Append($"            IF @W_{column["Name"]} IS NULL BEGIN\r\n");
                        result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} em @ActualRecord é requerido.';\r\n");
                        result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"            END\r\n");
                    }
                    if (validations.TryGetValue("Minimum", out dynamic? value))
                    {
                        result.Append($"            IF {(isRequired ? "" : $"@W_{column["Name"]} IS NOT NULL AND ")}@W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]}) BEGIN\r\n");
                        result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} em @ActualRecord deve ser maior que ou igual à {value}';\r\n");
                        result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"            END\r\n");
                    }
                    if (validations.TryGetValue("Maximum", out value))
                    {
                        result.Append($"            IF {(isRequired ? "" : $"@W_{column["Name"]} IS NOT NULL AND ")}@W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]}) BEGIN\r\n");
                        result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} em @ActualRecord deve ser menor que ou igual à {value}';\r\n");
                        result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"            END\r\n");
                    }
                    if (!IsNull(column["ReferenceTableId"]))
                    {
                        var referenceTable = tables.First(table => ToLong(table["Id"]) == ToLong(column["ReferenceTableId"]));
                        
                        pkColumn = columns.First(col => ToLong(col["TableId"]) == ToLong(referenceTable["Id"]) && ToBoolean(col["IsPrimarykey"]));

                        result.Append($"            IF NOT EXISTS(SELECT 1 FROM [dbo].[{referenceTable["Name"]}] WHERE [{pkColumn["Name"]}] = @W_{column["Name"]}) BEGIN\r\n");
                        result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Valor de {pkColumn["Name"]} em @ActualRecord inexiste em {referenceTable["Name"]}';\r\n");
                        result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"            END\r\n");
                    }
                }

                var uniqueIndexRows = indexes.FindAll(index => ToLong(index["TableId"]) == ToLong(table["Id"]) && ToBoolean(index["IsUnique"]));

                if (uniqueIndexRows.Count > 0)
                {
                    result.Append($"            IF @Action = 'create' BEGIN\r\n");
                    foreach (var index in uniqueIndexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => ToLong(indexkey["IndexId"]) == ToLong(index["Id"]));

                        firstTime = true;
                        foreach (var indexkey in indexkeyRows)
                        {
                            var column = columns.First(column => ToLong(column["Id"]) == ToLong(indexkey["ColumnId"]));

                            if (firstTime)
                            {
                                result.Append($"                IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                firstTime = false;
                            }
                            else
                                result.Append($"                                                                  AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
                        result.Append($") BEGIN\r\n");
                        result.Append($"                    SET @ErrorMessage = @ErrorMessage + 'Chave única de {index["Name"]} já existe';\r\n");
                        result.Append($"                    THROW 51000, @ErrorMessage, 1\r\n");
                    }
                    result.Append($"                END\r\n");
                    foreach (var index in uniqueIndexRows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => ToLong(indexkey["IndexId"]) == ToLong(index["Id"]));
                        
                        firstTime = true;
                        foreach (var indexkey in indexkeyRows)
                        {
                            var column = columns.First(column => ToLong(column["Id"]) == ToLong(indexkey["ColumnId"]));

                            if (firstTime)
                            {
                                result.Append($"            END ELSE IF EXISTS(SELECT 1 FROM [dbo].[{table["Name"]}] WHERE [{column["Name"]}] = @W_{column["Name"]}");
                                firstTime = false;
                            }
                            else
                                result.Append($"                                                              AND [{column["Name"]}] = @W_{column["Name"]}");
                        }
                        pkColumn = columnRows.First(col => ToLong(col["TableId"]) == ToLong(table["Id"]) && ToBoolean(col["IsPrimarykey"]));
                        result.Append($" AND [{pkColumn["Name"]}] <> @W_{pkColumn["Name"]}) BEGIN\r\n");
                        result.Append($"                SET @ErrorMessage = @ErrorMessage + 'Chave única de {index["Name"]} inexiste';\r\n");
                        result.Append($"                THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"            END\r\n");
                    }
                }
                result.Append($"        END\r\n");
                result.Append($"\r\n");
                result.Append($"        RETURN @TransactionId\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        THROW\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }

        private static StringBuilder GetScriptReadTable(DataRow table, TDataRows columns, TDataRows domains, TDataRows types)
        {
            var result = new StringBuilder();
            var firstTime = true;
            var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]));

            if (columnRows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [dbo].[{table["Name"]}Read]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{table["Name"]}Read]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{table["Name"]}Read] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE[dbo].[{table["Name"]}Read](@LoginId BIGINT\r\n");
                result.Append($"                                          ,@Parameters VARCHAR(MAX)\r\n");
                result.Append($"                                          ,@PageNumber INT OUT\r\n");
                result.Append($"                                          ,@LimitRows BIGINT OUT\r\n");
                result.Append($"                                          ,@MaxPage INT OUT\r\n");
                result.Append($"                                          ,@PaddingBrowseLastPage BIT OUT) AS BEGIN\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [{table["Name"]}Read]: '\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @LoginId IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @LoginId é requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @Parameters IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @Parameters é requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF ISJSON(@Parameters) = 0 BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de @ActualRecord não está no formato JSON';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");

                var filterableColumns = columnRows.FindAll(column => ToBoolean(column["IsFilterable"]));

                result.Append($"        DECLARE @TransactionId INT = ISNULL((SELECT MAX([Id]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId), 0)\r\n");
                foreach (var column in filterableColumns)
                    result.Append($"                ,@W_{column["Name"]} {column["#DataType"]} = CAST(JSON_VALUE(@Parameters, '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                result.Append($"\r\n");
                foreach (var column in filterableColumns)
                {
                    var validations = GetValidations(column, domains, types);

                    if (validations.TryGetValue("Minimum", out dynamic? value))
                    {
                        result.Append($"        IF @W_{column["Name"]} IS NOT NULL AND @W_{column["Name"]} < CAST('{value}' AS {column["#DataType"]}) BEGIN\r\n");
                        result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} deve ser maior que ou igual à ''{value}''.';\r\n");
                        result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"        END\r\n");
                    }
                    if (validations.TryGetValue("Maximum", out value))
                    {
                        result.Append($"        IF @W_{column["Name"]} IS NOT NULL AND @W_{column["Name"]} > CAST('{value}' AS {column["#DataType"]}) BEGIN\r\n");
                        result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor de {column["Name"]} deve ser menor que ou igual à ''{value}''.';\r\n");
                        result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                        result.Append($"        END\r\n");
                    }
                }
                result.Append($"\r\n");
                result.Append($"        DECLARE @RowCount BIGINT\r\n");
                result.Append($"               ,@OffSet INT\r\n");
                result.Append($"\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT [{column["Name"]}]\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"              ,[{column["Name"]}]\r\n");
                }
                result.Append($"            INTO [dbo].[#tmp]\r\n");
                result.Append($"            FROM [dbo].[{table["Name"]}]\r\n");
                firstTime = true;
                foreach (var column in filterableColumns)
                {
                    if (firstTime)
                    {
                        result.Append($"            WHERE ");
                        if (ToBoolean(column["IsRequired"]))
                            result.Append($"[{column["Name"]}] = ISNULL(@W_{column["Name"]}, [{column["Name"]}])\r\n");
                        else
                            result.Append($"(@W_{column["Name"]} IS NULL OR [{column["Name"]}] = @W_{column["Name"]})\r\n");
                        firstTime = false;
                    }
                    else
                    {
                        result.Append($"                  AND ");
                        if (ToBoolean(column["IsRequired"]))
                            result.Append($"[{column["Name"]}] = ISNULL(@W_{column["Name"]}, [{column["Name"]}])\r\n");
                        else
                            result.Append($"(@W_{column["Name"]} IS NULL OR [{column["Name"]}] = @W_{column["Name"]})\r\n");
                    }
                }

                var pkColumnRows = columnRows.FindAll(column => ToBoolean(column["IsPrimarykey"]));

                firstTime = true;
                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            ORDER BY [{column["Name"]}]\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                    ,[{column["Name"]}]\r\n");
                }
                result.Append($"        SET @RowCount = @@ROWCOUNT\r\n");
                result.Append($"        DELETE [tmp]\r\n");
                result.Append($"            FROM [dbo].[#tmp]\r\n");
                result.Append($"            WHERE EXISTS(SELECT 1\r\n");
                result.Append($"                            FROM [cruda].[Operations] [ope]\r\n");
                result.Append($"                            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                                  AND [ope].[TableName] = 'Columns'\r\n");
                result.Append($"                                  AND [ope].[IsConfirmed] IS NULL\r\n");
                result.Append($"                                  AND [ope].[Action] = 'update'\r\n");
                foreach (var column in pkColumnRows)
                    result.Append($"                                  AND CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]}) = [tmp].[{column["Name"]}])\r\n");
                result.Append($"        SET @RowCount = @RowCount - @@ROWCOUNT\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        INSERT [dbo].[#tmp] SELECT CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                                  ,CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]}) AS [{column["Name"]}]\r\n");
                }
                result.Append($"            FROM [cruda].[Operations]\r\n");
                result.Append($"            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                  AND [TableName] = '{table["Name"]}'\r\n");
                result.Append($"                  AND [IsConfirmed] IS NULL\r\n");
                result.Append($"                  AND [Action] = 'create'\r\n");
                result.Append($"        SET @RowCount = @RowCount + @@ROWCOUNT\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        UPDATE [tmp]\r\n");
                        result.Append($"            SET [tmp].[{column["Name"]}] = CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"               ,[tmp].[{column["Name"]}] = CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]})\r\n");
                }
                result.Append($"            FROM [dbo].[#tmp] \r\n");
                result.Append($"            WHERE EXISTS(SELECT 1\r\n");
                result.Append($"                            FROM [cruda].[Operations] [ope]\r\n");
                result.Append($"                            WHERE [TransactionId] = @TransactionId\r\n");
                result.Append($"                                  AND [ope].[TableName] = 'Columns'\r\n");
                result.Append($"                                  AND [ope].[IsConfirmed] IS NULL\r\n");
                result.Append($"                                  AND [ope].[Action] = 'update'\r\n");
                foreach (var column in pkColumnRows)
                    result.Append($"                                  AND CAST(JSON_VALUE([ActualRecord], '$.{column["Name"]}') AS {column["#DataType"]}) = [tmp].[{column["Name"]}])\r\n");
                result.Append($"        IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN\r\n");
                result.Append($"            SET @offset = 0\r\n");
                result.Append($"            SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END\r\n");
                result.Append($"            SET @PageNumber = 1\r\n");
                result.Append($"            SET @MaxPage = 1\r\n");
                result.Append($"        END ELSE BEGIN\r\n");
                result.Append($"            SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END\r\n");
                result.Append($"            IF ABS(@PageNumber) > @MaxPage\r\n");
                result.Append($"                SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END\r\n");
                result.Append($"            IF @PageNumber < 0\r\n");
                result.Append($"                SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1\r\n");
                result.Append($"            SET @offset = (@PageNumber - 1) * @LimitRows\r\n");
                result.Append($"            IF @PaddingBrowseLastPage = 1 AND @offset + @LimitRows > @RowCount\r\n");
                result.Append($"                SET @offset = CASE WHEN @RowCount > @LimitRows THEN @RowCount -@LimitRows ELSE 0 END\r\n");
                result.Append($"        END\r\n");
                firstTime = true;
                foreach (var column in columnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"        SELECT 'Record{table["Alias"]}' AS [ClassName]\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"              ,[{column["Name"]}]\r\n");
                }
                result.Append($"            FROM [dbo].[#tmp] \r\n");
                firstTime = true;
                foreach (var column in pkColumnRows)
                {
                    if (firstTime)
                    {
                        result.Append($"            ORDER BY [{column["Name"]}]\r\n");
                        firstTime = false;
                    }
                    else
                        result.Append($"                    ,[{column["Name"]}]\r\n");
                }
                result.Append($"            OFFSET @offset ROWS\r\n");
                result.Append($"            FETCH NEXT @LimitRows ROWS ONLY\r\n");
                result.Append($"\r\n");
                result.Append($"        RETURN @RowCount\r\n");
                result.Append($"    END TRY\r\n");
                result.Append($"    BEGIN CATCH\r\n");
                result.Append($"        THROW\r\n");
                result.Append($"    END CATCH\r\n");
                result.Append($"END\r\n");
                result.Append($"GO\r\n");
            }

            return result;
        }
    }
}
