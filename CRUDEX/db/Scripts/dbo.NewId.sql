﻿IF(SELECT object_id('[dbo].[NewId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[NewId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[NewId](@SystemName VARCHAR(25)
							 ,@DatabaseName VARCHAR(25)
							 ,@TableName VARCHAR(25)
							 ,@ReturnValue BIGINT OUT) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId BIGINT
				,@DatabaseId BIGINT
				,@TableId BIGINT
				,@NextId BIGINT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
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
		SELECT @TableId = [Id]
			   ,@NextId = ISNULL([CurrentId], 0) + 1
			FROM [dbo].[Tables]
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
		COMMIT TRANSACTION

		RETURN 0
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