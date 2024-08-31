USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[GenerateId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GenerateId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[GenerateId](@SystemName VARCHAR(25)
								  ,@DatabaseName VARCHAR(25)
								  ,@TableName VARCHAR(25)) AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId BIGINT,
				@DatabaseId BIGINT,
				@TableId BIGINT,
				@NextId BIGINT,
				@ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '

		IF @@TRANCOUNT = 0 BEGIN
			BEGIN TRANSACTION GenerateId
		END ELSE
			SAVE TRANSACTION GenerateId
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema não encontrado';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não encontrado';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
							  AND [DatabaseId] = @DatabaseId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não pertence ao sistema especificado';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TableId = [Id]
			   ,@NextId = [CurrentId] + 1
			FROM [dbo].[Tables]
			WHERE [Name] = @TableName
		IF @TableId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não encontrada';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
							  AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado';
			THROW 51000, @ErrorMessage, 1
		END
		UPDATE [dbo].[Tables] 
			SET [LastId] = @NextId
			WHERE [Id] = @TableId
		COMMIT TRANSACTION GenerateId

		RETURN @NextId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION GenerateId;
		THROW
	END CATCH
END
GO