USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[P_Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[P_Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[P_Login](@Parameters VARCHAR(MAX)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION P_Login
		ELSE
			SAVE TRANSACTION P_Login

		DECLARE @ErrorMessage VARCHAR(256)

		IF ISJSON(@Parameters) = 0 BEGIN
			SET @ErrorMessage = 'Parâmetro login não está no formato JSON.';
			THROW 51000, @ErrorMessage, 1
		END
	
		DECLARE	@Action VARCHAR(15) = CAST(JSON_VALUE(@Parameters, '$.Action') AS VARCHAR(15))
				,@LoginId BIGINT = CAST(JSON_VALUE(@Parameters, '$.LoginId') AS BIGINT)
				,@SystemName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.SystemName') AS VARCHAR(25))
				,@UserName VARCHAR(25) = CAST(JSON_VALUE(@Parameters, '$.UserName') AS VARCHAR(25))
				,@Password VARCHAR(256) = CAST(JSON_VALUE(@Parameters, '$.Password') AS VARCHAR(256))
				,@PublicKey VARCHAR(256) = CAST(JSON_VALUE(@Parameters, '$.PublicKey') AS VARCHAR(256))
				,@PasswordAux VARCHAR(256)
				,@SystemId BIGINT
				,@SystemIdAux BIGINT
				,@UserId BIGINT
				,@UserIdAux BIGINT
				,@MaxRetryLogins TINYINT
				,@RetryLogins TINYINT
				,@IsLogged BIT
				,@IsActive BIT
	
		IF @Action IS NULL BEGIN
			SET @ErrorMessage = 'Ação de login requerida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action NOT IN ('login','logout','authenticate') BEGIN
			SET @ErrorMessage = 'Ação de login inválida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemName IS NULL BEGIN
			SET @ErrorMessage = 'Sistema requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @SystemId = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = 'Sistema não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName IS NULL BEGIN
			SET @ErrorMessage = 'Usuário requerido.';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @UserId IS NULL BEGIN
			SET @ErrorMessage = 'Usuário não cadastrado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário inativo.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário bloqueado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado.';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Password IS NULL BEGIN
			SET @ErrorMessage = 'Senha requerida.';
			THROW 51000, @ErrorMessage, 1
		END
		IF CAST(@PasswordAux AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			SET @RetryLogins = @RetryLogins + 1
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = @RetryLogins
				WHERE [Id] = @UserId
			SET @ErrorMessage = 'Senha inválida (' + CAST(@MaxRetryLogins -  @RetryLogins AS VARCHAR(3)) + ' tentativas restantes).';
			THROW 51000, @ErrorMessage, 1
		END
		IF @action = 'login' BEGIN
			IF @PublicKey IS NULL BEGIN
				SET @ErrorMessage = 'Chave pública requerida.';
				THROW 51000, @ErrorMessage, 1
			END
			EXEC @LoginId = [dbo].[P_GenerateId] 'cruda', 'cruda', 'Logins'
			INSERT [dbo].[Logins]([Id],
								  [SystemId],
								  [UserId],
								  [PublicKey],
								  [IsLogged],
								  [CreatedAt],
								  [CreatedBy])
						  VALUES (@LoginId,
								  @SystemId,
								  @UserId,
								  @PublicKey,
								  1,
								  GETDATE(),
								  @UserName)
		END ELSE IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = 'Id de login requerido.';
			THROW 51000, @ErrorMessage, 1
		END ELSE BEGIN
			SELECT @SystemIdAux = [SystemId],
				   @UserIdAux = [UserId],
				   @IsLogged = [IsLogged]
				FROM [dbo].[Logins]
				WHERE [Id] = @LoginId
			IF @SystemIdAux IS NULL BEGIN
				SET @ErrorMessage = 'Login não cadastrado.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @SystemId <> @SystemIdAux BEGIN
				SET @ErrorMessage = 'Sistema inválido para este login.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @UserId <> @UserIdAux BEGIN
				SET @ErrorMessage = 'Usuário inválido para este login.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @IsLogged = 0 BEGIN
				SET @ErrorMessage = 'Login já encerrado.';
				THROW 51000, @ErrorMessage, 1
			END
			IF @action = 'logout'
				UPDATE [dbo].[Logins]
					SET [IsLogged] = 0,
						[UpdatedAt] = GETDATE(),
						[UpdatedBy] = @UserName
					WHERE [Id] = @LoginId
		END
		UPDATE [dbo].[Users]
			SET [RetryLogins] = 0
			WHERE [Id] = @UserId
		COMMIT TRANSACTION P_Login

		RETURN @LoginId
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION P_Login;
		THROW
	END CATCH
END
GO