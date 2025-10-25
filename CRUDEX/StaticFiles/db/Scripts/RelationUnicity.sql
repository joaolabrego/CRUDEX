USE crudex
GO
DECLARE @IndexName VARCHAR(25) = 'UNQ_Users_Name',
		@TableId BIGINT = 7

BEGIN TRANSACTION

SELECT [DT].[DatabaseId]
	INTO #tmpDatabases
	FROM [dbo].[Indexes] [I]
		INNER JOIN [dbo].[DatabasesTables] [DT] ON [DT].[TableId] = [I].[TableId]
	WHERE [I].[TableId] = @TableId

SELECT [I].[Name]
	FROM [#tmpDatabases] [D]
		INNER JOIN [dbo].[DatabasesTables] [DT] ON [DT].[DatabaseId] = [D].[DatabaseId]
		INNER JOIN [dbo].[Indexes] [I] ON [I].[TableId] = [DT].[TableId]
	WHERE [I].[Name] = @IndexName

ROLLBACK
