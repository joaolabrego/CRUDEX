USE [cruda]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[ColumnsDelete]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnsDelete] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnsDelete](@Parameters VARCHAR(MAX)) AS 
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		BEGIN TRANSACTION

		DECLARE @ErrorMessage VARCHAR(255)= 'Stored Procedure ColumnsDelete: '

		IF ISJSON(@Parameters) = 0 BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Parâmetros não estão no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END

		DECLARE @Login VARCHAR(MAX) = CAST(JSON_VALUE(@Parameters, '$.Login') AS VARCHAR(MAX))

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
		IF @Action <> 'delete' BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Operação não é de exclusão.';
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

		DECLARE @W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

		IF @W_Id IS NULL BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de Id é requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_Id < CAST('1' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de Id deve ser maior que ou igual à ''1''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @W_Id > CAST('9007199254740990' AS bigint) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Valor de Id deve ser menor que ou igual à ''9007199254740990''.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE Id = @W_Id) BEGIN
			SET @ErrorMessage = @ErrorMessage + 'Chave-primária não existe na tabela Columns.';
			THROW 51000, @ErrorMessage, 1
		END
		DELETE [dbo].[Columns] 
			WHERE [Id] = @W_Id
		UPDATE [dbo].[Operations]
			SET [IsConfirmed] = 1
				,[UpdatedAt] = GETDATE()
				,[UpdatedBy] = @UserName
			WHERE [Id] = @OperationId
		
		COMMIT

		RETURN 0
	END TRY
	BEGIN CATCH

		ROLLBACK

		THROW
	END CATCH
END
