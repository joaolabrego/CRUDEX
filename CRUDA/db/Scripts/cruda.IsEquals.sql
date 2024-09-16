IF (SELECT object_id('[cruda].[IsEquals]', 'FN')) IS NULL
    EXEC('CREATE FUNCTION [cruda].[IsEquals]() RETURNS BIT AS BEGIN RETURN 1 END')
GO

ALTER FUNCTION [cruda].[IsEquals](
    @LeftValue NVARCHAR(MAX),
    @RightValue NVARCHAR(4000),
    @TypeValue VARCHAR(25)
)
RETURNS BIT AS 
BEGIN
    IF @LeftValue IS NULL AND @RightValue IS NULL
        RETURN 1;
    IF @LeftValue IS NULL OR @RightValue IS NULL
        RETURN 0;
	
    -- Comparações numéricas
	IF @TypeValue = 'int'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS int) = TRY_CAST(@RightValue AS int) THEN 1 ELSE 0 END;
	IF @TypeValue = 'smallint'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS smallint) = TRY_CAST(@RightValue AS smallint) THEN 1 ELSE 0 END;
	IF @TypeValue = 'tinyint'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS tinyint) = TRY_CAST(@RightValue AS tinyint) THEN 1 ELSE 0 END;
	IF @TypeValue = 'bigint'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS bigint) = TRY_CAST(@RightValue AS bigint) THEN 1 ELSE 0 END;

	-- Comparações decimais e monetárias
	IF @TypeValue = 'decimal'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS decimal(38, 18)) = TRY_CAST(@RightValue AS decimal(38, 18)) THEN 1 ELSE 0 END;
	IF @TypeValue = 'numeric'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS numeric(38, 18)) = TRY_CAST(@RightValue AS numeric(38, 18)) THEN 1 ELSE 0 END;
	IF @TypeValue = 'float'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS float) = TRY_CAST(@RightValue AS float) THEN 1 ELSE 0 END;
	IF @TypeValue = 'real'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS real) = TRY_CAST(@RightValue AS real) THEN 1 ELSE 0 END;
	IF @TypeValue = 'money'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS money) = TRY_CAST(@RightValue AS money) THEN 1 ELSE 0 END;
	IF @TypeValue = 'smallmoney'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS smallmoney) = TRY_CAST(@RightValue AS smallmoney) THEN 1 ELSE 0 END;
    
    -- Comparação de strings
	IF @TypeValue IN ('varchar', 'char', 'text', 'nvarchar', 'nchar', 'ntext')
        RETURN CASE WHEN @LeftValue = @RightValue THEN 1 ELSE 0 END;

    -- Comparações de datas
	IF @TypeValue = 'date'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS date) = TRY_CAST(@RightValue AS date) THEN 1 ELSE 0 END;
	IF @TypeValue = 'datetime'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS datetime) = TRY_CAST(@RightValue AS datetime) THEN 1 ELSE 0 END;
	IF @TypeValue = 'datetime2'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS datetime2) = TRY_CAST(@RightValue AS datetime2) THEN 1 ELSE 0 END;
	IF @TypeValue = 'smalldatetime'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS smalldatetime) = TRY_CAST(@RightValue AS smalldatetime) THEN 1 ELSE 0 END;
	IF @TypeValue = 'datetimeoffset'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS datetimeoffset) = TRY_CAST(@RightValue AS datetimeoffset) THEN 1 ELSE 0 END;
	IF @TypeValue = 'time'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS time) = TRY_CAST(@RightValue AS time) THEN 1 ELSE 0 END;

    -- Comparações de tipos especiais
    IF @TypeValue = 'bit'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS BIT) = TRY_CAST(@RightValue AS BIT) THEN 1 ELSE 0 END;
    IF @TypeValue = 'sysname'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS SYSNAME) = TRY_CAST(@RightValue AS SYSNAME) THEN 1 ELSE 0 END;
    IF @TypeValue = 'uniqueidentifier'
        RETURN CASE WHEN TRY_CAST(@LeftValue AS UNIQUEIDENTIFIER) = TRY_CAST(@RightValue AS UNIQUEIDENTIFIER) THEN 1 ELSE 0 END;

    -- Comparação final como VARBINARY(MAX) (fallback)
    RETURN CASE WHEN TRY_CAST(@LeftValue AS VARBINARY(MAX)) = TRY_CAST(@RightValue AS VARBINARY(MAX)) THEN 1 ELSE 0 END;
END
GO
