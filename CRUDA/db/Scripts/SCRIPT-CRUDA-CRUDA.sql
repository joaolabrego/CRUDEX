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
CREATE SCHEMA cruda AUTHORIZATION [dbo]
GO
/**********************************************************************************
Criar stored procedure [dbo].[Config]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[Config]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[Config] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[Config](@SystemName VARCHAR(25)
							  ,@DatabaseName VARCHAR(25) = NULL
							  ,@TableName VARCHAR(25) = NULL) AS
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
				SET @ErrorMessage = 'Colunas de tabelas não cadastradas.';
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
				SET @ErrorMessage = 'Domínios de colunas não cadastrados.';
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
				SET @ErrorMessage = 'Tipos de domínios não cadastrados.';
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
			   SET @ErrorMessage = 'Categoria(s) de tipos não cadastrada(s).';
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
			   SET @ErrorMessage = 'Menu(s) de sistema não cadastrado(s).';
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
Criar stored procedure [dbo].[GenerateId]
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
ALTER PROCEDURE [dbo].[GenerateId](@SystemName VARCHAR(25)
								  ,@DatabaseName VARCHAR(25)
								  ,@TableName VARCHAR(25)) AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId BIGINT,
				@DatabaseId BIGINT,
				@TableId BIGINT,
				@NextId BIGINT,
				@ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '

		IF @@TRANCOUNT = 0 BEGIN
			BEGIN TRANSACTION GenerateId
		END ELSE
			SAVE TRANSACTION GenerateId
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema não encontrado';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não encontrado';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
							  AND [DatabaseId] = @DatabaseId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não pertence ao sistema especificado';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TableId = [Id]
			   ,@NextId = [CurrentId] + 1
			FROM [dbo].[Tables]
			WHERE [Name] = @TableName
		IF @TableId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não encontrada';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
							  AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado';
			THROW 51000, @ErrorMessage, 1
		END
		UPDATE [dbo].[Tables] 
			SET [LastId] = @NextId
			WHERE [Id] = @TableId
		COMMIT TRANSACTION GenerateId

		RETURN @NextId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION GenerateId;
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar stored procedure [dbo].[Login]
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
			SET @ErrorMessage = 'Parâmetro login não está no formato JSON';
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
				,@IsOffAir BIT
	
		IF @Action IS NULL BEGIN
			SET @ErrorMessage = 'Ação de login é requerida';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action NOT IN ('login','logout','authenticate') BEGIN
			SET @ErrorMessage = 'Ação de login é inválida';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemName IS NULL BEGIN
			SET @ErrorMessage = 'Sistema é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @SystemId = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			   ,@IsOffAir = [IsOffAir]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = 'Sistema não cadastrado';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsOffAir = 1 BEGIN
			SET @ErrorMessage = 'Sistema fora do ar';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName IS NULL BEGIN
			SET @ErrorMessage = 'Usuário é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @UserId IS NULL BEGIN
			SET @ErrorMessage = 'Usuário não cadastrado';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário está inativo';
			THROW 51000, @ErrorMessage, 1
		END
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário está bloqueado';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Password IS NULL BEGIN
			SET @ErrorMessage = 'Senha é requerida';
			THROW 51000, @ErrorMessage, 1
		END
		IF CAST(@PasswordAux AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			SET @RetryLogins = @RetryLogins + 1
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = @RetryLogins
				WHERE [Id] = @UserId
			SET @ErrorMessage = 'Senha é inválida (' + CAST(@MaxRetryLogins -  @RetryLogins AS VARCHAR(3)) + ' tentativas restantes)';
			THROW 51000, @ErrorMessage, 1
		END
		IF @action = 'login' BEGIN
			IF @PublicKey IS NULL BEGIN
				SET @ErrorMessage = 'Chave pública é requerida';
				THROW 51000, @ErrorMessage, 1
			END
			SELECT @LoginId = MAX([Id]) + 1 FROM [dbo].[Logins]
			INSERT [dbo].[Logins]([Id],
								  [SystemId],
								  [UserId],
								  [PublicKey],
								  [IsLogged],
								  [CreatedAt],
								  [CreatedBy])
						  VALUES (ISNULL(@LoginId, 1),
								  @SystemId,
								  @UserId,
								  @PublicKey,
								  1,
								  GETDATE(),
								  @UserName)
		END ELSE IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = 'Id de login é requerido';
			THROW 51000, @ErrorMessage, 1
		END ELSE BEGIN
			SELECT @SystemIdAux = [SystemId],
				   @UserIdAux = [UserId],
				   @IsLogged = [IsLogged]
				FROM [dbo].[Logins]
				WHERE [Id] = @LoginId
			IF @SystemIdAux IS NULL BEGIN
				SET @ErrorMessage = 'Login não cadastrado';
				THROW 51000, @ErrorMessage, 1
			END
			IF @SystemId <> @SystemIdAux BEGIN
				SET @ErrorMessage = 'Sistema é inválido para este login';
				THROW 51000, @ErrorMessage, 1
			END
			IF @UserId <> @UserIdAux BEGIN
				SET @ErrorMessage = 'Usuário é inválido para este login';
				THROW 51000, @ErrorMessage, 1
			END
			IF @IsLogged = 0 BEGIN
				SET @ErrorMessage = 'Login já encerrado';
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
/**********************************************************************************
Criar stored procedure [dbo].[GetPublicKey]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[GetPublicKey]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GetPublicKey] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[GetPublicKey](@LoginId BIGINT) AS 
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(256)

		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = 'Parâmetro @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT [PublicKey]
			FROM [dbo].[Logins]
			WHERE [Id] = @LoginId
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Valor @LoginId é inexistente';
			THROW 51000, @ErrorMessage, 1
		END

		RETURN @LoginId
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar function [dbo].[NumberInWordsOfHundreds]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[NumberInWordsOfHundreds]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[NumberInWordsOfHundreds]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [dbo].[NumberInWordsOfHundreds](@Value AS SMALLINT
											  ,@EnglishOrPortuguese BIT)
RETURNS VARCHAR(MAX) AS  
BEGIN 
	DECLARE @ThirdDigit INT = @Value / 100,
			@SecondDigit INT = CAST(@Value / 10 AS INT) % 10,
			@FirstDigit INT = @Value % 10,
			@And VARCHAR(10),
			@Result VARCHAR(MAX) = '',
			@Separator VARCHAR(5)
	DECLARE @Units TABLE (Id INT, Nome VARCHAR(50))
	DECLARE @Dozens TABLE (Id INT, Nome VARCHAR(50))
	DECLARE @Hundreds TABLE (Id INT, Nome VARCHAR(50))

	IF @EnglishOrPortuguese = 1 BEGIN
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
				  (2, 'Twenty'),
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
	SET  @Separator = CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE ' ' END
	IF @Value < 20 BEGIN
		SET @Result = (SELECT Nome FROM @Units WHERE Id = @Value)
	END ELSE IF @Value < 100 BEGIN
		SET @Result = (SELECT Nome FROM @Dozens WHERE Id = @SecondDigit) +
						 CASE WHEN @FirstDigit = 0 THEN '' ELSE CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE '-' END + (SELECT Nome FROM @Units WHERE Id = @FirstDigit) END
	END ELSE IF @Value = 100 BEGIN
		SET @Result = CASE WHEN @EnglishOrPortuguese = 1 THEN 'Cem' ELSE 'One Hundred' END
	END ELSE IF @Value % 100 = 0 BEGIN
		SET @Result = (SELECT Nome FROM @Hundreds WHERE Id = @ThirdDigit)
	END ELSE BEGIN
		SET @Result = (SELECT Nome FROM @Hundreds WHERE Id = @ThirdDigit) +
						 CASE WHEN @Value < 20
							  THEN @Separator + (SELECT Nome FROM @Units WHERE Id = @SecondDigit * 10 + @FirstDigit)
						      ELSE @Separator + (SELECT Nome FROM @Dozens WHERE Id = @SecondDigit) + CASE WHEN @FirstDigit = 0 
																										  THEN '' 
																										  ELSE CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE '-' END + (SELECT Nome FROM @Units WHERE Id = @FirstDigit)
																									 END
						 END
	END

	RETURN @Result
END
GO
/**********************************************************************************
Criar function [dbo].[NumberInWords]
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
ALTER FUNCTION [dbo].[NumberInWords](@Value AS DECIMAL(18,2)
									,@EnglishOrPortuguese BIT = 1
									,@CurrencyInSingular VARCHAR(50) = NULL
									,@CurrencyInPlural VARCHAR(50) = NULL
									,@CentsInSingular VARCHAR(50) = NULL
									,@CentsInPlural VARCHAR(50) = NULL)
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

	IF @EnglishOrPortuguese = 1 BEGIN
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
				  (1,'Thousand', 'Thousand'),
				  (2,'Million', 'Million'),
				  (3,'Billion', 'Billion'),
				  (4,'Trillion', 'Trillion'),
				  (5,'Quadrillion', 'Quadrillion'),
				  (6,'Quintillion', 'Quintillion'),
				  (7,'Sextillion', 'Sextillion'),
				  (8,'Septillion', 'Septillion'),
				  (9,'Octillion', 'Octillion'),
				  (10,'Nonillion', 'Nonillion'),
				  (11,'Decillion', 'Decillion'),
				  (12,'Undecillion', 'Undecillion'),
				  (13,'Duodecillion', 'Duodecillion'),
				  (14,'Tredecillion', 'Tredecillion')
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
			 SET @Result = [cruda].[NumberInWordsOfHundreds](@Digito, @EnglishOrPortuguese) + ' ' + 
							  (SELECT NomeSingular FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END ELSE IF @Digito > 0 BEGIN
			 SET @Result = [cruda].[NumberInWordsOfHundreds](@Digito, @EnglishOrPortuguese) + ' ' + 
							  (SELECT NomePlural FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END
		SET @PartialValue = @PartialValue / 1000
		IF @Digito > 0 BEGIN
			IF (@Power = 0) BEGIN
				SET @Separator = CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE ', ' END
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
				SET @Result = [cruda].[NumberInWordsOfHundreds](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInSingular + @Of + @CurrencyInSingular
			END ELSE BEGIN
				SET @Result = @Result + @And + [cruda].[NumberInWordsOfHundreds](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInSingular 
			END
		END ELSE BEGIN
			IF @Result = '' BEGIN
				SET @Result = [cruda].[NumberInWordsOfHundreds](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInPlural + @Of + @CurrencyInPlural
			END ELSE BEGIN
				SET @Result = @Result + @And + [cruda].[NumberInWordsOfHundreds](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInPlural
			END
		END
	END		

	RETURN @Minus + ' ' + @Result
END
GO
/**********************************************************************************
Criar stored procedure [cruda].[IsEquals]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF (SELECT object_id('[cruda].[IsEquals]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [cruda].[IsEquals]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [cruda].[IsEquals](@LeftValue SQL_VARIANT
							     ,@RightValue SQL_VARIANT)
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
Criar stored procedure [cruda].TransactionBegin]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionBegin](@LoginId BIGINT
										 ,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionBegin]: '
				,@TransactionId	BIGINT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionBegin]
		ELSE
			SAVE TRANSACTION [TransactionBegin]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do par�metro @LoginId � requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionId = MAX([TransactionId]) + 1
			FROM [cruda].[Transactions]
		INSERT [cruda].[Transactions] ([Id]
										,[LoginId]
										,[IsConfirmed]
										,[CreatedAt]
										,[CreatedBy])
								VALUES (ISNULL(@TransactionId, 1)
										,@LoginId
										,NULL
										,GETDATE()
										,@UserName)
		COMMIT TRANSACTION [TransactionBegin]

		RETURN @TransactionId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionBegin];
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar stored procedure [cruda].[TransactionCommit]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[TransactionCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionCommit] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionCommit](@TransactionId BIGINT
										  ,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionCommit]: '
				,@LoginId BIGINT
				,@OperationId BIGINT
				,@TableName VARCHAR(25)
				,@IsConfirmed BIT
				,@sql VARCHAR(MAX)

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionsCommit]
		ELSE
			SAVE TRANSACTION [TransactionsCommit]
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do par�metro @TransactionId � requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @LoginId = [LoginId]
			  ,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Transactions]
			WHERE [TransactionId] = @TransactionId
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transa��o � inexistente';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transa��o j� ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'conclu�da' END;
			THROW 51000, @ErrorMessage, 1
		END
		WHILE 1 = 1 BEGIN
			SELECT @OperationId = [OperationId]
					,@TableName = [TableName]
				FROM [cruda].[Operations]
				WHERE [TransactionId] = @TransactionId
						AND [IsConfirmed] IS NULL
			IF @OperationId IS NULL
				BREAK
			SET @sql = '[dbo].[' + @TableName + 'Ratify] @LoginId = ' + CAST(@LoginId AS VARCHAR) + ', @UserName = ''' + @UserName + ''', @OperationId = ' + CAST(@OperationId AS VARCHAR)
			EXEC @sql
		END
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 1
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
		COMMIT TRANSACTION [TransactionCommit]

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionCommit];
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar stored procedure [cruda].[TransactionRollback]
**********************************************************************************/
USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[TransactionRollback]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionRollback] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionRollback](@TransactionId BIGINT
											,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionRollback]: '
				,@LoginId BIGINT
				,@OperationId BIGINT
				,@TransactionIdAux BIGINT
				,@IsConfirmed BIT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionRollback]
		ELSE
			SAVE TRANSACTION [TransactionRollback]
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do par�metro @TransactionId � requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionIdAux = [Id]
			  ,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Transactions]
			WHERE [TransactionId] = @TransactionId
		IF @TransactionIdAux IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transa��o � inexistente';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transa��o j� ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'conclu�da' END;
			THROW 51000, @ErrorMessage, 1
		END
		UPDATE [cruda].[Operations]
			SET [IsConfirmed] = 0
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
				  AND [IsConfirmed] IS NULL
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 0
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
		COMMIT TRANSACTION [TransactionRollback]

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionRollback];
		THROW
	END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Categories]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Categories]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Categories]

