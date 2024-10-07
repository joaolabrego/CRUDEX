IF(SELECT object_id('[cruda].[TransactionCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[TransactionCommit] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[TransactionCommit](@TransactionId INT
										  ,@UserName VARCHAR(25)) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @LoginId INT
				,@OperationId INT
				,@TableName VARCHAR(25)
				,@IsConfirmed BIT
				,@CreatedBy VARCHAR(25)
				,@sql VARCHAR(MAX)

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		IF @TransactionId IS NULL
			THROW 51000, 'Valor de @TransactionId é requerido', 1
		IF @UserName IS NULL
			THROW 51000, 'Valor de @UserName é requerido', 1
		SELECT @LoginId = [LoginId]
			  ,@IsConfirmed = [IsConfirmed]
			  ,@CreatedBy = [CreatedBy]
			FROM [cruda].[Transactions]
			WHERE [Id] = @TransactionId
		IF @@ROWCOUNT = 0
			THROW 51000, 'Transação inexistente', 1
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName <> @CreatedBy
			THROW 51000, 'Erro grave de segurança', 1
		SET @sql = (SELECT STRING_AGG('[dbo].[' + [O].[TableName] + 'Commit] @LoginId = ' +
									  CAST(@LoginId AS VARCHAR) + ', @OperationId = ' +
									  CAST([O].[Id] AS VARCHAR), '; ')
						FROM [cruda].[Operations] [O]
						WHERE [O].[TransactionId] = @TransactionId
							  AND [O].[IsConfirmed] IS NULL)
		EXEC sp_executesql @sql
		UPDATE [cruda].[Transactions]
			SET [IsConfirmed] = 1
				,[UpdatedBy] = @UserName
				,[UpdatedAt] = GETDATE()
			WHERE [Id] = @TransactionId
		COMMIT TRANSACTION

		RETURN 1
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
