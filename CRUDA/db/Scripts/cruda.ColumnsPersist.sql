IF(SELECT object_id('[cruda].[ColumnPersist]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[ColumnPersist] AS PRINT 1')
GO
ALTER PROCEDURE [cruda].[ColumnPersist](@LoginId BIGINT
										,@UserName VARCHAR(25)
										,@Action VARCHAR(15)
										,@LastRecord VARCHAR(MAX)
										,@ActualRecord VARCHAR(MAX)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnPersist]: '
				,@TransactionId	INT
				,@OperationId INT
				,@CreatedBy VARCHAR(25)
				,@ActionAux VARCHAR(15)
				,@IsConfirmed BIT

		BEGIN TRANSACTION
		EXEC @TransactionId = [dbo].[ColumnValidate] @LoginId, @UserName, @Action, @LastRecord, @ActualRecord
		IF @TransactionId = 0
			GOTO EXIT_PROCEDURE

		DECLARE @W_Id BIGINT = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint) 

		SELECT @OperationId = [OperationId]
				,@CreatedBy = [CreatedBy]
				,@ActionAux = ['Action']
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Operations]
			WHERE [LoginId] = @LoginId
					AND [TableName] = 'Columns'
					AND [IsConfirmed] IS NULL
					AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
		IF @@ROWCOUNT = 0 BEGIN
			INSERT INTO [cruda].[Operations] ([TransactionId]
											  ,[TableName]
											  ,[Action]
											  ,[LastRecord]
											  ,[ActualRecord]
											  ,[IsConfirmed]
											  ,[CreatedAt]
											  ,[CreatedBy])
										VALUES(@TransactionId
												,@TableName
												,@Action
												,@LastRecord
												,@ActualRecord
												,NULL
												,GETDATE()
												,@UserName)
			SET @OperationId = @@IDENTITY
		END IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END ELSE IF @UserName <> @CreatedBy BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';
			THROW 51000, @ErrorMessage, 1
		END ELSE IF @ActionAux = 'delete' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Registro excluído nesta transação';
			THROW 51000, @ErrorMessage, 1
		END ELSE IF @Action = 'create' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Registro já existe nesta transação';
			THROW 51000, @ErrorMessage, 1
		END ELSE IF @Action = 'update' BEGIN
			UPDATE [cruda].[Operations]
				SET [ActualRecord] = @ActualRecord
				   ,[UpdatedAt] = GETDATE()
				   ,[@UpdatedBy] = @UserName
				WHERE [Id] = @OperationId
		END ELSE IF @ActionAux = 'create' BEGIN
			UPDATE [cruda].[Operations] 
				SET [IsConfirmed] = 0
				   ,[UpdatedAt] = GETDATE()
				   ,[UpdatedBy] = @UserName
				WHERE [Id] = @OperationId
		END ELSE BEGIN
			UPDATE [cruda].[Operations] 
				SET [Action] = 'delete'
					,[LastRecord] = @LastRecord
					,[ActualRecord] = @ActualRecord
					,[UpdatedAt] = GETDATE()
					,[@UpdatedBy] = @UserName
				WHERE [Id] = @OperationId
		END

		EXIT_PROCEDURE:

		COMMIT TRANSACTION

		RETURN @OperationId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		THROW
	END CATCH
END
GO
