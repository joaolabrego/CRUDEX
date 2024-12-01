USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[NumberInWords]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[NumberInWords]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
-- SELECT dbo.NumberInWords (600000, 1, 'Real', 'Reais', 'Centavo', 'Centavos') 
ALTER FUNCTION [dbo].[NumberInWords](@Value AS DECIMAL(18,2),
									  @PortugueseOrEnglish BIT = 0,
									  @CurrencyInSingular VARCHAR(50) = NULL,
									  @CurrencyInPlural VARCHAR(50) = NULL,
									  @CentsInSingular VARCHAR(50) = NULL,
									  @CentsInPlural VARCHAR(50) = NULL)
RETURNS VARCHAR(MAX) AS  
BEGIN 
	DECLARE @Power INT = 0,
		    @Separator VARCHAR(5) = '',
		    @PartialValue BIGINT,
		    @Digito INT = 0,
		    @LastDigit INT,
			@Result VARCHAR(MAX) = '',
			@Minus VARCHAR(10) = '',
			@Of VARCHAR(10),
			@And VARCHAR(10),
			@ValueOfHundreds INT = 0,
			@ValueOfThousands INT = 0
	DECLARE @Powers TABLE (Id INT, NomeSingular VARCHAR(50), NomePlural VARCHAR(50))

	IF @PortugueseOrEnglish = 1 BEGIN
		IF @CurrencyInSingular IS NULL
			SET @CurrencyInSingular = 'Real'
		IF @CurrencyInPlural IS NULL
			SET @CurrencyInPlural = 'Reais'
		IF @CentsInSingular IS NULL
			SET @CentsInSingular = 'Centavo'
		IF @CentsInPlural IS NULL
			SET @CentsInPlural = 'Centavos'
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
	END ELSE BEGIN
		IF @CurrencyInSingular IS NULL
			SET @CurrencyInSingular = 'Dollar'
		IF @CurrencyInPlural IS NULL
			SET @CurrencyInPlural = 'Dollars'
		IF @CentsInSingular IS NULL
			SET @CentsInSingular = 'Cent'
		IF @CentsInPlural IS NULL
			SET @CentsInPlural = 'Cents'
		SET @Of = ' of '
		SET @And = ' and '
		IF @Value < 0 BEGIN
			SET @Value = -@Value
			SET @Minus = 'Minus'
		END	
		INSERT @Powers
			VALUES(0,'', ''),
				  (1,'Thousand', 'Thousands'),
				  (2,'Million', 'Millions'),
				  (3,'Billion', 'Billions'),
				  (4,'Trillion', 'Trillions'),
				  (5,'Quadrillion', 'Quadrillions'),
				  (6,'Quintillion', 'Quintillions'),
				  (7,'Sextillion', 'Sextillions'),
				  (8,'Septillion', 'Septillions'),
				  (9,'Octillion', 'Octillions'),
				  (10,'Nonillion', 'Nonillions'),
				  (11,'Decillion', 'Decillion'),
				  (12,'Undecillion', 'Undecillions'),
				  (13,'Duodecillion', 'Duodecillions'),
				  (14,'Tredecillion', 'Tredecillions')
	END
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
			 SET @Result = [dbo].[NumberInWordsOfHundreds](@Digito, @PortugueseOrEnglish) + ' ' + 
							  (SELECT NomeSingular FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END ELSE IF @Digito > 0 BEGIN
			 SET @Result = [dbo].[NumberInWordsOfHundreds](@Digito, @PortugueseOrEnglish) + ' ' + 
							  (SELECT NomePlural FROM @Powers WHERE Id = @Power) + 
							  @Separator + @Result
		END
		SET @PartialValue = @PartialValue / 1000
		IF @Digito > 0 BEGIN
			IF (@Power = 0) BEGIN
				SET @Separator = @And
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
				SET @Result = [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInSingular + @Of + @CurrencyInSingular
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInSingular 
			END
		END ELSE BEGIN
			IF @Result = '' BEGIN
				SET @Result = [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInPlural + @Of + @CurrencyInPlural
			END ELSE BEGIN
				SET @Result = @Result + @And + [dbo].[NumberInWordsOfHundreds](@PartialValue, @PortugueseOrEnglish) + ' ' + @CentsInPlural
			END
		END
	END		

	RETURN @Minus + ' ' + @Result
END
GO
