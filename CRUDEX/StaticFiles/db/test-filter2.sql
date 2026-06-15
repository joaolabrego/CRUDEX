SET NOCOUNT ON;
DECLARE @Login NVARCHAR(MAX) = N'{"LoginId":1,"UserName":"crudex","SystemName":"crudex","Action":"authenticate"}';
DECLARE @Page INT = 1, @Limit INT = 35, @MaxPage INT = 0, @Ret BIGINT = 0;

EXEC dbo.ColumnsRead @Login, N'{}', NULL, NULL, N'Id ASC', 0, 0, @Page OUT, @Limit OUT, @MaxPage OUT, @Ret OUT;
SELECT 'all' AS test, @Ret AS Cnt, @MaxPage AS MaxPage;

SET @Page = 5; SET @Ret = 0; SET @MaxPage = 0;
EXEC dbo.ColumnsRead @Login, N'{"DomainId":{"op":3,"value":1}}', NULL, NULL, N'Id ASC', 0, 0, @Page OUT, @Limit OUT, @MaxPage OUT, @Ret OUT;
SELECT 'filtered page 5' AS test, @Ret AS Cnt, @Page AS PageOut, @MaxPage AS MaxPage;

SET @Page = 1; SET @Ret = 0; SET @MaxPage = 0;
EXEC dbo.ColumnsRead @Login, N'{"DomainId":{"op":3,"value":1}}', NULL, NULL, N'Id ASC', 0, 0, @Page OUT, @Limit OUT, @MaxPage OUT, @Ret OUT;
SELECT 'filtered page 1' AS test, @Ret AS Cnt, @Page AS PageOut, @MaxPage AS MaxPage;

SET @Page = 1; SET @Ret = 0; SET @MaxPage = 0;
EXEC dbo.ColumnsRead @Login, N'{"DomainId":{"op":3}}', NULL, NULL, N'Id ASC', 0, 0, @Page OUT, @Limit OUT, @MaxPage OUT, @Ret OUT;
SELECT 'op only no value' AS test, @Ret AS Cnt, @Page AS PageOut, @MaxPage AS MaxPage;
