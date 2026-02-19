USE [crudex]
GO
IF(SELECT object_id('[crudex].[CheckDigit]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [crudex].[CheckDigit]() RETURNS CHAR(1) AS BEGIN RETURN '' '' END')
GO
ALTER FUNCTION [crudex].[CheckDigit](@Value VARCHAR(50),
									 @Module INT = 11,
									 @Factors VARCHAR(100),
									 @DigitGreaterThanNine CHAR(1) = '0')
RETURNS CHAR(1) AS  
BEGIN
    DECLARE @Sum INT = 0,
            @i INT,
            @LenValue INT = LEN(@Value),
        
            @FactorStr NVARCHAR(100),
            @Digit INT,
            @FullValue BIT = 0,
            @DigitChar CHAR(1);
    DECLARE @FactorsTable TABLE (Pos INT, Factor INT)

    -- Converte lista "9;2;3;4" em tabela
    DECLARE @xml XML = N'<i>' + REPLACE(@Factors, ';', '</i><i>') + '</i>';
    INSERT INTO @FactorsTable(Pos, Factor)
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Pos,
           TRY_CAST(x.i.value('.', 'INT') AS INT)
    FROM @xml.nodes('//i') x(i);

    DECLARE @FactorCount INT = (SELECT COUNT(*) FROM @FactorsTable);

    IF @LenValue = @FactorCount
        SET @FullValue = 1;

    SET @i = @FactorCount;
    WHILE @i >= 1
    BEGIN
        DECLARE @DigitValue INT = TRY_CAST(SUBSTRING(@Value, @i, 1) AS INT),
                @Factor INT = (SELECT Factor FROM @FactorsTable WHERE Pos = @i);
        DECLARE @Product INT = @DigitValue * @Factor;

        IF @FullValue = 1 AND @Product > 9
        BEGIN
            DECLARE @Parcel1 INT = @Product / 10;
            DECLARE @Parcel2 INT = @Product % 10;
            SET @Product = @Parcel1 + @Parcel2;
        END;

        SET @Sum += @Product;
        SET @i -= 1;
    END

    SET @Digit = @Sum % @Module;

    IF @Digit > 9
        SET @Digit = TRY_CAST(@DigitGreaterThanNine AS INT);

    RETURN CASE WHEN @Digit > 9 THEN @DigitGreaterThanNine ELSE CAST(@Digit AS CHAR(1)) END
END

-- SELECT crudex.CheckDigit('047207048', 11, '1;2;3;4;5;6;7;8;9', '0');
