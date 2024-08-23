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
(NAME = N'cruda_log', FILENAME = N'D:\CRUDA-C#\CRUDA-CORE\CRUDA\db\cruda.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)
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
	   (@LeftType = @RightType AND CAST(@LeftValue AS VARBINARY(MAX)) = CAST(@RightValue AS VARBINARY(MAX)))
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
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL BEGIN
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
		IF @TableId IS NULL BEGIN
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
IF(SELECT object_id('[dbo].[P_Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_Login](@Parameters VARCHAR(MAX)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION P_Login
		ELSE
			SAVE TRANSACTION P_Login

		DECLARE @ErrorMessage VARCHAR(256)

		IF ISJSON(@Parameters) = 0 BEGIN
			SET @ErrorMessage = 'Parâmetro login não está no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END
	
		DECLARE	@Action VARCHAR(15) = CAST(JSON_VALUE(@Parameters, '$.Action') AS VARCHAR(15))
				,@LoginId BIGINT = CAST(JSON_VALUE(@Parameters, '$.LoginId') AS BIGINT)
				,@SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
				,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.UserName') AS VARCHAR(25))
				,@Password VARCHAR(256) = CAST(JSON_VALUE(@Parameters, '$.Password') AS VARCHAR(256))
				,@PublicKey VARCHAR(256) = CAST(JSON_VALUE(@Parameters, '$.PublicKey') AS VARCHAR(256))
				,@PasswordAux VARCHAR(256)
				,@SystemId BIGINT
				,@SystemIdAux BIGINT
				,@UserId BIGINT
				,@UserIdAux BIGINT
				,@MaxRetryLogins TINYINT
				,@RetryLogins TINYINT
				,@IsLogged BIT
				,@IsActive BIT
	
		IF @Action IS NULL BEGIN
			SET @ErrorMessage = 'Ação de login requerida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action NOT IN ('login','logout','authenticate') BEGIN
			SET @ErrorMessage = 'Ação de login inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemName IS NULL BEGIN
			SET @ErrorMessage = 'Sistema requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @SystemId = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = 'Sistema não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName IS NULL BEGIN
			SET @ErrorMessage = 'Usuário requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @UserId IS NULL BEGIN
			SET @ErrorMessage = 'Usuário não cadastrado.';
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
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Password IS NULL BEGIN
			SET @ErrorMessage = 'Senha requerida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF CAST(@PasswordAux AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			SET @RetryLogins = @RetryLogins + 1
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = @RetryLogins
				WHERE [Id] = @UserId
			SET @ErrorMessage = 'Senha inválida (' + CAST(@MaxRetryLogins -  @RetryLogins AS VARCHAR(3)) + ' tentativas restantes).';
			THROW 51000, @ErrorMessage, 1
		END
		IF @action = 'login' BEGIN
			IF @PublicKey IS NULL BEGIN
				SET @ErrorMessage = 'Chave pública requerida.';
				THROW 51000, @ErrorMessage, 1
			END
			EXEC @LoginId = [dbo].[P_GenerateId] 'cruda', 'cruda', 'Logins'
			INSERT [dbo].[Logins]([Id],
								  [SystemId],
								  [UserId],
								  [PublicKey],
								  [IsLogged],
								  [CreatedAt],
								  [CreatedBy])
						  VALUES (@LoginId,
								  @SystemId,
								  @UserId,
								  @PublicKey,
								  1,
								  GETDATE(),
								  @UserName)
		END ELSE IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = 'Id de login requerido.';
			THROW 51000, @ErrorMessage, 1
		END ELSE BEGIN
			SELECT @SystemIdAux = [SystemId],
				   @UserIdAux = [UserId],
				   @IsLogged = [IsLogged]
				FROM [dbo].[Logins]
				WHERE [Id] = @LoginId
			IF @SystemIdAux IS NULL BEGIN
				SET @ErrorMessage = 'Login não cadastrado.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @SystemId <> @SystemIdAux BEGIN
				SET @ErrorMessage = 'Sistema inválido para este login.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @UserId <> @UserIdAux BEGIN
				SET @ErrorMessage = 'Usuário inválido para este login.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @IsLogged = 0 BEGIN
				SET @ErrorMessage = 'Login já encerrado.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @action = 'logout'
				UPDATE [dbo].[Logins]
					SET [IsLogged] = 0,
						[UpdatedAt] = GETDATE(),
						[UpdatedBy] = @UserName
					WHERE [Id] = @LoginId
		END
		UPDATE [dbo].[Users]
			SET [RetryLogins] = 0
			WHERE [Id] = @UserId
		COMMIT TRANSACTION P_Login

		RETURN @LoginId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION P_Login;
		THROW
	END CATCH
END
GO
GO
IF(SELECT object_id('[dbo].[CategoriesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[CategoriesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskEncrypted IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskMask IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskListable IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskDefault IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskMinimum IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskMaximum IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Name] = @W_Name AND [HtmlInputType] = @W_HtmlInputType AND [HtmlInputAlign] = @W_HtmlInputAlign AND [AskEncrypted] = @W_AskEncrypted AND [AskMask] = @W_AskMask AND [AskListable] = @W_AskListable AND [AskDefault] = @W_AskDefault AND [AskMinimum] = @W_AskMinimum AND [AskMaximum] = @W_AskMaximum) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Categories.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Categories.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[TypesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TypesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)
        IF @W_CategoryId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskLength IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskDecimals IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskPrimarykey IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskAutoincrement IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskFilterable IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskBrowseable IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskCodification IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AskFormula IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_AllowMaxLength IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsActive IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [CategoryId] = @W_CategoryId AND [Name] = @W_Name AND [Minimum] = @W_Minimum AND [Maximum] = @W_Maximum AND [AskLength] = @W_AskLength AND [AskDecimals] = @W_AskDecimals AND [AskPrimarykey] = @W_AskPrimarykey AND [AskAutoincrement] = @W_AskAutoincrement AND [AskFilterable] = @W_AskFilterable AND [AskBrowseable] = @W_AskBrowseable AND [AskCodification] = @W_AskCodification AND [AskFormula] = @W_AskFormula AND [AllowMaxLength] = @W_AllowMaxLength AND [IsActive] = @W_IsActive) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Types.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Types.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[MasksCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[MasksCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Mask IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Name] = @W_Name AND [Mask] = @W_Mask) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Masks.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Masks.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[DomainsCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DomainsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_TypeId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TypeId < CAST('1' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TypeId > CAST('255' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Length < CAST('0' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Length > CAST('32767' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Decimals < CAST('0' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Decimals > CAST('255' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TypeId] = @W_TypeId AND [MaskId] = @W_MaskId AND [Name] = @W_Name AND [Length] = @W_Length AND [Decimals] = @W_Decimals AND [ValidValues] = @W_ValidValues AND [Default] = @W_Default AND [Minimum] = @W_Minimum AND [Maximum] = @W_Maximum AND [Codification] = @W_Codification) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Domains.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Domains.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[SystemsCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ClientName IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_MaxRetryLogins IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Name] = @W_Name AND [Description] = @W_Description AND [ClientName] = @W_ClientName AND [MaxRetryLogins] = @W_MaxRetryLogins) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Systems.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Systems.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[MenusCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[MenusCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_SystemId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence < CAST('1' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence > CAST('32767' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Caption IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Message IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [SystemId] = @W_SystemId AND [Sequence] = @W_Sequence AND [Caption] = @W_Caption AND [Message] = @W_Message AND [Action] = @W_Action AND [ParentMenuId] = @W_ParentMenuId) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Menus.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Menus.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[UsersCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[UsersCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Password IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_FullName IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_RetryLogins IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsActive IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Name] = @W_Name AND [Password] = @W_Password AND [FullName] = @W_FullName AND [RetryLogins] = @W_RetryLogins AND [IsActive] = @W_IsActive) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Users.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Users.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[SystemsUsersCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemsUsersCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_SystemId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_UserId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_UserId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId AND [Description] = @W_Description) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela SystemsUsers.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsUsers.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[DatabasesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DatabasesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Alias IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Port < CAST('1' AS int) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Port > CAST('65535' AS int) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Name] = @W_Name AND [Description] = @W_Description AND [Alias] = @W_Alias AND [ServerName] = @W_ServerName AND [HostName] = @W_HostName AND [Port] = @W_Port AND [Logon] = @W_Logon AND [Password] = @W_Password AND [Folder] = @W_Folder) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Databases.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Databases.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[SystemsDatabasesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_SystemId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId AND [Description] = @W_Description) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela SystemsDatabases.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela SystemsDatabases.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[TablesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TablesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TablesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Alias IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsPaged IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_LastId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_LastId < CAST('0' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Name] = @W_Name AND [Alias] = @W_Alias AND [Description] = @W_Description AND [ParentTableId] = @W_ParentTableId AND [ProcedureCreate] = @W_ProcedureCreate AND [ProcedureRead] = @W_ProcedureRead AND [ProcedureUpdate] = @W_ProcedureUpdate AND [ProcedureDelete] = @W_ProcedureDelete AND [ProcedureList] = @W_ProcedureList AND [IsPaged] = @W_IsPaged AND [LastId] = @W_LastId) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Tables.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Tables.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[DatabasesTablesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DatabasesTablesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesTablesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_DatabaseId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId AND [Description] = @W_Description) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela DatabasesTables.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela DatabasesTables.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[ColumnsCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[ColumnsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_TableId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence < CAST('1' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence > CAST('32767' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DomainId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DomainId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Description IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Title IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Caption IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsRequired IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence AND [DomainId] = @W_DomainId AND [ReferenceTableId] = @W_ReferenceTableId AND [Name] = @W_Name AND [Description] = @W_Description AND [Title] = @W_Title AND [Caption] = @W_Caption AND [ValidValues] = @W_ValidValues AND [Default] = @W_Default AND [Minimum] = @W_Minimum AND [Maximum] = @W_Maximum AND [IsPrimarykey] = @W_IsPrimarykey AND [IsAutoIncrement] = @W_IsAutoIncrement AND [IsRequired] = @W_IsRequired AND [IsListable] = @W_IsListable AND [IsFilterable] = @W_IsFilterable AND [IsEditable] = @W_IsEditable AND [IsBrowseable] = @W_IsBrowseable AND [IsEncrypted] = @W_IsEncrypted) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Columns.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[IndexesCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[IndexesCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_DatabaseId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Name IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsUnique IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId AND [Name] = @W_Name AND [IsUnique] = @W_IsUnique) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Indexes.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexes.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[IndexkeysCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[IndexkeysCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_IndexId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IndexId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence < CAST('1' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Sequence > CAST('32767' AS smallint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ColumnId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ColumnId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsDescending IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [IndexId] = @W_IndexId AND [Sequence] = @W_Sequence AND [ColumnId] = @W_ColumnId AND [IsDescending] = @W_IsDescending) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Indexkeys.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Indexkeys.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[LoginsCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[LoginsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[LoginsCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_SystemId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_UserId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_UserId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_PublicKey IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_IsLogged IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId AND [PublicKey] = @W_PublicKey AND [IsLogged] = @W_IsLogged) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Logins.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Logins.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[TransactionsCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TransactionsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TransactionsCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_LoginId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [LoginId] = @W_LoginId AND [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId AND [IsConfirmed] = @W_IsConfirmed) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Transactions.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Transactions.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
GO
IF(SELECT object_id('[dbo].[OperationsCommit]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[OperationsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[OperationsCommit](@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @TransactionId BIGINT,
                ,@LastRecord VARCHAR(MAX)
                ,@ActualRecord VARCHAR(MAX)
                ,@IsConfirmed BIT
                ,@Action VARCHAR(15)

        SELECT @TransactionId = [TransactionId]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
              ,@Action = [Action]
            FROM [dbo].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action NOT IN ('create', 'update', 'delete') BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
            THROW 51000, @ErrorMessage, 1
        END

        DECLARE @LoginId BIGINT

        SELECT @LoginId = [LoginId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
            THROW 51000, @ErrorMessage, 1
        END

    DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
        IF @W_TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TransactionId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId < CAST('1' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Action IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_ActualRecord IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TransactionId] = @W_TransactionId AND [TableId] = @W_TableId AND [Action] = @W_Action AND [LastRecord] = @W_LastRecord AND [ActualRecord] = @W_ActualRecord AND [IsConfirmed] = @W_IsConfirmed) BEGIN
            IF @Action = 'create' BEGIN);
                SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Operations.';
                THROW 51000, @ErrorMessage, 1
            END
        END ELSE IF @Action <> 'create' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Operations.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @Action <> 'delete' BEGIN
                DECLARE                     @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                    ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                    ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                    ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                    ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                    ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                    ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                    ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)
                    ,@W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
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
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)
                    ,@W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                    ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                    ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                    ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                    ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                    ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                    ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                    ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                    ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                    ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                    ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                    ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                    ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                    ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                    ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                    ,@W_ProcedureCreate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureCreate') AS varchar)
                    ,@W_ProcedureRead varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureRead') AS varchar)
                    ,@W_ProcedureUpdate varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureUpdate') AS varchar)
                    ,@W_ProcedureDelete varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureDelete') AS varchar)
                    ,@W_ProcedureList varchar = CAST(JSON_VALUE(@ActualRecord, '$.ProcedureList') AS varchar)
                    ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                    ,@W_LastId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LastId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                    ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                    ,@W_Title varchar = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar)
                    ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                    ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
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
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                    ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)
                    ,@W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                    ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                    ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                    ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                    ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                    ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)
                    ,@W_LoginId bigint = CAST(JSON_VALUE(@ActualRecord, '$.LoginId') AS bigint)
                    ,@W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                    ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
                    ,@W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                    ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                    ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                    ,@W_LastRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS varchar)
                    ,@W_ActualRecord varchar = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS varchar)
                    ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskEncrypted IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskEncrypted] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskListable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskListable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDefault IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDefault] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMinimum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMinimum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskMaximum IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskMaximum] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_CategoryId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [CategoryId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskDecimals IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskDecimals] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskPrimarykey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskPrimarykey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskAutoincrement IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskAutoincrement] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFilterable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFilterable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskBrowseable IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskBrowseable] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskCodification IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskCodification] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AskFormula IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AskFormula] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_AllowMaxLength IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [AllowMaxLength] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Mask IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Mask] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TypeId > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TypeId] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaskId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaskId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length < CAST('0' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Length > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Length] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Decimals > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Decimals] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ClientName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ClientName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins < CAST('1' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_MaxRetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [MaxRetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Message IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Message] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentMenuId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentMenuId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Password IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Password] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_FullName IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [FullName] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins < CAST('0' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_RetryLogins > CAST('255' AS tinyint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [RetryLogins] deve ser menor que ou igual à ''255''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsActive IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsActive] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port < CAST('1' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Port > CAST('65535' AS int) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Port] deve ser menor que ou igual à ''65535''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Alias IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Alias] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId < CAST('-9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser maior que ou igual à ''-9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ParentTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ParentTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsPaged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsPaged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId < CAST('0' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser maior que ou igual à ''0''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LastId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LastId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DomainId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ReferenceTableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Description IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Description] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Title IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Title] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Caption IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Caption] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsRequired IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsRequired] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Name IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Name] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsUnique IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsUnique] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IndexId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IndexId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence < CAST('1' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Sequence > CAST('32767' AS smallint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Sequence] deve ser menor que ou igual à ''32767''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ColumnId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ColumnId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsDescending IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsDescending] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_UserId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [UserId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_PublicKey < CAST('1' AS varchar(256)) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [PublicKey] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_IsLogged IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [IsLogged] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_LoginId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [LoginId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_SystemId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [SystemId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_DatabaseId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [DatabaseId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TransactionId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TransactionId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId < CAST('1' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser maior que ou igual à ''1''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [TableId] deve ser menor que ou igual à ''9007199254740990''.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_Action IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [Action] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @W_ActualRecord IS NULL BEGIN
                SET @ErrorMessage = @ErrorMessage + 'Valor de [ActualRecord] é requerido.';
                THROW 51000, @ErrorMessage, 1
            END
            IF @Action = 'create' BEGIN
