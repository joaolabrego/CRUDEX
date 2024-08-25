USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[ColumnsPersist]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnsPersist] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsPersist](@LoginId BIGINT
									  ,@Action VARCHAR(15)
									  ,@ActualRecord VARCHAR(MAX)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure [ColumnsPersist]: '
				,@TransactionId BIGINT
				,@TableName	VARCHAR(25)
				,@ActionAux VARCHAR(15)
				,@LastRecord VARCHAR(MAX)
				,@ActualRecordAux VARCHAR(MAX)
				,@IsConfirmed BIT

		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION [ColumnsPersist]
		ELSE
			SAVE TRANSACTION [ColumnsPersist]
		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TransactionId = MAX([[O].[TransactionId])
			FROM [cruda].[Operations] [O]
				INNER JOIN [cruda].[Transactions] [T] ON [T].[Id] = [O].[TransactionId]
			WHERE [T].[LoginId] = @LoginId
		IF @TransactionId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação inexistente para o login fornecido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @IsConfirmed = [IsConfirmed]
			FROM [cruda].[Transactions]
			WHERE [Id] = @TransactionId
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TableName = [TableName]
				,@ActionAux = [Action]
				,@LastRecord = [LastRecord]
				,@ActualRecordAux = [ActualRecord]
				,@IsConfirmed = [IsConfirmed]
			FROM [cruda].[Operations]
			WHERE [LoginId] = @LoginId
					AND [IsConfirmed] IS NULL
					AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint) 
		

		IF @Action NOT IN ('create', 'update', 'delete') BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @Action é inválido';
			THROW 51000, @ErrorMessage, 1
		END
		IF ISJSON(@ActualRecord) = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @ActualRecord não está no formato JSON';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action <> 'create' BEGIN
			IF @LastRecord IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LastRecord requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF ISJSON(@LastRecord) = 0 BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor do parâmetro @LastRecord não está no formato JSON';
				THROW 51000, @ErrorMessage, 1
			END
			IF NOT EXISTS(SELECT 1 
							FROM [dbo].[Columns]
							WHERE [dbo].[F_IsEquals]([Id], CAST(JSON_VALUE(@LastRecord, '$.Id') AS bigint)) = 1
									AND [dbo].[F_IsEquals]([TableId], CAST(JSON_VALUE(@LastRecord, '$.TableId') AS bigint)) = 1
									AND [dbo].[F_IsEquals]([Sequence], CAST(JSON_VALUE(@LastRecord, '$.Sequence') AS smallint)) = 1
									AND [dbo].[F_IsEquals]([DomainId], CAST(JSON_VALUE(@LastRecord, '$.DomainId') AS bigint)) = 1
									AND [dbo].[F_IsEquals]([ReferenceTableId], CAST(JSON_VALUE(@LastRecord, '$.ReferenceTableId') AS bigint)) = 1
									AND [dbo].[F_IsEquals]([Name], CAST(JSON_VALUE(@LastRecord, '$.Name') AS varchar(25))) = 1
									AND [dbo].[F_IsEquals]([Description], CAST(JSON_VALUE(@LastRecord, '$.Description') AS varchar(50))) = 1
									AND [dbo].[F_IsEquals]([Title], CAST(JSON_VALUE(@LastRecord, '$.Title') AS varchar(25))) = 1
									AND [dbo].[F_IsEquals]([Caption], CAST(JSON_VALUE(@LastRecord, '$.Caption') AS varchar(25))) = 1
									AND [dbo].[F_IsEquals]([ValidValues], CAST(JSON_VALUE(@LastRecord, '$.ValidValues') AS varchar(25))) = 1
									AND [dbo].[F_IsEquals]([Default], CAST(JSON_VALUE(@LastRecord, '$.Default') AS sql_variant)) = 1
									AND [dbo].[F_IsEquals]([Minimum], CAST(JSON_VALUE(@LastRecord, '$.Minimum') AS sql_variant)) = 1
									AND [dbo].[F_IsEquals]([Maximum], CAST(JSON_VALUE(@LastRecord, '$.Maximum') AS sql_variant)) = 1
									AND [dbo].[F_IsEquals]([IsPrimarykey], CAST(JSON_VALUE(@LastRecord, '$.IsPrimarykey') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsAutoIncrement], CAST(JSON_VALUE(@LastRecord, '$.IsAutoIncrement') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsRequired], CAST(JSON_VALUE(@LastRecord, '$.IsRequired') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsListable], CAST(JSON_VALUE(@LastRecord, '$.IsListable') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsFilterable], CAST(JSON_VALUE(@LastRecord, '$.IsFilterable') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsEditable], CAST(JSON_VALUE(@LastRecord, '$.IsEditable') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsBrowseable], CAST(JSON_VALUE(@LastRecord, '$.IsBrowseable') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsEncrypted], CAST(JSON_VALUE(@LastRecord, '$.IsEncrypted') AS bit)) = 1
									AND [dbo].[F_IsEquals]([IsCalculated], CAST(JSON_VALUE(@LastRecord, '$.IsCalculated') AS bit)) = 1) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Registro da tabela Columns alterado por outro usuário';
				THROW 51000, @ErrorMessage, 1
			END
		END

		DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

		IF @W_Id IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de Id no parâmetro @ActualRecord é requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_Id < CAST('1' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de Id no parâmetro @ActualRecord deve ser maior que ou igual à 1';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de Id no parâmetro @ActualRecord deve ser menor que ou igual à 9007199254740990';
			THROW 51000, @ErrorMessage, 1
		END
		IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id) BEGIN
			IF @Action = 'create' BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Columns';
				THROW 51000, @ErrorMessage, 1
			END
		END ELSE IF @Action <> 'create' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action <> 'delete' BEGIN
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

			IF @W_TableId IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de TableId no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_TableId < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de TableId no parâmetro @ActualRecord deve ser maior que ou igual à 1';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de TableId no parâmetro @ActualRecord deve ser menor que ou igual à 9007199254740990';
				THROW 51000, @ErrorMessage, 1
			END
			IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de TableId no parâmetro @ActualRecord não existe na tabela Tables';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Sequence IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Sequence < CAST('1' AS smallint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence no parâmetro @ActualRecord deve ser maior que ou igual à 1';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Sequence > CAST('32767' AS smallint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence no parâmetro @ActualRecord deve ser menor que ou igual à 32767';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_DomainId IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_DomainId < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId no parâmetro @ActualRecord deve ser maior que ou igual à 1';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId no parâmetro @ActualRecord deve ser menor que ou igual à 9007199254740990';
				THROW 51000, @ErrorMessage, 1
			END
			IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_DomainId) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId no parâmetro @ActualRecord não existe na tabela Domains';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId no parâmetro @ActualRecord deve ser maior que ou igual à 1';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId no parâmetro @ActualRecord deve ser menor que ou igual à 9007199254740990';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_ReferenceTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ReferenceTableId) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId no parâmetro @ActualRecord não existe na tabela Tables';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Name IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Name no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Description IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Description no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Title IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Title no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_Caption IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de Caption no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @W_IsRequired IS NULL BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Valor de IsRequired no parâmetro @ActualRecord é requerido';
				THROW 51000, @ErrorMessage, 1
			END
			IF @Action = 'create' BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
					SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe';
					THROW 51000, @ErrorMessage, 1
				END
				IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
					SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Sequence já existe';
					THROW 51000, @ErrorMessage, 1
				END
			END ELSE IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence AND [Id] <> @W_Id) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Sequence já existe';
				THROW 51000, @ErrorMessage, 1
			END ELSE IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name AND [Id] <> @W_Id) BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Chave única de índice UNQ_Columns_Table_Name já existe';
				THROW 51000, @ErrorMessage, 1
			END
		END

		RETURN 0
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
