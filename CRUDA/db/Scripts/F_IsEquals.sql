USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF (SELECT object_id('[dbo].[F_IsEquals]', 'FN')) IS NOT NULL
	DROP FUNCTION [dbo].[F_IsEquals]
GO
CREATE FUNCTION [dbo].[F_IsEquals](@LeftValue SQL_VARIANT,
								   @RightValue SQL_VARIANT)
RETURNS BIT AS
BEGIN
	DECLARE @Result BIT = 0,
			@LeftType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@LeftValue, 'BaseType'), 'NULL') AS VARCHAR(50)),
			@RightType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@RightValue, 'BaseType'), 'NULL') AS VARCHAR(50))

	IF (@LeftValue IS NULL AND @RightValue IS NULL) OR 
	   (@LeftType = @RightType AND @LeftValue = @RightValue)
		SET @Result = 1

	RETURN @Result
END
GO