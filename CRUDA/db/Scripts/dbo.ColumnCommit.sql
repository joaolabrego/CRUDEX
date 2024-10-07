IF(SELECT object_id('[dbo].[ColumnCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnCommit](@LoginId INT
								   ,@UserName VARCHAR(25)
								   ,@OperationId INT) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @TransactionId	INT
				,@TransactionIdAux INT
				,@TableName VARCHAR(25)
				,@Action VARCHAR(15)
				,@CreatedBy VARCHAR(25)
				,@LastRecord VARCHAR(MAX)
				,@ActualRecord VARCHAR(MAX)
				,@IsConfirmed BIT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		IF @LoginId IS NULL
			THROW 51000, 'Valor de @LoginId é requerido', 1
		IF @UserName IS NULL
			THROW 51000, 'Valor de @UserName é requerido', 1
		IF @OperationId IS NULL
			THROW 51000, 'Valor de @OperationId requerido', 1
		SELECT @TransactionIdAux = [TransactionId]
				,@TableName = [TableName]
				,@Action = [Action]
				,@CreatedBy = [CreatedBy]
				,@LastRecord = [LastRecord]
				,@ActualRecord = [ActualRecord]
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Operations]
			WHERE [Id] = @OperationId
		IF @@ROWCOUNT = 0
			THROW 51000, 'Operação inexistente', 1
		IF @TableName <> 'Columns'
			THROW 51000, 'Tabela da operação é inválida', 1
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName <> @CreatedBy
			THROW 51000, 'Erro grave de segurança', 1
		EXEC @TransactionId = [dbo].[ColumnValidate] @LoginId, @UserName, @Action, @LastRecord, @ActualRecord
		IF @TransactionIdAux <> @TransactionId
			THROW 51000, 'Transação da operação é inválida', 1

		DECLARE @W_Id int = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Id') AS int)

		IF @Action = 'delete'
			DELETE FROM [dbo].[Columns] WHERE [Id] = @W_Id
		ELSE BEGIN

			DECLARE @W_TableId int = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.TableId') AS int)
					,@W_Sequence smallint = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Sequence') AS smallint)
					,@W_DomainId int = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.DomainId') AS int)
					,@W_ReferenceTableId int = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.ReferenceTableId') AS int)
					,@W_Name varchar(25) = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Name') AS varchar(25))
					,@W_Description varchar(50) = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Description') AS varchar(50))
					,@W_Title varchar(25) = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Title') AS varchar(25))
					,@W_Caption varchar(25) = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Caption') AS varchar(25))
					,@W_Default sql_variant = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Default') AS sql_variant)
					,@W_Minimum sql_variant = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Minimum') AS sql_variant)
					,@W_Maximum sql_variant = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Maximum') AS sql_variant)
					,@W_IsPrimarykey bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsPrimarykey') AS bit)
					,@W_IsAutoIncrement bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsAutoIncrement') AS bit)
					,@W_IsRequired bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsRequired') AS bit)
					,@W_IsListable bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsListable') AS bit)
					,@W_IsFilterable bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsFilterable') AS bit)
					,@W_IsEditable bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsEditable') AS bit)
					,@W_IsGridable bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsGridable') AS bit)
					,@W_IsEncrypted bit = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.IsEncrypted') AS bit)

			IF @Action = 'create'
				INSERT INTO [dbo].[Columns] ([Id]
											,[TableId]
											,[Sequence]
											,[DomainId]
											,[ReferenceTableId]
											,[Name]
											,[Description]
											,[Title]
											,[Caption]
											,[Default]
											,[Minimum]
											,[Maximum]
											,[IsPrimarykey]
											,[IsAutoIncrement]
											,[IsRequired]
											,[IsListable]
											,[IsFilterable]
											,[IsEditable]
											,[IsGridable]
											,[IsEncrypted]
											,[CreatedAt]
											,[CreatedBy]
											)
									VALUES (@W_Id
											,@W_TableId
											,@W_Sequence
											,@W_DomainId
											,@W_ReferenceTableId
											,@W_Name
											,@W_Description
											,@W_Title
											,@W_Caption
											,@W_Default
											,@W_Minimum
											,@W_Maximum
											,@W_IsPrimarykey
											,@W_IsAutoIncrement
											,@W_IsRequired
											,@W_IsListable
											,@W_IsFilterable
											,@W_IsEditable
											,@W_IsGridable
											,@W_IsEncrypted
											,GETDATE()
											,@UserName)
			ELSE
				UPDATE [dbo].[Columns] 
					SET [TableId] = @W_TableId
						,[Sequence] = @W_Sequence
						,[DomainId] = @W_DomainId
						,[ReferenceTableId] = @W_ReferenceTableId
						,[Name] = @W_Name
						,[Description] = @W_Description
						,[Title] = @W_Title
						,[Caption] = @W_Caption
						,[Default] = @W_Default
						,[Minimum] = @W_Minimum
						,[Maximum] = @W_Maximum
						,[IsPrimarykey] = @W_IsPrimarykey
						,[IsAutoIncrement] = @W_IsAutoIncrement
						,[IsRequired] = @W_IsRequired
						,[IsListable] = @W_IsListable
						,[IsFilterable] = @W_IsFilterable
						,[IsEditable] = @W_IsEditable
						,[IsGridable] = @W_IsGridable
						,[IsEncrypted] = @W_IsEncrypted
						,[UpdatedAt] = GETDATE()
						,[UpdatedBy] = @UserName
					WHERE [Id] = @W_Id
		END

		UPDATE [cruda].[Operations] 
			SET [IsConfirmed] = 1
				,[UpdatedAt] = GETDATE()
				,[UpdatedBy] = @UserName
			WHERE [Id] = @OperationId

		COMMIT TRANSACTION

		RETURN @TransactionId
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
