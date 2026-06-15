USE [crudex]
GO
/****** Object:  StoredProcedure [dbo].[MasksRead]    Script Date: 20/04/2025 07:01:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @Page INT = 1, @Limit INT = 5, @Max INT, @Ret BIGINT;

--EXEC dbo.MasksRead1 
--    @SessionId = 1,
--    @RecordFilter = '{}',
--    @RecordSearch = NULL,
--    @OrderBy = '[Name] ASC',
--    @PaddingGridLastPage = 0,
--    @IsActionList = 0,
--    @PageNumber = @Page OUTPUT,
--    @LimitRows = @Limit OUTPUT,
--    @MaxPage = @Max OUTPUT,
--    @ReturnValue = @Ret OUTPUT;

EXEC dbo.MasksRead1 
    @SessionId = 1,
    @RecordFilter = '{"Name": "American Date"}',
    @RecordSearch = NULL,
    @OrderBy = '[Id] DESC',
    @PaddingGridLastPage = 0,
    @IsActionList = 0,
    @PageNumber = @Page OUTPUT,
    @LimitRows = @Limit OUTPUT,
    @MaxPage = @Max OUTPUT,
    @ReturnValue = @Ret OUTPUT;

--EXEC dbo.MasksRead1 
--    @SessionId = 1,
--    @RecordFilter = NULL,
--    @RecordSearch = '{"Id": 25}',
--    @OrderBy = '[Name]',
--    @PaddingGridLastPage = 1,
--    @IsActionList = 0,
--    @PageNumber = @Page OUTPUT,
--    @LimitRows = @Limit OUTPUT,
--    @MaxPage = @Max OUTPUT,
--    @ReturnValue = @Ret OUTPUT;
*/
ALTER PROCEDURE [dbo].[MasksRead](@SessionId BIGINT
                                          ,@RecordFilter NVARCHAR(MAX)
										  ,@RecordSearch NVARCHAR(MAX)
                                          ,@OrderBy NVARCHAR(MAX)
                                          ,@PaddingGridLastPage BIT
                                          ,@IsActionList BIT
                                          ,@PageNumber INT OUT
                                          ,@LimitRows INT OUT
                                          ,@MaxPage INT OUT
                                          ,@ReturnValue BIGINT OUT) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
        THROW 51000, 'Valor de @SessionId é requerido', 1
    IF @RecordFilter IS NULL
        SET @RecordFilter = '{}'
    ELSE IF ISJSON(@RecordFilter) = 0
        THROW 51000, 'Valor de @RecordFilter não está no formato JSON', 1
    SET @OrderBy = TRIM(ISNULL(@OrderBy, ''))
    IF @OrderBy = ''
        SET @OrderBy = '[T].[Id] ASC'
    ELSE BEGIN
        SET @OrderBy = REPLACE(REPLACE(@OrderBy, '[', ''), ']', '')
        IF EXISTS(SELECT 1 
                        FROM (SELECT CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)
                                        WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)
                                        ELSE TRIM([value])
                                    END AS [ColumnName]
                                FROM STRING_SPLIT(@OrderBy, ',')) AS [O]
                                    LEFT JOIN (SELECT [#1].[name] AS ColumnName
                                                FROM [sys].[columns] [#1]
                                                    INNER JOIN [sys].[tables] [#2] ON [#1].[object_id] = [#2].[object_id]
                                                WHERE [#2].[name] = 'Masks') AS [T] ON [T].[ColumnName] = [O].[ColumnName]
                        WHERE [T].[ColumnName] IS NULL)
            THROW 51000, 'Nome de coluna em @OrderBy é inválido', 1
        SELECT @OrderBy = STRING_AGG('[T].[' + TRIM(CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 4)
                                                        WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN LEFT(TRIM([value]), LEN(TRIM([value])) - 3)
                                                        ELSE TRIM([value])
                                                END) + '] ' + 
                                                CASE WHEN TRIM(RIGHT([value], 4)) = 'DESC' THEN 'DESC'
                                                        WHEN TRIM(RIGHT([value], 3)) = 'ASC' THEN 'ASC'
                                                        ELSE 'ASC'
                                                END, ', ')
            FROM STRING_SPLIT(@OrderBy, ',')
        IF CHARINDEX('[T].[Id]', @OrderBy) = 0
            SET @OrderBy = @OrderBy + ', [T].[Id] ASC'
    END

    DECLARE @TransactionId BIGINT = (SELECT MAX([Id]) FROM [dbo].[Transactions] WHERE [SessionId] = @SessionId)

    IF NOT EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [Id] = @TransactionId AND [IsConfirmed] IS NULL)
        SET @TransactionId = NULL
    SELECT [Action] AS [_]
            ,CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) AS [Id]
            ,CAST(JSON_VALUE([ActualRecord], '$.Name') AS nvarchar(25)) AS [Name]
            ,CAST(JSON_VALUE([ActualRecord], '$.Mask') AS nvarchar(max)) AS [Mask]
        INTO [#tmpOperations]
        FROM [dbo].[Operations]
        WHERE [TransactionId] = @TransactionId
                AND [TableName] = 'Masks'
                AND [IsConfirmed] IS NULL
    CREATE UNIQUE INDEX [#tmpOperations] ON [#tmpOperations]([Id])

    DECLARE @Where NVARCHAR(MAX) = ''
            ,@sql NVARCHAR(MAX)
            ,@W_Id bigint = CAST(JSON_VALUE(@RecordFilter, '$.Id') AS bigint)
            ,@W_Name nvarchar(25) = CAST(JSON_VALUE(@RecordFilter, '$.Name') AS nvarchar(25))

    IF @W_Id IS NOT NULL BEGIN
        SET @Where = @Where + ' AND [T].[Id] = @Id'
    END
    IF @W_Name IS NOT NULL BEGIN
        SET @Where = @Where + ' AND [T].[Name] = @Name'
    END

    CREATE TABLE [#tmpTable]([_] CHAR(1), [Recno] bigint, [Id] bigint)
    SET @sql = 'SELECT ''T'' AS [_]
                        ,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS Recno
                        ,[T].[Id]
                    FROM [dbo].[Masks] [T]
                        LEFT JOIN [#tmpOperations] [#] ON [#].[Id] = [T].[Id]
                    WHERE [#].[Id] IS NULL' + @Where + '
                UNION ALL
                SELECT ''O'' AS [_]
                        ,ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') + (SELECT COUNT(*) FROM [#tmpTable] [#] WHERE [#].[_] = ''T'')
                        ,[T].[Id]
                    FROM [#tmpOperations] [T]
                    WHERE [T].[_] <> ''delete''' + @Where
    SET @sql = 'INSERT [#tmpTable]([_], [Recno], [Id])
                    SELECT [_]
                            ,[Recno]
                            ,[Id]
                        FROM (' + @sql + ') AS T
                    ORDER BY [Recno]' + ';'
    EXEC sp_executesql @sql
                        ,N'@Id bigint
                        ,@Name nvarchar(25)'
                        ,@Id = @W_Id
                        ,@Name = @W_Name
    DECLARE @RowCount INT = @@ROWCOUNT
            ,@OffSet INT

    CREATE UNIQUE INDEX [#tmpTable] ON [#tmpTable]([Id])
    IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
        SET @OffSet = 0
        SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END
        SET @PageNumber = 1
        SET @MaxPage = 1
    END ELSE BEGIN
        SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END
        IF @RecordSearch IS NOT NULL BEGIN
            DECLARE @Recno  BIGINT,
                    @S_Id   BIGINT = CAST(JSON_VALUE(@RecordSearch, '$.Id') AS BIGINT),
                    @S_Name NVARCHAR(25) = CAST(JSON_VALUE(@RecordSearch, '$.Name') AS NVARCHAR(25))

            SET @Where = ''
            IF @S_Id IS NOT NULL
                SET @Where += CASE WHEN @Where = '' THEN '' ELSE ' AND ' END + '[T].[Id] = @Id';
            IF @S_Name IS NOT NULL
                SET @Where += CASE WHEN @Where = '' THEN '' ELSE ' AND ' END + '[T].[Name] = @Name';
            IF @Where <> '' BEGIN
                SET @sql = N'SELECT TOP 1 @r = [Recno]
                                FROM [#tmpTable] AS [T]
                                WHERE ' + @Where + ';';
                EXEC sp_executesql @sql,
                                    N'@Id BIGINT, @Name NVARCHAR(25), @r BIGINT OUTPUT',
                                    @Id = @S_Id,
                                    @Name = @S_Name,
                                    @r = @Recno OUTPUT;
                SET @PageNumber = CASE WHEN ISNULL(@Recno, 0) > 0 THEN ((@Recno - 1) / @LimitRows) + 1 ELSE @MaxPage END;
            END
        END
        IF ABS(@PageNumber) > @MaxPage
            SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
        ELSE IF @PageNumber < 0
            SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
        SET @OffSet = (@PageNumber - 1) * @LimitRows
        IF @PaddingGridLastPage = 1 AND @OffSet + @LimitRows > @RowCount
            SET @OffSet = CASE WHEN @RowCount > @LimitRows THEN @RowCount - @LimitRows ELSE 0 END
    END
    SELECT TOP 0 CAST(NULL AS NVARCHAR(50)) AS [Kind]
                ,CAST(NULL AS bigint) AS [Recno]
                ,CAST(NULL AS bigint) AS [Id]
                ,CAST(NULL AS nvarchar(25)) AS [Name]
                ,CAST(NULL AS nvarchar(max)) AS [Mask]
        INTO [#result]
    SET @sql = 'INSERT [#result]
                    SELECT ''Mask'' AS [Kind]
                            ,[#].[Recno]
                            ,[T].[Id]
                            ,[T].[Name]
                            ,[T].[Mask]
                        FROM [#tmpTable] [#]
                            INNER JOIN [dbo].[Masks] [T] ON [T].[Id] = [#].[Id]
                        WHERE [#].[_] = ''T''
                    UNION ALL
                        SELECT ''Mask'' AS [Kind]
                                ,[#].[Recno]
                                ,[O].[Id]
                                ,[O].[Name]
                                ,[O].[Mask]
                            FROM [#tmpTable] [#]
                                INNER JOIN [#tmpOperations] [O] ON [O].[Id] = [#].[Id]
                            WHERE [#].[_] = ''O''
                    ORDER BY [Recno]
                    OFFSET ' + CAST(@OffSet AS NVARCHAR(20)) + ' ROWS
                    FETCH NEXT ' + CAST(@LimitRows AS NVARCHAR(20)) + ' ROWS ONLY'
    EXEC sp_executesql @sql
    SELECT [Kind]
            ,[Id]
            ,[Name]
            ,[Mask]
        FROM [#result]
    SET @ReturnValue = @RowCount

    RETURN 0
END
