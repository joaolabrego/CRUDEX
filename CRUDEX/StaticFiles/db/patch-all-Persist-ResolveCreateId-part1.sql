IF(SELECT object_id('[dbo].[CategoryPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[CategoryPersist] AS PRINT 1')
GO
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
IF(SELECT object_id('[dbo].[TypePersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TypePersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[MaskPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[MaskPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[DomainPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DomainPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[SystemPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[MenuPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[MenuPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[UserPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[UserPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[SystemUserPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemUserPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[ConnectionPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[ConnectionPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[DatabasePersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DatabasePersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[SystemDatabasePersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SystemDatabasePersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[TablePersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TablePersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[DatabaseTablePersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[DatabaseTablePersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[ColumnPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[ColumnPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[IndexPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[IndexPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[IndexkeyPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[IndexkeyPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[SessionPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[SessionPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[TransactionPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[TransactionPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[OperationPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[OperationPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[UnicityPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[UnicityPersist] AS PRINT 1')
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
IF(SELECT object_id('[dbo].[OperatorPersist]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[OperatorPersist] AS PRINT 1')
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

