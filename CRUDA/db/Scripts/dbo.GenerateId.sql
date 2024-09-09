IF(SELECT object_id('[dbo].[GenerateId]','P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GenerateId] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[GenerateId](@SystemName VARCHAR(25)
								  ,@DatabaseName VARCHAR(25)
								  ,@TableName VARCHAR(25)) AS
BEGIN
	DECLARE @TranCount INT = @@TRANCOUNT

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		DECLARE @ErrorMessage VARCHAR(255) = 'Stored Procedure GenerateId: '
				,@SystemId BIGINT
				,@DatabaseId BIGINT
				,@TableId BIGINT
				,@NextId BIGINT

		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]
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
			SET [CurrentId] = @NextId
			WHERE [Id] = @TableId
		COMMIT TRANSACTION

		RETURN @NextId
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > @TranCount BEGIN
			ROLLBACK TRANSACTION [SavePoint]
			COMMIT TRANSACTION
		END;
		THROW
	END CATCH
END
GO
