USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[GetPublicKey]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GetPublicKey] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[GetPublicKey](@LoginId BIGINT) AS 
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(256)

		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = 'Parâmetro @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT [PublicKey]
			FROM [dbo].[Logins]
			WHERE [Id] = @LoginId
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Valor @LoginId é inexistente';
			THROW 51000, @ErrorMessage, 1
		END

		RETURN @LoginId
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
