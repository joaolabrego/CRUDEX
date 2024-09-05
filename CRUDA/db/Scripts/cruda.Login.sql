USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[cruda].[P_Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [cruda].[P_Login] AS PRINT 1')
GO
ALTER PROCEDURE [cruda].[P_Login](@Parameters VARCHAR(MAX)) AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		IF @@TRANCOUNT = 0
			BEGIN TRANSACTION P_Login
		ELSE
			SAVE TRANSACTION P_Login

		DECLARE @ErrorMessage VARCHAR(256)

		IF ISJSON(@Parameters) = 0 BEGIN
			SET @ErrorMessage = 'Parâmetro login não está no formato JSON';
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
				,@IsOffAir BIT
	
		IF @Action IS NULL BEGIN
			SET @ErrorMessage = 'Ação de login é requerida';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Action NOT IN ('login','logout','authenticate') BEGIN
			SET @ErrorMessage = 'Ação de login é inválida';
			THROW 51000, @ErrorMessage, 1
		END
		IF @SystemName IS NULL BEGIN
			SET @ErrorMessage = 'Sistema é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT @SystemId = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			   ,@IsOffAir = [IsOffAir]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL BEGIN
			SET @ErrorMessage = 'Sistema não cadastrado';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsOffAir = 1 BEGIN
			SET @ErrorMessage = 'Sistema fora do ar';
			THROW 51000, @ErrorMessage, 1
		END
		IF @UserName IS NULL BEGIN
			SET @ErrorMessage = 'Usuário é requerido';
			THROW 51000, @ErrorMessage, 1
		END
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @UserId IS NULL BEGIN
			SET @ErrorMessage = 'Usuário não cadastrado';
			THROW 51000, @ErrorMessage, 1
		END
		IF @IsActive = 0 BEGIN
			SET @ErrorMessage = 'Usuário está inativo';
			THROW 51000, @ErrorMessage, 1
		END
		IF @RetryLogins >= @MaxRetryLogins BEGIN
			SET @ErrorMessage = 'Usuário está bloqueado';
			THROW 51000, @ErrorMessage, 1
		END
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers] [SU]
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId) BEGIN
			SET @ErrorMessage = 'Usuário não autorizado';
			THROW 51000, @ErrorMessage, 1
		END
		IF @Password IS NULL BEGIN
			SET @ErrorMessage = 'Senha é requerida';
			THROW 51000, @ErrorMessage, 1
		END
		IF CAST(@PasswordAux AS VARBINARY(MAX)) <> CAST(@Password AS VARBINARY(MAX)) BEGIN
			SET @RetryLogins = @RetryLogins + 1
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = @RetryLogins
				WHERE [Id] = @UserId
			SET @ErrorMessage = 'Senha é inválida (' + CAST(@MaxRetryLogins -  @RetryLogins AS VARCHAR(3)) + ' tentativas restantes)';
			THROW 51000, @ErrorMessage, 1
		END
		IF @action = 'login' BEGIN
			IF @PublicKey IS NULL BEGIN
				SET @ErrorMessage = 'Chave pública é requerida';
				THROW 51000, @ErrorMessage, 1
			END
			SELECT @LoginId = MAX([Id]) + 1 FROM [dbo].[Logins]
			INSERT [dbo].[Logins]([Id],
								  [SystemId],
								  [UserId],
								  [PublicKey],
								  [IsLogged],
								  [CreatedAt],
								  [CreatedBy])
						  VALUES (ISNULL(@LoginId, 1),
								  @SystemId,
								  @UserId,
								  @PublicKey,
								  1,
								  GETDATE(),
								  @UserName)
		END ELSE IF @LoginId IS NULL BEGIN
			SET @ErrorMessage = 'Id de login é requerido';
			THROW 51000, @ErrorMessage, 1
		END ELSE BEGIN
			SELECT @SystemIdAux = [SystemId],
				   @UserIdAux = [UserId],
				   @IsLogged = [IsLogged]
				FROM [dbo].[Logins]
				WHERE [Id] = @LoginId
			IF @SystemIdAux IS NULL BEGIN
				SET @ErrorMessage = 'Login não cadastrado';
				THROW 51000, @ErrorMessage, 1
			END
			IF @SystemId <> @SystemIdAux BEGIN
				SET @ErrorMessage = 'Sistema é inválido para este login';
				THROW 51000, @ErrorMessage, 1
			END
			IF @UserId <> @UserIdAux BEGIN
				SET @ErrorMessage = 'Usuário é inválido para este login';
				THROW 51000, @ErrorMessage, 1
			END
			IF @IsLogged = 0 BEGIN
				SET @ErrorMessage = 'Login já encerrado';
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
