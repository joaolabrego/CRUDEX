IF (SELECT object_id('[dbo].[ScriptSystem]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ScriptSystem] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[ScriptSystem](@SystemName VARCHAR(25)) AS
BEGIN
	DECLARE @ErrorMessage VARCHAR(250)

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRY
		IF @SystemName IS NULL
			THROW 51000, 'Nome de sistema requerido', 1
		-- 1 [Systems]
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
		IF @@ROWCOUNT = 0
			THROW 51000, 'Sistema não cadastrado', 1
		ALTER TABLE [dbo].[#Systems] ADD PRIMARY KEY CLUSTERED([Id])
		-- 2 [[SystemsDatabases]]
		SELECT 	'RecordSystemDatabase' AS [ClassName]
				,[SD].[Id]
				,[SD].[SystemId]
				,[S].[Name] AS [#SystemName]
				,[SD].[DatabaseId]
				,[D].[Name] AS [#DatabaseName]
				,[SD].[Description]
			INTO [dbo].[#SystemsDatabases]
			FROM [dbo].[SystemsDatabases] [SD]
				INNER JOIN [dbo].[#Systems] [S] ON [S].[Id] = [SD].[SystemId]
				INNER JOIN [dbo].[Databases] [D] ON [D].[Id] = [SD].[DatabaseId]
		IF @@ROWCOUNT = 0
			THROW 51000, 'Sistemas x Bancos-de-dados não cadastrado(s)', 1
		ALTER TABLE [dbo].[#SystemsDatabases] ADD PRIMARY KEY CLUSTERED([Id])
		-- 3 [Databases]
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
				INNER JOIN [dbo].[#SystemsDatabases] [SD] ON [SD].[DatabaseId] = [D].[Id]
		IF @@ROWCOUNT = 0
			THROW 51000, 'Banco(s)-de-dados não cadastrado(s)', 1
		ALTER TABLE [dbo].[#Databases] ADD PRIMARY KEY CLUSTERED([Id])
		-- 4 [DatabasesTables]
		SELECT 'RecordDatabaseTable' AS [ClassName]
			  ,[DT].[Id]
			  ,[DT].[DatabaseId]
			  ,[D].[Name] AS [#DatabaseName]
			  ,[DT].[TableId]
			  ,[T].[Name] AS [#TableName]
			  ,[DT].[Description]
			INTO [dbo].[#DatabasesTables]
			FROM [dbo].[DatabasesTables] [DT]
				INNER JOIN [dbo].[#Databases] [D] ON [D].[Id] = [DT].[DatabaseId]
				INNER JOIN [dbo].[Tables] [T] ON [T].[Id] = [DT].[TableId]
		ALTER TABLE [dbo].[#DatabasesTables] ADD PRIMARY KEY CLUSTERED([Id])
		-- 5 [Tables]
		SELECT	'RecordTable' AS [ClassName]
				,[T].[Id]
				,[T].[Name]
				,[T].[Alias]
				,[T].[Description]
				,[T].[ParentTableId]
				,[PT].[Name] AS [#ParentTableName]
				,[T].[IsPaged]
				,[T].[CurrentId]
			INTO [dbo].[#Tables]
			FROM [dbo].[Tables] [T]
				INNER JOIN [dbo].[#DatabasesTables] [DT] ON [DT].[TableId] = [T].[Id]
				LEFT JOIN [dbo].[Tables] [PT] ON [PT].[Id] = [T].[ParentTableId]
		IF @@ROWCOUNT = 0
			THROW 51000, 'Tabela(s) não cadastrada(s)', 1
		ALTER TABLE [dbo].[#Tables] ADD PRIMARY KEY CLUSTERED([Id])
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
		IF @@ROWCOUNT = 0
			THROW 51000, 'Categoria(s) de tipos não cadastrada(s)', 1
		ALTER TABLE [dbo].[#Categories] ADD PRIMARY KEY CLUSTERED([Id])
		-- 7 [Types]
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
		IF @@ROWCOUNT = 0
			THROW 51000, 'Tipos de domínios não cadastrados', 1
		ALTER TABLE [dbo].[#Types] ADD PRIMARY KEY CLUSTERED([Id])
		-- 8 [Masks]
		SELECT 	'RecordMask' AS [ClassName]
				,[M].[Id]
				,[M].[Name]
				,[M].[Mask]
			INTO [dbo].[#Masks]
			FROM [dbo].[Masks] [M]
		-- 9 [Domains]
		SELECT	'RecordDomain' AS [ClassName]
				,[D].[Id]
				,[D].[TypeId]
				,[T].[Name] AS [#TypeName]
				,[C].[Name] AS [#CategoryName]
				,[T].[Name] + CASE WHEN ISNULL([D].[Length], 0) > 0 
								   THEN '(' + CAST([D].[Length] AS VARCHAR(10)) + 
										CASE WHEN ISNULL([D].[Decimals], 0) > 0 
											 THEN CAST([D].[Decimals] AS VARCHAR(10)) 
											 ELSE '' 
										END + ')'
								   ELSE CASE WHEN [T].[AllowMaxLength] = 1 
											 THEN '(MAX)' 
											 ELSE '' 
										END
							  END AS [#DataType]
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
				LEFT JOIN [dbo].[Masks] [M] ON [M].[Id] = [D].[MaskId]
		IF @@ROWCOUNT = 0
			THROW 51000, 'Domínios de colunas não cadastrados', 1
		ALTER TABLE [dbo].[#Domains] ADD PRIMARY KEY CLUSTERED([Id])
		-- 10 [Menus]
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
		IF @@ROWCOUNT = 0
			THROW 51000, 'Menu(s) de sistema não cadastrado(s)', 1
		ALTER TABLE [dbo].[#Menus] ADD PRIMARY KEY CLUSTERED([Id])
		-- 11 [SystemsUsers]
		SELECT 'RecordSystemUser' AS [ClassName] 
			  ,[SU].[Id]
			  ,[SU].[SystemId]
			  ,[S].[Name] AS [#SystemName]
			  ,[SU].[UserId]
			  ,[U].[Name] AS [#UserName]
			  ,[SU].[Description]
			INTO [dbo].[#SystemsUsers] 
			FROM [dbo].[SystemsUsers] [SU]
				INNER JOIN [dbo].[#Systems] [S] ON [S].[Id] = [SU].[SystemId]
				INNER JOIN [dbo].[Users] [U] ON [U].[Id] = [SU].[UserId]
		IF @@ROWCOUNT = 0
			THROW 51000, 'Menu(s) de sistema não cadastrado(s)', 1
		ALTER TABLE [dbo].[#SystemsUsers] ADD PRIMARY KEY NONCLUSTERED([Id])
		-- 12 [Users]
		SELECT 'RecordUser' AS [ClassName] 
			  ,[U].[Id]
			  ,[U].[Name]
			  ,[U].[Password]
			  ,[U].[FullName]
			  ,[U].[RetryLogins]
			  ,[U].[IsActive]
			INTO [dbo].[#Users]
			FROM [dbo].[Users] [U]
				INNER JOIN [dbo].[#SystemsUsers] [SU] ON [SU].[UserId] = [U].[Id]
		ALTER TABLE [dbo].[#Users] ADD PRIMARY KEY CLUSTERED([Id])
		-- 13 [Columns]
		SELECT 'RecordColumn' AS [ClassName]
			  ,[C].[Id]
			  ,[C].[TableId]
			  ,[T].[Name] AS [#TableName]
			  ,[T].[Alias] AS [#TableAlias]
			  ,[C].[Sequence]
			  ,[C].[DomainId]
			  ,[D].[Name] AS [#DomainName]
			  ,[D].[#CategoryName]
			  ,[D].[#TypeName]
			  ,[D].[#DataType]
			  ,[C].[ReferenceTableId]
			  ,[RT].[Name] AS [#ReferenceTableName]
			  ,[C].[Name]
			  ,[C].[Description]
			  ,[C].[Title]
			  ,[C].[Caption]
			  ,[C].[ValidValues]
			  ,[C].[Default]
			  ,[C].[Minimum]
			  ,[C].[Maximum]
			  ,[C].[IsPrimarykey]
			  ,[C].[IsAutoIncrement]
			  ,[C].[IsRequired]
			  ,[C].[IsListable]
			  ,[C].[IsFilterable]
			  ,[C].[IsEditable]
			  ,[C].[IsGridable]
			  ,[C].[IsEncrypted]
			INTO [dbo].[#Columns]
			FROM [dbo].[Columns] [C]
				INNER JOIN [dbo].[#Tables] [T] ON [T].[Id] = [C].[TableId]
				INNER JOIN [dbo].[#Domains] [D] ON [D].[Id] = [C].[DomainId]
				LEFT JOIN [dbo].[#Tables] [RT] ON [RT].[Id] = [C].[ReferenceTableId]
		IF @@ROWCOUNT = 0
			THROW 51000, 'Coluna(s) de tabela(s) não cadastrada(s)', 1
		ALTER TABLE [dbo].[#Columns] ADD PRIMARY KEY CLUSTERED([Id])
		-- 14 [Indexes]
		SELECT 'RecordIndex' AS [ClassName]
			  ,[I].[Id]
			  ,[I].[DatabaseId]
			  ,[D].[Name] AS [#DatabaseName]
			  ,[I].[TableId]
			  ,[T].[Name] AS [#TableName]
			  ,[I].[Name]
			  ,[I].[IsUnique]
		  INTO [dbo].[#Indexes]
		  FROM [dbo].[Indexes] [I]
			INNER JOIN [dbo].[#Databases] [D] ON [D].[Id] = [I].[DatabaseId]
			INNER JOIN [dbo].[#Tables] [T] ON [T].[Id] = [I].[TableId]
		ALTER TABLE [dbo].[#Indexes] ADD PRIMARY KEY CLUSTERED([Id])
		-- 15 [Indexkeys]
		SELECT 'RecordIndexkey' AS [ClassName]
			  ,[IK].[Id]
			  ,[IK].[IndexId]
			  ,[I].[Name] AS [#IndexName]
			  ,[IK].[Sequence]
			  ,[IK].[ColumnId]
			  ,[C].[Name] AS [#ColumnName]
			  ,[IK].[IsDescending]
		  INTO [dbo].[#Indexkeys]
		  FROM [dbo].[Indexkeys] [IK]
			INNER JOIN [dbo].[#Indexes] [I] ON [I].[Id] = [IK].[IndexId]
			INNER JOIN [dbo].[#Columns] [C] ON [C].[Id] = [IK].[ColumnId]
		ALTER TABLE [dbo].[#Indexkeys] ADD PRIMARY KEY CLUSTERED([Id])
		-- 16 [Logins]
		SELECT TOP 0 'RecordLogin' AS [ClassName]
					,[Id]
				    ,[SystemId]
					,[UserId]
					,[PublicKey]
					,[IsLogged]
			INTO [dbo].[#Logins]
			FROM [dbo].[Logins]
		SELECT * FROM [dbo].[#Categories]
		SELECT * FROM [dbo].[#Types]
		SELECT * FROM [dbo].[#Masks]
		SELECT * FROM [dbo].[#Domains]
		SELECT * FROM [dbo].[#Systems]
		SELECT * FROM [dbo].[#Menus] ORDER BY [SystemId], [Sequence]
		SELECT * FROM [dbo].[#Users]
		SELECT * FROM [dbo].[#SystemsUsers]
		SELECT * FROM [dbo].[#Databases]
		SELECT * FROM [dbo].[#SystemsDatabases]
		SELECT * FROM [dbo].[#Tables]
		SELECT * FROM [dbo].[#DatabasesTables]
		SELECT * FROM [dbo].[#Columns] ORDER BY [TableId], [Sequence]
		SELECT * FROM [dbo].[#Indexes]
		SELECT * FROM [dbo].[#Indexkeys] ORDER BY [IndexId], [Sequence]
		SELECT * FROM [dbo].[#Logins]
	END TRY
	BEGIN CATCH
        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