CREATE TABLE [dbo].[Categories]([Id] tinyint NOT NULL
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
Ratificar dados na tabela [dbo].[Categories]
**********************************************************************************/
IF(SELECT object_id('[dbo].[CategoriesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[CategoriesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CategoriesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Categories' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[CategoriesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Categories] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_HtmlInputType varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputType') AS varchar)
                   ,@W_HtmlInputAlign varchar = CAST(JSON_VALUE(@ActualRecord, '$.HtmlInputAlign') AS varchar)
                   ,@W_AskEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.AskEncrypted') AS bit)
                   ,@W_AskMask bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMask') AS bit)
                   ,@W_AskListable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskListable') AS bit)
                   ,@W_AskDefault bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDefault') AS bit)
                   ,@W_AskMinimum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMinimum') AS bit)
                   ,@W_AskMaximum bit = CAST(JSON_VALUE(@ActualRecord, '$.AskMaximum') AS bit)

            IF @Action = 'create'
                INSERT INTO [dbo].[Categories] ([Id]
                                                ,[Name]
                                                ,[HtmlInputType]
                                                ,[HtmlInputAlign]
                                                ,[AskEncrypted]
                                                ,[AskMask]
                                                ,[AskListable]
                                                ,[AskDefault]
                                                ,[AskMinimum]
                                                ,[AskMaximum])
                                          VALUES (@W_Id
                                                 ,@W_Name
                                                 ,@W_HtmlInputType
                                                 ,@W_HtmlInputAlign
                                                 ,@W_AskEncrypted
                                                 ,@W_AskMask
                                                 ,@W_AskListable
                                                 ,@W_AskDefault
                                                 ,@W_AskMinimum
                                                 ,@W_AskMaximum)
            ELSE
                UPDATE [dbo].[Categories] SET [Id] = @W_Id
                                              ,[Name] = @W_Name
                                              ,[HtmlInputType] = @W_HtmlInputType
                                              ,[HtmlInputAlign] = @W_HtmlInputAlign
                                              ,[AskEncrypted] = @W_AskEncrypted
                                              ,[AskMask] = @W_AskMask
                                              ,[AskListable] = @W_AskListable
                                              ,[AskDefault] = @W_AskDefault
                                              ,[AskMinimum] = @W_AskMinimum
                                              ,[AskMaximum] = @W_AskMaximum
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Types]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Types]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Types]

