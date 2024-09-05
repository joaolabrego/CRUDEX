USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[ColumnsRead]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[ColumnsRead] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[ColumnsRead](@PageNumber INT OUT
									,@LimitRows BIGINT OUT
									,@MaxPage INT OUT
									,@PaddingBrowseLastPage BIT OUT
									,@UserName VARCHAR(25)
									,@Record VARCHAR(MAX)) AS 
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsRead: ',
				@RowCount BIGINT,
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
		SELECT @LogId = [LogId]
				,@TableId = [TableId]
				,@ErrorMessage = [ErrorMessage]
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
		SET @RowCount = @@ROWCOUNT
		DELETE [tab] FROM [dbo].[#tab] [tab] WHERE EXISTS(SELECT 1 FROM [dbo].[#tmp] [tmp] WHERE [tmp].[_] = 'delete' 
		AND [tmp].[Id] = [tab].[Id])
		SET @RowCount = @RowCount - @@ROWCOUNT
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
		SET @RowCount = @RowCount + @@ROWCOUNT
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
		IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
		SET @offset = 0
		SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END
		SET @PageNumber = 1
		SET @MaxPage = 1
		END ELSE BEGIN
		SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END
		IF ABS(@PageNumber) > @MaxPage
		SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
		IF @PageNumber < 0
		SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
		SET @offset = (@PageNumber - 1) * @LimitRows
		IF @PaddingBrowseLastPage = 1 AND @offset + @LimitRows > @RowCount
		SET @offset = CASE WHEN @RowCount > @LimitRows THEN @RowCount -@LimitRows ELSE 0 END
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
		RETURN @RowCount
	END TRY
	BEGIN CATCH
	THROW
	END CATCH
END
GO
