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
			INTO [#Systems]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema "' + @SystemName + '" não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF (SELECT IsOffAir FROM [#Systems]) = 1 BEGIN
			SET @ErrorMessage = 'Sistema "' + @SystemName + '" fora do ar.';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [#Systems] DROP COLUMN [IsOffAir]
		IF @DatabaseName IS NULL
			RETURN 1
		ALTER TABLE [#Systems] ADD PRIMARY KEY CLUSTERED([Id])
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
			INTO [#Databases]
			FROM [dbo].[Databases] [D]
				INNER JOIN [dbo].[SystemsDatabases] [SD] ON [SD].[DatabaseId] = [D].[id]
				INNER JOIN [#Systems] [S] ON [S].[Id] = [SD].[SystemId]
			WHERE [D].[Name] = ISNULL(@DatabaseName, [D].[Name])
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Banco(s)-de-dados não cadastrado(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [#Databases] ADD PRIMARY KEY CLUSTERED([Id])
		IF @DatabaseName IS NULL BEGIN
			ALTER TABLE [#Databases] DROP COLUMN [Folder]
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
			INTO [#Connections]
			FROM [dbo].[Connections] [C]
			WHERE [C].[Id] IN (SELECT [ConnectionId] FROM [#Databases])
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Banco(s)-de-dados não cadastrado(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [#Connections] ADD PRIMARY KEY CLUSTERED([Id])

		-- 3 [Tables]
		SELECT	'Table' AS [ClassName]
				,[T].[Id]
				,[DT].[DatabaseId]
				,[T].[Name]
				,[T].[Alias]
				,[T].[Description]
				,[T].[ParentTableId]
				,[T].[IsLegacy]
			INTO [#Tables]
			FROM [dbo].[Tables] [T]
				INNER JOIN [dbo].[DatabasesTables] [DT] ON [DT].[TableId] = [T].[Id]
				INNER JOIN [#Databases] [D] ON [D].[Id] = [DT].[DatabaseId]
			WHERE [T].[Name] = ISNULL(@TableName, [T].[Name])
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Tabela(s) não cadastrada(s).';
			THROW 51000, @ErrorMessage, 1
		END
		ALTER TABLE [#Tables] ADD PRIMARY KEY CLUSTERED([Id])

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
				INTO [#Columns]
				FROM [dbo].[Columns] [C]
					INNER JOIN [#Tables] [T] ON [T].[Id]= [C].[TableId] 
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Colunas de tabelas não cadastradas.';
				THROW 51000, @ErrorMessage, 1
			END
			ALTER TABLE [#Columns] ADD PRIMARY KEY CLUSTERED([Id])
			CREATE INDEX [#ColumnsDomainId] ON [#Columns]([DomainId])

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
				INTO [#Domains]
				FROM [dbo].[Domains] [D]
				WHERE EXISTS(SELECT TOP 1 1 FROM [#Columns] WHERE [DomainId] = [D].[Id])
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Domínios de colunas não cadastrados.';
				THROW 51000, @ErrorMessage, 1
			END
			ALTER TABLE [#Domains] ADD PRIMARY KEY NONCLUSTERED([Id])
			CREATE INDEX [#DomainsTypeId] ON [#Domains]([TypeId])

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
				INTO [#Types]
				FROM [dbo].[Types] [T]
				WHERE EXISTS(SELECT TOP 1 1 FROM [#Domains] WHERE [TypeId] = [T].[Id])
			IF @@ROWCOUNT = 0 BEGIN
				SET @ErrorMessage = 'Tipos de domínios não cadastrados.';
				THROW 51000, @ErrorMessage, 1
			END
			CREATE INDEX [#TypesCategoryId] ON [#Types]([CategoryId])

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
				INTO [#Categories]
				FROM [dbo].[Categories] [C]
				WHERE EXISTS(SELECT TOP 1 1 FROM [#Types] WHERE [CategoryId] = [C].[Id])
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
				INTO [#Menus]
				FROM [dbo].[Menus] [M]
					INNER JOIN [#Systems] [S] ON [S].[Id] = [M].[SystemId]
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
				INTO [#Indexes]
				FROM [dbo].[Indexes] [I]
					INNER JOIN [#Tables] [T] ON [T].[Id] = [I].[TableId]
			ALTER TABLE [#Indexes] ADD PRIMARY KEY NONCLUSTERED([Id])

			-- 10 [Indexkeys]
			SELECT 	'Indexkey' AS [ClassName]
					,[IK].[Id]
					,[IK].[IndexId]
					,[IK].[Sequence]
					,[IK].[ColumnId]
					,[IK].[IsDescending]
				INTO [#Indexkeys]
				FROM [dbo].[Indexkeys] [IK]
					INNER JOIN [#Indexes] [I] ON [I].[Id] = [IK].IndexId
			
			-- 11 [Masks]
			SELECT 	'Mask' AS [ClassName]
					,[M].[Id]
					,[M].[Name]
					,[M].[Mask]
				INTO [#Masks]
				FROM [dbo].[Masks] [M]
				WHERE EXISTS(SELECT TOP 1 1 FROM [#Domains] WHERE [MaskId] = [M].[Id])
			
			-- 12 [Associations]
			SELECT DISTINCT 'Association' AS [ClassName]
						   ,[A].[Id]
						   ,[A].[TableId1]
						   ,[A].[TableId2]
						   ,[A].[IsBidirectional]
				INTO [#Associations]
				FROM [dbo].[Associations] [A]
					INNER JOIN [#Tables] [T] ON [T].[Id] IN ([A].[TableId1], [A].[TableId2])
			-- 13 [Uniques]
			SELECT DISTINCT 'Unique' AS [ClassName]
						   ,[U].[Id]
						   ,[U].[ColumnId1]
						   ,[U].[ColumnId2]
						   ,[U].[IsBidirectional]
				INTO [#Uniques]
				FROM [dbo].[Uniques] [U]
					INNER JOIN [dbo].[#Columns] [C] ON [C].[Id] IN ([U].[ColumnId1], [U].[ColumnId2])
		END

		-- Results
		SELECT * FROM [#Systems] ORDER BY [Name] -- 0 [#Systems]
		IF @DatabaseName IS NULL BEGIN
			SELECT * FROM [#Databases] ORDER BY [Name] -- 1 [#Databases]
			SELECT * FROM [#Tables] ORDER BY [DatabaseId], [Name] -- 2 [#Tables]
			SELECT * FROM [#Columns] ORDER BY [TableId], [Sequence] -- 3 [#Columns]
			SELECT * FROM [#Domains] ORDER BY [Name] -- 4 [#Domains]
			SELECT * FROM [#Types] ORDER BY [Name] -- 5 [#Types]
			SELECT * FROM [#Categories] ORDER BY [Name] -- 6 [#Categories]
			SELECT * FROM [#Menus] ORDER BY [SystemId], [Sequence] -- 7 [#Menus]
			SELECT * FROM [#Indexes] ORDER BY [Name] -- 8 [#Indexes]
			SELECT * FROM [#Indexkeys] ORDER BY [IndexId], [Sequence] -- 9 [#Indexkeys]
			SELECT * FROM [#Masks] ORDER BY [Id] -- 10 [#Masks]
			SELECT * FROM [#Associations] ORDER BY [Id] -- 11 [#Associations]
			SELECT * FROM [#Uniques] ORDER BY [Id] -- 12 [#Uniques]
		END ELSE BEGIN
			SELECT * FROM [#Connections] ORDER BY [Id] -- 1 [#Connections]]
			SELECT * FROM [#Databases] ORDER BY [Name] -- 2 [#Databases]
			SELECT * FROM [#Tables] ORDER BY [DatabaseId], [Name] -- 3 [#Tables]
		END
		
		RETURN 0
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
