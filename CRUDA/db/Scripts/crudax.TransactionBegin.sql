IF(SELECT object_id('[crudax].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [crudax].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[crudax].[TransactionBegin](@LoginId INT
										 ,@UserName VARCHAR(25)) AS BEGIN
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
		IF EXISTS(SELECT 1 FROM [crudax].[Transactions] WHERE [LoginId] = @LoginId AND [IsConfirmed] IS NULL)
			THROW 51000, 'Há transação pendente neste @LoginId', 1
		INSERT [crudax].[Transactions] ([LoginId]
									  ,[IsConfirmed]
									  ,[CreatedAt]
									  ,[CreatedBy])
								VALUES (@LoginId
									   ,NULL
									   ,GETDATE()
									   ,@UserName)

		DECLARE @TransactionId INT = @@IDENTITY

		COMMIT TRANSACTION

		RETURN @TransactionId
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