CREATE TABLE [dbo].[Types]([Id] tinyint NOT NULL
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
Ratificar dados na tabela [dbo].[Types]
**********************************************************************************/
IF(SELECT object_id('[dbo].[TypesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TypesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TypesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Types' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[TypesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Types] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
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

            IF @Action = 'create'
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
                                                ,[IsActive])
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
                                                 ,@W_IsActive)
            ELSE
                UPDATE [dbo].[Types] SET [Id] = @W_Id
                                              ,[CategoryId] = @W_CategoryId
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
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Masks]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Masks]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Masks]

CREATE TABLE [dbo].[Masks]([Id] bigint NOT NULL
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
Ratificar dados na tabela [dbo].[Masks]
**********************************************************************************/
IF(SELECT object_id('[dbo].[MasksRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[MasksRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MasksRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Masks' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[MasksValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Masks] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_Mask varchar = CAST(JSON_VALUE(@ActualRecord, '$.Mask') AS varchar)

            IF @Action = 'create'
                INSERT INTO [dbo].[Masks] ([Id]
                                                ,[Name]
                                                ,[Mask])
                                          VALUES (@W_Id
                                                 ,@W_Name
                                                 ,@W_Mask)
            ELSE
                UPDATE [dbo].[Masks] SET [Id] = @W_Id
                                              ,[Name] = @W_Name
                                              ,[Mask] = @W_Mask
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Domains]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Domains]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Domains]

CREATE TABLE [dbo].[Domains]([Id] bigint NOT NULL
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
Ratificar dados na tabela [dbo].[Domains]
**********************************************************************************/
IF(SELECT object_id('[dbo].[DomainsRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DomainsRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DomainsRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Domains' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[DomainsValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Domains] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                   ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                   ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                   ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                   ,@W_ValidValues varchar = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar)
                   ,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
                   ,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
                   ,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
                   ,@W_Codification varchar = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS varchar)

            IF @Action = 'create'
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
                                                ,[Codification])
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
                                                 ,@W_Codification)
            ELSE
                UPDATE [dbo].[Domains] SET [Id] = @W_Id
                                              ,[TypeId] = @W_TypeId
                                              ,[MaskId] = @W_MaskId
                                              ,[Name] = @W_Name
                                              ,[Length] = @W_Length
                                              ,[Decimals] = @W_Decimals
                                              ,[ValidValues] = @W_ValidValues
                                              ,[Default] = @W_Default
                                              ,[Minimum] = @W_Minimum
                                              ,[Maximum] = @W_Maximum
                                              ,[Codification] = @W_Codification
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Systems]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Systems]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Systems]

CREATE TABLE [dbo].[Systems]([Id] bigint NOT NULL
                                    ,[Name] varchar(25) NOT NULL
                                    ,[Description] varchar(50) NOT NULL
                                    ,[ClientName] varchar(15) NOT NULL
                                    ,[MaxRetryLogins] tinyint NOT NULL
                                    ,[IsOffAir] bit NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Systems] ADD CONSTRAINT PK_Systems PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Systems_Name] ON [dbo].[Systems]([Name] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Systems]
**********************************************************************************/
IF(SELECT object_id('[dbo].[SystemsRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemsRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Systems' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[SystemsValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Systems] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                   ,@W_ClientName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ClientName') AS varchar)
                   ,@W_MaxRetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.MaxRetryLogins') AS tinyint)
                   ,@W_IsOffAir bit = CAST(JSON_VALUE(@ActualRecord, '$.IsOffAir') AS bit)

            IF @Action = 'create'
                INSERT INTO [dbo].[Systems] ([Id]
                                                ,[Name]
                                                ,[Description]
                                                ,[ClientName]
                                                ,[MaxRetryLogins]
                                                ,[IsOffAir])
                                          VALUES (@W_Id
                                                 ,@W_Name
                                                 ,@W_Description
                                                 ,@W_ClientName
                                                 ,@W_MaxRetryLogins
                                                 ,@W_IsOffAir)
            ELSE
                UPDATE [dbo].[Systems] SET [Id] = @W_Id
                                              ,[Name] = @W_Name
                                              ,[Description] = @W_Description
                                              ,[ClientName] = @W_ClientName
                                              ,[MaxRetryLogins] = @W_MaxRetryLogins
                                              ,[IsOffAir] = @W_IsOffAir
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Menus]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Menus]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Menus]

CREATE TABLE [dbo].[Menus]([Id] bigint NOT NULL
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
CREATE UNIQUE INDEX [UNQ_Menus_SystemId_Sequence] ON [dbo].[Menus]([SystemId] ASC                                                                                                          ,[Sequence] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Menus]
**********************************************************************************/
IF(SELECT object_id('[dbo].[MenusRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[MenusRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[MenusRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Menus' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[MenusValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Menus] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                   ,@W_Caption varchar = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar)
                   ,@W_Message varchar = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS varchar)
                   ,@W_Action varchar = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS varchar)
                   ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)

            IF @Action = 'create'
                INSERT INTO [dbo].[Menus] ([Id]
                                                ,[SystemId]
                                                ,[Sequence]
                                                ,[Caption]
                                                ,[Message]
                                                ,[Action]
                                                ,[ParentMenuId])
                                          VALUES (@W_Id
                                                 ,@W_SystemId
                                                 ,@W_Sequence
                                                 ,@W_Caption
                                                 ,@W_Message
                                                 ,@W_Action
                                                 ,@W_ParentMenuId)
            ELSE
                UPDATE [dbo].[Menus] SET [Id] = @W_Id
                                              ,[SystemId] = @W_SystemId
                                              ,[Sequence] = @W_Sequence
                                              ,[Caption] = @W_Caption
                                              ,[Message] = @W_Message
                                              ,[Action] = @W_Action
                                              ,[ParentMenuId] = @W_ParentMenuId
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Users]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Users]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Users]

