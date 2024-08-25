USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF (SELECT object_id('[dbo].[ColumnsValidCreate]', 'TF')) IS NOT NULL 
	DROP FUNCTION [dbo].[ColumnsValidCreate]
GO
CREATE FUNCTION [dbo].[ColumnsValidCreate](@SystemName VARCHAR(25),
										   @DatabaseName VARCHAR(25),
										   @TableName VARCHAR(25),
										   @OperationId BIGINT,
										   @Login VARCHAR(MAX))
RETURNS @result TABLE ([Record] VARCHAR(MAX),
					   [ErrorMessage] VARCHAR(255)) AS
BEGIN
	DECLARE @FunctionName VARCHAR(255) = 'Function ColumnsValidCreate: '
			,@ErrorMessage VARCHAR(255)

	IF ISJSON(@Login) = 0 BEGIN
		SET @ErrorMessage = @ErrorMessage + 'Login n�o est� no formato JSON.'
		GOTO EXIT_FUNCTION
	END

	DECLARE @TransactionId BIGINT
			,@SystemId BIGINT
			,@DatabaseId BIGINT
			,@TableId BIGINT
			,@Action VARCHAR(15)
			,@IsConfirmed BIT
			,@ActualRecord VARCHAR(MAX)
			,@W_Id bigint
			,@W_TableId bigint
			,@W_Sequence smallint
			,@W_DomainId bigint
			,@W_ReferenceTableId bigint
			,@W_Name varchar(25)
			,@W_Description varchar(50)
			,@W_Title varchar(25)
			,@W_Caption varchar(25)
			,@W_ValidValues varchar(MAX)
			,@W_Default sql_variant
			,@W_Minimum sql_variant
			,@W_Maximum sql_variant
			,@W_IsPrimarykey bit
			,@W_IsAutoIncrement bit
			,@W_IsRequired bit
			,@W_IsListable bit
			,@W_IsFilterable bit
			,@W_IsEditable bit
			,@W_IsBrowseable bit
			,@W_IsEncrypted bit
			,@W_IsCalculated bit

	SELECT @TransactionId = [TransactionId]
			,@TableId = [TableId]
			,@Action = [Action]
			,@ActualRecord = [ActualRecord]
			,@IsConfirmed = [IsConfirmed]
		FROM [dbo].[Operations]
		WHERE [Id] = @OperationId
	IF @@ROWCOUNT = 0 BEGIN
		SET @ErrorMessage = @FunctionName + 'Opera��o n�o cadastrada.'
		GOTO EXIT_FUNCTION
	END
	IF @Action <> 'create' BEGIN
		SET @ErrorMessage = @FunctionName + 'Opera��o n�o � de inclus�o.'
		GOTO EXIT_FUNCTION
	END
	IF @IsConfirmed IS NOT NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Opera��o j� ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'conclu�da' END + '.'
		GOTO EXIT_FUNCTION
	END
	SELECT @SystemId = [SystemId]
			,@DatabaseId = [DatabaseId]
			,@IsConfirmed = [IsConfirmed]
		FROM [dbo].[Transactions]
		WHERE [Id] = @TransactionId
	IF @@ROWCOUNT = 0 BEGIN
		SET @ErrorMessage = @FunctionName + 'Transa��o n�o cadastrada.'
		GOTO EXIT_FUNCTION
	END
	IF @IsConfirmed IS NOT NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Transa��o j� ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'conclu�da' END + '.'
		GOTO EXIT_FUNCTION
	END
	IF (SELECT [Name]
			FROM [dbo].[Systems]
			WHERE [Id] = @SystemId) <> @SystemName BEGIN
		SET @ErrorMessage = @FunctionName + 'Nome de sistema inv�lido para a transa��o.'
		GOTO EXIT_FUNCTION
	END
	IF (SELECT [Name] 
			FROM [dbo].[Databases]
			WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
		SET @ErrorMessage = @FunctionName + 'Nome de banco-de-dados inv�lido para a transa��o.'
		GOTO EXIT_FUNCTION
	END
	IF (SELECT [Name]
			FROM [dbo].[Tables]
			WHERE [Id] = @TableId) <> @TableName BEGIN
		SET @ErrorMessage = @FunctionName + 'Nome de tabela inv�lido para a opera��o.'
		GOTO EXIT_FUNCTION
	END
	IF NOT EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @DatabaseId AND [TableId] = @TableId) BEGIN
		SET @ErrorMessage = @FunctionName + 'Tabela n�o pertence ao banco-de-dados especificado.'
		GOTO EXIT_FUNCTION
	END
	SELECT @W_Id = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint),
			@W_TableId = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint),
			@W_Sequence = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint),
			@W_DomainId = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint),
			@W_ReferenceTableId = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint),
			@W_Name = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25)),
			@W_Description = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS varchar(50)),
			@W_Title = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS varchar(25)),
			@W_Caption = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS varchar(25)),
			@W_ValidValues = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS varchar(25)),
			@W_Default = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS sql_variant),
			@W_Minimum = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS sql_variant),
			@W_Maximum = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS sql_variant),
			@W_IsPrimarykey = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit),
			@W_IsAutoIncrement = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit),
			@W_IsRequired = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit),
			@W_IsListable = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit),
			@W_IsFilterable = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit),
			@W_IsEditable = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit),
			@W_IsBrowseable = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit),
			@W_IsEncrypted = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit),
			@W_IsCalculated = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)
	IF @W_Id IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Id � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Id < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Id deve ser maior que ou igual � ''1''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Id deve ser menor que ou igual � ''9007199254740990''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_TableId IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de TableId � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_TableId < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de TableId deve ser maior que ou igual � ''1''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de TableId deve ser menor que ou igual � ''9007199254740990''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Sequence IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Sequence � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Sequence < CAST('1' AS smallint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Sequence deve ser maior que ou igual � ''1''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Sequence > CAST('32767' AS smallint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Sequence deve ser menor que ou igual � ''32767''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_DomainId IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de DomainId � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_DomainId < CAST('1' AS bigint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de DomainId deve ser maior que ou igual � ''1''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de DomainId deve ser menor que ou igual � ''9007199254740990''.'
		GOTO EXIT_FUNCTION
	END
	IF @W_ReferenceTableId IS NOT NULL BEGIN
		IF @W_ReferenceTableId < CAST('1' AS bigint) BEGIN
			SET @ErrorMessage = @FunctionName + 'Valor de ReferenceTableId deve ser maior que ou igual � ''1''.'
			GOTO EXIT_FUNCTION
		END
		IF @W_ReferenceTableId > CAST('9007199254740990' AS bigint) BEGIN
			SET @ErrorMessage = @FunctionName + 'Valor de ReferenceTableId deve ser menor que ou igual � ''9007199254740990''.'
			GOTO EXIT_FUNCTION
		END
	END
	IF @W_Name IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Name � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Description IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Description � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Title IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Title � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_Caption IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de Caption � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_IsRequired IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de IsRequired � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF @W_IsCalculated IS NULL BEGIN
		SET @ErrorMessage = @FunctionName + 'Valor de IsCalculated � requerido.'
		GOTO EXIT_FUNCTION
	END
	IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id) BEGIN
		SET @ErrorMessage = @FunctionName + 'Chave-prim�ria j� existe na tabela Columns.'
		GOTO EXIT_FUNCTION
	END
	IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name) BEGIN
		SET @ErrorMessage = @FunctionName + 'Chave �nica de �ndice UNQ_Columns_Table_Name j� existe.'
		GOTO EXIT_FUNCTION
	END
	IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence) BEGIN
		SET @ErrorMessage = @FunctionName + 'Chave �nica de �ndice UNQ_Columns_Table_Sequence j� existe.'
		GOTO EXIT_FUNCTION
	END
EXIT_FUNCTION:
	INSERT @result(Record,
				   ErrorMessage)
			VALUES(@ActualRecord,
				   @ErrorMessage)
	RETURN
END
GO
