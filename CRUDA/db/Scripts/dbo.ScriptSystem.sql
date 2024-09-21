IF (SELECT object_id('[dbo].[ScriptSystem]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ScriptSystem] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[ScriptSystem](@SystemName VARCHAR(25)) AS
BEGIN
	DECLARE @ErrorMessage VARCHAR(250)

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRY
		IF @SystemName IS NULL BEGIN
			SET @ErrorMessage = 'Nome de sistema é requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 0 [Systems]
		SELECT 	'RecordSystem' AS [ClassName]
				,[Id]
				,[Name]
				,[Description]
				,[ClientName]
				,[MaxRetryLogins]
				,[IsOffAir]
			INTO [dbo].[#Systems]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema "' + @SystemName + '" não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Systems] ADD PRIMARY KEY CLUSTERED([Id])
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
				,[T].[IsPaged]
				,[T].[CurrentId]
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
		-- 3 [Categories]
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
				,[C].[AskInWord]
			INTO [dbo].[#Categories]
			FROM [dbo].[Categories] [C]
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Categoria(s) de tipos não cadastrada(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Categories] ADD PRIMARY KEY CLUSTERED([Id])
		-- 4 [Types]
		SELECT 	'RecordType' AS [ClassName]
				,[T].[Id]
				,[T].[CategoryId]
				,[C].[Name] AS [#CategoryName]
				,[T].[Name]
				,[T].[Name] AS [#DataType]
				,[T].[Minimum]
				,[T].[Maximum]
				,[T].[AskLength]
				,[T].[AskDecimals]
				,[T].[AskPrimarykey]
				,[T].[AskAutoincrement]
				,[T].[AskFilterable]
				,[T].[AskGridable]
				,[T].[AskCodification]
				,[T].[AskFormula]
				,[T].[AllowMaxLength]
				,[T].[IsActive]
			INTO [dbo].[#Types]
			FROM [dbo].[Types] [T]
				INNER JOIN [dbo].[#Categories] [C] ON [C].[Id] = [T].[CategoryId]
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Tipos de domínios não cadastrados.';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[Categories] ADD PRIMARY KEY CLUSTERED([Id])
		-- 5 [Masks]
		SELECT 	'RecordMask' AS [ClassName]
				,[M].[Id]
				,[M].[Name]
				,[M].[Mask]
			INTO [dbo].[#Masks]
			FROM [dbo].[Masks] [M]
		-- 6 [Domains]
		SELECT	'RecordDomain' AS [ClassName]
				,[D].[Id]
				,[D].[TypeId]
				,[T].[Name] AS [#TypeName]
				,[C].[Name] AS [#CategoryName]
				,[D].[MaskId]
				,[M].[Name] AS [#MaskName]
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
				INNER JOIN [dbo].[#Types] [T] ON [T].[Id] = [D].[TypeId]
				INNER JOIN [dbo].[#Categories] [C] ON [C].[Id] = [T].[CategoryId]
				INNER JOIN [dbo].[Masks] [M] ON [M].[Id] = [D].[MaskId]
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Domínios de colunas não cadastrados.';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Domains] ADD PRIMARY KEY NONCLUSTERED([Id])
		CREATE INDEX [#DomainsTypeId] ON [dbo].[#Domains]([TypeId])
		-- 7 [Menus]
		SELECT 	'RecordMenu' AS [ClassName]
				,[M].[Id]
				,[M].[SystemId]
				,[S].[Name] AS [#SystemName]
				,[M].[Sequence]
				,[M].[Caption]
				,[M].[Message]
				,[M].[Action]
				,[M].[ParentMenuId]
				,[PM].[Caption] AS [#ParentMenuCaption]
			INTO [dbo].[#Menus]
			FROM [dbo].[Menus] [M]
				LEFT JOIN [dbo].[Menus] [PM] ON [PM].[Id] = [M].[ParentMenuId]
				INNER JOIN [dbo].[#Systems] [S] ON [S].[Id] = [M].[SystemId]
				
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Menu(s) de sistema não cadastrado(s).';
			THROW 51000, @ErrorMessage, 1
		END




	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
