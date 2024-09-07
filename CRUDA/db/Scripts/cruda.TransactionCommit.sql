IF(SELECT object_id('[cruda].[TransactionCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionCommit] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionCommit](@TransactionId INT) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionCommit]: '
				,@LoginId BIGINT
				,@OperationId BIGINT
				,@TableName VARCHAR(25)
				,@IsConfirmed BIT
				,@CreatedBy VARCHAR(25)
				,@sql VARCHAR(MAX)

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionsCommit]
		ELSE
			SAVE TRANSACTION [TransactionsCommit]
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @TransactionId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @LoginId = [LoginId]
			  ,@IsConfirmed = [IsConfirmed]
			  ,@CreatedBy = [CreatedBy]
			FROM [cruda].[Transactions]
			WHERE [Id] = @TransactionId
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação inexistente';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		WHILE 1 = 1 BEGIN
			SELECT @OperationId = [Id]
					,@TableName = [TableName]
				FROM [cruda].[Operations]
				WHERE [TransactionId] = @TransactionId
						AND [IsConfirmed] IS NULL
			IF @OperationId IS NULL
				BREAK
			SET @sql = '[dbo].[' + @TableName + 'Commit] @LoginId = ' + CAST(@LoginId AS VARCHAR) + ', @OperationId = ' + CAST(@OperationId AS VARCHAR)
			EXEC @sql
		END
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 1
				,[UpdatedBy] = @CreatedBy
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
GO
