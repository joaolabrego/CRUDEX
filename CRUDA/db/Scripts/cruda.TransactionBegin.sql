IF(SELECT object_id('[cruda].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionBegin](@LoginId BIGINT
										 ,@UserName VARCHAR(25)) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		
		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionBegin]: '
				,@TransactionId	INT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		INSERT [cruda].[Transactions] ([LoginId]
									  ,[IsConfirmed]
									  ,[CreatedAt]
									  ,[CreatedBy])
								VALUES (@LoginId
									   ,NULL
									   ,GETDATE()
									   ,@UserName)
		SET @TransactionId = @@IDENTITY
		COMMIT TRANSACTION

		RETURN CAST(@TransactionId AS INT)
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > @TRANCOUNT BEGIN
			ROLLBACK TRANSACTION [SavePoint]
			COMMIT TRANSACTION
		END;
		THROW
	END CATCH
END
GO
