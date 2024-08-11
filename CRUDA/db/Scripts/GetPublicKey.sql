USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[GetPublicKey]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[GetPublicKey] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[GetPublicKey](@LoginId BIGINT) AS 
BEGIN 
	SELECT [PublicKey]
		FROM [dbo].[Logs]
		WHERE [Id] = @LoginId

	RETURN @LoginId
END
GO
