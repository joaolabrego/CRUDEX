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
        ELSE IF @Action = 'create'
            THROW 51000, 'Registro já existe nesta transação', 1
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
