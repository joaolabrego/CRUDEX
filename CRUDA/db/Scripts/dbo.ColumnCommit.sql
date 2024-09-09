IF(SELECT object_id('[dbo].[ColumnCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnCommit](@LoginId BIGINT
								   ,@UserName VARCHAR(25)
								   ,@OperationId INT) AS BEGIN
	DECLARE @TranCount INT = @@TRANCOUNT

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnCommit]: '
				,@TransactionId	INT
				,@TransactionIdAux BIGINT
				,@TableName VARCHAR(25)
				,@Action VARCHAR(15)
				,@CreatedBy VARCHAR(25)
				,@LastRecord VARCHAR(MAX)
				,@ActualRecord VARCHAR(MAX)
				,@IsConfirmed BIT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		IF @OperationId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @OperationId requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionIdAux = [TransactionId]
				,@TableName = [TableName]
				,@Action = [Action]
				,@CreatedBy = [CreatedBy]
				,@LastRecord = [LastRecord]
				,@ActualRecord = [ActualRecord]
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Operations]
			WHERE [Id] = @OperationId
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação inexistente';
			THROW 51000, @ErrorMessage, 1
		END
		IF @TableName <> 'Columns' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela da operação é inválida';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName <> @CreatedBy BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Erro grave de segurança';
			THROW 51000, @ErrorMessage, 1
		END
		EXEC @TransactionId = [dbo].[ColumnsValidate] @LoginId, @UserName, @Action, @LastRecord, @ActualRecord
		IF @TransactionId = 0
			GOTO EXIT_PROCEDURE
		IF @TransactionIdAux <> @TransactionId BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

		IF @Action = 'delete'
			DELETE FROM [dbo].[Columns] WHERE [Id] = @W_Id
		ELSE BEGIN

			DECLARE @W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
					,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
					,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
					,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
					,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
					,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
					,@W_Title varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
					,@W_Caption varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
					,@W_Default sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
					,@W_Minimum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
					,@W_Maximum sql_variant = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
					,@W_IsPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
					,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
					,@W_IsRequired bit = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
					,@W_IsListable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
					,@W_IsFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
					,@W_IsEditable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
					,@W_IsBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
					,@W_IsEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
					,@W_IsCalculated bit = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)

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
											,[IsBrowseable]
											,[IsEncrypted]
											,[IsCalculated]
											,[CreatedAt]
											,[CreatedBy]
											)
									VALUES (@W_Id
											,@TableId
											,@Sequence
											,@DomainId
											,@ReferenceTableId
											,@Name
											,@Description
											,@Title
											,@Caption
											,@Default
											,@Minimum
											,@Maximum
											,@IsPrimarykey
											,@IsAutoIncrement
											,@IsRequired
											,@IsListable
											,@IsFilterable
											,@IsEditable
											,@IsBrowseable
											,@IsEncrypted
											,@IsCalculated
											,GETDATE()
											,@UserName)
			ELSE
				UPDATE [dbo].[Columns] 
					SET [TableId] = @TableId
						,[Sequence] = @Sequence
						,[DomainId] = @DomainId
						,[ReferenceTableId] = @ReferenceTableId
						,[Name] = @Name
						,[Description] = @Description
						,[Title] = @Title
						,[Caption] = @Caption
						,[Default] = @Default
						,[Minimum] = @Minimum
						,[Maximum] = @Maximum
						,[IsPrimarykey] = @IsPrimarykey
						,[IsAutoIncrement] = @IsAutoIncrement
						,[IsRequired] = @IsRequired
						,[IsListable] = @IsListable
						,[IsFilterable] = @IsFilterable
						,[IsEditable] = @IsEditable
						,[IsBrowseable] = @IsBrowseable
						,[IsEncrypted] = @IsEncrypted
						,[IsCalculated] = @IsCalculated
						,[UpdatedAt] = GETDATE()
						,[UpdatedBy] = @UserName
					WHERE [Id] = @W_Id
		END

		EXIT_PROCEDURE:

		UPDATE [cruda].[Operations] 
			SET [IsConfirmed] = 1
				,[UpdatedAt] = GETDATE()
				,[UpdatedBy] = @UserName
			WHERE [Id] = @OperationId

		COMMIT TRANSACTION

		RETURN 1
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > @TranCount BEGIN
			ROLLBACK TRANSACTION [SavePoint]
			COMMIT TRANSACTION
		END;
		THROW
	END CATCH
END
GO
