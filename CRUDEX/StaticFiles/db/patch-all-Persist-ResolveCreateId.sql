ALTER PROCEDURE [dbo].[CategoryPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS tinyint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Categories'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Categories', @NewId OUT
            SET @W_Id = CAST(@NewId AS tinyint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[CategoryValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Categories'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS tinyint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Categories'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[CategoryValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[TypePersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS tinyint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Types'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Types', @NewId OUT
            SET @W_Id = CAST(@NewId AS tinyint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[TypeValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Types'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS tinyint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Types'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[TypeValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[MaskPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Masks'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Masks', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[MaskValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Masks'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Masks'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[MaskValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[DomainPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Domains'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Domains', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[DomainValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Domains'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Domains'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[DomainValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[SystemPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Systems'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Systems', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[SystemValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Systems'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Systems'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[SystemValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[MenuPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Menus'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Menus', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[MenuValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Menus'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Menus'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[MenuValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[UserPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Users'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Users', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[UserValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Users'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Users'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[UserValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[SystemUserPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'SystemsUsers'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'SystemsUsers', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[SystemUserValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'SystemsUsers'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'SystemsUsers'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[SystemUserValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[ConnectionPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Connections'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Connections', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[ConnectionValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Connections'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Connections'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[ConnectionValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[DatabasePersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Databases'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Databases', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[DatabaseValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Databases'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Databases'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[DatabaseValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[SystemDatabasePersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'SystemsDatabases'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'SystemsDatabases', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[SystemDatabaseValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'SystemsDatabases'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'SystemsDatabases'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[SystemDatabaseValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[TablePersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Tables'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Tables', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[TableValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Tables'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Tables'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[TableValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[DatabaseTablePersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'DatabasesTables'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'DatabasesTables', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[DatabaseTableValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'DatabasesTables'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'DatabasesTables'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[DatabaseTableValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[ColumnPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Columns'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Columns', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[ColumnValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Columns'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Columns'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[ColumnValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[IndexPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Indexes'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Indexes', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[IndexValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Indexes'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Indexes'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[IndexValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[IndexkeyPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Indexkeys'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Indexkeys', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[IndexkeyValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Indexkeys'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Indexkeys'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[IndexkeyValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[SessionPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Sessions'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Sessions', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[SessionValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Sessions'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Sessions'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[SessionValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[TransactionPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Transactions'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Transactions', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[TransactionValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Transactions'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Transactions'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[TransactionValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[OperationPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Operations'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Operations', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[OperationValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Operations'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Operations'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[OperationValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[UnicityPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Unicities'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Unicities', @NewId OUT
            SET @W_Id = CAST(@NewId AS bigint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[UnicityValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Unicities'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS bigint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Unicities'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[UnicityValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO
ALTER PROCEDURE [dbo].[OperatorPersist](@Login NVARCHAR(MAX)
                                              ,@TransactionId BIGINT
                                              ,@Action NVARCHAR(15)
                                              ,@LastRecord NVARCHAR(max)
                                              ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(255)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @SessionId BIGINT
           ,@UserName NVARCHAR(25) = CAST(JSON_VALUE(@Login, '$.UserName') AS NVARCHAR(25))
    DECLARE @LoginReturn BIGINT

    EXEC [dbo].[Login] @Parameters = @Login, @ReturnValue = @LoginReturn OUTPUT
    SET @SessionId = CAST(JSON_VALUE(@Login, '$.LoginId') AS BIGINT)
    IF @SessionId IS NULL
        THROW 51000, 'LoginId é requerido', 1

    DECLARE @OperationId BIGINT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT
           ,@W_Id tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)


    IF @Action = 'create' AND @W_Id IS NULL BEGIN
        SELECT @W_Id = CAST(JSON_VALUE([ActualRecord], '$.Id') AS tinyint)
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Operators'
                  AND [Action] = 'create'
                  AND [IsConfirmed] IS NULL
        IF @W_Id IS NULL BEGIN
            DECLARE @NewId BIGINT
            EXEC [dbo].[NewId] 'crudex', 'crudex', 'Operators', @NewId OUT
            SET @W_Id = CAST(@NewId AS tinyint)
        END
        SET @ActualRecord = JSON_MODIFY(@ActualRecord, '$.Id', @W_Id)
    END
    EXEC @TransactionId = [dbo].[OperatorValidate] @SessionId, @TransactionId, @UserName, @Action, @LastRecord, @ActualRecord
        SELECT @OperationId = [Id]
              ,@CreatedBy = [CreatedBy]
              ,@ActionAux = [Action]
              ,@IsConfirmed = [IsConfirmed]
            FROM [dbo].[Operations]
            WHERE [TransactionId] = @TransactionId
                  AND [TableName] = 'Operators'
                  AND [IsConfirmed] IS NULL
                  AND CAST(JSON_VALUE([ActualRecord], '$.Id') AS tinyint) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            EXEC [dbo].[NewOperationId] 'crudex', 'crudex', @OperationId OUT
            INSERT INTO [dbo].[Operations] ([Id]
                                             ,[TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                       VALUES(@OperationId
                                             ,@TransactionId
                                             ,'Operators'
                                             ,@Action
                                             ,@LastRecord
                                             ,@ActualRecord
                                             ,NULL
                                             ,GETDATE()
                                             ,@UserName)
        END ELSE IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Operação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro excluído nesta transação', 1
        ELSE IF @Action = 'create' BEGIN
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[OperatorValidate] @SessionId, @TransactionId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [dbo].[Operations]
                SET [ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [dbo].[Operations] 
                SET [IsConfirmed] = 0
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [dbo].[Operations]
                SET [Action] = 'delete'
                   ,[LastRecord] = @LastRecord
                   ,[ActualRecord] = @ActualRecord
                   ,[UpdatedAt] = GETDATE()
                   ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END

    RETURN CAST(@OperationId AS BIGINT)
END
GO

