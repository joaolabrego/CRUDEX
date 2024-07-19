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
Criar function F_IsEquals
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF (SELECT object_id('[dbo].[F_IsEquals]', 'FN')) IS NOT NULL
	DROP FUNCTION [dbo].[F_IsEquals]
GO
CREATE FUNCTION [dbo].[F_IsEquals](@LeftValue SQL_VARIANT,
								   @RightValue SQL_VARIANT)
RETURNS BIT AS
BEGIN
	DECLARE @Result BIT = 0,
			@LeftType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@LeftValue, 'BaseType'), 'NULL') AS VARCHAR(25)),
			@RightType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@RightValue, 'BaseType'), 'NULL') AS VARCHAR(25))

	IF (@LeftValue IS NULL AND @RightValue IS NULL) OR 
	   (@LeftType = @RightType AND @LeftValue = @RightValue)
		SET @Result = 1

	RETURN @Result
END
GO
/**********************************************************************************
Criar function F_NumberInWordsOfHundreds
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[F_NumberInWordsOfHundreds]', 'P')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[F_NumberInWordsOfHundreds]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [dbo].[F_NumberInWordsOfHundreds](@Value AS DECIMAL(18),
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
Criar function F_NumberInWords
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[F_NumberInWords]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[F_NumberInWords]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
-- SELECT dbo.NumberInWords (600000, 1, 'Real', 'Reais', 'Centavo', 'Centavos') 
ALTER FUNCTION [dbo].[F_NumberInWords](@Value AS DECIMAL(18,2),
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
			 SET @Result = [dbo].[F_NumberInWordsOfHundreds](@Digito, @PortugueseOrEnglish) + ' ' + 
							  (SELECT NomeSingular FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END ELSE IF @Digito > 0 BEGIN
			 SET @Result = [dbo].[F_NumberInWordsOfHundreds](@Digito, @PortugueseOrEnglish) + ' ' + 
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
				SET @Result = [dbo].[F_NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInSingular + @Of + @CurrencyInSingular
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[F_NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInSingular 
			END
		END ELSE BEGIN
			IF @Result = '' BEGIN
				SET @Result = [dbo].[F_NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInPlural + @Of + @CurrencyInPlural
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[F_NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInPlural
			END
		END
	END		

	RETURN @Minus + ' ' + @Result
END
GO
/**********************************************************************************
Criar stored procedure P_Config
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [dbo].[Config] 'cruda','all',null
IF(SELECT object_id('[dbo].[P_Config]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_Config] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_Config](@SystemName VARCHAR(25),
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
				,[T].[FunctionValid]
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
Criar stored procedure P_GenerateId
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[P_GenerateId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_GenerateId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_GenerateId](@SystemName VARCHAR(25),
									 @DatabaseName VARCHAR(25),
									 @TableName VARCHAR(25)) AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId BIGINT,
				@DatabaseId BIGINT,
				@TableId BIGINT,
				@Next_Id BIGINT,
				@ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '

		IF @@TRANCOUNT = 0 BEGIN
			BEGIN TRANSACTION GenerateIdTransaction
		END ELSE
			SAVE TRANSACTION GenerateIdTransaction
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
							  AND [DatabaseId] = @DatabaseId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não pertence ao sistema especificado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TableId = [Id]
			FROM [dbo].[Tables]
			WHERE [Name] = @TableName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não encontrada.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
							  AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @Next_Id = [LastId] + 1
			FROM [dbo].[Tables]
			WHERE [Id] = @TableId
		UPDATE [dbo].[Tables] 
			SET [LastId] = @Next_Id
			WHERE [Id] = @TableId
		COMMIT TRANSACTION GenerateIdTransaction

		RETURN @Next_Id
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION GenerateIdTransaction;
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar stored procedure P_Login
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[P_Login] 'cruda','labrego','diva','authenticate'
IF(SELECT object_id('[dbo].[P_Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_Login](@Login VARCHAR(MAX)) AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(256)

		IF @@TRANCOUNT = 0 BEGIN
			BEGIN TRANSACTION P_Login
		END ELSE
			SAVE TRANSACTION P_Login
		IF ISJSON(@Login) = 1 BEGIN
			SET @ErrorMessage = 'Parâmetro Login não está no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END
	
		DECLARE @LoginId BIGINT = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
			   ,@SystemName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.SystemName') AS VARCHAR(25))
			   ,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
			   ,@Password VARCHAR(256) = CAST(JSON_VALUE(@Login, '$.Password') AS VARCHAR(256))
			   ,@Action VARCHAR(15) = CAST(JSON_VALUE(@Login, '$.Action') AS VARCHAR(15))
			   ,@PasswordAux VARCHAR(256)
			   ,@SystemId BIGINT
			   ,@SystemIdAux BIGINT
			   ,@UserId BIGINT
			   ,@UserIdAux BIGINT
			   ,@MaxRetryLogins TINYINT
			   ,@RetryLogins TINYINT
			   ,@IsLogged BIT
			   ,@IsActive BIT
	
		IF @Action NOT IN ('login','logout','authenticate') BEGIN
			SET @ErrorMessage = 'Ação de login inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @LoginId IS NULL AND @Action <> 'login' BEGIN
			SET @ErrorMessage = 'Id de login requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @SystemId = [SystemId],
			   @UserId = [UserId],
			   @IsLogged = [IsLogged]
			FROM [dbo].[Logins]
			WHERE [Id] = @LoginId
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário bloqueado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário inativo.';
			THROW 51000, @ErrorMessage, 1
		END
		IF CAST(@PasswordAux AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = [RetryLogins] + 1
				WHERE [Id] = @UserId 
						AND @RetryLogins < @MaxRetryLogins
			SET @ErrorMessage = 'Senha inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 0 [Systems]
		SELECT @SystemIdAux = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemIdAux <> @SystemId BEGIN
			SET @ErrorMessage = 'Sistema inválido.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 1 [Users]
		SELECT	@UserIdAux = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @@ROWCOUNT =0 BEGIN
			SET @ErrorMessage = 'Usuário não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserIdAux <> @UserId BEGIN
			SET @ErrorMessage = 'Usuário inválido.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 2 [SystemsUsers]
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @action = 'login' BEGIN
			EXEC @LoginId = [dbo].[P_GenerateId] 'cruda', 'cruda', 'Logins'
			INSERT [dbo].[Logins]([Id],
								  [SystemId],
								  [UserId],
								  [IsLogged],
								  [CreatedAt],
								  [CreatedBy])
						  VALUES (@LoginId,
								  @SystemId,
								  @UserId,
								  1,
								  GETDATE(),
								  @UserName)
		END ELSE IF @action = 'logout' BEGIN
			UPDATE [dbo].[Logins]
				SET [IsLogged] = 0,
					[UpdatedAt] = GETDATE(),
					[UpdatedBy] = @UserName
				WHERE [Id] = @LoginId
		END ELSE BEGIN
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = 0
				WHERE [Id] = @UserId
			SELECT [Id]
				  ,[Name]
				  ,[FullName]
				FROM [dbo].[Users] 
				WHERE [Id] = @UserId
		END
		COMMIT TRANSACTION P_Login

		RETURN @LoginId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION P_Login;
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar tabela Categories
**********************************************************************************/
IF (SELECT object_id('[dbo].[Categories]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Categories]
CREATE TABLE [dbo].[Categories](
[Id] tinyint NOT NULL
,[Name] varchar(25) NOT NULL
,[HtmlInputType] varchar(10) NULL
,[HtmlInputAlign] varchar(6) NULL
,[AskEncrypted] bit NOT NULL
,[AskMask] bit NOT NULL
,[AskListable] bit NOT NULL
,[AskDefault] bit NOT NULL
,[AskMinimum] bit NOT NULL
,[AskMaximum] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Categories] ADD CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Categories_Name] ON [dbo].[Categories]([Name] ASC)
GO
/**********************************************************************************
Criar procedure CategoriesCreate
**********************************************************************************/
IF(SELECT object_id('CategoriesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[CategoriesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_HtmlInputType varchar(10) = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar(10))
,@W_HtmlInputAlign varchar(6) = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar(6))
,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskEncrypted IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskEncrypted é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskListable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskListable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDefault IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskDefault é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMinimum IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMinimum é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMaximum IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMaximum é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Categories.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Categories_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Categories] ([Id]
,[Name]
,[HtmlInputType]
,[HtmlInputAlign]
,[AskEncrypted]
,[AskMask]
,[AskListable]
,[AskDefault]
,[AskMinimum]
,[AskMaximum]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_Name
,@W_HtmlInputType
,@W_HtmlInputAlign
,@W_AskEncrypted
,@W_AskMask
,@W_AskListable
,@W_AskDefault
,@W_AskMinimum
,@W_AskMaximum
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure CategoriesUpdate
**********************************************************************************/
IF(SELECT object_id('CategoriesUpdate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[CategoriesUpdate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_HtmlInputType varchar(10) = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar(10))
,@W_HtmlInputAlign varchar(6) = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar(6))
,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskEncrypted IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskEncrypted é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskListable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskListable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDefault IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskDefault é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMinimum IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMinimum é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMaximum IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMaximum é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Categories.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Categories_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Categories]
SET [Name] = @W_Name
,[HtmlInputType] = @W_HtmlInputType
,[HtmlInputAlign] = @W_HtmlInputAlign
,[AskEncrypted] = @W_AskEncrypted
,[AskMask] = @W_AskMask
,[AskListable] = @W_AskListable
,[AskDefault] = @W_AskDefault
,[AskMinimum] = @W_AskMinimum
,[AskMaximum] = @W_AskMaximum
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure CategoriesDelete
**********************************************************************************/
IF(SELECT object_id('CategoriesDelete', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[CategoriesDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Categories.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Categories]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar procedure CategoriesRead
**********************************************************************************/
IF(SELECT object_id('CategoriesRead', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[CategoriesRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_HtmlInputType varchar(10) = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar(10))
,@W_HtmlInputAlign varchar(6) = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar(6))
,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id < CAST('1' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Id > CAST('255' AS tinyint) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''255''.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskEncrypted IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskEncrypted é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskListable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskListable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDefault IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskDefault é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMinimum IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMinimum é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskMaximum IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskMaximum é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Categories_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS tinyint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'HtmlInputType') AS varchar(10)) AS [HtmlInputType]
,CAST(JSON_VALUE([ActualRecord], 'HtmlInputAlign') AS varchar(6)) AS [HtmlInputAlign]
,CAST(JSON_VALUE([ActualRecord], 'AskEncrypted') AS bit) AS [AskEncrypted]
,CAST(JSON_VALUE([ActualRecord], 'AskMask') AS bit) AS [AskMask]
,CAST(JSON_VALUE([ActualRecord], 'AskListable') AS bit) AS [AskListable]
,CAST(JSON_VALUE([ActualRecord], 'AskDefault') AS bit) AS [AskDefault]
,CAST(JSON_VALUE([ActualRecord], 'AskMinimum') AS bit) AS [AskMinimum]
,CAST(JSON_VALUE([ActualRecord], 'AskMaximum') AS bit) AS [AskMaximum]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[Name]
,[HtmlInputType]
,[HtmlInputAlign]
,[AskEncrypted]
,[AskMask]
,[AskListable]
,[AskDefault]
,[AskMinimum]
,[AskMaximum]
INTO[dbo].[#Categories]
FROM [dbo].[Categories]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
AND [AskEncrypted] = ISNULL(@W_AskEncrypted, [AskEncrypted])
AND [AskMask] = ISNULL(@W_AskMask, [AskMask])
AND [AskListable] = ISNULL(@W_AskListable, [AskListable])
AND [AskDefault] = ISNULL(@W_AskDefault, [AskDefault])
AND [AskMinimum] = ISNULL(@W_AskMinimum, [AskMinimum])
AND [AskMaximum] = ISNULL(@W_AskMaximum, [AskMaximum])
SET @RowCount = @@ROWCOUNT
DELETE [Categories]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Categories] [Categories] ON [Categories].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Categories] SELECT [Id]
,[Name]
,[HtmlInputType]
,[HtmlInputAlign]
,[AskEncrypted]
,[AskMask]
,[AskListable]
,[AskDefault]
,[AskMinimum]
,[AskMaximum]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Types
**********************************************************************************/
IF (SELECT object_id('[dbo].[Types]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Types]
CREATE TABLE [dbo].[Types](
[Id] tinyint NOT NULL
,[CategoryId] tinyint NOT NULL
,[Name] varchar(25) NOT NULL
,[Minimum] sql_variant NULL
,[Maximum] sql_variant NULL
,[AskLength] bit NOT NULL
,[AskDecimals] bit NOT NULL
,[AskPrimarykey] bit NOT NULL
,[AskAutoincrement] bit NOT NULL
,[AskFilterable] bit NOT NULL
,[AskBrowseable] bit NOT NULL
,[AskCodification] bit NOT NULL
,[AskFormula] bit NOT NULL
,[AllowMaxLength] bit NOT NULL
,[IsActive] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Types] ADD CONSTRAINT PK_Types PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Types_Name] ON [dbo].[Types]([Name] ASC)
GO
/**********************************************************************************
Criar procedure TypesCreate
**********************************************************************************/
IF(SELECT object_id('TypesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[TypesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_AskLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AskLength') AS bit)
,@W_AskDecimals bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDecimals') AS bit)
,@W_AskPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.AskPrimarykey') AS bit)
,@W_AskAutoincrement bit = CAST(JSON_VALUE(@ActualRecord, '$.AskAutoincrement') AS bit)
,@W_AskFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFilterable') AS bit)
,@W_AskBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskBrowseable') AS bit)
,@W_AskCodification bit = CAST(JSON_VALUE(@ActualRecord, '$.AskCodification') AS bit)
,@W_AskFormula bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFormula') AS bit)
,@W_AllowMaxLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AllowMaxLength') AS bit)
,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de CategoryId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_CategoryId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de CategoryId não existe em Categories';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDecimals IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskDecimals é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskPrimarykey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskPrimarykey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskAutoincrement IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskAutoincrement é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFilterable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskFilterable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskBrowseable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskBrowseable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskCodification IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskCodification é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFormula IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskFormula é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AllowMaxLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AllowMaxLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Types.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Types_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Types] ([Id]
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
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_CategoryId
,@W_Name
,@W_Minimum
,@W_Maximum
,@W_AskLength
,@W_AskDecimals
,@W_AskPrimarykey
,@W_AskAutoincrement
,@W_AskFilterable
,@W_AskBrowseable
,@W_AskCodification
,@W_AskFormula
,@W_AllowMaxLength
,@W_IsActive
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[TypesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_AskLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AskLength') AS bit)
,@W_AskDecimals bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDecimals') AS bit)
,@W_AskPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.AskPrimarykey') AS bit)
,@W_AskAutoincrement bit = CAST(JSON_VALUE(@ActualRecord, '$.AskAutoincrement') AS bit)
,@W_AskFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFilterable') AS bit)
,@W_AskBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskBrowseable') AS bit)
,@W_AskCodification bit = CAST(JSON_VALUE(@ActualRecord, '$.AskCodification') AS bit)
,@W_AskFormula bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFormula') AS bit)
,@W_AllowMaxLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AllowMaxLength') AS bit)
,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de CategoryId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_CategoryId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de CategoryId não existe em Categories';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDecimals IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskDecimals é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskPrimarykey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskPrimarykey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskAutoincrement IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskAutoincrement é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFilterable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskFilterable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskBrowseable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskBrowseable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskCodification IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskCodification é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFormula IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskFormula é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AllowMaxLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AllowMaxLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Types.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Types_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Types]
SET [CategoryId] = @W_CategoryId
,[Name] = @W_Name
,[Minimum] = @W_Minimum
,[Maximum] = @W_Maximum
,[AskLength] = @W_AskLength
,[AskDecimals] = @W_AskDecimals
,[AskPrimarykey] = @W_AskPrimarykey
,[AskAutoincrement] = @W_AskAutoincrement
,[AskFilterable] = @W_AskFilterable
,[AskBrowseable] = @W_AskBrowseable
,[AskCodification] = @W_AskCodification
,[AskFormula] = @W_AskFormula
,[AllowMaxLength] = @W_AllowMaxLength
,[IsActive] = @W_IsActive
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[TypesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Types.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Types]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[TypesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_AskLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AskLength') AS bit)
,@W_AskDecimals bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDecimals') AS bit)
,@W_AskPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.AskPrimarykey') AS bit)
,@W_AskAutoincrement bit = CAST(JSON_VALUE(@ActualRecord, '$.AskAutoincrement') AS bit)
,@W_AskFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFilterable') AS bit)
,@W_AskBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskBrowseable') AS bit)
,@W_AskCodification bit = CAST(JSON_VALUE(@ActualRecord, '$.AskCodification') AS bit)
,@W_AskFormula bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFormula') AS bit)
,@W_AllowMaxLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AllowMaxLength') AS bit)
,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de CategoryId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_CategoryId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de CategoryId não existe em Categories';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskDecimals IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskDecimals é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskPrimarykey IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskPrimarykey é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskAutoincrement IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskAutoincrement é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFilterable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskFilterable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskBrowseable IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskBrowseable é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskCodification IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskCodification é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AskFormula IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AskFormula é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_AllowMaxLength IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de AllowMaxLength é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsActive IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Types_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS tinyint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'CategoryId') AS tinyint) AS [CategoryId]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Minimum') AS sql_variant) AS [Minimum]
,CAST(JSON_VALUE([ActualRecord], 'Maximum') AS sql_variant) AS [Maximum]
,CAST(JSON_VALUE([ActualRecord], 'AskLength') AS bit) AS [AskLength]
,CAST(JSON_VALUE([ActualRecord], 'AskDecimals') AS bit) AS [AskDecimals]
,CAST(JSON_VALUE([ActualRecord], 'AskPrimarykey') AS bit) AS [AskPrimarykey]
,CAST(JSON_VALUE([ActualRecord], 'AskAutoincrement') AS bit) AS [AskAutoincrement]
,CAST(JSON_VALUE([ActualRecord], 'AskFilterable') AS bit) AS [AskFilterable]
,CAST(JSON_VALUE([ActualRecord], 'AskBrowseable') AS bit) AS [AskBrowseable]
,CAST(JSON_VALUE([ActualRecord], 'AskCodification') AS bit) AS [AskCodification]
,CAST(JSON_VALUE([ActualRecord], 'AskFormula') AS bit) AS [AskFormula]
,CAST(JSON_VALUE([ActualRecord], 'AllowMaxLength') AS bit) AS [AllowMaxLength]
,CAST(JSON_VALUE([ActualRecord], 'IsActive') AS bit) AS [IsActive]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
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
INTO[dbo].[#Types]
FROM [dbo].[Types]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
AND [AskLength] = ISNULL(@W_AskLength, [AskLength])
AND [AskDecimals] = ISNULL(@W_AskDecimals, [AskDecimals])
AND [AskPrimarykey] = ISNULL(@W_AskPrimarykey, [AskPrimarykey])
AND [AskAutoincrement] = ISNULL(@W_AskAutoincrement, [AskAutoincrement])
AND [AskFilterable] = ISNULL(@W_AskFilterable, [AskFilterable])
AND [AskBrowseable] = ISNULL(@W_AskBrowseable, [AskBrowseable])
AND [AskCodification] = ISNULL(@W_AskCodification, [AskCodification])
AND [AskFormula] = ISNULL(@W_AskFormula, [AskFormula])
AND [AllowMaxLength] = ISNULL(@W_AllowMaxLength, [AllowMaxLength])
AND [IsActive] = ISNULL(@W_IsActive, [IsActive])
SET @RowCount = @@ROWCOUNT
DELETE [Types]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Types] [Types] ON [Types].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Types] SELECT [Id]
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
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Masks
**********************************************************************************/
IF (SELECT object_id('[dbo].[Masks]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Masks]
CREATE TABLE [dbo].[Masks](
[Id] bigint NOT NULL
,[Name] varchar(25) NOT NULL
,[Mask] varchar(MAX) NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Masks] ADD CONSTRAINT PK_Masks PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Masks_Name] ON [dbo].[Masks]([Name] ASC)
GO
/**********************************************************************************
Criar procedure MasksCreate
**********************************************************************************/
IF(SELECT object_id('MasksCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MasksCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Mask varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar(MAX))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Mask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Mask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Masks.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Masks_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Masks] ([Id]
,[Name]
,[Mask]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_Name
,@W_Mask
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[MasksUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Mask varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar(MAX))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Mask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Mask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Masks.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Masks_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Masks]
SET [Name] = @W_Name
,[Mask] = @W_Mask
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[MasksDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Masks.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Masks]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[MasksRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Mask varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar(MAX))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Mask IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Mask é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Masks_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Mask') AS varchar(MAX)) AS [Mask]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[Name]
,[Mask]
INTO[dbo].[#Masks]
FROM [dbo].[Masks]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
SET @RowCount = @@ROWCOUNT
DELETE [Masks]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Masks] [Masks] ON [Masks].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Masks] SELECT [Id]
,[Name]
,[Mask]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Domains
**********************************************************************************/
IF (SELECT object_id('[dbo].[Domains]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Domains]
CREATE TABLE [dbo].[Domains](
[Id] bigint NOT NULL
,[TypeId] tinyint NOT NULL
,[MaskId] bigint NULL
,[Name] varchar(25) NOT NULL
,[Length] smallint NULL
,[Decimals] tinyint NULL
,[ValidValues] varchar(MAX) NULL
,[Default] sql_variant NULL
,[Minimum] sql_variant NULL
,[Maximum] sql_variant NULL
,[Codification] varchar(5) NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Domains] ADD CONSTRAINT PK_Domains PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Domains_Name] ON [dbo].[Domains]([Name] ASC)
GO
/**********************************************************************************
Criar procedure DomainsCreate
**********************************************************************************/
IF(SELECT object_id('DomainsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DomainsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_Codification varchar(5) = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar(5))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de TypeId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_TypeId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TypeId não existe em Types';
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
IF @W_MaskId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_MaskId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de MaskId não existe em Masks';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Domains.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Domains_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Domains] ([Id]
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
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_TypeId
,@W_MaskId
,@W_Name
,@W_Length
,@W_Decimals
,@W_ValidValues
,@W_Default
,@W_Minimum
,@W_Maximum
,@W_Codification
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DomainsUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_Codification varchar(5) = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar(5))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de TypeId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_TypeId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TypeId não existe em Types';
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
IF @W_MaskId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_MaskId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de MaskId não existe em Masks';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Domains.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Domains_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Domains]
SET [TypeId] = @W_TypeId
,[MaskId] = @W_MaskId
,[Name] = @W_Name
,[Length] = @W_Length
,[Decimals] = @W_Decimals
,[ValidValues] = @W_ValidValues
,[Default] = @W_Default
,[Minimum] = @W_Minimum
,[Maximum] = @W_Maximum
,[Codification] = @W_Codification
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DomainsDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Domains.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Domains]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DomainsRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_Codification varchar(5) = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar(5))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de TypeId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_TypeId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TypeId não existe em Types';
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
IF @W_MaskId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_MaskId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de MaskId não existe em Masks';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Domains_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'TypeId') AS tinyint) AS [TypeId]
,CAST(JSON_VALUE([ActualRecord], 'MaskId') AS bigint) AS [MaskId]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Length') AS smallint) AS [Length]
,CAST(JSON_VALUE([ActualRecord], 'Decimals') AS tinyint) AS [Decimals]
,CAST(JSON_VALUE([ActualRecord], 'ValidValues') AS varchar(MAX)) AS [ValidValues]
,CAST(JSON_VALUE([ActualRecord], 'Default') AS sql_variant) AS [Default]
,CAST(JSON_VALUE([ActualRecord], 'Minimum') AS sql_variant) AS [Minimum]
,CAST(JSON_VALUE([ActualRecord], 'Maximum') AS sql_variant) AS [Maximum]
,CAST(JSON_VALUE([ActualRecord], 'Codification') AS varchar(5)) AS [Codification]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
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
INTO[dbo].[#Domains]
FROM [dbo].[Domains]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [TypeId] = ISNULL(@W_TypeId, [TypeId])
AND (@W_MaskId IS NULL OR [MaskId] = @W_MaskId)
AND [Name] = ISNULL(@W_Name, [Name])
AND (@W_ValidValues IS NULL OR [ValidValues] = @W_ValidValues)
AND (@W_Codification IS NULL OR [Codification] = @W_Codification)
SET @RowCount = @@ROWCOUNT
DELETE [Domains]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Domains] [Domains] ON [Domains].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Domains] SELECT [Id]
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
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Systems
**********************************************************************************/
IF (SELECT object_id('[dbo].[Systems]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Systems]
CREATE TABLE [dbo].[Systems](
[Id] bigint NOT NULL
,[Name] varchar(25) NOT NULL
,[Description] varchar(50) NOT NULL
,[ClientName] varchar(15) NOT NULL
,[MaxRetryLogins] tinyint NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Systems] ADD CONSTRAINT PK_Systems PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Systems_Name] ON [dbo].[Systems]([Name] ASC)
GO
/**********************************************************************************
Criar procedure SystemsCreate
**********************************************************************************/
IF(SELECT object_id('SystemsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_ClientName varchar(15) = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar(15))
,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ClientName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ClientName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de MaxRetryLogins é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Systems.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Systems_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Systems] ([Id]
,[Name]
,[Description]
,[ClientName]
,[MaxRetryLogins]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_Name
,@W_Description
,@W_ClientName
,@W_MaxRetryLogins
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_ClientName varchar(15) = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar(15))
,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ClientName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ClientName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de MaxRetryLogins é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Systems.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Systems_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Systems]
SET [Name] = @W_Name
,[Description] = @W_Description
,[ClientName] = @W_ClientName
,[MaxRetryLogins] = @W_MaxRetryLogins
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Systems.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Systems]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_ClientName varchar(15) = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar(15))
,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_ClientName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ClientName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_MaxRetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de MaxRetryLogins é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Systems_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([ActualRecord], 'ClientName') AS varchar(15)) AS [ClientName]
,CAST(JSON_VALUE([ActualRecord], 'MaxRetryLogins') AS tinyint) AS [MaxRetryLogins]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[Name]
,[Description]
,[ClientName]
,[MaxRetryLogins]
INTO[dbo].[#Systems]
FROM [dbo].[Systems]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
AND [ClientName] = ISNULL(@W_ClientName, [ClientName])
SET @RowCount = @@ROWCOUNT
DELETE [Systems]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Systems] [Systems] ON [Systems].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Systems] SELECT [Id]
,[Name]
,[Description]
,[ClientName]
,[MaxRetryLogins]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Menus
**********************************************************************************/
IF (SELECT object_id('[dbo].[Menus]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Menus]
CREATE TABLE [dbo].[Menus](
[Id] bigint NOT NULL
,[SystemId] bigint NOT NULL
,[Sequence] smallint NOT NULL
,[Caption] varchar(20) NOT NULL
,[Message] varchar(50) NOT NULL
,[Action] varchar(50) NULL
,[ParentMenuId] bigint NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Menus] ADD CONSTRAINT PK_Menus PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Menus_SystemId_Sequence] ON [dbo].[Menus]([SystemId] ASC,[Sequence] ASC)
GO
/**********************************************************************************
Criar procedure MenusCreate
**********************************************************************************/
IF(SELECT object_id('MenusCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[MenusCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_Caption varchar(20) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(20))
,@W_Message varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar(50))
,@W_Action varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar(50))
,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Message IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Message é requerido.';
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
IF @W_ParentMenuId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_ParentMenuId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ParentMenuId não existe em Menus';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Menus.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Menus_SystemId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Menus] ([Id]
,[SystemId]
,[Sequence]
,[Caption]
,[Message]
,[Action]
,[ParentMenuId]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_SystemId
,@W_Sequence
,@W_Caption
,@W_Message
,@W_Action
,@W_ParentMenuId
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[MenusUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_Caption varchar(20) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(20))
,@W_Message varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar(50))
,@W_Action varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar(50))
,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Message IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Message é requerido.';
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
IF @W_ParentMenuId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_ParentMenuId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ParentMenuId não existe em Menus';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Menus.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Menus_SystemId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Menus]
SET [SystemId] = @W_SystemId
,[Sequence] = @W_Sequence
,[Caption] = @W_Caption
,[Message] = @W_Message
,[Action] = @W_Action
,[ParentMenuId] = @W_ParentMenuId
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[MenusDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Menus.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Menus]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[MenusRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_Caption varchar(20) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(20))
,@W_Message varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar(50))
,@W_Action varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar(50))
,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Message IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Message é requerido.';
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
IF @W_ParentMenuId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_ParentMenuId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ParentMenuId não existe em Menus';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Menus_SystemId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([ActualRecord], 'Sequence') AS smallint) AS [Sequence]
,CAST(JSON_VALUE([ActualRecord], 'Caption') AS varchar(20)) AS [Caption]
,CAST(JSON_VALUE([ActualRecord], 'Message') AS varchar(50)) AS [Message]
,CAST(JSON_VALUE([ActualRecord], 'Action') AS varchar(50)) AS [Action]
,CAST(JSON_VALUE([ActualRecord], 'ParentMenuId') AS bigint) AS [ParentMenuId]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[SystemId]
,[Sequence]
,[Caption]
,[Message]
,[Action]
,[ParentMenuId]
INTO[dbo].[#Menus]
FROM [dbo].[Menus]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [SystemId] = ISNULL(@W_SystemId, [SystemId])
AND [Caption] = ISNULL(@W_Caption, [Caption])
SET @RowCount = @@ROWCOUNT
DELETE [Menus]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Menus] [Menus] ON [Menus].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Menus] SELECT [Id]
,[SystemId]
,[Sequence]
,[Caption]
,[Message]
,[Action]
,[ParentMenuId]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Users
**********************************************************************************/
IF (SELECT object_id('[dbo].[Users]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Users]
CREATE TABLE [dbo].[Users](
[Id] bigint NOT NULL
,[Name] varchar(25) NOT NULL
,[Password] varchar(256) NOT NULL
,[FullName] varchar(50) NOT NULL
,[RetryLogins] tinyint NOT NULL
,[IsActive] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Users] ADD CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Users_Name] ON [dbo].[Users]([Name] ASC)
GO
/**********************************************************************************
Criar procedure UsersCreate
**********************************************************************************/
IF(SELECT object_id('UsersCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[UsersCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Password varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar(256))
,@W_FullName varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar(50))
,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Password IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Password é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_FullName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de FullName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de RetryLogins é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Users.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Users_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Users] ([Id]
,[Name]
,[Password]
,[FullName]
,[RetryLogins]
,[IsActive]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_Name
,@W_Password
,@W_FullName
,@W_RetryLogins
,@W_IsActive
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[UsersUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Password varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar(256))
,@W_FullName varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar(50))
,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Password IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Password é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_FullName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de FullName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de RetryLogins é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Users.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Users_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Users]
SET [Name] = @W_Name
,[Password] = @W_Password
,[FullName] = @W_FullName
,[RetryLogins] = @W_RetryLogins
,[IsActive] = @W_IsActive
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[UsersDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Users.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Users]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[UsersRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Password varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar(256))
,@W_FullName varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar(50))
,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Password IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Password é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_FullName IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de FullName é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_RetryLogins IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de RetryLogins é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de IsActive é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Users_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Password') AS varchar(256)) AS [Password]
,CAST(JSON_VALUE([ActualRecord], 'FullName') AS varchar(50)) AS [FullName]
,CAST(JSON_VALUE([ActualRecord], 'RetryLogins') AS tinyint) AS [RetryLogins]
,CAST(JSON_VALUE([ActualRecord], 'IsActive') AS bit) AS [IsActive]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[Name]
,[Password]
,[FullName]
,[RetryLogins]
,[IsActive]
INTO[dbo].[#Users]
FROM [dbo].[Users]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
AND [FullName] = ISNULL(@W_FullName, [FullName])
AND [IsActive] = ISNULL(@W_IsActive, [IsActive])
SET @RowCount = @@ROWCOUNT
DELETE [Users]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Users] [Users] ON [Users].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Users] SELECT [Id]
,[Name]
,[Password]
,[FullName]
,[RetryLogins]
,[IsActive]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela SystemsUsers
**********************************************************************************/
IF (SELECT object_id('[dbo].[SystemsUsers]', 'U')) IS NOT NULL
DROP TABLE [dbo].[SystemsUsers]
CREATE TABLE [dbo].[SystemsUsers](
[Id] bigint NOT NULL
,[SystemId] bigint NOT NULL
,[UserId] bigint NOT NULL
,[Description] varchar(50) NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[SystemsUsers] ADD CONSTRAINT PK_SystemsUsers PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_SystemsUsers_SystemId_UserId] ON [dbo].[SystemsUsers]([SystemId] ASC,[UserId] ASC)
CREATE UNIQUE INDEX [UNQ_SystemsUsers_Description] ON [dbo].[SystemsUsers]([Description] ASC)
GO
/**********************************************************************************
Criar procedure SystemsUsersCreate
**********************************************************************************/
IF(SELECT object_id('SystemsUsersCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsUsersCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de UserId é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela SystemsUsers.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsUsers_SystemId_UserId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsUsers_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[SystemsUsers] ([Id]
,[SystemId]
,[UserId]
,[Description]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_SystemId
,@W_UserId
,@W_Description
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsUsersUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de UserId é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsUsers.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsUsers_SystemId_UserId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsUsers_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[SystemsUsers]
SET [SystemId] = @W_SystemId
,[UserId] = @W_UserId
,[Description] = @W_Description
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsUsersDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsUsers.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[SystemsUsers]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsUsersRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_UserId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de UserId é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsUsers_SystemId_UserId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsUsers_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([ActualRecord], 'UserId') AS bigint) AS [UserId]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[SystemId]
,[UserId]
,[Description]
INTO[dbo].[#SystemsUsers]
FROM [dbo].[SystemsUsers]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [SystemId] = ISNULL(@W_SystemId, [SystemId])
AND [UserId] = ISNULL(@W_UserId, [UserId])
AND [Description] = ISNULL(@W_Description, [Description])
SET @RowCount = @@ROWCOUNT
DELETE [SystemsUsers]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#SystemsUsers] [SystemsUsers] ON [SystemsUsers].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#SystemsUsers] SELECT [Id]
,[SystemId]
,[UserId]
,[Description]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Databases
**********************************************************************************/
IF (SELECT object_id('[dbo].[Databases]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Databases]
CREATE TABLE [dbo].[Databases](
[Id] bigint NOT NULL
,[Name] varchar(25) NOT NULL
,[Description] varchar(50) NOT NULL
,[Alias] varchar(25) NOT NULL
,[ServerName] varchar(50) NULL
,[HostName] varchar(25) NULL
,[Port] int NULL
,[Logon] varchar(256) NULL
,[Password] varchar(256) NULL
,[Folder] varchar(256) NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
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
ALTER PROCEDURE[dbo].[DatabasesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_Alias varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar(25))
,@W_ServerName varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar(50))
,@W_HostName varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar(25))
,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
,@W_Logon varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar(256))
,@W_Password varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar(256))
,@W_Folder varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar(256))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Alias é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Databases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Databases_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Alias] = @W_Alias) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Databases_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Databases] ([Id]
,[Name]
,[Description]
,[Alias]
,[ServerName]
,[HostName]
,[Port]
,[Logon]
,[Password]
,[Folder]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_Name
,@W_Description
,@W_Alias
,@W_ServerName
,@W_HostName
,@W_Port
,@W_Logon
,@W_Password
,@W_Folder
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DatabasesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_Alias varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar(25))
,@W_ServerName varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar(50))
,@W_HostName varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar(25))
,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
,@W_Logon varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar(256))
,@W_Password varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar(256))
,@W_Folder varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar(256))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Alias é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Databases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Databases_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Alias] = @W_Alias) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Databases_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Databases]
SET [Name] = @W_Name
,[Description] = @W_Description
,[Alias] = @W_Alias
,[ServerName] = @W_ServerName
,[HostName] = @W_HostName
,[Port] = @W_Port
,[Logon] = @W_Logon
,[Password] = @W_Password
,[Folder] = @W_Folder
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DatabasesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Databases.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Databases]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DatabasesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_Alias varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar(25))
,@W_ServerName varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar(50))
,@W_HostName varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar(25))
,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
,@W_Logon varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar(256))
,@W_Password varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar(256))
,@W_Folder varchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar(256))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Alias é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Databases_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Alias] = @W_Alias) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Databases_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([ActualRecord], 'Alias') AS varchar(25)) AS [Alias]
,CAST(JSON_VALUE([ActualRecord], 'ServerName') AS varchar(50)) AS [ServerName]
,CAST(JSON_VALUE([ActualRecord], 'HostName') AS varchar(25)) AS [HostName]
,CAST(JSON_VALUE([ActualRecord], 'Port') AS int) AS [Port]
,CAST(JSON_VALUE([ActualRecord], 'Logon') AS varchar(256)) AS [Logon]
,CAST(JSON_VALUE([ActualRecord], 'Password') AS varchar(256)) AS [Password]
,CAST(JSON_VALUE([ActualRecord], 'Folder') AS varchar(256)) AS [Folder]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[Name]
,[Description]
,[Alias]
,[ServerName]
,[HostName]
,[Port]
,[Logon]
,[Password]
,[Folder]
INTO[dbo].[#Databases]
FROM [dbo].[Databases]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
AND [Alias] = ISNULL(@W_Alias, [Alias])
SET @RowCount = @@ROWCOUNT
DELETE [Databases]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Databases] [Databases] ON [Databases].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Databases] SELECT [Id]
,[Name]
,[Description]
,[Alias]
,[ServerName]
,[HostName]
,[Port]
,[Logon]
,[Password]
,[Folder]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela SystemsDatabases
**********************************************************************************/
IF (SELECT object_id('[dbo].[SystemsDatabases]', 'U')) IS NOT NULL
DROP TABLE [dbo].[SystemsDatabases]
CREATE TABLE [dbo].[SystemsDatabases](
[Id] bigint NOT NULL
,[SystemId] bigint NOT NULL
,[DatabaseId] bigint NOT NULL
,[Description] varchar(50) NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[SystemsDatabases] ADD CONSTRAINT PK_SystemsDatabases PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_SystemsDatabases_SystemId_DatabaseId] ON [dbo].[SystemsDatabases]([SystemId] ASC,[DatabaseId] ASC)
CREATE UNIQUE INDEX [UNQ_SystemsDatabases_Description] ON [dbo].[SystemsDatabases]([Description] ASC)
GO
/**********************************************************************************
Criar procedure SystemsDatabasesCreate
**********************************************************************************/
IF(SELECT object_id('SystemsDatabasesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela SystemsDatabases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsDatabases_SystemId_DatabaseId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsDatabases_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[SystemsDatabases] ([Id]
,[SystemId]
,[DatabaseId]
,[Description]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_SystemId
,@W_DatabaseId
,@W_Description
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsDatabasesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsDatabases.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsDatabases_SystemId_DatabaseId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsDatabases_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[SystemsDatabases]
SET [SystemId] = @W_SystemId
,[DatabaseId] = @W_DatabaseId
,[Description] = @W_Description
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsDatabasesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsDatabases.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[SystemsDatabases]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[SystemsDatabasesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de SystemId não existe em Systems';
THROW 51000, @ErrorMessage, 1
END
IF @W_DatabaseId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsDatabases_SystemId_DatabaseId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_SystemsDatabases_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'SystemId') AS bigint) AS [SystemId]
,CAST(JSON_VALUE([ActualRecord], 'DatabaseId') AS bigint) AS [DatabaseId]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[SystemId]
,[DatabaseId]
,[Description]
INTO[dbo].[#SystemsDatabases]
FROM [dbo].[SystemsDatabases]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [SystemId] = ISNULL(@W_SystemId, [SystemId])
AND [DatabaseId] = ISNULL(@W_DatabaseId, [DatabaseId])
AND [Description] = ISNULL(@W_Description, [Description])
SET @RowCount = @@ROWCOUNT
DELETE [SystemsDatabases]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#SystemsDatabases] [SystemsDatabases] ON [SystemsDatabases].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#SystemsDatabases] SELECT [Id]
,[SystemId]
,[DatabaseId]
,[Description]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Tables
**********************************************************************************/
IF (SELECT object_id('[dbo].[Tables]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Tables]
CREATE TABLE [dbo].[Tables](
[Id] bigint NOT NULL
,[Name] varchar(25) NOT NULL
,[Alias] varchar(25) NOT NULL
,[Description] varchar(50) NOT NULL
,[ParentTableId] bigint NULL
,[ProcedureCreate] varchar(50) NULL
,[ProcedureRead] varchar(50) NULL
,[ProcedureUpdate] varchar(50) NULL
,[ProcedureDelete] varchar(50) NULL
,[ProcedureList] varchar(50) NULL
,[IsPaged] bit NOT NULL
,[LastId] bigint NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
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
ALTER PROCEDURE[dbo].[TablesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Alias varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
,@W_ProcedureCreate varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar(50))
,@W_ProcedureRead varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar(50))
,@W_ProcedureUpdate varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar(50))
,@W_ProcedureDelete varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar(50))
,@W_ProcedureList varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar(50))
,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
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
IF @W_ParentTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ParentTableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ParentTableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsPaged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsPaged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de LastId é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Tables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Tables_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Alias] = @W_Alias) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Tables_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Tables] ([Id]
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
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_Name
,@W_Alias
,@W_Description
,@W_ParentTableId
,@W_ProcedureCreate
,@W_ProcedureRead
,@W_ProcedureUpdate
,@W_ProcedureDelete
,@W_ProcedureList
,@W_IsPaged
,@W_LastId
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[TablesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Alias varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
,@W_ProcedureCreate varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar(50))
,@W_ProcedureRead varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar(50))
,@W_ProcedureUpdate varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar(50))
,@W_ProcedureDelete varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar(50))
,@W_ProcedureList varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar(50))
,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
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
IF @W_ParentTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ParentTableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ParentTableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsPaged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsPaged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de LastId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Tables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Tables_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Alias] = @W_Alias) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Tables_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Tables]
SET [Name] = @W_Name
,[Alias] = @W_Alias
,[Description] = @W_Description
,[ParentTableId] = @W_ParentTableId
,[ProcedureCreate] = @W_ProcedureCreate
,[ProcedureRead] = @W_ProcedureRead
,[ProcedureUpdate] = @W_ProcedureUpdate
,[ProcedureDelete] = @W_ProcedureDelete
,[ProcedureList] = @W_ProcedureList
,[IsPaged] = @W_IsPaged
,[LastId] = @W_LastId
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[TablesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Tables.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Tables]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[TablesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Alias varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
,@W_ProcedureCreate varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar(50))
,@W_ProcedureRead varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar(50))
,@W_ProcedureUpdate varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar(50))
,@W_ProcedureDelete varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar(50))
,@W_ProcedureList varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar(50))
,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Alias IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Alias é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
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
IF @W_ParentTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ParentTableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ParentTableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsPaged IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsPaged é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_LastId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de LastId é requerido.';
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
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Tables_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Alias] = @W_Alias) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Tables_Alias já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Alias') AS varchar(25)) AS [Alias]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([ActualRecord], 'ParentTableId') AS bigint) AS [ParentTableId]
,CAST(JSON_VALUE([ActualRecord], 'ProcedureCreate') AS varchar(50)) AS [ProcedureCreate]
,CAST(JSON_VALUE([ActualRecord], 'ProcedureRead') AS varchar(50)) AS [ProcedureRead]
,CAST(JSON_VALUE([ActualRecord], 'ProcedureUpdate') AS varchar(50)) AS [ProcedureUpdate]
,CAST(JSON_VALUE([ActualRecord], 'ProcedureDelete') AS varchar(50)) AS [ProcedureDelete]
,CAST(JSON_VALUE([ActualRecord], 'ProcedureList') AS varchar(50)) AS [ProcedureList]
,CAST(JSON_VALUE([ActualRecord], 'IsPaged') AS bit) AS [IsPaged]
,CAST(JSON_VALUE([ActualRecord], 'LastId') AS bigint) AS [LastId]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
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
INTO[dbo].[#Tables]
FROM [dbo].[Tables]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [Name] = ISNULL(@W_Name, [Name])
AND [Alias] = ISNULL(@W_Alias, [Alias])
AND (@W_ParentTableId IS NULL OR [ParentTableId] = @W_ParentTableId)
AND [IsPaged] = ISNULL(@W_IsPaged, [IsPaged])
SET @RowCount = @@ROWCOUNT
DELETE [Tables]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Tables] [Tables] ON [Tables].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Tables] SELECT [Id]
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
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela DatabasesTables
**********************************************************************************/
IF (SELECT object_id('[dbo].[DatabasesTables]', 'U')) IS NOT NULL
DROP TABLE [dbo].[DatabasesTables]
CREATE TABLE [dbo].[DatabasesTables](
[Id] bigint NOT NULL
,[DatabaseId] bigint NOT NULL
,[TableId] bigint NOT NULL
,[Description] varchar(50) NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[DatabasesTables] ADD CONSTRAINT PK_DatabasesTables PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_DatabasesTables_DatabaseId_TableId] ON [dbo].[DatabasesTables]([DatabaseId] ASC,[TableId] ASC)
CREATE UNIQUE INDEX [UNQ_DatabasesTables_Description] ON [dbo].[DatabasesTables]([Description] ASC)
GO
/**********************************************************************************
Criar procedure DatabasesTablesCreate
**********************************************************************************/
IF(SELECT object_id('DatabasesTablesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[DatabasesTablesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesTablesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela DatabasesTables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_DatabasesTables_DatabaseId_TableId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_DatabasesTables_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[DatabasesTables] ([Id]
,[DatabaseId]
,[TableId]
,[Description]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_DatabaseId
,@W_TableId
,@W_Description
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DatabasesTablesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela DatabasesTables.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_DatabasesTables_DatabaseId_TableId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_DatabasesTables_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[DatabasesTables]
SET [DatabaseId] = @W_DatabaseId
,[TableId] = @W_TableId
,[Description] = @W_Description
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DatabasesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela DatabasesTables.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[DatabasesTables]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[DatabasesTablesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_DatabasesTables_DatabaseId_TableId já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Description] = @W_Description) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_DatabasesTables_Description já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'DatabaseId') AS bigint) AS [DatabaseId]
,CAST(JSON_VALUE([ActualRecord], 'TableId') AS bigint) AS [TableId]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[DatabaseId]
,[TableId]
,[Description]
INTO[dbo].[#DatabasesTables]
FROM [dbo].[DatabasesTables]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [DatabaseId] = ISNULL(@W_DatabaseId, [DatabaseId])
AND [TableId] = ISNULL(@W_TableId, [TableId])
AND [Description] = ISNULL(@W_Description, [Description])
SET @RowCount = @@ROWCOUNT
DELETE [DatabasesTables]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#DatabasesTables] [DatabasesTables] ON [DatabasesTables].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#DatabasesTables] SELECT [Id]
,[DatabaseId]
,[TableId]
,[Description]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Columns
**********************************************************************************/
IF (SELECT object_id('[dbo].[Columns]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Columns]
CREATE TABLE [dbo].[Columns](
[Id] bigint NOT NULL
,[TableId] bigint NOT NULL
,[Sequence] smallint NOT NULL
,[DomainId] bigint NOT NULL
,[ReferenceTableId] bigint NULL
,[Name] varchar(25) NOT NULL
,[Description] varchar(50) NOT NULL
,[Title] varchar(25) NOT NULL
,[Caption] varchar(25) NOT NULL
,[ValidValues] varchar(MAX) NULL
,[Default] sql_variant NULL
,[Minimum] sql_variant NULL
,[Maximum] sql_variant NULL
,[IsPrimarykey] bit NULL
,[IsAutoIncrement] bit NULL
,[IsRequired] bit NOT NULL
,[IsListable] bit NULL
,[IsFilterable] bit NULL
,[IsEditable] bit NULL
,[IsBrowseable] bit NULL
,[IsEncrypted] bit NULL
,[IsCalculated] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Columns] ADD CONSTRAINT PK_Columns PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Columns_TableId_Name] ON [dbo].[Columns]([TableId] ASC,[Name] ASC)
CREATE UNIQUE INDEX [UNQ_Columns_TableId_Sequence] ON [dbo].[Columns]([TableId] ASC,[Sequence] ASC)
GO
/**********************************************************************************
Criar procedure ColumnsCreate
**********************************************************************************/
IF(SELECT object_id('ColumnsCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[ColumnsCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_Title varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
,@W_Caption varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_IsPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
,@W_IsRequired bit = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
,@W_IsListable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
,@W_IsFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
,@W_IsEditable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
,@W_IsBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
,@W_IsEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
,@W_IsCalculated bit = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_DomainId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId não existe em Domains';
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
IF @W_ReferenceTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ReferenceTableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Title IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Title é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsRequired IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsRequired é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsCalculated IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsCalculated é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Columns.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Columns] ([Id]
,[TableId]
,[Sequence]
,[DomainId]
,[ReferenceTableId]
,[Name]
,[Description]
,[Title]
,[Caption]
,[ValidValues]
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
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_TableId
,@W_Sequence
,@W_DomainId
,@W_ReferenceTableId
,@W_Name
,@W_Description
,@W_Title
,@W_Caption
,@W_ValidValues
,@W_Default
,@W_Minimum
,@W_Maximum
,@W_IsPrimarykey
,@W_IsAutoIncrement
,@W_IsRequired
,@W_IsListable
,@W_IsFilterable
,@W_IsEditable
,@W_IsBrowseable
,@W_IsEncrypted
,@W_IsCalculated
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[ColumnsUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_Title varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
,@W_Caption varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_IsPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
,@W_IsRequired bit = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
,@W_IsListable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
,@W_IsFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
,@W_IsEditable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
,@W_IsBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
,@W_IsEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
,@W_IsCalculated bit = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_DomainId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId não existe em Domains';
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
IF @W_ReferenceTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ReferenceTableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Title IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Title é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsRequired IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsRequired é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsCalculated IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsCalculated é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Columns]
SET [TableId] = @W_TableId
,[Sequence] = @W_Sequence
,[DomainId] = @W_DomainId
,[ReferenceTableId] = @W_ReferenceTableId
,[Name] = @W_Name
,[Description] = @W_Description
,[Title] = @W_Title
,[Caption] = @W_Caption
,[ValidValues] = @W_ValidValues
,[Default] = @W_Default
,[Minimum] = @W_Minimum
,[Maximum] = @W_Maximum
,[IsPrimarykey] = @W_IsPrimarykey
,[IsAutoIncrement] = @W_IsAutoIncrement
,[IsRequired] = @W_IsRequired
,[IsListable] = @W_IsListable
,[IsFilterable] = @W_IsFilterable
,[IsEditable] = @W_IsEditable
,[IsBrowseable] = @W_IsBrowseable
,[IsEncrypted] = @W_IsEncrypted
,[IsCalculated] = @W_IsCalculated
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[ColumnsDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Columns]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[ColumnsRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
,@W_Title varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
,@W_Caption varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
,@W_IsPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
,@W_IsRequired bit = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
,@W_IsListable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
,@W_IsFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
,@W_IsEditable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
,@W_IsBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
,@W_IsEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
,@W_IsCalculated bit = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_DomainId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId não existe em Domains';
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
IF @W_ReferenceTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ReferenceTableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Description IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Title IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Title é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_Caption IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsRequired IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsRequired é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsCalculated IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsCalculated é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'TableId') AS bigint) AS [TableId]
,CAST(JSON_VALUE([ActualRecord], 'Sequence') AS smallint) AS [Sequence]
,CAST(JSON_VALUE([ActualRecord], 'DomainId') AS bigint) AS [DomainId]
,CAST(JSON_VALUE([ActualRecord], 'ReferenceTableId') AS bigint) AS [ReferenceTableId]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(25)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'Description') AS varchar(50)) AS [Description]
,CAST(JSON_VALUE([ActualRecord], 'Title') AS varchar(25)) AS [Title]
,CAST(JSON_VALUE([ActualRecord], 'Caption') AS varchar(25)) AS [Caption]
,CAST(JSON_VALUE([ActualRecord], 'ValidValues') AS varchar(MAX)) AS [ValidValues]
,CAST(JSON_VALUE([ActualRecord], 'Default') AS sql_variant) AS [Default]
,CAST(JSON_VALUE([ActualRecord], 'Minimum') AS sql_variant) AS [Minimum]
,CAST(JSON_VALUE([ActualRecord], 'Maximum') AS sql_variant) AS [Maximum]
,CAST(JSON_VALUE([ActualRecord], 'IsPrimarykey') AS bit) AS [IsPrimarykey]
,CAST(JSON_VALUE([ActualRecord], 'IsAutoIncrement') AS bit) AS [IsAutoIncrement]
,CAST(JSON_VALUE([ActualRecord], 'IsRequired') AS bit) AS [IsRequired]
,CAST(JSON_VALUE([ActualRecord], 'IsListable') AS bit) AS [IsListable]
,CAST(JSON_VALUE([ActualRecord], 'IsFilterable') AS bit) AS [IsFilterable]
,CAST(JSON_VALUE([ActualRecord], 'IsEditable') AS bit) AS [IsEditable]
,CAST(JSON_VALUE([ActualRecord], 'IsBrowseable') AS bit) AS [IsBrowseable]
,CAST(JSON_VALUE([ActualRecord], 'IsEncrypted') AS bit) AS [IsEncrypted]
,CAST(JSON_VALUE([ActualRecord], 'IsCalculated') AS bit) AS [IsCalculated]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[TableId]
,[Sequence]
,[DomainId]
,[ReferenceTableId]
,[Name]
,[Description]
,[Title]
,[Caption]
,[ValidValues]
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
INTO[dbo].[#Columns]
FROM [dbo].[Columns]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [TableId] = ISNULL(@W_TableId, [TableId])
AND [DomainId] = ISNULL(@W_DomainId, [DomainId])
AND (@W_ReferenceTableId IS NULL OR [ReferenceTableId] = @W_ReferenceTableId)
AND [Name] = ISNULL(@W_Name, [Name])
AND (@W_IsAutoIncrement IS NULL OR [IsAutoIncrement] = @W_IsAutoIncrement)
AND [IsRequired] = ISNULL(@W_IsRequired, [IsRequired])
AND (@W_IsListable IS NULL OR [IsListable] = @W_IsListable)
AND (@W_IsFilterable IS NULL OR [IsFilterable] = @W_IsFilterable)
AND (@W_IsEditable IS NULL OR [IsEditable] = @W_IsEditable)
AND (@W_IsBrowseable IS NULL OR [IsBrowseable] = @W_IsBrowseable)
AND (@W_IsEncrypted IS NULL OR [IsEncrypted] = @W_IsEncrypted)
AND [IsCalculated] = ISNULL(@W_IsCalculated, [IsCalculated])
SET @RowCount = @@ROWCOUNT
DELETE [Columns]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Columns] [Columns] ON [Columns].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Columns] SELECT [Id]
,[TableId]
,[Sequence]
,[DomainId]
,[ReferenceTableId]
,[Name]
,[Description]
,[Title]
,[Caption]
,[ValidValues]
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
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Indexes
**********************************************************************************/
IF (SELECT object_id('[dbo].[Indexes]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Indexes]
CREATE TABLE [dbo].[Indexes](
[Id] bigint NOT NULL
,[DatabaseId] bigint NOT NULL
,[TableId] bigint NOT NULL
,[Name] varchar(50) NOT NULL
,[IsUnique] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Indexes] ADD CONSTRAINT PK_Indexes PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Indexes_DatabaseId_Name] ON [dbo].[Indexes]([DatabaseId] ASC,[Name] ASC)
GO
/**********************************************************************************
Criar procedure IndexesCreate
**********************************************************************************/
IF(SELECT object_id('IndexesCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexesCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Name varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(50))
,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsUnique IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsUnique é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Indexes.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [DatabaseId] = @W_DatabaseId AND [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexes_DatabaseId_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Indexes] ([Id]
,[DatabaseId]
,[TableId]
,[Name]
,[IsUnique]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_DatabaseId
,@W_TableId
,@W_Name
,@W_IsUnique
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[IndexesUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Name varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(50))
,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsUnique IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsUnique é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexes.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [DatabaseId] = @W_DatabaseId AND [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexes_DatabaseId_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Indexes]
SET [DatabaseId] = @W_DatabaseId
,[TableId] = @W_TableId
,[Name] = @W_Name
,[IsUnique] = @W_IsUnique
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[IndexesDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexes.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Indexes]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[IndexesRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
,@W_Name varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(50))
,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de DatabaseId não existe em Databases';
THROW 51000, @ErrorMessage, 1
END
IF @W_TableId IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
THROW 51000, @ErrorMessage, 1
END
IF @W_Name IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsUnique IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsUnique é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [DatabaseId] = @W_DatabaseId AND [Name] = @W_Name) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexes_DatabaseId_Name já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'DatabaseId') AS bigint) AS [DatabaseId]
,CAST(JSON_VALUE([ActualRecord], 'TableId') AS bigint) AS [TableId]
,CAST(JSON_VALUE([ActualRecord], 'Name') AS varchar(50)) AS [Name]
,CAST(JSON_VALUE([ActualRecord], 'IsUnique') AS bit) AS [IsUnique]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[DatabaseId]
,[TableId]
,[Name]
,[IsUnique]
INTO[dbo].[#Indexes]
FROM [dbo].[Indexes]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [TableId] = ISNULL(@W_TableId, [TableId])
AND [Name] = ISNULL(@W_Name, [Name])
AND [IsUnique] = ISNULL(@W_IsUnique, [IsUnique])
SET @RowCount = @@ROWCOUNT
DELETE [Indexes]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Indexes] [Indexes] ON [Indexes].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Indexes] SELECT [Id]
,[DatabaseId]
,[TableId]
,[Name]
,[IsUnique]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Indexkeys
**********************************************************************************/
IF (SELECT object_id('[dbo].[Indexkeys]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Indexkeys]
CREATE TABLE [dbo].[Indexkeys](
[Id] bigint NOT NULL
,[IndexId] bigint NOT NULL
,[Sequence] smallint NOT NULL
,[ColumnId] bigint NOT NULL
,[IsDescending] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Indexkeys] ADD CONSTRAINT PK_Indexkeys PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Indexkeys_IndexId_Sequence] ON [dbo].[Indexkeys]([IndexId] ASC,[Sequence] ASC)
CREATE UNIQUE INDEX [UNQ_Indexkeys_IndexId_Column] ON [dbo].[Indexkeys]([IndexId] ASC,[ColumnId] ASC)
GO
/**********************************************************************************
Criar procedure IndexkeysCreate
**********************************************************************************/
IF(SELECT object_id('IndexkeysCreate', 'P')) IS NULL
EXEC('CREATE PROCEDURE [dbo].[IndexkeysCreate] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'create' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de IndexId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_IndexId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IndexId não existe em Indexes';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de ColumnId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_ColumnId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ColumnId não existe em Columns';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsDescending IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsDescending é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Indexkeys.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexkeys_IndexId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [ColumnId] = @W_ColumnId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexkeys_IndexId_Column já existe.';
THROW 51000, @ErrorMessage, 1
END
INSERT INTO [dbo].[Indexkeys] ([Id]
,[IndexId]
,[Sequence]
,[ColumnId]
,[IsDescending]
,[CreatedAt]
,[CreatedBy]
)
VALUES (@W_Id
,@W_IndexId
,@W_Sequence
,@W_ColumnId
,@W_IsDescending
,GETDATE()
,@UserName
)
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[IndexkeysUpdate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'update' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de alteração.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de IndexId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_IndexId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IndexId não existe em Indexes';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de ColumnId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_ColumnId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ColumnId não existe em Columns';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsDescending IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsDescending é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexkeys.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexkeys_IndexId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [ColumnId] = @W_ColumnId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexkeys_IndexId_Column já existe.';
THROW 51000, @ErrorMessage, 1
END
UPDATE [dbo].[Indexkeys]
SET [IndexId] = @W_IndexId
,[Sequence] = @W_Sequence
,[ColumnId] = @W_ColumnId
,[IsDescending] = @W_IsDescending
,[UpdatedAt] = GETDATE()
,[UpdatedBy] = @UserName
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[IndexkeysDelete](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'delete' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [Id] = @W_Id) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexkeys.';
THROW 51000, @ErrorMessage, 1
END
DELETE FROM [dbo].[Indexkeys]
WHERE [Id] = @W_Id
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
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
ALTER PROCEDURE[dbo].[IndexkeysRead](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
DECLARE @ErrorMessage VARCHAR(255)
IF ISJSON(@Parameters) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
IF ISJSON(@Login) = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
THROW 51000, @ErrorMessage, 1
END
EXEC [dbo].[P_Login] @Login
DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
,@TransactionId BIGINT
,@TableId BIGINT
,@Action VARCHAR(15)
,@ActualRecord VARCHAR(MAX)
,@IsConfirmed BIT
SELECT @TransactionId = [TransactionId]
,@TableId = [TableId]
,@Action = [Action]
,@ActualRecord = [ActualRecord]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Operations]
WHERE [Id] = @OperationId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @Action <> 'read' BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação não é de consulta.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Tables]
WHERE [Id] = @TableId) <> @TableName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @SystemId BIGINT
,@DatabaseId BIGINT
SELECT @SystemId = [SystemId]
,@DatabaseId = [DatabaseId]
,@IsConfirmed = [IsConfirmed]
FROM [dbo].[Transactions]
WHERE [Id] = @TransactionId
IF @@ROWCOUNT = 0 BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
THROW 51000, @ErrorMessage, 1
END
IF @IsConfirmed IS NOT NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Transação já ' +
CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Systems]
WHERE [Id] = @SystemId) <> @SystemName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF (SELECT [Name]
FROM [dbo].[Databases]
WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
THROW 51000, @ErrorMessage, 1
END
IF NOT EXISTS(SELECT 1
FROM [dbo].[DatabasesTables]
WHERE [DatabaseId] = @DatabaseId
AND [TableId] = @TableId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
THROW 51000, @ErrorMessage, 1
END
DECLARE @PageNumber INT --OUT
,@LimitRows BIGINT --OUT
,@MaxPage INT --OUT
,@PaddingGridLastPage BIT --OUT
,@RowCount BIGINT
,@LoginId BIGINT
,@OffSet INT
DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
IF @W_Id IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de IndexId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_IndexId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IndexId não existe em Indexes';
THROW 51000, @ErrorMessage, 1
END
IF @W_Sequence IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
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
SET @ErrorMessage = @ErrorMessage + 'Valor de ColumnId é requerido.';
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
IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_ColumnId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de ColumnId não existe em Columns';
THROW 51000, @ErrorMessage, 1
END
IF @W_IsDescending IS NULL BEGIN
SET @ErrorMessage = @ErrorMessage + 'Valor de IsDescending é requerido.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [Sequence] = @W_Sequence) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexkeys_IndexId_Sequence já existe.';
THROW 51000, @ErrorMessage, 1
END
IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [ColumnId] = @W_ColumnId) BEGIN
SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Indexkeys_IndexId_Column já existe.';
THROW 51000, @ErrorMessage, 1
END
SELECT [Action] AS [_]
,CAST(JSON_VALUE([ActualRecord], 'Id') AS bigint) AS [Id]
,CAST(JSON_VALUE([ActualRecord], 'IndexId') AS bigint) AS [IndexId]
,CAST(JSON_VALUE([ActualRecord], 'Sequence') AS smallint) AS [Sequence]
,CAST(JSON_VALUE([ActualRecord], 'ColumnId') AS bigint) AS [ColumnId]
,CAST(JSON_VALUE([ActualRecord], 'IsDescending') AS bit) AS [IsDescending]
INTO [dbo].[#Operations]
FROM [dbo].[Operations]
WHERE [TransactionId] = @TransactionId
AND [TableId] = @TableId
AND [IsConfirmed] IS NULL
CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])
SELECT [Id]
,[IndexId]
,[Sequence]
,[ColumnId]
,[IsDescending]
INTO[dbo].[#Indexkeys]
FROM [dbo].[Indexkeys]
WHERE [Id] = ISNULL(@W_Id, [Id])
AND [IndexId] = ISNULL(@W_IndexId, [IndexId])
AND [ColumnId] = ISNULL(@W_ColumnId, [ColumnId])
AND [IsDescending] = ISNULL(@W_IsDescending, [IsDescending])
SET @RowCount = @@ROWCOUNT
DELETE [Indexkeys]
FROM [dbo].[#Operations] [Operations]
INNER JOIN [dbo].[#Indexkeys] [Indexkeys] ON [Indexkeys].[Id] = [Operations].[Id]
WHERE [Operations].[_] = 'delete'
SET @RowCount = @RowCount - @@ROWCOUNT
INSERT [dbo].[#Indexkeys] SELECT [Id]
,[IndexId]
,[Sequence]
,[ColumnId]
,[IsDescending]
FROM [dbo].[#Operations]
WHERE [_] = 'create'
SET @RowCount = @RowCount + @@ROWCOUNT
UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
RETURN 1
END TRY
BEGIN CATCH
THROW
END CATCH
END
GO
/**********************************************************************************
Criar tabela Logins
**********************************************************************************/
IF (SELECT object_id('[dbo].[Logins]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Logins]
CREATE TABLE [dbo].[Logins](
[Id] bigint NOT NULL
,[SystemId] bigint NOT NULL
,[UserId] bigint NOT NULL
,[PublicKey] varchar(256) NOT NULL
,[IsLogged] bit NOT NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Logins] ADD CONSTRAINT PK_Logins PRIMARY KEY CLUSTERED ([Id])
CREATE INDEX [UNQ_Logins_SystemId_UserId_IsLogged] ON [dbo].[Logins]([SystemId] ASC,[UserId] ASC,[IsLogged] ASC)
GO
/**********************************************************************************
Criar tabela Transactions
**********************************************************************************/
IF (SELECT object_id('[dbo].[Transactions]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Transactions]
CREATE TABLE [dbo].[Transactions](
[Id] bigint NOT NULL
,[LoginId] bigint NOT NULL
,[SystemId] bigint NOT NULL
,[DatabaseId] bigint NOT NULL
,[IsConfirmed] bit NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Transactions] ADD CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED ([Id])
CREATE INDEX [UNQ_Transactions_LoginId_SystemId_DatabaseId] ON [dbo].[Transactions]([LoginId] ASC,[SystemId] ASC,[DatabaseId] ASC)
GO
/**********************************************************************************
Criar tabela Operations
**********************************************************************************/
IF (SELECT object_id('[dbo].[Operations]', 'U')) IS NOT NULL
DROP TABLE [dbo].[Operations]
CREATE TABLE [dbo].[Operations](
[Id] bigint NOT NULL
,[TransactionId] bigint NOT NULL
,[TableId] bigint NOT NULL
,[Action] varchar(15) NOT NULL
,[LastRecord] varchar(MAX) NULL
,[ActualRecord] varchar(MAX) NOT NULL
,[IsConfirmed] bit NULL
,[CreatedAt] datetime NOT NULL
,[CreatedBy] varchar(25) NOT NULL
,[UpdatedAt] datetime NULL
,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Operations] ADD CONSTRAINT PK_Operations PRIMARY KEY CLUSTERED ([Id])
CREATE INDEX [UNQ_Operations_TransactionId_TableId_Action] ON [dbo].[Operations]([TransactionId] ASC,[TableId] ASC,[Action] ASC)
GO
/**********************************************************************************
Criar referências de Types)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Types_Categories')
ALTER TABLE [dbo].[Types] DROP CONSTRAINT FK_Types_Categories
GO
ALTER TABLE [dbo].[Types] WITH CHECK ADD CONSTRAINT [FK_Types_Categories] FOREIGN KEY([CategoryId]) REFERENCES [dbo].[Categories] ([Id])
GO
ALTER TABLE [dbo].[Types] CHECK CONSTRAINT [FK_Types_Categories]
GO
/**********************************************************************************
Criar referências de Domains)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Domains_Types')
ALTER TABLE [dbo].[Domains] DROP CONSTRAINT FK_Domains_Types
GO
ALTER TABLE [dbo].[Domains] WITH CHECK ADD CONSTRAINT [FK_Domains_Types] FOREIGN KEY([TypeId]) REFERENCES [dbo].[Types] ([Id])
GO
ALTER TABLE [dbo].[Domains] CHECK CONSTRAINT [FK_Domains_Types]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Domains_Masks')
ALTER TABLE [dbo].[Domains] DROP CONSTRAINT FK_Domains_Masks
GO
ALTER TABLE [dbo].[Domains] WITH CHECK ADD CONSTRAINT [FK_Domains_Masks] FOREIGN KEY([MaskId]) REFERENCES [dbo].[Masks] ([Id])
GO
ALTER TABLE [dbo].[Domains] CHECK CONSTRAINT [FK_Domains_Masks]
GO
/**********************************************************************************
Criar referências de Menus)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Menus_Systems')
ALTER TABLE [dbo].[Menus] DROP CONSTRAINT FK_Menus_Systems
GO
ALTER TABLE [dbo].[Menus] WITH CHECK ADD CONSTRAINT [FK_Menus_Systems] FOREIGN KEY([SystemId]) REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[Menus] CHECK CONSTRAINT [FK_Menus_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Menus_Menus')
ALTER TABLE [dbo].[Menus] DROP CONSTRAINT FK_Menus_Menus
GO
ALTER TABLE [dbo].[Menus] WITH CHECK ADD CONSTRAINT [FK_Menus_Menus] FOREIGN KEY([ParentMenuId]) REFERENCES [dbo].[Menus] ([Id])
GO
ALTER TABLE [dbo].[Menus] CHECK CONSTRAINT [FK_Menus_Menus]
GO
/**********************************************************************************
Criar referências de SystemsUsers)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsUsers_Systems')
ALTER TABLE [dbo].[SystemsUsers] DROP CONSTRAINT FK_SystemsUsers_Systems
GO
ALTER TABLE [dbo].[SystemsUsers] WITH CHECK ADD CONSTRAINT [FK_SystemsUsers_Systems] FOREIGN KEY([SystemId]) REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[SystemsUsers] CHECK CONSTRAINT [FK_SystemsUsers_Systems]
GO
/**********************************************************************************
Criar referências de SystemsDatabases)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsDatabases_Systems')
ALTER TABLE [dbo].[SystemsDatabases] DROP CONSTRAINT FK_SystemsDatabases_Systems
GO
ALTER TABLE [dbo].[SystemsDatabases] WITH CHECK ADD CONSTRAINT [FK_SystemsDatabases_Systems] FOREIGN KEY([SystemId]) REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[SystemsDatabases] CHECK CONSTRAINT [FK_SystemsDatabases_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsDatabases_Databases')
ALTER TABLE [dbo].[SystemsDatabases] DROP CONSTRAINT FK_SystemsDatabases_Databases
GO
ALTER TABLE [dbo].[SystemsDatabases] WITH CHECK ADD CONSTRAINT [FK_SystemsDatabases_Databases] FOREIGN KEY([DatabaseId]) REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[SystemsDatabases] CHECK CONSTRAINT [FK_SystemsDatabases_Databases]
GO
/**********************************************************************************
Criar referências de Tables)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Tables_Tables')
ALTER TABLE [dbo].[Tables] DROP CONSTRAINT FK_Tables_Tables
GO
ALTER TABLE [dbo].[Tables] WITH CHECK ADD CONSTRAINT [FK_Tables_Tables] FOREIGN KEY([ParentTableId]) REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Tables] CHECK CONSTRAINT [FK_Tables_Tables]
GO
/**********************************************************************************
Criar referências de DatabasesTables)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_DatabasesTables_Databases')
ALTER TABLE [dbo].[DatabasesTables] DROP CONSTRAINT FK_DatabasesTables_Databases
GO
ALTER TABLE [dbo].[DatabasesTables] WITH CHECK ADD CONSTRAINT [FK_DatabasesTables_Databases] FOREIGN KEY([DatabaseId]) REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[DatabasesTables] CHECK CONSTRAINT [FK_DatabasesTables_Databases]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_DatabasesTables_Tables')
ALTER TABLE [dbo].[DatabasesTables] DROP CONSTRAINT FK_DatabasesTables_Tables
GO
ALTER TABLE [dbo].[DatabasesTables] WITH CHECK ADD CONSTRAINT [FK_DatabasesTables_Tables] FOREIGN KEY([TableId]) REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[DatabasesTables] CHECK CONSTRAINT [FK_DatabasesTables_Tables]
GO
/**********************************************************************************
Criar referências de Columns)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Columns_Tables')
ALTER TABLE [dbo].[Columns] DROP CONSTRAINT FK_Columns_Tables
GO
ALTER TABLE [dbo].[Columns] WITH CHECK ADD CONSTRAINT [FK_Columns_Tables] FOREIGN KEY([TableId]) REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Columns] CHECK CONSTRAINT [FK_Columns_Tables]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Columns_Domains')
ALTER TABLE [dbo].[Columns] DROP CONSTRAINT FK_Columns_Domains
GO
ALTER TABLE [dbo].[Columns] WITH CHECK ADD CONSTRAINT [FK_Columns_Domains] FOREIGN KEY([DomainId]) REFERENCES [dbo].[Domains] ([Id])
GO
ALTER TABLE [dbo].[Columns] CHECK CONSTRAINT [FK_Columns_Domains]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Columns_Tables')
ALTER TABLE [dbo].[Columns] DROP CONSTRAINT FK_Columns_Tables
GO
ALTER TABLE [dbo].[Columns] WITH CHECK ADD CONSTRAINT [FK_Columns_Tables] FOREIGN KEY([ReferenceTableId]) REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Columns] CHECK CONSTRAINT [FK_Columns_Tables]
GO
/**********************************************************************************
Criar referências de Indexes)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexes_Databases')
ALTER TABLE [dbo].[Indexes] DROP CONSTRAINT FK_Indexes_Databases
GO
ALTER TABLE [dbo].[Indexes] WITH CHECK ADD CONSTRAINT [FK_Indexes_Databases] FOREIGN KEY([DatabaseId]) REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[Indexes] CHECK CONSTRAINT [FK_Indexes_Databases]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexes_Tables')
ALTER TABLE [dbo].[Indexes] DROP CONSTRAINT FK_Indexes_Tables
GO
ALTER TABLE [dbo].[Indexes] WITH CHECK ADD CONSTRAINT [FK_Indexes_Tables] FOREIGN KEY([TableId]) REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Indexes] CHECK CONSTRAINT [FK_Indexes_Tables]
GO
/**********************************************************************************
Criar referências de Indexkeys)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexkeys_Indexes')
ALTER TABLE [dbo].[Indexkeys] DROP CONSTRAINT FK_Indexkeys_Indexes
GO
ALTER TABLE [dbo].[Indexkeys] WITH CHECK ADD CONSTRAINT [FK_Indexkeys_Indexes] FOREIGN KEY([IndexId]) REFERENCES [dbo].[Indexes] ([Id])
GO
ALTER TABLE [dbo].[Indexkeys] CHECK CONSTRAINT [FK_Indexkeys_Indexes]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexkeys_Columns')
ALTER TABLE [dbo].[Indexkeys] DROP CONSTRAINT FK_Indexkeys_Columns
GO
ALTER TABLE [dbo].[Indexkeys] WITH CHECK ADD CONSTRAINT [FK_Indexkeys_Columns] FOREIGN KEY([ColumnId]) REFERENCES [dbo].[Columns] ([Id])
GO
ALTER TABLE [dbo].[Indexkeys] CHECK CONSTRAINT [FK_Indexkeys_Columns]
GO
/**********************************************************************************
Criar referências de Logins)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Logins_Systems')
ALTER TABLE [dbo].[Logins] DROP CONSTRAINT FK_Logins_Systems
GO
ALTER TABLE [dbo].[Logins] WITH CHECK ADD CONSTRAINT [FK_Logins_Systems] FOREIGN KEY([SystemId]) REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[Logins] CHECK CONSTRAINT [FK_Logins_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Logins_Users')
ALTER TABLE [dbo].[Logins] DROP CONSTRAINT FK_Logins_Users
GO
ALTER TABLE [dbo].[Logins] WITH CHECK ADD CONSTRAINT [FK_Logins_Users] FOREIGN KEY([UserId]) REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Logins] CHECK CONSTRAINT [FK_Logins_Users]
GO
/**********************************************************************************
Criar referências de Transactions)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Transactions_Logins')
ALTER TABLE [dbo].[Transactions] DROP CONSTRAINT FK_Transactions_Logins
GO
ALTER TABLE [dbo].[Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_Logins] FOREIGN KEY([LoginId]) REFERENCES [dbo].[Logins] ([Id])
GO
ALTER TABLE [dbo].[Transactions] CHECK CONSTRAINT [FK_Transactions_Logins]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Transactions_Systems')
ALTER TABLE [dbo].[Transactions] DROP CONSTRAINT FK_Transactions_Systems
GO
ALTER TABLE [dbo].[Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_Systems] FOREIGN KEY([SystemId]) REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[Transactions] CHECK CONSTRAINT [FK_Transactions_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Transactions_Databases')
ALTER TABLE [dbo].[Transactions] DROP CONSTRAINT FK_Transactions_Databases
GO
ALTER TABLE [dbo].[Transactions] WITH CHECK ADD CONSTRAINT [FK_Transactions_Databases] FOREIGN KEY([DatabaseId]) REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[Transactions] CHECK CONSTRAINT [FK_Transactions_Databases]
GO
/**********************************************************************************
Criar referências de Operations)
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Operations_Transactions')
ALTER TABLE [dbo].[Operations] DROP CONSTRAINT FK_Operations_Transactions
GO
ALTER TABLE [dbo].[Operations] WITH CHECK ADD CONSTRAINT [FK_Operations_Transactions] FOREIGN KEY([TransactionId]) REFERENCES [dbo].[Transactions] ([Id])
GO
ALTER TABLE [dbo].[Operations] CHECK CONSTRAINT [FK_Operations_Transactions]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Operations_Tables')
ALTER TABLE [dbo].[Operations] DROP CONSTRAINT FK_Operations_Tables
GO
ALTER TABLE [dbo].[Operations] WITH CHECK ADD CONSTRAINT [FK_Operations_Tables] FOREIGN KEY([TableId]) REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Operations] CHECK CONSTRAINT [FK_Operations_Tables]
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
GO
/**********************************************************************************
Inserir dados na tabela Masks
**********************************************************************************/
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt,
CreatedBy) VALUES (
'1', 
'BigInteger', 
'#.###.###.###.###.###', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'Integer', 
'#.###.###.###', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt,
CreatedBy) VALUES (
'3', 
'SmallInteger', 
'##.###', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt,
CreatedBy) VALUES (
'4', 
'TinyInteger', 
'###', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt,
CreatedBy) VALUES (
'5', 
'ShortInteger', 
'##.###', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Masks] (
[Id], 
[Name], 
[Mask], 
CreatedAt,
CreatedBy) VALUES (
'6', 
'DateTime', 
'dd/MM/yyyy hh:mm:ss', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'18', 
'33', 
NULL, 
'Codification', 
'5', 
NULL, 
'JSON;JS;SQL', 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'20', 
'33', 
NULL, 
'HtmlInputAlign', 
'6', 
NULL, 
'left;center;right', 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'21', 
'33', 
NULL, 
'Action', 
'15', 
NULL, 
'create;read;update;delete;commit;rollback', 
NULL, 
NULL, 
NULL, 
NULL, 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'cruda', 
'CRUD Automático', 
'DAYCOVAL', 
'5', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'1', 
'5', 
'Cadastros', 
'Cadastros', 
NULL, 
NULL, 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'1', 
'10', 
'Usuários', 
'Cadastro de Usuários', 
'grid/cruda/Users', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'3', 
'1', 
'15', 
'Tabelas', 
'Cadastro de tabelas', 
'grid/cruda/Tables', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'4', 
'1', 
'20', 
'Menus', 
'Cadastro de menus', 
'grid/cruda/Menus', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'5', 
'1', 
'25', 
'Sistemas', 
'Cadastro de sistemas', 
'grid/cruda/Systems', 
'3', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'6', 
'1', 
'30', 
'Banco de Dados', 
'Cadastro de bancos de dados', 
'grid/cruda/Databases', 
'3', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'7', 
'1', 
'35', 
'Colunas', 
'Cadastro de colunas de tabelas', 
'grid/cruda/Columns', 
'7', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'8', 
'1', 
'40', 
'Tipos', 
'Cadastro de tipos', 
'grid/cruda/Types', 
'7', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'9', 
'1', 
'45', 
'Associações', 
'Associações entre tabelas', 
NULL, 
NULL, 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'10', 
'1', 
'50', 
'Sistemas x BD', 
'Associação entre sistemas e bancos de dados', 
'grid/cruda/SystemsDatabases', 
'9', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'11', 
'1', 
'55', 
'Usuários x Sistemas', 
'Associação entre usuários e sistemas', 
'grid/cruda/SystemsUsers', 
'9', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Menus] (
[Id], 
[SystemId], 
[Sequence], 
[Caption], 
[Message], 
[Action], 
[ParentMenuId], 
CreatedAt,
CreatedBy) VALUES (
'12', 
'1', 
'60', 
'Sair', 
'Retornar ao login', 
'exit/login', 
NULL, 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'adm', 
'adm', 
'Administrador', 
'0', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Users] (
[Id], 
[Name], 
[Password], 
[FullName], 
[RetryLogins], 
[IsActive], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'labrego', 
'diva', 
'João da Rocha Labrego', 
'0', 
'1', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'1', 
'1', 
'cruda x adm', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[SystemsUsers] (
[Id], 
[SystemId], 
[UserId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'1', 
'2', 
'cruda x labrego', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'1', 
'1', 
'cruda x cruda', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'Categories', 
'Category', 
'Categorias de tipos de dados', 
NULL, 
'CategoriesCreate', 
'CategoriesRead', 
'CategoriesUpdate', 
'CategoriesDelete', 
'CategoriesList', 
'1', 
'10', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'21', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'2', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'2', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'18', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'18', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'140', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'25', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
'40', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'16', 
'Logins', 
'Login', 
'Logins de Acesso aos Sistemas', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
'0', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'17', 
'Transactions', 
'Transaction', 
'Transações em Bancos-de-Dados', 
'16', 
NULL, 
NULL, 
NULL, 
NULL, 
NULL, 
'0', 
'0', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'1', 
'1', 
'cruda x Categories', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'1', 
'2', 
'cruda x Types', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'3', 
'1', 
'3', 
'cruda x Masks', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'4', 
'1', 
'4', 
'cruda x Domains', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'5', 
'1', 
'5', 
'cruda x Systems', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'6', 
'1', 
'6', 
'cruda x Menus', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'7', 
'1', 
'7', 
'cruda x Users', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'8', 
'1', 
'8', 
'cruda x SystemsUsers', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'9', 
'1', 
'9', 
'cruda x Databases', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'10', 
'1', 
'10', 
'cruda x SystemsDatabases', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'11', 
'1', 
'11', 
'cruda x Tables', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'12', 
'1', 
'12', 
'cruda x DatabasesTables', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'13', 
'1', 
'13', 
'cruda x Columns', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'14', 
'1', 
'14', 
'cruda x Indexes', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'15', 
'1', 
'15', 
'cruda x Indexkeys', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'16', 
'1', 
'16', 
'cruda x Logs', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'17', 
'1', 
'17', 
'cruda x Transactions', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[DatabasesTables] (
[Id], 
[DatabaseId], 
[TableId], 
[Description], 
CreatedAt,
CreatedBy) VALUES (
'18', 
'1', 
'18', 
'cruda x Operations', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
'0', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'0', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'44', 
'5', 
'25', 
'5', 
NULL, 
'MaxRetryLogins', 
'Máximo de tentativas de logins', 
'Máximo de logins', 
'Máximo de logins', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'51', 
'6', 
'35', 
'1', 
'6', 
'ParentMenuId', 
'ID do menu-pai', 
'Menu-pai', 
'Menu-pai', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'56', 
'7', 
'25', 
'5', 
NULL, 
'RetryLogins', 
'Tentativas de login', 
'Tentativas de login', 
'Tentativas de login', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'80', 
'11', 
'25', 
'1', 
'11', 
'ParentTableId', 
'ID tabela-pai', 
'Tabela-pai', 
'Tabela-pai', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'87', 
'11', 
'60', 
'1', 
NULL, 
'LastId', 
'Último Id', 
'Último Id', 
'Último Id', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'93', 
'13', 
'10', 
'1', 
'11', 
'TableId', 
'Tabela', 
'Tabela', 
'Tabela', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'95', 
'13', 
'20', 
'1', 
'4', 
'DomainId', 
'Domínio da coluna', 
'Domínio', 
'Domínio', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'96', 
'13', 
'25', 
'1', 
'11', 
'ReferenceTableId', 
'Tabela-referência', 
'Referência', 
'Referência', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'101', 
'13', 
'50', 
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
'0', 
NULL, 
'0', 
NULL, 
'0', 
'1', 
'0', 
'0', 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'102', 
'13', 
'55', 
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'103', 
'13', 
'60', 
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'104', 
'13', 
'65', 
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'105', 
'13', 
'70', 
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
NULL, 
'0', 
NULL, 
NULL, 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'106', 
'13', 
'75', 
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'107', 
'13', 
'80', 
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'108', 
'13', 
'85', 
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'109', 
'13', 
'90', 
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'110', 
'13', 
'95', 
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'111', 
'13', 
'100', 
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'112', 
'13', 
'105', 
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
NULL, 
'0', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'113', 
'13', 
'110', 
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'114', 
'14', 
'5', 
'1', 
NULL, 
'Id', 
'ID do índice', 
'ID', 
'ID', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'115', 
'14', 
'10', 
'1', 
'9', 
'DatabaseId', 
'ID do banco-de-dados do índice', 
'Banco-de-dados', 
'Banco-de-dados', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'116', 
'14', 
'15', 
'1', 
'11', 
'TableId', 
'ID da tabela do índice', 
'Tabela', 
'Tabela', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'117', 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'118', 
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'119', 
'15', 
'5', 
'1', 
NULL, 
'Id', 
'ID da chave de índice', 
'ID', 
'ID', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'120', 
'15', 
'10', 
'1', 
'14', 
'IndexId', 
'ID do índice da chave', 
'Índice', 
'Índice', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'121', 
'15', 
'15', 
'4', 
NULL, 
'Sequence', 
'Sequência da chave', 
'Sequência', 
'Sequência', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'122', 
'15', 
'20', 
'1', 
'13', 
'ColumnId', 
'ID da coluna-chave do índice', 
'Coluna', 
'Coluna', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'123', 
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
NULL, 
'1', 
NULL, 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'124', 
'16', 
'5', 
'1', 
NULL, 
'Id', 
'ID do Login de Acesso', 
'ID', 
'ID', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'125', 
'16', 
'10', 
'1', 
'5', 
'SystemId', 
'ID do Sistema', 
'Sistema', 
'Sistema', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'126', 
'16', 
'15', 
'1', 
'7', 
'UserId', 
'ID do usuário', 
'Usuário', 
'Usuário', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'127', 
'16', 
'20', 
'11', 
NULL, 
'PublicKey', 
'Chave pública do usuário', 
'Chave pública', 
'Chave pública', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'128', 
'16', 
'25', 
'6', 
NULL, 
'IsLogged', 
'Logado?', 
'Logado?', 
'Logado?', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'129', 
'17', 
'5', 
'1', 
NULL, 
'Id', 
'ID  da Atualização', 
'ID', 
'ID', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'130', 
'17', 
'10', 
'1', 
'16', 
'LoginId', 
'ID do Login de Acesso', 
'Log de Acesso', 
'Log de Acesso', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'131', 
'17', 
'15', 
'1', 
'5', 
'SystemId', 
'ID do Sistema', 
'Sistema', 
'Sistema', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'132', 
'17', 
'20', 
'1', 
'9', 
'DatabaseId', 
'ID do Banco-de-dados', 
'Banco-de-dados', 
'Banco-de-dados', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'133', 
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
NULL, 
'0', 
'1', 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'134', 
'18', 
'5', 
'1', 
NULL, 
'Id', 
'ID  da Atualização', 
'ID', 
'ID', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'135', 
'18', 
'10', 
'1', 
'17', 
'TransactionId', 
'Id da Transação', 
'Transação', 
'Transação', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'136', 
'18', 
'15', 
'1', 
'11', 
'TableId', 
'Id da Tabela', 
'Tabela', 
'Tabela', 
NULL, 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'137', 
'18', 
'20', 
'21', 
NULL, 
'Action', 
'Ação de Atualização', 
'Ação', 
'Ação', 
'create;read;update;delete', 
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
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'138', 
'18', 
'25', 
'15', 
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
NULL, 
'0', 
NULL, 
NULL, 
'0', 
'0', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'139', 
'18', 
'30', 
'15', 
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
NULL, 
'1', 
NULL, 
NULL, 
'0', 
'0', 
NULL, 
'0', 
GETDATE(),
'adm')
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
[ValidValues], 
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
CreatedAt,
CreatedBy) VALUES (
'140', 
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
NULL, 
'0', 
'1', 
'1', 
'1', 
'1', 
NULL, 
'0', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'1', 
'1', 
'UNQ_Categories_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'1', 
'2', 
'UNQ_Types_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'3', 
'1', 
'3', 
'UNQ_Masks_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'4', 
'1', 
'4', 
'UNQ_Domains_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'5', 
'1', 
'5', 
'UNQ_Systems_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'6', 
'1', 
'6', 
'UNQ_Menus_SystemId_Sequence', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'7', 
'1', 
'7', 
'UNQ_Users_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'8', 
'1', 
'8', 
'UNQ_SystemsUsers_SystemId_UserId', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'9', 
'1', 
'8', 
'UNQ_SystemsUsers_Description', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'10', 
'1', 
'9', 
'UNQ_Databases_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'11', 
'1', 
'9', 
'UNQ_Databases_Alias', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'12', 
'1', 
'10', 
'UNQ_SystemsDatabases_SystemId_DatabaseId', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'13', 
'1', 
'10', 
'UNQ_SystemsDatabases_Description', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'14', 
'1', 
'11', 
'UNQ_Tables_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'15', 
'1', 
'11', 
'UNQ_Tables_Alias', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'16', 
'1', 
'12', 
'UNQ_DatabasesTables_DatabaseId_TableId', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'17', 
'1', 
'12', 
'UNQ_DatabasesTables_Description', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'18', 
'1', 
'13', 
'UNQ_Columns_TableId_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'19', 
'1', 
'13', 
'UNQ_Columns_TableId_Sequence', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'20', 
'1', 
'14', 
'UNQ_Indexes_DatabaseId_Name', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'21', 
'1', 
'15', 
'UNQ_Indexkeys_IndexId_Sequence', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'22', 
'1', 
'15', 
'UNQ_Indexkeys_IndexId_Column', 
'1', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'23', 
'1', 
'16', 
'UNQ_Logins_SystemId_UserId_IsLogged', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'24', 
'1', 
'17', 
'UNQ_Transactions_LoginId_SystemId_DatabaseId', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexes] (
[Id], 
[DatabaseId], 
[TableId], 
[Name], 
[IsUnique], 
CreatedAt,
CreatedBy) VALUES (
'25', 
'1', 
'18', 
'UNQ_Operations_TransactionId_TableId_Action', 
'0', 
GETDATE(),
'adm')
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
CreatedAt,
CreatedBy) VALUES (
'1', 
'1', 
'5', 
'2', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'2', 
'2', 
'5', 
'13', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'3', 
'3', 
'5', 
'27', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'4', 
'4', 
'5', 
'32', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'5', 
'5', 
'5', 
'41', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'6', 
'6', 
'5', 
'46', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'7', 
'6', 
'10', 
'47', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'8', 
'7', 
'5', 
'53', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'9', 
'8', 
'5', 
'59', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'10', 
'8', 
'10', 
'60', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'11', 
'9', 
'5', 
'61', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'12', 
'10', 
'5', 
'63', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'13', 
'11', 
'5', 
'65', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'14', 
'12', 
'5', 
'73', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'15', 
'12', 
'10', 
'74', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'16', 
'13', 
'5', 
'75', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'17', 
'14', 
'5', 
'77', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'18', 
'15', 
'5', 
'78', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'19', 
'16', 
'5', 
'89', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'20', 
'16', 
'10', 
'90', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'21', 
'17', 
'5', 
'91', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'22', 
'18', 
'5', 
'93', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'23', 
'18', 
'10', 
'97', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'24', 
'19', 
'5', 
'93', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'25', 
'19', 
'10', 
'94', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'26', 
'20', 
'5', 
'115', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'27', 
'20', 
'10', 
'117', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'28', 
'21', 
'5', 
'120', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'29', 
'21', 
'10', 
'121', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'30', 
'22', 
'5', 
'120', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'31', 
'22', 
'10', 
'122', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'32', 
'23', 
'5', 
'125', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'33', 
'23', 
'10', 
'126', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'34', 
'23', 
'15', 
'128', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'35', 
'24', 
'5', 
'130', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'36', 
'24', 
'10', 
'131', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'37', 
'24', 
'15', 
'132', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'38', 
'25', 
'5', 
'135', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'39', 
'25', 
'10', 
'136', 
'0', 
GETDATE(),
'adm')
GO
INSERT INTO [dbo].[Indexkeys] (
[Id], 
[IndexId], 
[Sequence], 
[ColumnId], 
[IsDescending], 
CreatedAt,
CreatedBy) VALUES (
'40', 
'25', 
'15', 
'137', 
'0', 
GETDATE(),
'adm')
GO
/**********************************************************************************
Inserir dados na tabela Logins
**********************************************************************************/
GO
/**********************************************************************************
Inserir dados na tabela Transactions
**********************************************************************************/
GO
/**********************************************************************************
Inserir dados na tabela Operations
**********************************************************************************/
GO
