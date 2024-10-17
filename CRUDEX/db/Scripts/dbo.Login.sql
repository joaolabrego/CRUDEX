IF(SELECT object_id('[dbo].[Login]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[Login] AS PRINT 1')
GO
ALTER PROCEDURE [dbo].[Login](@Parameters VARCHAR(MAX)) AS BEGIN
	DECLARE @TRANCOUNT INT = @@TRANCOUNT
			,@ErrorMessage NVARCHAR(MAX)

	BEGIN TRY
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		BEGIN TRANSACTION
		SAVE TRANSACTION [SavePoint]

		IF ISJSON(@Parameters) = 0
			THROW 51000, 'Parâmetro login não está no formato JSON', 1

		DECLARE @Action VARCHAR(15) = CAST([crudex].[JSON_EXTRACT](@Parameters, '$.Action') AS VARCHAR(15))
				,@LoginId INT = CAST([crudex].[JSON_EXTRACT](@Parameters, '$.LoginId') AS INT)
				,@SystemName VARCHAR(25) = CAST([crudex].[JSON_EXTRACT](@Parameters, '$.SystemName') AS VARCHAR(25))
				,@UserName VARCHAR(25) = CAST([crudex].[JSON_EXTRACT](@Parameters, '$.UserName') AS VARCHAR(25))
				,@Password VARCHAR(256) = CAST([crudex].[JSON_EXTRACT](@Parameters, '$.Password') AS VARCHAR(256))
				,@PublicKey VARCHAR(256) = CAST([crudex].[JSON_EXTRACT](@Parameters, '$.PublicKey') AS VARCHAR(256))
				,@PasswordAux VARCHAR(256)
				,@SystemId INT
				,@SystemIdAux INT
				,@UserId INT
				,@UserIdAux INT
				,@MaxRetryLogins TINYINT
				,@RetryLogins TINYINT
				,@IsLogged BIT
				,@IsActive BIT
				,@IsOffAir BIT
	
		IF @Action IS NULL
			THROW 51000, 'Ação de login é requerida', 1
		IF @Action NOT IN ('login','logout','authenticate')
			THROW 51000, 'Ação de login é inválida', 1
		IF @SystemName IS NULL
			THROW 51000, 'Sistema é requerido', 1
		SELECT @SystemId = [Id]
			   ,@MaxRetryLogins = [MaxRetryLogins]
			   ,@IsOffAir = [IsOffAir]
			FROM [dbo].[Systems]
			WHERE [Name] = @SystemName
		IF @SystemId IS NULL
			THROW 51000, 'Sistema não cadastrado', 1
		IF @IsOffAir = 1
			THROW 51000, 'Sistema fora do ar', 1
		IF @UserName IS NULL
			THROW 51000, 'Usuário é requerido', 1
		SELECT	@UserId = [Id]
				,@RetryLogins = [RetryLogins]
				,@IsActive = [IsActive]
				,@PasswordAux = [Password]
			FROM [dbo].[Users]
			WHERE [Name] = @UserName
		IF @UserId IS NULL
			THROW 51000, 'Usuário não cadastrado', 1
		IF @IsActive = 0
			THROW 51000, 'Usuário está inativo', 1
		IF @RetryLogins >= @MaxRetryLogins
			THROW 51000, 'Usuário está bloqueado', 1
		IF NOT EXISTS(SELECT TOP 1 1
						FROM [dbo].[SystemsUsers]
						WHERE [SystemId] = @SystemId
							  AND [UserId] =  @UserId)
			THROW 51000, 'Usuário não autorizado', 1
		IF @Password IS NULL
			THROW 51000, 'Senha é requerida', 1
		IF CAST(@PasswordAux AS VARCHAR(MAX)) <> CAST(@Password AS VARCHAR(MAX)) BEGIN
			SET @RetryLogins = @RetryLogins + 1
			UPDATE [dbo].[Users] 
				SET [RetryLogins] = @RetryLogins
				WHERE [Id] = @UserId
			COMMIT TRANSACTION 
			IF @RetryLogins = @MaxRetryLogins
				THROW 51000, 'Usuário está bloqueado', 1
			ELSE BEGIN
				SET @ErrorMessage = 'Senha é inválida (' + CAST(@MaxRetryLogins -  @RetryLogins AS VARCHAR(3)) + ' tentativas restantes)';
				THROW 51000, @ErrorMessage, 1
			END
		
		END
		IF @action = 'login' BEGIN
			IF @PublicKey IS NULL
				THROW 51000, 'Chave pública é requerida', 1
			EXEC @LoginId = [dbo].[GenerateId] 'crudex', 'crudex', 'Logins'
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
		END ELSE IF @LoginId IS NULL
			THROW 51000, 'Id de login é requerido', 1
		ELSE BEGIN
			SELECT @SystemIdAux = [SystemId],
				   @UserIdAux = [UserId],
				   @IsLogged = [IsLogged]
				FROM [dbo].[Logins]
				WHERE [Id] = @LoginId
			IF @SystemIdAux IS NULL
				THROW 51000, 'Login não cadastrado', 1
			IF @SystemId <> @SystemIdAux
				THROW 51000, 'Sistema é inválido para este login', 1
			IF @UserId <> @UserIdAux
				THROW 51000, 'Usuário é inválido para este login', 1
			IF @IsLogged = 0
				THROW 51000, 'Login já encerrado', 1
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
		COMMIT TRANSACTION 

		RETURN @LoginId
	END TRY
	BEGIN CATCH
        IF @@TRANCOUNT > @TRANCOUNT BEGIN
            ROLLBACK TRANSACTION [SavePoint];
            COMMIT TRANSACTION
        END
        SET @ErrorMessage = ERROR_MESSAGE();
        THROW 51000, @ErrorMessage, 1
	END CATCH
END
GO
