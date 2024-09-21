USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE[dbo].[ColumnsRead](@LoginId INT
                                  ,@RecordFilter NVARCHAR(MAX)
                                  ,@OrderBy NVARCHAR(MAX)
                                  ,@PaddingGridLastPage BIT
                                  ,@PageNumber INT OUT
                                  ,@LimitRows INT OUT
                                  ,@MaxPage INT OUT) AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @ErrorMessage NVARCHAR(255) = 'Stored Procedure [ColumnsRead]: '

        IF @LoginId IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de @LoginId é requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF @RecordFilter IS NULL BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de @RecordFilter é requerido';
            THROW 51000, @ErrorMessage, 1
        END
        IF ISJSON(@RecordFilter) = 0 BEGIN
            SET @ErrorMessage = @ErrorMessage + 'Valor de @ActualRecord não está no formato JSON';
            THROW 51000, @ErrorMessage, 1
        END
		SET @OrderBy = TRIM(ISNULL(@OrderBy, ''))
		IF @OrderBy = ''
			SET @OrderBy = '[Id]'
		ELSE BEGIN
			SET @OrderBy = REPLACE(REPLACE(@OrderBy, '[', ''), ']', '')
			IF EXISTS(SELECT [value]
							FROM STRING_SPLIT(@OrderBy, ',')
							WHERE CHARINDEX(TRIM(value), STUFF((SELECT ', ' + [COLUMN_NAME]
							FROM [INFORMATION_SCHEMA].[COLUMNS]
							WHERE TABLE_NAME = 'Columns'
							ORDER BY ORDINAL_POSITION
							FOR XML PATH(''), TYPE).[value]('.', 'VARCHAR(MAX)'), 1, 2, '')) = 0) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Nome de coluna em @OrderBy é inválido';
				THROW 51000, @ErrorMessage, 1
			END
			SELECT @OrderBy = STRING_AGG('[' + TRIM(value) + ']', ', ') FROM STRING_SPLIT(@OrderBy, ',')
		END

        DECLARE @TransactionId INT = (SELECT MAX([Id]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
                ,@W_Id int = CAST(JSON_VALUE(@RecordFilter, '$.Id') AS int)
                ,@W_TableId int = CAST(JSON_VALUE(@RecordFilter, '$.TableId') AS int)
                ,@W_DomainId int = CAST(JSON_VALUE(@RecordFilter, '$.DomainId') AS int)
                ,@W_ReferenceTableId int = CAST(JSON_VALUE(@RecordFilter, '$.ReferenceTableId') AS int)
                ,@W_Name nvarchar(25) = CAST(JSON_VALUE(@RecordFilter, '$.Name') AS nvarchar(25))
                ,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@RecordFilter, '$.IsAutoIncrement') AS bit)
                ,@W_IsRequired bit = CAST(JSON_VALUE(@RecordFilter, '$.IsRequired') AS bit)
                ,@W_IsListable bit = CAST(JSON_VALUE(@RecordFilter, '$.IsListable') AS bit)
                ,@W_IsFilterable bit = CAST(JSON_VALUE(@RecordFilter, '$.IsFilterable') AS bit)
                ,@W_IsEditable bit = CAST(JSON_VALUE(@RecordFilter, '$.IsEditable') AS bit)
                ,@W_IsGridable bit = CAST(JSON_VALUE(@RecordFilter, '$.IsGridable') AS bit)
                ,@W_IsEncrypted bit = CAST(JSON_VALUE(@RecordFilter, '$.IsEncrypted') AS bit)

		IF @W_Id IS NOT NULL BEGIN
			IF @W_Id < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
				THROW 51000, @ErrorMessage, 1
			END
		END
		IF @W_TableId IS NOT NULL BEGIN
			IF @W_TableId < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
				THROW 51000, @ErrorMessage, 1
			END
		END
		IF @W_DomainId IS NOT NULL BEGIN
			IF @W_DomainId < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser maior que ou igual à ''1''.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.';
				THROW 51000, @ErrorMessage, 1
			END
		END
		IF @W_ReferenceTableId IS NOT NULL BEGIN
			IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser maior que ou igual à ''1''.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser menor que ou igual à ''9007199254740990''.';
				THROW 51000, @ErrorMessage, 1
			END
		END

        DECLARE @RowCount INT
               ,@OffSet INT

        SELECT CAST(JSON_QUERY([ActualRecord], '$.Id') AS int) AS [Id]
              ,CAST(JSON_QUERY([ActualRecord], '$.TableId') AS int) AS [TableId]
              ,CAST(JSON_QUERY([ActualRecord], '$.Sequence') AS smallint) AS [Sequence]
              ,CAST(JSON_QUERY([ActualRecord], '$.DomainId') AS int) AS [DomainId]
              ,CAST(JSON_QUERY([ActualRecord], '$.ReferenceTableId') AS int) AS [ReferenceTableId]
              ,CAST(JSON_QUERY([ActualRecord], '$.Name') AS nvarchar(25)) AS [Name]
              ,CAST(JSON_QUERY([ActualRecord], '$.Description') AS nvarchar(50)) AS [Description]
              ,CAST(JSON_QUERY([ActualRecord], '$.Title') AS nvarchar(25)) AS [Title]
              ,CAST(JSON_QUERY([ActualRecord], '$.Caption') AS nvarchar(25)) AS [Caption]
              ,CAST(JSON_QUERY([ActualRecord], '$.ValidValues') AS nvarchar(MAX)) AS [ValidValues]
              ,CAST(JSON_QUERY([ActualRecord], '$.Default') AS nvarchar(MAX)) AS [Default]
              ,CAST(JSON_QUERY([ActualRecord], '$.Minimum') AS nvarchar(MAX)) AS [Minimum]
              ,CAST(JSON_QUERY([ActualRecord], '$.Maximum') AS nvarchar(MAX)) AS [Maximum]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsPrimarykey') AS bit) AS [IsPrimarykey]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsAutoIncrement') AS bit) AS [IsAutoIncrement]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsRequired') AS bit) AS [IsRequired]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsListable') AS bit) AS [IsListable]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsFilterable') AS bit) AS [IsFilterable]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsEditable') AS bit) AS [IsEditable]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsGridable') AS bit) AS [IsGridable]
              ,CAST(JSON_QUERY([ActualRecord], '$.IsEncrypted') AS bit) AS [IsEncrypted]
			  ,[Action] AS [_]
		   INTO [dbo].[#tmpOperations]
           FROM [cruda].[Operations]
           WHERE [TransactionId] = @TransactionId
                 AND [TableName] = 'Columns'
                 AND [IsConfirmed] IS NULL
		CREATE UNIQUE INDEX [#unqOperations] ON [dbo].[#tmpOperations]([Id])
        SELECT CASE WHEN [U].[Id] IS NULL THEN [C].[Id] ELSE [U].[Id] END AS [Id]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[TableId] ELSE [U].[TableId] END AS [TableId]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Sequence] ELSE [U].[Sequence] END AS [Sequence]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[DomainId] ELSE [U].[DomainId] END AS [DomainId]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[ReferenceTableId] ELSE [U].[ReferenceTableId] END AS [ReferenceTableId]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Name] ELSE [U].[Name] END AS [Name]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Description] ELSE [U].[Description] END AS [Description]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Title] ELSE [U].[Title] END AS [Title]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Caption] ELSE [U].[Caption] END AS [Caption]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[ValidValues] ELSE [U].[ValidValues] END AS [ValidValues]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Default] ELSE [U].[Default] END AS [Default]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Minimum] ELSE [U].[Minimum] END AS [Minimum]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[Maximum] ELSE [U].[Maximum] END AS [Maximum]
              ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsPrimarykey] ELSE [U].[IsPrimarykey] END AS [IsPrimarykey]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsAutoIncrement] ELSE [U].[IsAutoIncrement] END AS [IsAutoIncrement]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsRequired] ELSE [U].[IsRequired] END AS [IsRequired]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsListable] ELSE [U].[IsListable] END AS [IsListable]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsFilterable] ELSE [U].[IsFilterable] END AS [IsFilterable]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsEditable] ELSE [U].[IsEditable] END AS [IsEditable]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsGridable] ELSE [U].[IsGridable] END AS [IsGridable]
			  ,CASE WHEN [U].[Id] IS NULL THEN [C].[IsEncrypted] ELSE [U].[IsEncrypted] END AS [IsEncrypted]
            INTO [dbo].[#tmp]
            FROM [dbo].[Columns] [C]
				LEFT JOIN [dbo].[#tmpOperations] [U] ON [U].[Id] = [C].[Id] AND [U].[_] = 'update'
				LEFT JOIN [dbo].[#tmpOperations] [D] ON [D].[Id] = [C].[Id] AND [D].[_] = 'delete'
            WHERE [D].[Id] IS NULL 
				  AND [C].[Id] = ISNULL(@W_Id, [C].[Id])
                  AND [C].[TableId] = ISNULL(@W_TableId, [C].[TableId])
                  AND [C].[DomainId] = ISNULL(@W_DomainId, [C].[DomainId])
                  AND (@W_ReferenceTableId IS NULL OR [C].[ReferenceTableId] = @W_ReferenceTableId)
                  AND [C].[Name] = ISNULL(@W_Name, [C].[Name])
                  AND (@W_IsAutoIncrement IS NULL OR [C].[IsAutoIncrement] = @W_IsAutoIncrement)
                  AND [C].[IsRequired] = ISNULL(@W_IsRequired, [C].[IsRequired])
                  AND (@W_IsListable IS NULL OR [C].[IsListable] = @W_IsListable)
                  AND (@W_IsFilterable IS NULL OR [C].[IsFilterable] = @W_IsFilterable)
                  AND (@W_IsEditable IS NULL OR [C].[IsEditable] = @W_IsEditable)
                  AND (@W_IsGridable IS NULL OR [C].[IsGridable] = @W_IsGridable)
                  AND (@W_IsEncrypted IS NULL OR [C].[IsEncrypted] = @W_IsEncrypted)
		UNION ALL
			SELECT [C].[Id]
					,[C].[TableId]
					,[C].[Sequence]
					,[C].[DomainId]
					,[C].[ReferenceTableId]
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
			FROM [dbo].[#tmpOperations] [C]
			WHERE [C].[_] = 'create'
					AND [C].[Id] = ISNULL(@W_Id, [C].[Id])
					AND [C].[TableId] = ISNULL(@W_TableId, [C].[TableId])
					AND [C].[DomainId] = ISNULL(@W_DomainId, [C].[DomainId])
					AND (@W_ReferenceTableId IS NULL OR [C].[ReferenceTableId] = @W_ReferenceTableId)
					AND [C].[Name] = ISNULL(@W_Name, [C].[Name])
					AND (@W_IsAutoIncrement IS NULL OR [C].[IsAutoIncrement] = @W_IsAutoIncrement)
					AND [C].[IsRequired] = ISNULL(@W_IsRequired, [C].[IsRequired])
					AND (@W_IsListable IS NULL OR [C].[IsListable] = @W_IsListable)
					AND (@W_IsFilterable IS NULL OR [C].[IsFilterable] = @W_IsFilterable)
					AND (@W_IsEditable IS NULL OR [C].[IsEditable] = @W_IsEditable)
					AND (@W_IsGridable IS NULL OR [C].[IsGridable] = @W_IsGridable)
					AND (@W_IsEncrypted IS NULL OR [C].[IsEncrypted] = @W_IsEncrypted)
		SET @RowCount = @@ROWCOUNT
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
            IF @PaddingGridLastPage = 1 AND @offset + @LimitRows > @RowCount
                SET @offset = CASE WHEN @RowCount > @LimitRows THEN @RowCount - @LimitRows ELSE 0 END
        END

        DECLARE @sql NVARCHAR(MAX)
                ,@className NVARCHAR(50) = 'RecordColumn'

        SELECT TOP 0 @className AS [ClassName], * INTO [dbo].[#view] FROM [dbo].[#tmp]
		SET @sql = 'INSERT INTO [dbo].[#view]
						SELECT ''RecordColumn'' AS [ClassName], *
							FROM [dbo].[#tmp]
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
								   AND (@W_IsGridable IS NULL OR [IsGridable] = @W_IsGridable)
								   AND (@W_IsEncrypted IS NULL OR [IsEncrypted] = @W_IsEncrypted)
							ORDER BY ' + @OrderBy + '
							OFFSET ' + CAST(@offset AS NVARCHAR(20)) + ' ROWS
							FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'
		EXEC sp_executesql @sql, N'@W_Id INT, @W_TableId INT, @W_DomainId INT, @W_ReferenceTableId INT, @W_Name NVARCHAR(25), 
								   @W_IsAutoIncrement BIT, @W_IsRequired BIT, @W_IsListable BIT, @W_IsFilterable BIT, 
								   @W_IsEditable BIT, @W_IsGridable BIT, @W_IsEncrypted BIT',
								   @W_Id, @W_TableId, @W_DomainId, @W_ReferenceTableId, @W_Name, @W_IsAutoIncrement, 
								   @W_IsRequired, @W_IsListable, @W_IsFilterable, @W_IsEditable, @W_IsGridable, @W_IsEncrypted
        SELECT * FROM [dbo].[#view]

        RETURN @RowCount
    END TRY
    BEGIN CATCH
        THROW
    END CATCH
END

