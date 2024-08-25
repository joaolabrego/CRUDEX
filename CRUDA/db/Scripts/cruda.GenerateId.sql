USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[GenerateId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GenerateId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[GenerateId](@SystemName VARCHAR(25),
								   @DatabaseName VARCHAR(25),
								   @TableName VARCHAR(25)) AS
BEGIN 
	DECLARE @SystemId BIGINT,
			@DatabaseId BIGINT,
			@TableId BIGINT,
			@Next_Id BIGINT,
			@ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @IsNewTransaction BIT = 0
	
	IF @@TRANCOUNT = 0 BEGIN
		BEGIN TRANSACTION GenerateIdTransaction
		SET @IsNewTransaction = 1
	END ELSE
		SAVE TRANSACTION GenerateIdTransaction

	BEGIN TRY
		SELECT @SystemId = [Id]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Sistema ' + @SystemName + ' não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END

		SELECT @DatabaseId = [Id]
			FROM [dbo].[Databases]
			WHERE [Name] = @DatabaseName
		IF @DatabaseId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados ' + @DatabaseName + ' não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END

		IF NOT EXISTS(SELECT 1
						FROM [dbo].[SystemsDatabases]
						WHERE [SystemId] = @SystemId
								AND [DatabaseId] = @DatabaseId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Banco-de-dados ' + @DatabaseName + ' não pertence ao sistema ' + @SystemName + '.';
			THROW 51000, @ErrorMessage, 1
		END

		SELECT @TableId = [Id]
			FROM [dbo].[Tables]
			WHERE [Name] = @TableName
		IF @TableId IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela ' + @TableName + ' não encontrada.';
			THROW 51000, @ErrorMessage, 1
		END

		IF NOT EXISTS(SELECT 1
						FROM [dbo].[DatabasesTables]
						WHERE [DatabaseId] = @DatabaseId
								AND [TableId] = @TableId) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Tabela ' + @TableName + 'não pertence ao banco-de-dados ' + @DatabaseName + '.';
			THROW 51000, @ErrorMessage, 1
		END

		SET @Next_Id = (SELECT [LastId] + 1
							FROM [dbo].[Tables]
							WHERE [Id] = @TableId)
		UPDATE [dbo].[Tables] 
			SET [LastId] = @Next_Id
			WHERE [Id] = @TableId

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @IsNewTransaction = 0
			ROLLBACK TRANSACTION GenerateIdTransaction
		ELSE
			ROLLBACK TRANSACTION
		THROW
	END CATCH
	COMMIT TRANSACTION

	RETURN @Next_Id
END
GO
