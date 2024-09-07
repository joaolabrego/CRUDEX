IF(SELECT object_id('[cruda].[ColumnPersist]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[ColumnPersist] AS PRINT 1')
GO
ALTER PROCEDURE [cruda].[ColumnPersist](@LoginId BIGINT
										,@Action VARCHAR(15)
										,@LastRecord VARCHAR(MAX)
										,@ActualRecord VARCHAR(MAX)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnPersist]: '
				,@TransactionId	BIGINT
				,@TransactionIdAux BIGINT
				,@OperationId BIGINT
				,@TableName VARCHAR(25)
				,@CreatedBy VARCHAR(25)
				,@ActionAux VARCHAR(15)
				,@IsConfirmed BIT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [ColumnPersist]
		ELSE
			SAVE TRANSACTION [ColumnPersist]
		EXEC @TransactionId = [dbo].[ColumnValidate] @LoginId, @Action, @LastRecord, @ActualRecord
		IF @TransactionId = 0
			GOTO EXIT_PROCEDURE
		SELECT @CreatedBy = [CreatedBy]
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Transactions]
			WHERE [Id] = @TransactionId

		DECLARE @W_Id BIGINT = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint) 

		SELECT @OperationId = [OperationId]
				,@TableName = [TableName]
				,@ActionAux = ['Action']
			FROM [cruda].[Operations]
			WHERE [LoginId] = @LoginId
					AND [TableName] = 'Columns'
					AND [IsConfirmed] IS NULL
					AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id 
		IF @@ROWCOUNT = 0 BEGIN
			SELECT @OperationId = ISNULL(MAX(Id) + 1, 1)
				FROM [cruda].[Operations]
			IF @OperationId > 2147483647 BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de @OperationId deve ser menor que ou igual à ''2147483647''.';
				THROW 51000, @ErrorMessage, 1
			END
			INSERT INTO [cruda].[Operations] ([Id]
											  ,[TransactionId]
											  ,[TableName]
											  ,[Action]
											  ,[LastRecord]
											  ,[ActualRecord]
											  ,[IsConfirmed]
											  ,[CreatedAt]
											  ,[CreatedBy])
										VALUES(@OperationId
												,@TransactionId
												,@TableName
												,@Action
												,@LastRecord
												,@ActualRecord
												,NULL
												,GETDATE()
												,@CreatedBy)
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
				   ,[@UpdatedBy] = @CreatedBy
				WHERE [Id] = @OperationId
		END ELSE IF @ActionAux = 'create' BEGIN
			UPDATE [cruda].[Operations] 
				SET [IsConfirmed] = 0
				   ,[UpdatedAt] = GETDATE()
				   ,[UpdatedBy] = @CreatedBy
				WHERE [Id] = @OperationId
		END ELSE BEGIN
			UPDATE [cruda].[Operations] 
				SET [Action] = 'delete'
					,[LastRecord] = @LastRecord
					,[ActualRecord] = @ActualRecord
					,[UpdatedAt] = GETDATE()
					,[@UpdatedBy] = @CreatedBy
				WHERE [Id] = @OperationId
		END

		EXIT_PROCEDURE:

		COMMIT TRANSACTION [ColumnPersist]

		RETURN @OperationId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [ColumnPersist];
		THROW
	END CATCH
END
GO
