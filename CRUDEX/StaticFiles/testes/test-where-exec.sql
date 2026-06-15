SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#tmpOperations') IS NOT NULL DROP TABLE #tmpOperations;
IF OBJECT_ID('tempdb..#tmpTable') IS NOT NULL DROP TABLE #tmpTable;

CREATE TABLE #tmpOperations([_] CHAR(1), [Id] BIGINT, [DomainId] BIGINT, [IsRequired] BIT);

DECLARE @RecordFilterGrid NVARCHAR(MAX) = N'{"Filter":{"DomainId":1,"IsRequired":true}}';
DECLARE @_ NVARCHAR(MAX) = (SELECT STRING_AGG(value, ',') FROM OPENJSON(@RecordFilterGrid, '$.Filter._'))
       ,@WhereFixed NVARCHAR(MAX) = ''
       ,@WhereFilter NVARCHAR(MAX) = ''
       ,@WhereSearch NVARCHAR(MAX) = ''
       ,@WhereUser NVARCHAR(MAX) = ''
       ,@Where NVARCHAR(MAX) = ''
       ,@sql NVARCHAR(MAX);

DECLARE @W_U_DomainId bigint = CAST(JSON_VALUE(@RecordFilterGrid, '$.Filter.DomainId') AS bigint)
       ,@W_U_IsRequired bit = CAST(JSON_VALUE(@RecordFilterGrid, '$.Filter.IsRequired') AS bit);

IF @W_U_DomainId IS NOT NULL
    SET @WhereFilter = @WhereFilter + ' AND [T].[DomainId] = @U_DomainId';
IF @W_U_IsRequired IS NOT NULL
    SET @WhereFilter = @WhereFilter + ' AND [T].[IsRequired] = @U_IsRequired';

IF @WhereFilter <> ''
    SET @WhereUser = STUFF(@WhereFilter, 1, 5, '');

SET @Where = @WhereFixed;
IF @WhereUser <> ''
    SET @Where = @Where + ' AND (' + @WhereUser + ')';

SET @sql = 'INSERT [#tmpTable]
                SELECT ''T'' AS [_]
                      ,[T].[Id]
                    FROM [dbo].[Columns] [T]
                        LEFT JOIN [#tmpOperations] [#] ON [#].[Id] = [T].[Id]
                    WHERE [#].[Id] IS NULL' + @Where + '
                UNION ALL
                    SELECT ''O'' AS [_]
                          ,[T].[Id]
                        FROM [#tmpOperations] [T]
                        WHERE [T].[_] <> ''delete''' + @Where;

CREATE TABLE [#tmpTable]([_] CHAR(1), [Id] BIGINT);

BEGIN TRY
    EXEC sp_executesql @sql
        ,N'@U_DomainId bigint,@U_IsRequired bit'
        ,@U_DomainId = @W_U_DomainId
        ,@U_IsRequired = @W_U_IsRequired;
    PRINT 'OK rows=' + CAST(@@ROWCOUNT AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    PRINT '@Where=' + @Where;
END CATCH
