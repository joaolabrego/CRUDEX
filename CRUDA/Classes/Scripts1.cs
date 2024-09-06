using CRUDA_LIB;
using ExcelDataReader;
using System.Data;
using System.Text;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;
using TDataRows = System.Collections.Generic.List<System.Data.DataRow>;

namespace CRUDA.Classes
{
    public class Scripts1
    {
        static readonly string DirectoryScripts = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_SCRIPTS"));
        public static void GenerateScript(string systemName, string databaseName)
        {
            var dataSet = ExcelToDataSet();
            var columns = (dataSet.Tables["Columns"] ?? throw new Exception("Tabela Columns não existe.")).AsEnumerable().ToList();
            var indexes = (dataSet.Tables["Indexes"] ?? throw new Exception("Tabela Indexes não existe.")).AsEnumerable().ToList();
            var indexkeys = (dataSet.Tables["Indexkeys"] ?? throw new Exception("Tabela Indexkeys não existe.")).AsEnumerable().ToList();
            var domains = (dataSet.Tables["Domains"] ?? throw new Exception("Tabela Domains não existe.")).AsEnumerable().ToList();
            var categories = (dataSet.Tables["Categories"] ?? throw new Exception("Tabela Categories não existe.")).AsEnumerable().ToList();
            var types = (dataSet.Tables["Types"] ?? throw new Exception("Tabela Types não existe.")).AsEnumerable().ToList();
            var system = (dataSet.Tables["Systems"] ?? throw new Exception("Tabela Systems não existe.")).AsEnumerable().ToList().First(row => ToString(row["Name"]) == systemName);
            var database = (dataSet.Tables["Databases"] ?? throw new Exception("Tabela Databases não existe.")).AsEnumerable().ToList().First(row => ToString(row["Name"]) == databaseName);
            var databasesTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("Tabela DatabasesTables não existe.")).AsEnumerable().ToList().FindAll(row => ToLong(row["DatabaseId"]) == ToLong(database?["Id"]));
            var tables = (dataSet.Tables["Tables"] ?? throw new Exception("Tabela Tables não existe.")).AsEnumerable().ToList();
            var filename = Path.Combine(DirectoryScripts, $"SCRIPT-{systemName.ToUpper()}-{databaseName.ToUpper()}.sql");
            var firstTime = true;

