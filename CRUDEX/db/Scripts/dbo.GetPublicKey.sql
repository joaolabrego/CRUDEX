IF(SELECT object_id('[dbo].[GetPublicKey]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GetPublicKey] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[GetPublicKey](@LoginId BIGINT
								   ,@ReturnValue BIGINT OUT) AS BEGIN
	DECLARE @ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		IF @LoginId IS NULL
			THROW 51000, 'Parâmetro @LoginId é requerido', 1
		SELECT [PublicKey]
			FROM [dbo].[Logins]
			WHERE [Id] = @LoginId
		IF @@ROWCOUNT = 0
			THROW 51000, 'Valor @LoginId é inexistente', 1
		SET @ReturnValue = @LoginId

		RETURN @ReturnValue
	END TRY
	BEGIN CATCH
        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
