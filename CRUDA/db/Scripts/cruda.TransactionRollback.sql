IF(SELECT object_id('[cruda].[TransactionRollback]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionRollback] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionRollback](@TransactionId INT
											,@UserName VARCHAR(25)) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @OperationId INT
				,@CreatedBy VARCHAR(25)
				,@IsConfirmed BIT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		IF @TransactionId IS NULL
			THROW 51000, 'Valor de @TransactionId é requerido', 1
		SELECT @IsConfirmed = [IsConfirmed]
			  ,@CreatedBy = [CreatedBy]
			FROM [cruda].[Transactions]
			WHERE [Id] = @TransactionId
		IF @@ROWCOUNT = 0
			THROW 51000, 'Transação inexistente', 1
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END

		IF @UserName <> @CreatedBy
			THROW 51000, 'Erro grave de segurança', 1
		WHILE 1 = 1 BEGIN
			SELECT TOP 1 @OperationId = [Id]
						,@CreatedBy = [CreatedBy]
				FROM [cruda].[Operations]
				WHERE [TransactionId] = @TransactionId
						AND [IsConfirmed] IS NULL
				ORDER BY [Id]
			IF @@ROWCOUNT = 0
				BREAK
			IF @UserName <> @CreatedBy
				THROW 51000, 'Erro grave de segurança', 1
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
        IF @@TRANCOUNT > @TRANCOUNT BEGIN
            ROLLBACK TRANSACTION [SavePoint];
            COMMIT TRANSACTION
        END
        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
