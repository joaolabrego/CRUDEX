IF(SELECT object_id('[dbo].[NewOperationId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[NewOperationId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[NewOperationId](@SystemName VARCHAR(25)
									  ,@DatabaseName VARCHAR(25)
									  ,@ReturnValue BIGINT OUT) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId BIGINT
				,@DatabaseId BIGINT
				,@NexOperationtId BIGINT

		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL
			THROW 51000, 'Sistema não encontrado', 1
		SELECT @DatabaseId = [Id]
				,@NexOperationtId = ISNULL([CurrentOperationId], 0) + 1
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL
			THROW 51000, 'Banco-de-dados não encontrado', 1
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
							  AND [DatabaseId] = @DatabaseId)
			THROW 51000, 'Banco-de-dados não pertence ao sistema especificado', 1
		UPDATE [dbo].[Databases] 
			SET [CurrentOperationId] = @NexOperationtId
			WHERE [Id] = @DatabaseId
		SET @ReturnValue = @NexOperationtId

		RETURN 0
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage VARCHAR(MAX) = ERROR_MESSAGE();

        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
