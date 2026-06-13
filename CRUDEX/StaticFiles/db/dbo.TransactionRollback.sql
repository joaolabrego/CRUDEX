IF(SELECT object_id('[dbo].[TransactionRollback]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[TransactionRollback] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TransactionRollback](@TransactionId INT
											,@UserName VARCHAR(25)) AS BEGIN
	DECLARE @ErrorMessage NVARCHAR(MAX)

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	DECLARE @OperationId INT
			,@CreatedBy VARCHAR(25)
			,@IsConfirmed BIT

	IF @TransactionId IS NULL
		THROW 51000, 'Valor de @TransactionId Ã© requerido', 1
	SELECT @IsConfirmed = [IsConfirmed]
		  ,@CreatedBy = [CreatedBy]
		FROM [dbo].[Transactions]
		WHERE [Id] = @TransactionId
	IF @@ROWCOUNT = 0
		THROW 51000, 'TransaÃ§Ã£o inexistente', 1
	IF @IsConfirmed IS NOT NULL BEGIN
		SET @ErrorMessage = 'TransaÃ§Ã£o jÃ¡ ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluÃ­da' END;
		THROW 51000, @ErrorMessage, 1
	END

	IF @UserName <> @CreatedBy
		THROW 51000, 'Erro grave de seguranÃ§a', 1
	WHILE 1 = 1 BEGIN
		SELECT TOP 1 @OperationId = [Id]
					,@CreatedBy = [CreatedBy]
			FROM [dbo].[Operations]
			WHERE [TransactionId] = @TransactionId
					AND [IsConfirmed] IS NULL
			ORDER BY [Id]
		IF @@ROWCOUNT = 0
			BREAK
		IF @UserName <> @CreatedBy
			THROW 51000, 'Erro grave de seguranÃ§a', 1
		UPDATE [dbo].[Operations]
			SET [IsConfirmed] = 0
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @OperationId
	END
	UPDATE [dbo].[Transactions]
		SET [IsConfirmed] = 0
			,[UpdatedBy] = @UserName
			,[UpdatedAt] = GETDATE()
		WHERE [Id] = @TransactionId

	RETURN 1
END
GO
