IF(SELECT object_id('[dbo].[Config]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[Config] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[Config](@SystemName VARCHAR(25)
							  ,@DatabaseName VARCHAR(25) = NULL
							  ,@TableName VARCHAR(25) = NULL
							  ,@ReturnValue BIGINT OUT) AS
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
		SELECT 	'System' AS [ClassName]
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
		IF (SELECT IsOffAir FROM [dbo].[#Systems]) = 1 BEGIN
			SET @ErrorMessage = 'Sistema "' + @SystemName + '" fora do ar.';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Systems] DROP COLUMN [IsOffAir]
		IF @DatabaseName IS NULL
			RETURN 1
		ALTER TABLE [dbo].[#Systems] ADD PRIMARY KEY CLUSTERED([Id])
		IF @DatabaseName = 'all' BEGIN
			SET @DatabaseName = NULL
			SET @TableName = NULL
		END

		-- 1 [Databases]
		SELECT 	'Database' AS [ClassName]
				,[D].[Id]
				,[D].[ConnectionId]
				,[D].[Name]
				,[D].[Alias]
				,[D].[Description]
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
		IF @DatabaseName IS NULL BEGIN
			ALTER TABLE [dbo].[#Databases] DROP COLUMN [Folder]
		END

		-- 2 [Connections]
		SELECT 	'Connection' AS [ClassName]
				,[C].[Id]
				,[C].[Provider]
				,[C].[HostName]
				,[C].[Port]
				,[C].[IntegratedSecurity]
				,[C].[ConnectionTimeout]
				,[C].[ExtendedProperties]
				,[C].[UserID]
				,[C].[Password]
				,[C].[PersistSecurityInfo]
				,[C].[AdditionalParameters]
			INTO [dbo].[#Connections]
			FROM [dbo].[Connections] [C]
			WHERE [C].[Id] IN (SELECT [ConnectionId] FROM [dbo].[#Databases])
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Banco(s)-de-dados não cadastrado(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [dbo].[#Connections] ADD PRIMARY KEY CLUSTERED([Id])

		-- 3 [Tables]
		SELECT	'Table' AS [ClassName]
				,[T].[Id]
				,[DT].[DatabaseId]
				,[T].[Name]
				,[T].[Alias]
				,[T].[Description]
				,[T].[ParentTableId]
				,[T].[IsLegacy]
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
			-- 4 [Columns]
			SELECT	'Column' AS [ClassName]
					,[C].[Id]
					,[C].[TableId]
					,[C].[Sequence]
					,[C].[DomainId]
					,[C].[ReferenceTableId]
					,[C].[Name]
					,[C].[Alias]
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
					,[C].[IsGridable]			
					,[C].[IsEncrypted]
					,[C].[IsInWords]
				INTO [dbo].[#Columns]
				FROM [dbo].[Columns] [C]
					INNER JOIN [dbo].[#Tables] [T] ON [T].[Id]= [C].[TableId] 
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Colunas de tabelas não cadastradas.';
				THROW 51000, @ErrorMessage, 1
			END
			ALTER TABLE [dbo].[#Columns] ADD PRIMARY KEY CLUSTERED([Id])
			CREATE INDEX [#ColumnsDomainId] ON [dbo].[#Columns]([DomainId])

			-- 5 [Domains]
			SELECT	'Domain' AS [ClassName]
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

			-- 6 [Types]
			SELECT 	'Type' AS [ClassName]
					,[T].[Id]
					,[T].[CategoryId]
					,[T].[Name]
					,[T].[MaxLength]
				    ,[T].[Minimum]
					,[T].[Maximum]
					,[T].[AskLength]
					,[T].[AskDecimals]
					,[T].[AskPrimarykey]
					,[T].[AskAutoincrement]
					,[T].[AskFilterable]
					,[T].[AskGridable]
					,[T].[AskCodification]
					,[T].[IsActive]
				INTO [dbo].[#Types]
				FROM [dbo].[Types] [T]
				WHERE EXISTS(SELECT TOP 1 1 FROM [dbo].[#Domains] WHERE [TypeId] = [T].[Id])
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Tipos de domínios não cadastrados.';
				THROW 51000, @ErrorMessage, 1
			END
			CREATE INDEX [#TypesCategoryId] ON [dbo].[#Types]([CategoryId])

			-- 7 [Categories]
			SELECT 	'Category' AS [ClassName]
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
					,[C].[AskInWords]
				INTO [dbo].[#Categories]
				FROM [dbo].[Categories] [C]
				WHERE EXISTS(SELECT TOP 1 1 FROM [dbo].[#Types] WHERE [CategoryId] = [C].[Id])
			IF @@ROWCOUNT = 0 BEGIN
			   SET @ErrorMessage = 'Categoria(s) de tipos não cadastrada(s).';
			   THROW 51000, @ErrorMessage, 1
			END

			-- 8 [Menus]
			SELECT 	'Menu' AS [ClassName]
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

			-- 9 [Indexes]
			SELECT 	'Index' AS [ClassName]
					,[I].[Id]
					,[I].[TableId]
					,[I].[Name]
					,[I].[IsUnique]
				INTO [dbo].[#Indexes]
				FROM [dbo].[Indexes] [I]
					INNER JOIN [dbo].[#Tables] [T] ON [T].[Id] = [I].[TableId]
			ALTER TABLE [dbo].[#Indexes] ADD PRIMARY KEY NONCLUSTERED([Id])

			-- 10 [Indexkeys]
			SELECT 	'Indexkey' AS [ClassName]
					,[IK].[Id]
					,[IK].[IndexId]
					,[IK].[Sequence]
					,[IK].[ColumnId]
					,[IK].[IsDescending]
				INTO [dbo].[#Indexkeys]
				FROM [dbo].[Indexkeys] [IK]
					INNER JOIN [dbo].[#Indexes] [I] ON [I].[Id] = [IK].IndexId
			-- 11 [Masks]
			SELECT 	'Mask' AS [ClassName]
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
			
			SELECT * FROM [dbo].[#Databases] ORDER BY [Name] -- 1 [#Databases]
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
			SELECT * FROM [dbo].[#Connections] ORDER BY [Id] -- 1 [#Connections]]
			SELECT * FROM [dbo].[#Databases] ORDER BY [Name] -- 2 [#Databases]
			SELECT * FROM [dbo].[#Tables] ORDER BY [DatabaseId], [Name] -- 3 [#Tables]
		END
		
		RETURN 0
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