            using var stream = new StreamWriter(path: filename, append: false, encoding: Encoding.UTF8);
            foreach (DataRow databaseTable in databasesTables)
            {
                var table = tables.First(table => ToLong(table["Id"]) == ToLong(databaseTable["TableId"]));
                if (firstTime)
                {
                    stream.Write(GetScriptDatabase(database));
                    stream.Write(GetScriptOthers(systemName == "cruda"));
                    GetScriptTableTransactions();
                    GetScriptTableOperations();
                    firstTime = false;
                }
                stream.Write(GetScriptTable(table, columns, indexes, indexkeys, domains, types));

                stream.Write(GetScriptRatify(table, columns, domains, types, categories, indexes, indexkeys));

            }
            stream.Write(GetScriptReferences(tables, columns));
            foreach (var table in tables)
            {
                var datatable = (dataSet.Tables[ToString(table["Name"])] ?? throw new Exception($"Tabela {table["Name"]} não encontrada")).AsEnumerable().ToList();

                stream.Write(GetScriptDml(table, columns, domains, types, categories, datatable));
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
        private static TDictionary GetValidations(DataRow type, DataRow domain, DataRow column)
        {
            var result = new TDictionary();
            string value;

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
        private static string GetScriptDatabase(DataRow database)
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
            result.Append($"DROP DATABASE {database["Alias"]}\r\n");
            result.Append($"GO\r\n");
            result.Append($"CREATE DATABASE [{database["Alias"]}]\r\n");
            result.Append($"CONTAINMENT = NONE\r\n");
            result.Append($"ON PRIMARY\r\n");
            result.Append($"(NAME = N'cruda', FILENAME = N'{filename}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)\r\n");
            result.Append($"LOG ON\r\n");
            result.Append($"(NAME = N'cruda_log', FILENAME = N'{filename}.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)\r\n");
            result.Append($"WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET COMPATIBILITY_LEVEL = 160\r\n");
            result.Append($"GO\r\n");
            result.Append($"IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))\r\n");
            result.Append($"BEGIN\r\n");
            result.Append($"EXEC[{database["Alias"]}].[dbo].[sp_fulltext_database] @action = 'enable'\r\n");
            result.Append($"END\r\n");
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
            result.Append($"ALTER DATABASE[{database["Alias"]}] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)\r\n");
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

            return result.ToString();
        }
        private static string GetScriptOthers(bool all)
        {
            var result = new StringBuilder();

            if (all)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [cruda].[Config]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.Config.sql")));
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [cruda].[GenerateId]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.GenerateId.sql")));
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [cruda].[Login]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.Login.sql")));
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar stored procedure [cruda].[GetPublicKey]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.GetPublicKey.sql")));
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar function [cruda].[NumberInWordsOfHundreds]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.NumberInWordsOfHundreds.sql")));
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar function [cruda].[NumberInWords]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append(File.ReadAllText(Path.Combine(DirectoryScripts, "cruda.NumberInWords.sql")));
            }
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

            return result.ToString();
        }
        private static string GetScriptTableTransactions()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar tabela [cruda].[Transactions]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"IF (SELECT object_id('[cruda].[Transactions]', 'U')) IS NOT NULL\r\n");
            result.Append($"    DROP TABLE [cruda].[Transactions]\r\n");
            result.Append($"CREATE TABLE [cruda].[Transactions]([Id] [bigint] NOT NULL\r\n");
            result.Append($"                                   ,[LoginId] [bigint] NOT NULL\r\n");
            result.Append($"                                   ,[IsConfirmed] [bit] NULL\r\n");
            result.Append($"                                   ,[CreatedAt] datetime NOT NULL\r\n");
            result.Append($"                                   ,[CreatedBy] varchar(25) NOT NULL\r\n");
            result.Append($"                                   ,[UpdatedAt] datetime NULL\r\n");
            result.Append($"                                   ,[UpdatedBy] varchar(25) NULL)\r\n");
            result.Append($"ALTER TABLE [cruda].[Transactions] ADD CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED([Id])");
            result.Append($"CREATE INDEX [IDX_Transactions_LoginId_IsConfirmed] ON [dbo].[Transactions]([LoginId], [IsConfirmed])");
            result.Append($"GO\r\n");

