USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[Login] 'cruda','labrego','diva','authenticate'
IF(SELECT object_id('[dbo].[Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[Login](@SystemName VARCHAR(25)
							 ,@UserName VARCHAR(25)
							 ,@Password VARCHAR(256)
							 ,@Action VARCHAR(15) = 'authenticate') AS
BEGIN
	DECLARE @SystemId BIGINT,
			@UserId BIGINT,
			@UserPassword VARCHAR(256),
			@ErrorMessage VARCHAR(100),
			@MaxRetryLogins TINYINT,
			@RetryLogins TINYINT,
			@IsActive BIT,
			@LogId BIGINT

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRY
		-- 0 [Systems]
		SELECT 	@SystemId = [Id]
				,@MaxRetryLogins = [MaxRetryLogins]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END

		-- 1 [Users]
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@UserPassword = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Usuário não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END

		IF CAST(@UserPassword AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = [RetryLogins] + 1
				WHERE [Id] = @UserId 
						AND @RetryLogins < @MaxRetryLogins
			SET @ErrorMessage = 'Senha inválida';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário inativo';
			THROW 51000, @ErrorMessage, 1
		END
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário bloqueado';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE	[UserId] =  @UserId
								AND [SystemId] = @SystemId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado';
			THROW 51000, @ErrorMessage, 1
		END
		
		SELECT @LogId = [Id]
			FROM [dbo].[Logins]
			WHERE [SystemId] = @SystemId
				  AND [UserId] = @UserId
				  AND [Logged] = 1
		IF @LogId IS NULL BEGIN
			IF @action = 'login' BEGIN
				EXEC @LogId = [dbo].[GenerateId] 'cruda', 'cruda', 'Logs'

				INSERT [dbo].[Logins]([Id],
									[SystemId],
									[UserId],
									[Logged],
									[CreatedAt],
									[CreatedBy])
							VALUES (@LogId,
									@SystemId,
									@UserId,
									1,
									GETDATE(),
									@UserName)
			END ELSE IF @action <> 'logout' BEGIN
				SET @ErrorMessage = 'Instância do sistema foi encerrada.';
				THROW 51000, @ErrorMessage, 1
			END
		END ELSE IF @action = 'login' BEGIN
			SET @ErrorMessage = 'Usuário já tem uma instância do sistema em execução.';
			THROW 51000, @ErrorMessage, 1
		END ELSE IF @action = 'logout' BEGIN
			UPDATE [dbo].[Logins]
				SET [Logged] = 0,
					[UpdatedAt] = GETDATE(),
					[UpdatedBy] = @UserName
				WHERE [Id] = @LogId
			RETURN @LogId
		END ELSE IF @action <> 'authenticate' BEGIN
			SET @ErrorMessage = 'Valor inválido para o parâmetro @Action.';
			THROW 51000, @ErrorMessage, 1
		END
		UPDATE [dbo].[Users] 
			SET [RetryLogins] = 0
			WHERE [Id] = @UserId

		SELECT [Id]
				,[Name]
				,[FullName]
			FROM [dbo].[Users] 
			WHERE [Id] = @UserId

		RETURN @LogId
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
GO
