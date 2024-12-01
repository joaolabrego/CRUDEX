USE [cruda]
GO
/****** Object:  StoredProcedure [dbo].[ColumnsCreate]    Script Date: 21/07/2024 10:46:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE[dbo].[ColumnsCreate](@Parameters VARCHAR(MAX)) AS
BEGIN
BEGIN TRY
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRANSACTION

	DECLARE @ErrorMessage VARCHAR(255)

	IF ISJSON(@Parameters) = 0 BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
		THROW 51000, @ErrorMessage, 1
	END

	DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX)),
			@IsCommit BIT = ISNULL(CAST(JSON_VALUE(@Parameters, '$.IsCommit') AS BIT), 0)

	IF ISJSON(@Login) = 0 BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Login não está no formato JSON.';
		THROW 51000, @ErrorMessage, 1
	END
	EXEC [dbo].[P_Login] @Login
	
	DECLARE @SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
			,@DatabaseName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.DatabaseName') AS VARCHAR(25))
			,@TableName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.TableName') AS VARCHAR(25))
			,@OperationId BIGINT = CAST(JSON_VALUE(@Parameters, '$.OperationId') AS BIGINT)
			,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
			,@TransactionId BIGINT
			,@TableId BIGINT
			,@Action VARCHAR(15)
			,@ActualRecord VARCHAR(MAX)
			,@IsConfirmed BIT

	SELECT @TransactionId = [TransactionId]
			,@TableId = [TableId]
			,@Action = [Action]
			,@ActualRecord = [ActualRecord]
			,@IsConfirmed = [IsConfirmed]
		FROM [dbo].[Operations]
		WHERE [Id] = @OperationId
	IF @@ROWCOUNT = 0 BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Operação não cadastrada.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @Action <> 'create' BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Operação não é de inclusão.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @IsConfirmed IS NOT NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
		THROW 51000, @ErrorMessage, 1
	END
	IF (SELECT [Name]
		FROM [dbo].[Tables]
		WHERE [Id] = @TableId) <> @TableName BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Nome de tabela inválido para a operação.';
		THROW 51000, @ErrorMessage, 1
	END
	
	DECLARE @SystemId BIGINT
			,@DatabaseId BIGINT

	SELECT @SystemId = [SystemId]
			,@DatabaseId = [DatabaseId]
			,@IsConfirmed = [IsConfirmed]
		FROM [dbo].[Transactions]
		WHERE [Id] = @TransactionId
	IF @System IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @IsConfirmed IS NOT NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
		THROW 51000, @ErrorMessage, 1
	END
	IF (SELECT [Name]
			FROM [dbo].[Systems]
			WHERE [Id] = @SystemId) <> @SystemName BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Sistema inválido para a transação.';
		THROW 51000, @ErrorMessage, 1
	END
	IF (SELECT [Name]
			FROM [dbo].[Databases]
			WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados inválido para a transação.';
		THROW 51000, @ErrorMessage, 1
	END
	IF NOT EXISTS(SELECT 1
					FROM [dbo].[DatabasesTables]
					WHERE [DatabaseId] = @DatabaseId
							AND [TableId] = @TableId) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
		THROW 51000, @ErrorMessage, 1
	END

	DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
			,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
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
	IF @W_Id IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Id < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_TableId IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de TableId é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_TableId < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de TableId não existe em Tables';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Sequence IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de Sequence é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Sequence < CAST('1' AS smallint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser maior que ou igual à ''1''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Sequence > CAST('32767' AS smallint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @Sequence deve ser menor que ou igual à ''32767''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_DomainId IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_DomainId < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser maior que ou igual à ''1''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_DomainId) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de DomainId não existe em Domains';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser maior que ou igual à ''1''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de @ReferenceTableId deve ser menor que ou igual à ''9007199254740990''.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_ReferenceTableId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ReferenceTableId) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de ReferenceTableId não existe em Tables';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Name IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de Name é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Description IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de Description é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Title IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de Title é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_Caption IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de Caption é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_IsRequired IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de IsRequired é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @W_IsCalculated IS NULL BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Valor de IsCalculated é requerido.';
		THROW 51000, @ErrorMessage, 1
	END
	IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_Id) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Chave-primária já existe na tabela Columns.';
		THROW 51000, @ErrorMessage, 1
	END
	IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Name já existe.';
		THROW 51000, @ErrorMessage, 1
	END
	IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Chave única do índice UNQ_Columns_TableId_Sequence já existe.';
		THROW 51000, @ErrorMessage, 1
	END
	IF @IsCommit = 1 BEGIN
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
									,@W_TableId
									,@W_Sequence
									,@W_DomainId
									,@W_ReferenceTableId
									,@W_Name
									,@W_Description
									,@W_Title
									,@W_Caption
									,@W_ValidValues
									,@W_Default
									,@W_Minimum
									,@W_Maximum
									,@W_IsPrimarykey
									,@W_IsAutoIncrement
									,@W_IsRequired
									,@W_IsListable
									,@W_IsFilterable
									,@W_IsEditable
									,@W_IsBrowseable
									,@W_IsEncrypted
									,@W_IsCalculated
									,GETDATE()
									,@UserName)
		UPDATE[dbo].[Operations] SET [IsConfirmed] = 1, [UpdatedAt] = GETDATE(), [UpdatedBy] = @UserName WHERE [Id] = @OperationId
	END ELSE BEGIN
		PRINT ''
	END
	RETURN 1
END TRY
BEGIN CATCH
	THROW
END CATCH
END
