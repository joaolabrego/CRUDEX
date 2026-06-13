ALTER PROCEDURE [dbo].[TypeValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS tinyint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS tinyint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Types', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Types', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Types]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [CategoryId] = JSON_VALUE(@LastRecord, '$.CategoryId')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [dbo].[IS_EQUAL]([MaxLength], JSON_VALUE(@LastRecord, '$.MaxLength'), 'int') = 1
                                  AND [dbo].[IS_EQUAL]([Minimum], JSON_VALUE(@LastRecord, '$.Minimum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Maximum], JSON_VALUE(@LastRecord, '$.Maximum'), 'nvarchar(max)') = 1
                                  AND [AskLength] = JSON_VALUE(@LastRecord, '$.AskLength')
                                  AND [AskDecimals] = JSON_VALUE(@LastRecord, '$.AskDecimals')
                                  AND [AskPrimarykey] = JSON_VALUE(@LastRecord, '$.AskPrimarykey')
                                  AND [AskAutoincrement] = JSON_VALUE(@LastRecord, '$.AskAutoincrement')
                                  AND [AskFilterable] = JSON_VALUE(@LastRecord, '$.AskFilterable')
                                  AND [AskGridable] = JSON_VALUE(@LastRecord, '$.AskGridable')
                                  AND [AskCodification] = JSON_VALUE(@LastRecord, '$.AskCodification')
                                  AND [IsLikeable] = JSON_VALUE(@LastRecord, '$.IsLikeable')
                                  AND [IsActive] = JSON_VALUE(@LastRecord, '$.IsActive'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Types'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.CategoryId') = JSON_VALUE(@LastRecord, '$.CategoryId')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.MaxLength'), JSON_VALUE(@LastRecord, '$.MaxLength'), 'int') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Minimum'), JSON_VALUE(@LastRecord, '$.Minimum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Maximum'), JSON_VALUE(@LastRecord, '$.Maximum'), 'nvarchar(max)') = 1
                                  AND JSON_VALUE([ActualRecord], '$.AskLength') = JSON_VALUE(@LastRecord, '$.AskLength')
                                  AND JSON_VALUE([ActualRecord], '$.AskDecimals') = JSON_VALUE(@LastRecord, '$.AskDecimals')
                                  AND JSON_VALUE([ActualRecord], '$.AskPrimarykey') = JSON_VALUE(@LastRecord, '$.AskPrimarykey')
                                  AND JSON_VALUE([ActualRecord], '$.AskAutoincrement') = JSON_VALUE(@LastRecord, '$.AskAutoincrement')
                                  AND JSON_VALUE([ActualRecord], '$.AskFilterable') = JSON_VALUE(@LastRecord, '$.AskFilterable')
                                  AND JSON_VALUE([ActualRecord], '$.AskGridable') = JSON_VALUE(@LastRecord, '$.AskGridable')
                                  AND JSON_VALUE([ActualRecord], '$.AskCodification') = JSON_VALUE(@LastRecord, '$.AskCodification')
                                  AND JSON_VALUE([ActualRecord], '$.IsLikeable') = JSON_VALUE(@LastRecord, '$.IsLikeable')
                                  AND JSON_VALUE([ActualRecord], '$.IsActive') = JSON_VALUE(@LastRecord, '$.IsActive'))
                THROW 51000, 'Registro de Types alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [TypeId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Domains', 1
        END ELSE BEGIN

            DECLARE @W_CategoryId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.CategoryId') AS tinyint)
                   ,@W_Name nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(25))
                   ,@W_MaxLength int = CAST(JSON_VALUE(@ActualRecord, '$.MaxLength') AS int)
                   ,@W_Minimum nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS nvarchar(max))
                   ,@W_Maximum nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS nvarchar(max))
                   ,@W_AskLength bit = CAST(JSON_VALUE(@ActualRecord, '$.AskLength') AS bit)
                   ,@W_AskDecimals bit = CAST(JSON_VALUE(@ActualRecord, '$.AskDecimals') AS bit)
                   ,@W_AskPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.AskPrimarykey') AS bit)
                   ,@W_AskAutoincrement bit = CAST(JSON_VALUE(@ActualRecord, '$.AskAutoincrement') AS bit)
                   ,@W_AskFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskFilterable') AS bit)
                   ,@W_AskGridable bit = CAST(JSON_VALUE(@ActualRecord, '$.AskGridable') AS bit)
                   ,@W_AskCodification bit = CAST(JSON_VALUE(@ActualRecord, '$.AskCodification') AS bit)
                   ,@W_IsLikeable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLikeable') AS bit)
                   ,@W_IsActive bit = CAST(JSON_VALUE(@ActualRecord, '$.IsActive') AS bit)

            IF @W_CategoryId IS NULL
                THROW 51000, 'Valor de CategoryId em @ActualRecord é requerido.', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Categories] WHERE [Id] = @W_CategoryId)
                THROW 51000, 'Valor de CategoryId em @ActualRecord inexiste em Categories', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @W_MaxLength IS NOT NULL AND @W_MaxLength < CAST('1' AS int)
                THROW 51000, 'Valor de MaxLength em @ActualRecord deve ser maior que ou igual a 1', 1
            IF @W_AskLength IS NULL
                THROW 51000, 'Valor de AskLength em @ActualRecord é requerido.', 1
            IF @W_AskDecimals IS NULL
                THROW 51000, 'Valor de AskDecimals em @ActualRecord é requerido.', 1
            IF @W_AskPrimarykey IS NULL
                THROW 51000, 'Valor de AskPrimarykey em @ActualRecord é requerido.', 1
            IF @W_AskAutoincrement IS NULL
                THROW 51000, 'Valor de AskAutoincrement em @ActualRecord é requerido.', 1
            IF @W_AskFilterable IS NULL
                THROW 51000, 'Valor de AskFilterable em @ActualRecord é requerido.', 1
            IF @W_AskGridable IS NULL
                THROW 51000, 'Valor de AskGridable em @ActualRecord é requerido.', 1
            IF @W_AskCodification IS NULL
                THROW 51000, 'Valor de AskCodification em @ActualRecord é requerido.', 1
            IF @W_IsLikeable IS NULL
                THROW 51000, 'Valor de IsLikeable em @ActualRecord é requerido.', 1
            IF @W_IsActive IS NULL
                THROW 51000, 'Valor de IsActive em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_Types_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Types_Name já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[DomainValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Domains', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Domains', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Domains]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [TypeId] = JSON_VALUE(@LastRecord, '$.TypeId')
                                  AND [dbo].[IS_EQUAL]([MaskId], JSON_VALUE(@LastRecord, '$.MaskId'), 'bigint') = 1
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [dbo].[IS_EQUAL]([Length], JSON_VALUE(@LastRecord, '$.Length'), 'smallint') = 1
                                  AND [dbo].[IS_EQUAL]([Decimals], JSON_VALUE(@LastRecord, '$.Decimals'), 'tinyint') = 1
                                  AND [dbo].[IS_EQUAL]([ValidValues], JSON_VALUE(@LastRecord, '$.ValidValues'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Default], JSON_VALUE(@LastRecord, '$.Default'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Minimum], JSON_VALUE(@LastRecord, '$.Minimum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Maximum], JSON_VALUE(@LastRecord, '$.Maximum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Codification], JSON_VALUE(@LastRecord, '$.Codification'), 'nvarchar') = 1)
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Domains'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.TypeId') = JSON_VALUE(@LastRecord, '$.TypeId')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.MaskId'), JSON_VALUE(@LastRecord, '$.MaskId'), 'bigint') = 1
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Length'), JSON_VALUE(@LastRecord, '$.Length'), 'smallint') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Decimals'), JSON_VALUE(@LastRecord, '$.Decimals'), 'tinyint') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.ValidValues'), JSON_VALUE(@LastRecord, '$.ValidValues'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Default'), JSON_VALUE(@LastRecord, '$.Default'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Minimum'), JSON_VALUE(@LastRecord, '$.Minimum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Maximum'), JSON_VALUE(@LastRecord, '$.Maximum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Codification'), JSON_VALUE(@LastRecord, '$.Codification'), 'nvarchar') = 1)
                THROW 51000, 'Registro de Domains alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [DomainId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Columns', 1
        END ELSE BEGIN

            DECLARE @W_TypeId tinyint = CAST(JSON_VALUE(@ActualRecord, '$.TypeId') AS tinyint)
                   ,@W_MaskId bigint = CAST(JSON_VALUE(@ActualRecord, '$.MaskId') AS bigint)
                   ,@W_Name nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(25))
                   ,@W_Length smallint = CAST(JSON_VALUE(@ActualRecord, '$.Length') AS smallint)
                   ,@W_Decimals tinyint = CAST(JSON_VALUE(@ActualRecord, '$.Decimals') AS tinyint)
                   ,@W_ValidValues nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.ValidValues') AS nvarchar(max))
                   ,@W_Default nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS nvarchar(max))
                   ,@W_Minimum nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS nvarchar(max))
                   ,@W_Maximum nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS nvarchar(max))
                   ,@W_Codification nvarchar(5) = CAST(JSON_VALUE(@ActualRecord, '$.Codification') AS nvarchar(5))

            IF @W_TypeId IS NULL
                THROW 51000, 'Valor de TypeId em @ActualRecord é requerido.', 1
            IF @W_TypeId < CAST('1' AS tinyint)
                THROW 51000, 'Valor de TypeId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Types] WHERE [Id] = @W_TypeId)
                THROW 51000, 'Valor de TypeId em @ActualRecord inexiste em Types', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Masks] WHERE [Id] = @W_MaskId)
                THROW 51000, 'Valor de MaskId em @ActualRecord inexiste em Masks', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @W_Length IS NOT NULL AND @W_Length < CAST('0' AS smallint)
                THROW 51000, 'Valor de Length em @ActualRecord deve ser maior que ou igual a 0', 1
            IF @W_Decimals IS NOT NULL AND @W_Decimals < CAST('0' AS tinyint)
                THROW 51000, 'Valor de Decimals em @ActualRecord deve ser maior que ou igual a 0', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_Domains_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Domains_Name já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[MenuValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Menus', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Menus', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Menus]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [SystemId] = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND [Sequence] = JSON_VALUE(@LastRecord, '$.Sequence')
                                  AND [Caption] = JSON_VALUE(@LastRecord, '$.Caption')
                                  AND [Message] = JSON_VALUE(@LastRecord, '$.Message')
                                  AND [dbo].[IS_EQUAL]([Action], JSON_VALUE(@LastRecord, '$.Action'), 'nvarchar') = 1
                                  AND [dbo].[IS_EQUAL]([ParentMenuId], JSON_VALUE(@LastRecord, '$.ParentMenuId'), 'bigint') = 1)
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Menus'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.SystemId') = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND JSON_VALUE([ActualRecord], '$.Sequence') = JSON_VALUE(@LastRecord, '$.Sequence')
                                  AND JSON_VALUE([ActualRecord], '$.Caption') = JSON_VALUE(@LastRecord, '$.Caption')
                                  AND JSON_VALUE([ActualRecord], '$.Message') = JSON_VALUE(@LastRecord, '$.Message')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Action'), JSON_VALUE(@LastRecord, '$.Action'), 'nvarchar') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.ParentMenuId'), JSON_VALUE(@LastRecord, '$.ParentMenuId'), 'bigint') = 1)
                THROW 51000, 'Registro de Menus alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [ParentMenuId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Menus', 1
        END ELSE BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                   ,@W_Caption nvarchar(20) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS nvarchar(20))
                   ,@W_Message nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Message') AS nvarchar(50))
                   ,@W_Action nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS nvarchar(50))
                   ,@W_ParentMenuId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentMenuId') AS bigint)

            IF @W_SystemId IS NULL
                THROW 51000, 'Valor de SystemId em @ActualRecord é requerido.', 1
            IF @W_SystemId < CAST('1' AS bigint)
                THROW 51000, 'Valor de SystemId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId)
                THROW 51000, 'Valor de SystemId em @ActualRecord inexiste em Systems', 1
            IF @W_Sequence IS NULL
                THROW 51000, 'Valor de Sequence em @ActualRecord é requerido.', 1
            IF @W_Sequence < CAST('1' AS smallint)
                THROW 51000, 'Valor de Sequence em @ActualRecord deve ser maior que ou igual a 1', 1
            IF @W_Caption IS NULL
                THROW 51000, 'Valor de Caption em @ActualRecord é requerido.', 1
            IF @W_Message IS NULL
                THROW 51000, 'Valor de Message em @ActualRecord é requerido.', 1
            IF @W_ParentMenuId IS NOT NULL AND @W_ParentMenuId < CAST('1' AS bigint)
                THROW 51000, 'Valor de ParentMenuId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [Id] = @W_ParentMenuId)
                THROW 51000, 'Valor de ParentMenuId em @ActualRecord inexiste em Menus', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Sequence] = @W_Sequence)
                    THROW 51000, 'Chave única de UNQ_Menus_SystemId_Sequence já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Caption] = @W_Caption)
                    THROW 51000, 'Chave única de UNQ_Menus_SystemId_Caption já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Sequence] = @W_Sequence AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Menus_SystemId_Sequence já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Menus] WHERE [SystemId] = @W_SystemId AND [Caption] = @W_Caption AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Menus_SystemId_Caption já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[SystemUserValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em SystemsUsers', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em SystemsUsers', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[SystemsUsers]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [SystemId] = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND [UserId] = JSON_VALUE(@LastRecord, '$.UserId')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'SystemsUsers'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.SystemId') = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND JSON_VALUE([ActualRecord], '$.UserId') = JSON_VALUE(@LastRecord, '$.UserId')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name'))
                THROW 51000, 'Registro de SystemsUsers alterado por outro usuário', 1
        END

        IF @Action <> 'delete' BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                   ,@W_Name nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(50))

            IF @W_SystemId IS NULL
                THROW 51000, 'Valor de SystemId em @ActualRecord é requerido.', 1
            IF @W_SystemId < CAST('1' AS bigint)
                THROW 51000, 'Valor de SystemId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId)
                THROW 51000, 'Valor de SystemId em @ActualRecord inexiste em Systems', 1
            IF @W_UserId IS NULL
                THROW 51000, 'Valor de UserId em @ActualRecord é requerido.', 1
            IF @W_UserId < CAST('1' AS bigint)
                THROW 51000, 'Valor de UserId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Id] = @W_UserId)
                THROW 51000, 'Valor de UserId em @ActualRecord inexiste em Users', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId)
                    THROW 51000, 'Chave única de UNQ_SystemsUsers_SystemId_UserId já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_SystemsUsers_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [SystemId] = @W_SystemId AND [UserId] = @W_UserId AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_SystemsUsers_SystemId_UserId já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[SystemsUsers] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_SystemsUsers_Name já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[DatabaseValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Databases', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Databases', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Databases]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [ConnectionId] = JSON_VALUE(@LastRecord, '$.ConnectionId')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [Alias] = JSON_VALUE(@LastRecord, '$.Alias')
                                  AND [Description] = JSON_VALUE(@LastRecord, '$.Description')
                                  AND [dbo].[IS_EQUAL]([Folder], JSON_VALUE(@LastRecord, '$.Folder'), 'nvarchar') = 1
                                  AND [IsLegacy] = JSON_VALUE(@LastRecord, '$.IsLegacy')
                                  AND [CurrentOperationId] = JSON_VALUE(@LastRecord, '$.CurrentOperationId'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Databases'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.ConnectionId') = JSON_VALUE(@LastRecord, '$.ConnectionId')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name')
                                  AND JSON_VALUE([ActualRecord], '$.Alias') = JSON_VALUE(@LastRecord, '$.Alias')
                                  AND JSON_VALUE([ActualRecord], '$.Description') = JSON_VALUE(@LastRecord, '$.Description')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Folder'), JSON_VALUE(@LastRecord, '$.Folder'), 'nvarchar') = 1
                                  AND JSON_VALUE([ActualRecord], '$.IsLegacy') = JSON_VALUE(@LastRecord, '$.IsLegacy')
                                  AND JSON_VALUE([ActualRecord], '$.CurrentOperationId') = JSON_VALUE(@LastRecord, '$.CurrentOperationId'))
                THROW 51000, 'Registro de Databases alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [DatabaseId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em SystemsDatabases', 1
            IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em DatabasesTables', 1
        END ELSE BEGIN

            DECLARE @W_ConnectionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ConnectionId') AS bigint)
                   ,@W_Name nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(25))
                   ,@W_Alias nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS nvarchar(25))
                   ,@W_Description nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS nvarchar(50))
                   ,@W_Folder nvarchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.Folder') AS nvarchar(256))
                   ,@W_IsLegacy bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLegacy') AS bit)
                   ,@W_CurrentOperationId bigint = CAST(JSON_VALUE(@ActualRecord, '$.CurrentOperationId') AS bigint)

            IF @W_ConnectionId IS NULL
                THROW 51000, 'Valor de ConnectionId em @ActualRecord é requerido.', 1
            IF @W_ConnectionId < CAST('1' AS bigint)
                THROW 51000, 'Valor de ConnectionId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Connections] WHERE [Id] = @W_ConnectionId)
                THROW 51000, 'Valor de ConnectionId em @ActualRecord inexiste em Connections', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @W_Alias IS NULL
                THROW 51000, 'Valor de Alias em @ActualRecord é requerido.', 1
            IF @W_Description IS NULL
                THROW 51000, 'Valor de Description em @ActualRecord é requerido.', 1
            IF @W_IsLegacy IS NULL
                THROW 51000, 'Valor de IsLegacy em @ActualRecord é requerido.', 1
            IF @W_CurrentOperationId IS NULL
                THROW 51000, 'Valor de CurrentOperationId em @ActualRecord é requerido.', 1
            IF @W_CurrentOperationId < CAST('0' AS bigint)
                THROW 51000, 'Valor de CurrentOperationId em @ActualRecord deve ser maior que ou igual a 0', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_Databases_Name já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Alias] = @W_Alias)
                    THROW 51000, 'Chave única de UNQ_Databases_Alias já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Databases_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Alias] = @W_Alias AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Databases_Alias já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[SystemDatabaseValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em SystemsDatabases', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em SystemsDatabases', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[SystemsDatabases]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [SystemId] = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND [DatabaseId] = JSON_VALUE(@LastRecord, '$.DatabaseId')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'SystemsDatabases'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.SystemId') = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND JSON_VALUE([ActualRecord], '$.DatabaseId') = JSON_VALUE(@LastRecord, '$.DatabaseId')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name'))
                THROW 51000, 'Registro de SystemsDatabases alterado por outro usuário', 1
        END

        IF @Action <> 'delete' BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                   ,@W_Name nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(50))

            IF @W_SystemId IS NULL
                THROW 51000, 'Valor de SystemId em @ActualRecord é requerido.', 1
            IF @W_SystemId < CAST('1' AS bigint)
                THROW 51000, 'Valor de SystemId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId)
                THROW 51000, 'Valor de SystemId em @ActualRecord inexiste em Systems', 1
            IF @W_DatabaseId IS NULL
                THROW 51000, 'Valor de DatabaseId em @ActualRecord é requerido.', 1
            IF @W_DatabaseId < CAST('1' AS bigint)
                THROW 51000, 'Valor de DatabaseId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId)
                THROW 51000, 'Valor de DatabaseId em @ActualRecord inexiste em Databases', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId)
                    THROW 51000, 'Chave única de UNQ_SystemsDatabases_SystemId_DatabaseId já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_SystemsDatabases_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [SystemId] = @W_SystemId AND [DatabaseId] = @W_DatabaseId AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_SystemsDatabases_SystemId_DatabaseId já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[SystemsDatabases] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_SystemsDatabases_Name já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[TableValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Tables', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Tables', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Tables]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [Alias] = JSON_VALUE(@LastRecord, '$.Alias')
                                  AND [Description] = JSON_VALUE(@LastRecord, '$.Description')
                                  AND [dbo].[IS_EQUAL]([ParentTableId], JSON_VALUE(@LastRecord, '$.ParentTableId'), 'bigint') = 1
                                  AND [IsLegacy] = JSON_VALUE(@LastRecord, '$.IsLegacy')
                                  AND [CurrentId] = JSON_VALUE(@LastRecord, '$.CurrentId'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Tables'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name')
                                  AND JSON_VALUE([ActualRecord], '$.Alias') = JSON_VALUE(@LastRecord, '$.Alias')
                                  AND JSON_VALUE([ActualRecord], '$.Description') = JSON_VALUE(@LastRecord, '$.Description')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.ParentTableId'), JSON_VALUE(@LastRecord, '$.ParentTableId'), 'bigint') = 1
                                  AND JSON_VALUE([ActualRecord], '$.IsLegacy') = JSON_VALUE(@LastRecord, '$.IsLegacy')
                                  AND JSON_VALUE([ActualRecord], '$.CurrentId') = JSON_VALUE(@LastRecord, '$.CurrentId'))
                THROW 51000, 'Registro de Tables alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [ParentTableId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Tables', 1
            IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [TableId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em DatabasesTables', 1
            IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Columns', 1
            IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [ReferenceTableId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Columns', 1
            IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [TableId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Indexes', 1
        END ELSE BEGIN

            DECLARE @W_Name nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(25))
                   ,@W_Alias nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS nvarchar(25))
                   ,@W_Description nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS nvarchar(50))
                   ,@W_ParentTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ParentTableId') AS bigint)
                   ,@W_IsLegacy bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLegacy') AS bit)
                   ,@W_CurrentId bigint = CAST(JSON_VALUE(@ActualRecord, '$.CurrentId') AS bigint)

            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @W_Alias IS NULL
                THROW 51000, 'Valor de Alias em @ActualRecord é requerido.', 1
            IF @W_Description IS NULL
                THROW 51000, 'Valor de Description em @ActualRecord é requerido.', 1
            IF @W_ParentTableId IS NOT NULL AND @W_ParentTableId < CAST('0' AS bigint)
                THROW 51000, 'Valor de ParentTableId em @ActualRecord deve ser maior que ou igual a 0', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ParentTableId)
                THROW 51000, 'Valor de ParentTableId em @ActualRecord inexiste em Tables', 1
            IF @W_IsLegacy IS NULL
                THROW 51000, 'Valor de IsLegacy em @ActualRecord é requerido.', 1
            IF @W_CurrentId IS NULL
                THROW 51000, 'Valor de CurrentId em @ActualRecord é requerido.', 1
            IF @W_CurrentId < CAST('0' AS bigint)
                THROW 51000, 'Valor de CurrentId em @ActualRecord deve ser maior que ou igual a 0', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_Tables_Name já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Alias] = @W_Alias)
                    THROW 51000, 'Chave única de UNQ_Tables_Alias já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Tables_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Alias] = @W_Alias AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Tables_Alias já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[DatabaseTableValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em DatabasesTables', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em DatabasesTables', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[DatabasesTables]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [DatabaseId] = JSON_VALUE(@LastRecord, '$.DatabaseId')
                                  AND [TableId] = JSON_VALUE(@LastRecord, '$.TableId')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'DatabasesTables'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.DatabaseId') = JSON_VALUE(@LastRecord, '$.DatabaseId')
                                  AND JSON_VALUE([ActualRecord], '$.TableId') = JSON_VALUE(@LastRecord, '$.TableId')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name'))
                THROW 51000, 'Registro de DatabasesTables alterado por outro usuário', 1
        END

        IF @Action <> 'delete' BEGIN

            DECLARE @W_DatabaseId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DatabaseId') AS bigint)
                   ,@W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                   ,@W_Name nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(50))

            IF @W_DatabaseId IS NULL
                THROW 51000, 'Valor de DatabaseId em @ActualRecord é requerido.', 1
            IF @W_DatabaseId < CAST('1' AS bigint)
                THROW 51000, 'Valor de DatabaseId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Databases] WHERE [Id] = @W_DatabaseId)
                THROW 51000, 'Valor de DatabaseId em @ActualRecord inexiste em Databases', 1
            IF @W_TableId IS NULL
                THROW 51000, 'Valor de TableId em @ActualRecord é requerido.', 1
            IF @W_TableId < CAST('1' AS bigint)
                THROW 51000, 'Valor de TableId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId)
                THROW 51000, 'Valor de TableId em @ActualRecord inexiste em Tables', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId)
                    THROW 51000, 'Chave única de UNQ_DatabasesTables_DatabaseId_TableId já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_DatabasesTables_Name já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_TableId)
                    THROW 51000, 'Unicidade cruzada de [DatabaseTable].[DatabaseId] => [DatabaseTable].[TableId] já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [TableId] = @W_DatabaseId)
                    THROW 51000, 'Unicidade cruzada de [DatabaseTable].[TableId] => [DatabaseTable].[DatabaseId] já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_DatabaseId AND [TableId] = @W_TableId AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_DatabasesTables_DatabaseId_TableId já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_DatabasesTables_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [DatabaseId] = @W_TableId AND [Id] <> @W_Id)
                THROW 51000, 'Unicidade cruzada de [DatabaseTable].[DatabaseId] => [DatabaseTable].[TableId] já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[DatabasesTables] WHERE [TableId] = @W_DatabaseId AND [Id] <> @W_Id)
                THROW 51000, 'Unicidade cruzada de [DatabaseTable].[TableId] => [DatabaseTable].[DatabaseId] já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[ColumnValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Columns', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Columns', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Columns]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [TableId] = JSON_VALUE(@LastRecord, '$.TableId')
                                  AND [Sequence] = JSON_VALUE(@LastRecord, '$.Sequence')
                                  AND [DomainId] = JSON_VALUE(@LastRecord, '$.DomainId')
                                  AND [dbo].[IS_EQUAL]([ReferenceTableId], JSON_VALUE(@LastRecord, '$.ReferenceTableId'), 'bigint') = 1
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [dbo].[IS_EQUAL]([Alias], JSON_VALUE(@LastRecord, '$.Alias'), 'nvarchar') = 1
                                  AND [Description] = JSON_VALUE(@LastRecord, '$.Description')
                                  AND [Title] = JSON_VALUE(@LastRecord, '$.Title')
                                  AND [Caption] = JSON_VALUE(@LastRecord, '$.Caption')
                                  AND [dbo].[IS_EQUAL]([Default], JSON_VALUE(@LastRecord, '$.Default'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Minimum], JSON_VALUE(@LastRecord, '$.Minimum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([Maximum], JSON_VALUE(@LastRecord, '$.Maximum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL]([IsPrimarykey], JSON_VALUE(@LastRecord, '$.IsPrimarykey'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL]([IsAutoIncrement], JSON_VALUE(@LastRecord, '$.IsAutoIncrement'), 'bit') = 1
                                  AND [IsRequired] = JSON_VALUE(@LastRecord, '$.IsRequired')
                                  AND [dbo].[IS_EQUAL]([IsListable], JSON_VALUE(@LastRecord, '$.IsListable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL]([IsFilterable], JSON_VALUE(@LastRecord, '$.IsFilterable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL]([IsEditable], JSON_VALUE(@LastRecord, '$.IsEditable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL]([IsGridable], JSON_VALUE(@LastRecord, '$.IsGridable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL]([IsEncrypted], JSON_VALUE(@LastRecord, '$.IsEncrypted'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL]([IsInWords], JSON_VALUE(@LastRecord, '$.IsInWords'), 'bit') = 1)
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Columns'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.TableId') = JSON_VALUE(@LastRecord, '$.TableId')
                                  AND JSON_VALUE([ActualRecord], '$.Sequence') = JSON_VALUE(@LastRecord, '$.Sequence')
                                  AND JSON_VALUE([ActualRecord], '$.DomainId') = JSON_VALUE(@LastRecord, '$.DomainId')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.ReferenceTableId'), JSON_VALUE(@LastRecord, '$.ReferenceTableId'), 'bigint') = 1
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Alias'), JSON_VALUE(@LastRecord, '$.Alias'), 'nvarchar') = 1
                                  AND JSON_VALUE([ActualRecord], '$.Description') = JSON_VALUE(@LastRecord, '$.Description')
                                  AND JSON_VALUE([ActualRecord], '$.Title') = JSON_VALUE(@LastRecord, '$.Title')
                                  AND JSON_VALUE([ActualRecord], '$.Caption') = JSON_VALUE(@LastRecord, '$.Caption')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Default'), JSON_VALUE(@LastRecord, '$.Default'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Minimum'), JSON_VALUE(@LastRecord, '$.Minimum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.Maximum'), JSON_VALUE(@LastRecord, '$.Maximum'), 'nvarchar(max)') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsPrimarykey'), JSON_VALUE(@LastRecord, '$.IsPrimarykey'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsAutoIncrement'), JSON_VALUE(@LastRecord, '$.IsAutoIncrement'), 'bit') = 1
                                  AND JSON_VALUE([ActualRecord], '$.IsRequired') = JSON_VALUE(@LastRecord, '$.IsRequired')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsListable'), JSON_VALUE(@LastRecord, '$.IsListable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsFilterable'), JSON_VALUE(@LastRecord, '$.IsFilterable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsEditable'), JSON_VALUE(@LastRecord, '$.IsEditable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsGridable'), JSON_VALUE(@LastRecord, '$.IsGridable'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsEncrypted'), JSON_VALUE(@LastRecord, '$.IsEncrypted'), 'bit') = 1
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsInWords'), JSON_VALUE(@LastRecord, '$.IsInWords'), 'bit') = 1)
                THROW 51000, 'Registro de Columns alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [ColumnId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Indexkeys', 1
            IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [ColumnId1] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Unicities', 1
            IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [ColumnId2] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Unicities', 1
        END ELSE BEGIN

            DECLARE @W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                   ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                   ,@W_DomainId bigint = CAST(JSON_VALUE(@ActualRecord, '$.DomainId') AS bigint)
                   ,@W_ReferenceTableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ReferenceTableId') AS bigint)
                   ,@W_Name nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(25))
                   ,@W_Alias nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Alias') AS nvarchar(25))
                   ,@W_Description nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Description') AS nvarchar(50))
                   ,@W_Title nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Title') AS nvarchar(25))
                   ,@W_Caption nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.Caption') AS nvarchar(25))
                   ,@W_Default nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Default') AS nvarchar(max))
                   ,@W_Minimum nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Minimum') AS nvarchar(max))
                   ,@W_Maximum nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.Maximum') AS nvarchar(max))
                   ,@W_IsPrimarykey bit = CAST(JSON_VALUE(@ActualRecord, '$.IsPrimarykey') AS bit)
                   ,@W_IsAutoIncrement bit = CAST(JSON_VALUE(@ActualRecord, '$.IsAutoIncrement') AS bit)
                   ,@W_IsRequired bit = CAST(JSON_VALUE(@ActualRecord, '$.IsRequired') AS bit)
                   ,@W_IsListable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsListable') AS bit)
                   ,@W_IsFilterable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsFilterable') AS bit)
                   ,@W_IsEditable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEditable') AS bit)
                   ,@W_IsGridable bit = CAST(JSON_VALUE(@ActualRecord, '$.IsGridable') AS bit)
                   ,@W_IsEncrypted bit = CAST(JSON_VALUE(@ActualRecord, '$.IsEncrypted') AS bit)
                   ,@W_IsInWords bit = CAST(JSON_VALUE(@ActualRecord, '$.IsInWords') AS bit)

            IF @W_TableId IS NULL
                THROW 51000, 'Valor de TableId em @ActualRecord é requerido.', 1
            IF @W_TableId < CAST('1' AS bigint)
                THROW 51000, 'Valor de TableId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId)
                THROW 51000, 'Valor de TableId em @ActualRecord inexiste em Tables', 1
            IF @W_Sequence IS NULL
                THROW 51000, 'Valor de Sequence em @ActualRecord é requerido.', 1
            IF @W_Sequence < CAST('1' AS smallint)
                THROW 51000, 'Valor de Sequence em @ActualRecord deve ser maior que ou igual a 1', 1
            IF @W_DomainId IS NULL
                THROW 51000, 'Valor de DomainId em @ActualRecord é requerido.', 1
            IF @W_DomainId < CAST('1' AS bigint)
                THROW 51000, 'Valor de DomainId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_DomainId)
                THROW 51000, 'Valor de DomainId em @ActualRecord inexiste em Domains', 1
            IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint)
                THROW 51000, 'Valor de ReferenceTableId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_ReferenceTableId)
                THROW 51000, 'Valor de ReferenceTableId em @ActualRecord inexiste em Tables', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @W_Description IS NULL
                THROW 51000, 'Valor de Description em @ActualRecord é requerido.', 1
            IF @W_Title IS NULL
                THROW 51000, 'Valor de Title em @ActualRecord é requerido.', 1
            IF @W_Caption IS NULL
                THROW 51000, 'Valor de Caption em @ActualRecord é requerido.', 1
            IF @W_IsRequired IS NULL
                THROW 51000, 'Valor de IsRequired em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_Columns_TableId_Name já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence)
                    THROW 51000, 'Chave única de UNQ_Columns_TableId_Sequence já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Columns_TableId_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [TableId] = @W_TableId AND [Sequence] = @W_Sequence AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Columns_TableId_Sequence já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[IndexValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Indexes', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Indexes', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Indexes]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [TableId] = JSON_VALUE(@LastRecord, '$.TableId')
                                  AND [Name] = JSON_VALUE(@LastRecord, '$.Name')
                                  AND [IsUnique] = JSON_VALUE(@LastRecord, '$.IsUnique'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Indexes'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.TableId') = JSON_VALUE(@LastRecord, '$.TableId')
                                  AND JSON_VALUE([ActualRecord], '$.Name') = JSON_VALUE(@LastRecord, '$.Name')
                                  AND JSON_VALUE([ActualRecord], '$.IsUnique') = JSON_VALUE(@LastRecord, '$.IsUnique'))
                THROW 51000, 'Registro de Indexes alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Indexkeys', 1
        END ELSE BEGIN

            DECLARE @W_TableId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TableId') AS bigint)
                   ,@W_Name nvarchar(50) = CAST(JSON_VALUE(@ActualRecord, '$.Name') AS nvarchar(50))
                   ,@W_IsUnique bit = CAST(JSON_VALUE(@ActualRecord, '$.IsUnique') AS bit)

            IF @W_TableId IS NULL
                THROW 51000, 'Valor de TableId em @ActualRecord é requerido.', 1
            IF @W_TableId < CAST('1' AS bigint)
                THROW 51000, 'Valor de TableId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_TableId)
                THROW 51000, 'Valor de TableId em @ActualRecord inexiste em Tables', 1
            IF @W_Name IS NULL
                THROW 51000, 'Valor de Name em @ActualRecord é requerido.', 1
            IF @W_IsUnique IS NULL
                THROW 51000, 'Valor de IsUnique em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Name] = @W_Name)
                    THROW 51000, 'Chave única de UNQ_Indexes_Name já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Name] = @W_Name AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Indexes_Name já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[IndexkeyValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Indexkeys', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Indexkeys', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Indexkeys]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [IndexId] = JSON_VALUE(@LastRecord, '$.IndexId')
                                  AND [Sequence] = JSON_VALUE(@LastRecord, '$.Sequence')
                                  AND [ColumnId] = JSON_VALUE(@LastRecord, '$.ColumnId')
                                  AND [IsDescending] = JSON_VALUE(@LastRecord, '$.IsDescending'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Indexkeys'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.IndexId') = JSON_VALUE(@LastRecord, '$.IndexId')
                                  AND JSON_VALUE([ActualRecord], '$.Sequence') = JSON_VALUE(@LastRecord, '$.Sequence')
                                  AND JSON_VALUE([ActualRecord], '$.ColumnId') = JSON_VALUE(@LastRecord, '$.ColumnId')
                                  AND JSON_VALUE([ActualRecord], '$.IsDescending') = JSON_VALUE(@LastRecord, '$.IsDescending'))
                THROW 51000, 'Registro de Indexkeys alterado por outro usuário', 1
        END

        IF @Action <> 'delete' BEGIN

            DECLARE @W_IndexId bigint = CAST(JSON_VALUE(@ActualRecord, '$.IndexId') AS bigint)
                   ,@W_Sequence smallint = CAST(JSON_VALUE(@ActualRecord, '$.Sequence') AS smallint)
                   ,@W_ColumnId bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId') AS bigint)
                   ,@W_IsDescending bit = CAST(JSON_VALUE(@ActualRecord, '$.IsDescending') AS bit)

            IF @W_IndexId IS NULL
                THROW 51000, 'Valor de IndexId em @ActualRecord é requerido.', 1
            IF @W_IndexId < CAST('1' AS bigint)
                THROW 51000, 'Valor de IndexId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Indexes] WHERE [Id] = @W_IndexId)
                THROW 51000, 'Valor de IndexId em @ActualRecord inexiste em Indexes', 1
            IF @W_Sequence IS NULL
                THROW 51000, 'Valor de Sequence em @ActualRecord é requerido.', 1
            IF @W_Sequence < CAST('1' AS smallint)
                THROW 51000, 'Valor de Sequence em @ActualRecord deve ser maior que ou igual a 1', 1
            IF @W_ColumnId IS NULL
                THROW 51000, 'Valor de ColumnId em @ActualRecord é requerido.', 1
            IF @W_ColumnId < CAST('1' AS bigint)
                THROW 51000, 'Valor de ColumnId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_ColumnId)
                THROW 51000, 'Valor de ColumnId em @ActualRecord inexiste em Columns', 1
            IF @W_IsDescending IS NULL
                THROW 51000, 'Valor de IsDescending em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [Sequence] = @W_Sequence)
                    THROW 51000, 'Chave única de UNQ_Indexkeys_IndexId_Sequence já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [ColumnId] = @W_ColumnId)
                    THROW 51000, 'Chave única de UNQ_Indexkeys_IndexId_ColumnId já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [Sequence] = @W_Sequence AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Indexkeys_IndexId_Sequence já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Indexkeys] WHERE [IndexId] = @W_IndexId AND [ColumnId] = @W_ColumnId AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Indexkeys_IndexId_ColumnId já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[SessionValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Sessions] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Sessions', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Sessions', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Sessions]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [SystemId] = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND [UserId] = JSON_VALUE(@LastRecord, '$.UserId')
                                  AND [dbo].[IS_EQUAL]([PublicKey], JSON_VALUE(@LastRecord, '$.PublicKey'), 'nvarchar') = 1
                                  AND [IsLogged] = JSON_VALUE(@LastRecord, '$.IsLogged'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Sessions'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.SystemId') = JSON_VALUE(@LastRecord, '$.SystemId')
                                  AND JSON_VALUE([ActualRecord], '$.UserId') = JSON_VALUE(@LastRecord, '$.UserId')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.PublicKey'), JSON_VALUE(@LastRecord, '$.PublicKey'), 'nvarchar') = 1
                                  AND JSON_VALUE([ActualRecord], '$.IsLogged') = JSON_VALUE(@LastRecord, '$.IsLogged'))
                THROW 51000, 'Registro de Sessions alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [SessionId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Transactions', 1
        END ELSE BEGIN

            DECLARE @W_SystemId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SystemId') AS bigint)
                   ,@W_UserId bigint = CAST(JSON_VALUE(@ActualRecord, '$.UserId') AS bigint)
                   ,@W_PublicKey nvarchar(256) = CAST(JSON_VALUE(@ActualRecord, '$.PublicKey') AS nvarchar(256))
                   ,@W_IsLogged bit = CAST(JSON_VALUE(@ActualRecord, '$.IsLogged') AS bit)

            IF @W_SystemId IS NULL
                THROW 51000, 'Valor de SystemId em @ActualRecord é requerido.', 1
            IF @W_SystemId < CAST('1' AS bigint)
                THROW 51000, 'Valor de SystemId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Systems] WHERE [Id] = @W_SystemId)
                THROW 51000, 'Valor de SystemId em @ActualRecord inexiste em Systems', 1
            IF @W_UserId IS NULL
                THROW 51000, 'Valor de UserId em @ActualRecord é requerido.', 1
            IF @W_UserId < CAST('1' AS bigint)
                THROW 51000, 'Valor de UserId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Users] WHERE [Id] = @W_UserId)
                THROW 51000, 'Valor de UserId em @ActualRecord inexiste em Users', 1
            IF @W_IsLogged IS NULL
                THROW 51000, 'Valor de IsLogged em @ActualRecord é requerido.', 1
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[TransactionValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Transactions', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Transactions', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Transactions]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [SessionId] = JSON_VALUE(@LastRecord, '$.SessionId')
                                  AND [dbo].[IS_EQUAL]([IsConfirmed], JSON_VALUE(@LastRecord, '$.IsConfirmed'), 'bit') = 1)
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Transactions'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.SessionId') = JSON_VALUE(@LastRecord, '$.SessionId')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsConfirmed'), JSON_VALUE(@LastRecord, '$.IsConfirmed'), 'bit') = 1)
                THROW 51000, 'Registro de Transactions alterado por outro usuário', 1
        END

        IF @Action = 'delete' BEGIN
            IF EXISTS(SELECT 1 FROM [dbo].[Operations] WHERE [TransactionId] = @W_Id)
                THROW 51000, 'Chave-primária referenciada em Operations', 1
        END ELSE BEGIN

            DECLARE @W_SessionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.SessionId') AS bigint)
                   ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)

            IF @W_SessionId IS NULL
                THROW 51000, 'Valor de SessionId em @ActualRecord é requerido.', 1
            IF @W_SessionId < CAST('1' AS bigint)
                THROW 51000, 'Valor de SessionId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Sessions] WHERE [Id] = @W_SessionId)
                THROW 51000, 'Valor de SessionId em @ActualRecord inexiste em Sessions', 1
            IF @W_IsConfirmed IS NOT NULL AND @W_IsConfirmed < CAST('1' AS bit)
                THROW 51000, 'Valor de IsConfirmed em @ActualRecord deve ser maior que ou igual a 1', 1
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[OperationValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Operations] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Operations', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Operations', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [TransactionId] = JSON_VALUE(@LastRecord, '$.TransactionId')
                                  AND [TableName] = JSON_VALUE(@LastRecord, '$.TableName')
                                  AND [Action] = JSON_VALUE(@LastRecord, '$.Action')
                                  AND [dbo].[IS_EQUAL]([LastRecord], JSON_VALUE(@LastRecord, '$.LastRecord'), 'nvarchar(max)') = 1
                                  AND [ActualRecord] = JSON_VALUE(@LastRecord, '$.ActualRecord')
                                  AND [dbo].[IS_EQUAL]([IsConfirmed], JSON_VALUE(@LastRecord, '$.IsConfirmed'), 'bit') = 1)
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Operations'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.TransactionId') = JSON_VALUE(@LastRecord, '$.TransactionId')
                                  AND JSON_VALUE([ActualRecord], '$.TableName') = JSON_VALUE(@LastRecord, '$.TableName')
                                  AND JSON_VALUE([ActualRecord], '$.Action') = JSON_VALUE(@LastRecord, '$.Action')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.LastRecord'), JSON_VALUE(@LastRecord, '$.LastRecord'), 'nvarchar(max)') = 1
                                  AND JSON_VALUE([ActualRecord], '$.ActualRecord') = JSON_VALUE(@LastRecord, '$.ActualRecord')
                                  AND [dbo].[IS_EQUAL](JSON_VALUE([ActualRecord], '$.IsConfirmed'), JSON_VALUE(@LastRecord, '$.IsConfirmed'), 'bit') = 1)
                THROW 51000, 'Registro de Operations alterado por outro usuário', 1
        END

        IF @Action <> 'delete' BEGIN

            DECLARE @W_TransactionId bigint = CAST(JSON_VALUE(@ActualRecord, '$.TransactionId') AS bigint)
                   ,@W_TableName nvarchar(25) = CAST(JSON_VALUE(@ActualRecord, '$.TableName') AS nvarchar(25))
                   ,@W_Action nvarchar(15) = CAST(JSON_VALUE(@ActualRecord, '$.Action') AS nvarchar(15))
                   ,@W_LastRecord nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.LastRecord') AS nvarchar(max))
                   ,@W_ActualRecord nvarchar(max) = CAST(JSON_VALUE(@ActualRecord, '$.ActualRecord') AS nvarchar(max))
                   ,@W_IsConfirmed bit = CAST(JSON_VALUE(@ActualRecord, '$.IsConfirmed') AS bit)

            IF @W_TransactionId IS NULL
                THROW 51000, 'Valor de TransactionId em @ActualRecord é requerido.', 1
            IF @W_TransactionId < CAST('1' AS bigint)
                THROW 51000, 'Valor de TransactionId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [Id] = @W_TransactionId)
                THROW 51000, 'Valor de TransactionId em @ActualRecord inexiste em Transactions', 1
            IF @W_TableName IS NULL
                THROW 51000, 'Valor de TableName em @ActualRecord é requerido.', 1
            IF @W_Action IS NULL
                THROW 51000, 'Valor de Action em @ActualRecord é requerido.', 1
            IF @W_ActualRecord IS NULL
                THROW 51000, 'Valor de ActualRecord em @ActualRecord é requerido.', 1
        END

    RETURN @TransactionId
