SET NOCOUNT ON;
DECLARE @RecordFilter NVARCHAR(MAX) = N'{"Filter":{"DomainId":1,"IsRequired":true}}';
DECLARE @_ NVARCHAR(MAX) = (SELECT STRING_AGG(value, ',') FROM OPENJSON(@RecordFilter, '$.Filter._'))
       ,@WhereFixed NVARCHAR(MAX) = ''
       ,@WhereFilter NVARCHAR(MAX) = ''
       ,@WhereSearch NVARCHAR(MAX) = ''
       ,@WhereUser NVARCHAR(MAX) = ''
       ,@Where NVARCHAR(MAX) = ''
       ,@sql NVARCHAR(MAX);

DECLARE @W_U_DomainId bigint = CAST(JSON_VALUE(@RecordFilter, '$.Filter.DomainId') AS bigint)
       ,@W_U_IsRequired bit = CAST(JSON_VALUE(@RecordFilter, '$.Filter.IsRequired') AS bit);

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

PRINT '@Where=' + ISNULL(@Where, '(null)');
PRINT '@sql=' + @Where;
PRINT '---';
EXEC('BEGIN TRY EXEC sp_executesql N''SELECT 1''; PRINT ''sp_executesql ok''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH');
