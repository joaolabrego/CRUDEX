USE [crudex]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF (SELECT OBJECT_ID('[crudex].[NextDate]', 'FN')) IS NULL
    EXEC('CREATE FUNCTION [crudex].[NextDate]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [crudex].[NextDate](@Interval INT,
                         @PeriodicityName NVARCHAR(10),
                         @DateValue DATETIME2,
                         @TimeOfDay TIME = NULL,
                         @IsFirstOrLastDay BIT = NULL,
                         @DayOfMonth TINYINT = NULL,
                         @IsBusinessDays BIT = NULL)
RETURNS DATETIME2
AS
BEGIN
    DECLARE @Result DATETIME2 = @DateValue,
            @BaseDate DATE;

    -- Adiciona o intervalo conforme a periodicidade
    IF @PeriodicityName = 'second'
        SET @Result = DATEADD(SECOND, @Interval, @Result);
    ELSE IF @PeriodicityName = 'minute'
        SET @Result = DATEADD(MINUTE, @Interval, @Result);
    ELSE IF @PeriodicityName = 'hour'
        SET @Result = DATEADD(HOUR, @Interval, @Result);
    ELSE IF @PeriodicityName = 'day'
        SET @Result = DATEADD(DAY, @Interval, @Result);
    ELSE IF @PeriodicityName = 'month'
        SET @Result = DATEADD(MONTH, @Interval, @Result);
    ELSE IF @PeriodicityName = 'year'
        SET @Result = DATEADD(YEAR, @Interval, @Result);

    -- Define o dia fixo do mês, se fornecido
    IF @DayOfMonth IS NOT NULL AND @PeriodicityName IN ('month', 'year') BEGIN
        DECLARE @UltimoDia INT = DAY(EOMONTH(@Result))
        DECLARE @DiaFinal INT = IIF(@DayOfMonth > @UltimoDia, @UltimoDia, @DayOfMonth)

        SET @Result = DATEFROMPARTS(YEAR(@Result), MONTH(@Result), @DiaFinal)
    END

    -- Ajuste para primeiro ou último dia do mês (se definido)
    IF @IsFirstOrLastDay IS NOT NULL AND @PeriodicityName IN ('month', 'year') BEGIN
        IF @IsFirstOrLastDay = 1
            SET @Result = DATEFROMPARTS(YEAR(@Result), MONTH(@Result), 1);
        ELSE IF @IsFirstOrLastDay = 0
            SET @Result = EOMONTH(@Result);
    END

    -- Define o horário se fornecido
    IF @TimeOfDay IS NOT NULL
        SET @Result = CAST(CAST(@Result AS DATE) AS DATETIME2) + CAST(@TimeOfDay AS DATETIME2);

    -- Ajusta se não for dia útil (sábado ou domingo)
    IF @IsBusinessDays IS NOT NULL AND @IsBusinessDays = 1 BEGIN
        SET DATEFIRST 7; -- Define domingo como o primeiro dia da semana
        WHILE DATEPART(WEEKDAY, @Result) IN (1, 7)
            SET @Result = DATEADD(DAY, 1, @Result);
    END

    RETURN @Result;
END
