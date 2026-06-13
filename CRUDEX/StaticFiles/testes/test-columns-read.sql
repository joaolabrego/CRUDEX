SET NOCOUNT ON;
DECLARE @rf NVARCHAR(MAX) = N'{"Filter":{"DomainId":1,"IsRequired":true}}';
DECLARE @Login NVARCHAR(MAX) = N'{"LoginId":1}';
DECLARE @Page INT = 1, @Limit INT = 35, @Max INT, @Ret BIGINT;
BEGIN TRY
    EXEC dbo.ColumnsRead @Login, @rf, NULL, 1, 0, @Page OUT, @Limit OUT, @Max OUT, @Ret OUT;
    PRINT 'OK Rows=' + CAST(@Ret AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH
