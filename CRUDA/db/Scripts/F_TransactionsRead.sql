USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[F_TransactionsRead]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[F_TransactionsRead]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [dbo].[F_TransactionsRead](@TransactionId BIGINT
										,@Action VARCHAR(15))
RETURNS @result TABLE ([UserName] VARCHAR(25),
						[Record] VARCHAR(MAX),
						[ErrorMessage] VARCHAR(255)) AS
BEGIN
	DECLARE @FunctionName VARCHAR(255) = 'Função ' + (SELECT OBJECT_NAME(@@PROCID)) + ': '
			,@ErrorMessage VARCHAR(255)
			,@LoginId BIGINT
			,@TransactionAction VARCHAR(15)
			,@Record VARCHAR(MAX)
			,@IsConfirmed BIT
			,@UserId BIGINT
			,@Logged BIT
			,@UserName VARCHAR(25)
			,@IsActive BIT

	SELECT @LoginId = [LoginId],
			@TransactionAction = [Action],
			@Record = [Record],
			@IsConfirmed = [IsConfirmed]
		FROM [dbo].[Transactions]
		WHERE [Id] = @TransactionId

	IF @@ROWCOUNT = 0
		SET @ErrorMessage = @FunctionName + 'Transação não existe.'
	ELSE IF @IsConfirmed IS NOT NULL
		SET @ErrorMessage = @FunctionName + 'Transação já finalizada.'
	ELSE IF @Action <> @TransactionAction
		SET @ErrorMessage = @FunctionName + 'Ação solicitada difere da ação registrada na transação.'
	ELSE BEGIN
		SELECT @UserId = [UserId]
				,@Logged = [Logged]
			FROM [dbo].[Logins] WHERE [Id] = @LoginId
			IF @@ROWCOUNT = 0
				SET @ErrorMessage = @FunctionName + 'Login de transação não existe.'
			ELSE IF @Logged = 0 
				SET @ErrorMessage = @FunctionName + 'Login de transação já encerrado.'
			ELSE BEGIN
				SELECT @UserName = [Name]
						,@IsActive = [IsActive]
					FROM [dbo].[Users]
					WHERE [Id] = @UserId
				IF @@ROWCOUNT = 0
					SET @ErrorMessage = @FunctionName + 'Usuário de transação não cadastrado.'
				ELSE IF @IsActive = 0 
					SET @ErrorMessage = @FunctionName + 'Usuário de transação encontra-se inativo.'
			END
	END
	INSERT @result
		VALUES(@UserName
				,@Record
				,@ErrorMessage)
			
	RETURN
END
