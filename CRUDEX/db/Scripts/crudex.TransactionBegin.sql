IF(SELECT object_id('[crudex].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [crudex].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[crudex].[TransactionBegin](@LoginId BIGINT
										 ,@UserName VARCHAR(25)
										 ,@ReturnValue BIGINT OUT) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		IF @LoginId IS NULL
			THROW 51000, 'Valor de @LoginId é requerido', 1
		IF @UserName IS NULL
			THROW 51000, 'Valor de @UserName é requerido', 1
		IF EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [LoginId] = @LoginId AND [IsConfirmed] IS NULL)
			THROW 51000, 'Há transação pendente neste @LoginId', 1
		
		DECLARE @TransactionId BIGINT

		EXEC @TransactionId = [dbo].[NewId] 'crudex', 'crudex', 'Transactions'
		INSERT [dbo].[Transactions] ([Id]
									,[LoginId]
									,[IsConfirmed]
									,[CreatedAt]
									,[CreatedBy])
								VALUES (@TransactionId
									   ,@LoginId
									   ,NULL
									   ,GETDATE()
									   ,@UserName)
		SET @ReturnValue = @TransactionId
		COMMIT TRANSACTION

		RETURN 0
	END TRY
	BEGIN CATCH
        IF @@TRANCOUNT > @TRANCOUNT BEGIN
            ROLLBACK TRANSACTION [SavePoint]
            COMMIT TRANSACTION
        END
        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
