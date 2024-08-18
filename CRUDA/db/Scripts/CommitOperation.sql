USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[CommitOperation]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[CommitOperation] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[CommitOperation](@OperationId BIGINT = NULL) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsCommit: '

		IF @OperationId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Id de operação requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION CommitOperation
		ELSE
			SAVE TRANSACTION CommitOperation

		DECLARE @TransactionId BIGINT
				,@TableId BIGINT
				,@Action VARCHAR(15)
				,@LastRecord VARCHAR(MAX)
				,@ActualRecord VARCHAR(MAX)
				,@IsConfirmed BIT
				

		SELECT @TransactionId = [TransactionId]
				,@TableId = [TableId]
				,@Action = [Action]
				,@LastRecord = [LastRecord]
				,@ActualRecord = [ActualRecord]
				,@IsConfirmed = [IsConfirmed]
			FROM [dbo].[Operations]
			WHERE [Id] = @OperationId
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action NOT IN ('create', 'update', 'delete') BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Ação da operação é inválida.';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @LoginId BIGINT

		SELECT @LoginId = [LoginId]
				,@IsConfirmed = [IsConfirmed]
			FROM [dbo].[Transactions]
			WHERE [Id] = @TransactionId
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @UserName VARCHAR(25)

		SELECT @UserName = [Name]
			FROM [dbo].[Users]
			WHERE [Id] = @UserId
		IF @UserName IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Usuário não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

		IF @Action = 'delete' BEGIN
			DELETE FROM [dbo].[Columns] WHERE [Id] = @W_Id
		END ELSE BEGIN
			IF @Action = 'create' BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
					SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe.';
					THROW 51000, @ErrorMessage, 1
				END
				IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
					SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Sequence já existe.';
					THROW 51000, @ErrorMessage, 1
				END
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
			END ELSE IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name AND [Id] <> @W_Id) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe.';
				THROW 51000, @ErrorMessage, 1
			END ELSE IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence AND [Id] <> @W_Id) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Sequence já existe.';
				THROW 51000, @ErrorMessage, 1
			END ELSE BEGIN
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
		END
		UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
		COMMIT TRANSACTION CommitOperation

		RETURN 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION CommitOperation;
		THROW
	END CATCH
END
