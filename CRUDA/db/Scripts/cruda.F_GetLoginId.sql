USE [cruda]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF(SELECT object_id('[dbo].[F_GetLoginId]', 'FN')) IS NULL
	EXEC('CREATE FUNCTION [dbo].[F_GetLoginId]() RETURNS BIT AS BEGIN RETURN 1 END')
GO
ALTER FUNCTION [dbo].[F_GetLoginId](@SystemName VARCHAR(25),
								    @UserName VARCHAR(25))
RETURNS BIGINT AS
BEGIN 
	DECLARE @SystemId BIGINT,
			@UserId BIGINT,
			@LoginId BIGINT

	SELECT @SystemId = [Id] FROM [dbo].[Systems] WHERE [Name] = @SystemName
	IF @SystemId IS NOT NULL BEGIN
		SELECT @UserId = [U].[Id]
			FROM [dbo].Users [U]
				INNER JOIN [dbo].[SystemsUsers] [SU] ON [SU].[UserId] = [U].[Id]
			WHERE [SU].[SystemId] = @SystemId
					AND [U].[Name] = @UserName
		IF @UserId IS NOT NULL
			SELECT @LoginId = [Id]
				FROM [dbo].[Logins]
				WHERE [SystemId] = @SystemId
						AND [UserId] = @UserId
						AND [Logged] = 1
	END

	RETURN @LoginId
END
GO
