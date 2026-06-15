IF(SELECT object_id('[dbo].[NUMBER_IN_WORDS]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[NUMBER_IN_WORDS]() RETURNS VARCHAR(MAX) AS BEGIN RETURN '''' END')
GO
ALTER FUNCTION [dbo].[NUMBER_IN_WORDS](@Value AS DECIMAL(18,2))
RETURNS VARCHAR(MAX) AS  
BEGIN 
	DECLARE @EnglishOrPortuguese BIT = 1,
		    @CurrencyInSingular VARCHAR(50) = 'Real',
		    @CurrencyInPlural VARCHAR(50) = 'Reais',
		    @CentsInSingular VARCHAR(50) = 'Centavo',
		    @CentsInPlural VARCHAR(50) = 'Centavos',
		    @Power INT = 0,
		    @Separator VARCHAR(5) = '',
		    @PartialValue INT,
		    @Digito INT = 0,
		    @LastDigit INT,
			@Result VARCHAR(MAX) = '',
			@Minus VARCHAR(10) = '',
			@Of VARCHAR(10),
			@And VARCHAR(10),
			@ValueOfHundreds INT = 0,
			@ValueOfThousands INT = 0
	DECLARE @Powers TABLE (Id INT, NomeSingular VARCHAR(50), NomePlural VARCHAR(50))

	SET @Of = ' de '
	SET @And = ' e '
	IF @Value < 0 BEGIN
		SET @Value = -@Value
		SET @Minus = 'Menos'
	END	
	INSERT @Powers
		VALUES(0,'', ''),
			  (1,'Mil', 'Mil'),
			  (2,'Milhão', 'Milhões'),
			  (3,'Bilhão', 'Bilhões'),
			  (4,'Trilhão', 'Trilhões'),
			  (5,'Quatrilhão', 'Quatrilhões'),
			  (6,'Quintilhão', 'Quintilhões'),
			  (7,'Sextilhão', 'Sextilhões'),
			  (8,'Septilhão', 'Septilhões'),
			  (9,'Octilhão', 'Octilhões'),
			  (10,'Nonilhão', 'Nonilhões'),
			  (11,'Decilhão', 'Decilhões'),
		      (12,'Undecilhão', 'Undecilhões'),
			  (13,'Duodecilhão', 'Duodecilhões'),
			  (14,'Tredecilhão', 'Tredecilhões')
	SET @PartialValue = FLOOR(@Value)
	WHILE @PartialValue > 0 BEGIN
		SET @LastDigit = @Digito
		SET @Digito = @PartialValue % 1000
		IF @Power = 0 BEGIN
			SET @ValueOfHundreds = @Digito
		END ELSE IF @Power = 1 BEGIN
			SET @ValueOfThousands = @Digito
		END
		IF @Digito = 1 BEGIN
			 SET @Result = [dbo].[HUNDREDS_IN_WORDS](@Digito, @EnglishOrPortuguese) + ' ' + 
							  (SELECT NomeSingular FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END ELSE IF @Digito > 0 BEGIN
			 SET @Result = [dbo].[HUNDREDS_IN_WORDS](@Digito, @EnglishOrPortuguese) + ' ' + 
							  (SELECT NomePlural FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END
		SET @PartialValue = @PartialValue / 1000
		IF @Digito > 0 BEGIN
			IF (@Power = 0) BEGIN
				SET @Separator = CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE ', ' END
			END ELSE BEGIN
				SET @Separator = ', '
			END
		END
		SET @Power = @Power + 1
	END
	SET @Result = RTRIM(@Result)
	IF @Result = '' BEGIN
		IF @Value = 0 BEGIN
			SET @Result = 'Zero ' + @CurrencyInPlural
		END
	END ELSE IF @Digito = 1 BEGIN
		IF @Power < 2 BEGIN
			SET @Result = @Result + ' ' + @CurrencyInSingular
		END ELSE IF @Power = 2 BEGIN
			SET @Result = @Result + ' ' + @CurrencyInPlural
		END ELSE BEGIN
			SET @Result = @Result + CASE WHEN @ValueOfHundreds > 0 OR @ValueOfThousands > 0 THEN ' ' ELSE @Of END + @CurrencyInPlural
		END
	END ELSE IF @Power <= 2 BEGIN
		SET @Result = @Result + ' ' + @CurrencyInPlural
	END ELSE BEGIN
		SET @Result = @Result + CASE WHEN @ValueOfHundreds > 0 OR @ValueOfThousands > 0 THEN ' ' ELSE @Of END + @CurrencyInPlural
	END
	SET @PartialValue = FLOOR(@Value * 100) % 100
	IF @PartialValue > 0 BEGIN
		IF @PartialValue = 1 BEGIN
			IF @Result = '' BEGIN
				SET @Result = [dbo].[HUNDREDS_IN_WORDS](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInSingular + @Of + @CurrencyInSingular
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[HUNDREDS_IN_WORDS](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInSingular 
			END
		END ELSE BEGIN
			IF @Result = '' BEGIN
				SET @Result = [dbo].[HUNDREDS_IN_WORDS](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInPlural + @Of + @CurrencyInPlural
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[HUNDREDS_IN_WORDS](@PartialValue, @EnglishOrPortuguese) + ' ' + @CentsInPlural
			END
		END
	END		

	RETURN @Minus + ' ' + @Result
END
GO
