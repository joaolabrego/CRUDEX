using CRUDA.Classes.Models;
using CRUDA_LIB;
using ExcelDataReader;
using Microsoft.Extensions.Primitives;
using Newtonsoft.Json.Linq;
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
                var databasesTables = (dataSet.Tables["DatabasesTables"] ?? throw new Exception("Tabela DatabasesTables não existe.")).Select($"DatabaseId = {database["Id"]}");
                var tables = (dataSet.Tables["Tables"] ?? throw new Exception("Tabela Tables não existe.")).Select();
                var filename = Path.Combine(DirectoryScripts, $"SCRIPT-{systemName.ToUpper()}-{databaseName.ToUpper()}.sql");
                var firstTime = true;

                using var stream = new StreamWriter(path: filename, append: false, encoding: Encoding.UTF8);
                foreach (DataRow databaseTable in databasesTables)
                {
                    var table = tables.First(table => Convert.ToInt64(table["Id"]) == Convert.ToInt64(databaseTable["TableId"]));
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
                    var datatable = (dataSet.Tables[ToString(table["Name"])] ?? new DataTable()).Select();

                    stream.Write(GetScriptDml(table, columns, domains, types, categories, datatable));
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
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

            return Convert.ToBoolean(Convert.ToUInt16(value));
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
            string value;

            if (ToBoolean(column["IsRequired"]))
                result.Add("IsRequired", string.Empty);

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
            var name = database["Name"].ToString() ?? string.Empty;
            var alias = database["Alias"];
            var filename = Path.Combine(folder, name);

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar banco-de-dados {name}\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"USE [master]\r\n");
            result.Append($"SET NOCOUNT ON\r\n");
            result.Append($"IF EXISTS(SELECT 1 FROM sys.databases where name = '{alias}')\r\n");
            result.Append($"DROP DATABASE {alias}\r\n");
            result.Append($"GO\r\n");
            result.Append($"CREATE DATABASE [{alias}]\r\n");
            result.Append($"CONTAINMENT = NONE\r\n");
            result.Append($"ON PRIMARY\r\n");
            result.Append($"(NAME = N'cruda', FILENAME = N'{filename}.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)\r\n");
            result.Append($"LOG ON\r\n");
            result.Append($"(NAME = N'cruda_log', FILENAME = N'{filename}.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)\r\n");
            result.Append($"WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET COMPATIBILITY_LEVEL = 160\r\n");
            result.Append($"GO\r\n");
            result.Append($"IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))\r\n");
            result.Append($"BEGIN\r\n");
            result.Append($"EXEC[{alias}].[dbo].[sp_fulltext_database] @action = 'enable'\r\n");
            result.Append($"END\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ANSI_NULL_DEFAULT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ANSI_NULLS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ANSI_PADDING OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ANSI_WARNINGS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ARITHABORT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET AUTO_CLOSE OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET AUTO_SHRINK OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET AUTO_UPDATE_STATISTICS ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET CURSOR_CLOSE_ON_COMMIT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET CURSOR_DEFAULT  GLOBAL\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET CONCAT_NULL_YIELDS_NULL OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET NUMERIC_ROUNDABORT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET QUOTED_IDENTIFIER OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET RECURSIVE_TRIGGERS OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET  DISABLE_BROKER\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET AUTO_UPDATE_STATISTICS_ASYNC OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET DATE_CORRELATION_OPTIMIZATION OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET TRUSTWORTHY OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ALLOW_SNAPSHOT_ISOLATION ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET PARAMETERIZATION SIMPLE\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET READ_COMMITTED_SNAPSHOT OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET HONOR_BROKER_PRIORITY OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET RECOVERY SIMPLE\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET  MULTI_USER\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET PAGE_VERIFY CHECKSUM\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET DB_CHAINING OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF)\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET TARGET_RECOVERY_TIME = 60 SECONDS\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET DELAYED_DURABILITY = DISABLED\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET ACCELERATED_DATABASE_RECOVERY = OFF\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET QUERY_STORE = ON\r\n");
            result.Append($"GO\r\n");
            result.Append($"ALTER DATABASE[{alias}] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)\r\n");
            result.Append($"GO\r\n");
            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Início da criação dos scripts\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"USE [{alias}]\r\n");
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
            result.Append($"CREATE TABLE [cruda].[Transactions]([Id] [bigint] NOT NULL,\r\n");
            result.Append($"                                    [LoginId] [bigint] NOT NULL,\r\n");
            result.Append($"                                    [IsConfirmed] [bit] NULL,\r\n");
            result.Append($"    CONSTRAINT [PK_Transactions] PRIMARY KEY CLUSTERED([Id] ASC)\r\n");
            result.Append($"        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)\r\n");
            result.Append($"        ON [PRIMARY]) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]\r\n");
            result.Append($"GO\r\n");

            return result.ToString();
        }
        private static string GetScriptTableOperations()
        {
            var result = new StringBuilder();

            result.Append($"/**********************************************************************************\r\n");
            result.Append($"Criar tabela [cruda][Operations]\r\n");
            result.Append($"**********************************************************************************/\r\n");
            result.Append($"IF (SELECT object_id('[cruda].[Operations]', 'U')) IS NOT NULL\r\n");
            result.Append($"    DROP TABLE [cruda].[Operations]\r\n");
            result.Append($"CREATE TABLE [cruda].[Operations]([Id] [bigint] NOT NULL,\r\n");
            result.Append($"                                  [TransactionId] [bigint] NOT NULL,\r\n");
            result.Append($"                                  [TableName] [varchar](25) NOT NULL,\r\n");
            result.Append($"                                  [Action] [varchar](15) NOT NULL,\r\n");
            result.Append($"                                  [LastRecord] [varchar](max) NULL,\r\n");
            result.Append($"                                  [ActualRecord] [varchar](max) NOT NULL,\r\n");
            result.Append($"                                  [IsConfirmed] [bit] NULL,\r\n");
            result.Append($"    CONSTRAINT [PK_Operations] PRIMARY KEY CLUSTERED([Id] ASC)\r\n");
            result.Append($"        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)\r\n");
            result.Append($"        ON [PRIMARY]) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]\r\n");
            result.Append($"GO\r\n");

            return result.ToString();
        }
        private static string GetScriptTable(DataRow table, DataRow[] columns, DataRow[] indexes, DataRow[] indexkeys, DataRow[] domains, DataRow[] types)
        {
            var result = new StringBuilder();
            var firstTime = true;
            var rows = columns.Where(column => Convert.ToInt64(column["TableId"]) == Convert.ToInt64(table["Id"]));

            if (rows.Any())
            {
                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Criar tabela [dbo].[{table["Name"]}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF (SELECT object_id('[dbo].[{table["Name"]}]', 'U')) IS NOT NULL\r\n");
                result.Append($"    DROP TABLE [dbo].[{table["Name"]}]\r\n");

                foreach (DataRow column in rows)
                {
                    var domain = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(column["DomainId"]));
                    var type = types.First(t => Convert.ToInt64(t["Id"]) == Convert.ToInt64(domain["TypeId"]));
                    var typeName = GetDataType(type, domain);
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
                rows = columns.Where(column => Convert.ToInt64(column["TableId"]) == Convert.ToInt64(table["Id"]) && ToBoolean(column["IsPrimarykey"]));
                if (rows.Any())
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
                rows = indexes.Where(index => Convert.ToInt64(index["TableId"]) == Convert.ToInt64(table["Id"]));
                if (rows.Any())
                {
                    foreach (var index in rows)
                    {
                        var indexkeyRows = indexkeys.Where(indexkey => Convert.ToInt64(indexkey["IndexId"]) == Convert.ToInt64(index["Id"]));

                        if (indexkeyRows.Any())
                        {
                            firstTime = true;
                            foreach (var indexkey in indexkeyRows)
                            {
                                var column = columns.First(column => Convert.ToInt64(column["Id"]) == Convert.ToInt64(indexkey["ColumnId"]));
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
        private static string GetScriptReferences(DataRow[] tables, DataRow[] columns)
        {
            var result = new StringBuilder();
            var columnRows = columns.Where(column => column["ReferenceTableId"].ToString() != string.Empty);
            var lastTableName = string.Empty;

            if (columnRows.Any())
            {
                foreach (var columnRow in columnRows)
                {
                    var primaryTable = tables.First(table => Convert.ToInt64(table["Id"]) == Convert.ToInt64(columnRow["TableId"]));
                    var referencedTable = tables.First(table => Convert.ToInt64(table["Id"]) == Convert.ToInt64(columnRow["ReferenceTableId"]));
                    var referencedPrimarykey = columns.First(column => Convert.ToInt64(column["TableId"]) == Convert.ToInt64(referencedTable["Id"]) && ToBoolean(column["IsPrimarykey"]));
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
        private static string GetScriptDml(DataRow table, DataRow[] columns, DataRow[] domains, DataRow[] types, DataRow[] categories, DataRow[] dataRows)
        {
            var result = new StringBuilder();

            if (dataRows.Length > 0)
            {
                var tableId = Convert.ToInt64(table["Id"]);
                var tableName = ToString(table["Name"]);
                var columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == tableId && !ToBoolean(row["IsAutoIncrement"]));

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Inserir dados na tabela [dbo].[{tableName}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                if (columnRows.Any())
                {
                    foreach (var dataRow in dataRows)
                    {
                        var firstTime = true;

                        foreach (var columnRow in columnRows)
                        {
                            var columnName = ToString(columnRow["Name"]);

                            if (firstTime)
                            {
                                result.Append($"INSERT INTO [dbo].[{tableName}] ([{columnName}]");
                                firstTime = false;
                            }
                            else
                            {
                                result.Append("\r\n");
                                result.Append($"                                ,[{columnName}]");
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
                            var domain = domains.First(domain => Convert.ToInt64(domain["Id"]) == Convert.ToInt64(columnRow["DomainId"]));
                            var type = types.First(type => Convert.ToInt64(type["Id"]) == Convert.ToInt64(domain["TypeId"]));
                            var category = categories.First(category => Convert.ToInt64(category["Id"]) == Convert.ToInt64(type["CategoryId"]));
                            var typeName = ToString(type["Name"]);
                            var categoryName = ToString(category["Name"]);
                            var columnName = ToString(columnRow["Name"]);
                            dynamic? value = dataRow[ToString(columnRow["Name"])];

                            if (categoryName == "numeric")
                                value ??= null;
                            else if (categoryName == "boolean")
                                value = value == null ? null : value ? 1 : 0;
                            if ((value = ToString(value)) == string.Empty)
                                value = "NULL";
                            else
                                value = $"CAST('{value}' AS {GetDataType(type, domain)})";
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
        private static string GetScriptRatify(DataRow table, DataRow[] columns, DataRow[] domains, DataRow[] types, DataRow[] categories, DataRow[] indexes, DataRow[] indexkeys)
        {
            var result = new StringBuilder();

            if (columns.Length > 0)
            {
                var tableId = Convert.ToInt64(table["Id"]);
                var tableName = ToString(table["Name"]);
                var columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == tableId && ToBoolean(row["IsPrimarykey"]));
                var firstTime = true;

                result.Append($"/**********************************************************************************\r\n");
                result.Append($"Ratificar dados na tabela [dbo].[{tableName}]\r\n");
                result.Append($"**********************************************************************************/\r\n");
                result.Append($"IF(SELECT object_id('[dbo].[{tableName}Ratify]', 'P')) IS NULL\r\n");
                result.Append($"    EXEC('CREATE PROCEDURE [dbo].[{tableName}Ratify] AS PRINT 1')\r\n");
                result.Append($"GO\r\n");
                result.Append($"ALTER PROCEDURE[dbo].[{tableName}Ratify](@LoginId BIGINT\r\n");
                result.Append($"                                    ,@UserName VARCHAR(25)\r\n");
                result.Append($"                                    ,@OperationId BIGINT) AS BEGIN\r\n");
                result.Append($"    BEGIN TRY\r\n");
                result.Append($"        SET NOCOUNT ON\r\n");
                result.Append($"        SET TRANSACTION ISOLATION LEVEL READ COMMITTED\r\n");
                result.Append($"\r\n");
                result.Append($"        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '\r\n");
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
                result.Append($"        IF @TableName <> '{tableName}' BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        IF @IsConfirmed IS NOT NULL BEGIN\r\n");
                result.Append($"            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;\r\n");
                result.Append($"            THROW 51000, @ErrorMessage, 1\r\n");
                result.Append($"        END\r\n");
                result.Append($"        EXEC @ValidOk = [dbo].[{tableName}Valid] @Action, @LastRecord, @ActualRecord\r\n");
                result.Append($"        IF @ValidOk = 0\r\n");
                result.Append($"            RETURN 0\r\n");
                if (columnRows.Any())
                {
                    foreach (var columnRow in columnRows)
                    {
                        var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"])) ?? throw new Exception("Domínio não encontrado");
                        var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"])) ?? throw new Exception("Tipo não encontrado");
                        var columnName = ToString(columnRow["Name"]);
                        var typeName = ToString(typeRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"\r\n");
                            result.Append($"        DECLARE @W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"               ,@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})\r\n");
                    }
                    result.Append($"\r\n");
                    firstTime = true;
                    foreach (var columnRow in columnRows)
                    {
                        var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"])) ?? throw new Exception("Domínio não encontrado");
                        var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"])) ?? throw new Exception("Tipo não encontrado");
                        var columnName = ToString(columnRow["Name"]);
                        var typeName = ToString(typeRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"        IF @Action = 'delete'\r\n");
                            result.Append($"            DELETE FROM [dbo].[{tableName}] WHERE [{columnName}] = @W_{columnName}\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                                                  AND [{columnName}] = @W_{columnName}\r\n");
                    }
                }
                firstTime = true;
                columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == tableId && !ToBoolean(row["IsPrimarykey"]) && !ToBoolean(row["IsAutoIncrement"]));
                if (columnRows.Any())
                {
                    foreach (var columnRow in columnRows)
                    {
                        var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"])) ?? throw new Exception("Domínio não encontrado");
                        var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"])) ?? throw new Exception("Tipo não encontrado");
                        var columnName = ToString(columnRow["Name"]);
                        var typeName = ToString(typeRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"        ELSE BEGIN\r\n");
                            result.Append($"\r\n");
                            result.Append($"            DECLARE @W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                   ,@W_{columnName} {typeName} = CAST(JSON_VALUE(@ActualRecord, '$.{columnName}') AS {typeName})\r\n");
                    }
                    result.Append($"\r\n");
                }
                firstTime = true;
                columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == tableId && !ToBoolean(row["IsAutoIncrement"]));
                if (columnRows.Any())
                {
                    foreach (var columnRow in columnRows)
                    {
                        var domainRow = domains.First(d => Convert.ToInt64(d["Id"]) == Convert.ToInt64(columnRow["DomainId"])) ?? throw new Exception("Domínio não encontrado");
                        var typeRow = types.First(t => Convert.ToByte(t["Id"]) == Convert.ToByte(domainRow["TypeId"])) ?? throw new Exception("Tipo não encontrado");
                        var columnName = ToString(columnRow["Name"]);
                        var typeName = ToString(typeRow["Name"]);

                        if (firstTime)
                        {
                            result.Append($"            IF @Action = 'create'\r\n");
                            result.Append($"                INSERT INTO [dbo].[{tableName}] ([{columnName}]");
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
                            result.Append($"                UPDATE [dbo].[{tableName}] SET [{columnName}] = @W_{columnName}\r\n");
                            firstTime = false;
                        }
                        else
                            result.Append($"                                              ,[{columnName}] = @W_{columnName}\r\n");
                    }
                    firstTime = true;
                    columnRows = columns.Where(row => Convert.ToInt64(row["TableId"]) == tableId && ToBoolean(row["IsPrimarykey"]));
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
