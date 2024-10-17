IF (SELECT object_id('[crudex].[Transactions]', 'U')) IS NOT NULL
    DROP TABLE [crudex].[Transactions]
CREATE TABLE [crudex].[Transactions]([Id] [int] IDENTITY(1,1) NOT NULL
                                   ,[LoginId] [int] NOT NULL
                                   ,[IsConfirmed] [bit] NULL
                                   ,[CreatedAt] datetime NOT NULL
                                   ,[CreatedBy] varchar(25) NOT NULL
                                   ,[UpdatedAt] datetime NULL
                                   ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [crudex].[Transactions] ADD CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED([Id])
CREATE INDEX [IDX_Transactions_LoginId_IsConfirmed] ON [crudex].[Transactions]([LoginId], [IsConfirmed])
GO