            return result.ToString();
        }
        private static string GetScriptTableOperations()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar tabela [cruda].[Operations]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"IF (SELECT object_id('[cruda].[Operations]', 'U')) IS NOT NULL\r\n");
            result.Append($"    DROP TABLE [cruda].[Operations]\r\n");
            result.Append($"CREATE TABLE [cruda].[Operations]([Id] [bigint] NOT NULL,\r\n");
            result.Append($"                                 ,[TransactionId] [bigint] NOT NULL\r\n");
            result.Append($"                                 ,[TableName] [varchar](25) NOT NULL\r\n");
            result.Append($"                                 ,[Action] [varchar](15) NOT NULL\r\n");
            result.Append($"                                 ,[LastRecord] [varchar](max) NULL\r\n");
            result.Append($"                                 ,[ActualRecord] [varchar](max) NOT NULL\r\n");
            result.Append($"                                 ,[IsConfirmed] [bit] NULL\r\n");
            result.Append($"                                 ,[CreatedAt] datetime NOT NULL\r\n");
            result.Append($"                                 ,[CreatedBy] varchar(25) NOT NULL\r\n");
            result.Append($"                                 ,[UpdatedAt] datetime NULL\r\n");
            result.Append($"                                 ,[UpdatedBy] varchar(25) NULL)\r\n");
            result.Append($"ALTER TABLE [cruda].[Operations] ADD CONSTRAINT PK_Operations PRIMARY KEY CLUSTERED([Id])");
            result.Append($"CREATE INDEX [IDX_Operations_TransactionId_TableName_Action_IsConfirmed] ON [dbo].[Operations]([TransactionId], [TableName], [Action], [IsConfirmed])");
            result.Append($"GO\r\n");

            return result.ToString();
        }
        private static string GetScriptTable(DataRow table, TDataRows columns, TDataRows indexes, TDataRows indexkeys, TDataRows domains, TDataRows types)
        {
            var result = new StringBuilder();
            var firstTime = true;
            var rows = columns.FindAll(column => ToLong(column["TableId"]) == ToLong(table["Id"]));

            if (rows.Count > 0)
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF (SELECT object_id('[dbo].[{table["Name"]}]', 'U')) IS NOT NULL\r\n");
                result.Append($"    DROP TABLE [dbo].[{table["Name"]}]\r\n");

                foreach (DataRow column in rows)
                {
                    var typeName = ToString(column["#DataType"]);
                    var definition = $"[{column["Name"]}] {typeName} {(ToBoolean(column["IsRequired"]) ? "NOT NULL" : "NULL")}";

                    if (firstTime)
                    {
                        result.Append($"\r\n");
                        result.Append($"CREATE TABLE [dbo].[{table["Name"]}]({definition}");
                        firstTime = false;
                    }
                    else
                    {
                        result.Append($"\r\n");
                        result.Append($"                                    ,{definition}");
                    }
                }
                result.Append($"\r\n");
                result.Append($"                                    ,[CreatedAt] datetime NOT NULL\r\n");
                result.Append($"                                    ,[CreatedBy] varchar(25) NOT NULL\r\n");
                result.Append($"                                    ,[UpdatedAt] datetime NULL\r\n");
                result.Append($"                                    ,[UpdatedBy] varchar(25) NULL)\r\n");
                firstTime = true;
                rows = columns.FindAll(column => ToLong(column["TableId"]) == ToLong(table["Id"]) && ToBoolean(column["IsPrimarykey"]));
                if (rows.Count > 0)
                {
                    foreach (DataRow column in rows)
                    {
                        if (firstTime)
                        {
                            result.Append($"ALTER TABLE [dbo].[{table["Name"]}] ADD CONSTRAINT PK_{table["Name"]} PRIMARY KEY CLUSTERED ([{column["Name"]}]");
                            firstTime = false;
                        }
                        else
                            result.Append($", [{column["Name"]}]");
                    }
                    result.Append($")\r\n");
                }
                rows = indexes.FindAll(index => ToLong(index["TableId"]) == ToLong(table["Id"]));
                if (rows.Count > 0)
                {
                    foreach (var index in rows)
                    {
                        var indexkeyRows = indexkeys.FindAll(indexkey => ToLong(indexkey["IndexId"]) == ToLong(index["Id"]));

                        if (indexkeyRows.Count > 0)
                        {
                            firstTime = true;
                            foreach (var indexkey in indexkeyRows)
                            {
                                var column = columns.First(column => ToLong(column["Id"]) == ToLong(indexkey["ColumnId"]));
                                var columnName = $"[{column["Name"]}] {(ToBoolean(indexkey["IsDescending"]) ? "DESC" : "ASC")}";

                                if (firstTime)
                                {
                                    result.Append($"CREATE {(ToBoolean(index["IsUnique"]) ? "UNIQUE" : "")} INDEX [{index["Name"]}] ON [dbo].[{table["Name"]}]({columnName}");
                                    firstTime = false;
                                }
                                else
                                    result.Append($"                                                                                                          ,{columnName}");
                            }
                            result.Append($")\r\n");
                        }
                    }
                    result.Append($"GO\r\n");
                }
            }

            return result.ToString();
        }
        private static string GetScriptReferences(TDataRows tables, TDataRows columns)
        {
            var result = new StringBuilder();
            var columnRows = columns.FindAll(column => !string.IsNullOrEmpty(column["ReferenceTableId"].ToString()));
            var lastTableName = string.Empty;

            if (columnRows.Count > 0)
            {
                foreach (var columnRow in columnRows)
                {
                    var primaryTable = tables.First(table => ToLong(table["Id"]) == ToLong(columnRow["TableId"]));
                    var referencedTable = tables.First(table => ToLong(table["Id"]) == ToLong(columnRow["ReferenceTableId"]));
                    var referencedPrimarykey = columns.First(column => ToLong(column["TableId"]) == ToLong(referencedTable["Id"]) && ToBoolean(column["IsPrimarykey"]));
                    var foreignKeyName = $"FK_{primaryTable["Name"]}_{referencedTable["Name"]}";

                    if (primaryTable["Name"].ToString() != lastTableName)
                    {
                        result.Append($"/**********************************************************************************\r\n");
                        result.Append($"Criar referências de [dbo].[{primaryTable["Name"]}]\r\n");
                        result.Append($"**********************************************************************************/\r\n");
                        lastTableName = primaryTable["Name"].ToString();
                    }
                    result.Append($"IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = '{foreignKeyName}')\r\n");
                    result.Append($"    ALTER TABLE [dbo].[{primaryTable["Name"]}] DROP CONSTRAINT {foreignKeyName}\r\n");
                    result.Append($"GO\r\n");
                    result.Append($"ALTER TABLE [dbo].[{primaryTable["Name"]}] WITH CHECK \r\n");
                    result.Append($"    ADD CONSTRAINT [{foreignKeyName}] \r\n");
                    result.Append($"    FOREIGN KEY([{columnRow["Name"]}]) \r\n");
                    result.Append($"    REFERENCES [dbo].[{referencedTable["Name"]}] ([{referencedPrimarykey["Name"]}])\r\n");
                    result.Append($"GO\r\n");
                    result.Append($"ALTER TABLE [dbo].[{primaryTable["Name"]}] CHECK CONSTRAINT [{foreignKeyName}]\r\n");
                    result.Append($"GO\r\n");
                }
            }

            return result.ToString();
        }
        private static string GetScriptDml(DataRow table, TDataRows columns, TDataRows domains, TDataRows types, TDataRows categories, TDataRows dataRows)
        {
            var result = new StringBuilder();

            if (dataRows.Count > 0)
            {
                var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]) && !ToBoolean(row["IsAutoIncrement"]));

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Inserir dados na tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                if (columnRows.Count > 0)
                {
                    foreach (var dataRow in dataRows)
                    {
                        var firstTime = true;

                        foreach (var columnRow in columnRows)
                        {
                            if (firstTime)
                            {
                                result.Append($"INSERT INTO [dbo].[{table["Name"]}] ([{columnRow["Name"]}]");
                                firstTime = false;
                            }
                            else
                            {
                                result.Append("\r\n");
                                result.Append($"                                ,[{columnRow["Name"]}]");
                            }
                        }
                        result.Append("\r\n");
                        result.Append($"                                ,[CreatedAt]\r\n");
                        result.Append($"                                ,[CreatedBy]\r\n");
                        result.Append($"                                ,[UpdatedAt]\r\n");
                        result.Append($"                                ,[UpdatedBy])\r\n");
                        firstTime = true;
                        foreach (var columnRow in columnRows)
                        {
                            var domain = domains.First(domain => ToLong(domain["Id"]) == ToLong(columnRow["DomainId"]));
                            var type = types.First(type => ToLong(type["Id"]) == ToLong(domain["TypeId"]));
                            var category = categories.First(category => ToLong(category["Id"]) == ToLong(type["CategoryId"]));
                            var categoryName = ToString(category["Name"]);
                            dynamic? value = dataRow[ToString(columnRow["Name"])];

                            if (categoryName == "numeric")
                                value ??= null;
                            else if (categoryName == "boolean")
                                value = IsNull(value) ? null : value ? 1 : 0;
                            if ((value = ToString(value)) == string.Empty)
                                value = "NULL";
                            else
                                value = $"CAST('{value}' AS {columnRow["#DataType"]})";
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

            return result.ToString();
        }
        private static string GetScriptRatify(DataRow table, TDataRows columns, TDataRows domains, TDataRows types, TDataRows categories, TDataRows indexes, TDataRows indexkeys)
        {
            var result = new StringBuilder();

            if (columns.Count > 0)
            {
                var columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]) && ToBoolean(row["IsPrimarykey"]));
                var firstTime = true;

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Ratificar dados na tabela [cruda].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[cruda].[{table["Name"]}Ratify]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [cruda].[{table["Name"]}Ratify] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE[cruda].[{table["Name"]}Ratify](@LoginId BIGINT\r\n");
                result.Append($"                                          ,@UserName VARCHAR(25)\r\n");
                result.Append($"                                          ,@OperationId BIGINT) AS BEGIN\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [{table["Name"]}Ratify]: '\r\n");
                result.Append($"               ,@TransactionId BIGINT\r\n");
                result.Append($"               ,@TransactionIdAux BIGINT\r\n");
                result.Append($"               ,@TableName VARCHAR(25)\r\n");
                result.Append($"               ,@Action VARCHAR(15)\r\n");
                result.Append($"               ,@LastRecord VARCHAR(MAX)\r\n");
                result.Append($"               ,@ActualRecord VARCHAR(MAX)\r\n");
                result.Append($"               ,@IsConfirmed BIT\r\n");
                result.Append($"               ,@ValidOk BIT\r\n");
                result.Append($"\r\n");
                result.Append($"        IF @@TRANCOUNT = 0\r\n");
                result.Append($"            BEGIN TRANSACTION [ColumnsRatify]\r\n");
                result.Append($"        ELSE\r\n");
                result.Append($"            SAVE TRANSACTION [ColumnsRatify]\r\n");
                result.Append($"        IF @LoginId IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @OperationId IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        SELECT @TransactionId = [TransactionId]\r\n");
                result.Append($"              ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [cruda].[Transactions]\r\n");
                result.Append($"            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)\r\n");
                result.Append($"        IF @TransactionId IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        SELECT @TransactionIdAux = [TransactionId]\r\n");
                result.Append($"              ,@TableName = [TableName]\r\n");
                result.Append($"              ,@Action = [Action]\r\n");
                result.Append($"              ,@LastRecord = [LastRecord]\r\n");
                result.Append($"              ,@ActualRecord = [ActualRecord]\r\n");
                result.Append($"              ,@IsConfirmed = [IsConfirmed]\r\n");
                result.Append($"            FROM [cruda].[Operations]\r\n");
                result.Append($"            WHERE [Id] = @OperationId\r\n");
                result.Append($"        IF @TransactionIdAux IS NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @TransactionIdAux <> @TransactionId BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @TableName <> '{table["Name"]}' BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        EXEC @ValidOk = [cruda].[{table["Name"]}Valid] @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        IF @ValidOk = 0\r\n");
                result.Append($"            RETURN 0\r\n");
                if (columnRows.Count > 0)
                {
                    foreach (var columnRow in columnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"\r\n");
                            result.Append($"        DECLARE @W_{columnRow["Name"]} {columnRow["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {columnRow["#DataType"]})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"               ,@W_{columnRow["Name"]} {columnRow["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {columnRow["#DataType"]})\r\n");
                    }
                    result.Append($"\r\n");
                    firstTime = true;
                    foreach (var columnRow in columnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"        IF @Action = 'delete'\r\n");
                            result.Append($"            DELETE FROM [dbo].[{table["Name"]}] WHERE [{columnRow["Name"]}] = @W_{columnRow["Name"]}\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                                                  AND [{columnRow["Name"]}] = @W_{columnRow["Name"]}\r\n");
                    }
                }
                firstTime = true;
                columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]) && !ToBoolean(row["IsPrimarykey"]) && !ToBoolean(row["IsAutoIncrement"]));
                if (columnRows.Count > 0)
                {
                    foreach (var columnRow in columnRows)
                    {
                        if (firstTime)
                        {
                            result.Append($"        ELSE BEGIN\r\n");
                            result.Append($"\r\n");
                            result.Append($"            DECLARE @W_{columnRow["Name"]} {columnRow["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {columnRow["#DataType"]})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                   ,@W_{columnRow["Name"]} {columnRow["#DataType"]} = CAST(JSON_VALUE(@ActualRecord, '$.{columnRow["Name"]}') AS {columnRow["#DataType"]})\r\n");
                    }
                    result.Append($"\r\n");
                }
                firstTime = true;
                columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]) && !ToBoolean(row["IsAutoIncrement"]));
                if (columnRows.Count > 0)
                {
                    foreach (var columnRow in columnRows)
                    {
                        var columnName = ToString(columnRow["Name"]);
                        var typeName = ToString(columnRow["#DataType"]);

                        if (firstTime)
                        {
                            result.Append($"            IF @Action = 'create'\r\n");
                            result.Append($"                INSERT INTO [dbo].[{table["Name"]}] ([{columnName}]");
                            firstTime = false;
                        }
                        else
                        {
                            result.Append($"\r\n");
                            result.Append($"                                                ,[{columnName}]");
                        }
                    }
                    result.Append($")\r\n");
                    firstTime = true;
                    foreach (var columnRow in columnRows)
                    {
                        var columnName = ToString(columnRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"                                          VALUES (@W_{columnName}");
                            firstTime = false;
                        }
                        else
                        {
                            result.Append("\r\n");
                            result.Append($"                                                 ,@W_{columnName}");
                        }
                    }
                    result.Append($")\r\n");
                    result.Append($"            ELSE\r\n");
                    firstTime = true;
                    foreach (var columnRow in columnRows)
                    {
                        var columnName = ToString(columnRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"                UPDATE [dbo].[{table["Name"]}] SET [{columnName}] = @W_{columnName}\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                                              ,[{columnName}] = @W_{columnName}\r\n");
                    }
                    firstTime = true;
                    columnRows = columns.FindAll(row => ToLong(row["TableId"]) == ToLong(table["Id"]) && ToBoolean(row["IsPrimarykey"]));
                    foreach (var columnRow in columnRows)
                    {
                        var columnName = ToString(columnRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"                    WHERE [{columnName}] = @W_{columnName}\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                          AND [{columnName}] = @W_{columnName}\r\n");
                    }
                    result.Append($"        END\r\n");
                    result.Append($"        UPDATE [cruda].[Operations]\r\n");
                    result.Append($"            SET [IsConfirmed] = 1\r\n");
                    result.Append($"                ,[UpdatedBy] = @UserName\r\n");
                    result.Append($"                ,[UpdatedAt] = GETDATE()\r\n");
                    result.Append($"            WHERE [Id] = @OperationId\r\n");
                    result.Append($"        COMMIT TRANSACTION [ColumnsRatify]\r\n");
                    result.Append("\r\n");
                    result.Append($"        RETURN 1\r\n");
                    result.Append($"    END TRY\r\n");
                    result.Append($"    BEGIN CATCH\r\n");
                    result.Append($"        ROLLBACK TRANSACTION [ColumnsRatify];\r\n");
                    result.Append($"        THROW\r\n");
                    result.Append($"    END CATCH\r\n");
                    result.Append($"END\r\n");
                    result.Append($"GO\r\n");
                }
            }

            return result.ToString();
        }
    }
}
