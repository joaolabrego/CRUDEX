USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('ColumnsRead', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnsRead] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsRead](@Parameters VARCHAR(MAX)) AS BEGIN

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255)= 'Stored Procedure ColumnsDelete: '
				,@Login VARCHAR(MAX)

		IF ISJSON(@Parameters) = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END
		SET @Login = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))
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
		IF @Action <> 'read' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação não é de leitura.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação já ' + 
								CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
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
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação não cadastrada.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsConfirmed IS NOT NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Transação já ' + 
								CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END + '.';
			THROW 51000, @ErrorMessage, 1
		END
		IF (SELECT [Name]
				FROM [dbo].[Systems]
				WHERE [Id] = @SystemId) <> @SystemName BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Nome de sistema inválido para a transação.';
			THROW 51000, @ErrorMessage, 1
		END
		IF (SELECT [Name] 
				FROM [dbo].[Databases]
				WHERE [Id] = @DatabaseId) <> @DatabaseName BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Nome de banco-de-dados inválido para a transação.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1 
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId 
							  AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @PageNumber INT --OUT
				,@LimitRows BIGINT --OUT
				,@MaxPage INT --OUT
				,@PaddingGridLastPage BIT --OUT
				,@RowCount BIGINT
				,@LoginId BIGINT
				,@OffSet INT

		DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)
				,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
				,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
				,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
				,@W_Name varchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS varchar(25))
				,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
				,@W_IsRequired bit = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
				,@W_IsListable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
				,@W_IsFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
				,@W_IsEditable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
				,@W_IsBrowseable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsBrowseable') AS bit)
				,@W_IsEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
				,@W_IsCalculated bit = CAST(JSON_VALUE(@ActualRecord, '$.IsCalculated') AS bit)

		IF @W_Id IS NOT NULL AND @W_Id < CAST('1' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser maior que ou igual à ''1''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_Id IS NOT NULL AND @W_Id > CAST('9007199254740990' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @Id deve ser menor que ou igual à ''9007199254740990''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_TableId IS NOT NULL AND @W_TableId < CAST('1' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser maior que ou igual à ''1''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_TableId IS NOT NULL AND @W_TableId > CAST('9007199254740990' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @TableId deve ser menor que ou igual à ''9007199254740990''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_DomainId IS NOT NULL AND @W_DomainId < CAST('1' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser maior que ou igual à ''1''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_DomainId IS NOT NULL AND @W_DomainId > CAST('9007199254740990' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @DomainId deve ser menor que ou igual à ''9007199254740990''.';
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
		SELECT [Action] AS [_]
				,CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) AS [Id]
				,CAST(JSON_VALUE([ActualRecord], '$.TableId') AS bigint) AS [TableId]
				,CAST(JSON_VALUE([ActualRecord], '$.Sequence') AS smallint) AS [Sequence]
				,CAST(JSON_VALUE([ActualRecord], '$.DomainId') AS bigint) AS [DomainId]
				,CAST(JSON_VALUE([ActualRecord], '$.ReferenceTableId') AS bigint) AS [ReferenceTableId]
				,CAST(JSON_VALUE([ActualRecord], '$.Name') AS varchar(25)) AS [Name]
				,CAST(JSON_VALUE([ActualRecord], '$.Description') AS varchar(50)) AS [Description]
				,CAST(JSON_VALUE([ActualRecord], '$.Title') AS varchar(25)) AS [Title]
				,CAST(JSON_VALUE([ActualRecord], '$.Caption') AS varchar(25)) AS [Caption]
				,CAST(JSON_VALUE([ActualRecord], '$.ValidValues') AS varchar(25)) AS [ValidValues]
				,CAST(JSON_VALUE([ActualRecord], '$.Default') AS sql_variant) AS [Default]
				,CAST(JSON_VALUE([ActualRecord], '$.Minimum') AS sql_variant) AS [Minimum]
				,CAST(JSON_VALUE([ActualRecord], '$.Maximum') AS sql_variant) AS [Maximum]
				,CAST(JSON_VALUE([ActualRecord], '$.IsPrimarykey') AS bit) AS [IsPrimarykey]
				,CAST(JSON_VALUE([ActualRecord], '$.IsAutoIncrement') AS bit) AS [IsAutoIncrement]
				,CAST(JSON_VALUE([ActualRecord], '$.IsRequired') AS bit) AS [IsRequired]
				,CAST(JSON_VALUE([ActualRecord], '$.IsListable') AS bit) AS [IsListable]
				,CAST(JSON_VALUE([ActualRecord], '$.IsFilterable') AS bit) AS [IsFilterable]
				,CAST(JSON_VALUE([ActualRecord], '$.IsEditable') AS bit) AS [IsEditable]
				,CAST(JSON_VALUE([ActualRecord], '$.IsBrowseable') AS bit) AS [IsBrowseable]
				,CAST(JSON_VALUE([ActualRecord], '$.IsEncrypted') AS bit) AS [IsEncrypted]
				,CAST(JSON_VALUE([ActualRecord], '$.IsCalculated') AS bit) AS [IsCalculated]
			INTO [dbo].[#Operations]
			FROM [dbo].[Operations]
			WHERE [TransactionId] = @TransactionId
					AND [TableId] = @TableId
					AND [IsConfirmed] IS NULL
		CREATE INDEX [#IDX_Operations] ON [dbo].[#Operations]([_], [Id])

		SELECT 	[Id]
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
			INTO[dbo].[#Columns]
			FROM[dbo].[Columns]
			WHERE [Id] = ISNULL(@W_Id, [Id])
					AND [TableId] = ISNULL(@W_TableId, [TableId])
					AND [DomainId] = ISNULL(@W_DomainId, [DomainId])
					AND (@W_ReferenceTableId IS NULL OR [ReferenceTableId] = @W_ReferenceTableId)
					AND [Name] = ISNULL(@W_Name, [Name])
					AND (@W_IsAutoIncrement IS NULL OR [IsAutoIncrement] = @W_IsAutoIncrement)
					AND [IsRequired] = ISNULL(@W_IsRequired, [IsRequired])
					AND (@W_IsListable IS NULL OR [IsListable] = @W_IsListable)
					AND (@W_IsFilterable IS NULL OR [IsFilterable] = @W_IsFilterable)
					AND (@W_IsEditable IS NULL OR [IsEditable] = @W_IsEditable)
					AND (@W_IsBrowseable IS NULL OR [IsBrowseable] = @W_IsBrowseable)
					AND (@W_IsEncrypted IS NULL OR [IsEncrypted] = @W_IsEncrypted)
					AND [IsCalculated] = ISNULL(@W_IsCalculated, [IsCalculated])
			ORDER BY [Id]
		SET @RowCount = @@ROWCOUNT
		DELETE [Columns] 
			FROM [dbo].[#Operations] [Operations]
				INNER JOIN [dbo].[#Columns] [Columns] ON [Operations].[_] = 'delete' 
														 AND [Columns].[Id] = [Operations].[Id]
		SET @RowCount = @RowCount - @@ROWCOUNT
		INSERT [dbo].[#Columns] 
			SELECT [Id] 
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
				FROM [dbo].[#Operations]
				WHERE [_] = 'create'
		SET @RowCount = @RowCount + @@ROWCOUNT
		UPDATE [Columns] 
			SET [Columns].[Id] = [Operations].[Id]
				,[Columns].[TableId] = [Operations].[TableId]
				,[Columns].[Sequence] = [Operations].[Sequence]
				,[Columns].[DomainId] = [Operations].[DomainId]
				,[Columns].[ReferenceTableId] = [Operations].[ReferenceTableId]
				,[Columns].[Name] = [Operations].[Name]
				,[Columns].[Description] = [Operations].[Description]
				,[Columns].[Title] = [Operations].[Title]
				,[Columns].[Caption] = [Operations].[Caption]
				,[Columns].[ValidValues] = [Operations].[ValidValues]
				,[Columns].[Default] = [Operations].[Default]
				,[Columns].[Minimum] = [Operations].[Minimum]
				,[Columns].[Maximum] = [Operations].[Maximum]
				,[Columns].[IsPrimarykey] = [Operations].[IsPrimarykey]
				,[Columns].[IsAutoIncrement] = [Operations].[IsAutoIncrement]
				,[Columns].[IsRequired] = [Operations].[IsRequired]
				,[Columns].[IsListable] = [Operations].[IsListable]
				,[Columns].[IsFilterable] = [Operations].[IsFilterable]
				,[Columns].[IsEditable] = [Operations].[IsEditable]
				,[Columns].[IsBrowseable] = [Operations].[IsBrowseable]
				,[Columns].[IsEncrypted] = [Operations].[IsEncrypted]
				,[Columns].[IsCalculated] = [Operations].[IsCalculated]
			FROM [dbo].[#Operations] [Operations]
				INNER JOIN [dbo].[#Columns] [Columns] ON [tmp].[_] = 'update' 
														 AND [Columns].[Id] = [Operations].[Id] 
		IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
			SET @OffSet = 0
			SET @LimitRows = CASE WHEN @RowCount = 0 
								  THEN 1 
								  ELSE @RowCount 
							 END
			SET @PageNumber = 1
			SET @MaxPage = 1
		END ELSE BEGIN
			SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END
			IF ABS(@PageNumber) > @MaxPage
				SET @PageNumber = CASE WHEN @PageNumber < 0 
									   THEN -@MaxPage 
									   ELSE @MaxPage 
								  END
			IF @PageNumber < 0
				SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
			SET @OffSet = (@PageNumber - 1) * @LimitRows
			IF @PaddingGridLastPage = 1 AND @OffSet + @LimitRows > @RowCount
				SET @OffSet = CASE WHEN @RowCount > @LimitRows
								   THEN @RowCount - @LimitRows
								   ELSE 0 
							  END
		END
		SELECT 'RecordColumn' AS [ClassName]
				,[Id]
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
			FROM[dbo].[#Columns] 
			ORDER BY [Id]
				OFFSET @OffSet ROWS
				FETCH NEXT @LimitRows ROWS ONLY

		RETURN @RowCount
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
