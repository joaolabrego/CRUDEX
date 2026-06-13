IF(SELECT object_id('[dbo].[TransactionBegin]', 'P')) IS NULL
	EXEC('CREATE PROCEDURE [dbo].[TransactionBegin] AS PRINT 1')
GO
ALTER PROCEDURE[dbo].[TransactionBegin](@SessionId BIGINT
										 ,@UserName VARCHAR(25)
										 ,@ReturnValue BIGINT OUT) AS BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	IF @SessionId IS NULL
		THROW 51000, 'Valor de @SessionId Ã© requerido', 1
	IF @UserName IS NULL
		THROW 51000, 'Valor de @UserName Ã© requerido', 1
	IF EXISTS(SELECT 1 FROM [dbo].[Transactions] WHERE [SessionId] = @SessionId AND [IsConfirmed] IS NULL)
		THROW 51000, 'HÃ¡ transaÃ§Ã£o pendente neste @SessionId', 1
	
	DECLARE @TransactionId BIGINT

	EXEC [dbo].[NewId] 'crudex', 'crudex', 'Transactions', @TransactionId OUT
	INSERT [dbo].[Transactions] ([Id]
								,[SessionId]
								,[IsConfirmed]
								,[CreatedAt]
								,[CreatedBy])
							VALUES (@TransactionId
								   ,@SessionId
								   ,NULL
								   ,GETDATE()
								   ,@UserName)
	SET @ReturnValue = @TransactionId

	RETURN 0
END
GO
