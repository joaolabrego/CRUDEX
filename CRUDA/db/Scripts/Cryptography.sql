DECLARE @Value NVARCHAR(MAX) = REPLICATE('ABCDEFGHIJKLM',100000),
		@CryptographyKey NVARCHAR(MAX) = null,
		@Encrypted NVARCHAR(MAX), 
		@Decrypted NVARCHAR(MAX), 
		@IsEncryptedValue BIT
SET @Value = @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value
SET @Value = @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value
SET @Value = @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value
SET @Value = @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value
SET @Value = @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value + @Value
exec [dbo].[Cryptography] @Value,@CryptographyKey out, @Encrypted OUT, @IsEncryptedValue OUT
SELECT LEN(@Value), @CryptographyKey AS CryptographyKey, @Encrypted AS Encrypted, @IsEncryptedValue AS IsEncryptedValue
exec [dbo].[Cryptography] @Encrypted,@CryptographyKey OUT, @Decrypted OUT, @IsEncryptedValue OUT
SELECT LEN(@Encrypted), @CryptographyKey AS CryptographyKey, @Decrypted AS Decrypted, @IsEncryptedValue AS IsEncryptedValue

USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Cryptography](@Value NVARCHAR(MAX),
									  @CryptographyKey NVARCHAR(MAX) = NULL OUT,
									  @Result NVARCHAR(MAX) = NULL OUT,
									  @IsEncryptedValue BIT = NULL OUT) AS
BEGIN
	DECLARE @CHARSET NVARCHAR(MAX) = '0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz+*&%$#!?.:=@<>,;/[]{}()',
			@DEFAULT_LENGTH INT = 100,
			@CRYPTOPREFIX NVARCHAR(MAX) = 'encrypted',
			@I INT,
			@ASCII INT,
			@SPACE INT = ASCII(SPACE(1)),
			@Random INT

	IF LEN(ISNULL(@CryptographyKey, '')) = 0 BEGIN
		SET @I = 1
		SET @CryptographyKey = ''
		WHILE @I <= @DEFAULT_LENGTH BEGIN
			SET @Random = CAST(FLOOR(RAND() * LEN(@CHARSET)) AS INT) + 1
			SET @CryptographyKey = @CryptographyKey + SUBSTRING(@CHARSET, @Random, 1)
			SET @I = @I + 1
		END
	END
	IF LEN(ISNULL(@Value, '')) > 0 BEGIN
		DECLARE @Factor INT = -1,
				@Prefix NVARCHAR(MAX) = @CRYPTOPREFIX
		SET @IsEncryptedValue = CASE WHEN LEN(@Value) >= LEN(@CRYPTOPREFIX) AND LEFT(@Value, LEN(@CRYPTOPREFIX)) = @CRYPTOPREFIX THEN 1 ELSE 0 END

		IF @IsEncryptedValue = 1 BEGIN
			SELECT @Factor = 1,
					@Value = RIGHT(@Value, LEN(@Value) - LEN(@CRYPTOPREFIX)),
					@Prefix = ''
		END ELSE BEGIN
			SET @I = 1
			WHILE @I <= LEN(@VALUE) BEGIN
				IF SUBSTRING(@Value, @I, 1) = '#'
					THROW 51000, 'Stored Procedure Cryptography: Valor não pode conter #.', 1
				SET @I = @I + 1
			END
			SET @Value = @Value + '#'
			SET @I = LEN(@Value) + 1
			WHILE @I <= @DEFAULT_LENGTH BEGIN
				SET @Random = CAST(FLOOR(RAND() * LEN(@CHARSET)) AS INT) + 1
				SELECT @Value = @Value + SUBSTRING(@CHARSET, @Random, 1),
						@I = @I + 1
			END
		END
		SELECT @Result = '',
				@I = 1
		WHILE @I <= LEN(@Value) BEGIN
			SET @ASCII = ASCII(SUBSTRING(@Value, @I, 1))
			IF @ASCII >= @SPACE BEGIN
				SET @ASCII = ((@ASCII - @SPACE) + ASCII(SUBSTRING(@CryptographyKey, @I % LEN(@CryptographyKey) + 1, 1)) * @Factor) % (256 - @SPACE)
				IF @ASCII < 0 
					SET @ASCII = @ASCII + (256 - @SPACE)
				SET @ASCII = @ASCII + @SPACE
			END
			SET @Result = @Result + CHAR(@ASCII)
			SET @I = @I + 1
		END	
		SET @Result = @Prefix + @Result
		IF @IsEncryptedValue = 1
			SET @Result = LEFT(@Result, CHARINDEX('#', @Result) - 1)
	END

	--SELECT @Value as Value, @Result as Result, @CryptographyKey as CryptoKey, @IsEncryptedValue as IsEncryptedValue
END
