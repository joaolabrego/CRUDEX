IF(SELECT object_id('[dbo].[ColumnValidate]', 'P')) IS NULL
    EXEC('CREATE PROCEDURE [dbo].[ColumnValidate] AS PRINT 1')
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
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_Id)
                THROW 51000, 'Valor de TableId em @ActualRecord inexiste em Tables', 1
            IF @W_Sequence IS NULL
                THROW 51000, 'Valor de Sequence em @ActualRecord é requerido.', 1
            IF @W_Sequence < CAST('1' AS smallint)
                THROW 51000, 'Valor de Sequence em @ActualRecord deve ser maior que ou igual a 1', 1
            IF @W_DomainId IS NULL
                THROW 51000, 'Valor de DomainId em @ActualRecord é requerido.', 1
            IF @W_DomainId < CAST('1' AS bigint)
                THROW 51000, 'Valor de DomainId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Domains] WHERE [Id] = @W_Id)
                THROW 51000, 'Valor de DomainId em @ActualRecord inexiste em Domains', 1
            IF @W_ReferenceTableId IS NOT NULL AND @W_ReferenceTableId < CAST('1' AS bigint)
                THROW 51000, 'Valor de ReferenceTableId em @ActualRecord deve ser maior que ou igual a 1', 1
            IF NOT EXISTS(SELECT 1 FROM [dbo].[Tables] WHERE [Id] = @W_Id)
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
