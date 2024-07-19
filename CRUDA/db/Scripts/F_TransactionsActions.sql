USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[F_TransactionsActions]', 'FN')) IS NOT NULL
	DROP FUNCTION [dbo].[F_TransactionsActions]
GO
CREATE FUNCTION [dbo].[F_TransactionsActions](@SystemName VARCHAR(25),
											@DatabaseName VARCHAR(25),
											@TableName VARCHAR(25),
											@Action VARCHAR(15))
RETURNS @result TABLE ([SystemId] BIGINT,
						[DatabaseId] BIGINT,
						[TableId] BIGINT,
						[UserId] BIGINT,
						[LoginId] BIGINT,
						[ProcedureCreate] VARCHAR(50),
						[ProcedureUpdate] VARCHAR(50),
						[ProcedureDelete] VARCHAR(50),
						[ProcedureRead] VARCHAR(50),
						[AlterTable] VARCHAR(MAX),
						[InsertTable] VARCHAR(MAX),
						[SelectTable] VARCHAR(MAX),
						[CommitTable] VARCHAR(MAX),
						[ErrorMessage] VARCHAR(255)) AS
BEGIN
	DECLARE @SystemId BIGINT,
			@DatabaseId BIGINT,
			@TableId BIGINT,
			@UserId BIGINT,
			@LoginId BIGINT,
			@ProcedureCreate VARCHAR(50),
			@ProcedureUpdate VARCHAR(50),
			@ProcedureDelete VARCHAR(50),
			@ProcedureRead VARCHAR(50),
			@AlterTable VARCHAR(MAX),
			@InsertTable VARCHAR(MAX),
			@SelectTable VARCHAR(MAX),
			@CommitTable VARCHAR(MAX),
			@FunctionName VARCHAR(255) = 'Function ' + (SELECT OBJECT_NAME(@@PROCID)) + ': ',
			@ErrorMessage VARCHAR(255)

	IF @Action IN ('create', 'update', 'delete', 'rollback', 'commit', 'read') BEGIN
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL
			SET @ErrorMessage = @FunctionName + 'Sistema ' + @SystemName + ' não encontrado.'
		ELSE BEGIN
			SELECT @DatabaseId = [D].[Id]
				FROM [dbo].[Databases] [D]
					INNER JOIN [dbo].[SystemsDatabases] [SD] ON [SD].[DatabaseId] = [D].[Id]
				WHERE [SD].[SystemId] = @SystemId
					  AND [D].[Name] = @DatabaseName
			IF @DatabaseId IS NULL
				SET @ErrorMessage = @FunctionName + 'Banco de dados ' + @DatabaseName + ' não encontrado.'
			ELSE BEGIN
				SELECT @TableId = [Id],
					   @ProcedureCreate = [ProcedureCreate],
					   @ProcedureUpdate = [ProcedureUpdate],
					   @ProcedureDelete = [ProcedureDelete],
					   @ProcedureRead = [ProcedureRead]
					FROM [dbo].[Tables]
					WHERE [Name] = @TableName
				IF @TableId IS NULL
					SET @ErrorMessage = @FunctionName + 'Tabela ' + @TableName + ' não encontrada.'
				ELSE IF NOT EXISTS(SELECT 1
										FROM [dbo].[DatabasesTables]
										WHERE [DatabaseId] = @DatabaseId
											  AND [TableId] = @TableId)
					SET @ErrorMessage = @FunctionName + 'Tabela ' + @TableName + 'não pertence ao banco-de-dados ' + @DatabaseName + '.'
				ELSE IF @Action = 'create' AND @ProcedureCreate IS NULL
					SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Create para a tabela ' + @TableName + '.';
				ELSE IF @Action = 'update' AND @ProcedureUpdate IS NULL
					SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Update para a tabela ' + @TableName + '.';
				ELSE IF @Action = 'delete' AND @ProcedureDelete IS NULL
					SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Delete para a tabela ' + @TableName + '.';
				ELSE IF @Action = 'read' BEGIN
					IF @ProcedureRead IS NULL
						SET @ErrorMessage = @FunctionName + 'Não foi definida procedure Read para a tabela ' + @TableName + '.';
					ELSE BEGIN
						SET @AlterTable = (SELECT 'ALTER TABLE [dbo].[#tmp] ADD [' + 
												[C].[Name] + '] ['  +
												[T].[Name] + ']' +
												CASE WHEN [D].[Length] IS NULL
													 THEN CASE WHEN [T].[Name] IN ('varchar', 'nvarchar', 'varbinary')
															   THEN '(MAX)'
															   ELSE ''
														  END
													 ELSE '(' + CAST([D].[Length] AS VARCHAR) +
														  CASE WHEN [D].[Decimals] IS NULL
															   THEN ''
															   ELSE ',' + CAST([D].[Decimals] AS VARCHAR)
														  END +
														  ')'
												END + ';'
											FROM [dbo].[Columns] [C]
												INNER JOIN [dbo].[Domains] [D] ON [D].[Id] = [C].[DomainId]
												INNER JOIN [dbo].[Types] [T] ON [T].[Id] = [D].[TypeId]
											WHERE [C].[TableId] = @TableId
											ORDER BY [C].[TableId],
													 [C].[Sequence]
											FOR XML PATH(''))

						SET @InsertTable = 'INSERT [dbo].[#tmp] SELECT 0' + 
											  (SELECT ',' + 'CAST(JSON_VALUE(Record, ''$.' + [Name] + '''' + ') AS VARCHAR(MAX))'
													FROM [dbo].[Columns]
													WHERE [TableId] = @TableId
													ORDER BY [TableId],
															 [Sequence]
													FOR XML PATH('')) + ' FROM [dbo].[Transactions]'

						SET @SelectTable = (SELECT ',' + [Name]
												FROM [dbo].[Columns]
												WHERE [TableId] = @TableId
												ORDER BY [TableId],
														 [Sequence]
												FOR XML PATH(''))
						SET @SelectTable = 'SELECT ' + RIGHT(@SelectTable, LEN(@SelectTable) - 1) + ' FROM [dbo].[#tmp]'
					END
				END
			END
		END
	END ELSE
		SET @ErrorMessage = @FunctionName + 'Valor ( ' + @Action + ') do parâmetro @Action é inválido.';
	INSERT @result VALUES(@SystemId,
							@DatabaseId,
							@TableId,
							@UserId,
							@LoginId,
							@ProcedureCreate,
							@ProcedureUpdate,
							@ProcedureDelete,
							@ProcedureRead,
							@AlterTable,
							@InsertTable,
							@SelectTable,
							@CommitTable,
							@ErrorMessage)
	RETURN
END
GO
