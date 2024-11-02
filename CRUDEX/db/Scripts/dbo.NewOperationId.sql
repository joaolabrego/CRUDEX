IF(SELECT object_id('[dbo].[NewOperationId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[NewOperationId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[NewOperationId](@SystemName VARCHAR(25)
									  ,@DatabaseName VARCHAR(25)) AS
BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId INT
				,@DatabaseId INT
				,@NexOperationtId INT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL
			THROW 51000, 'Sistema n�o encontrado', 1
		SELECT @DatabaseId = [Id]
				,@NexOperationtId = ISNULL([CurrentOperationId], 0) + 1
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL
			THROW 51000, 'Banco-de-dados n�o encontrado', 1
		UPDATE [dbo].[Databases] 
			SET [CurrentOperationId] = @NexOperationtId
			WHERE [Id] = @DatabaseId
		COMMIT TRANSACTION

		RETURN @NexOperationtId
	END TRY
	BEGIN CATCH
        IF @@TRANCOUNT > @TRANCOUNT BEGIN
            ROLLBACK TRANSACTION [SavePoint];
            COMMIT TRANSACTION
        END
        SET @ErrorMessage = '[' + ERROR_PROCEDURE() + ']: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
