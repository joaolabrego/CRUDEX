IF(SELECT object_id('[cruda].[ColumnsRead]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[ColumnsRead] AS PRINT 1')
GO
ALTER PROCEDURE[cruda].[ColumnsRead](@LoginId BIGINT
									,@Parameters VARCHAR(MAX)
									,@PageNumber INT OUT
									,@LimitRows BIGINT OUT
									,@MaxPage INT OUT
									,@PaddingBrowseLastPage BIT OUT) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure ColumnsRead: '

		IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @LoginId é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Parameters IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @Parameters é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		IF ISJSON(@ActualRecord) = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de @Parameters não está no formato JSON';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @TransactionId INT = ISNULL((SELECT MAX([Id]) FROM [cruda].[Transactions] WHERE [LoginId] = @LoginId), 0)
				,@W_Id bigint = CAST(JSON_VALUE(@Parameters, '$.Id') AS bigint)
				,@W_TableId bigint = CAST(JSON_VALUE(@Parameters, '$.TableId') AS bigint)
				,@W_DomainId bigint = CAST(JSON_VALUE(@Parameters, '$.DomainId') AS bigint)
				,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@Parameters, '$.ReferenceTableId') AS bigint)
				,@W_Name varchar(25) = CAST(JSON_VALUE(@Parameters, '$.Name') AS varchar(25))
				,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@Parameters, '$.IsAutoIncrement') AS bit)
				,@W_IsRequired bit = CAST(JSON_VALUE(@Parameters, '$.IsRequired') AS bit)
				,@W_IsListable bit = CAST(JSON_VALUE(@Parameters, '$.IsListable') AS bit)
				,@W_IsFilterable bit = CAST(JSON_VALUE(@Parameters, '$.IsFilterable') AS bit)
				,@W_IsEditable bit = CAST(JSON_VALUE(@Parameters, '$.IsEditable') AS bit)
				,@W_IsBrowseable bit = CAST(JSON_VALUE(@Parameters, '$.IsBrowseable') AS bit)
				,@W_IsEncrypted bit = CAST(JSON_VALUE(@Parameters, '$.IsEncrypted') AS bit)
				,@W_IsCalculated bit = CAST(JSON_VALUE(@Parameters, '$.IsCalculated') AS bit)

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

		DECLARE @RowCount BIGINT
				,@OffSet INT

		SELECT [Id]
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
			INTO[dbo].[#tmp]
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
		DELETE [tmp] 
			FROM [dbo].[#tmp]
			WHERE EXISTS(SELECT 1
							FROM [dbo].[Operations] [ope]
							WHERE [ope].[TransactionId] = @TransactionId
								  AND [ope].[TableName] = 'Columns'
								  AND [ope].[IsConfirmed] IS NULL
								  AND [ope].[Action] = 'delete'
								  AND CAST(JSON_VALUE([ope].[ActualRecord], '$.Id') AS bigint) = [tmp].[Id])
		SET @RowCount = @RowCount - @@ROWCOUNT
		INSERT [dbo].[#tmp] SELECT CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) AS [Id]
									,CAST(JSON_VALUE([ActualRecord], '$.TableId') AS bigint) AS [TableId]
									,CAST(JSON_VALUE([ActualRecord], '$.Sequence') AS smallint) AS [Sequence]
									,CAST(JSON_VALUE([ActualRecord], '$.DomainId') AS bigint) AS [DomainId]
									,CAST(JSON_VALUE([ActualRecord], '$.ReferenceTableId') AS bigint) AS [ReferenceTableId]
									,CAST(JSON_VALUE([ActualRecord], '$.Name') AS varchar(25)) AS [Name]
									,CAST(JSON_VALUE([ActualRecord], '$.Description') AS varchar(50)) AS [Description]
									,CAST(JSON_VALUE([ActualRecord], '$.Title') AS varchar(25)) AS [Title]
									,CAST(JSON_VALUE([ActualRecord], '$.Caption') AS varchar(25)) AS [Caption]
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
								FROM [dbo].[Operations]
								WHERE [TransactionId] = @TransactionId
									  AND [TableName] = 'Columns'
									  AND [IsConfirmed] IS NULL
									  AND [Action] = 'create'
		SET @RowCount = @RowCount + @@ROWCOUNT
		UPDATE [tmp]
			SET [Id] = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
				,[TableId] = CAST(JSON_VALUE([ActualRecord], '$.TableId') AS bigint)
				,[Sequence] = CAST(JSON_VALUE([ActualRecord], '$.Sequence') AS smallint)
				,[DomainId] = CAST(JSON_VALUE([ActualRecord], '$.DomainId') AS bigint)
				,[ReferenceTableId] = CAST(JSON_VALUE([ActualRecord], '$.ReferenceTableId') AS bigint)
				,[Name] = CAST(JSON_VALUE([ActualRecord], '$.Name') AS varchar(25))
				,[Description] = CAST(JSON_VALUE([ActualRecord], '$.Description') AS varchar(50))
				,[Title] = CAST(JSON_VALUE([ActualRecord], '$.Title') AS varchar(25))
				,[Caption] = CAST(JSON_VALUE([ActualRecord], '$.Caption') AS varchar(25))
				,[Default] = CAST(JSON_VALUE([ActualRecord], '$.Default') AS sql_variant)
				,[Minimum] = CAST(JSON_VALUE([ActualRecord], '$.Minimum') AS sql_variant)
				,[Maximum] = CAST(JSON_VALUE([ActualRecord], '$.Maximum') AS sql_variant)
				,[IsPrimarykey] = CAST(JSON_VALUE([ActualRecord], '$.IsPrimarykey') AS bit)
				,[IsAutoIncrement] = CAST(JSON_VALUE([ActualRecord], '$.IsAutoIncrement') AS bit)
				,[IsRequired] = CAST(JSON_VALUE([ActualRecord], '$.IsRequired') AS bit)
				,[IsListable] = CAST(JSON_VALUE([ActualRecord], '$.IsListable') AS bit)
				,[IsFilterable] = CAST(JSON_VALUE([ActualRecord], '$.IsFilterable') AS bit)
				,[IsEditable] = CAST(JSON_VALUE([ActualRecord], '$.IsEditable') AS bit)
				,[IsBrowseable] = CAST(JSON_VALUE([ActualRecord], '$.IsBrowseable') AS bit)
				,[IsEncrypted] = CAST(JSON_VALUE([ActualRecord], '$.IsEncrypted') AS bit)
				,[IsCalculated] = CAST(JSON_VALUE([ActualRecord], '$.IsCalculated') AS bit)
			FROM [dbo].[#tmp] 
			WHERE EXISTS(SELECT 1
							FROM [dbo].[Operations] [ope]
							WHERE [TransactionId] = @TransactionId
								  AND [ope].[TableName] = 'Columns'
								  AND [ope].[IsConfirmed] IS NULL
								  AND [ope].[Action] = 'update'
								  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = [tmp].[Id])
		IF @RowCount = 0 OR ISNULL(@PageNumber, 0) = 0 OR ISNULL(@LimitRows, 0) <= 0 BEGIN
			SET @offset = 0
			SET @LimitRows = CASE WHEN @RowCount = 0 THEN 1 ELSE @RowCount END
			SET @PageNumber = 1
			SET @MaxPage = 1
		END ELSE BEGIN
			SET @MaxPage = @RowCount / @LimitRows + CASE WHEN @RowCount % @LimitRows = 0 THEN 0 ELSE 1 END
			IF ABS(@PageNumber) > @MaxPage
				SET @PageNumber = CASE WHEN @PageNumber < 0 THEN -@MaxPage ELSE @MaxPage END
			IF @PageNumber < 0
				SET @PageNumber = @MaxPage - ABS(@PageNumber) + 1
			SET @offset = (@PageNumber - 1) * @LimitRows
			IF @PaddingBrowseLastPage = 1 AND @offset + @LimitRows > @RowCount
				SET @offset = CASE WHEN @RowCount > @LimitRows THEN @RowCount -@LimitRows ELSE 0 END
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
		FROM [dbo].[#tmp] 
		ORDER BY [Id]
		OFFSET @offset ROWS
		FETCH NEXT @LimitRows ROWS ONLY
		RETURN @RowCount
	END TRY
	BEGIN CATCH
	THROW
	END CATCH
END
GO
