IF(SELECT object_id('[dbo].[NewId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[NewId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[NewId](@SystemName VARCHAR(25)
							 ,@DatabaseName VARCHAR(25)
							 ,@TableName VARCHAR(25)
							 ,@ReturnValue BIGINT OUT) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

		DECLARE @SystemId BIGINT
				,@DatabaseId BIGINT
				,@TableId BIGINT
				,@NextId BIGINT

		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL
			THROW 51000, 'Sistema não encontrado', 1
		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL
			THROW 51000, 'Banco-de-dados não encontrado', 1
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
							  AND [DatabaseId] = @DatabaseId)
			THROW 51000, 'Banco-de-dados não pertence ao sistema especificado', 1

		BEGIN TRANSACTION

		SELECT @TableId = [Id]
			   ,@NextId = ISNULL([CurrentId], 0) + 1
			FROM [dbo].[Tables] WITH (UPDLOCK, HOLDLOCK)
			WHERE [Name] = @TableName
		IF @TableId IS NULL
			THROW 51000, 'Tabela não encontrada', 1
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
							  AND [TableId] = @TableId)
			THROW 51000, 'Tabela não pertence ao banco-de-dados especificado', 1
		UPDATE [dbo].[Tables]
			SET [CurrentId] = @NextId
			WHERE [Id] = @TableId
		SET @ReturnValue = @NextId
		COMMIT
		RETURN 0
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage VARCHAR(MAX) = ERROR_MESSAGE();

		IF @@TRANCOUNT > 0
			ROLLBACK;

        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
