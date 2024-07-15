USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF (SELECT object_id('[dbo].[F_IsEquals]', 'FN')) IS NOT NULL
	DROP FUNCTION [dbo].[F_IsEquals]
GO
CREATE FUNCTION [dbo].[F_IsEquals](@LeftComparand SQL_VARIANT,
								   @RightComparand SQL_VARIANT)
RETURNS BIT AS
BEGIN
	DECLARE @Result BIT = 0,
			@LeftType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@LeftComparand, 'BaseType'), 'NULL') AS VARCHAR(25)),
			@RightType VARCHAR(25) = CAST(ISNULL(SQL_VARIANT_PROPERTY(@RightComparand, 'BaseType'), 'NULL') AS VARCHAR(25))

	IF (@LeftComparand IS NULL AND @RightComparand IS NULL) OR 
	   (@LeftType = @RightType AND @LeftComparand = @RightComparand)
		SET @Result = 1

	RETURN @Result
END
GO