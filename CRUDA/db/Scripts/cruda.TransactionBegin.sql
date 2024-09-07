IF(SELECT object_id('[cruda].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionBegin](@LoginId BIGINT
										 ,@UserName VARCHAR(25)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionBegin]: '
				,@TransactionId	INT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionBegin]
		ELSE
			SAVE TRANSACTION [TransactionBegin]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		INSERT [cruda].[Transactions] ([[LoginId]
									  ,[IsConfirmed]
									  ,[CreatedAt]
									  ,[CreatedBy])
								VALUES (@LoginId
									   ,NULL
									   ,GETDATE()
									   ,@UserName)
		SET @TransactionId = @@IDENTITY
		COMMIT TRANSACTION [TransactionBegin]

		RETURN CAST(@TransactionId AS INT)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionBegin];
		THROW
	END CATCH
END
GO
