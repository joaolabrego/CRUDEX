IF(SELECT object_id('[dbo].[ColumnPersist]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[ColumnPersist] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[ColumnPersist](@LoginId INT
                                    ,@UserName NVARCHAR(25)
                                    ,@Action NVARCHAR(15)
                                    ,@LastRecord NVARCHAR(max)
                                    ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @TRANCOUNT INT = @@TRANCOUNT
            ,@ErrorMessage NVARCHAR(MAX)

    BEGIN TRY
        SET NOCOUNT ON
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED

        DECLARE @TransactionId INT

        BEGIN TRANSACTION
        SAVE TRANSACTION [SavePoint]
        EXEC @TransactionId = [dbo].[ColumnValidate] @LoginId, @UserName, @Action, @LastRecord, @ActualRecord

        DECLARE @W_Id int = CAST([cruda].[JSON_EXTRACT](@ActualRecord, '$.Id') AS int)
               ,@OperationId INT
               ,@CreatedBy NVARCHAR(25)
               ,@ActionAux NVARCHAR(15)
               ,@IsConfirmed BIT

        SELECT @OperationId = [Id]
                ,@CreatedBy = [CreatedBy]
                ,@ActionAux = [Action]
            FROM [cruda].[Operations]
            WHERE [TransactionId] = @TransactionId
                    AND [TableName] = 'Columns'
                    AND [IsConfirmed] IS NULL
                    AND CAST([cruda].[JSON_EXTRACT]([ActualRecord], '$.Id') AS int) = @W_Id
        IF @@ROWCOUNT = 0 BEGIN
            INSERT INTO [cruda].[Operations] ([TransactionId]
                                             ,[TableName]
                                             ,[Action]
                                             ,[LastRecord]
                                             ,[ActualRecord]
                                             ,[IsConfirmed]
                                             ,[CreatedAt]
                                             ,[CreatedBy])
                                        VALUES(@TransactionId
                                              ,'Columns'
                                              ,@Action
                                              ,@LastRecord
                                              ,@ActualRecord
                                              ,NULL
                                              ,GETDATE()
                                              ,@UserName)
            SET @OperationId = @@IDENTITY
        END ELSE IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        ELSE IF @ActionAux = 'delete'
            THROW 51000, 'Registro já excluído nesta transação', 1
        ELSE IF @Action = 'create'
            THROW 51000, 'Registro já existe nesta transação', 1
        ELSE IF @Action = 'update' BEGIN
            IF @ActionAux = 'create'
                EXEC [dbo].[ColumnValidate] @LoginId, @UserName, 'create', NULL, @ActualRecord
            UPDATE [cruda].[Operations]
                SET [ActualRecord] = @ActualRecord
                    ,[UpdatedAt] = GETDATE()
                    ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE IF @ActionAux = 'create' BEGIN
            UPDATE [cruda].[Operations] 
                SET [IsConfirmed] = 0
                    ,[UpdatedAt] = GETDATE()
                    ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END ELSE BEGIN
            UPDATE [cruda].[Operations]
                SET [Action] = 'delete'
                    ,[LastRecord] = @LastRecord
                    ,[ActualRecord] = @ActualRecord
                    ,[UpdatedAt] = GETDATE()
                    ,[UpdatedBy] = @UserName
                WHERE [Id] = @OperationId
        END
        COMMIT TRANSACTION

        RETURN CAST(@OperationId AS INT)
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > @TRANCOUNT BEGIN
            ROLLBACK TRANSACTION [SavePoint];
            COMMIT TRANSACTION
        END
        SET @ErrorMessage = 'Stored Procedure [' + ERROR_PROCEDURE() + '] Error: ' + ERROR_MESSAGE() + ', Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        THROW 51000, @ErrorMessage, 1
    END CATCH
END
