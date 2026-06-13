SET NOCOUNT ON;
DECLARE @rf NVARCHAR(MAX) = N'{"Fixed":{"TableId":14},"Filter":{"IsFilterable":true}}';
DECLARE @Login NVARCHAR(MAX) = N'{"LoginId":1}';
DECLARE @Page INT = 1, @Limit INT = 15, @Max INT, @Ret BIGINT;
BEGIN TRY
    EXEC dbo.ColumnsRead @Login, @rf, NULL, 1, 0, @Page OUT, @Limit OUT, @Max OUT, @Ret OUT;
    PRINT 'OK Rows=' + CAST(@Ret AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'ERR: ' + ERROR_MESSAGE();
END CATCH
GO

DECLARE @rf2 NVARCHAR(MAX) = N'{"Fixed":{"TableId":14},"Filter":{"IsFilterable":1}}';
DECLARE @Login2 NVARCHAR(MAX) = N'{"LoginId":1}';
DECLARE @Page2 INT = 1, @Limit2 INT = 15, @Max2 INT, @Ret2 BIGINT;
BEGIN TRY
    EXEC dbo.ColumnsRead @Login2, @rf2, NULL, 1, 0, @Page2 OUT, @Limit2 OUT, @Max2 OUT, @Ret2 OUT;
    PRINT 'OK with 1 Rows=' + CAST(@Ret2 AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'ERR2: ' + ERROR_MESSAGE();
END CATCH
GO

SELECT CAST(JSON_VALUE(N'{"IsFilterable":true}', '$.IsFilterable') AS bit) AS BitFromTrue;
GO
