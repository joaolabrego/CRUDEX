USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionBegin](@LoginId BIGINT) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [TransactionBegin]: '
				,@TransactionId	BIGINT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [TransactionBegin]
		ELSE
			SAVE TRANSACTION [TransactionBegin]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionId = MAX([TransactionId]) + 1
			FROM [cruda].[Transactions]
		INSERT [cruda].[Transactions] ([Id]
										,[LoginId]
										,[IsConfirmed]
										,[CreatedAt]
										,[CreatedBy])
								VALUES (ISNULL(@TransactionId, 1)
										,@LoginId
										,NULL
										,GETDATE()
										,@UserName)
		COMMIT TRANSACTION [TransactionBegin]

		RETURN @TransactionId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [TransactionBegin];
		THROW
	END CATCH
END
