IF (SELECT object_id('[cruda].[ConvertToType]', 'FN')) IS NULL
    EXEC('CREATE FUNCTION [cruda].[ConvertToType]() RETURNS NVARCHAR(MAX) AS BEGIN RETURN NULL END')
GO

ALTER FUNCTION [cruda].[ConvertToType](
    @Value NVARCHAR(MAX),
    @Type VARCHAR(25)
)
RETURNS NVARCHAR(MAX) AS 
BEGIN
    IF @Value IS NULL
        RETURN NULL;
    
    -- Conversões numéricas
    IF @Type = 'int'
        RETURN CAST(TRY_CAST(@Value AS INT) AS NVARCHAR(MAX));
    IF @Type = 'smallint'
        RETURN CAST(TRY_CAST(@Value AS SMALLINT) AS NVARCHAR(MAX));
    IF @Type = 'tinyint'
        RETURN CAST(TRY_CAST(@Value AS TINYINT) AS NVARCHAR(MAX));
    IF @Type = 'bigint'
        RETURN CAST(TRY_CAST(@Value AS BIGINT) AS NVARCHAR(MAX));
    IF @Type = 'money'
        RETURN CAST(TRY_CAST(@Value AS MONEY) AS NVARCHAR(MAX));
    IF @Type = 'smallmoney'
        RETURN CAST(TRY_CAST(@Value AS SMALLMONEY) AS NVARCHAR(MAX));
    IF @Type = 'decimal'
        RETURN CAST(TRY_CAST(@Value AS DECIMAL(38, 18)) AS NVARCHAR(MAX));
    IF @Type = 'numeric'
        RETURN CAST(TRY_CAST(@Value AS NUMERIC(38, 18)) AS NVARCHAR(MAX));
    IF @Type = 'float'
        RETURN CAST(TRY_CAST(@Value AS FLOAT) AS NVARCHAR(MAX));
    IF @Type = 'real'
        RETURN CAST(TRY_CAST(@Value AS REAL) AS NVARCHAR(MAX));
    
    -- Conversão para tipos de texto
    IF @Type IN ('varchar', 'char', 'text')
        RETURN CAST(@Value AS VARCHAR(MAX));  -- Retorna o valor diretamente como VARCHAR(MAX)
    IF @Type IN ('nvarchar', 'nchar', 'ntext')
        RETURN CAST(@Value AS NVARCHAR(MAX));  -- Retorna o valor diretamente como NVARCHAR(MAX)
    
    -- Conversões de tipos de data
    IF @Type = 'date'
        RETURN CAST(TRY_CAST(@Value AS DATE) AS NVARCHAR(MAX));
    IF @Type = 'datetime'
        RETURN CAST(TRY_CAST(@Value AS DATETIME) AS NVARCHAR(MAX));
    IF @Type = 'smalldatetime'
        RETURN CAST(TRY_CAST(@Value AS SMALLDATETIME) AS NVARCHAR(MAX));
    IF @Type = 'datetime2'
        RETURN CAST(TRY_CAST(@Value AS DATETIME2) AS NVARCHAR(MAX));
    IF @Type = 'datetimeoffset'
        RETURN CAST(TRY_CAST(@Value AS DATETIMEOFFSET) AS NVARCHAR(MAX));
    IF @Type = 'time'
        RETURN CAST(TRY_CAST(@Value AS TIME) AS NVARCHAR(MAX));
    
    -- Conversão para bit
    IF @Type = 'bit'
        RETURN CAST(TRY_CAST(@Value AS BIT) AS NVARCHAR(MAX));
    
    -- Conversões para tipos especiais
    IF @Type = 'sysname'
        RETURN CAST(TRY_CAST(@Value AS SYSNAME) AS NVARCHAR(MAX));
    IF @Type = 'uniqueidentifier'
        RETURN CAST(TRY_CAST(@Value AS UNIQUEIDENTIFIER) AS NVARCHAR(MAX));
    IF @Type = 'xml'
        RETURN CAST(TRY_CAST(@Value AS xml) AS NVARCHAR(MAX));
    
    -- Fallback para VARBINARY(MAX) caso nenhum tipo anterior seja identificado
    RETURN CAST(TRY_CAST(@Value AS VARBINARY(MAX)) AS NVARCHAR(MAX));
END
GO
