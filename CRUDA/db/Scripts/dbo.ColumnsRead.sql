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
        IF @LoginId IS NULL
            THROW 51000, 'Valor de @LoginId é requerido', 1
        IF @RecordFilter IS NULL
            THROW 51000, 'Valor de @RecordFilter é requerido', 1
        IF ISJSON(@RecordFilter) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
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
							FOR XML PATH(''), TYPE).[value]('.', 'VARCHAR(MAX)'), 1, 2, '')) = 0)
				THROW 51000, 'Nome de coluna em @OrderBy é inválido', 1
			SELECT @OrderBy = STRING_AGG('[' + TRIM(value) + ']', ', ') FROM STRING_SPLIT(@OrderBy, ',')
		END

        DECLARE @TransactionId INT = (SELECT MAX([Id]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
                ,@W_Id int = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.Id') AS int)
                ,@W_TableId int = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.TableId') AS int)
                ,@W_DomainId int = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.DomainId') AS int)
                ,@W_ReferenceTableId int = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.ReferenceTableId') AS int)
                ,@W_Name nvarchar(25) = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.Name') AS nvarchar(25))
                ,@W_IsAutoIncrement bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsAutoIncrement') AS bit)
                ,@W_IsRequired bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsRequired') AS bit)
                ,@W_IsListable bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsListable') AS bit)
                ,@W_IsFilterable bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsFilterable') AS bit)
                ,@W_IsEditable bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsEditable') AS bit)
                ,@W_IsGridable bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsGridable') AS bit)
                ,@W_IsEncrypted bit = CAST([cruda].[JSON_EXTRACT](@RecordFilter, '$.IsEncrypted') AS bit)

		IF @W_Id IS NOT NULL BEGIN
			IF @W_Id < CAST('1' AS bigint)
				THROW 51000, 'Valor de @Id deve ser maior que ou igual à ''1''.', 1
			IF @W_Id > CAST('9007199254740990' AS bigint)
				THROW 51000, 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.', 1
		END
		IF @W_TableId IS NOT NULL BEGIN
			IF @W_TableId < CAST('1' AS bigint)
				THROW 51000, 'Valor de @TableId deve ser maior que ou igual à ''1''.', 1
			IF @W_TableId > CAST('9007199254740990' AS bigint)
				THROW 51000, 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.', 1
		END
		IF @W_DomainId IS NOT NULL BEGIN
			IF @W_DomainId < CAST('1' AS bigint)
				THROW 51000, 'Valor de @DomainId deve ser maior que ou igual à ''1''.', 1
			IF @W_DomainId > CAST('9007199254740990' AS bigint)
				THROW 51000, 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.', 1
		END
		IF @W_ReferenceTableId IS NOT NULL BEGIN
			IF @W_ReferenceTableId < CAST('1' AS bigint)
				THROW 51000, 'Valor de @ReferenceTableId deve ser maior que ou igual à ''1''.', 1
			IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint)
				THROW 51000, 'Valor de @ReferenceTableId deve ser menor que ou igual à ''9007199254740990''.', 1
		END
        SELECT CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Id') AS int) AS [Id]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.TableId') AS int) AS [TableId]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Sequence') AS smallint) AS [Sequence]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.DomainId') AS int) AS [DomainId]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.ReferenceTableId') AS int) AS [ReferenceTableId]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Name') AS nvarchar(25)) AS [Name]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Description') AS nvarchar(50)) AS [Description]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Title') AS nvarchar(25)) AS [Title]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Caption') AS nvarchar(25)) AS [Caption]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.ValidValues') AS nvarchar(MAX)) AS [ValidValues]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Default') AS nvarchar(MAX)) AS [Default]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Minimum') AS nvarchar(MAX)) AS [Minimum]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Maximum') AS nvarchar(MAX)) AS [Maximum]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsPrimarykey') AS bit) AS [IsPrimarykey]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsAutoIncrement') AS bit) AS [IsAutoIncrement]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsRequired') AS bit) AS [IsRequired]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsListable') AS bit) AS [IsListable]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsFilterable') AS bit) AS [IsFilterable]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsEditable') AS bit) AS [IsEditable]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsGridable') AS bit) AS [IsGridable]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.IsEncrypted') AS bit) AS [IsEncrypted]
			  ,[Action] AS [_]
		   INTO [dbo].[#tmpOperations]
           FROM [cruda].[Operations]
           WHERE [TransactionId] = @TransactionId
                 AND [TableName] = 'Columns'
                 AND [IsConfirmed] IS NULL
		CREATE UNIQUE INDEX [#unqOperations] ON [dbo].[#tmpOperations]([Id])
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
            INTO [dbo].[#tmp]
            FROM [dbo].[Columns] [C]
				LEFT JOIN [dbo].[#tmpOperations] [D] ON [D].[Id] = [C].[Id] AND [D].[_] <> 'create'
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
			WHERE [C].[_] = 'update'
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

        DECLARE @RowCount INT = @@ROWCOUNT
               ,@OffSet INT

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
							ORDER BY ' + @OrderBy + '
							OFFSET ' + CAST(@offset AS NVARCHAR(20)) + ' ROWS
							FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'
		EXEC(@sql)
        SELECT * FROM [dbo].[#view]

        RETURN @RowCount
    END TRY
    BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(MAX)

		SET @ErrorMessage = 'Stored Procedure [' + ERROR_PROCEDURE() + '] Error: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
		THROW 51000, @ErrorMessage, 1;
    END CATCH
END

