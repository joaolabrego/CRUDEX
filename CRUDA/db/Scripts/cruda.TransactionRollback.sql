IF(SELECT object_id('[cruda].[TransactionRollback]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionRollback] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionRollback](@TransactionId INT
											,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionRollback]: '
				,@OperationId INT
				,@CreatedBy VARCHAR(25)
				,@IsConfirmed BIT

		BEGIN TRANSACTION
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @TransactionId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @IsConfirmed = [IsConfirmed]
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
		IF @UserName <> @CreatedBy BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';
			THROW 51000, @ErrorMessage, 1
		END
		WHILE 1 = 1 BEGIN
			SELECT TOP 1 @OperationId = [Id]
						,@CreatedBy = [CreatedBy]
				FROM [cruda].[Operations]
				WHERE [TransactionId] = @TransactionId
						AND [IsConfirmed] IS NULL
			IF @@ROWCOUNT = 0
				BREAK
			IF @UserName <> @CreatedBy BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';
				THROW 51000, @ErrorMessage, 1
			END
			UPDATE [cruda].[Operations]
				SET [IsConfirmed] = 0
					,[UpdatedBy] = @UserName
					,[UpdatedAt] = GETDATE()
				WHERE [Id] = @OperationId
		END
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 0
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
		COMMIT TRANSACTION

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW
	END CATCH
END
GO
