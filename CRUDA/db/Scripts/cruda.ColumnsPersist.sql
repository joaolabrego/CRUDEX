IF(SELECT object_id('[cruda].[ColumnsPersist]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[ColumnsPersist] AS PRINT 1')
GO
ALTER PROCEDURE [cruda].[ColumnsPersist](@LoginId BIGINT
										,@UserName VARCHAR(25)
										,@Action VARCHAR(15)
										,@LastRecord VARCHAR(MAX)
										,@ActualRecord VARCHAR(MAX)
										,@IsBeginTransaction BIT = 0) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		EXEC [dbo].[ColumnsValid] @LoginId, @Action, @LastRecord, @ActualRecord

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsPersist]: '
				,@TransactionId	BIGINT
				,@TransactionIdAux BIGINT
				,@OperationId BIGINT
				,@Action VARCHAR(15)
				,@ActionAux VARCHAR(15)
				,@LastRecord VARCHAR(MAX)
				,@ActualRecord VARCHAR(MAX)
				,@IsConfirmed BIT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [ColumnsPersist]
		ELSE
			SAVE TRANSACTION [ColumnsPersist]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @UserName é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsBeginTransaction = 1 BEGIN
			SELECT @TransactionId = MAX([TransactionId]) + 1
					,@IsConfirmed = 1
				FROM [cruda].[Transactions]
			INSERT [cruda].[Transactions] ([Id]
										   ,[LoginId]
										   ,[IsConfirmed])
									VALUES (ISNULL(@TransactionId, 1)
											,@LoginId
											,@IsConfirmed)
		END ELSE BEGIN
			SELECT @TransactionId = [TransactionId]
					,@IsConfirmed = [IsConfirmed]
				FROM [cruda].[Transactions]
				WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
			IF @TransactionId IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Transação é inexistente';
				THROW 51000, @ErrorMessage, 1
			END
			IF @IsConfirmed IS NOT NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
				THROW 51000, @ErrorMessage, 1
			END
		END
		SELECT @OperationId = [OperationId]
				,@ActionAux = ['Action']
			FROM [cruda].[Operations]
			WHERE [LoginId] = @LoginId
					AND [TableName] = 'Columns'
					AND [IsConfirmed] IS NULL
					AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint) 
		IF @OperationId IS NULL BEGIN
			SELECT @OperationId = MAX(Id) + 1 FROM [cruda].[Operations]
			INSERT INTO [cruda].[Operations] ([Id]
											  ,[TransactionId]
											  ,[TableName]
											  ,[Action]
											  ,[LastRecord]
											  ,[ActualRecord]
											  ,[IsConfirmed]
											  ,[CreatedAt]
											  ,[CreatedBy])
										VALUES(ISNULL(@OperationId, 1)
												,@TransactionId
												,@TableName
												,@Action
												,@LastRecord
												,@ActualRecord
												,NULL
												,GETDATE()
												,@UserName)
		END ELSE BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Registro pendente de efetivação';
			THROW 51000, @ErrorMessage, 1
		END
		COMMIT TRANSACTION [ColumnsPersist]

		RETURN @OperationId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [ColumnsPersist];
		THROW
	END CATCH
END
GO
