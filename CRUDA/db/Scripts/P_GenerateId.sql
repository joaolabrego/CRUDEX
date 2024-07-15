USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[P_GenerateId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_GenerateId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_GenerateId](@SystemName VARCHAR(25),
									 @DatabaseName VARCHAR(25),
									 @TableName VARCHAR(25)) AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @SystemId BIGINT,
				@DatabaseId BIGINT,
				@TableId BIGINT,
				@Next_Id BIGINT,
				@ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '

		IF @@TRANCOUNT = 0 BEGIN
			BEGIN TRANSACTION GenerateIdTransaction
		END ELSE
			SAVE TRANSACTION GenerateIdTransaction
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
							  AND [DatabaseId] = @DatabaseId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados não pertence ao sistema especificado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @TableId = [Id]
			FROM [dbo].[Tables]
			WHERE [Name] = @TableName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não encontrada.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
							  AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela não pertence ao banco-de-dados especificado.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @Next_Id = [LastId] + 1
			FROM [dbo].[Tables]
			WHERE [Id] = @TableId
		UPDATE [dbo].[Tables] 
			SET [LastId] = @Next_Id
			WHERE [Id] = @TableId
		COMMIT TRANSACTION GenerateIdTransaction

		RETURN @Next_Id
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION GenerateIdTransaction;
		THROW
	END CATCH
END
GO