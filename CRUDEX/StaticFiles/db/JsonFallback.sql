CREATE OR ALTER FUNCTION dbo.JsonIsJsonFallback
(
    @JsonText NVARCHAR(MAX)
)
RETURNS BIT
AS
BEGIN
    /*
      Retorna 1 se o texto começa e termina com { } ou [ ] e tem aspas balanceadas.
      Não é um validador sintático completo, apenas uma verificação básica.
    */
    IF @JsonText IS NULL RETURN 0;
    SET @JsonText = LTRIM(RTRIM(@JsonText));

    IF (LEFT(@JsonText,1) IN ('{','[') AND RIGHT(@JsonText,1) IN ('}',']'))
        RETURN 1;
    RETURN 0;
END;
GO

CREATE OR ALTER FUNCTION dbo.JsonValueFallback
(
    @JsonText NVARCHAR(MAX),
    @Path NVARCHAR(400)   -- ex: $.Cidade.Estado
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Current NVARCHAR(MAX) = @JsonText,
            @Key NVARCHAR(200),
            @NextDot INT,
            @pos INT, @start INT, @end INT,
            @PathWork NVARCHAR(400) = @Path,
            @first NCHAR(1);

    IF @Current IS NULL OR @PathWork IS NULL RETURN NULL;
    IF LEFT(@PathWork,2) = '$.' SET @PathWork = SUBSTRING(@PathWork,3,LEN(@PathWork));

    WHILE LEN(@PathWork) > 0
    BEGIN
        SET @NextDot = CHARINDEX('.', @PathWork);
        IF @NextDot = 0
        BEGIN
            SET @Key = @PathWork;
            SET @PathWork = '';
        END
        ELSE
        BEGIN
            SET @Key = LEFT(@PathWork, @NextDot - 1);
            SET @PathWork = SUBSTRING(@PathWork, @NextDot + 1, LEN(@PathWork));
        END

        DECLARE @Pattern NVARCHAR(400) = '"' + @Key + '":';
        SET @pos = CHARINDEX(@Pattern, @Current);
        IF @pos = 0 RETURN NULL;
        SET @pos = @pos + LEN(@Pattern);

        WHILE SUBSTRING(@Current, @pos, 1) IN (' ', CHAR(9)) SET @pos += 1;
        SET @first = SUBSTRING(@Current, @pos, 1);

        IF @first = '"' 
        BEGIN
            SET @start = @pos + 1;
            SET @end = CHARINDEX('"', @Current, @start);
            RETURN SUBSTRING(@Current, @start, @end - @start);
        END
        ELSE
        BEGIN
            SET @start = @pos;
            SET @end = CHARINDEX(',', @Current + ',', @start);
            IF @end = 0 SET @end = CHARINDEX('}', @Current + '}', @start);
            RETURN LTRIM(RTRIM(SUBSTRING(@Current, @start, @end - @start)));
        END
    END
    RETURN NULL;
END;
GO

CREATE OR ALTER FUNCTION dbo.JsonQueryFallback
(
    @JsonText NVARCHAR(MAX),
    @Path NVARCHAR(400)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @obj NVARCHAR(MAX);
    SET @obj = dbo.JsonValueFallback(@JsonText, @Path);
    -- Se não achou, tenta localizar o início de { ... } manualmente
    IF @obj IS NULL
    BEGIN
        DECLARE @Pattern NVARCHAR(400) = '"' + REPLACE(@Path,'$.','') + '":';
        DECLARE @pos INT = CHARINDEX(@Pattern, @JsonText);
        IF @pos > 0
        BEGIN
            SET @pos = @pos + LEN(@Pattern);
            DECLARE @start INT = CHARINDEX('{', @JsonText, @pos);
            IF @start = 0 SET @start = CHARINDEX('[', @JsonText, @pos);
            IF @start > 0
            BEGIN
                DECLARE @i INT = @start + 1, @level INT = 1;
                WHILE @level > 0 AND @i <= LEN(@JsonText)
                BEGIN
                    IF SUBSTRING(@JsonText,@i,1) IN ('{','[') SET @level += 1;
                    IF SUBSTRING(@JsonText,@i,1) IN ('}',']') SET @level -= 1;
                    SET @i += 1;
                END
                RETURN SUBSTRING(@JsonText, @start, @i - @start);
            END
        END
    END
    RETURN @obj;
END;
GO

CREATE OR ALTER FUNCTION dbo.JsonModifyFallback
(
    @JsonText NVARCHAR(MAX),
    @Path NVARCHAR(200),
    @NewValue NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Key NVARCHAR(100) = REPLACE(@Path,'$.','');
    DECLARE @Pattern NVARCHAR(400) = '"' + @Key + '":';
    DECLARE @pos INT = CHARINDEX(@Pattern, @JsonText);
    DECLARE @Result NVARCHAR(MAX) = @JsonText;

    IF @pos > 0
    BEGIN
        DECLARE @end INT = CHARINDEX(',', @JsonText + ',', @pos);
        IF @end = 0 SET @end = CHARINDEX('}', @JsonText + '}', @pos);
        SET @Result = STUFF(@JsonText, @pos, @end - @pos, @Pattern + '"' + @NewValue + '"');
    END
    ELSE
    BEGIN
        -- Inserir antes do último }
        SET @Result = STUFF(@JsonText, LEN(@JsonText), 0, ',"' + @Key + '":"' + @NewValue + '"');
    END

    RETURN @Result;
END;
GO

CREATE OR ALTER FUNCTION dbo.JsonPathExistsFallback
(
    @JsonText NVARCHAR(MAX),
    @Path NVARCHAR(400)
)
RETURNS BIT
AS
BEGIN
    DECLARE @val NVARCHAR(MAX) = dbo.JsonValueFallback(@JsonText, @Path);
    IF @val IS NOT NULL RETURN 1;
    RETURN 0;
END;
GO
