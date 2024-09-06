IF(SELECT object_id('[dbo].[NumberInWordsOfHundreds]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[NumberInWordsOfHundreds]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [dbo].[NumberInWordsOfHundreds](@Value AS SMALLINT
											  ,@EnglishOrPortuguese BIT)
RETURNS VARCHAR(MAX) AS  
BEGIN 
	DECLARE @ThirdDigit INT = @Value / 100,
			@SecondDigit INT = CAST(@Value / 10 AS INT) % 10,
			@FirstDigit INT = @Value % 10,
			@And VARCHAR(10),
			@Result VARCHAR(MAX) = '',
			@Separator VARCHAR(5)
	DECLARE @Units TABLE (Id INT, Nome VARCHAR(50))
	DECLARE @Dozens TABLE (Id INT, Nome VARCHAR(50))
	DECLARE @Hundreds TABLE (Id INT, Nome VARCHAR(50))

	IF @EnglishOrPortuguese = 1 BEGIN
		SET @And = ' e '
		INSERT @Units
			VALUES(0, ''),
				  (1, 'Um'),
				  (2, 'Dois'),
				  (3, 'Três'),
				  (4, 'Quatro'),
				  (5, 'Cinco'),
				  (6, 'Seis'),
				  (7, 'Sete'),
				  (8, 'Oito'),
				  (9, 'Nove'),
				  (10, 'Dez'),
				  (11, 'Onze'),
				  (12, 'Doze'),
				  (13, 'Treze'),
				  (14, 'Quatorze'),
				  (15, 'Quinze'),
				  (16, 'Dezesseis'),
				  (17, 'Dezessete'),
				  (18, 'Dezoito'),
				  (19, 'Dezenove')
			
		INSERT @Dozens
			VALUES(0, ''),
				  (1, 'Dez'),
				  (2, 'Vinte'),
				  (3, 'Trinta'),
				  (4, 'Quarenta'),
				  (5, 'Cinquenta'),
				  (6, 'Sessenta'),
				  (7, 'Setenta'),
				  (8, 'Oitenta'),
				  (9, 'Noventa')
			
		INSERT @Hundreds
			VALUES(0, ''),
				  (1, 'Cento'),
				  (2, 'Duzentos'),
				  (3, 'Trezentos'),
				  (4, 'Quatrocentos'),
				  (5, 'Quinhentos'),
				  (6, 'Seiscentos'),
				  (7, 'Setecentos'),
				  (8, 'Oitocentos'),
				  (9, 'Novecentos')
	END ELSE BEGIN
		SET @And = ' and '
		INSERT @Units
			VALUES(0, ''),
				  (1, 'One'),
				  (2, 'Two'),
				  (3, 'Three'),
				  (4, 'Four'),
				  (5, 'Five'),
				  (6, 'Six'),
				  (7, 'Seven'),
				  (8, 'Eight'),
				  (9, 'Nine'),
				  (10, 'Ten'),
				  (11, 'Eleven'),
				  (12, 'Twelve'),
				  (13, 'Thirteen'),
				  (14, 'Fourteen'),
				  (15, 'Fifteen'),
				  (16, 'Sixteen'),
				  (17, 'Seventeen'),
				  (18, 'Eighteen'),
				  (19, 'Nineteen')
			
		INSERT @Dozens
			VALUES(0, ''),
				  (1, 'Ten'),
				  (2, 'Twenty'),
				  (3, 'Thirty'),
				  (4, 'Forty'),
				  (5, 'Fifty'),
				  (6, 'Sixty'),
				  (7, 'Seventy'),
				  (8, 'Eighty'),
				  (9, 'Ninety')
			
		INSERT @Hundreds
			VALUES(0, ''),
				  (1, 'One Hundred'),
				  (2, 'Two Hundred'),
				  (3, 'Three Hundred'),
				  (4, 'Four Hundred'),
				  (5, 'Five Hundred'),
				  (6, 'Six Hundred'),
				  (7, 'Seven Hundred'),
				  (8, 'Eight Hundred'),
				  (9, 'Nine Hundred')
	END
	SET  @Separator = CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE ' ' END
	IF @Value < 20 BEGIN
		SET @Result = (SELECT Nome FROM @Units WHERE Id = @Value)
	END ELSE IF @Value < 100 BEGIN
		SET @Result = (SELECT Nome FROM @Dozens WHERE Id = @SecondDigit) +
						 CASE WHEN @FirstDigit = 0 THEN '' ELSE CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE '-' END + (SELECT Nome FROM @Units WHERE Id = @FirstDigit) END
	END ELSE IF @Value = 100 BEGIN
		SET @Result = CASE WHEN @EnglishOrPortuguese = 1 THEN 'Cem' ELSE 'One Hundred' END
	END ELSE IF @Value % 100 = 0 BEGIN
		SET @Result = (SELECT Nome FROM @Hundreds WHERE Id = @ThirdDigit)
	END ELSE BEGIN
		SET @Result = (SELECT Nome FROM @Hundreds WHERE Id = @ThirdDigit) +
						 CASE WHEN @Value < 20
							  THEN @Separator + (SELECT Nome FROM @Units WHERE Id = @SecondDigit * 10 + @FirstDigit)
						      ELSE @Separator + (SELECT Nome FROM @Dozens WHERE Id = @SecondDigit) + CASE WHEN @FirstDigit = 0 
																										  THEN '' 
																										  ELSE CASE WHEN @EnglishOrPortuguese = 1 THEN @And ELSE '-' END + (SELECT Nome FROM @Units WHERE Id = @FirstDigit)
																									 END
						 END
	END

	RETURN @Result
END
GO