CREATE TABLE [dbo].[Users]([Id] bigint NOT NULL
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
Ratificar dados na tabela [dbo].[Users]
**********************************************************************************/
IF(SELECT object_id('[dbo].[UsersRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[UsersRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[UsersRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Users' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[UsersValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Users] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                   ,@W_FullName varchar = CAST(JSON_VALUE(@ActualRecord, '$.FullName') AS varchar)
                   ,@W_RetryLogins tinyint = CAST(JSON_VALUE(@ActualRecord, '$.RetryLogins') AS tinyint)
                   ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)

            IF @Action = 'create'
                INSERT INTO [dbo].[Users] ([Id]
                                                ,[Name]
                                                ,[Password]
                                                ,[FullName]
                                                ,[RetryLogins]
                                                ,[IsActive])
                                          VALUES (@W_Id
                                                 ,@W_Name
                                                 ,@W_Password
                                                 ,@W_FullName
                                                 ,@W_RetryLogins
                                                 ,@W_IsActive)
            ELSE
                UPDATE [dbo].[Users] SET [Id] = @W_Id
                                              ,[Name] = @W_Name
                                              ,[Password] = @W_Password
                                              ,[FullName] = @W_FullName
                                              ,[RetryLogins] = @W_RetryLogins
                                              ,[IsActive] = @W_IsActive
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[SystemsUsers]
**********************************************************************************/
IF (SELECT object_id('[dbo].[SystemsUsers]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[SystemsUsers]

CREATE TABLE [dbo].[SystemsUsers]([Id] bigint NOT NULL
                                    ,[SystemId] bigint NOT NULL
                                    ,[UserId] bigint NOT NULL
                                    ,[Description] varchar(50) NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[SystemsUsers] ADD CONSTRAINT PK_SystemsUsers PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_SystemsUsers_SystemId_UserId] ON [dbo].[SystemsUsers]([SystemId] ASC                                                                                                          ,[UserId] ASC)
CREATE UNIQUE INDEX [UNQ_SystemsUsers_Description] ON [dbo].[SystemsUsers]([Description] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[SystemsUsers]
**********************************************************************************/
IF(SELECT object_id('[dbo].[SystemsUsersRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemsUsersRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsUsersRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'SystemsUsers' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[SystemsUsersValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[SystemsUsers] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                   ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)

            IF @Action = 'create'
                INSERT INTO [dbo].[SystemsUsers] ([Id]
                                                ,[SystemId]
                                                ,[UserId]
                                                ,[Description])
                                          VALUES (@W_Id
                                                 ,@W_SystemId
                                                 ,@W_UserId
                                                 ,@W_Description)
            ELSE
                UPDATE [dbo].[SystemsUsers] SET [Id] = @W_Id
                                              ,[SystemId] = @W_SystemId
                                              ,[UserId] = @W_UserId
                                              ,[Description] = @W_Description
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Databases]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Databases]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Databases]

CREATE TABLE [dbo].[Databases]([Id] bigint NOT NULL
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
Ratificar dados na tabela [dbo].[Databases]
**********************************************************************************/
IF(SELECT object_id('[dbo].[DatabasesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DatabasesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Databases' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[DatabasesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Databases] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                   ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                   ,@W_ServerName varchar = CAST(JSON_VALUE(@ActualRecord, '$.ServerName') AS varchar)
                   ,@W_HostName varchar = CAST(JSON_VALUE(@ActualRecord, '$.HostName') AS varchar)
                   ,@W_Port int = CAST(JSON_VALUE(@ActualRecord, '$.Port') AS int)
                   ,@W_Logon varchar = CAST(JSON_VALUE(@ActualRecord, '$.Logon') AS varchar)
                   ,@W_Password varchar = CAST(JSON_VALUE(@ActualRecord, '$.Password') AS varchar)
                   ,@W_Folder varchar = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS varchar)

            IF @Action = 'create'
                INSERT INTO [dbo].[Databases] ([Id]
                                                ,[Name]
                                                ,[Description]
                                                ,[Alias]
                                                ,[ServerName]
                                                ,[HostName]
                                                ,[Port]
                                                ,[Logon]
                                                ,[Password]
                                                ,[Folder])
                                          VALUES (@W_Id
                                                 ,@W_Name
                                                 ,@W_Description
                                                 ,@W_Alias
                                                 ,@W_ServerName
                                                 ,@W_HostName
                                                 ,@W_Port
                                                 ,@W_Logon
                                                 ,@W_Password
                                                 ,@W_Folder)
            ELSE
                UPDATE [dbo].[Databases] SET [Id] = @W_Id
                                              ,[Name] = @W_Name
                                              ,[Description] = @W_Description
                                              ,[Alias] = @W_Alias
                                              ,[ServerName] = @W_ServerName
                                              ,[HostName] = @W_HostName
                                              ,[Port] = @W_Port
                                              ,[Logon] = @W_Logon
                                              ,[Password] = @W_Password
                                              ,[Folder] = @W_Folder
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[SystemsDatabases]
**********************************************************************************/
IF (SELECT object_id('[dbo].[SystemsDatabases]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[SystemsDatabases]

CREATE TABLE [dbo].[SystemsDatabases]([Id] bigint NOT NULL
                                    ,[SystemId] bigint NOT NULL
                                    ,[DatabaseId] bigint NOT NULL
                                    ,[Description] varchar(50) NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[SystemsDatabases] ADD CONSTRAINT PK_SystemsDatabases PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_SystemsDatabases_SystemId_DatabaseId] ON [dbo].[SystemsDatabases]([SystemId] ASC                                                                                                          ,[DatabaseId] ASC)
CREATE UNIQUE INDEX [UNQ_SystemsDatabases_Description] ON [dbo].[SystemsDatabases]([Description] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[SystemsDatabases]
**********************************************************************************/
IF(SELECT object_id('[dbo].[SystemsDatabasesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemsDatabasesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[SystemsDatabasesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'SystemsDatabases' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[SystemsDatabasesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[SystemsDatabases] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                   ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)

            IF @Action = 'create'
                INSERT INTO [dbo].[SystemsDatabases] ([Id]
                                                ,[SystemId]
                                                ,[DatabaseId]
                                                ,[Description])
                                          VALUES (@W_Id
                                                 ,@W_SystemId
                                                 ,@W_DatabaseId
                                                 ,@W_Description)
            ELSE
                UPDATE [dbo].[SystemsDatabases] SET [Id] = @W_Id
                                              ,[SystemId] = @W_SystemId
                                              ,[DatabaseId] = @W_DatabaseId
                                              ,[Description] = @W_Description
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Tables]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Tables]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Tables]

CREATE TABLE [dbo].[Tables]([Id] bigint NOT NULL
                                    ,[Name] varchar(25) NOT NULL
                                    ,[Alias] varchar(25) NOT NULL
                                    ,[Description] varchar(50) NOT NULL
                                    ,[IsPaged] bit NOT NULL
                                    ,[CurrentId] bigint NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Tables] ADD CONSTRAINT PK_Tables PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Tables_Name] ON [dbo].[Tables]([Name] ASC)
CREATE UNIQUE INDEX [UNQ_Tables_Alias] ON [dbo].[Tables]([Alias] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Tables]
**********************************************************************************/
IF(SELECT object_id('[dbo].[TablesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TablesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TablesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Tables' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[TablesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Tables] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_Alias varchar = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS varchar)
                   ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)
                   ,@W_IsPaged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPaged') AS bit)
                   ,@W_CurrentId bigint = CAST(JSON_VALUE(@ActualRecord, '$.CurrentId') AS bigint)

            IF @Action = 'create'
                INSERT INTO [dbo].[Tables] ([Id]
                                                ,[Name]
                                                ,[Alias]
                                                ,[Description]
                                                ,[IsPaged]
                                                ,[CurrentId])
                                          VALUES (@W_Id
                                                 ,@W_Name
                                                 ,@W_Alias
                                                 ,@W_Description
                                                 ,@W_IsPaged
                                                 ,@W_CurrentId)
            ELSE
                UPDATE [dbo].[Tables] SET [Id] = @W_Id
                                              ,[Name] = @W_Name
                                              ,[Alias] = @W_Alias
                                              ,[Description] = @W_Description
                                              ,[IsPaged] = @W_IsPaged
                                              ,[CurrentId] = @W_CurrentId
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[DatabasesTables]
**********************************************************************************/
IF (SELECT object_id('[dbo].[DatabasesTables]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[DatabasesTables]

CREATE TABLE [dbo].[DatabasesTables]([Id] bigint NOT NULL
                                    ,[DatabaseId] bigint NOT NULL
                                    ,[TableId] bigint NOT NULL
                                    ,[Description] varchar(50) NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[DatabasesTables] ADD CONSTRAINT PK_DatabasesTables PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_DatabasesTables_DatabaseId_TableId] ON [dbo].[DatabasesTables]([DatabaseId] ASC                                                                                                          ,[TableId] ASC)
CREATE UNIQUE INDEX [UNQ_DatabasesTables_Description] ON [dbo].[DatabasesTables]([Description] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[DatabasesTables]
**********************************************************************************/
IF(SELECT object_id('[dbo].[DatabasesTablesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DatabasesTablesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[DatabasesTablesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'DatabasesTables' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[DatabasesTablesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[DatabasesTables] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                   ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                   ,@W_Description varchar = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar)

            IF @Action = 'create'
                INSERT INTO [dbo].[DatabasesTables] ([Id]
                                                ,[DatabaseId]
                                                ,[TableId]
                                                ,[Description])
                                          VALUES (@W_Id
                                                 ,@W_DatabaseId
                                                 ,@W_TableId
                                                 ,@W_Description)
            ELSE
                UPDATE [dbo].[DatabasesTables] SET [Id] = @W_Id
                                              ,[DatabaseId] = @W_DatabaseId
                                              ,[TableId] = @W_TableId
                                              ,[Description] = @W_Description
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Columns]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Columns]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Columns]

CREATE TABLE [dbo].[Columns]([Id] bigint NOT NULL
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
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Columns] ADD CONSTRAINT PK_Columns PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Columns_TableId_Name] ON [dbo].[Columns]([TableId] ASC                                                                                                          ,[Name] ASC)
CREATE UNIQUE INDEX [UNQ_Columns_TableId_Sequence] ON [dbo].[Columns]([TableId] ASC                                                                                                          ,[Sequence] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Columns]
**********************************************************************************/
IF(SELECT object_id('[dbo].[ColumnsRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[ColumnsRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Columns' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[ColumnsValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Columns] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
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

            IF @Action = 'create'
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
                                                ,[IsEncrypted])
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
                                                 ,@W_IsEncrypted)
            ELSE
                UPDATE [dbo].[Columns] SET [Id] = @W_Id
                                              ,[TableId] = @W_TableId
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
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Indexes]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Indexes]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Indexes]

CREATE TABLE [dbo].[Indexes]([Id] bigint NOT NULL
                                    ,[DatabaseId] bigint NOT NULL
                                    ,[TableId] bigint NOT NULL
                                    ,[Name] varchar(50) NOT NULL
                                    ,[IsUnique] bit NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Indexes] ADD CONSTRAINT PK_Indexes PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Indexes_DatabaseId_Name] ON [dbo].[Indexes]([DatabaseId] ASC                                                                                                          ,[Name] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Indexes]
**********************************************************************************/
IF(SELECT object_id('[dbo].[IndexesRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[IndexesRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexesRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Indexes' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[IndexesValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Indexes] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                   ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                   ,@W_Name varchar = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar)
                   ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)

            IF @Action = 'create'
                INSERT INTO [dbo].[Indexes] ([Id]
                                                ,[DatabaseId]
                                                ,[TableId]
                                                ,[Name]
                                                ,[IsUnique])
                                          VALUES (@W_Id
                                                 ,@W_DatabaseId
                                                 ,@W_TableId
                                                 ,@W_Name
                                                 ,@W_IsUnique)
            ELSE
                UPDATE [dbo].[Indexes] SET [Id] = @W_Id
                                              ,[DatabaseId] = @W_DatabaseId
                                              ,[TableId] = @W_TableId
                                              ,[Name] = @W_Name
                                              ,[IsUnique] = @W_IsUnique
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Indexkeys]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Indexkeys]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Indexkeys]

CREATE TABLE [dbo].[Indexkeys]([Id] bigint NOT NULL
                                    ,[IndexId] bigint NOT NULL
                                    ,[Sequence] smallint NOT NULL
                                    ,[ColumnId] bigint NOT NULL
                                    ,[IsDescending] bit NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Indexkeys] ADD CONSTRAINT PK_Indexkeys PRIMARY KEY CLUSTERED ([Id])
CREATE UNIQUE INDEX [UNQ_Indexkeys_IndexId_Sequence] ON [dbo].[Indexkeys]([IndexId] ASC                                                                                                          ,[Sequence] ASC)
CREATE UNIQUE INDEX [UNQ_Indexkeys_IndexId_ColumnId] ON [dbo].[Indexkeys]([IndexId] ASC                                                                                                          ,[ColumnId] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Indexkeys]
**********************************************************************************/
IF(SELECT object_id('[dbo].[IndexkeysRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[IndexkeysRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[IndexkeysRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Indexkeys' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[IndexkeysValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Indexkeys] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                   ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                   ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                   ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)

            IF @Action = 'create'
                INSERT INTO [dbo].[Indexkeys] ([Id]
                                                ,[IndexId]
                                                ,[Sequence]
                                                ,[ColumnId]
                                                ,[IsDescending])
                                          VALUES (@W_Id
                                                 ,@W_IndexId
                                                 ,@W_Sequence
                                                 ,@W_ColumnId
                                                 ,@W_IsDescending)
            ELSE
                UPDATE [dbo].[Indexkeys] SET [Id] = @W_Id
                                              ,[IndexId] = @W_IndexId
                                              ,[Sequence] = @W_Sequence
                                              ,[ColumnId] = @W_ColumnId
                                              ,[IsDescending] = @W_IsDescending
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar tabela [dbo].[Logins]
**********************************************************************************/
IF (SELECT object_id('[dbo].[Logins]', 'U')) IS NOT NULL
    DROP TABLE [dbo].[Logins]

CREATE TABLE [dbo].[Logins]([Id] bigint NOT NULL
                                    ,[SystemId] bigint NOT NULL
                                    ,[UserId] bigint NOT NULL
                                    ,[PublicKey] varchar(256) NOT NULL
                                    ,[IsLogged] bit NOT NULL
                                    ,[CreatedAt] datetime NOT NULL
                                    ,[CreatedBy] varchar(25) NOT NULL
                                    ,[UpdatedAt] datetime NULL
                                    ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [dbo].[Logins] ADD CONSTRAINT PK_Logins PRIMARY KEY CLUSTERED ([Id])
CREATE  INDEX [UNQ_Logins_SystemId_UserId_IsLogged] ON [dbo].[Logins]([SystemId] ASC                                                                                                          ,[UserId] ASC                                                                                                          ,[IsLogged] ASC)
GO
/**********************************************************************************
Ratificar dados na tabela [dbo].[Logins]
**********************************************************************************/
IF(SELECT object_id('[dbo].[LoginsRatify]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[LoginsRatify] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[LoginsRatify](@LoginId BIGINT
                                    ,@UserName VARCHAR(25)
                                    ,@OperationId BIGINT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsRatify]: '
               ,@TransactionId BIGINT
               ,@TransactionIdAux BIGINT
               ,@TableName VARCHAR(25)
               ,@Action VARCHAR(15)
               ,@LastRecord VARCHAR(MAX)
               ,@ActualRecord VARCHAR(MAX)
               ,@IsConfirmed BIT
               ,@ValidOk BIT

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION [ColumnsRatify]
        ELSE
            SAVE TRANSACTION [ColumnsRatify]
        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @OperationId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId requerido';
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionId = [TransactionId]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Transactions]
            WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
        IF @TransactionId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        SELECT @TransactionIdAux = [TransactionId]
              ,@TableName = [TableName]
              ,@Action = [Action]
              ,@LastRecord = [LastRecord]
              ,@ActualRecord = [ActualRecord]
              ,@IsConfirmed = [IsConfirmed]
            FROM [cruda].[Operations]
            WHERE [Id] = @OperationId
        IF @TransactionIdAux IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação é inexistente';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TransactionIdAux <> @TransactionId BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @TableName <> 'Logins' BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
            THROW 51000, @ErrorMessage, 1
        END
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END
        EXEC @ValidOk = [dbo].[LoginsValid] @Action, @LastRecord, @ActualRecord
        IF @ValidOk = 0
            RETURN 0

        DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        IF @Action = 'delete'
            DELETE FROM [dbo].[Logins] WHERE [Id] = @W_Id
        ELSE BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                   ,@W_PublicKey varchar = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS varchar)
                   ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)

            IF @Action = 'create'
                INSERT INTO [dbo].[Logins] ([Id]
                                                ,[SystemId]
                                                ,[UserId]
                                                ,[PublicKey]
                                                ,[IsLogged])
                                          VALUES (@W_Id
                                                 ,@W_SystemId
                                                 ,@W_UserId
                                                 ,@W_PublicKey
                                                 ,@W_IsLogged)
            ELSE
                UPDATE [dbo].[Logins] SET [Id] = @W_Id
                                              ,[SystemId] = @W_SystemId
                                              ,[UserId] = @W_UserId
                                              ,[PublicKey] = @W_PublicKey
                                              ,[IsLogged] = @W_IsLogged
                    WHERE [Id] = @W_Id
        END
        UPDATE [cruda].[Operations]
            SET [IsConfirmed] = 1
                ,[UpdatedBy] = @UserName
                ,[UpdatedAt] = GETDATE()
            WHERE [Id] = @OperationId
        COMMIT TRANSACTION [ColumnsRatify]

        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [ColumnsRatify];
        THROW
    END CATCH
END
GO
/**********************************************************************************
Criar referências de [dbo].[Types]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Types_Categories')
    ALTER TABLE [dbo].[Types] DROP CONSTRAINT FK_Types_Categories
GO
ALTER TABLE [dbo].[Types] WITH CHECK 
    ADD CONSTRAINT [FK_Types_Categories] 
    FOREIGN KEY([CategoryId]) 
    REFERENCES [dbo].[Categories] ([Id])
GO
ALTER TABLE [dbo].[Types] CHECK CONSTRAINT [FK_Types_Categories]
GO
/**********************************************************************************
Criar referências de [dbo].[Domains]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Domains_Types')
    ALTER TABLE [dbo].[Domains] DROP CONSTRAINT FK_Domains_Types
GO
ALTER TABLE [dbo].[Domains] WITH CHECK 
    ADD CONSTRAINT [FK_Domains_Types] 
    FOREIGN KEY([TypeId]) 
    REFERENCES [dbo].[Types] ([Id])
GO
ALTER TABLE [dbo].[Domains] CHECK CONSTRAINT [FK_Domains_Types]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Domains_Masks')
    ALTER TABLE [dbo].[Domains] DROP CONSTRAINT FK_Domains_Masks
GO
ALTER TABLE [dbo].[Domains] WITH CHECK 
    ADD CONSTRAINT [FK_Domains_Masks] 
    FOREIGN KEY([MaskId]) 
    REFERENCES [dbo].[Masks] ([Id])
GO
ALTER TABLE [dbo].[Domains] CHECK CONSTRAINT [FK_Domains_Masks]
GO
/**********************************************************************************
Criar referências de [dbo].[Menus]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Menus_Systems')
    ALTER TABLE [dbo].[Menus] DROP CONSTRAINT FK_Menus_Systems
GO
ALTER TABLE [dbo].[Menus] WITH CHECK 
    ADD CONSTRAINT [FK_Menus_Systems] 
    FOREIGN KEY([SystemId]) 
    REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[Menus] CHECK CONSTRAINT [FK_Menus_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Menus_Menus')
    ALTER TABLE [dbo].[Menus] DROP CONSTRAINT FK_Menus_Menus
GO
ALTER TABLE [dbo].[Menus] WITH CHECK 
    ADD CONSTRAINT [FK_Menus_Menus] 
    FOREIGN KEY([ParentMenuId]) 
    REFERENCES [dbo].[Menus] ([Id])
GO
ALTER TABLE [dbo].[Menus] CHECK CONSTRAINT [FK_Menus_Menus]
GO
/**********************************************************************************
Criar referências de [dbo].[SystemsUsers]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsUsers_Systems')
    ALTER TABLE [dbo].[SystemsUsers] DROP CONSTRAINT FK_SystemsUsers_Systems
GO
ALTER TABLE [dbo].[SystemsUsers] WITH CHECK 
    ADD CONSTRAINT [FK_SystemsUsers_Systems] 
    FOREIGN KEY([SystemId]) 
    REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[SystemsUsers] CHECK CONSTRAINT [FK_SystemsUsers_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsUsers_Users')
    ALTER TABLE [dbo].[SystemsUsers] DROP CONSTRAINT FK_SystemsUsers_Users
GO
ALTER TABLE [dbo].[SystemsUsers] WITH CHECK 
    ADD CONSTRAINT [FK_SystemsUsers_Users] 
    FOREIGN KEY([UserId]) 
    REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[SystemsUsers] CHECK CONSTRAINT [FK_SystemsUsers_Users]
GO
/**********************************************************************************
Criar referências de [dbo].[SystemsDatabases]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsDatabases_Systems')
    ALTER TABLE [dbo].[SystemsDatabases] DROP CONSTRAINT FK_SystemsDatabases_Systems
GO
ALTER TABLE [dbo].[SystemsDatabases] WITH CHECK 
    ADD CONSTRAINT [FK_SystemsDatabases_Systems] 
    FOREIGN KEY([SystemId]) 
    REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[SystemsDatabases] CHECK CONSTRAINT [FK_SystemsDatabases_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SystemsDatabases_Databases')
    ALTER TABLE [dbo].[SystemsDatabases] DROP CONSTRAINT FK_SystemsDatabases_Databases
GO
ALTER TABLE [dbo].[SystemsDatabases] WITH CHECK 
    ADD CONSTRAINT [FK_SystemsDatabases_Databases] 
    FOREIGN KEY([DatabaseId]) 
    REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[SystemsDatabases] CHECK CONSTRAINT [FK_SystemsDatabases_Databases]
GO
/**********************************************************************************
Criar referências de [dbo].[DatabasesTables]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_DatabasesTables_Databases')
    ALTER TABLE [dbo].[DatabasesTables] DROP CONSTRAINT FK_DatabasesTables_Databases
GO
ALTER TABLE [dbo].[DatabasesTables] WITH CHECK 
    ADD CONSTRAINT [FK_DatabasesTables_Databases] 
    FOREIGN KEY([DatabaseId]) 
    REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[DatabasesTables] CHECK CONSTRAINT [FK_DatabasesTables_Databases]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_DatabasesTables_Tables')
    ALTER TABLE [dbo].[DatabasesTables] DROP CONSTRAINT FK_DatabasesTables_Tables
GO
ALTER TABLE [dbo].[DatabasesTables] WITH CHECK 
    ADD CONSTRAINT [FK_DatabasesTables_Tables] 
    FOREIGN KEY([TableId]) 
    REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[DatabasesTables] CHECK CONSTRAINT [FK_DatabasesTables_Tables]
GO
/**********************************************************************************
Criar referências de [dbo].[Columns]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Columns_Tables')
    ALTER TABLE [dbo].[Columns] DROP CONSTRAINT FK_Columns_Tables
GO
ALTER TABLE [dbo].[Columns] WITH CHECK 
    ADD CONSTRAINT [FK_Columns_Tables] 
    FOREIGN KEY([TableId]) 
    REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Columns] CHECK CONSTRAINT [FK_Columns_Tables]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Columns_Domains')
    ALTER TABLE [dbo].[Columns] DROP CONSTRAINT FK_Columns_Domains
GO
ALTER TABLE [dbo].[Columns] WITH CHECK 
    ADD CONSTRAINT [FK_Columns_Domains] 
    FOREIGN KEY([DomainId]) 
    REFERENCES [dbo].[Domains] ([Id])
GO
ALTER TABLE [dbo].[Columns] CHECK CONSTRAINT [FK_Columns_Domains]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Columns_Tables')
    ALTER TABLE [dbo].[Columns] DROP CONSTRAINT FK_Columns_Tables
GO
ALTER TABLE [dbo].[Columns] WITH CHECK 
    ADD CONSTRAINT [FK_Columns_Tables] 
    FOREIGN KEY([ReferenceTableId]) 
    REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Columns] CHECK CONSTRAINT [FK_Columns_Tables]
GO
/**********************************************************************************
Criar referências de [dbo].[Indexes]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexes_Databases')
    ALTER TABLE [dbo].[Indexes] DROP CONSTRAINT FK_Indexes_Databases
GO
ALTER TABLE [dbo].[Indexes] WITH CHECK 
    ADD CONSTRAINT [FK_Indexes_Databases] 
    FOREIGN KEY([DatabaseId]) 
    REFERENCES [dbo].[Databases] ([Id])
GO
ALTER TABLE [dbo].[Indexes] CHECK CONSTRAINT [FK_Indexes_Databases]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexes_Tables')
    ALTER TABLE [dbo].[Indexes] DROP CONSTRAINT FK_Indexes_Tables
GO
ALTER TABLE [dbo].[Indexes] WITH CHECK 
    ADD CONSTRAINT [FK_Indexes_Tables] 
    FOREIGN KEY([TableId]) 
    REFERENCES [dbo].[Tables] ([Id])
GO
ALTER TABLE [dbo].[Indexes] CHECK CONSTRAINT [FK_Indexes_Tables]
GO
/**********************************************************************************
Criar referências de [dbo].[Indexkeys]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexkeys_Indexes')
    ALTER TABLE [dbo].[Indexkeys] DROP CONSTRAINT FK_Indexkeys_Indexes
GO
ALTER TABLE [dbo].[Indexkeys] WITH CHECK 
    ADD CONSTRAINT [FK_Indexkeys_Indexes] 
    FOREIGN KEY([IndexId]) 
    REFERENCES [dbo].[Indexes] ([Id])
GO
ALTER TABLE [dbo].[Indexkeys] CHECK CONSTRAINT [FK_Indexkeys_Indexes]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Indexkeys_Columns')
    ALTER TABLE [dbo].[Indexkeys] DROP CONSTRAINT FK_Indexkeys_Columns
GO
ALTER TABLE [dbo].[Indexkeys] WITH CHECK 
    ADD CONSTRAINT [FK_Indexkeys_Columns] 
    FOREIGN KEY([ColumnId]) 
    REFERENCES [dbo].[Columns] ([Id])
GO
ALTER TABLE [dbo].[Indexkeys] CHECK CONSTRAINT [FK_Indexkeys_Columns]
GO
/**********************************************************************************
Criar referências de [dbo].[Logins]
**********************************************************************************/
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Logins_Systems')
    ALTER TABLE [dbo].[Logins] DROP CONSTRAINT FK_Logins_Systems
GO
ALTER TABLE [dbo].[Logins] WITH CHECK 
    ADD CONSTRAINT [FK_Logins_Systems] 
    FOREIGN KEY([SystemId]) 
    REFERENCES [dbo].[Systems] ([Id])
GO
ALTER TABLE [dbo].[Logins] CHECK CONSTRAINT [FK_Logins_Systems]
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Logins_Users')
    ALTER TABLE [dbo].[Logins] DROP CONSTRAINT FK_Logins_Users
GO
ALTER TABLE [dbo].[Logins] WITH CHECK 
    ADD CONSTRAINT [FK_Logins_Users] 
    FOREIGN KEY([UserId]) 
    REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Logins] CHECK CONSTRAINT [FK_Logins_Users]
