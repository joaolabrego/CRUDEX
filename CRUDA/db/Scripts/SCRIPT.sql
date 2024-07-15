/**********************************************************************************
Criar banco-de-dados cruda
**********************************************************************************/
USE [master]
SET NOCOUNT ON
IF EXISTS(SELECT 1 FROM sys.databases where name = 'cruda')
DROP DATABASE cruda
GO
CREATE DATABASE [cruda]
CONTAINMENT = NONE
ON PRIMARY
(NAME = N'cruda', FILENAME = N'D:\CRUDA-C#\CRUDA-CORE\CRUDA\db\cruda.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)
LOG ON
(NAME = N'cruda_log', FILENAME = N'D:\CRUDA-C#\CRUDA-CORE\CRUDA\db\cruda_log.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)
WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE[cruda] SET COMPATIBILITY_LEVEL = 160
GO
IF(1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
BEGIN
EXEC[cruda].[dbo].[sp_fulltext_database] @action = 'enable'
END
GO
ALTER DATABASE[cruda] SET ANSI_NULL_DEFAULT OFF
GO
ALTER DATABASE[cruda] SET ANSI_NULLS OFF
GO
ALTER DATABASE[cruda] SET ANSI_PADDING OFF
GO
ALTER DATABASE[cruda] SET ANSI_WARNINGS OFF
GO
ALTER DATABASE[cruda] SET ARITHABORT OFF
GO
ALTER DATABASE[cruda] SET AUTO_CLOSE OFF
GO
ALTER DATABASE[cruda] SET AUTO_SHRINK OFF
GO
ALTER DATABASE[cruda] SET AUTO_UPDATE_STATISTICS ON
GO
ALTER DATABASE[cruda] SET CURSOR_CLOSE_ON_COMMIT OFF
GO
ALTER DATABASE[cruda] SET CURSOR_DEFAULT  GLOBAL
GO
ALTER DATABASE[cruda] SET CONCAT_NULL_YIELDS_NULL OFF
GO
ALTER DATABASE[cruda] SET NUMERIC_ROUNDABORT OFF
GO
ALTER DATABASE[cruda] SET QUOTED_IDENTIFIER OFF
GO
ALTER DATABASE[cruda] SET RECURSIVE_TRIGGERS OFF
GO
ALTER DATABASE[cruda] SET  DISABLE_BROKER
GO
ALTER DATABASE[cruda] SET AUTO_UPDATE_STATISTICS_ASYNC OFF
GO
ALTER DATABASE[cruda] SET DATE_CORRELATION_OPTIMIZATION OFF
GO
ALTER DATABASE[cruda] SET TRUSTWORTHY OFF
GO
ALTER DATABASE[cruda] SET ALLOW_SNAPSHOT_ISOLATION ON
GO
ALTER DATABASE[cruda] SET PARAMETERIZATION SIMPLE
GO
ALTER DATABASE[cruda] SET READ_COMMITTED_SNAPSHOT OFF
GO
ALTER DATABASE[cruda] SET HONOR_BROKER_PRIORITY OFF
GO
ALTER DATABASE[cruda] SET RECOVERY SIMPLE
GO
ALTER DATABASE[cruda] SET  MULTI_USER
GO
ALTER DATABASE[cruda] SET PAGE_VERIFY CHECKSUM
GO
ALTER DATABASE[cruda] SET DB_CHAINING OFF
GO
ALTER DATABASE[cruda] SET FILESTREAM(NON_TRANSACTED_ACCESS = OFF)
GO
ALTER DATABASE[cruda] SET TARGET_RECOVERY_TIME = 60 SECONDS
GO
ALTER DATABASE[cruda] SET DELAYED_DURABILITY = DISABLED
GO
ALTER DATABASE[cruda] SET ACCELERATED_DATABASE_RECOVERY = OFF
GO
ALTER DATABASE[cruda] SET QUERY_STORE = ON
GO
ALTER DATABASE[cruda] SET QUERY_STORE(OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/**********************************************************************************
Início da criação dos scripts
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/**********************************************************************************
Criar tabela Categories
**********************************************************************************/
IF (SELECT object_id('[dbo].[Categories]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Categories]
CREATE TABLE [dbo].[Categories](
[Id] tinyint NOT NULL,
[Name] varchar(25) NOT NULL,
[HtmlInputType] varchar(10) NULL,
[HtmlInputAlign] varchar(6) NULL,
[AskEncrypted] bit NOT NULL,
[AskMask] bit NOT NULL,
[AskListable] bit NOT NULL,
[AskDefault] bit NOT NULL,
[AskMinimum] bit NOT NULL,
[AskMaximum] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Categories] ADD CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Categories_Name] ON [dbo].[Categories]([Name] ASC)
GO
/**********************************************************************************
Criar procedure CategoriesRead
**********************************************************************************/
IF(SELECT object_id('CategoriesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[CategoriesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure CategoriesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id tinyint = CAST(JSON_VALUE(@Record, '$.Id') AS tinyint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_AskEncrypted bit = CAST(JSON_VALUE(@Record, '$.AskEncrypted') AS bit),
@W_AskMask bit = CAST(JSON_VALUE(@Record, '$.AskMask') AS bit),
@W_AskListable bit = CAST(JSON_VALUE(@Record, '$.AskListable') AS bit),
@W_AskDefault bit = CAST(JSON_VALUE(@Record, '$.AskDefault') AS bit),
@W_AskMinimum bit = CAST(JSON_VALUE(@Record, '$.AskMinimum') AS bit),
@W_AskMaximum bit = CAST(JSON_VALUE(@Record, '$.AskMaximum') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Categories', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS tinyint) AS [Id]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.HtmlInputType') AS varchar(10)) AS [HtmlInputType]
,CAST(JSON_VALUE([Record], '$.HtmlInputAlign') AS varchar(6)) AS [HtmlInputAlign]
,CAST(JSON_VALUE([Record], '$.AskEncrypted') AS bit) AS [AskEncrypted]
,CAST(JSON_VALUE([Record], '$.AskMask') AS bit) AS [AskMask]
,CAST(JSON_VALUE([Record], '$.AskListable') AS bit) AS [AskListable]
,CAST(JSON_VALUE([Record], '$.AskDefault') AS bit) AS [AskDefault]
,CAST(JSON_VALUE([Record], '$.AskMinimum') AS bit) AS [AskMinimum]
,CAST(JSON_VALUE([Record], '$.AskMaximum') AS bit) AS [AskMaximum]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[Name]
,[tab].[HtmlInputType]
,[tab].[HtmlInputAlign]
,[tab].[AskEncrypted]
,[tab].[AskMask]
,[tab].[AskListable]
,[tab].[AskDefault]
,[tab].[AskMinimum]
,[tab].[AskMaximum]
INTO[dbo].[#tab]
FROM[dbo].[Categories] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[AskEncrypted] = ISNULL(@W_AskEncrypted, [tab].[AskEncrypted])
AND [tab].[AskMask] = ISNULL(@W_AskMask, [tab].[AskMask])
AND [tab].[AskListable] = ISNULL(@W_AskListable, [tab].[AskListable])
AND [tab].[AskDefault] = ISNULL(@W_AskDefault, [tab].[AskDefault])
AND [tab].[AskMinimum] = ISNULL(@W_AskMinimum, [tab].[AskMinimum])
AND [tab].[AskMaximum] = ISNULL(@W_AskMaximum, [tab].[AskMaximum])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[Name]
,[HtmlInputType]
,[HtmlInputAlign]
,[AskEncrypted]
,[AskMask]
,[AskListable]
,[AskDefault]
,[AskMinimum]
,[AskMaximum]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[Name] = [tmp].[Name]
,[tab].[HtmlInputType] = [tmp].[HtmlInputType]
,[tab].[HtmlInputAlign] = [tmp].[HtmlInputAlign]
,[tab].[AskEncrypted] = [tmp].[AskEncrypted]
,[tab].[AskMask] = [tmp].[AskMask]
,[tab].[AskListable] = [tmp].[AskListable]
,[tab].[AskDefault] = [tmp].[AskDefault]
,[tab].[AskMinimum] = [tmp].[AskMinimum]
,[tab].[AskMaximum] = [tmp].[AskMaximum]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordCategory' AS [ClassName],
[tab].[Id]
,[tab].[Name]
,[tab].[HtmlInputType]
,[tab].[HtmlInputAlign]
,[tab].[AskEncrypted]
,[tab].[AskMask]
,[tab].[AskListable]
,[tab].[AskDefault]
,[tab].[AskMinimum]
,[tab].[AskMaximum]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Categories
**********************************************************************************/
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'1', 
'string', 
'text', 
'left', 
'1', 
'1', 
'1', 
'1', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'2', 
'numeric', 
'text', 
'right', 
'0', 
'1', 
'0', 
'1', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'3', 
'date', 
'text', 
'right', 
'0', 
'1', 
'0', 
'1', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'4', 
'datetime', 
'text', 
'right', 
'0', 
'1', 
'0', 
'1', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'5', 
'boolean', 
'checkbox', 
'center', 
'0', 
'0', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'6', 
'time', 
'text', 
'right', 
'0', 
'1', 
'0', 
'1', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'7', 
'text', 
'textarea', 
'left', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'8', 
'image', 
'image', 
'left', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'9', 
'binary', 
'file', 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Categories] (
[Id], 
[Name], 
[HtmlInputType], 
[HtmlInputAlign], 
[AskEncrypted], 
[AskMask], 
[AskListable], 
[AskDefault], 
[AskMinimum], 
[AskMaximum], 
CreatedAt, CreatedBy) VALUES (
'10', 
'undefined', 
'textarea', 
'left', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Categories
**********************************************************************************/
/**********************************************************************************
Criar tabela Types
**********************************************************************************/
IF (SELECT object_id('[dbo].[Types]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Types]
CREATE TABLE [dbo].[Types](
[Id] tinyint NOT NULL,
[CategoryId] tinyint NOT NULL,
[Name] varchar(25) NOT NULL,
[Minimum] sql_variant NULL,
[Maximum] sql_variant NULL,
[AskLength] bit NOT NULL,
[AskDecimals] bit NOT NULL,
[AskPrimarykey] bit NOT NULL,
[AskAutoincrement] bit NOT NULL,
[AskFilterable] bit NOT NULL,
[AskBrowseable] bit NOT NULL,
[AskCodification] bit NOT NULL,
[AskFormula] bit NOT NULL,
[AllowMaxLength] bit NOT NULL,
[IsActive] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Types] ADD CONSTRAINT PK_Types PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Types_Name] ON [dbo].[Types]([Name] ASC)
GO
/**********************************************************************************
Criar procedure TypesCreate
**********************************************************************************/
IF(SELECT object_id('TypesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TypesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure TypesCreate: ',
@W_Id tinyint = CAST(JSON_VALUE(@Record, '$.Id') AS tinyint),
@W_CategoryId tinyint = CAST(JSON_VALUE(@Record, '$.CategoryId') AS tinyint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Minimum sql_variant = CAST(JSON_VALUE(@Record, '$.Minimum') AS sql_variant),
@W_Maximum sql_variant = CAST(JSON_VALUE(@Record, '$.Maximum') AS sql_variant),
@W_AskLength bit = CAST(JSON_VALUE(@Record, '$.AskLength') AS bit),
@W_AskDecimals bit = CAST(JSON_VALUE(@Record, '$.AskDecimals') AS bit),
@W_AskPrimarykey bit = CAST(JSON_VALUE(@Record, '$.AskPrimarykey') AS bit),
@W_AskAutoincrement bit = CAST(JSON_VALUE(@Record, '$.AskAutoincrement') AS bit),
@W_AskFilterable bit = CAST(JSON_VALUE(@Record, '$.AskFilterable') AS bit),
@W_AskBrowseable bit = CAST(JSON_VALUE(@Record, '$.AskBrowseable') AS bit),
@W_AskCodification bit = CAST(JSON_VALUE(@Record, '$.AskCodification') AS bit),
@W_AskFormula bit = CAST(JSON_VALUE(@Record, '$.AskFormula') AS bit),
@W_AllowMaxLength bit = CAST(JSON_VALUE(@Record, '$.AllowMaxLength') AS bit),
@W_IsActive bit = CAST(JSON_VALUE(@Record, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_CategoryId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @CategoryId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @CategoryId deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @CategoryId deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDecimals IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskDecimals é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskPrimarykey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskPrimarykey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskAutoincrement IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskAutoincrement é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFilterable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskFilterable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskBrowseable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskBrowseable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskCodification IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskCodification é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFormula IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskFormula é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AllowMaxLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AllowMaxLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Types.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Types_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Types] (
[Id],
[CategoryId],
[Name],
[Minimum],
[Maximum],
[AskLength],
[AskDecimals],
[AskPrimarykey],
[AskAutoincrement],
[AskFilterable],
[AskBrowseable],
[AskCodification],
[AskFormula],
[AllowMaxLength],
[IsActive],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_CategoryId,
@W_Name,
@W_Minimum,
@W_Maximum,
@W_AskLength,
@W_AskDecimals,
@W_AskPrimarykey,
@W_AskAutoincrement,
@W_AskFilterable,
@W_AskBrowseable,
@W_AskCodification,
@W_AskFormula,
@W_AllowMaxLength,
@W_IsActive,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure TypesUpdate
**********************************************************************************/
IF(SELECT object_id('TypesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TypesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@Record, '$.Id') AS tinyint),
@W_CategoryId tinyint = CAST(JSON_VALUE(@Record, '$.CategoryId') AS tinyint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Minimum sql_variant = CAST(JSON_VALUE(@Record, '$.Minimum') AS sql_variant),
@W_Maximum sql_variant = CAST(JSON_VALUE(@Record, '$.Maximum') AS sql_variant),
@W_AskLength bit = CAST(JSON_VALUE(@Record, '$.AskLength') AS bit),
@W_AskDecimals bit = CAST(JSON_VALUE(@Record, '$.AskDecimals') AS bit),
@W_AskPrimarykey bit = CAST(JSON_VALUE(@Record, '$.AskPrimarykey') AS bit),
@W_AskAutoincrement bit = CAST(JSON_VALUE(@Record, '$.AskAutoincrement') AS bit),
@W_AskFilterable bit = CAST(JSON_VALUE(@Record, '$.AskFilterable') AS bit),
@W_AskBrowseable bit = CAST(JSON_VALUE(@Record, '$.AskBrowseable') AS bit),
@W_AskCodification bit = CAST(JSON_VALUE(@Record, '$.AskCodification') AS bit),
@W_AskFormula bit = CAST(JSON_VALUE(@Record, '$.AskFormula') AS bit),
@W_AllowMaxLength bit = CAST(JSON_VALUE(@Record, '$.AllowMaxLength') AS bit),
@W_IsActive bit = CAST(JSON_VALUE(@Record, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_CategoryId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @CategoryId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @CategoryId deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @CategoryId deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDecimals IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskDecimals é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskPrimarykey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskPrimarykey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskAutoincrement IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskAutoincrement é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFilterable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskFilterable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskBrowseable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskBrowseable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskCodification IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskCodification é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFormula IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AskFormula é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AllowMaxLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @AllowMaxLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Types.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Types_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Types] SET
[CategoryId] = @W_CategoryId,
[Name] = @W_Name,
[Minimum] = @W_Minimum,
[Maximum] = @W_Maximum,
[AskLength] = @W_AskLength,
[AskDecimals] = @W_AskDecimals,
[AskPrimarykey] = @W_AskPrimarykey,
[AskAutoincrement] = @W_AskAutoincrement,
[AskFilterable] = @W_AskFilterable,
[AskBrowseable] = @W_AskBrowseable,
[AskCodification] = @W_AskCodification,
[AskFormula] = @W_AskFormula,
[AllowMaxLength] = @W_AllowMaxLength,
[IsActive] = @W_IsActive,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure TypesDelete
**********************************************************************************/
IF(SELECT object_id('TypesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TypesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure TypesDelete: ',
@W_Id tinyint = CAST(JSON_VALUE(@Record, '$.Id') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Types.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Types]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure TypesRead
**********************************************************************************/
IF(SELECT object_id('TypesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TypesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure TypesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id tinyint = CAST(JSON_VALUE(@Record, '$.Id') AS tinyint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_AskLength bit = CAST(JSON_VALUE(@Record, '$.AskLength') AS bit),
@W_AskDecimals bit = CAST(JSON_VALUE(@Record, '$.AskDecimals') AS bit),
@W_AskPrimarykey bit = CAST(JSON_VALUE(@Record, '$.AskPrimarykey') AS bit),
@W_AskAutoincrement bit = CAST(JSON_VALUE(@Record, '$.AskAutoincrement') AS bit),
@W_AskFilterable bit = CAST(JSON_VALUE(@Record, '$.AskFilterable') AS bit),
@W_AskBrowseable bit = CAST(JSON_VALUE(@Record, '$.AskBrowseable') AS bit),
@W_AskCodification bit = CAST(JSON_VALUE(@Record, '$.AskCodification') AS bit),
@W_AskFormula bit = CAST(JSON_VALUE(@Record, '$.AskFormula') AS bit),
@W_AllowMaxLength bit = CAST(JSON_VALUE(@Record, '$.AllowMaxLength') AS bit),
@W_IsActive bit = CAST(JSON_VALUE(@Record, '$.IsActive') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Types', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS tinyint) AS [Id]
,CAST(JSON_VALUE([Record], '$.CategoryId') AS tinyint) AS [CategoryId]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Minimum') AS sql_variant) AS [Minimum]
,CAST(JSON_VALUE([Record], '$.Maximum') AS sql_variant) AS [Maximum]
,CAST(JSON_VALUE([Record], '$.AskLength') AS bit) AS [AskLength]
,CAST(JSON_VALUE([Record], '$.AskDecimals') AS bit) AS [AskDecimals]
,CAST(JSON_VALUE([Record], '$.AskPrimarykey') AS bit) AS [AskPrimarykey]
,CAST(JSON_VALUE([Record], '$.AskAutoincrement') AS bit) AS [AskAutoincrement]
,CAST(JSON_VALUE([Record], '$.AskFilterable') AS bit) AS [AskFilterable]
,CAST(JSON_VALUE([Record], '$.AskBrowseable') AS bit) AS [AskBrowseable]
,CAST(JSON_VALUE([Record], '$.AskCodification') AS bit) AS [AskCodification]
,CAST(JSON_VALUE([Record], '$.AskFormula') AS bit) AS [AskFormula]
,CAST(JSON_VALUE([Record], '$.AllowMaxLength') AS bit) AS [AllowMaxLength]
,CAST(JSON_VALUE([Record], '$.IsActive') AS bit) AS [IsActive]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[CategoryId]
,[tab].[Name]
,[tab].[Minimum]
,[tab].[Maximum]
,[tab].[AskLength]
,[tab].[AskDecimals]
,[tab].[AskPrimarykey]
,[tab].[AskAutoincrement]
,[tab].[AskFilterable]
,[tab].[AskBrowseable]
,[tab].[AskCodification]
,[tab].[AskFormula]
,[tab].[AllowMaxLength]
,[tab].[IsActive]
INTO[dbo].[#tab]
FROM[dbo].[Types] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[AskLength] = ISNULL(@W_AskLength, [tab].[AskLength])
AND [tab].[AskDecimals] = ISNULL(@W_AskDecimals, [tab].[AskDecimals])
AND [tab].[AskPrimarykey] = ISNULL(@W_AskPrimarykey, [tab].[AskPrimarykey])
AND [tab].[AskAutoincrement] = ISNULL(@W_AskAutoincrement, [tab].[AskAutoincrement])
AND [tab].[AskFilterable] = ISNULL(@W_AskFilterable, [tab].[AskFilterable])
AND [tab].[AskBrowseable] = ISNULL(@W_AskBrowseable, [tab].[AskBrowseable])
AND [tab].[AskCodification] = ISNULL(@W_AskCodification, [tab].[AskCodification])
AND [tab].[AskFormula] = ISNULL(@W_AskFormula, [tab].[AskFormula])
AND [tab].[AllowMaxLength] = ISNULL(@W_AllowMaxLength, [tab].[AllowMaxLength])
AND [tab].[IsActive] = ISNULL(@W_IsActive, [tab].[IsActive])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[CategoryId]
,[Name]
,[Minimum]
,[Maximum]
,[AskLength]
,[AskDecimals]
,[AskPrimarykey]
,[AskAutoincrement]
,[AskFilterable]
,[AskBrowseable]
,[AskCodification]
,[AskFormula]
,[AllowMaxLength]
,[IsActive]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[CategoryId] = [tmp].[CategoryId]
,[tab].[Name] = [tmp].[Name]
,[tab].[Minimum] = [tmp].[Minimum]
,[tab].[Maximum] = [tmp].[Maximum]
,[tab].[AskLength] = [tmp].[AskLength]
,[tab].[AskDecimals] = [tmp].[AskDecimals]
,[tab].[AskPrimarykey] = [tmp].[AskPrimarykey]
,[tab].[AskAutoincrement] = [tmp].[AskAutoincrement]
,[tab].[AskFilterable] = [tmp].[AskFilterable]
,[tab].[AskBrowseable] = [tmp].[AskBrowseable]
,[tab].[AskCodification] = [tmp].[AskCodification]
,[tab].[AskFormula] = [tmp].[AskFormula]
,[tab].[AllowMaxLength] = [tmp].[AllowMaxLength]
,[tab].[IsActive] = [tmp].[IsActive]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordType' AS [ClassName],
[tab].[Id]
,[tab].[CategoryId]
,[tab].[Name]
,[tab].[Minimum]
,[tab].[Maximum]
,[tab].[AskLength]
,[tab].[AskDecimals]
,[tab].[AskPrimarykey]
,[tab].[AskAutoincrement]
,[tab].[AskFilterable]
,[tab].[AskBrowseable]
,[tab].[AskCodification]
,[tab].[AskFormula]
,[tab].[AllowMaxLength]
,[tab].[IsActive]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Types
**********************************************************************************/
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'1', 
'2', 
'bigint', 
CAST('-9007199254740990' AS bigint), 
CAST('9007199254740990' AS bigint), 
'0', 
'0', 
'1', 
'1', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'2', 
'9', 
'binary', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'3', 
'5', 
'bit', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'4', 
'1', 
'char', 
NULL, 
NULL, 
'1', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'5', 
'3', 
'date', 
CONVERT(date,'01/01/0001', 103), 
CONVERT(date,'31/12/9999', 103), 
'0', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'6', 
'4', 
'datetime', 
CONVERT(datetime,'01/01/1753 00:00:00.000', 103), 
CONVERT(datetime,'31/12/9999 23:59:59.997', 103), 
'0', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'7', 
'4', 
'datetime2', 
CONVERT(datetime2,'01/01/0001 00:00:00.0000000', 103), 
CONVERT(datetime2,'31/12/9999 23:59:59.9999999', 103), 
'0', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'8', 
'4', 
'datetimeoffset', 
CONVERT(datetimeoffset,'01/01/0001 00:00:00.0000000', 103), 
CONVERT(datetimeoffset,'31/12/9999 23:59:59.9999999', 103), 
'0', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'9', 
'2', 
'decimal', 
CAST('-9007199254740990' AS decimal), 
CAST('9007199254740990' AS decimal), 
'1', 
'1', 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'10', 
'2', 
'float', 
CAST('-9007199254740990' AS float), 
CAST('9007199254740990' AS float), 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'11', 
'7', 
'geography', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'12', 
'7', 
'geometry', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'13', 
'1', 
'hierarchyid', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'14', 
'8', 
'image', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'15', 
'2', 
'int', 
CAST('-2147483648' AS int), 
CAST('2147483647' AS int), 
'0', 
'0', 
'1', 
'1', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'16', 
'2', 
'money', 
CAST('-922337203685477' AS money), 
CAST('922337203685477' AS money), 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'17', 
'1', 
'nchar', 
NULL, 
NULL, 
'1', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'18', 
'7', 
'ntext', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'19', 
'2', 
'numeric', 
CAST('-9007199254740990' AS numeric), 
CAST('9007199254740990' AS numeric), 
'1', 
'1', 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'20', 
'1', 
'nvarchar', 
NULL, 
NULL, 
'1', 
'0', 
'1', 
'0', 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'21', 
'2', 
'real', 
CAST('-9007199254740990' AS real), 
CAST('9007199254740990' AS real), 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'22', 
'4', 
'smalldatetime', 
CONVERT(smalldatetime,'01/01/1900', 103), 
CONVERT(smalldatetime,'06/06/2079 ', 103), 
'0', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'23', 
'2', 
'smallint', 
CAST('-32768' AS smallint), 
CAST('32767' AS smallint), 
'0', 
'0', 
'1', 
'1', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'24', 
'2', 
'smallmoney', 
CAST('214748' AS smallmoney), 
CAST('214748' AS smallmoney), 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'25', 
'10', 
'sql_variant', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'26', 
'1', 
'sysname', 
NULL, 
NULL, 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'27', 
'7', 
'text', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'28', 
'6', 
'time', 
CONVERT(time,'00:00:00.0000000', 103), 
CONVERT(time,'23:59:59.9999999', 103), 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'29', 
'4', 
'timestamp', 
NULL, 
NULL, 
'0', 
'0', 
'1', 
'0', 
'1', 
'1', 
'0', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'30', 
'2', 
'tinyint', 
CAST('0' AS tinyint), 
CAST('255' AS tinyint), 
'0', 
'0', 
'1', 
'1', 
'1', 
'1', 
'0', 
'1', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'31', 
'1', 
'uniqueidentifier', 
NULL, 
NULL, 
'0', 
'0', 
'1', 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'32', 
'9', 
'varbinary', 
NULL, 
NULL, 
'1', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'33', 
'1', 
'varchar', 
NULL, 
NULL, 
'1', 
'0', 
'1', 
'0', 
'1', 
'1', 
'1', 
'1', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Types] (
[Id], 
[CategoryId], 
[Name], 
[Minimum], 
[Maximum], 
[AskLength], 
[AskDecimals], 
[AskPrimarykey], 
[AskAutoincrement], 
[AskFilterable], 
[AskBrowseable], 
[AskCodification], 
[AskFormula], 
[AllowMaxLength], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'34', 
'7', 
'xml', 
NULL, 
NULL, 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Types
**********************************************************************************/
/**********************************************************************************
Criar tabela Masks
**********************************************************************************/
IF (SELECT object_id('[dbo].[Masks]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Masks]
CREATE TABLE [dbo].[Masks](
[Id] bigint NOT NULL,
[Name] varchar(25) NOT NULL,
[Mask] varchar(MAX) NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Masks] ADD CONSTRAINT PK_Masks PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Masks_Name] ON [dbo].[Masks]([Name] ASC)
GO
/**********************************************************************************
Criar procedure MasksCreate
**********************************************************************************/
IF(SELECT object_id('MasksCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MasksCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure MasksCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Mask varchar(MAX) = CAST(JSON_VALUE(@Record, '$.Mask') AS varchar(MAX))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Mask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Mask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Masks.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Masks_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Masks] (
[Id],
[Name],
[Mask],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_Name,
@W_Mask,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure MasksUpdate
**********************************************************************************/
IF(SELECT object_id('MasksUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MasksUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Mask varchar(MAX) = CAST(JSON_VALUE(@Record, '$.Mask') AS varchar(MAX))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Mask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Mask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Masks.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Masks_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Masks] SET
[Name] = @W_Name,
[Mask] = @W_Mask,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure MasksDelete
**********************************************************************************/
IF(SELECT object_id('MasksDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MasksDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure MasksDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Masks.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Masks]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure MasksRead
**********************************************************************************/
IF(SELECT object_id('MasksRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MasksRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure MasksRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Masks', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Mask') AS varchar(MAX)) AS [Mask]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[Name]
,[tab].[Mask]
INTO[dbo].[#tab]
FROM[dbo].[Masks] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[Name]
,[Mask]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[Name] = [tmp].[Name]
,[tab].[Mask] = [tmp].[Mask]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordMask' AS [ClassName],
[tab].[Id]
,[tab].[Name]
,[tab].[Mask]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Masks
**********************************************************************************/
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt, CreatedBy) VALUES (
'1', 
'BigInteger', 
'#.###.###.###.###.###', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt, CreatedBy) VALUES (
'2', 
'Integer', 
'#.###.###.###', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt, CreatedBy) VALUES (
'3', 
'SmallInteger', 
'##.###', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt, CreatedBy) VALUES (
'4', 
'TinyInteger', 
'###', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt, CreatedBy) VALUES (
'5', 
'ShortInteger', 
'##.###', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt, CreatedBy) VALUES (
'6', 
'DateTime', 
'dd/MM/yyyy hh:mm:ss', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Masks
**********************************************************************************/
/**********************************************************************************
Criar tabela Domains
**********************************************************************************/
IF (SELECT object_id('[dbo].[Domains]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Domains]
CREATE TABLE [dbo].[Domains](
[Id] bigint NOT NULL,
[TypeId] tinyint NOT NULL,
[MaskId] bigint NULL,
[Name] varchar(25) NOT NULL,
[Length] smallint NULL,
[Decimals] tinyint NULL,
[ValidValues] varchar(MAX) NULL,
[Default] sql_variant NULL,
[Minimum] sql_variant NULL,
[Maximum] sql_variant NULL,
[Codification] varchar(5) NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Domains] ADD CONSTRAINT PK_Domains PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Domains_Name] ON [dbo].[Domains]([Name] ASC)
GO
/**********************************************************************************
Criar procedure DomainsCreate
**********************************************************************************/
IF(SELECT object_id('DomainsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DomainsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DomainsCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TypeId tinyint = CAST(JSON_VALUE(@Record, '$.TypeId') AS tinyint),
@W_MaskId bigint = CAST(JSON_VALUE(@Record, '$.MaskId') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Length smallint = CAST(JSON_VALUE(@Record, '$.Length') AS smallint),
@W_Decimals tinyint = CAST(JSON_VALUE(@Record, '$.Decimals') AS tinyint),
@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@Record, '$.ValidValues') AS varchar(MAX)),
@W_Default sql_variant = CAST(JSON_VALUE(@Record, '$.Default') AS sql_variant),
@W_Minimum sql_variant = CAST(JSON_VALUE(@Record, '$.Minimum') AS sql_variant),
@W_Maximum sql_variant = CAST(JSON_VALUE(@Record, '$.Maximum') AS sql_variant),
@W_Codification varchar(5) = CAST(JSON_VALUE(@Record, '$.Codification') AS varchar(5))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaskId IS NOT NULL AND @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaskId deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaskId IS NOT NULL AND @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaskId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Length IS NOT NULL AND @W_Length < CAST('0' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Length deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Length IS NOT NULL AND @W_Length > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Length deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Decimals IS NOT NULL AND @W_Decimals < CAST('0' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Decimals deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Decimals IS NOT NULL AND @W_Decimals > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Decimals deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Domains.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Domains_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Domains] (
[Id],
[TypeId],
[MaskId],
[Name],
[Length],
[Decimals],
[ValidValues],
[Default],
[Minimum],
[Maximum],
[Codification],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_TypeId,
@W_MaskId,
@W_Name,
@W_Length,
@W_Decimals,
@W_ValidValues,
@W_Default,
@W_Minimum,
@W_Maximum,
@W_Codification,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DomainsUpdate
**********************************************************************************/
IF(SELECT object_id('DomainsUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DomainsUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TypeId tinyint = CAST(JSON_VALUE(@Record, '$.TypeId') AS tinyint),
@W_MaskId bigint = CAST(JSON_VALUE(@Record, '$.MaskId') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Length smallint = CAST(JSON_VALUE(@Record, '$.Length') AS smallint),
@W_Decimals tinyint = CAST(JSON_VALUE(@Record, '$.Decimals') AS tinyint),
@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@Record, '$.ValidValues') AS varchar(MAX)),
@W_Default sql_variant = CAST(JSON_VALUE(@Record, '$.Default') AS sql_variant),
@W_Minimum sql_variant = CAST(JSON_VALUE(@Record, '$.Minimum') AS sql_variant),
@W_Maximum sql_variant = CAST(JSON_VALUE(@Record, '$.Maximum') AS sql_variant),
@W_Codification varchar(5) = CAST(JSON_VALUE(@Record, '$.Codification') AS varchar(5))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaskId IS NOT NULL AND @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaskId deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaskId IS NOT NULL AND @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaskId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Length IS NOT NULL AND @W_Length < CAST('0' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Length deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Length IS NOT NULL AND @W_Length > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Length deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Decimals IS NOT NULL AND @W_Decimals < CAST('0' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Decimals deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Decimals IS NOT NULL AND @W_Decimals > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Decimals deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Domains.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Domains_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Domains] SET
[TypeId] = @W_TypeId,
[MaskId] = @W_MaskId,
[Name] = @W_Name,
[Length] = @W_Length,
[Decimals] = @W_Decimals,
[ValidValues] = @W_ValidValues,
[Default] = @W_Default,
[Minimum] = @W_Minimum,
[Maximum] = @W_Maximum,
[Codification] = @W_Codification,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DomainsDelete
**********************************************************************************/
IF(SELECT object_id('DomainsDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DomainsDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DomainsDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Domains.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Domains]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DomainsRead
**********************************************************************************/
IF(SELECT object_id('DomainsRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DomainsRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DomainsRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TypeId tinyint = CAST(JSON_VALUE(@Record, '$.TypeId') AS tinyint),
@W_MaskId bigint = CAST(JSON_VALUE(@Record, '$.MaskId') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@Record, '$.ValidValues') AS varchar(MAX)),
@W_Codification varchar(5) = CAST(JSON_VALUE(@Record, '$.Codification') AS varchar(5))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId IS NOT NULL AND @W_TypeId < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TypeId IS NOT NULL AND @W_TypeId > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TypeId deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaskId IS NOT NULL AND @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaskId deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaskId IS NOT NULL AND @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaskId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Domains', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.TypeId') AS tinyint) AS [TypeId]
,CAST(JSON_VALUE([Record], '$.MaskId') AS bigint) AS [MaskId]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Length') AS smallint) AS [Length]
,CAST(JSON_VALUE([Record], '$.Decimals') AS tinyint) AS [Decimals]
,CAST(JSON_VALUE([Record], '$.ValidValues') AS varchar(MAX)) AS [ValidValues]
,CAST(JSON_VALUE([Record], '$.Default') AS sql_variant) AS [Default]
,CAST(JSON_VALUE([Record], '$.Minimum') AS sql_variant) AS [Minimum]
,CAST(JSON_VALUE([Record], '$.Maximum') AS sql_variant) AS [Maximum]
,CAST(JSON_VALUE([Record], '$.Codification') AS varchar(5)) AS [Codification]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[TypeId]
,[tab].[MaskId]
,[tab].[Name]
,[tab].[Length]
,[tab].[Decimals]
,[tab].[ValidValues]
,[tab].[Default]
,[tab].[Minimum]
,[tab].[Maximum]
,[tab].[Codification]
INTO[dbo].[#tab]
FROM[dbo].[Domains] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[TypeId] = ISNULL(@W_TypeId, [tab].[TypeId])
AND (@W_MaskId IS NULL OR [tab].[MaskId] = @W_MaskId)
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND (@W_ValidValues IS NULL OR [tab].[ValidValues] = @W_ValidValues)
AND (@W_Codification IS NULL OR [tab].[Codification] = @W_Codification)
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[TypeId]
,[MaskId]
,[Name]
,[Length]
,[Decimals]
,[ValidValues]
,[Default]
,[Minimum]
,[Maximum]
,[Codification]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[TypeId] = [tmp].[TypeId]
,[tab].[MaskId] = [tmp].[MaskId]
,[tab].[Name] = [tmp].[Name]
,[tab].[Length] = [tmp].[Length]
,[tab].[Decimals] = [tmp].[Decimals]
,[tab].[ValidValues] = [tmp].[ValidValues]
,[tab].[Default] = [tmp].[Default]
,[tab].[Minimum] = [tmp].[Minimum]
,[tab].[Maximum] = [tmp].[Maximum]
,[tab].[Codification] = [tmp].[Codification]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordDomain' AS [ClassName],
[tab].[Id]
,[tab].[TypeId]
,[tab].[MaskId]
,[tab].[Name]
,[tab].[Length]
,[tab].[Decimals]
,[tab].[ValidValues]
,[tab].[Default]
,[tab].[Minimum]
,[tab].[Maximum]
,[tab].[Codification]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Domains
**********************************************************************************/
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'1', 
'BigInteger', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'2', 
'15', 
'2', 
'Integer', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'3', 
'15', 
'5', 
'ShortInteger', 
NULL, 
NULL, 
NULL, 
NULL, 
CAST('-65536' AS int), 
CAST('65535' AS int), 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'4', 
'23', 
'3', 
'SmallInteger', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'5', 
'30', 
'4', 
'TinyInteger', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'6', 
'3', 
NULL, 
'Boolean', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'7', 
'33', 
NULL, 
'Varchar(15)', 
'15', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'8', 
'33', 
NULL, 
'Varchar(20)', 
'20', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'9', 
'33', 
NULL, 
'Varchar(25)', 
'25', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'10', 
'33', 
NULL, 
'Varchar(50)', 
'50', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'11', 
'33', 
NULL, 
'Varchar(256)', 
'256', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'12', 
'33', 
NULL, 
'Varchar(MAX)', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'13', 
'33', 
NULL, 
'JavaScript', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'JS', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'14', 
'33', 
NULL, 
'SQL', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'SQL', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'15', 
'33', 
NULL, 
'JSON', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'JSON', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'16', 
'6', 
'6', 
'DateTime', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'17', 
'25', 
NULL, 
'Variant', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'18', 
'33', 
NULL, 
'Codification', 
'5', 
NULL, 
';JSON;JS;SQL', 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'19', 
'33', 
NULL, 
'HtmlInputType', 
'10', 
NULL, 
'text;checkbox;textarea;image;file', 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Domains] (
[Id], 
[TypeId], 
[MaskId], 
[Name], 
[Length], 
[Decimals], 
[ValidValues], 
[Default], 
[Minimum], 
[Maximum], 
[Codification], 
CreatedAt, CreatedBy) VALUES (
'20', 
'33', 
NULL, 
'HtmlInputAlign', 
'6', 
NULL, 
';left;center;right', 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Domains
**********************************************************************************/
/**********************************************************************************
Criar tabela Systems
**********************************************************************************/
IF (SELECT object_id('[dbo].[Systems]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Systems]
CREATE TABLE [dbo].[Systems](
[Id] bigint NOT NULL,
[Name] varchar(25) NOT NULL,
[Description] varchar(50) NOT NULL,
[ClientName] varchar(15) NOT NULL,
[MaxRetryLogins] tinyint NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Systems] ADD CONSTRAINT PK_Systems PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Systems_Name] ON [dbo].[Systems]([Name] ASC)
GO
/**********************************************************************************
Criar procedure SystemsCreate
**********************************************************************************/
IF(SELECT object_id('SystemsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_ClientName varchar(15) = CAST(JSON_VALUE(@Record, '$.ClientName') AS varchar(15)),
@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@Record, '$.MaxRetryLogins') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ClientName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ClientName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins IS NULL
SET @W_MaxRetryLogins = CAST('5' AS tinyint)
IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaxRetryLogins deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaxRetryLogins deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Systems.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Systems_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Systems] (
[Id],
[Name],
[Description],
[ClientName],
[MaxRetryLogins],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_Name,
@W_Description,
@W_ClientName,
@W_MaxRetryLogins,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsUpdate
**********************************************************************************/
IF(SELECT object_id('SystemsUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_ClientName varchar(15) = CAST(JSON_VALUE(@Record, '$.ClientName') AS varchar(15)),
@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@Record, '$.MaxRetryLogins') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ClientName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ClientName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaxRetryLogins é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaxRetryLogins deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @MaxRetryLogins deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Systems.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Systems_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Systems] SET
[Name] = @W_Name,
[Description] = @W_Description,
[ClientName] = @W_ClientName,
[MaxRetryLogins] = @W_MaxRetryLogins,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsDelete
**********************************************************************************/
IF(SELECT object_id('SystemsDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Systems.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Systems]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsRead
**********************************************************************************/
IF(SELECT object_id('SystemsRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_ClientName varchar(15) = CAST(JSON_VALUE(@Record, '$.ClientName') AS varchar(15))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Systems', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([Record], '$.ClientName') AS varchar(15)) AS [ClientName]
,CAST(JSON_VALUE([Record], '$.MaxRetryLogins') AS tinyint) AS [MaxRetryLogins]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[Name]
,[tab].[Description]
,[tab].[ClientName]
,[tab].[MaxRetryLogins]
INTO[dbo].[#tab]
FROM[dbo].[Systems] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[ClientName] = ISNULL(@W_ClientName, [tab].[ClientName])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[Name]
,[Description]
,[ClientName]
,[MaxRetryLogins]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[Name] = [tmp].[Name]
,[tab].[Description] = [tmp].[Description]
,[tab].[ClientName] = [tmp].[ClientName]
,[tab].[MaxRetryLogins] = [tmp].[MaxRetryLogins]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordSystem' AS [ClassName],
[tab].[Id]
,[tab].[Name]
,[tab].[Description]
,[tab].[ClientName]
,[tab].[MaxRetryLogins]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Systems
**********************************************************************************/
GO
INSERT INTO [dbo].[Systems] (
[Id], 
[Name], 
[Description], 
[ClientName], 
[MaxRetryLogins], 
CreatedAt, CreatedBy) VALUES (
'1', 
'cruda', 
'CRUD Automático', 
'DAYCOVAL', 
'5', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Systems
**********************************************************************************/
/**********************************************************************************
Criar tabela Menus
**********************************************************************************/
IF (SELECT object_id('[dbo].[Menus]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Menus]
CREATE TABLE [dbo].[Menus](
[Id] bigint NOT NULL,
[SystemId] bigint NOT NULL,
[Sequence] smallint NOT NULL,
[Caption] varchar(20) NOT NULL,
[Message] varchar(50) NOT NULL,
[Action] varchar(50) NULL,
[ParentMenuId] bigint NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Menus] ADD CONSTRAINT PK_Menus PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Menus_System_Sequence] ON [dbo].[Menus]([SystemId] ASC,[Sequence] ASC)
GO
/**********************************************************************************
Criar procedure MenusCreate
**********************************************************************************/
IF(SELECT object_id('MenusCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MenusCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure MenusCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_Sequence smallint = CAST(JSON_VALUE(@Record, '$.Sequence') AS smallint),
@W_Caption varchar(20) = CAST(JSON_VALUE(@Record, '$.Caption') AS varchar(20)),
@W_Message varchar(50) = CAST(JSON_VALUE(@Record, '$.Message') AS varchar(50)),
@W_Action varchar(50) = CAST(JSON_VALUE(@Record, '$.Action') AS varchar(50)),
@W_ParentMenuId bigint = CAST(JSON_VALUE(@Record, '$.ParentMenuId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence < CAST('1' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Message IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Message é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentMenuId IS NOT NULL AND @W_ParentMenuId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentMenuId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentMenuId IS NOT NULL AND @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentMenuId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Menus.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId
 AND [Sequence] = @W_Sequence
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Menus_System_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Menus] (
[Id],
[SystemId],
[Sequence],
[Caption],
[Message],
[Action],
[ParentMenuId],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_SystemId,
@W_Sequence,
@W_Caption,
@W_Message,
@W_Action,
@W_ParentMenuId,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure MenusUpdate
**********************************************************************************/
IF(SELECT object_id('MenusUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MenusUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_Sequence smallint = CAST(JSON_VALUE(@Record, '$.Sequence') AS smallint),
@W_Caption varchar(20) = CAST(JSON_VALUE(@Record, '$.Caption') AS varchar(20)),
@W_Message varchar(50) = CAST(JSON_VALUE(@Record, '$.Message') AS varchar(50)),
@W_Action varchar(50) = CAST(JSON_VALUE(@Record, '$.Action') AS varchar(50)),
@W_ParentMenuId bigint = CAST(JSON_VALUE(@Record, '$.ParentMenuId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence < CAST('1' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Message IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Message é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentMenuId IS NOT NULL AND @W_ParentMenuId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentMenuId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentMenuId IS NOT NULL AND @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentMenuId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Menus.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE NOT (Id = @W_Id
) AND [SystemId] = @W_SystemId
AND [Sequence] = @W_Sequence
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Menus_System_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Menus] SET
[SystemId] = @W_SystemId,
[Sequence] = @W_Sequence,
[Caption] = @W_Caption,
[Message] = @W_Message,
[Action] = @W_Action,
[ParentMenuId] = @W_ParentMenuId,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure MenusDelete
**********************************************************************************/
IF(SELECT object_id('MenusDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MenusDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure MenusDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Menus.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Menus]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure MenusRead
**********************************************************************************/
IF(SELECT object_id('MenusRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MenusRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure MenusRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_Caption varchar(20) = CAST(JSON_VALUE(@Record, '$.Caption') AS varchar(20))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Menus', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([Record], '$.Sequence') AS smallint) AS [Sequence]
,CAST(JSON_VALUE([Record], '$.Caption') AS varchar(20)) AS [Caption]
,CAST(JSON_VALUE([Record], '$.Message') AS varchar(50)) AS [Message]
,CAST(JSON_VALUE([Record], '$.Action') AS varchar(50)) AS [Action]
,CAST(JSON_VALUE([Record], '$.ParentMenuId') AS bigint) AS [ParentMenuId]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[SystemId]
,[tab].[Sequence]
,[tab].[Caption]
,[tab].[Message]
,[tab].[Action]
,[tab].[ParentMenuId]
INTO[dbo].[#tab]
FROM[dbo].[Menus] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[SystemId] = ISNULL(@W_SystemId, [tab].[SystemId])
AND [tab].[Caption] = ISNULL(@W_Caption, [tab].[Caption])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[SystemId]
,[Sequence]
,[Caption]
,[Message]
,[Action]
,[ParentMenuId]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[SystemId] = [tmp].[SystemId]
,[tab].[Sequence] = [tmp].[Sequence]
,[tab].[Caption] = [tmp].[Caption]
,[tab].[Message] = [tmp].[Message]
,[tab].[Action] = [tmp].[Action]
,[tab].[ParentMenuId] = [tmp].[ParentMenuId]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordMenu' AS [ClassName],
[tab].[Id]
,[tab].[SystemId]
,[tab].[Sequence]
,[tab].[Caption]
,[tab].[Message]
,[tab].[Action]
,[tab].[ParentMenuId]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Menus
**********************************************************************************/
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'5', 
'Cadastros', 
'Cadastros', 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'2', 
'1', 
'10', 
'Tipos', 
'Cadastro de tipos', 
'grid/cruda/Types', 
'7', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'3', 
'1', 
'15', 
'Usuários', 
'Cadastro de Usuários', 
'grid/cruda/Users', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'4', 
'1', 
'60', 
'Tabelas', 
'Cadastro de tabelas', 
'grid/cruda/Tables', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'5', 
'1', 
'35', 
'Menus', 
'Cadastro de menus', 
'grid/cruda/Menus', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'6', 
'1', 
'20', 
'Sistemas', 
'Cadastro de sistemas', 
'grid/cruda/Systems', 
'3', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'7', 
'1', 
'25', 
'Banco de Dados', 
'Cadastro de bancos de dados', 
'grid/cruda/Databases', 
'3', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'8', 
'1', 
'30', 
'Colunas', 
'Cadastro de colunas de tabelas', 
'grid/cruda/Columns', 
'7', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'9', 
'1', 
'40', 
'Associações', 
'Associações entre tabelas', 
NULL, 
NULL, 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'10', 
'1', 
'45', 
'Sistemas x BD', 
'Associação entre sistemas e bancos de dados', 
'grid/cruda/SystemsDatabases', 
'9', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'11', 
'1', 
'50', 
'Usuários x Sistemas', 
'Associação entre usuários e sistemas', 
'grid/cruda/SystemsUsers', 
'9', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt, CreatedBy) VALUES (
'12', 
'1', 
'55', 
'Sair', 
'Retornar ao login', 
'exit/login', 
NULL, 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Menus
**********************************************************************************/
/**********************************************************************************
Criar tabela Users
**********************************************************************************/
IF (SELECT object_id('[dbo].[Users]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Users]
CREATE TABLE [dbo].[Users](
[Id] bigint NOT NULL,
[Name] varchar(25) NOT NULL,
[Password] varchar(256) NOT NULL,
[FullName] varchar(50) NOT NULL,
[RetryLogins] tinyint NOT NULL,
[IsActive] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Users] ADD CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Users_Name] ON [dbo].[Users]([Name] ASC)
GO
/**********************************************************************************
Criar procedure UsersCreate
**********************************************************************************/
IF(SELECT object_id('UsersCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[UsersCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure UsersCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Password varchar(256) = CAST(JSON_VALUE(@Record, '$.Password') AS varchar(256)),
@W_FullName varchar(50) = CAST(JSON_VALUE(@Record, '$.FullName') AS varchar(50)),
@W_RetryLogins tinyint = CAST(JSON_VALUE(@Record, '$.RetryLogins') AS tinyint),
@W_IsActive bit = CAST(JSON_VALUE(@Record, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Password IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Password é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_FullName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @FullName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins IS NULL
SET @W_RetryLogins = CAST('0' AS tinyint)
IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @RetryLogins deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @RetryLogins deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Users.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Users_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Users] (
[Id],
[Name],
[Password],
[FullName],
[RetryLogins],
[IsActive],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_Name,
@W_Password,
@W_FullName,
@W_RetryLogins,
@W_IsActive,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure UsersUpdate
**********************************************************************************/
IF(SELECT object_id('UsersUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[UsersUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Password varchar(256) = CAST(JSON_VALUE(@Record, '$.Password') AS varchar(256)),
@W_FullName varchar(50) = CAST(JSON_VALUE(@Record, '$.FullName') AS varchar(50)),
@W_RetryLogins tinyint = CAST(JSON_VALUE(@Record, '$.RetryLogins') AS tinyint),
@W_IsActive bit = CAST(JSON_VALUE(@Record, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Password IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Password é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_FullName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @FullName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @RetryLogins é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @RetryLogins deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @RetryLogins deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Users] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Users.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Users_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Users] SET
[Name] = @W_Name,
[Password] = @W_Password,
[FullName] = @W_FullName,
[RetryLogins] = @W_RetryLogins,
[IsActive] = @W_IsActive,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure UsersDelete
**********************************************************************************/
IF(SELECT object_id('UsersDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[UsersDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure UsersDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Users] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Users.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Users]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure UsersRead
**********************************************************************************/
IF(SELECT object_id('UsersRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[UsersRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure UsersRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_FullName varchar(50) = CAST(JSON_VALUE(@Record, '$.FullName') AS varchar(50)),
@W_IsActive bit = CAST(JSON_VALUE(@Record, '$.IsActive') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Users', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Password') AS varchar(256)) AS [Password]
,CAST(JSON_VALUE([Record], '$.FullName') AS varchar(50)) AS [FullName]
,CAST(JSON_VALUE([Record], '$.RetryLogins') AS tinyint) AS [RetryLogins]
,CAST(JSON_VALUE([Record], '$.IsActive') AS bit) AS [IsActive]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[Name]
,[tab].[Password]
,[tab].[FullName]
,[tab].[RetryLogins]
,[tab].[IsActive]
INTO[dbo].[#tab]
FROM[dbo].[Users] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[FullName] = ISNULL(@W_FullName, [tab].[FullName])
AND [tab].[IsActive] = ISNULL(@W_IsActive, [tab].[IsActive])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[Name]
,[Password]
,[FullName]
,[RetryLogins]
,[IsActive]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[Name] = [tmp].[Name]
,[tab].[Password] = [tmp].[Password]
,[tab].[FullName] = [tmp].[FullName]
,[tab].[RetryLogins] = [tmp].[RetryLogins]
,[tab].[IsActive] = [tmp].[IsActive]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordUser' AS [ClassName],
[tab].[Id]
,[tab].[Name]
,[tab].[Password]
,[tab].[FullName]
,[tab].[RetryLogins]
,[tab].[IsActive]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Users
**********************************************************************************/
GO
INSERT INTO [dbo].[Users] (
[Id], 
[Name], 
[Password], 
[FullName], 
[RetryLogins], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'1', 
'adm', 
'adm', 
'Administrador', 
'0', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Users] (
[Id], 
[Name], 
[Password], 
[FullName], 
[RetryLogins], 
[IsActive], 
CreatedAt, CreatedBy) VALUES (
'2', 
'labrego', 
'diva', 
'João da Rocha Labrego', 
'0', 
'1', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Users
**********************************************************************************/
/**********************************************************************************
Criar tabela SystemsUsers
**********************************************************************************/
IF (SELECT object_id('[dbo].[SystemsUsers]', 'U')) IS NOT NULL
DROP TABLE [dbo].[SystemsUsers]
CREATE TABLE [dbo].[SystemsUsers](
[Id] bigint NOT NULL,
[SystemId] bigint NOT NULL,
[UserId] bigint NOT NULL,
[Description] varchar(50) NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[SystemsUsers] ADD CONSTRAINT PK_SystemsUsers PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_SystemsUsers_System_User] ON [dbo].[SystemsUsers]([SystemId] ASC,[UserId] ASC)
CREATE UNIQUE INDEX [UNQ_SystemsUsers_Description] ON [dbo].[SystemsUsers]([Description] ASC)
GO
/**********************************************************************************
Criar procedure SystemsUsersCreate
**********************************************************************************/
IF(SELECT object_id('SystemsUsersCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsUsersCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsUsersCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_UserId bigint = CAST(JSON_VALUE(@Record, '$.UserId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela SystemsUsers.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [SystemId] = @W_SystemId
 AND [UserId] = @W_UserId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsUsers_System_User já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Description] = @W_Description
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsUsers_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[SystemsUsers] (
[Id],
[SystemId],
[UserId],
[Description],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_SystemId,
@W_UserId,
@W_Description,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsUsersUpdate
**********************************************************************************/
IF(SELECT object_id('SystemsUsersUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsUsersUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_UserId bigint = CAST(JSON_VALUE(@Record, '$.UserId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsUsers.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE NOT (Id = @W_Id
) AND [SystemId] = @W_SystemId
AND [UserId] = @W_UserId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsUsers_System_User já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE NOT (Id = @W_Id
) AND [Description] = @W_Description
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsUsers_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[SystemsUsers] SET
[SystemId] = @W_SystemId,
[UserId] = @W_UserId,
[Description] = @W_Description,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsUsersDelete
**********************************************************************************/
IF(SELECT object_id('SystemsUsersDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsUsersDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsUsersDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsUsers.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[SystemsUsers]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsUsersRead
**********************************************************************************/
IF(SELECT object_id('SystemsUsersRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsUsersRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsUsersRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_UserId bigint = CAST(JSON_VALUE(@Record, '$.UserId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NOT NULL AND @W_UserId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NOT NULL AND @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'SystemsUsers', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([Record], '$.UserId') AS bigint) AS [UserId]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[SystemId]
,[tab].[UserId]
,[tab].[Description]
INTO[dbo].[#tab]
FROM[dbo].[SystemsUsers] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[SystemId] = ISNULL(@W_SystemId, [tab].[SystemId])
AND [tab].[UserId] = ISNULL(@W_UserId, [tab].[UserId])
AND [tab].[Description] = ISNULL(@W_Description, [tab].[Description])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[SystemId]
,[UserId]
,[Description]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[SystemId] = [tmp].[SystemId]
,[tab].[UserId] = [tmp].[UserId]
,[tab].[Description] = [tmp].[Description]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordSystemUser' AS [ClassName],
[tab].[Id]
,[tab].[SystemId]
,[tab].[UserId]
,[tab].[Description]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela SystemsUsers
**********************************************************************************/
GO
INSERT INTO [dbo].[SystemsUsers] (
[Id], 
[SystemId], 
[UserId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'1', 
'cruda x adm', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[SystemsUsers] (
[Id], 
[SystemId], 
[UserId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'2', 
'1', 
'2', 
'cruda x labrego', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela SystemsUsers
**********************************************************************************/
/**********************************************************************************
Criar tabela Databases
**********************************************************************************/
IF (SELECT object_id('[dbo].[Databases]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Databases]
CREATE TABLE [dbo].[Databases](
[Id] bigint NOT NULL,
[Name] varchar(25) NOT NULL,
[Description] varchar(50) NOT NULL,
[Alias] varchar(25) NOT NULL,
[ServerName] varchar(50) NULL,
[HostName] varchar(25) NULL,
[Port] int NULL,
[Logon] varchar(256) NULL,
[Password] varchar(256) NULL,
[Folder] varchar(256) NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Databases] ADD CONSTRAINT PK_Databases PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Databases_Name] ON [dbo].[Databases]([Name] ASC)
CREATE UNIQUE INDEX [UNQ_Databases_Alias] ON [dbo].[Databases]([Alias] ASC)
GO
/**********************************************************************************
Criar procedure DatabasesCreate
**********************************************************************************/
IF(SELECT object_id('DatabasesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DatabasesCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_Alias varchar(25) = CAST(JSON_VALUE(@Record, '$.Alias') AS varchar(25)),
@W_ServerName varchar(50) = CAST(JSON_VALUE(@Record, '$.ServerName') AS varchar(50)),
@W_HostName varchar(25) = CAST(JSON_VALUE(@Record, '$.HostName') AS varchar(25)),
@W_Port int = CAST(JSON_VALUE(@Record, '$.Port') AS int),
@W_Logon varchar(256) = CAST(JSON_VALUE(@Record, '$.Logon') AS varchar(256)),
@W_Password varchar(256) = CAST(JSON_VALUE(@Record, '$.Password') AS varchar(256)),
@W_Folder varchar(256) = CAST(JSON_VALUE(@Record, '$.Folder') AS varchar(256))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Port IS NOT NULL AND @W_Port < CAST('1' AS int) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Port deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Port IS NOT NULL AND @W_Port > CAST('65535' AS int) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Port deve ser menor que ou igual à ''65535''.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Databases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Databases_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Alias] = @W_Alias
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Databases_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Databases] (
[Id],
[Name],
[Description],
[Alias],
[ServerName],
[HostName],
[Port],
[Logon],
[Password],
[Folder],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_Name,
@W_Description,
@W_Alias,
@W_ServerName,
@W_HostName,
@W_Port,
@W_Logon,
@W_Password,
@W_Folder,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DatabasesUpdate
**********************************************************************************/
IF(SELECT object_id('DatabasesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_Alias varchar(25) = CAST(JSON_VALUE(@Record, '$.Alias') AS varchar(25)),
@W_ServerName varchar(50) = CAST(JSON_VALUE(@Record, '$.ServerName') AS varchar(50)),
@W_HostName varchar(25) = CAST(JSON_VALUE(@Record, '$.HostName') AS varchar(25)),
@W_Port int = CAST(JSON_VALUE(@Record, '$.Port') AS int),
@W_Logon varchar(256) = CAST(JSON_VALUE(@Record, '$.Logon') AS varchar(256)),
@W_Password varchar(256) = CAST(JSON_VALUE(@Record, '$.Password') AS varchar(256)),
@W_Folder varchar(256) = CAST(JSON_VALUE(@Record, '$.Folder') AS varchar(256))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Port IS NOT NULL AND @W_Port < CAST('1' AS int) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Port deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Port IS NOT NULL AND @W_Port > CAST('65535' AS int) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Port deve ser menor que ou igual à ''65535''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Databases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Databases_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE NOT (Id = @W_Id
) AND [Alias] = @W_Alias
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Databases_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Databases] SET
[Name] = @W_Name,
[Description] = @W_Description,
[Alias] = @W_Alias,
[ServerName] = @W_ServerName,
[HostName] = @W_HostName,
[Port] = @W_Port,
[Logon] = @W_Logon,
[Password] = @W_Password,
[Folder] = @W_Folder,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DatabasesDelete
**********************************************************************************/
IF(SELECT object_id('DatabasesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DatabasesDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Databases.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Databases]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DatabasesRead
**********************************************************************************/
IF(SELECT object_id('DatabasesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DatabasesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Alias varchar(25) = CAST(JSON_VALUE(@Record, '$.Alias') AS varchar(25))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Databases', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([Record], '$.Alias') AS varchar(25)) AS [Alias]
,CAST(JSON_VALUE([Record], '$.ServerName') AS varchar(50)) AS [ServerName]
,CAST(JSON_VALUE([Record], '$.HostName') AS varchar(25)) AS [HostName]
,CAST(JSON_VALUE([Record], '$.Port') AS int) AS [Port]
,CAST(JSON_VALUE([Record], '$.Logon') AS varchar(256)) AS [Logon]
,CAST(JSON_VALUE([Record], '$.Password') AS varchar(256)) AS [Password]
,CAST(JSON_VALUE([Record], '$.Folder') AS varchar(256)) AS [Folder]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[Name]
,[tab].[Description]
,[tab].[Alias]
,[tab].[ServerName]
,[tab].[HostName]
,[tab].[Port]
,[tab].[Logon]
,[tab].[Password]
,[tab].[Folder]
INTO[dbo].[#tab]
FROM[dbo].[Databases] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[Alias] = ISNULL(@W_Alias, [tab].[Alias])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[Name]
,[Description]
,[Alias]
,[ServerName]
,[HostName]
,[Port]
,[Logon]
,[Password]
,[Folder]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[Name] = [tmp].[Name]
,[tab].[Description] = [tmp].[Description]
,[tab].[Alias] = [tmp].[Alias]
,[tab].[ServerName] = [tmp].[ServerName]
,[tab].[HostName] = [tmp].[HostName]
,[tab].[Port] = [tmp].[Port]
,[tab].[Logon] = [tmp].[Logon]
,[tab].[Password] = [tmp].[Password]
,[tab].[Folder] = [tmp].[Folder]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordDatabase' AS [ClassName],
[tab].[Id]
,[tab].[Name]
,[tab].[Description]
,[tab].[Alias]
,[tab].[ServerName]
,[tab].[HostName]
,[tab].[Port]
,[tab].[Logon]
,[tab].[Password]
,[tab].[Folder]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Databases
**********************************************************************************/
GO
INSERT INTO [dbo].[Databases] (
[Id], 
[Name], 
[Description], 
[Alias], 
[ServerName], 
[HostName], 
[Port], 
[Logon], 
[Password], 
[Folder], 
CreatedAt, CreatedBy) VALUES (
'1', 
'cruda', 
'CRUD Automático', 
'cruda', 
'NOTEBOOK-DELL', 
'localhost', 
'1433', 
'sa', 
'diva', 
'D:\CRUDA-C#\CRUDA-CORE\CRUDA\db\', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Databases
**********************************************************************************/
/**********************************************************************************
Criar tabela SystemsDatabases
**********************************************************************************/
IF (SELECT object_id('[dbo].[SystemsDatabases]', 'U')) IS NOT NULL
DROP TABLE [dbo].[SystemsDatabases]
CREATE TABLE [dbo].[SystemsDatabases](
[Id] bigint NOT NULL,
[SystemId] bigint NOT NULL,
[DatabaseId] bigint NOT NULL,
[Description] varchar(50) NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[SystemsDatabases] ADD CONSTRAINT PK_SystemsDatabases PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_SystemsDatabases_System_Database] ON [dbo].[SystemsDatabases]([SystemId] ASC,[DatabaseId] ASC)
CREATE UNIQUE INDEX [UNQ_SystemsDatabases_Description] ON [dbo].[SystemsDatabases]([Description] ASC)
GO
/**********************************************************************************
Criar procedure SystemsDatabasesCreate
**********************************************************************************/
IF(SELECT object_id('SystemsDatabasesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsDatabasesCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela SystemsDatabases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [SystemId] = @W_SystemId
 AND [DatabaseId] = @W_DatabaseId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsDatabases_System_Database já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Description] = @W_Description
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsDatabases_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[SystemsDatabases] (
[Id],
[SystemId],
[DatabaseId],
[Description],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_SystemId,
@W_DatabaseId,
@W_Description,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsDatabasesUpdate
**********************************************************************************/
IF(SELECT object_id('SystemsDatabasesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsDatabases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE NOT (Id = @W_Id
) AND [SystemId] = @W_SystemId
AND [DatabaseId] = @W_DatabaseId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsDatabases_System_Database já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE NOT (Id = @W_Id
) AND [Description] = @W_Description
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_SystemsDatabases_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[SystemsDatabases] SET
[SystemId] = @W_SystemId,
[DatabaseId] = @W_DatabaseId,
[Description] = @W_Description,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsDatabasesDelete
**********************************************************************************/
IF(SELECT object_id('SystemsDatabasesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsDatabasesDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsDatabases.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[SystemsDatabases]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure SystemsDatabasesRead
**********************************************************************************/
IF(SELECT object_id('SystemsDatabasesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure SystemsDatabasesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NOT NULL AND @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NOT NULL AND @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'SystemsDatabases', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([Record], '$.DatabaseId') AS bigint) AS [DatabaseId]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[SystemId]
,[tab].[DatabaseId]
,[tab].[Description]
INTO[dbo].[#tab]
FROM[dbo].[SystemsDatabases] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[SystemId] = ISNULL(@W_SystemId, [tab].[SystemId])
AND [tab].[DatabaseId] = ISNULL(@W_DatabaseId, [tab].[DatabaseId])
AND [tab].[Description] = ISNULL(@W_Description, [tab].[Description])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[SystemId]
,[DatabaseId]
,[Description]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[SystemId] = [tmp].[SystemId]
,[tab].[DatabaseId] = [tmp].[DatabaseId]
,[tab].[Description] = [tmp].[Description]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordSystemDatabase' AS [ClassName],
[tab].[Id]
,[tab].[SystemId]
,[tab].[DatabaseId]
,[tab].[Description]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela SystemsDatabases
**********************************************************************************/
GO
INSERT INTO [dbo].[SystemsDatabases] (
[Id], 
[SystemId], 
[DatabaseId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'1', 
'cruda x cruda', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela SystemsDatabases
**********************************************************************************/
/**********************************************************************************
Criar tabela Tables
**********************************************************************************/
IF (SELECT object_id('[dbo].[Tables]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Tables]
CREATE TABLE [dbo].[Tables](
[Id] bigint NOT NULL,
[Name] varchar(25) NOT NULL,
[Alias] varchar(25) NOT NULL,
[Description] varchar(50) NOT NULL,
[ParentTableId] bigint NULL,
[ProcedureCreate] varchar(50) NULL,
[ProcedureRead] varchar(50) NULL,
[ProcedureUpdate] varchar(50) NULL,
[ProcedureDelete] varchar(50) NULL,
[ProcedureList] varchar(50) NULL,
[IsPaged] bit NOT NULL,
[LastId] bigint NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Tables] ADD CONSTRAINT PK_Tables PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Tables_Name] ON [dbo].[Tables]([Name] ASC)
CREATE UNIQUE INDEX [UNQ_Tables_Alias] ON [dbo].[Tables]([Alias] ASC)
GO
/**********************************************************************************
Criar procedure TablesCreate
**********************************************************************************/
IF(SELECT object_id('TablesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TablesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TablesCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure TablesCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Alias varchar(25) = CAST(JSON_VALUE(@Record, '$.Alias') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_ParentTableId bigint = CAST(JSON_VALUE(@Record, '$.ParentTableId') AS bigint),
@W_ProcedureCreate varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureCreate') AS varchar(50)),
@W_ProcedureRead varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureRead') AS varchar(50)),
@W_ProcedureUpdate varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureUpdate') AS varchar(50)),
@W_ProcedureDelete varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureDelete') AS varchar(50)),
@W_ProcedureList varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureList') AS varchar(50)),
@W_IsPaged bit = CAST(JSON_VALUE(@Record, '$.IsPaged') AS bit),
@W_LastId bigint = CAST(JSON_VALUE(@Record, '$.LastId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentTableId deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentTableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsPaged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsPaged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId IS NULL
SET @W_LastId = CAST('0' AS bigint)
IF @W_LastId < CAST('0' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @LastId deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @LastId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Tables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Tables_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Alias] = @W_Alias
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Tables_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Tables] (
[Id],
[Name],
[Alias],
[Description],
[ParentTableId],
[ProcedureCreate],
[ProcedureRead],
[ProcedureUpdate],
[ProcedureDelete],
[ProcedureList],
[IsPaged],
[LastId],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_Name,
@W_Alias,
@W_Description,
@W_ParentTableId,
@W_ProcedureCreate,
@W_ProcedureRead,
@W_ProcedureUpdate,
@W_ProcedureDelete,
@W_ProcedureList,
@W_IsPaged,
@W_LastId,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure TablesUpdate
**********************************************************************************/
IF(SELECT object_id('TablesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TablesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TablesUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Alias varchar(25) = CAST(JSON_VALUE(@Record, '$.Alias') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_ParentTableId bigint = CAST(JSON_VALUE(@Record, '$.ParentTableId') AS bigint),
@W_ProcedureCreate varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureCreate') AS varchar(50)),
@W_ProcedureRead varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureRead') AS varchar(50)),
@W_ProcedureUpdate varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureUpdate') AS varchar(50)),
@W_ProcedureDelete varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureDelete') AS varchar(50)),
@W_ProcedureList varchar(50) = CAST(JSON_VALUE(@Record, '$.ProcedureList') AS varchar(50)),
@W_IsPaged bit = CAST(JSON_VALUE(@Record, '$.IsPaged') AS bit),
@W_LastId bigint = CAST(JSON_VALUE(@Record, '$.LastId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentTableId deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentTableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsPaged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsPaged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @LastId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId < CAST('0' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @LastId deve ser maior que ou igual à ''0''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @LastId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Tables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE NOT (Id = @W_Id
) AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Tables_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE NOT (Id = @W_Id
) AND [Alias] = @W_Alias
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Tables_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Tables] SET
[Name] = @W_Name,
[Alias] = @W_Alias,
[Description] = @W_Description,
[ParentTableId] = @W_ParentTableId,
[ProcedureCreate] = @W_ProcedureCreate,
[ProcedureRead] = @W_ProcedureRead,
[ProcedureUpdate] = @W_ProcedureUpdate,
[ProcedureDelete] = @W_ProcedureDelete,
[ProcedureList] = @W_ProcedureList,
[IsPaged] = @W_IsPaged,
[LastId] = @W_LastId,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure TablesDelete
**********************************************************************************/
IF(SELECT object_id('TablesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TablesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TablesDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure TablesDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Tables.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Tables]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure TablesRead
**********************************************************************************/
IF(SELECT object_id('TablesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TablesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TablesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure TablesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Alias varchar(25) = CAST(JSON_VALUE(@Record, '$.Alias') AS varchar(25)),
@W_ParentTableId bigint = CAST(JSON_VALUE(@Record, '$.ParentTableId') AS bigint),
@W_IsPaged bit = CAST(JSON_VALUE(@Record, '$.IsPaged') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentTableId deve ser maior que ou igual à ''-9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ParentTableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Tables', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Alias') AS varchar(25)) AS [Alias]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([Record], '$.ParentTableId') AS bigint) AS [ParentTableId]
,CAST(JSON_VALUE([Record], '$.ProcedureCreate') AS varchar(50)) AS [ProcedureCreate]
,CAST(JSON_VALUE([Record], '$.ProcedureRead') AS varchar(50)) AS [ProcedureRead]
,CAST(JSON_VALUE([Record], '$.ProcedureUpdate') AS varchar(50)) AS [ProcedureUpdate]
,CAST(JSON_VALUE([Record], '$.ProcedureDelete') AS varchar(50)) AS [ProcedureDelete]
,CAST(JSON_VALUE([Record], '$.ProcedureList') AS varchar(50)) AS [ProcedureList]
,CAST(JSON_VALUE([Record], '$.IsPaged') AS bit) AS [IsPaged]
,CAST(JSON_VALUE([Record], '$.LastId') AS bigint) AS [LastId]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[Name]
,[tab].[Alias]
,[tab].[Description]
,[tab].[ParentTableId]
,[tab].[ProcedureCreate]
,[tab].[ProcedureRead]
,[tab].[ProcedureUpdate]
,[tab].[ProcedureDelete]
,[tab].[ProcedureList]
,[tab].[IsPaged]
,[tab].[LastId]
INTO[dbo].[#tab]
FROM[dbo].[Tables] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[Alias] = ISNULL(@W_Alias, [tab].[Alias])
AND (@W_ParentTableId IS NULL OR [tab].[ParentTableId] = @W_ParentTableId)
AND [tab].[IsPaged] = ISNULL(@W_IsPaged, [tab].[IsPaged])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[Name]
,[Alias]
,[Description]
,[ParentTableId]
,[ProcedureCreate]
,[ProcedureRead]
,[ProcedureUpdate]
,[ProcedureDelete]
,[ProcedureList]
,[IsPaged]
,[LastId]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[Name] = [tmp].[Name]
,[tab].[Alias] = [tmp].[Alias]
,[tab].[Description] = [tmp].[Description]
,[tab].[ParentTableId] = [tmp].[ParentTableId]
,[tab].[ProcedureCreate] = [tmp].[ProcedureCreate]
,[tab].[ProcedureRead] = [tmp].[ProcedureRead]
,[tab].[ProcedureUpdate] = [tmp].[ProcedureUpdate]
,[tab].[ProcedureDelete] = [tmp].[ProcedureDelete]
,[tab].[ProcedureList] = [tmp].[ProcedureList]
,[tab].[IsPaged] = [tmp].[IsPaged]
,[tab].[LastId] = [tmp].[LastId]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordTable' AS [ClassName],
[tab].[Id]
,[tab].[Name]
,[tab].[Alias]
,[tab].[Description]
,[tab].[ParentTableId]
,[tab].[ProcedureCreate]
,[tab].[ProcedureRead]
,[tab].[ProcedureUpdate]
,[tab].[ProcedureDelete]
,[tab].[ProcedureList]
,[tab].[IsPaged]
,[tab].[LastId]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Tables
**********************************************************************************/
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'1', 
'Categories', 
'Category', 
'Categorias de tipos de dados', 
NULL, 
NULL, 
'CategoriesRead', 
NULL, 
NULL, 
NULL, 
'1', 
'10', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'2', 
'Types', 
'Type', 
'Tipos', 
NULL, 
'TypesCreate', 
'TypesRead', 
'TypesUpdate', 
'TypesDelete', 
'TypesList', 
'1', 
'34', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'3', 
'Masks', 
'Mask', 
'Máscaras de Edição', 
NULL, 
'MasksCreate', 
'MasksRead', 
'MasksUpdate', 
'MasksDelete', 
'MasksList', 
'1', 
'6', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'4', 
'Domains', 
'Domain', 
'Domínios', 
NULL, 
'DomainsCreate', 
'DomainsRead', 
'DomainsUpdate', 
'DomainsDelete', 
'DomainsList', 
'1', 
'20', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'5', 
'Systems', 
'System', 
'Sistemas', 
NULL, 
'SystemsCreate', 
'SystemsRead', 
'SystemsUpdate', 
'SystemsDelete', 
'SystemsList', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'6', 
'Menus', 
'Menu', 
'Menus', 
'4', 
'MenusCreate', 
'MenusRead', 
'MenusUpdate', 
'MenusDelete', 
'MenusList', 
'1', 
'12', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'7', 
'Users', 
'User', 
'Usuários', 
NULL, 
'UsersCreate', 
'UsersRead', 
'UsersUpdate', 
'UsersDelete', 
'UsersList', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'8', 
'SystemsUsers', 
'SystemUser', 
'Sistemas x Usuários', 
'4', 
'SystemsUsersCreate', 
'SystemsUsersRead', 
'SystemsUsersUpdate', 
'SystemsUsersDelete', 
NULL, 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'9', 
'Databases', 
'Database', 
'Bancos-de-Dados', 
NULL, 
'DatabasesCreate', 
'DatabasesRead', 
'DatabasesUpdate', 
'DatabasesDelete', 
'DatabasesList', 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'10', 
'SystemsDatabases', 
'SystemDatabase', 
'Sistemas x Bancos-de-Dados', 
'4', 
'SystemsDatabasesCreate', 
'SystemsDatabasesRead', 
'SystemsDatabasesUpdate', 
'SystemsDatabasesDelete', 
NULL, 
'1', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'11', 
'Tables', 
'Table', 
'Tabelas', 
'8', 
'TablesCreate', 
'TablesRead', 
'TablesUpdate', 
'TablesDelete', 
'TablesList', 
'1', 
'17', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'12', 
'DatabasesTables', 
'DatabaseTable', 
'Bancos-de-Dados x Tabelas', 
'9', 
'DatabasesTablesCreate', 
'DatabasesTablesRead', 
'DatabasesTablesUpdate', 
'DatabasesDelete', 
NULL, 
'1', 
'17', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'13', 
'Columns', 
'Column', 
'Colunas', 
'10', 
'ColumnsCreate', 
'ColumnsRead', 
'ColumnsUpdate', 
'ColumnsDelete', 
'ColumnsList', 
'1', 
'134', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'14', 
'Indexes', 
'Index', 
'Índices', 
'10', 
'IndexesCreate', 
'IndexesRead', 
'IndexesUpdate', 
'IndexesDelete', 
'IndexesList', 
'1', 
'24', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'15', 
'Indexkeys', 
'Indexkey', 
'Chaves de índices', 
'12', 
'IndexkeysCreate', 
'IndexkeysRead', 
'IndexkeysUpdate', 
'IndexkeysDelete', 
NULL, 
'1', 
'37', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'16', 
'Logins', 
'Login', 
'Logins de Acesso aos Sistemas', 
NULL, 
'LoginsCreate', 
'LoginsRead', 
'LoginsUpdate', 
NULL, 
NULL, 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'17', 
'Transactions', 
'Transaction', 
'Transações em Bancos-de-Dados', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Tables] (
[Id], 
[Name], 
[Alias], 
[Description], 
[ParentTableId], 
[ProcedureCreate], 
[ProcedureRead], 
[ProcedureUpdate], 
[ProcedureDelete], 
[ProcedureList], 
[IsPaged], 
[LastId], 
CreatedAt, CreatedBy) VALUES (
'18', 
'Operations', 
'Operation', 
'Operações em Tabelas', 
'17', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
'0', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Tables
**********************************************************************************/
/**********************************************************************************
Criar tabela DatabasesTables
**********************************************************************************/
IF (SELECT object_id('[dbo].[DatabasesTables]', 'U')) IS NOT NULL
DROP TABLE [dbo].[DatabasesTables]
CREATE TABLE [dbo].[DatabasesTables](
[Id] bigint NOT NULL,
[DatabaseId] bigint NOT NULL,
[TableId] bigint NOT NULL,
[Description] varchar(50) NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[DatabasesTables] ADD CONSTRAINT PK_DatabasesTables PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_DatabasesTables_Database_Table] ON [dbo].[DatabasesTables]([DatabaseId] ASC,[TableId] ASC)
CREATE UNIQUE INDEX [UNQ_DatabasesTables_Description] ON [dbo].[DatabasesTables]([Description] ASC)
GO
/**********************************************************************************
Criar procedure DatabasesTablesCreate
**********************************************************************************/
IF(SELECT object_id('DatabasesTablesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesTablesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesTablesCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DatabasesTablesCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela DatabasesTables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_DatabaseId
 AND [TableId] = @W_TableId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_DatabasesTables_Database_Table já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Description] = @W_Description
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_DatabasesTables_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[DatabasesTables] (
[Id],
[DatabaseId],
[TableId],
[Description],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_DatabaseId,
@W_TableId,
@W_Description,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DatabasesTablesUpdate
**********************************************************************************/
IF(SELECT object_id('DatabasesTablesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesTablesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesTablesUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela DatabasesTables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE NOT (Id = @W_Id
) AND [DatabaseId] = @W_DatabaseId
AND [TableId] = @W_TableId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_DatabasesTables_Database_Table já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE NOT (Id = @W_Id
) AND [Description] = @W_Description
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_DatabasesTables_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[DatabasesTables] SET
[DatabaseId] = @W_DatabaseId,
[TableId] = @W_TableId,
[Description] = @W_Description,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DatabasesDelete
**********************************************************************************/
IF(SELECT object_id('DatabasesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DatabasesDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela DatabasesTables.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[DatabasesTables]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure DatabasesTablesRead
**********************************************************************************/
IF(SELECT object_id('DatabasesTablesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesTablesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesTablesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure DatabasesTablesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50))
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NOT NULL AND @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NOT NULL AND @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NOT NULL AND @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NOT NULL AND @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'DatabasesTables', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.DatabaseId') AS bigint) AS [DatabaseId]
,CAST(JSON_VALUE([Record], '$.TableId') AS bigint) AS [TableId]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[DatabaseId]
,[tab].[TableId]
,[tab].[Description]
INTO[dbo].[#tab]
FROM[dbo].[DatabasesTables] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[DatabaseId] = ISNULL(@W_DatabaseId, [tab].[DatabaseId])
AND [tab].[TableId] = ISNULL(@W_TableId, [tab].[TableId])
AND [tab].[Description] = ISNULL(@W_Description, [tab].[Description])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[DatabaseId]
,[TableId]
,[Description]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[DatabaseId] = [tmp].[DatabaseId]
,[tab].[TableId] = [tmp].[TableId]
,[tab].[Description] = [tmp].[Description]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordDatabaseTable' AS [ClassName],
[tab].[Id]
,[tab].[DatabaseId]
,[tab].[TableId]
,[tab].[Description]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela DatabasesTables
**********************************************************************************/
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'1', 
'cruda x Categories', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'2', 
'1', 
'2', 
'cruda x Types', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'3', 
'1', 
'3', 
'cruda x Masks', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'4', 
'1', 
'4', 
'cruda x Domains', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'5', 
'1', 
'5', 
'cruda x Systems', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'6', 
'1', 
'6', 
'cruda x Menus', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'7', 
'1', 
'7', 
'cruda x Users', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'8', 
'1', 
'8', 
'cruda x SystemsUsers', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'9', 
'1', 
'9', 
'cruda x Databases', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'10', 
'1', 
'10', 
'cruda x SystemsDatabases', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'11', 
'1', 
'11', 
'cruda x Tables', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'12', 
'1', 
'12', 
'cruda x DatabasesTables', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'13', 
'1', 
'13', 
'cruda x Columns', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'14', 
'1', 
'14', 
'cruda x Indexes', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'15', 
'1', 
'15', 
'cruda x Indexkeys', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'16', 
'1', 
'16', 
'cruda x Logs', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt, CreatedBy) VALUES (
'17', 
'1', 
'17', 
'cruda x Transactions', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela DatabasesTables
**********************************************************************************/
/**********************************************************************************
Criar tabela Columns
**********************************************************************************/
IF (SELECT object_id('[dbo].[Columns]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Columns]
CREATE TABLE [dbo].[Columns](
[Id] bigint NOT NULL,
[TableId] bigint NOT NULL,
[Sequence] smallint NOT NULL,
[DomainId] bigint NOT NULL,
[ReferenceTableId] bigint NULL,
[Name] varchar(25) NOT NULL,
[Description] varchar(50) NOT NULL,
[Title] varchar(25) NOT NULL,
[Caption] varchar(25) NOT NULL,
[Default] sql_variant NULL,
[Minimum] sql_variant NULL,
[Maximum] sql_variant NULL,
[IsPrimarykey] bit NULL,
[IsAutoIncrement] bit NULL,
[IsRequired] bit NOT NULL,
[IsListable] bit NULL,
[IsFilterable] bit NULL,
[IsEditable] bit NULL,
[IsBrowseable] bit NULL,
[IsEncrypted] bit NULL,
[IsCalculated] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Columns] ADD CONSTRAINT PK_Columns PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Columns_Table_Name] ON [dbo].[Columns]([TableId] ASC,[Name] ASC)
CREATE UNIQUE INDEX [UNQ_Columns_Table_Sequence] ON [dbo].[Columns]([TableId] ASC,[Sequence] ASC)
GO
/**********************************************************************************
Criar procedure ColumnsCreate
**********************************************************************************/
IF(SELECT object_id('ColumnsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[ColumnsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Sequence smallint = CAST(JSON_VALUE(@Record, '$.Sequence') AS smallint),
@W_DomainId bigint = CAST(JSON_VALUE(@Record, '$.DomainId') AS bigint),
@W_ReferenceTableId bigint = CAST(JSON_VALUE(@Record, '$.ReferenceTableId') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_Title varchar(25) = CAST(JSON_VALUE(@Record, '$.Title') AS varchar(25)),
@W_Caption varchar(25) = CAST(JSON_VALUE(@Record, '$.Caption') AS varchar(25)),
@W_Default sql_variant = CAST(JSON_VALUE(@Record, '$.Default') AS sql_variant),
@W_Minimum sql_variant = CAST(JSON_VALUE(@Record, '$.Minimum') AS sql_variant),
@W_Maximum sql_variant = CAST(JSON_VALUE(@Record, '$.Maximum') AS sql_variant),
@W_IsPrimarykey bit = CAST(JSON_VALUE(@Record, '$.IsPrimarykey') AS bit),
@W_IsAutoIncrement bit = CAST(JSON_VALUE(@Record, '$.IsAutoIncrement') AS bit),
@W_IsRequired bit = CAST(JSON_VALUE(@Record, '$.IsRequired') AS bit),
@W_IsListable bit = CAST(JSON_VALUE(@Record, '$.IsListable') AS bit),
@W_IsFilterable bit = CAST(JSON_VALUE(@Record, '$.IsFilterable') AS bit),
@W_IsEditable bit = CAST(JSON_VALUE(@Record, '$.IsEditable') AS bit),
@W_IsBrowseable bit = CAST(JSON_VALUE(@Record, '$.IsBrowseable') AS bit),
@W_IsEncrypted bit = CAST(JSON_VALUE(@Record, '$.IsEncrypted') AS bit),
@W_IsCalculated bit = CAST(JSON_VALUE(@Record, '$.IsCalculated') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence < CAST('1' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Title IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Title é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsRequired IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsRequired é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsCalculated IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsCalculated é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Columns.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId
 AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId
 AND [Sequence] = @W_Sequence
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Columns] (
[Id],
[TableId],
[Sequence],
[DomainId],
[ReferenceTableId],
[Name],
[Description],
[Title],
[Caption],
[Default],
[Minimum],
[Maximum],
[IsPrimarykey],
[IsAutoIncrement],
[IsRequired],
[IsListable],
[IsFilterable],
[IsEditable],
[IsBrowseable],
[IsEncrypted],
[IsCalculated],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_TableId,
@W_Sequence,
@W_DomainId,
@W_ReferenceTableId,
@W_Name,
@W_Description,
@W_Title,
@W_Caption,
@W_Default,
@W_Minimum,
@W_Maximum,
@W_IsPrimarykey,
@W_IsAutoIncrement,
@W_IsRequired,
@W_IsListable,
@W_IsFilterable,
@W_IsEditable,
@W_IsBrowseable,
@W_IsEncrypted,
@W_IsCalculated,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure ColumnsUpdate
**********************************************************************************/
IF(SELECT object_id('ColumnsUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[ColumnsUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Sequence smallint = CAST(JSON_VALUE(@Record, '$.Sequence') AS smallint),
@W_DomainId bigint = CAST(JSON_VALUE(@Record, '$.DomainId') AS bigint),
@W_ReferenceTableId bigint = CAST(JSON_VALUE(@Record, '$.ReferenceTableId') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_Description varchar(50) = CAST(JSON_VALUE(@Record, '$.Description') AS varchar(50)),
@W_Title varchar(25) = CAST(JSON_VALUE(@Record, '$.Title') AS varchar(25)),
@W_Caption varchar(25) = CAST(JSON_VALUE(@Record, '$.Caption') AS varchar(25)),
@W_Default sql_variant = CAST(JSON_VALUE(@Record, '$.Default') AS sql_variant),
@W_Minimum sql_variant = CAST(JSON_VALUE(@Record, '$.Minimum') AS sql_variant),
@W_Maximum sql_variant = CAST(JSON_VALUE(@Record, '$.Maximum') AS sql_variant),
@W_IsPrimarykey bit = CAST(JSON_VALUE(@Record, '$.IsPrimarykey') AS bit),
@W_IsAutoIncrement bit = CAST(JSON_VALUE(@Record, '$.IsAutoIncrement') AS bit),
@W_IsRequired bit = CAST(JSON_VALUE(@Record, '$.IsRequired') AS bit),
@W_IsListable bit = CAST(JSON_VALUE(@Record, '$.IsListable') AS bit),
@W_IsFilterable bit = CAST(JSON_VALUE(@Record, '$.IsFilterable') AS bit),
@W_IsEditable bit = CAST(JSON_VALUE(@Record, '$.IsEditable') AS bit),
@W_IsBrowseable bit = CAST(JSON_VALUE(@Record, '$.IsBrowseable') AS bit),
@W_IsEncrypted bit = CAST(JSON_VALUE(@Record, '$.IsEncrypted') AS bit),
@W_IsCalculated bit = CAST(JSON_VALUE(@Record, '$.IsCalculated') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence < CAST('1' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Title IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Title é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsRequired IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsRequired é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsCalculated IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsCalculated é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE NOT (Id = @W_Id
) AND [TableId] = @W_TableId
AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE NOT (Id = @W_Id
) AND [TableId] = @W_TableId
AND [Sequence] = @W_Sequence
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Columns] SET
[TableId] = @W_TableId,
[Sequence] = @W_Sequence,
[DomainId] = @W_DomainId,
[ReferenceTableId] = @W_ReferenceTableId,
[Name] = @W_Name,
[Description] = @W_Description,
[Title] = @W_Title,
[Caption] = @W_Caption,
[Default] = @W_Default,
[Minimum] = @W_Minimum,
[Maximum] = @W_Maximum,
[IsPrimarykey] = @W_IsPrimarykey,
[IsAutoIncrement] = @W_IsAutoIncrement,
[IsRequired] = @W_IsRequired,
[IsListable] = @W_IsListable,
[IsFilterable] = @W_IsFilterable,
[IsEditable] = @W_IsEditable,
[IsBrowseable] = @W_IsBrowseable,
[IsEncrypted] = @W_IsEncrypted,
[IsCalculated] = @W_IsCalculated,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure ColumnsDelete
**********************************************************************************/
IF(SELECT object_id('ColumnsDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[ColumnsDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Columns]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure ColumnsRead
**********************************************************************************/
IF(SELECT object_id('ColumnsRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[ColumnsRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_DomainId bigint = CAST(JSON_VALUE(@Record, '$.DomainId') AS bigint),
@W_ReferenceTableId bigint = CAST(JSON_VALUE(@Record, '$.ReferenceTableId') AS bigint),
@W_Name varchar(25) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(25)),
@W_IsAutoIncrement bit = CAST(JSON_VALUE(@Record, '$.IsAutoIncrement') AS bit),
@W_IsRequired bit = CAST(JSON_VALUE(@Record, '$.IsRequired') AS bit),
@W_IsListable bit = CAST(JSON_VALUE(@Record, '$.IsListable') AS bit),
@W_IsFilterable bit = CAST(JSON_VALUE(@Record, '$.IsFilterable') AS bit),
@W_IsEditable bit = CAST(JSON_VALUE(@Record, '$.IsEditable') AS bit),
@W_IsBrowseable bit = CAST(JSON_VALUE(@Record, '$.IsBrowseable') AS bit),
@W_IsEncrypted bit = CAST(JSON_VALUE(@Record, '$.IsEncrypted') AS bit),
@W_IsCalculated bit = CAST(JSON_VALUE(@Record, '$.IsCalculated') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NOT NULL AND @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NOT NULL AND @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId IS NOT NULL AND @W_DomainId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DomainId IS NOT NULL AND @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Columns', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.TableId') AS bigint) AS [TableId]
,CAST(JSON_VALUE([Record], '$.Sequence') AS smallint) AS [Sequence]
,CAST(JSON_VALUE([Record], '$.DomainId') AS bigint) AS [DomainId]
,CAST(JSON_VALUE([Record], '$.ReferenceTableId') AS bigint) AS [ReferenceTableId]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([Record], '$.Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([Record], '$.Title') AS varchar(25)) AS [Title]
,CAST(JSON_VALUE([Record], '$.Caption') AS varchar(25)) AS [Caption]
,CAST(JSON_VALUE([Record], '$.Default') AS sql_variant) AS [Default]
,CAST(JSON_VALUE([Record], '$.Minimum') AS sql_variant) AS [Minimum]
,CAST(JSON_VALUE([Record], '$.Maximum') AS sql_variant) AS [Maximum]
,CAST(JSON_VALUE([Record], '$.IsPrimarykey') AS bit) AS [IsPrimarykey]
,CAST(JSON_VALUE([Record], '$.IsAutoIncrement') AS bit) AS [IsAutoIncrement]
,CAST(JSON_VALUE([Record], '$.IsRequired') AS bit) AS [IsRequired]
,CAST(JSON_VALUE([Record], '$.IsListable') AS bit) AS [IsListable]
,CAST(JSON_VALUE([Record], '$.IsFilterable') AS bit) AS [IsFilterable]
,CAST(JSON_VALUE([Record], '$.IsEditable') AS bit) AS [IsEditable]
,CAST(JSON_VALUE([Record], '$.IsBrowseable') AS bit) AS [IsBrowseable]
,CAST(JSON_VALUE([Record], '$.IsEncrypted') AS bit) AS [IsEncrypted]
,CAST(JSON_VALUE([Record], '$.IsCalculated') AS bit) AS [IsCalculated]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[TableId]
,[tab].[Sequence]
,[tab].[DomainId]
,[tab].[ReferenceTableId]
,[tab].[Name]
,[tab].[Description]
,[tab].[Title]
,[tab].[Caption]
,[tab].[Default]
,[tab].[Minimum]
,[tab].[Maximum]
,[tab].[IsPrimarykey]
,[tab].[IsAutoIncrement]
,[tab].[IsRequired]
,[tab].[IsListable]
,[tab].[IsFilterable]
,[tab].[IsEditable]
,[tab].[IsBrowseable]
,[tab].[IsEncrypted]
,[tab].[IsCalculated]
INTO[dbo].[#tab]
FROM[dbo].[Columns] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[TableId] = ISNULL(@W_TableId, [tab].[TableId])
AND [tab].[DomainId] = ISNULL(@W_DomainId, [tab].[DomainId])
AND (@W_ReferenceTableId IS NULL OR [tab].[ReferenceTableId] = @W_ReferenceTableId)
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND (@W_IsAutoIncrement IS NULL OR [tab].[IsAutoIncrement] = @W_IsAutoIncrement)
AND [tab].[IsRequired] = ISNULL(@W_IsRequired, [tab].[IsRequired])
AND (@W_IsListable IS NULL OR [tab].[IsListable] = @W_IsListable)
AND (@W_IsFilterable IS NULL OR [tab].[IsFilterable] = @W_IsFilterable)
AND (@W_IsEditable IS NULL OR [tab].[IsEditable] = @W_IsEditable)
AND (@W_IsBrowseable IS NULL OR [tab].[IsBrowseable] = @W_IsBrowseable)
AND (@W_IsEncrypted IS NULL OR [tab].[IsEncrypted] = @W_IsEncrypted)
AND [tab].[IsCalculated] = ISNULL(@W_IsCalculated, [tab].[IsCalculated])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[TableId]
,[Sequence]
,[DomainId]
,[ReferenceTableId]
,[Name]
,[Description]
,[Title]
,[Caption]
,[Default]
,[Minimum]
,[Maximum]
,[IsPrimarykey]
,[IsAutoIncrement]
,[IsRequired]
,[IsListable]
,[IsFilterable]
,[IsEditable]
,[IsBrowseable]
,[IsEncrypted]
,[IsCalculated]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[TableId] = [tmp].[TableId]
,[tab].[Sequence] = [tmp].[Sequence]
,[tab].[DomainId] = [tmp].[DomainId]
,[tab].[ReferenceTableId] = [tmp].[ReferenceTableId]
,[tab].[Name] = [tmp].[Name]
,[tab].[Description] = [tmp].[Description]
,[tab].[Title] = [tmp].[Title]
,[tab].[Caption] = [tmp].[Caption]
,[tab].[Default] = [tmp].[Default]
,[tab].[Minimum] = [tmp].[Minimum]
,[tab].[Maximum] = [tmp].[Maximum]
,[tab].[IsPrimarykey] = [tmp].[IsPrimarykey]
,[tab].[IsAutoIncrement] = [tmp].[IsAutoIncrement]
,[tab].[IsRequired] = [tmp].[IsRequired]
,[tab].[IsListable] = [tmp].[IsListable]
,[tab].[IsFilterable] = [tmp].[IsFilterable]
,[tab].[IsEditable] = [tmp].[IsEditable]
,[tab].[IsBrowseable] = [tmp].[IsBrowseable]
,[tab].[IsEncrypted] = [tmp].[IsEncrypted]
,[tab].[IsCalculated] = [tmp].[IsCalculated]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordColumn' AS [ClassName],
[tab].[Id]
,[tab].[TableId]
,[tab].[Sequence]
,[tab].[DomainId]
,[tab].[ReferenceTableId]
,[tab].[Name]
,[tab].[Description]
,[tab].[Title]
,[tab].[Caption]
,[tab].[Default]
,[tab].[Minimum]
,[tab].[Maximum]
,[tab].[IsPrimarykey]
,[tab].[IsAutoIncrement]
,[tab].[IsRequired]
,[tab].[IsListable]
,[tab].[IsFilterable]
,[tab].[IsEditable]
,[tab].[IsBrowseable]
,[tab].[IsEncrypted]
,[tab].[IsCalculated]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Columns
**********************************************************************************/
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'5', 
'5', 
NULL, 
'Id', 
'Id da categoria', 
'Categoria', 
'Categoria', 
NULL, 
CAST('1' AS tinyint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'2', 
'1', 
'10', 
'9', 
NULL, 
'Name', 
'Nome da categoria', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'3', 
'1', 
'15', 
'19', 
NULL, 
'HtmlInputType', 
'Tipo do input HTML', 
'Tipo input HTML', 
'Tipo input HTML', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'4', 
'1', 
'20', 
'20', 
NULL, 
'HtmlInputAlign', 
'Alinhamento do input HTML', 
'Alinhamento input HTML', 
'Alinhamento input HTML', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'5', 
'1', 
'25', 
'6', 
NULL, 
'AskEncrypted', 
'Tipo pede criptografia?', 
'Pede criptografia?', 
'Pede criptografia?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'6', 
'1', 
'30', 
'6', 
NULL, 
'AskMask', 
'Tipo pede máscara?', 
'Pede máscara?', 
'Pede máscara?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'7', 
'1', 
'35', 
'6', 
NULL, 
'AskListable', 
'Tipo pede listável?', 
'Pede listável?', 
'Pede listável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'8', 
'1', 
'40', 
'6', 
NULL, 
'AskDefault', 
'Tipo pede valor padrão?', 
'Pede valor padrão?', 
'Pede valor padrão?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'9', 
'1', 
'45', 
'6', 
NULL, 
'AskMinimum', 
'Tipo pede valor mínimo?', 
'Pede valor mínimo?', 
'Pede valor mínimo?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'10', 
'1', 
'50', 
'6', 
NULL, 
'AskMaximum', 
'Tipo pede valor máximo?', 
'Pede valor máximo?', 
'Pede valor máximo?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'11', 
'2', 
'5', 
'5', 
NULL, 
'Id', 
'ID do tipo', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'12', 
'2', 
'10', 
'5', 
'1', 
'CategoryId', 
'Categoria do tipo', 
'Categoria', 
'Categoria', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'13', 
'2', 
'15', 
'9', 
NULL, 
'Name', 
'Nome do tipo', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'14', 
'2', 
'20', 
'17', 
NULL, 
'Minimum', 
'Valor mínimo do tipo', 
'Mínimo', 
'Mínimo', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'15', 
'2', 
'25', 
'17', 
NULL, 
'Maximum', 
'Valor máximo do tipo', 
'Máximo', 
'Máximo', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'16', 
'2', 
'30', 
'6', 
NULL, 
'AskLength', 
'Tipo pede tamanho?', 
'Pede Tamanho?', 
'Pede Tamanho?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'17', 
'2', 
'35', 
'6', 
NULL, 
'AskDecimals', 
'Tipo pede decimais?', 
'Pede decimais?', 
'Pede decimais?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'18', 
'2', 
'40', 
'6', 
NULL, 
'AskPrimarykey', 
'Tipo pede chave-primária?', 
'Pede chave-primária?', 
'Pede chave-primária?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'19', 
'2', 
'45', 
'6', 
NULL, 
'AskAutoincrement', 
'Tipo pede autoincremento?', 
'Pede autoincremento?', 
'Pede autoincremento?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'20', 
'2', 
'50', 
'6', 
NULL, 
'AskFilterable', 
'Tipo pede filtrável?', 
'Pede filtrável?', 
'Pede filtrável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'21', 
'2', 
'55', 
'6', 
NULL, 
'AskBrowseable', 
'Tipo pede navegável?', 
'Pede navegável?', 
'Pede navegável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'22', 
'2', 
'60', 
'6', 
NULL, 
'AskCodification', 
'Tipo pede codificação?', 
'Pede codificação?', 
'Pede codificação?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'23', 
'2', 
'65', 
'6', 
NULL, 
'AskFormula', 
'Tipo pede fórmula?', 
'Pede fórmula?', 
'Pede fórmula?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'24', 
'2', 
'70', 
'6', 
NULL, 
'AllowMaxLength', 
'Tipo permite MAX no tamanho?', 
'Permite MAX?', 
'Permite MAX?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'25', 
'2', 
'75', 
'6', 
NULL, 
'IsActive', 
'Tipo é ativo?', 
'É ativo?', 
'É ativo?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'26', 
'3', 
'5', 
'1', 
NULL, 
'Id', 
'ID da máscara de edição', 
'ID', 
'ID', 
NULL, 
NULL, 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'27', 
'3', 
'10', 
'9', 
NULL, 
'Name', 
'Nome da máscara', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'28', 
'3', 
'15', 
'12', 
NULL, 
'Mask', 
'Máscara de edição', 
'Máscara', 
'Máscara', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'29', 
'4', 
'5', 
'1', 
NULL, 
'Id', 
'ID do domínio', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'30', 
'4', 
'10', 
'5', 
'2', 
'TypeId', 
'ID do tipo do domínio', 
'Tipo', 
'Tipo', 
NULL, 
CAST('1' AS tinyint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'31', 
'4', 
'15', 
'1', 
'3', 
'MaskId', 
'Id da máscara de edição do domínio', 
'Máscara', 
'Máscara', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'32', 
'4', 
'20', 
'9', 
NULL, 
'Name', 
'Nome do domínio', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'33', 
'4', 
'25', 
'4', 
NULL, 
'Length', 
'Tamanho do domínio', 
'Tamanho', 
'Tamanho', 
NULL, 
CAST('0' AS smallint), 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'34', 
'4', 
'30', 
'5', 
NULL, 
'Decimals', 
'Decimais do domínio', 
'Decimais', 
'Decimais', 
NULL, 
CAST('0' AS tinyint), 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'35', 
'4', 
'35', 
'12', 
NULL, 
'ValidValues', 
'Valores válidos', 
'Valores válidos', 
'Valores válidos', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'36', 
'4', 
'40', 
'17', 
NULL, 
'Default', 
'Valor mínimo do domínio', 
'Mínimo', 
'Mínimo', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'37', 
'4', 
'45', 
'17', 
NULL, 
'Minimum', 
'Valor máximo do domínio', 
'Máximo', 
'Máximo', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'38', 
'4', 
'50', 
'17', 
NULL, 
'Maximum', 
'Valor padrão do domínio', 
'Valor padrão', 
'Valor padrão', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'39', 
'4', 
'55', 
'18', 
NULL, 
'Codification', 
'Codificação da coluna', 
'Codificação', 
'Codificação', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'40', 
'5', 
'5', 
'1', 
NULL, 
'Id', 
'ID do sistema', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'41', 
'5', 
'10', 
'9', 
NULL, 
'Name', 
'Nome do sistema', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'42', 
'5', 
'15', 
'10', 
NULL, 
'Description', 
'Descrição do sistema', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'43', 
'5', 
'20', 
'7', 
NULL, 
'ClientName', 
'Cliente do sistema', 
'Cliente', 
'Cliente', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'44', 
'5', 
'25', 
'5', 
NULL, 
'MaxRetryLogins', 
'Máximo de tentativas de logins', 
'Máximo de logins', 
'Máximo de logins', 
CAST('5' AS tinyint), 
CAST('1' AS tinyint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'45', 
'6', 
'5', 
'1', 
NULL, 
'Id', 
'ID do menu', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'46', 
'6', 
'10', 
'1', 
'5', 
'SystemId', 
'ID do sistema do menu', 
'Sistema', 
'Sistema', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'47', 
'6', 
'15', 
'4', 
NULL, 
'Sequence', 
'Sequência do menu', 
'Sequência', 
'Sequência', 
NULL, 
CAST('1' AS smallint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'48', 
'6', 
'20', 
'8', 
NULL, 
'Caption', 
'Opção do menu', 
'Opção', 
'Opção', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'49', 
'6', 
'25', 
'10', 
NULL, 
'Message', 
'Mensagem do menu', 
'Mensagem', 
'Mensagem', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'50', 
'6', 
'30', 
'10', 
NULL, 
'Action', 
'Ação do menu', 
'Ação', 
'Ação', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
NULL, 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'51', 
'6', 
'35', 
'1', 
NULL, 
'ParentMenuId', 
'ID do menu-pai', 
'Menu-pai', 
'Menu-pai', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'0', 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'52', 
'7', 
'5', 
'1', 
NULL, 
'Id', 
'ID do usuário', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'53', 
'7', 
'10', 
'9', 
NULL, 
'Name', 
'Nome do usuário', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'54', 
'7', 
'15', 
'11', 
NULL, 
'Password', 
'Senha do usuário', 
'Senha', 
'Senha', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'55', 
'7', 
'20', 
'10', 
NULL, 
'FullName', 
'Nome completo do usuário', 
'Nome completo', 
'Nome completo', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'56', 
'7', 
'25', 
'5', 
NULL, 
'RetryLogins', 
'Tentativas de login', 
'Tentativas de login', 
'Tentativas de login', 
CAST('0' AS tinyint), 
CAST('0' AS tinyint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'57', 
'7', 
'30', 
'6', 
NULL, 
'IsActive', 
'Ativo?', 
'Ativo?', 
'Ativo?', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'58', 
'8', 
'5', 
'1', 
NULL, 
'Id', 
'ID do sistema x usuário', 
'Sistema', 
'Sistema', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'59', 
'8', 
'10', 
'1', 
'5', 
'SystemId', 
'ID do sistema', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'60', 
'8', 
'15', 
'1', 
NULL, 
'UserId', 
'ID do usuário', 
'Usuário', 
'Usuário', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'61', 
'8', 
'20', 
'10', 
NULL, 
'Description', 
'Descrição do siistema x usuário', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'62', 
'9', 
'5', 
'1', 
NULL, 
'Id', 
'ID do banco-de-dados', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'63', 
'9', 
'10', 
'9', 
NULL, 
'Name', 
'Nome do banco-de-dados', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'64', 
'9', 
'15', 
'10', 
NULL, 
'Description', 
'Descrição do banco-de-dados', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'65', 
'9', 
'20', 
'9', 
NULL, 
'Alias', 
'Alias  do banco-de-dados', 
'Alias', 
'Alias', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'66', 
'9', 
'25', 
'10', 
NULL, 
'ServerName', 
'String de conexão do banco-de-dados', 
'String de Conexão', 
'String de Conexão', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'67', 
'9', 
'30', 
'9', 
NULL, 
'HostName', 
'Hospedeiro do banco-de-dados', 
'Hospedeiro', 
'Hospedeiro', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'68', 
'9', 
'35', 
'3', 
NULL, 
'Port', 
'Porta TCP/IP do banco-de-dados', 
'Porta TCP/IP', 
'Porta TCP/IP', 
NULL, 
CAST('1' AS int), 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'0', 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'69', 
'9', 
'40', 
'11', 
NULL, 
'Logon', 
'Usuário do banco-de-dados', 
'Usuário', 
'Usuário', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'70', 
'9', 
'45', 
'11', 
NULL, 
'Password', 
'Senha do banco-de-dados', 
'Senha', 
'Senha', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'71', 
'9', 
'50', 
'11', 
NULL, 
'Folder', 
'Pasta diretório do banco-de-dados', 
'Pasta', 
'Pasta', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'0', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'72', 
'10', 
'5', 
'1', 
NULL, 
'Id', 
'ID do sistema x banco-de-dados', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'73', 
'10', 
'10', 
'1', 
'5', 
'SystemId', 
'ID do sistema', 
'Sistema', 
'Sistema', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'74', 
'10', 
'15', 
'1', 
'9', 
'DatabaseId', 
'ID do banco-de-dados', 
'Banco-de-dados', 
'Banco-de-dados', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'75', 
'10', 
'20', 
'10', 
NULL, 
'Description', 
'Descrição do sistema x banco-de-dados', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'76', 
'11', 
'5', 
'1', 
NULL, 
'Id', 
'ID da tabela', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'77', 
'11', 
'10', 
'9', 
NULL, 
'Name', 
'Nome da tabela', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'78', 
'11', 
'15', 
'9', 
NULL, 
'Alias', 
'Alias da tabela', 
'Alias', 
'Alias', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'79', 
'11', 
'20', 
'10', 
NULL, 
'Description', 
'Descrição da tabela', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'80', 
'11', 
'25', 
'1', 
'10', 
'ParentTableId', 
'ID tabela-pai', 
'Tabela-pai', 
'Tabela-pai', 
NULL, 
NULL, 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'81', 
'11', 
'30', 
'10', 
NULL, 
'ProcedureCreate', 
'Nome da procedure create da tabela', 
'Procedure Create', 
'Procedure Create', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'82', 
'11', 
'35', 
'10', 
NULL, 
'ProcedureRead', 
'Nome da procedure read da tabela', 
'Procedure Read', 
'Procedure Read', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'83', 
'11', 
'40', 
'10', 
NULL, 
'ProcedureUpdate', 
'Nome da procedure update da tabela', 
'Procedure Update', 
'Procedure Update', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'84', 
'11', 
'45', 
'10', 
NULL, 
'ProcedureDelete', 
'Nome da procedure delete da tabela', 
'Procedure Delete', 
'Procedure Delete', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'85', 
'11', 
'50', 
'10', 
NULL, 
'ProcedureList', 
'Nome da procedure list da tabela', 
'Procedure List', 
'Procedure List', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'86', 
'11', 
'55', 
'6', 
NULL, 
'IsPaged', 
'Consulta é paginada?', 
'Paginado?', 
'Paginado?', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'87', 
'11', 
'60', 
'1', 
NULL, 
'LastId', 
'Último Id', 
'Último Id', 
'Último Id', 
CAST('0' AS bigint), 
CAST('0' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'88', 
'12', 
'5', 
'1', 
NULL, 
'Id', 
'ID do banco-de-dados x tabela', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'89', 
'12', 
'10', 
'1', 
'9', 
'DatabaseId', 
'ID do banco-de-dados', 
'Sistema', 
'Sistema', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'90', 
'12', 
'15', 
'1', 
'11', 
'TableId', 
'ID da tabela', 
'Banco-de-dados', 
'Banco-de-dados', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'91', 
'12', 
'20', 
'10', 
NULL, 
'Description', 
'Descrição do banco-de-dados x tabela', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'92', 
'13', 
'5', 
'1', 
NULL, 
'Id', 
'ID da coluna', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'93', 
'13', 
'10', 
'1', 
'10', 
'TableId', 
'Tabela', 
'Tabela', 
'Tabela', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'94', 
'13', 
'15', 
'4', 
NULL, 
'Sequence', 
'Sequência', 
'Sequência', 
'Sequência', 
NULL, 
CAST('1' AS smallint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'95', 
'13', 
'20', 
'1', 
'2', 
'DomainId', 
'Domínio da coluna', 
'Domínio', 
'Domínio', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'96', 
'13', 
'25', 
'1', 
'10', 
'ReferenceTableId', 
'Tabela-referência', 
'Referência', 
'Referência', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'97', 
'13', 
'30', 
'9', 
NULL, 
'Name', 
'Nome da coluna', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'98', 
'13', 
'35', 
'10', 
NULL, 
'Description', 
'Descrição da Coluna', 
'Descrição', 
'Descrição', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'99', 
'13', 
'40', 
'9', 
NULL, 
'Title', 
'Título da Coluna', 
'Título', 
'Título', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'100', 
'13', 
'45', 
'9', 
NULL, 
'Caption', 
'Legenda da Coluna', 
'Legenda', 
'Legenda', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
NULL, 
'0', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'101', 
'13', 
'50', 
'17', 
NULL, 
'Default', 
'Valor padrão da coluna', 
'Padrão', 
'Padrão', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'102', 
'13', 
'55', 
'17', 
NULL, 
'Minimum', 
'Valor mínimo da coluna', 
'Mínimo', 
'Mínimo', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'103', 
'13', 
'60', 
'17', 
NULL, 
'Maximum', 
'Valor máximo da coluna', 
'Máximo', 
'Máximo', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'104', 
'13', 
'65', 
'6', 
NULL, 
'IsPrimarykey', 
'Coluna é chave-primária?', 
'É chave-primária?', 
'É chave-primária?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'105', 
'13', 
'70', 
'6', 
NULL, 
'IsAutoIncrement', 
'Coluna é autoincremento?', 
'É autoincremento?', 
'É autoincremento?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'106', 
'13', 
'75', 
'6', 
NULL, 
'IsRequired', 
'Coluna é requerida?', 
'É requerida?', 
'É requerida?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'107', 
'13', 
'80', 
'6', 
NULL, 
'IsListable', 
'Coluna é listável?', 
'É listável?', 
'É listável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'108', 
'13', 
'85', 
'6', 
NULL, 
'IsFilterable', 
'Coluna é filtrável?', 
'É filtrável?', 
'É filtrável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'109', 
'13', 
'90', 
'6', 
NULL, 
'IsEditable', 
'Coluna é editável?', 
'É editável?', 
'É editável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'110', 
'13', 
'95', 
'6', 
NULL, 
'IsBrowseable', 
'Coluna é navegável?', 
'É navegável?', 
'É navegável?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'111', 
'13', 
'100', 
'6', 
NULL, 
'IsEncrypted', 
'Coluna é encriptada?', 
'É encriptada?', 
'É encriptada?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'112', 
'13', 
'105', 
'6', 
NULL, 
'IsCalculated', 
'Coluna é calculada?', 
'É calculada?', 
'É calculada?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'113', 
'14', 
'5', 
'1', 
NULL, 
'Id', 
'ID do índice', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'114', 
'14', 
'10', 
'1', 
'8', 
'DatabaseId', 
'ID do banco-de-dados do índice', 
'Banco-de-dados', 
'Banco-de-dados', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'0', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'115', 
'14', 
'15', 
'1', 
'10', 
'TableId', 
'ID da tabela do índice', 
'Tabela', 
'Tabela', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'116', 
'14', 
'20', 
'10', 
NULL, 
'Name', 
'Nome do índice', 
'Nome', 
'Nome', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'117', 
'14', 
'25', 
'6', 
NULL, 
'IsUnique', 
'É índice único?', 
'É único?', 
'É único?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'118', 
'15', 
'5', 
'1', 
NULL, 
'Id', 
'ID da chave de índice', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'119', 
'15', 
'10', 
'1', 
'12', 
'IndexId', 
'ID do índice da chave', 
'Índice', 
'Índice', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'120', 
'15', 
'15', 
'4', 
NULL, 
'Sequence', 
'Sequência da chave', 
'Sequência', 
'Sequência', 
NULL, 
CAST('1' AS smallint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'121', 
'15', 
'20', 
'1', 
'11', 
'ColumnId', 
'ID da coluna-chave do índice', 
'Coluna', 
'Coluna', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'122', 
'15', 
'25', 
'6', 
NULL, 
'IsDescending', 
'Ordem descedente da chave?', 
'Descendente?', 
'Descendente?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'123', 
'16', 
'5', 
'1', 
NULL, 
'Id', 
'ID do Login de Acesso', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'124', 
'16', 
'10', 
'1', 
'4', 
'SystemId', 
'ID do Sistema', 
'Sistema', 
'Sistema', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'125', 
'16', 
'15', 
'1', 
'7', 
'UserId', 
'ID do usuário', 
'Usuário', 
'Usuário', 
NULL, 
CAST('1' AS bigint), 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'126', 
'16', 
'20', 
'11', 
NULL, 
'PublicKey', 
'Chave pública do usuário', 
'Chave pública', 
'Chave pública', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
'0', 
'0', 
'0', 
'1', 
'1', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'127', 
'16', 
'25', 
'6', 
NULL, 
'Logged', 
'Logado?', 
'Logado?', 
'Logado?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
'1', 
'1', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'128', 
'17', 
'5', 
'1', 
NULL, 
'Id', 
'ID  da Atualização', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'129', 
'17', 
'10', 
'1', 
'16', 
'LoginId', 
'ID do Login de Acesso', 
'Log de Acesso', 
'Log de Acesso', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'130', 
'17', 
'15', 
'1', 
'5', 
'SystemId', 
'ID do Sistema', 
'Sistema', 
'Sistema', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'131', 
'17', 
'20', 
'1', 
'9', 
'DatabaseId', 
'ID do Banco-de-dados', 
'Banco-de-dados', 
'Banco-de-dados', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'132', 
'17', 
'25', 
'6', 
NULL, 
'IsConfirmed', 
'Confirmado?', 
'Confirmado?', 
'Confirmado?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
'1', 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'133', 
'18', 
'5', 
'1', 
NULL, 
'Id', 
'ID  da Atualização', 
'ID', 
'ID', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'1', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'134', 
'18', 
'10', 
'1', 
'17', 
'TransactionId', 
'Id da Transação', 
'Transação', 
'Transação', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'135', 
'18', 
'15', 
'1', 
'11', 
'TableId', 
'Id da Tabela', 
'Tabela', 
'Tabela', 
NULL, 
CAST('1' AS bigint), 
NULL, 
'0', 
'0', 
'1', 
NULL, 
'1', 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'136', 
'18', 
'20', 
'7', 
NULL, 
'Action', 
'Ação de Atualização', 
'Ação', 
'Ação', 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
'1', 
'1', 
'0', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'137', 
'18', 
'25', 
'12', 
NULL, 
'LastRecord', 
'Registro Anterior', 
'Registro Anterior', 
'Registro Anterior', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
NULL, 
NULL, 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'138', 
'18', 
'30', 
'12', 
NULL, 
'ActualRecord', 
'Registro Atual', 
'Registro Atual', 
'Registro Atual', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'1', 
NULL, 
NULL, 
'0', 
'0', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Columns] (
[Id], 
[TableId], 
[Sequence], 
[DomainId], 
[ReferenceTableId], 
[Name], 
[Description], 
[Title], 
[Caption], 
[Default], 
[Minimum], 
[Maximum], 
[IsPrimarykey], 
[IsAutoIncrement], 
[IsRequired], 
[IsListable], 
[IsFilterable], 
[IsEditable], 
[IsBrowseable], 
[IsEncrypted], 
[IsCalculated], 
CreatedAt, CreatedBy) VALUES (
'139', 
'18', 
'35', 
'6', 
NULL, 
'IsConfirmed', 
'Confirmado?', 
'Confirmado?', 
'Confirmado?', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
'1', 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Columns
**********************************************************************************/
/**********************************************************************************
Criar tabela Indexes
**********************************************************************************/
IF (SELECT object_id('[dbo].[Indexes]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Indexes]
CREATE TABLE [dbo].[Indexes](
[Id] bigint NOT NULL,
[DatabaseId] bigint NOT NULL,
[TableId] bigint NOT NULL,
[Name] varchar(50) NOT NULL,
[IsUnique] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Indexes] ADD CONSTRAINT PK_Indexes PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Indexes_Database_Name] ON [dbo].[Indexes]([DatabaseId] ASC,[Name] ASC)
GO
/**********************************************************************************
Criar procedure IndexesCreate
**********************************************************************************/
IF(SELECT object_id('IndexesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure IndexesCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Name varchar(50) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(50)),
@W_IsUnique bit = CAST(JSON_VALUE(@Record, '$.IsUnique') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsUnique IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsUnique é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Indexes.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [DatabaseId] = @W_DatabaseId
 AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Indexes_Database_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Indexes] (
[Id],
[DatabaseId],
[TableId],
[Name],
[IsUnique],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_DatabaseId,
@W_TableId,
@W_Name,
@W_IsUnique,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure IndexesUpdate
**********************************************************************************/
IF(SELECT object_id('IndexesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_DatabaseId bigint = CAST(JSON_VALUE(@Record, '$.DatabaseId') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Name varchar(50) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(50)),
@W_IsUnique bit = CAST(JSON_VALUE(@Record, '$.IsUnique') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @DatabaseId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsUnique IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsUnique é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexes.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE NOT (Id = @W_Id
) AND [DatabaseId] = @W_DatabaseId
AND [Name] = @W_Name
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Indexes_Database_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Indexes] SET
[DatabaseId] = @W_DatabaseId,
[TableId] = @W_TableId,
[Name] = @W_Name,
[IsUnique] = @W_IsUnique,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure IndexesDelete
**********************************************************************************/
IF(SELECT object_id('IndexesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure IndexesDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexes.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Indexes]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure IndexesRead
**********************************************************************************/
IF(SELECT object_id('IndexesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure IndexesRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_TableId bigint = CAST(JSON_VALUE(@Record, '$.TableId') AS bigint),
@W_Name varchar(50) = CAST(JSON_VALUE(@Record, '$.Name') AS varchar(50)),
@W_IsUnique bit = CAST(JSON_VALUE(@Record, '$.IsUnique') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NOT NULL AND @W_TableId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NOT NULL AND @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Indexes', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.DatabaseId') AS bigint) AS [DatabaseId]
,CAST(JSON_VALUE([Record], '$.TableId') AS bigint) AS [TableId]
,CAST(JSON_VALUE([Record], '$.Name') AS varchar(50)) AS [Name]
,CAST(JSON_VALUE([Record], '$.IsUnique') AS bit) AS [IsUnique]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[DatabaseId]
,[tab].[TableId]
,[tab].[Name]
,[tab].[IsUnique]
INTO[dbo].[#tab]
FROM[dbo].[Indexes] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[TableId] = ISNULL(@W_TableId, [tab].[TableId])
AND [tab].[Name] = ISNULL(@W_Name, [tab].[Name])
AND [tab].[IsUnique] = ISNULL(@W_IsUnique, [tab].[IsUnique])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[DatabaseId]
,[TableId]
,[Name]
,[IsUnique]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[DatabaseId] = [tmp].[DatabaseId]
,[tab].[TableId] = [tmp].[TableId]
,[tab].[Name] = [tmp].[Name]
,[tab].[IsUnique] = [tmp].[IsUnique]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordIndex' AS [ClassName],
[tab].[Id]
,[tab].[DatabaseId]
,[tab].[TableId]
,[tab].[Name]
,[tab].[IsUnique]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Indexes
**********************************************************************************/
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'1', 
'UNQ_Categories_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'2', 
'1', 
'2', 
'UNQ_Types_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'3', 
'1', 
'3', 
'UNQ_Masks_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'4', 
'1', 
'4', 
'UNQ_Domains_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'5', 
'1', 
'5', 
'UNQ_Systems_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'6', 
'1', 
'6', 
'UNQ_Menus_System_Sequence', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'7', 
'1', 
'7', 
'UNQ_Users_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'8', 
'1', 
'8', 
'UNQ_SystemsUsers_System_User', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'9', 
'1', 
'8', 
'UNQ_SystemsUsers_Description', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'10', 
'1', 
'9', 
'UNQ_Databases_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'11', 
'1', 
'9', 
'UNQ_Databases_Alias', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'12', 
'1', 
'10', 
'UNQ_SystemsDatabases_System_Database', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'13', 
'1', 
'10', 
'UNQ_SystemsDatabases_Description', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'14', 
'1', 
'11', 
'UNQ_Tables_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'15', 
'1', 
'11', 
'UNQ_Tables_Alias', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'16', 
'1', 
'12', 
'UNQ_DatabasesTables_Database_Table', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'17', 
'1', 
'12', 
'UNQ_DatabasesTables_Description', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'18', 
'1', 
'13', 
'UNQ_Columns_Table_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'19', 
'1', 
'13', 
'UNQ_Columns_Table_Sequence', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'20', 
'1', 
'14', 
'UNQ_Indexes_Database_Name', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'21', 
'1', 
'15', 
'UNQ_Indexkeys_Index_Sequence', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'22', 
'1', 
'15', 
'UNQ_Indexkeys_Index_Column', 
'1', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'23', 
'1', 
'16', 
'UNQ_Logs_System_User_Logged', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt, CreatedBy) VALUES (
'24', 
'1', 
'17', 
'UNQ_Transactions_Log_Table_Primarykey', 
'0', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Indexes
**********************************************************************************/
/**********************************************************************************
Criar tabela Indexkeys
**********************************************************************************/
IF (SELECT object_id('[dbo].[Indexkeys]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Indexkeys]
CREATE TABLE [dbo].[Indexkeys](
[Id] bigint NOT NULL,
[IndexId] bigint NOT NULL,
[Sequence] smallint NOT NULL,
[ColumnId] bigint NOT NULL,
[IsDescending] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Indexkeys] ADD CONSTRAINT PK_Indexkeys PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Indexkeys_Index_Sequence] ON [dbo].[Indexkeys]([IndexId] ASC,[Sequence] ASC)
CREATE UNIQUE INDEX [UNQ_Indexkeys_Index_Column] ON [dbo].[Indexkeys]([IndexId] ASC,[ColumnId] ASC)
GO
/**********************************************************************************
Criar procedure IndexkeysCreate
**********************************************************************************/
IF(SELECT object_id('IndexkeysCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexkeysCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure IndexkeysCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_IndexId bigint = CAST(JSON_VALUE(@Record, '$.IndexId') AS bigint),
@W_Sequence smallint = CAST(JSON_VALUE(@Record, '$.Sequence') AS smallint),
@W_ColumnId bigint = CAST(JSON_VALUE(@Record, '$.ColumnId') AS bigint),
@W_IsDescending bit = CAST(JSON_VALUE(@Record, '$.IsDescending') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence < CAST('1' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsDescending IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsDescending é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Indexkeys.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId
 AND [Sequence] = @W_Sequence
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Indexkeys_Index_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId
 AND [ColumnId] = @W_ColumnId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Indexkeys_Index_Column já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Indexkeys] (
[Id],
[IndexId],
[Sequence],
[ColumnId],
[IsDescending],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_IndexId,
@W_Sequence,
@W_ColumnId,
@W_IsDescending,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure IndexkeysUpdate
**********************************************************************************/
IF(SELECT object_id('IndexkeysUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexkeysUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_IndexId bigint = CAST(JSON_VALUE(@Record, '$.IndexId') AS bigint),
@W_Sequence smallint = CAST(JSON_VALUE(@Record, '$.Sequence') AS smallint),
@W_ColumnId bigint = CAST(JSON_VALUE(@Record, '$.ColumnId') AS bigint),
@W_IsDescending bit = CAST(JSON_VALUE(@Record, '$.IsDescending') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence < CAST('1' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence > CAST('32767' AS smallint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsDescending IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IsDescending é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexkeys.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE NOT (Id = @W_Id
) AND [IndexId] = @W_IndexId
AND [Sequence] = @W_Sequence
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Indexkeys_Index_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE NOT (Id = @W_Id
) AND [IndexId] = @W_IndexId
AND [ColumnId] = @W_ColumnId
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Indexkeys_Index_Column já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Indexkeys] SET
[IndexId] = @W_IndexId,
[Sequence] = @W_Sequence,
[ColumnId] = @W_ColumnId,
[IsDescending] = @W_IsDescending,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure IndexkeysDelete
**********************************************************************************/
IF(SELECT object_id('IndexkeysDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexkeysDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysDelete](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure IndexkeysDelete: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexkeys.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Indexkeys]
WHERE Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure IndexkeysRead
**********************************************************************************/
IF(SELECT object_id('IndexkeysRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexkeysRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysRead](
@PageNumber INT OUT,
@LimitRows BIGINT OUT,
@MaxPage INT OUT,
@PaddingGridLastPage BIT OUT,
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure IndexkeysRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@offset INT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_IndexId bigint = CAST(JSON_VALUE(@Record, '$.IndexId') AS bigint),
@W_ColumnId bigint = CAST(JSON_VALUE(@Record, '$.ColumnId') AS bigint),
@W_IsDescending bit = CAST(JSON_VALUE(@Record, '$.IsDescending') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId IS NOT NULL AND @W_IndexId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IndexId IS NOT NULL AND @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @IndexId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId IS NOT NULL AND @W_ColumnId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ColumnId IS NOT NULL AND @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @ColumnId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Indexkeys', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.IndexId') AS bigint) AS [IndexId]
,CAST(JSON_VALUE([Record], '$.Sequence') AS smallint) AS [Sequence]
,CAST(JSON_VALUE([Record], '$.ColumnId') AS bigint) AS [ColumnId]
,CAST(JSON_VALUE([Record], '$.IsDescending') AS bit) AS [IsDescending]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[IndexId]
,[tab].[Sequence]
,[tab].[ColumnId]
,[tab].[IsDescending]
INTO[dbo].[#tab]
FROM[dbo].[Indexkeys] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[IndexId] = ISNULL(@W_IndexId, [tab].[IndexId])
AND [tab].[ColumnId] = ISNULL(@W_ColumnId, [tab].[ColumnId])
AND [tab].[IsDescending] = ISNULL(@W_IsDescending, [tab].[IsDescending])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[IndexId]
,[Sequence]
,[ColumnId]
,[IsDescending]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[IndexId] = [tmp].[IndexId]
,[tab].[Sequence] = [tmp].[Sequence]
,[tab].[ColumnId] = [tmp].[ColumnId]
,[tab].[IsDescending] = [tmp].[IsDescending]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
IF @ROWCOUNT = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
SET @offset = 0
SET @LimitRows = CASE WHEN @ROWCOUNT = 0 THEN 1 ELSE @ROWCOUNT END
SET @PageNumber = 1
SET @MaxPage = 1
END ELSE BEGIN
SET @MaxPage = @ROWCOUNT / @LimitRows + CASE WHEN @ROWCOUNT % @LimitRows = 0 THEN 0 ELSE 1 END
IF ABS(@PageNumber) > @MaxPage
SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
IF @PageNumber < 0
SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
SET @offset = (@PageNumber - 1) * @LimitRows
IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @ROWCOUNT
SET @offset = CASE WHEN @ROWCOUNT > @LimitRows THEN @ROWCOUNT -@LimitRows ELSE 0 END
END
SELECT 'RecordIndexkey' AS [ClassName],
[tab].[Id]
,[tab].[IndexId]
,[tab].[Sequence]
,[tab].[ColumnId]
,[tab].[IsDescending]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
OFFSET @offset ROWS
FETCH NEXT @LimitRows ROWS ONLY
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Indexkeys
**********************************************************************************/
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'1', 
'1', 
'5', 
'2', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'2', 
'2', 
'5', 
'13', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'3', 
'3', 
'5', 
'27', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'4', 
'4', 
'5', 
'32', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'5', 
'5', 
'5', 
'41', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'6', 
'6', 
'5', 
'46', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'7', 
'6', 
'10', 
'47', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'8', 
'7', 
'5', 
'53', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'9', 
'8', 
'5', 
'59', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'10', 
'8', 
'10', 
'60', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'11', 
'9', 
'5', 
'61', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'12', 
'10', 
'5', 
'63', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'13', 
'11', 
'5', 
'65', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'14', 
'12', 
'5', 
'73', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'15', 
'12', 
'10', 
'74', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'16', 
'13', 
'5', 
'75', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'17', 
'14', 
'5', 
'77', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'18', 
'15', 
'5', 
'78', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'19', 
'16', 
'5', 
'89', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'20', 
'16', 
'10', 
'90', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'21', 
'17', 
'5', 
'91', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'22', 
'18', 
'5', 
'93', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'23', 
'18', 
'10', 
'97', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'24', 
'19', 
'5', 
'93', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'25', 
'19', 
'10', 
'94', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'26', 
'20', 
'5', 
'114', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'27', 
'20', 
'10', 
'116', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'28', 
'21', 
'5', 
'119', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'29', 
'21', 
'10', 
'120', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'30', 
'22', 
'5', 
'119', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'31', 
'22', 
'10', 
'121', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'32', 
'23', 
'5', 
'124', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'33', 
'23', 
'10', 
'125', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'34', 
'23', 
'15', 
'126', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'35', 
'24', 
'5', 
'129', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'36', 
'24', 
'10', 
'130', 
'0', 
GETDATE(), 'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt, CreatedBy) VALUES (
'37', 
'24', 
'15', 
'131', 
'0', 
GETDATE(), 'adm')
GO
/**********************************************************************************
Final da criação dos scripts da tabela Indexkeys
**********************************************************************************/
/**********************************************************************************
Criar tabela Logins
**********************************************************************************/
IF (SELECT object_id('[dbo].[Logins]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Logins]
CREATE TABLE [dbo].[Logins](
[Id] bigint NOT NULL,
[SystemId] bigint NOT NULL,
[UserId] bigint NOT NULL,
[PublicKey] varchar(256) NOT NULL,
[Logged] bit NOT NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Logins] ADD CONSTRAINT PK_Logins PRIMARY KEY CLUSTERED ([Id])
CREATE INDEX [UNQ_Logs_System_User_Logged] ON [dbo].[Logins]([SystemId] ASC,[UserId] ASC,[PublicKey] ASC)
GO
/**********************************************************************************
Criar procedure LoginsCreate
**********************************************************************************/
IF(SELECT object_id('LoginsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[LoginsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[LoginsCreate](
@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
) AS BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure LoginsCreate: ',
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_UserId bigint = CAST(JSON_VALUE(@Record, '$.UserId') AS bigint),
@W_PublicKey varchar(256) = CAST(JSON_VALUE(@Record, '$.PublicKey') AS varchar(256)),
@W_Logged bit = CAST(JSON_VALUE(@Record, '$.Logged') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_PublicKey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @PublicKey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_PublicKey < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @PublicKey deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Logged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Logged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Logins] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Logins.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Logins] (
[Id],
[SystemId],
[UserId],
[PublicKey],
[Logged],
[CreatedBy],
[CreatedAt])
VALUES (
@W_Id,
@W_SystemId,
@W_UserId,
@W_PublicKey,
@W_Logged,
@UserName,
GETDATE())
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure LoginsUpdate
**********************************************************************************/
IF(SELECT object_id('LoginsUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[LoginsUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[LoginsUpdate](
@TransactionId BIGINT
) AS BEGIN
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
,@UserName VARCHAR(25)
,@Record VARCHAR(MAX)
SELECT @UserName = [UserName]
,@Record = [Record]
,@ErrorMessage = ISNULL([ErrorMessage], @ErrorMessage)
FROM [dbo].[TransactionsRead](@TransactionId, 'update')
 IF @ErrorMessage IS NULL
THROW 51000, @ErrorMessage, 1
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DECLARE @W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_UserId bigint = CAST(JSON_VALUE(@Record, '$.UserId') AS bigint),
@W_PublicKey varchar(256) = CAST(JSON_VALUE(@Record, '$.PublicKey') AS varchar(256)),
@W_Logged bit = CAST(JSON_VALUE(@Record, '$.Logged') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_PublicKey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @PublicKey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_PublicKey < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @PublicKey deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Logged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Logged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Logins] WHERE Id = @W_Id
) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Logins.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Logins] SET
[SystemId] = @W_SystemId,
[UserId] = @W_UserId,
[PublicKey] = @W_PublicKey,
[Logged] = @W_Logged,
[UpdatedAt] = GETDATE()
WHERE 
Id = @W_Id
RETURN @@ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure LoginsRead
**********************************************************************************/
IF(SELECT object_id('LoginsRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[LoginsRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[LoginsRead](
@UserName VARCHAR(25),
@Record VARCHAR(MAX)) AS BEGIN
BEGIN TRY
DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure LoginsRead: ',
@ROWCOUNT BIGINT,
@LogId BIGINT,
@TableId BIGINT,
@W_Id bigint = CAST(JSON_VALUE(@Record, '$.Id') AS bigint),
@W_SystemId bigint = CAST(JSON_VALUE(@Record, '$.SystemId') AS bigint),
@W_UserId bigint = CAST(JSON_VALUE(@Record, '$.UserId') AS bigint),
@W_Logged bit = CAST(JSON_VALUE(@Record, '$.Logged') AS bit)
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_SystemId IS NOT NULL AND @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @SystemId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NOT NULL AND @W_UserId < CAST('1' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NOT NULL AND @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @UserId deve ser menor que ou igual à ''9007199254740990''.';
THROW 51000, @ErrorMessage, 1
END
SELECT @LogId = [LogId],
@TableId = [TableId],
@ErrorMessage = [ErrorMessage]
FROM [dbo].[TransactionsActions]('cruda', 'cruda', 'Logins', @UserName, 'create')
IF @ErrorMessage IS NOT NULL
THROW 51000, @ErrorMessage, 1
SELECT [Action] AS [_]
,CAST(JSON_VALUE([Record], '$.Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([Record], '$.SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([Record], '$.UserId') AS bigint) AS [UserId]
,CAST(JSON_VALUE([Record], '$.PublicKey') AS varchar(256)) AS [PublicKey]
,CAST(JSON_VALUE([Record], '$.Logged') AS bit) AS [Logged]
INTO [dbo].[#tmp]
FROM [dbo].[Transactions]
WHERE [LogId] = @LogId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
SELECT 
[tab].[Id]
,[tab].[SystemId]
,[tab].[UserId]
,[tab].[PublicKey]
,[tab].[Logged]
INTO[dbo].[#tab]
FROM[dbo].[Logins] [tab]
WHERE [tab].[Id] = ISNULL(@W_Id, [tab].[Id])
AND [tab].[SystemId] = ISNULL(@W_SystemId, [tab].[SystemId])
AND [tab].[UserId] = ISNULL(@W_UserId, [tab].[UserId])
AND [tab].[Logged] = ISNULL(@W_Logged, [tab].[Logged])
ORDER BY [tab].[Id]
SET @ROWCOUNT = @@ROWCOUNT
DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
AND [tmp].[Id] = [tab].[Id])
SET @ROWCOUNT = @ROWCOUNT - @@ROWCOUNT
INSERT [dbo].[#tab] SELECT 
[Id]
,[SystemId]
,[UserId]
,[PublicKey]
,[Logged]
FROM [dbo].[#tmp]
WHERE [_] = 'create'
SET @ROWCOUNT = @ROWCOUNT + @@ROWCOUNT
UPDATE [tab] SET
[tab].[Id] = [tmp].[Id]
,[tab].[SystemId] = [tmp].[SystemId]
,[tab].[UserId] = [tmp].[UserId]
,[tab].[PublicKey] = [tmp].[PublicKey]
,[tab].[Logged] = [tmp].[Logged]
FROM [dbo].[#tab] [tab], [dbo].[#tmp] [tmp]
WHERE [tmp].[_] = 'update' 
AND [tmp].[Id] = [tab].[Id]
SELECT 'RecordLogin' AS [ClassName],
[tab].[Id]
,[tab].[SystemId]
,[tab].[UserId]
,[tab].[PublicKey]
,[tab].[Logged]
FROM[dbo].[#tab] [tab]
ORDER BY [tab].[Id]
RETURN @ROWCOUNT
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Inserir dados na tabela Logins
**********************************************************************************/
GO
/**********************************************************************************
Final da criação dos scripts da tabela Logins
**********************************************************************************/
/**********************************************************************************
Criar tabela Transactions
**********************************************************************************/
IF (SELECT object_id('[dbo].[Transactions]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Transactions]
CREATE TABLE [dbo].[Transactions](
[Id] bigint NOT NULL,
[LoginId] bigint NOT NULL,
[SystemId] bigint NOT NULL,
[DatabaseId] bigint NOT NULL,
[IsConfirmed] bit NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Transactions] ADD CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED ([Id])
CREATE INDEX [UNQ_Transactions_Log_Table_Primarykey] ON [dbo].[Transactions]([LoginId] ASC,[SystemId] ASC,[DatabaseId] ASC)
GO
/**********************************************************************************
Inserir dados na tabela Transactions
**********************************************************************************/
GO
/**********************************************************************************
Final da criação dos scripts da tabela Transactions
**********************************************************************************/
/**********************************************************************************
Criar tabela Operations
**********************************************************************************/
IF (SELECT object_id('[dbo].[Operations]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Operations]
CREATE TABLE [dbo].[Operations](
[Id] bigint NOT NULL,
[TransactionId] bigint NOT NULL,
[TableId] bigint NOT NULL,
[Action] varchar(15) NOT NULL,
[LastRecord] varchar(MAX) NULL,
[ActualRecord] varchar(MAX) NOT NULL,
[IsConfirmed] bit NULL,
[CreatedAt] [datetime] NULL,
[CreatedBy] [varchar](25) NULL,
[UpdatedAt] [datetime] NULL,
[UpdatedBy] [varchar](25) NULL)
ALTER TABLE [dbo].[Operations] ADD CONSTRAINT PK_Operations PRIMARY KEY CLUSTERED ([Id])
GO
/**********************************************************************************
Inserir dados na tabela Operations
**********************************************************************************/
GO
/**********************************************************************************
Final da criação dos scripts da tabela Operations
**********************************************************************************/
/**********************************************************************************
Criar stored procedure Config
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [dbo].[Config] 'cruda','all',null
IF(SELECT object_id('[dbo].[Config]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[Config] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[Config](@SystemName VARCHAR(25),
							   @DatabaseName VARCHAR(25) = NULL,
							   @TableName VARCHAR(25) = NULL) AS
BEGIN
	DECLARE @ErrorMessage VARCHAR(50)

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRY
		-- 0 [Systems]
		SELECT 	'RecordSystem' AS [ClassName]
				,[Id]
				,[Name]
				,[Description]
				,[ClientName]
			INTO [dbo].[#Systems]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema "' + @SystemName + '" não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @DatabaseName IS NULL
			RETURN
		ALTER TABLE [dbo].[#Systems] ADD PRIMARY KEY CLUSTERED([Id])
		IF @DatabaseName = 'all' BEGIN
			SET @DatabaseName = NULL
			SET @TableName = NULL
		END

		-- 1 [Databases]
		SELECT 	'RecordDatabase' AS [ClassName]
				,[D].[Id]
				,[D].[Name]
				,[D].[Description]
				,[D].[Alias]
				,[D].[ServerName]
				,[D].[HostName]
				,[D].[Port]
				,[D].[Logon]
				,[D].[Password]
				,[D].[Folder]
			INTO [dbo].[#Databases]
			FROM [dbo].[Databases] [D]
				INNER JOIN [dbo].[SystemsDatabases] [SD] ON [SD].[DatabaseId] = [D].[id]
				INNER JOIN [dbo].[#Systems] [S] ON [S].[Id] = [SD].[SystemId]
			WHERE [D].[Name] = ISNULL(@DatabaseName, [D].[Name])
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Banco(s)-de-dados não cadastrado(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Databases] ADD PRIMARY KEY CLUSTERED([Id])

		-- 2 [Tables]
		SELECT	'RecordTable' AS [ClassName]
				,[T].[Id]
				,[DT].[DatabaseId]
				,[T].[Name]
				,[T].[Alias]
				,[T].[Description]
				,[T].[ParentTableId]
				,[T].[ProcedureCreate]
				,[T].[ProcedureRead]
				,[T].[ProcedureUpdate]
				,[T].[ProcedureDelete]
				,[T].[ProcedureList]
				,[T].[IsPaged]
			INTO [dbo].[#Tables]
			FROM [dbo].[Tables] [T]
				INNER JOIN [dbo].[DatabasesTables] [DT] ON [DT].[TableId] = [T].[Id]
				INNER JOIN [dbo].[#Databases] [D] ON [D].[Id] = [DT].[DatabaseId]
			WHERE [T].[Name] = ISNULL(@TableName, [T].[Name])
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Tabela(s) não cadastrada(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Tables] ADD PRIMARY KEY CLUSTERED([Id])

		IF @DatabaseName IS NULL BEGIN
			-- 3 [Columns]
			SELECT	'RecordColumn' AS [ClassName]
					,[C].[Id]
					,[C].[TableId]
					,[C].[Sequence]
					,[C].[DomainId]
					,[C].[ReferenceTableId]
					,[C].[Name]
					,[C].[Description]
					,[C].[Title]
					,[C].[Caption]
				    ,[C].[Default]
				    ,[C].[Minimum]
				    ,[C].[Maximum]
					,[C].[IsPrimarykey]
					,[C].[IsAutoIncrement]
					,[C].[IsRequired]
					,[C].[IsListable]
					,[C].[IsFilterable]
					,[C].[IsEditable]
					,[C].[IsBrowseable]			
					,[C].[IsEncrypted]
				INTO [dbo].[#Columns]
				FROM [dbo].[Columns] [C]
					INNER JOIN [dbo].[#Tables] [T] ON [T].[Id]= [C].[TableId] 
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Colunas não cadastradas.';
				THROW 51000, @ErrorMessage, 1
			END
			ALTER TABLE [dbo].[#Columns] ADD PRIMARY KEY CLUSTERED([Id])
			CREATE INDEX [#ColumnsDomainId] ON [dbo].[#Columns]([DomainId])

			-- 4 [Domains]
			SELECT	'RecordDomain' AS [ClassName]
					,[D].[Id]
					,[D].[TypeId]
					,[D].[MaskId]
					,[D].[Name]
					,[D].[Length]
					,[D].[Decimals]
					,[D].[ValidValues]
					,[D].[Default]
					,[D].[Minimum]
					,[D].[Maximum]
					,[D].[Codification]
				INTO [dbo].[#Domains]
				FROM [dbo].[Domains] [D]
				WHERE EXISTS(SELECT TOP 1 1 FROM [dbo].[#Columns] WHERE [DomainId] = [D].[Id])
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Domínios não cadastrados.';
				THROW 51000, @ErrorMessage, 1
			END
			ALTER TABLE [dbo].[#Domains] ADD PRIMARY KEY NONCLUSTERED([Id])
			CREATE INDEX [#DomainsTypeId] ON [dbo].[#Domains]([TypeId])

			-- 5 [Types]
			SELECT 	'RecordType' AS [ClassName]
					,[T].[Id]
					,[T].[CategoryId]
					,[T].[Name]
				    ,[T].[Minimum]
					,[T].[Maximum]
					,[T].[AskLength]
					,[T].[AskDecimals]
					,[T].[AskPrimarykey]
					,[T].[AskAutoincrement]
					,[T].[AskFilterable]
					,[T].[AskBrowseable]
					,[T].[AskCodification]
					,[T].[AskFormula]
					,[T].[AllowMaxLength]
					,[T].[IsActive]
				INTO [dbo].[#Types]
				FROM [dbo].[Types] [T]
				WHERE EXISTS(SELECT TOP 1 1 FROM [dbo].[#Domains] WHERE [TypeId] = [T].[Id])
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Tipos não cadastrados.';
				THROW 51000, @ErrorMessage, 1
			END
			CREATE INDEX [#TypesCategoryId] ON [dbo].[#Types]([CategoryId])

			-- 6 [Categories]
			SELECT 	'RecordCategory' AS [ClassName]
					,[C].[Id]
					,[C].[Name]
					,[C].[HtmlInputType]
					,[C].[HtmlInputAlign]
					,[C].[AskEncrypted]
					,[C].[AskMask]
					,[C].[AskListable]
					,[C].[AskDefault]
					,[C].[AskMinimum]
					,[C].[AskMaximum]
				INTO [dbo].[#Categories]
				FROM [dbo].[Categories] [C]
				WHERE EXISTS(SELECT TOP 1 1 FROM [dbo].[#Types] WHERE [CategoryId] = [C].[Id])
			IF @@ROWCOUNT = 0 BEGIN
			   SET @ErrorMessage = 'Categoria(s) não cadastrada(s).';
			   THROW 51000, @ErrorMessage, 1
			END

			-- 7 [Menus]
			SELECT 	'RecordMenu' AS [ClassName]
					,[M].[Id]
					,[M].[SystemId]
					,[M].[Sequence]
					,[M].[Caption]
					,[M].[Message]
					,[M].[Action]
					,[M].[ParentMenuId]
				INTO [dbo].[#Menus]
				FROM [dbo].[Menus] [M]
					INNER JOIN [dbo].[#Systems] [S] ON [S].[Id] = [M].[SystemId]
			IF @@ROWCOUNT = 0 BEGIN
			   SET @ErrorMessage = 'Menu(s) não cadastrado(s).';
			   THROW 51000, @ErrorMessage, 1
			END

			-- 8 [Indexes]
			SELECT 	'RecordIndex' AS [ClassName]
					,[I].[Id]
					,[I].[TableId]
					,[I].[Name]
					,[I].[IsUnique]
				INTO [dbo].[#Indexes]
				FROM [dbo].[Indexes] [I]
					INNER JOIN [dbo].[#Tables] [T] ON [T].[Id] = [I].[TableId]
			ALTER TABLE [dbo].[#Indexes] ADD PRIMARY KEY NONCLUSTERED([Id])

			-- 9 [Indexkeys]
			SELECT 	'RecordIndexkey' AS [ClassName]
					,[IK].[Id]
					,[IK].[IndexId]
					,[IK].[Sequence]
					,[IK].[ColumnId]
					,[IK].[IsDescending]
				INTO [dbo].[#Indexkeys]
				FROM [dbo].[Indexkeys] [IK]
					INNER JOIN [dbo].[#Indexes] [I] ON [I].[Id] = [IK].IndexId
			-- 10 [Masks]
			SELECT 	'RecordMask' AS [ClassName]
					,[M].[Id]
					,[M].[Name]
					,[M].[Mask]
				INTO [dbo].[#Masks]
				FROM [dbo].[Masks] [M]
				WHERE EXISTS(SELECT TOP 1 1 FROM [dbo].[#Domains] WHERE [MaskId] = [M].[Id])
		END

		-- Results
		SELECT * FROM [dbo].[#Systems] ORDER BY [Name] -- 0 [#Systems]
		IF @DatabaseName IS NULL BEGIN
			SELECT [ClassName] -- 1 [#Databases]
					,[Id]
					,[Name]
					,[Description]
					,[Alias]
				FROM [dbo].[#Databases] 
				ORDER BY [Name]
			SELECT * FROM [dbo].[#Tables] ORDER BY [DatabaseId], [Name] -- 2 [#Tables]
			SELECT * FROM [dbo].[#Columns] ORDER BY [TableId], [Sequence] -- 3 [#Columns]
			SELECT * FROM [dbo].[#Domains] ORDER BY [Name] -- 4 [#Domains]
			SELECT * FROM [dbo].[#Types] ORDER BY [Name] -- 5 [#Types]
			SELECT * FROM [dbo].[#Categories] ORDER BY [Name] -- 6 [#Categories]
			SELECT * FROM [dbo].[#Menus] ORDER BY [SystemId], [Sequence] -- 7 [#Menus]
			SELECT * FROM [dbo].[#Indexes] ORDER BY [Name] -- 8 [#Indexes]
			SELECT * FROM [dbo].[#Indexkeys] ORDER BY [IndexId], [Sequence] -- 9 [#Indexkeys]
			SELECT * FROM [dbo].[#Masks] ORDER BY [Id] -- 10 [#Masks]
		END ELSE BEGIN
			SELECT * FROM [dbo].[#Databases] ORDER BY [Name] -- 1 [#Databases]
			SELECT * FROM [dbo].[#Tables] ORDER BY [DatabaseId], [Name] -- 2 [#Tables]
		END

		RETURN CAST(1 AS BIT)
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar stored procedure GenerateId
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[GenerateId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GenerateId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[GenerateId](@SystemName VARCHAR(25),
								   @DatabaseName VARCHAR(25),
								   @TableName VARCHAR(25)) AS
BEGIN 
	DECLARE @SystemId BIGINT,
			@DatabaseId BIGINT,
			@TableId BIGINT,
			@Next_Id BIGINT,
			@ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @IsNewTransaction BIT = 0
	
	IF @@TRANCOUNT = 0 BEGIN
		BEGIN TRANSACTION GenerateIdTransaction
		SET @IsNewTransaction = 1
	END ELSE
		SAVE TRANSACTION GenerateIdTransaction

	BEGIN TRY
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema ' + @SystemName + ' não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END

		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados ' + @DatabaseName + ' não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END

		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
								AND [DatabaseId] = @DatabaseId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados ' + @DatabaseName + ' não pertence ao sistema ' + @SystemName + '.';
			THROW 51000, @ErrorMessage, 1
		END

		SELECT @TableId = [Id]
			FROM [dbo].[Tables]
			WHERE [Name] = @TableName
		IF @TableId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela ' + @TableName + ' não encontrada.';
			THROW 51000, @ErrorMessage, 1
		END

		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
								AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela ' + @TableName + 'não pertence ao banco-de-dados ' + @DatabaseName + '.';
			THROW 51000, @ErrorMessage, 1
		END

		SET @Next_Id = (SELECT [LastId] + 1
							FROM [dbo].[Tables]
							WHERE [Id] = @TableId)
		UPDATE [dbo].[Tables] 
			SET [LastId] = @Next_Id
			WHERE [Id] = @TableId

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @IsNewTransaction = 0
			ROLLBACK TRANSACTION GenerateIdTransaction
		ELSE
			ROLLBACK TRANSACTION
		THROW
	END CATCH
	COMMIT TRANSACTION

	RETURN @Next_Id
END
GO
/**********************************************************************************
Criar stored procedure Login
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[Login] 'cruda','labrego','diva','authenticate'
IF(SELECT object_id('[dbo].[Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[Login](@SystemName VARCHAR(25)
							 ,@UserName VARCHAR(25)
							 ,@Password VARCHAR(256)
							 ,@Action VARCHAR(15) = 'authenticate') AS
BEGIN
	DECLARE @SystemId BIGINT,
			@UserId BIGINT,
			@UserPassword VARCHAR(256),
			@ErrorMessage VARCHAR(100),
			@MaxRetryLogins TINYINT,
			@RetryLogins TINYINT,
			@IsActive BIT,
			@LogId BIGINT

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRY
		-- 0 [Systems]
		SELECT 	@SystemId = [Id]
				,@MaxRetryLogins = [MaxRetryLogins]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END

		-- 1 [Users]
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@UserPassword = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Usuário não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END

		IF CAST(@UserPassword AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = [RetryLogins] + 1
				WHERE [Id] = @UserId 
						AND @RetryLogins < @MaxRetryLogins
			SET @ErrorMessage = 'Senha inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário inativo.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário bloqueado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE	[UserId] =  @UserId
								AND [SystemId] = @SystemId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado.';
			THROW 51000, @ErrorMessage, 1
		END
		
		SELECT @LogId = [Id]
			FROM [dbo].[Logins]
			WHERE [SystemId] = @SystemId
				  AND [UserId] = @UserId
				  AND [Logged] = 1
		IF @LogId IS NULL BEGIN
			IF @action = 'login' BEGIN
				EXEC @LogId = [dbo].[GenerateId] 'cruda', 'cruda', 'Logs'

				INSERT [dbo].[Logins]([Id],
									[SystemId],
									[UserId],
									[Logged],
									[CreatedAt],
									[CreatedBy])
							VALUES (@LogId,
									@SystemId,
									@UserId,
									1,
									GETDATE(),
									@UserName)
			END ELSE IF @action <> 'logout' BEGIN
				SET @ErrorMessage = 'Instância do sistema foi encerrada.';
				THROW 51000, @ErrorMessage, 1
			END
		END ELSE IF @action = 'login' BEGIN
			SET @ErrorMessage = 'Usuário já tem uma instância do sistema em execução.';
			THROW 51000, @ErrorMessage, 1
		END ELSE IF @action = 'logout' BEGIN
			UPDATE [dbo].[Logins]
				SET [Logged] = 0,
					[UpdatedAt] = GETDATE(),
					[UpdatedBy] = @UserName
				WHERE [Id] = @LogId
			RETURN @LogId
		END ELSE IF @action <> 'authenticate' BEGIN
			SET @ErrorMessage = 'Valor inválido para o parâmetro @Action.';
			THROW 51000, @ErrorMessage, 1
		END
		UPDATE [dbo].[Users] 
			SET [RetryLogins] = 0
			WHERE [Id] = @UserId

		SELECT [Id]
				,[Name]
				,[FullName]
			FROM [dbo].[Users] 
			WHERE [Id] = @UserId

		RETURN @LogId
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar stored function NumberInWordsOfHundreds
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[NumberInWordsOfHundreds]', 'P')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[NumberInWordsOfHundreds]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [dbo].[NumberInWordsOfHundreds](@Value AS DECIMAL(18),
												@PortugueseOrEnglish BIT = 0)
RETURNS VARCHAR(MAX) AS  
BEGIN 
	DECLARE @ThirdDigit INT = @Value / 100,
			@SecondDigit INT = @Value / 10 % 10,
			@FirstDigit INT = @Value % 10,
			@And VARCHAR(10),
			@Result VARCHAR(MAX) = ''
	DECLARE @Units TABLE (Id INT, Nome VARCHAR(50))
	DECLARE @Dozens TABLE (Id INT, Nome VARCHAR(50))
	DECLARE @Hundreds TABLE (Id INT, Nome VARCHAR(50))

	IF @PortugueseOrEnglish = 1 BEGIN
		SET @And = ' e '
		INSERT @Units
			VALUES(0, ''),
				  (1, 'Um'),
				  (2, 'Dois'),
				  (3, 'Três'),
				  (4, 'Quatro'),
				  (5, 'Cinco'),
				  (6, 'Seis'),
				  (7, 'Sete'),
				  (8, 'Oito'),
				  (9, 'Nove'),
				  (10, 'Dez'),
				  (11, 'Onze'),
				  (12, 'Doze'),
				  (13, 'Treze'),
				  (14, 'Quatorze'),
				  (15, 'Quinze'),
				  (16, 'Dezesseis'),
				  (17, 'Dezessete'),
				  (18, 'Dezoito'),
				  (19, 'Dezenove')
			
		INSERT @Dozens
			VALUES(0, ''),
				  (1, 'Dez'),
				  (2, 'Vinte'),
				  (3, 'Trinta'),
				  (4, 'Quarenta'),
				  (5, 'Cinquenta'),
				  (6, 'Sessenta'),
				  (7, 'Setenta'),
				  (8, 'Oitenta'),
				  (9, 'Noventa')
			
		INSERT @Hundreds
			VALUES(0, ''),
				  (1, 'Cento'),
				  (2, 'Duzentos'),
				  (3, 'Trezentos'),
				  (4, 'Quatrocentos'),
				  (5, 'Quinhentos'),
				  (6, 'Seiscentos'),
				  (7, 'Setecentos'),
				  (8, 'Oitocentos'),
				  (9, 'Novecentos')
	END ELSE BEGIN
		SET @And = ' and '
		INSERT @Units
			VALUES(0, ''),
				  (1, 'One'),
				  (2, 'Two'),
				  (3, 'Three'),
				  (4, 'Four'),
				  (5, 'Five'),
				  (6, 'Six'),
				  (7, 'Seven'),
				  (8, 'Eight'),
				  (9, 'Nine'),
				  (10, 'Ten'),
				  (11, 'Eleven'),
				  (12, 'Twelve'),
				  (13, 'Thirteen'),
				  (14, 'Fourteen'),
				  (15, 'Fifteen'),
				  (16, 'Sixteen'),
				  (17, 'Seventeen'),
				  (18, 'Eighteen'),
				  (19, 'Nineteen')
			
		INSERT @Dozens
			VALUES(0, ''),
				  (1, 'Ten'),
				  (2, 'Vinte'),
				  (3, 'Thirty'),
				  (4, 'Forty'),
				  (5, 'Fifty'),
				  (6, 'Sixty'),
				  (7, 'Seventy'),
				  (8, 'Eighty'),
				  (9, 'Ninety')
			
		INSERT @Hundreds
			VALUES(0, ''),
				  (1, 'One Hundred'),
				  (2, 'Two Hundred'),
				  (3, 'Three Hundred'),
				  (4, 'Four Hundred'),
				  (5, 'Five Hundred'),
				  (6, 'Six Hundred'),
				  (7, 'Seven Hundred'),
				  (8, 'Eight Hundred'),
				  (9, 'Nine Hundred')
	END
	
	IF @Value < 20 BEGIN
		SET @Result = (SELECT Nome FROM @Units WHERE Id = @Value)
	END ELSE IF @Value < 100 BEGIN
		SET @Result = (SELECT Nome FROM @Dozens WHERE Id = @SecondDigit) +
						 CASE WHEN @FirstDigit = 0 THEN '' ELSE @And + (SELECT Nome FROM @Units WHERE Id = @FirstDigit) END
	END ELSE IF @Value = 100 BEGIN
		SET @Result = CASE WHEN @PortugueseOrEnglish = 1 THEN 'Cem' ELSE 'One Hundred' END
	END ELSE IF @Value % 100 = 0 BEGIN
		SET @Result = (SELECT Nome FROM @Hundreds WHERE Id = @ThirdDigit)
	END ELSE BEGIN
		SET @Result = (SELECT Nome FROM @Hundreds WHERE Id = @ThirdDigit) +
						 CASE WHEN @SecondDigit < 2 
							  THEN @And + (SELECT Nome FROM @Units WHERE Id = @SecondDigit * 10 + @FirstDigit)
						      ELSE @And + (SELECT Nome FROM @Dozens WHERE Id = @SecondDigit) + CASE WHEN @FirstDigit = 0 
																									 THEN '' 
																									 ELSE @And + (SELECT Nome FROM @Units WHERE Id = @FirstDigit)
																								END
						 END
	END

	RETURN @Result
END
GO
/**********************************************************************************
Criar stored function NumberInWords
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[NumberInWords]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[NumberInWords]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
-- SELECT dbo.NumberInWords (600000, 1, 'Real', 'Reais', 'Centavo', 'Centavos') 
ALTER FUNCTION [dbo].[NumberInWords](@Value AS DECIMAL(18,2),
									  @PortugueseOrEnglish BIT = 0,
									  @CurrencyInSingular VARCHAR(50) = NULL,
									  @CurrencyInPlural VARCHAR(50) = NULL,
									  @CentsInSingular VARCHAR(50) = NULL,
									  @CentsInPlural VARCHAR(50) = NULL)
RETURNS VARCHAR(MAX) AS  
BEGIN 
	DECLARE @Power INT = 0,
		    @Separator VARCHAR(5) = '',
		    @PartialValue BIGINT,
		    @Digito INT = 0,
		    @LastDigit INT,
			@Result VARCHAR(MAX) = '',
			@Minus VARCHAR(10) = '',
			@Of VARCHAR(10),
			@And VARCHAR(10),
			@ValueOfHundreds INT = 0,
			@ValueOfThousands INT = 0
	DECLARE @Powers TABLE (Id INT, NomeSingular VARCHAR(50), NomePlural VARCHAR(50))

	IF @PortugueseOrEnglish = 1 BEGIN
		IF @CurrencyInSingular IS NULL
			SET @CurrencyInSingular = 'Real'
		IF @CurrencyInPlural IS NULL
			SET @CurrencyInPlural = 'Reais'
		IF @CentsInSingular IS NULL
			SET @CentsInSingular = 'Centavo'
		IF @CentsInPlural IS NULL
			SET @CentsInPlural = 'Centavos'
		SET @Of = ' de '
		SET @And = ' e '
		IF @Value < 0 BEGIN
			SET @Value = -@Value
			SET @Minus = 'Menos'
		END	
		INSERT @Powers
			VALUES(0,'', ''),
				  (1,'Mil', 'Mil'),
				  (2,'Milhão', 'Milhões'),
				  (3,'Bilhão', 'Bilhões'),
				  (4,'Trilhão', 'Trilhões'),
				  (5,'Quatrilhão', 'Quatrilhões'),
				  (6,'Quintilhão', 'Quintilhões'),
				  (7,'Sextilhão', 'Sextilhões'),
				  (8,'Septilhão', 'Septilhões'),
				  (9,'Octilhão', 'Octilhões'),
				  (10,'Nonilhão', 'Nonilhões'),
				  (11,'Decilhão', 'Decilhões'),
			      (12,'Undecilhão', 'Undecilhões'),
				  (13,'Duodecilhão', 'Duodecilhões'),
				  (14,'Tredecilhão', 'Tredecilhões')
	END ELSE BEGIN
		IF @CurrencyInSingular IS NULL
			SET @CurrencyInSingular = 'Dollar'
		IF @CurrencyInPlural IS NULL
			SET @CurrencyInPlural = 'Dollars'
		IF @CentsInSingular IS NULL
			SET @CentsInSingular = 'Cent'
		IF @CentsInPlural IS NULL
			SET @CentsInPlural = 'Cents'
		SET @Of = ' of '
		SET @And = ' and '
		IF @Value < 0 BEGIN
			SET @Value = -@Value
			SET @Minus = 'Minus'
		END	
		INSERT @Powers
			VALUES(0,'', ''),
				  (1,'Thousand', 'Thousands'),
				  (2,'Million', 'Millions'),
				  (3,'Billion', 'Billions'),
				  (4,'Trillion', 'Trillions'),
				  (5,'Quadrillion', 'Quadrillions'),
				  (6,'Quintillion', 'Quintillions'),
				  (7,'Sextillion', 'Sextillions'),
				  (8,'Septillion', 'Septillions'),
				  (9,'Octillion', 'Octillions'),
				  (10,'Nonillion', 'Nonillions'),
				  (11,'Decillion', 'Decillion'),
				  (12,'Undecillion', 'Undecillions'),
				  (13,'Duodecillion', 'Duodecillions'),
				  (14,'Tredecillion', 'Tredecillions')
	END
	SET @PartialValue = FLOOR(@Value)
	WHILE @PartialValue > 0 BEGIN
		SET @LastDigit = @Digito
		SET @Digito = @PartialValue % 1000
		IF @Power = 0 BEGIN
			SET @ValueOfHundreds = @Digito
		END ELSE IF @Power = 1 BEGIN
			SET @ValueOfThousands = @Digito
		END
		IF @Digito = 1 BEGIN
			 SET @Result = [dbo].[NumberInWordsOfHundreds](@Digito, @PortugueseOrEnglish) + ' ' + 
							  (SELECT NomeSingular FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END ELSE IF @Digito > 0 BEGIN
			 SET @Result = [dbo].[NumberInWordsOfHundreds](@Digito, @PortugueseOrEnglish) + ' ' + 
							  (SELECT NomePlural FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END
		SET @PartialValue = @PartialValue / 1000
		IF @Digito > 0 BEGIN
			IF (@Power = 0) BEGIN
				SET @Separator = @And
			END ELSE BEGIN
				SET @Separator = ', '
			END
		END
		SET @Power = @Power + 1
	END
	SET @Result = RTRIM(@Result)
	IF @Result = '' BEGIN
		IF @Value = 0 BEGIN
			SET @Result = 'Zero ' + @CurrencyInPlural
		END
	END ELSE IF @Digito = 1 BEGIN
		IF @Power < 2 BEGIN
			SET @Result = @Result + ' ' + @CurrencyInSingular
		END ELSE IF @Power = 2 BEGIN
			SET @Result = @Result + ' ' + @CurrencyInPlural
		END ELSE BEGIN
			SET @Result = @Result + CASE WHEN @ValueOfHundreds > 0 OR @ValueOfThousands > 0 THEN ' ' ELSE @Of END + @CurrencyInPlural
		END
	END ELSE IF @Power <= 2 BEGIN
		SET @Result = @Result + ' ' + @CurrencyInPlural
	END ELSE BEGIN
		SET @Result = @Result + CASE WHEN @ValueOfHundreds > 0 OR @ValueOfThousands > 0 THEN ' ' ELSE @Of END + @CurrencyInPlural
	END
	SET @PartialValue = FLOOR(@Value * 100) % 100
	IF @PartialValue > 0 BEGIN
		IF @PartialValue = 1 BEGIN
			IF @Result = '' BEGIN
				SET @Result = [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInSingular + @Of + @CurrencyInSingular
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInSingular 
			END
		END ELSE BEGIN
			IF @Result = '' BEGIN
				SET @Result = [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInPlural + @Of + @CurrencyInPlural
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInPlural
			END
		END
	END		

	RETURN @Minus + ' ' + @Result
END
GO
/**********************************************************************************
Criar stored function F_TransactionsRead
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[F_TransactionsActions]', 'FN')) IS NOT NULL
	DROP FUNCTION [dbo].[F_TransactionsActions]
GO
CREATE FUNCTION [dbo].[F_TransactionsActions](@SystemName VARCHAR(25),
											@DatabaseName VARCHAR(25),
											@TableName VARCHAR(25),
											@Action VARCHAR(15))
RETURNS @result TABLE ([SystemId] BIGINT,
						[DatabaseId] BIGINT,
						[TableId] BIGINT,
						[UserId] BIGINT,
						[LoginId] BIGINT,
						[ProcedureCreate] VARCHAR(50),
						[ProcedureUpdate] VARCHAR(50),
						[ProcedureDelete] VARCHAR(50),
						[ProcedureRead] VARCHAR(50),
						[AlterTable] VARCHAR(MAX),
						[InsertTable] VARCHAR(MAX),
						[SelectTable] VARCHAR(MAX),
						[CommitTable] VARCHAR(MAX),
						[ErrorMessage] VARCHAR(255)) AS
BEGIN
	DECLARE @SystemId BIGINT,
			@DatabaseId BIGINT,
			@TableId BIGINT,
			@UserId BIGINT,
			@LoginId BIGINT,
			@ProcedureCreate VARCHAR(50),
			@ProcedureUpdate VARCHAR(50),
			@ProcedureDelete VARCHAR(50),
			@ProcedureRead VARCHAR(50),
			@AlterTable VARCHAR(MAX),
			@InsertTable VARCHAR(MAX),
			@SelectTable VARCHAR(MAX),
			@CommitTable VARCHAR(MAX),
			@FunctionName VARCHAR(255) = 'Function ' + (SELECT OBJECT_NAME(@@PROCID)) + ': ',
			@ErrorMessage VARCHAR(255)

	IF @Action IN ('create', 'update', 'delete', 'rollback', 'commit', 'read') BEGIN
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL
			SET @ErrorMessage = @FunctionName + 'Sistema ' + @SystemName + ' não encontrado.'
		ELSE BEGIN
			SELECT @DatabaseId = [D].[Id]
				FROM [dbo].[Databases] [D]
					INNER JOIN [dbo].[SystemsDatabases] [SD] ON [SD].[DatabaseId] = [D].[Id]
				WHERE [SD].[SystemId] = @SystemId
					  AND [D].[Name] = @DatabaseName
			IF @DatabaseId IS NULL
				SET @ErrorMessage = @FunctionName + 'Banco de dados ' + @DatabaseName + ' não encontrado.'
			ELSE BEGIN
				SELECT @TableId = [Id],
					   @ProcedureCreate = [ProcedureCreate],
					   @ProcedureUpdate = [ProcedureUpdate],
					   @ProcedureDelete = [ProcedureDelete],
					   @ProcedureRead = [ProcedureRead]
					FROM [dbo].[Tables]
					WHERE [Name] = @TableName
				IF @TableId IS NULL
					SET @ErrorMessage = @FunctionName + 'Tabela ' + @TableName + ' não encontrada.'
				ELSE IF NOT EXISTS(SELECT 1
										FROM [dbo].[DatabasesTables]
										WHERE [DatabaseId] = @DatabaseId
											  AND [TableId] = @TableId)
					SET @ErrorMessage = @FunctionName + 'Tabela ' + @TableName + 'não pertence ao banco-de-dados ' + @DatabaseName + '.'
				ELSE IF @Action = 'create' AND @ProcedureCreate IS NULL
					SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Create para a tabela ' + @TableName + '.';
				ELSE IF @Action = 'update' AND @ProcedureUpdate IS NULL
					SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Update para a tabela ' + @TableName + '.';
				ELSE IF @Action = 'delete' AND @ProcedureDelete IS NULL
					SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Delete para a tabela ' + @TableName + '.';
				ELSE IF @Action = 'read' BEGIN
					IF @ProcedureRead IS NULL
						SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Read para a tabela ' + @TableName + '.';
					ELSE BEGIN
						SET @AlterTable = (SELECT 'ALTER TABLE [dbo].[#tmp] ADD [' + 
												[C].[Name] + '] ['  +
												[T].[Name] + ']' +
												CASE WHEN [D].[Length] IS NULL
													 THEN CASE WHEN [T].[Name] IN ('varchar', 'nvarchar', 'varbinary')
															   THEN '(MAX)'
															   ELSE ''
														  END
													 ELSE '(' + CAST([D].[Length] AS VARCHAR) +
														  CASE WHEN [D].[Decimals] IS NULL
															   THEN ''
															   ELSE ',' + CAST([D].[Decimals] AS VARCHAR)
														  END +
														  ')'
												END + ';'
											FROM [dbo].[Columns] [C]
												INNER JOIN [dbo].[Domains] [D] ON [D].[Id] = [C].[DomainId]
												INNER JOIN [dbo].[Types] [T] ON [T].[Id] = [D].[TypeId]
											WHERE [C].[TableId] = @TableId
											ORDER BY [C].[TableId],
													 [C].[Sequence]
											FOR XML PATH(''))

						SET @InsertTable = 'INSERT [dbo].[#tmp] SELECT 0' + 
											  (SELECT ',' + 'CAST(JSON_VALUE(Record, ''$.' + [Name] + '''' + ') AS VARCHAR(MAX))'
													FROM [dbo].[Columns]
													WHERE [TableId] = @TableId
													ORDER BY [TableId],
															 [Sequence]
													FOR XML PATH('')) + ' FROM [dbo].[Transactions]'

						SET @SelectTable = (SELECT ',' + [Name]
												FROM [dbo].[Columns]
												WHERE [TableId] = @TableId
												ORDER BY [TableId],
														 [Sequence]
												FOR XML PATH(''))
						SET @SelectTable = 'SELECT ' + RIGHT(@SelectTable, LEN(@SelectTable) - 1) + ' FROM [dbo].[#tmp]'
					END
				END
			END
		END
	END ELSE
		SET @ErrorMessage = @FunctionName + 'Valor ( ' + @Action + ') do parâmetro @Action é inválido.';
	INSERT @result VALUES(@SystemId,
							@DatabaseId,
							@TableId,
							@UserId,
							@LoginId,
							@ProcedureCreate,
							@ProcedureUpdate,
							@ProcedureDelete,
							@ProcedureRead,
							@AlterTable,
							@InsertTable,
							@SelectTable,
							@CommitTable,
							@ErrorMessage)
	RETURN
END
GO
