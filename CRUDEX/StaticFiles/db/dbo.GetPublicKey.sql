IF(SELECT object_id('[dbo].[GetPublicKey]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GetPublicKey] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[GetPublicKey](@SessionId BIGINT
								   ,@ReturnValue BIGINT OUT) AS BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	IF @SessionId IS NULL
		THROW 51000, 'Parâmetro @SessionId é requerido', 1
	SELECT [PublicKey]
		  ,[ClientRsaPublicKey]
		FROM [dbo].[Sessions]
		WHERE [Id] = @SessionId
	IF @@ROWCOUNT = 0
		THROW 51000, 'Valor @SessionId é inexistente', 1
	SET @ReturnValue = @SessionId

	RETURN @ReturnValue
END
GO
