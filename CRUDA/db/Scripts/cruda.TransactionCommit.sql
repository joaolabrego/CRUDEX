USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[TransactionCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionCommit] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionCommit](@TransactionId BIGINT
										   ,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionCommit]: '
				,@LoginId BIGINT
				,@OperationId BIGINT
				,@TableName VARCHAR(25)

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionsCommit]
		ELSE
			SAVE TRANSACTION [TransactionsCommit]
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @TransactionId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @LoginId = [LoginId]
			FROM [cruda].[Transactions]
			WHERE [TransactionId] = @TransactionId
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @TransactionId é inválido';
			THROW 51000, @ErrorMessage, 1
		END
		WHILE 1 = 1 BEGIN
			SELECT @OperationId = [OperationId]
					,@TableName = [TableName]
				FROM [cruda].[Operations]
				WHERE [TransactionId] = @TransactionId
						AND [IsConfirmed] IS NULL
			IF @OperationId IS NULL
				BREAK
			
			DECLARE @sql VARCHAR(MAX) = '[dbo].[' + @TableName + 'Ratify] @LoginId = ' + CAST(@LoginId AS VARCHAR) + ', @UserName = ''' + @UserName + ''', @OperationId = ' + CAST(@OperationId AS VARCHAR)
			
			EXEC(@sql)
		END
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 1
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
		COMMIT TRANSACTION [TransactionCommit]

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionCommit];
		THROW
	END CATCH
END
