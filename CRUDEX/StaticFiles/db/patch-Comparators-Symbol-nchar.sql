-- Comparators.Symbol: char(1) corrompe Unicode; ALTER para nchar(1) NAO corrige linhas ja gravadas.
-- Usar NCHAR(codepoint) evita problemas de encoding do sqlcmd com literais Unicode no ficheiro.

IF COL_LENGTH('[dbo].[Comparators]', 'Symbol') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
         FROM sys.columns c
         JOIN sys.types t ON c.user_type_id = t.user_type_id
        WHERE c.object_id = OBJECT_ID('[dbo].[Comparators]')
          AND c.name = 'Symbol'
          AND t.name = N'nchar')
BEGIN
    ALTER TABLE [dbo].[Comparators] ALTER COLUMN [Symbol] nchar(1) NOT NULL;
END
GO

UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(60) AS nchar(1)) WHERE [Id] = 1;   -- <
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8804) AS nchar(1)) WHERE [Id] = 2; -- <=
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(61) AS nchar(1)) WHERE [Id] = 3;   -- =
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8800) AS nchar(1)) WHERE [Id] = 4; -- <>
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8805) AS nchar(1)) WHERE [Id] = 5; -- >=
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(62) AS nchar(1)) WHERE [Id] = 6;   -- >
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8712) AS nchar(1)) WHERE [Id] = 7; -- IN
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8713) AS nchar(1)) WHERE [Id] = 8; -- NOT IN
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8835) AS nchar(1)) WHERE [Id] = 9; -- LIKE
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8837) AS nchar(1)) WHERE [Id] = 10; -- NOT LIKE
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8707) AS nchar(1)) WHERE [Id] = 11; -- BETWEEN
UPDATE [dbo].[Comparators] SET [Symbol] = CAST(NCHAR(8708) AS nchar(1)) WHERE [Id] = 12; -- NOT BETWEEN
GO

SELECT [Id], [Symbol], [Description], UNICODE([Symbol]) AS [CodePoint]
  FROM [dbo].[Comparators]
 ORDER BY [Id];
GO
