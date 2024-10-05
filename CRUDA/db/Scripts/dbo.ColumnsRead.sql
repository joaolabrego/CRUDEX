ALTER PROCEDURE[dbo].[ColumnsRead](@LoginId INT
                                          ,@RecordFilter NVARCHAR(MAX)
                                          ,@OrderBy NVARCHAR(MAX)
                                          ,@PaddingGridLastPage BIT
                                          ,@PageNumber INT OUT
                                          ,@LimitRows INT OUT
                                          ,@MaxPage INT OUT) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED
        IF @LoginId IS NULL
            THROW 51000, 'Valor de @LoginId é requerido', 1
        IF @RecordFilter IS NULL
            THROW 51000, 'Valor de @RecordFilter é requerido', 1
        IF ISJSON(@RecordFilter) = 0
            THROW 51000, 'Valor de @RecordFilter não está no formato JSON', 1
        SET @OrderBy = TRIM(ISNULL(@OrderBy, ''))
        IF @OrderBy = ''
            SET @OrderBy = '[Id]'
        ELSE BEGIN
            SET @OrderBy = REPLACE(REPLACE(@OrderBy, '[', ''), ']', '')
            IF EXISTS(SELECT 1 
                         FROM (SELECT CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)
                                           WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)
                                           ELSE TRIM([value])
                                      END AS [ColumnName]
                                  FROM STRING_SPLIT(@OrderBy, ',')) AS [O]
                                      LEFT JOIN (SELECT [COLUMN_NAME] AS [ColumnName]
                                                    FROM [INFORMATION_SCHEMA].[COLUMNS]
                                                    WHERE [TABLE_NAME] = 'Columns') AS [T] ON [T].[ColumnName] = [O].[ColumnName]
                         WHERE [T].[ColumnName] IS NULL)
                THROW 51000, 'Nome de coluna em @OrderBy é inválido', 1
            SELECT @OrderBy = STRING_AGG('[' + TRIM(CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)
                                                         WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)
                                                         ELSE TRIM([value])
                                                    END) + '] ' + 
                                                    CASE WHEN LTRIM(RTRIM(RIGHT([value], 4))) = 'DESC' THEN 'DESC'
                                                         WHEN LTRIM(RTRIM(RIGHT([value], 3))) = 'ASC' THEN 'ASC'
                                                         ELSE 'ASC'
                                                    END, ', ')
                FROM STRING_SPLIT(@OrderBy, ',')
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

        IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS int)
            THROW 51000, 'Valor de Id deve ser maior que ou igual à ''1''', 1
        IF @W_Id IS NOT NULL AND @W_Id > CAST('2147483647' AS int)
            THROW 51000, 'Valor de Id deve ser menor que ou igual à ''2147483647''', 1
        IF @W_TableId IS NOT NULL AND @W_TableId < CAST('1' AS int)
            THROW 51000, 'Valor de TableId deve ser maior que ou igual à ''1''', 1
        IF @W_TableId IS NOT NULL AND @W_TableId > CAST('2147483647' AS int)
            THROW 51000, 'Valor de TableId deve ser menor que ou igual à ''2147483647''', 1
        IF @W_DomainId IS NOT NULL AND @W_DomainId < CAST('1' AS int)
            THROW 51000, 'Valor de DomainId deve ser maior que ou igual à ''1''', 1
        IF @W_DomainId IS NOT NULL AND @W_DomainId > CAST('2147483647' AS int)
            THROW 51000, 'Valor de DomainId deve ser menor que ou igual à ''2147483647''', 1
        IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS int)
            THROW 51000, 'Valor de ReferenceTableId deve ser maior que ou igual à ''1''', 1
        IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId > CAST('2147483647' AS int)
            THROW 51000, 'Valor de ReferenceTableId deve ser menor que ou igual à ''2147483647''', 1
        SELECT [Action] AS [_]
              ,CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Id') AS int) AS [Id]
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
            INTO [dbo].[#operations]
            FROM [cruda].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Columns'
                  AND [IsConfirmed] IS NULL
        CREATE UNIQUE INDEX [#unqOperations] ON [dbo].[#operations]([Id])
        SELECT CAST('T' AS CHAR(1)) AS [_]
              ,[T].[Id]
            INTO [dbo].[#table]
            FROM [dbo].[Columns] [T]
                LEFT JOIN [dbo].[#operations] [#] ON [#].[Id] = [T].[Id]
            WHERE [#].[Id] IS NULL
				  AND [T].[Id] = ISNULL(@W_Id, [T].[Id])
                  AND [T].[TableId] = ISNULL(@W_TableId, [T].[TableId])
                  AND [T].[DomainId] = ISNULL(@W_DomainId, [T].[DomainId])
                  AND (@W_ReferenceTableId IS NULL OR [T].[ReferenceTableId] = @W_ReferenceTableId)
                  AND [T].[Name] = ISNULL(@W_Name, [T].[Name])
                  AND (@W_IsAutoIncrement IS NULL OR [T].[IsAutoIncrement] = @W_IsAutoIncrement)
                  AND [T].[IsRequired] = ISNULL(@W_IsRequired, [T].[IsRequired])
                  AND (@W_IsListable IS NULL OR [T].[IsListable] = @W_IsListable)
                  AND (@W_IsFilterable IS NULL OR [T].[IsFilterable] = @W_IsFilterable)
                  AND (@W_IsEditable IS NULL OR [T].[IsEditable] = @W_IsEditable)
                  AND (@W_IsGridable IS NULL OR [T].[IsGridable] = @W_IsGridable)
                  AND (@W_IsEncrypted IS NULL OR [T].[IsEncrypted] = @W_IsEncrypted)
        UNION ALL
            SELECT CAST('O' AS CHAR(1)) AS [_]
                  ,[O].[Id]
                FROM [dbo].[#operations] [O]
                WHERE [_] <> 'delete'
                      AND [O].[Id] = ISNULL(@W_Id, [O].[Id])
                      AND [O].[TableId] = ISNULL(@W_TableId, [O].[TableId])
                      AND [O].[DomainId] = ISNULL(@W_DomainId, [O].[DomainId])
                      AND (@W_ReferenceTableId IS NULL OR [O].[ReferenceTableId] = @W_ReferenceTableId)
                      AND [O].[Name] = ISNULL(@W_Name, [O].[Name])
                      AND (@W_IsAutoIncrement IS NULL OR [O].[IsAutoIncrement] = @W_IsAutoIncrement)
                      AND [O].[IsRequired] = ISNULL(@W_IsRequired, [O].[IsRequired])
                      AND (@W_IsListable IS NULL OR [O].[IsListable] = @W_IsListable)
                      AND (@W_IsFilterable IS NULL OR [O].[IsFilterable] = @W_IsFilterable)
                      AND (@W_IsEditable IS NULL OR [O].[IsEditable] = @W_IsEditable)
                      AND (@W_IsGridable IS NULL OR [O].[IsGridable] = @W_IsGridable)
                      AND (@W_IsEncrypted IS NULL OR [O].[IsEncrypted] = @W_IsEncrypted)

        DECLARE @RowCount INT = @@ROWCOUNT
               ,@OffSet INT
               ,@sql NVARCHAR(MAX)
               ,@ClassName NVARCHAR(50) = 'RecordColumn'

		CREATE UNIQUE INDEX [#unqTable] ON [dbo].[#table]([Id])
        IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
            SET @OffSet = 0
            SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END
            SET @PageNumber = 1
            SET @MaxPage = 1
        END ELSE BEGIN
            SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END
            IF ABS(@PageNumber) > @MaxPage
                SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
            IF @PageNumber < 0
                SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
            SET @OffSet = (@PageNumber - 1) * @LimitRows
            IF @PaddingGridLastPage = 1 AND @OffSet + @LimitRows > @RowCount
                SET @OffSet = CASE WHEN @RowCount > @LimitRows THEN @RowCount - @LimitRows ELSE 0 END
        END
        SET @sql = 'SELECT @ClassName AS [ClassName]
						  ,[T].[Id]
						  ,[T].[TableId]
 						  ,[T].[Sequence]
						  ,[T].[DomainId]
						  ,[T].[ReferenceTableId]
						  ,[T].[Name]
						  ,[T].[Description]
						  ,[T].[Title]
						  ,[T].[Caption]
						  ,[T].[ValidValues]
						  ,[T].[Default]
						  ,[T].[Minimum]
						  ,[T].[Maximum]
						  ,[T].[IsPrimarykey]
						  ,[T].[IsAutoIncrement]
						  ,[T].[IsRequired]
						  ,[T].[IsListable]
						  ,[T].[IsFilterable]
						  ,[T].[IsEditable]
						  ,[T].[IsGridable]
						  ,[T].[IsEncrypted]
					   FROM [dbo].[#table] [#]
						   INNER JOIN [dbo].[Columns] [T] ON [T].[Id] = [#].[Id]
						WHERE [#].[_] = ''T''
				    UNION ALL
						SELECT @ClassName AS [ClassName]
							  ,[O].[Id]
							  ,[O].[TableId]
							  ,[O].[Sequence]
							  ,[O].[DomainId]
							  ,[O].[ReferenceTableId]
							  ,[O].[Name]
							  ,[O].[Description]
							  ,[O].[Title]
							  ,[O].[Caption]
							  ,[O].[ValidValues]
							  ,[O].[Default]
							  ,[O].[Minimum]
							  ,[O].[Maximum]
							  ,[O].[IsPrimarykey]
							  ,[O].[IsAutoIncrement]
							  ,[O].[IsRequired]
							  ,[O].[IsListable]
							  ,[O].[IsFilterable]
							  ,[O].[IsEditable]
							  ,[O].[IsGridable]
							  ,[O].[IsEncrypted]
						   FROM [dbo].[#table] [#]
							   INNER JOIN [dbo].[#operations] [O] ON [O].[Id] = [#].[Id]
						   WHERE [#].[_] = ''O''
                    ORDER BY ' + @OrderBy + '
                    OFFSET ' + CAST(@OffSet AS NVARCHAR(20)) + ' ROWS
                    FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'
		EXEC sp_executesql @sql, 
						   N'@ClassName NVARCHAR(50), @OffSet INT, @LimitRows INT',
						   @ClassName = @ClassName, @OffSet = @OffSet, @LimitRows = @LimitRows

        RETURN @RowCount
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
    END CATCH
END
