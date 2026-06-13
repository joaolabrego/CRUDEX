IF(SELECT object_id('[dbo].[TransactionCommit]', 'P')) IS NULL

	EXEC('CREATE PROCEDURE [dbo].[TransactionCommit] AS PRINT 1')

GO

ALTER PROCEDURE[dbo].[TransactionCommit](@Login NVARCHAR(MAX)

										   ,@TransactionId BIGINT

										   ,@ReturnValue BIGINT OUT) AS BEGIN

	DECLARE @ErrorMessage NVARCHAR(MAX)



	SET NOCOUNT ON

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED



	DECLARE @LoginReturn BIGINT

			,@SessionId BIGINT

			,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))

			,@IsConfirmed BIT

			,@CreatedBy VARCHAR(25)

			,@sql NVARCHAR(MAX)



	EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT

	SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)

	IF @SessionId IS NULL

		THROW 51000, 'LoginId Ã© requerido', 1

	IF @TransactionId IS NULL

		THROW 51000, 'Valor de @TransactionId Ã© requerido', 1

	IF @UserName IS NULL

		THROW 51000, 'Valor de @UserName Ã© requerido', 1

	SELECT @IsConfirmed = [IsConfirmed]

		  ,@CreatedBy = [CreatedBy]

		FROM [dbo].[Transactions]

		WHERE [Id] = @TransactionId

			  AND [SessionId] = @SessionId

	IF @@ROWCOUNT = 0

		THROW 51000, 'TransaÃ§Ã£o inexistente', 1

	IF @IsConfirmed IS NOT NULL BEGIN

		SET @ErrorMessage = 'TransaÃ§Ã£o jÃ¡ ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluÃ­da' END;

		THROW 51000, @ErrorMessage, 1

	END

	IF @UserName <> @CreatedBy

		THROW 51000, 'Erro grave de seguranÃ§a', 1

	SET @sql = (SELECT STRING_AGG(
								  CASE [O].[Action]
									  WHEN 'create' THEN '[dbo].[' + [T].[Alias] + 'Create] @Login = @Login, @OperationId = ' + CAST([O].[Id] AS VARCHAR(20))
									  WHEN 'update' THEN '[dbo].[' + [T].[Alias] + 'Update] @Login = @Login, @OperationId = ' + CAST([O].[Id] AS VARCHAR(20))
									  WHEN 'delete' THEN '[dbo].[' + [T].[Alias] + 'Delete] @Login = @Login, @OperationId = ' + CAST([O].[Id] AS VARCHAR(20))
								  END, '; ')

					FROM [dbo].[Operations] [O]

						INNER JOIN [dbo].[Tables] [T] ON [T].[Name] = [O].[TableName]

					WHERE [O].[TransactionId] = @TransactionId

						  AND [O].[IsConfirmed] IS NULL)

	IF @sql IS NOT NULL

		EXEC sp_executesql @sql, N'@Login NVARCHAR(MAX)', @Login = @Login

	UPDATE [dbo].[Transactions]

		SET [IsConfirmed] = 1

			,[UpdatedBy] = @UserName

			,[UpdatedAt] = GETDATE()

		WHERE [Id] = @TransactionId



	RETURN 0

END

GO

