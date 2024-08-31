USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[TransactionRollback]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionRollback] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionRollback](@TransactionId BIGINT
											,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionRollback]: '
				,@LoginId BIGINT
				,@OperationId BIGINT
				,@TransactionIdAux BIGINT
				,@IsConfirmed BIT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionRollback]
		ELSE
			SAVE TRANSACTION [TransactionRollback]
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @TransactionId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionIdAux = [Id]
			  ,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Transactions]
			WHERE [TransactionId] = @TransactionId
		IF @TransactionIdAux IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação é inexistente';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		UPDATE [cruda].[Operations]
			SET [IsConfirmed] = 0
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
				  AND [IsConfirmed] IS NULL
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 0
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
		COMMIT TRANSACTION [TransactionRollback]

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionRollback];
		THROW
	END CATCH
END
