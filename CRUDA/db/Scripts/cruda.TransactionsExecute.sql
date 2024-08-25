USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[TransactionsExecute]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[TransactionsExecute] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TransactionsExecute](
	@SystemName VARCHAR(25),
	@DatabaseName VARCHAR(25),
	@TableName VARCHAR(25),
	@Action VARCHAR(15),
	@Record VARCHAR(MAX) = NULL) AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	DECLARE @SystemId BIGINT,
			@DatabaseId BIGINT,
			@TableId BIGINT,
			@UserId BIGINT,
			@LoginId BIGINT,
			@TransactionId BIGINT,
			@TransactionAction VARCHAR(15),
			@PrimarykeyId BIGINT,
			@PrimarykeyName VARCHAR(25),
			@ProcedureCreate VARCHAR(50),
			@ProcedureUpdate VARCHAR(50),
			@ProcedureDelete VARCHAR(50),
			@ProcedureRead VARCHAR(50),
			@AlterTable VARCHAR(MAX),
			@InsertTable VARCHAR(MAX),
			@SelectTable VARCHAR(MAX),
			@CommitTable VARCHAR(MAX),
			@ErrorMessage VARCHAR(255) = 'Stored Procedure TransactionsExecute: '

	BEGIN TRANSACTION
	BEGIN TRY
		IF ISJSON(@Record) = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Registro não está no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END

		SELECT @SystemId = [SystemId],
				@DatabaseId = [DatabaseId],
				@TableId = [TableId],
				@UserId = [UserId],
				@LoginId = [LoginId],
				@ProcedureCreate = [ProcedureCreate],
				@ProcedureUpdate = [ProcedureUpdate],
				@ProcedureDelete = [ProcedureDelete],
				@ProcedureRead = [ProcedureRead],
				@AlterTable = [AlterTable],
				@InsertTable = [InsertTable],
				@SelectTable = [SelectTable],
				@CommitTable = [CommitTable],
				@ErrorMessage = [ErrorMessage]
			FROM [dbo].[TransactionsActions](@SystemName, @DatabaseName, @TableName, @Action)
		IF @ErrorMessage IS NOT NULL
			THROW 51000, @ErrorMessage, 1

		IF @Action = 'read' BEGIN
			CREATE TABLE [dbo].[#tmp](_ BIT)
			EXEC(@AlterTable)
			EXEC(@InsertTable)
			EXEC(@SelectTable)
		END	IF @Action = 'rollback' BEGIN
			UPDATE [dbo].[Transactions]
				SET [IsConfirmed] = 0
				WHERE [LoginId] = @LoginId
						AND [IsConfirmed] IS NULL
		END ELSE BEGIN
			SELECT @PrimarykeyName = [C].[Name]
				FROM [dbo].[Columns] [C]
				WHERE [C].[TableId] = @TableId
						AND [C].[IsPrimarykey] = 1
			IF @PrimarykeyName IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Tabela ' + @TableName + ' não possui chave-primária.';
				THROW 51000, @ErrorMessage, 1
			END

			SET @PrimarykeyId = JSON_VALUE(@Record, '$.' + @PrimarykeyName)
			SELECT @TransactionId = [Id],
					@TransactionAction = [Action]
				FROM [dbo].[Transactions]
				WHERE [LoginId] = @LoginId
						AND [TableId] = @TableId
						AND [PrimarykeyId] = @PrimarykeyId
						AND [IsConfirmed] IS NULL

			IF @TransactionId IS NULL BEGIN
				EXEC @TransactionId = [dbo].[GenerateId] 'cruda', 'cruda', 'Transactions'
				INSERT [dbo].[Transactions]([Id],
											[LoginId],
											[TableId],
											[PrimarykeyId],
											[Action],
											[Record],
											[IsConfirmed],
											[CreatedAt],
											[CreatedBy],
											[UpdatedAt],
											[UpdatedBy])
									VALUES (@TransactionId, 
											@LoginId,
											@TableId,
											@PrimarykeyId,
											@Action,
											@Record,
											NULL,
											GETDATE(),
											@UserName,
											NULL,
											NULL)
			END ELSE IF @TransactionAction = 'delete' BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Registro já excluído da tabela ' + @TableName + '.';
				THROW 51000, @ErrorMessage, 1
			END ELSE IF @Action = 'create' BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Registro já existente na tabela ' + @TableName + '.';
				THROW 51000, @ErrorMessage, 1
			END ELSE IF @Action = 'update' BEGIN
				UPDATE [dbo].[Transactions]
					SET [Record] = @Record,
						[UpdatedAt] = GETDATE(),
						[UpdatedBy] = @UserName
					WHERE [Id] = @TransactionId
			END ELSE IF @Action = 'delete' BEGIN
				UPDATE [dbo].[Transactions]
					SET [Action] = CASE WHEN @TransactionAction = 'create' THEN [Action] ELSE @Action END,
						[IsConfirmed] = CASE WHEN @TransactionAction = 'create' THEN 0 ELSE [IsConfirmed] END,
						[UpdatedAt] = GETDATE(),
						[UpdatedBy] = @UserName
					WHERE [Id] = @TransactionId 
			END

			RETURN @TransactionId
		END

		COMMIT TRANSACTION
		RETURN @@ROWCOUNT;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		THROW
	END CATCH
END
GO
