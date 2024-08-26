USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[ColumnsCommit]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnsCommit] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsCommit](@LoginId BIGINT,
									 @OperationId BIGINT) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsCommit]: '
				,@TransactionId	BIGINT
				,@TransactionIdAux	BIGINT
				,@SystemName VARCHAR(25)
				,@DatabaseName VARCHAR(25)
				,@TableName VARCHAR(25)
				,@Action VARCHAR(15)
				,@LastRecord VARCHAR(MAX)
				,@ActualRecord VARCHAR(MAX)
				,@IsConfirmed BIT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [ColumnsCommit]
		ELSE
			SAVE TRANSACTION [ColumnsCommit]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @OperationId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @OperationId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionId = [TransactionId]
				,@SystemName = [SystemName]
				,@DatabaseName = [DatabaseName]
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Transactions]
			WHERE [TransactionId] = (SELECT MAX([TransactionId]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId)
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação inexistente para login fornecido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemName <> 'cruda' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema da transação é inválido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @DatabaseName <> 'cruda' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados da transação é inválido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionIdAux = [TransactionId]
				,@TableName = [TableName]
				,@Action = [Action]
				,@LastRecord = [LastRecord]
				,@ActualRecord = [ActualRecord]
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Operations]
			WHERE [Id] = @OperationId
		IF @TransactionIdAux IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação inexistente';
			THROW 51000, @ErrorMessage, 1
		END
		IF @TransactionIdAux <> @TransactionId BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação da operação é inválida';
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
		EXEC [dbo].[ColumnsValid] @Action, @LastRecord, @ActualRecord
		IF @Action = 'delete' BEGIN
			DELETE FROM [dbo].[Columns] WHERE [Id] = @W_Id
		END ELSE BEGIN

			DECLARE @W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
					,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
					,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
					,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
					,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
					,@W_Description varchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
					,@W_Title varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
					,@W_Caption varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
					,@W_ValidValues varchar(MAX) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
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
											,[ValidValues]
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
											,CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
											,CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
											,CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
											,CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
											,CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
											,CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
											,CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
											,CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
											,CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
											,CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
											,CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
											,CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
											,CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)
											,GETDATE()
											,@UserName)
			ELSE
				UPDATE [dbo].[Columns] 
					SET [TableId] = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
						,[Sequence] = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
						,[DomainId] = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
						,[ReferenceTableId] = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
						,[Name] = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
						,[Description] = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50))
						,[Title] = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25))
						,[Caption] = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25))
						,ValidValues = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(MAX))
						,[Default] = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant)
						,[Minimum] = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant)
						,[Maximum] = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant)
						,[IsPrimarykey] = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
						,[IsAutoIncrement] = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
						,[IsRequired] = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
						,[IsListable] = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
						,[IsFilterable] = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
						,[IsEditable] = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
						,[IsBrowseable] = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
						,[IsEncrypted] = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
						,[IsCalculated] = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)
						,[UpdatedBy] = @UserName
						,[UpdatedAt] = GETDATE()
					WHERE [Id] = @W_Id
		END
		COMMIT TRANSACTION [ColumnsCommit]

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION [ColumnsCommit];
		THROW
	END CATCH
END