END
GO
GO

ALTER PROCEDURE [dbo].[UnicityValidate](@SessionId BIGINT
                                               ,@TransactionId BIGINT
                                               ,@UserName NVARCHAR(25)
                                               ,@Action NVARCHAR(15)
                                               ,@LastRecord NVARCHAR(max)
                                               ,@ActualRecord NVARCHAR(max)) AS BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX)

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    IF @SessionId IS NULL
            THROW 51000, 'Valor de @SessionId é requerido', 1
        IF @UserName IS NULL
            THROW 51000, 'Valor de @UserName é requerido', 1
        IF @Action IS NULL
            THROW 51000, 'Valor de @Action é requerido', 1
        IF @Action NOT IN ('create', 'update', 'delete')
            THROW 51000, 'Valor de @Action é inválido', 1
        IF @ActualRecord IS NULL
            THROW 51000, 'Valor de @ActualRecord é requerido', 1
        IF ISJSON(@ActualRecord) = 0
            THROW 51000, 'Valor de @ActualRecord não está no formato JSON', 1
        IF @TransactionId IS NULL
            THROW 51000, 'Valor de @TransactionId é requerido', 1
        DECLARE @IsConfirmed BIT
               ,@CreatedBy NVARCHAR(25)
               ,@W_Id AS bigint = CAST(JSON_VALUE(@ActualRecord, '$.Id') AS bigint)

        SELECT @IsConfirmed = [IsConfirmed]
              ,@CreatedBy = [CreatedBy]
            FROM [dbo].[Transactions]
            WHERE [Id] = @TransactionId
                  AND [SessionId] = @SessionId
        IF @@ROWCOUNT = 0
            THROW 51000, 'Transação inexistente', 1
        IF @IsConfirmed IS NOT NULL BEGIN
            SET @ErrorMessage = 'Transação já ' + CASE WHEN @IsConfirmed = 0 THEN 'cancelada' ELSE 'concluída' END;
            THROW 51000, @ErrorMessage, 1;
        END
        IF @UserName <> @CreatedBy
            THROW 51000, 'Erro grave de segurança', 1
        IF @W_Id IS NULL BEGIN
            SET @ErrorMessage = 'Valor de Id em @ActualRecord é requerido.';
            THROW 51000, @ErrorMessage, 1
        END
        IF @W_Id < CAST('1' AS bigint)
            THROW 51000, 'Valor de Id em @ActualRecord deve ser maior que ou igual a 1', 1
        IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [Id] = @W_Id) BEGIN
            IF @Action = 'create'
                THROW 51000, 'Chave-primária já existe em Unicities', 1
        END ELSE IF @Action <> 'create'
            THROW 51000, 'Chave-primária não existe em Unicities', 1
        IF @Action <> 'create' BEGIN
            IF @LastRecord IS NULL
                THROW 51000, 'Valor de @LastRecord é requerido', 1
            IF ISJSON(@LastRecord) = 0
                THROW 51000, 'Valor de @LastRecord não está no formato JSON', 1
            IF NOT EXISTS(SELECT 1
                            FROM [dbo].[Unicities]
                            WHERE [Id] = JSON_VALUE(@LastRecord, '$.Id')
                                  AND [ColumnId1] = JSON_VALUE(@LastRecord, '$.ColumnId1')
                                  AND [ColumnId2] = JSON_VALUE(@LastRecord, '$.ColumnId2')
                                  AND [IsBidirectional] = JSON_VALUE(@LastRecord, '$.IsBidirectional'))
            AND NOT EXISTS(SELECT 1
                            FROM [dbo].[Operations]
                            WHERE [TransactionId] = @TransactionId
                                  AND [TableName] = 'Unicities'
                                  AND [IsConfirmed] IS NULL
                                  AND JSON_VALUE([ActualRecord], '$.Id') = JSON_VALUE(@LastRecord, '$.Id')
                                  AND JSON_VALUE([ActualRecord], '$.ColumnId1') = JSON_VALUE(@LastRecord, '$.ColumnId1')
                                  AND JSON_VALUE([ActualRecord], '$.ColumnId2') = JSON_VALUE(@LastRecord, '$.ColumnId2')
                                  AND JSON_VALUE([ActualRecord], '$.IsBidirectional') = JSON_VALUE(@LastRecord, '$.IsBidirectional'))
                THROW 51000, 'Registro de Unicities alterado por outro usuário', 1
        END

        IF @Action <> 'delete' BEGIN

            DECLARE @W_ColumnId1 bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId1') AS bigint)
                   ,@W_ColumnId2 bigint = CAST(JSON_VALUE(@ActualRecord, '$.ColumnId2') AS bigint)
                   ,@W_IsBidirectional bit = CAST(JSON_VALUE(@ActualRecord, '$.IsBidirectional') AS bit)

            IF @W_ColumnId1 IS NULL
                THROW 51000, 'Valor de ColumnId1 em @ActualRecord é requerido.', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_ColumnId1)
                THROW 51000, 'Valor de ColumnId1 em @ActualRecord inexiste em Columns', 1
            IF @W_ColumnId2 IS NULL
                THROW 51000, 'Valor de ColumnId2 em @ActualRecord é requerido.', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Columns] WHERE [Id] = @W_ColumnId2)
                THROW 51000, 'Valor de ColumnId2 em @ActualRecord inexiste em Columns', 1
            IF @W_IsBidirectional IS NULL
                THROW 51000, 'Valor de IsBidirectional em @ActualRecord é requerido.', 1
            IF @Action = 'create' BEGIN
                IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [ColumnId1] = @W_ColumnId1 AND [ColumnId2] = @W_ColumnId2)
                    THROW 51000, 'Chave única de UNQ_Unicities_ColumnId1_ColumnId2 já existe', 1
                IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [ColumnId2] = @W_ColumnId2 AND [ColumnId1] = @W_ColumnId1)
                    THROW 51000, 'Chave única de UNQ_Unicities_ColumnId2_ColumnId1 já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [ColumnId1] = @W_ColumnId1 AND [ColumnId2] = @W_ColumnId2 AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Unicities_ColumnId1_ColumnId2 já existe', 1
            ELSE IF EXISTS(SELECT 1 FROM [dbo].[Unicities] WHERE [ColumnId2] = @W_ColumnId2 AND [ColumnId1] = @W_ColumnId1 AND [Id] <> @W_Id)
                THROW 51000, 'Chave única de UNQ_Unicities_ColumnId2_ColumnId1 já existe', 1
            END
        END

    RETURN @TransactionId
END
GO
GO