GO
/**********************************************************************************
Inserir dados na tabela [dbo].[Categories]
**********************************************************************************/
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('1' AS tinyint)
                                ,CAST('string' AS varchar(25))
                                ,CAST('text' AS varchar(10))
                                ,CAST('left' AS varchar(6))
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('2' AS tinyint)
                                ,CAST('numeric' AS varchar(25))
                                ,CAST('text' AS varchar(10))
                                ,CAST('right' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('3' AS tinyint)
                                ,CAST('date' AS varchar(25))
                                ,CAST('text' AS varchar(10))
                                ,CAST('right' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('4' AS tinyint)
                                ,CAST('datetime' AS varchar(25))
                                ,CAST('text' AS varchar(10))
                                ,CAST('right' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('5' AS tinyint)
                                ,CAST('boolean' AS varchar(25))
                                ,CAST('checkbox' AS varchar(10))
                                ,CAST('center' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('6' AS tinyint)
                                ,CAST('time' AS varchar(25))
                                ,CAST('text' AS varchar(10))
                                ,CAST('right' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('7' AS tinyint)
                                ,CAST('text' AS varchar(25))
                                ,CAST('textarea' AS varchar(10))
                                ,CAST('left' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('8' AS tinyint)
                                ,CAST('image' AS varchar(25))
                                ,CAST('image' AS varchar(10))
                                ,CAST('left' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('9' AS tinyint)
                                ,CAST('binary' AS varchar(25))
                                ,CAST('file' AS varchar(10))
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('10' AS tinyint)
                                ,CAST('undefined' AS varchar(25))
                                ,CAST('textarea' AS varchar(10))
                                ,CAST('left' AS varchar(6))
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
/**********************************************************************************
Inserir dados na tabela [dbo].[Types]
**********************************************************************************/
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('1' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('bigint' AS varchar(25))
                                ,CAST('-9007199254740990' AS sql_variant)
                                ,CAST('9007199254740990' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('2' AS tinyint)
                                ,CAST('9' AS tinyint)
                                ,CAST('binary' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('3' AS tinyint)
                                ,CAST('5' AS tinyint)
                                ,CAST('bit' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('4' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('char' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('5' AS tinyint)
                                ,CAST('3' AS tinyint)
                                ,CAST('date' AS varchar(25))
                                ,CAST('01/01/0001' AS sql_variant)
                                ,CAST('31/12/9999' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('6' AS tinyint)
                                ,CAST('4' AS tinyint)
                                ,CAST('datetime' AS varchar(25))
                                ,CAST('01/01/1753 00:00:00.000' AS sql_variant)
                                ,CAST('31/12/9999 23:59:59.997' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('7' AS tinyint)
                                ,CAST('4' AS tinyint)
                                ,CAST('datetime2' AS varchar(25))
                                ,CAST('01/01/0001 00:00:00.0000000' AS sql_variant)
                                ,CAST('31/12/9999 23:59:59.9999999' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('8' AS tinyint)
                                ,CAST('4' AS tinyint)
                                ,CAST('datetimeoffset' AS varchar(25))
                                ,CAST('01/01/0001 00:00:00.0000000' AS sql_variant)
                                ,CAST('31/12/9999 23:59:59.9999999' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('9' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('decimal' AS varchar(25))
                                ,CAST('-9007199254740990' AS sql_variant)
                                ,CAST('9007199254740990' AS sql_variant)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('10' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('float' AS varchar(25))
                                ,CAST('-9007199254740990' AS sql_variant)
                                ,CAST('9007199254740990' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('11' AS tinyint)
                                ,CAST('7' AS tinyint)
                                ,CAST('geography' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('12' AS tinyint)
                                ,CAST('7' AS tinyint)
                                ,CAST('geometry' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('13' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('hierarchyid' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('14' AS tinyint)
                                ,CAST('8' AS tinyint)
                                ,CAST('image' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('15' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('int' AS varchar(25))
                                ,CAST('-2147483648' AS sql_variant)
                                ,CAST('2147483647' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('16' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('money' AS varchar(25))
                                ,CAST('-922337203685477' AS sql_variant)
                                ,CAST('922337203685477' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('17' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('nchar' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('18' AS tinyint)
                                ,CAST('7' AS tinyint)
                                ,CAST('ntext' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('19' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('numeric' AS varchar(25))
                                ,CAST('-9007199254740990' AS sql_variant)
                                ,CAST('9007199254740990' AS sql_variant)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('20' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('nvarchar' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('21' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('real' AS varchar(25))
                                ,CAST('-9007199254740990' AS sql_variant)
                                ,CAST('9007199254740990' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('22' AS tinyint)
                                ,CAST('4' AS tinyint)
                                ,CAST('smalldatetime' AS varchar(25))
                                ,CAST('01/01/1900' AS sql_variant)
                                ,CAST('06/06/2079' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('23' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('smallint' AS varchar(25))
                                ,CAST('-32768' AS sql_variant)
                                ,CAST('32767' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('24' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('smallmoney' AS varchar(25))
                                ,CAST('214748' AS sql_variant)
                                ,CAST('214748' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('25' AS tinyint)
                                ,CAST('10' AS tinyint)
                                ,CAST('sql_variant' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('26' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('sysname' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('27' AS tinyint)
                                ,CAST('7' AS tinyint)
                                ,CAST('text' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('28' AS tinyint)
                                ,CAST('6' AS tinyint)
                                ,CAST('time' AS varchar(25))
                                ,CAST('00:00:00.0000000' AS sql_variant)
                                ,CAST('23:59:59.9999999' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('29' AS tinyint)
                                ,CAST('4' AS tinyint)
                                ,CAST('timestamp' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('30' AS tinyint)
                                ,CAST('2' AS tinyint)
                                ,CAST('tinyint' AS varchar(25))
                                ,CAST('0' AS sql_variant)
                                ,CAST('255' AS sql_variant)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('31' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('uniqueidentifier' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('32' AS tinyint)
                                ,CAST('9' AS tinyint)
                                ,CAST('varbinary' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('33' AS tinyint)
                                ,CAST('1' AS tinyint)
                                ,CAST('varchar' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,CAST('1' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('34' AS tinyint)
                                ,CAST('7' AS tinyint)
                                ,CAST('xml' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,CAST('0' AS bit)
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
/**********************************************************************************
Inserir dados na tabela [dbo].[Masks]
**********************************************************************************/
INSERT INTO [dbo].[Masks] ([Id]
                                ,[Name]
                                ,[Mask]
                                ,[CreatedAt]
                                ,[CreatedBy]
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('1' AS bigint)
                                ,CAST('BigInteger' AS varchar(25))
                                ,CAST('#.###.###.###.###.###' AS varchar(MAX))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
INSERT INTO [dbo].[Masks] ([Id]
                                ,[Name]
                                ,[Mask]
                                ,[CreatedAt]
                                ,[CreatedBy]
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('2' AS bigint)
                                ,CAST('Integer' AS varchar(25))
                                ,CAST('#.###.###.###' AS varchar(MAX))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
INSERT INTO [dbo].[Masks] ([Id]
                                ,[Name]
                                ,[Mask]
                                ,[CreatedAt]
                                ,[CreatedBy]
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('3' AS bigint)
                                ,CAST('SmallInteger' AS varchar(25))
                                ,CAST('##.###' AS varchar(MAX))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
INSERT INTO [dbo].[Masks] ([Id]
                                ,[Name]
                                ,[Mask]
                                ,[CreatedAt]
                                ,[CreatedBy]
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('4' AS bigint)
                                ,CAST('TinyInteger' AS varchar(25))
                                ,CAST('###' AS varchar(MAX))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
INSERT INTO [dbo].[Masks] ([Id]
                                ,[Name]
                                ,[Mask]
                                ,[CreatedAt]
                                ,[CreatedBy]
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('5' AS bigint)
                                ,CAST('ShortInteger' AS varchar(25))
                                ,CAST('##.###' AS varchar(MAX))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
INSERT INTO [dbo].[Masks] ([Id]
                                ,[Name]
                                ,[Mask]
                                ,[CreatedAt]
                                ,[CreatedBy]
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('6' AS bigint)
                                ,CAST('DateTime' AS varchar(25))
                                ,CAST('dd/MM/yyyy hh:mm:ss' AS varchar(MAX))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
/**********************************************************************************
Inserir dados na tabela [dbo].[Domains]
**********************************************************************************/
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('1' AS bigint)
                                ,CAST('1' AS tinyint)
                                ,CAST('1' AS bigint)
                                ,CAST('BigInteger' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('2' AS bigint)
                                ,CAST('15' AS tinyint)
                                ,CAST('2' AS bigint)
                                ,CAST('Integer' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('3' AS bigint)
                                ,CAST('15' AS tinyint)
                                ,CAST('5' AS bigint)
                                ,CAST('ShortInteger' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,CAST('-65536' AS sql_variant)
                                ,CAST('65535' AS sql_variant)
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('4' AS bigint)
                                ,CAST('23' AS tinyint)
                                ,CAST('3' AS bigint)
                                ,CAST('SmallInteger' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('5' AS bigint)
                                ,CAST('30' AS tinyint)
                                ,CAST('4' AS bigint)
                                ,CAST('TinyInteger' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('6' AS bigint)
                                ,CAST('3' AS tinyint)
                                ,NULL
                                ,CAST('Boolean' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('7' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Varchar(15)' AS varchar(25))
                                ,CAST('15' AS smallint)
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('8' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Varchar(20)' AS varchar(25))
                                ,CAST('20' AS smallint)
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('9' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Varchar(25)' AS varchar(25))
                                ,CAST('25' AS smallint)
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('10' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Varchar(50)' AS varchar(25))
                                ,CAST('50' AS smallint)
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('11' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Varchar(256)' AS varchar(25))
                                ,CAST('256' AS smallint)
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('12' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Varchar(MAX)' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('13' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('JavaScript' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,CAST('JS' AS varchar(5))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('14' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('SQL' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,CAST('SQL' AS varchar(5))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('15' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('JSON' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,CAST('JSON' AS varchar(5))
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('16' AS bigint)
                                ,CAST('6' AS tinyint)
                                ,CAST('6' AS bigint)
                                ,CAST('DateTime' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('17' AS bigint)
                                ,CAST('25' AS tinyint)
                                ,NULL
                                ,CAST('Variant' AS varchar(25))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('18' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Codification' AS varchar(25))
                                ,CAST('5' AS smallint)
                                ,NULL
                                ,CAST('JSON;JS;SQL' AS varchar(MAX))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('19' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('HtmlInputType' AS varchar(25))
                                ,CAST('10' AS smallint)
                                ,NULL
                                ,CAST('text;checkbox;textarea;image;file' AS varchar(MAX))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('20' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('HtmlInputAlign' AS varchar(25))
                                ,CAST('6' AS smallint)
                                ,NULL
                                ,CAST('left;center;right' AS varchar(MAX))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
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
                                ,[UpdatedAt]
                                ,[UpdatedBy])
                         VALUES (CAST('21' AS bigint)
                                ,CAST('33' AS tinyint)
                                ,NULL
                                ,CAST('Action' AS varchar(25))
                                ,CAST('15' AS smallint)
                                ,NULL
                                ,CAST('create;read;update;delete;commit;rollback' AS varchar(MAX))
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,GETDATE()
                                ,'admnistrator'
                                ,NULL
                                ,NULL)
GO
