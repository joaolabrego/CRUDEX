IF (SELECT object_id('[cruda].[IsEquals]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [cruda].[IsEquals]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [cruda].[IsEquals](@LeftValue SQL_VARIANT
							     ,@RightValue SQL_VARIANT)
RETURNS BIT AS
BEGIN
	DECLARE @Result BIT = 0,
			@LeftType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@LeftValue, 'BaseType'), 'NULL') AS VARCHAR(25)),
			@RightType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@RightValue, 'BaseType'), 'NULL') AS VARCHAR(25))

	IF (@LeftValue IS NULL AND @RightValue IS NULL) OR 
	   (@LeftType = @RightType AND CAST(@LeftValue AS VARBINARY(MAX)) = CAST(@RightValue AS VARBINARY(MAX)))
		SET @Result = 1

	RETURN @Result
END
GO
