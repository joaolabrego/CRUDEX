USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dbo].[P_Login] 'cruda','labrego','diva','authenticate'
IF(SELECT object_id('[dbo].[P_Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_Login](@Login VARCHAR(MAX)) AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		IF @@TRANCOUNT = 0 BEGIN
			BEGIN TRANSACTION P_Login
		END ELSE
			SAVE TRANSACTION P_Login

		DECLARE @ErrorMessage VARCHAR(256)

		IF ISJSON(@Login) = 1 BEGIN
			SET @ErrorMessage = 'Parâmetro Login não está no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END
	
		DECLARE @LoginId BIGINT = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
			   ,@SystemName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.SystemName') AS VARCHAR(25))
			   ,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS VARCHAR(25))
			   ,@Password VARCHAR(256) = CAST(JSON_VALUE(@Login, '$.Password') AS VARCHAR(256))
			   ,@Action VARCHAR(15) = CAST(JSON_VALUE(@Login, '$.Action') AS VARCHAR(15))
			   ,@PasswordAux VARCHAR(256)
			   ,@SystemId BIGINT
			   ,@SystemIdAux BIGINT
			   ,@UserId BIGINT
			   ,@UserIdAux BIGINT
			   ,@MaxRetryLogins TINYINT
			   ,@RetryLogins TINYINT
			   ,@IsLogged BIT
			   ,@IsActive BIT
	
		IF @Action NOT IN ('login','logout','authenticate') BEGIN
			SET @ErrorMessage = 'Ação de login inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @LoginId IS NULL AND @Action <> 'login' BEGIN
			SET @ErrorMessage = 'Id de login requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @SystemId = [SystemId],
			   @UserId = [UserId],
			   @IsLogged = [IsLogged],
			   @PasswordAux = [Password]
			FROM [dbo].[Logins]
			WHERE [Id] = @LoginId
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário bloqueado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário inativo.';
			THROW 51000, @ErrorMessage, 1
		END
		IF CAST(@PasswordAux AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = [RetryLogins] + 1
				WHERE [Id] = @UserId 
						AND @RetryLogins < @MaxRetryLogins
			SET @ErrorMessage = 'Senha inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 0 [Systems]
		SELECT @SystemIdAux = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @@ROWCOUNT = 0 BEGIN
			SET @ErrorMessage = 'Sistema não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemIdAux <> @SystemId BEGIN
			SET @ErrorMessage = 'Sistema inválido.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 1 [Users]
		SELECT	@UserIdAux = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @@ROWCOUNT =0 BEGIN
			SET @ErrorMessage = 'Usuário não encontrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserIdAux <> @UserId BEGIN
			SET @ErrorMessage = 'Usuário inválido.';
			THROW 51000, @ErrorMessage, 1
		END
		-- 2 [SystemsUsers]
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @action = 'login' BEGIN
			EXEC @LoginId = [dbo].[P_GenerateId] 'cruda', 'cruda', 'Logins'
			INSERT [dbo].[Logins]([Id],
								  [SystemId],
								  [UserId],
								  [IsLogged],
								  [CreatedAt],
								  [CreatedBy])
						  VALUES (@LoginId,
								  @SystemId,
								  @UserId,
								  1,
								  GETDATE(),
								  @UserName)
		END ELSE IF @action = 'logout' BEGIN
			UPDATE [dbo].[Logins]
				SET [IsLogged] = 0,
					[UpdatedAt] = GETDATE(),
					[UpdatedBy] = @UserName
				WHERE [Id] = @LoginId
		END ELSE BEGIN
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = 0
				WHERE [Id] = @UserId
			SELECT [Id]
				  ,[Name]
				  ,[FullName]
				FROM [dbo].[Users] 
				WHERE [Id] = @UserId
		END
		COMMIT TRANSACTION P_Login

		RETURN @LoginId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION P_Login;
		THROW
	END CATCH
END
GO