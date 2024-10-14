IF (SELECT object_id('[crudax].[Operations]', 'U')) IS NOT NULL
    DROP TABLE [crudax].[Operations]
CREATE TABLE [crudax].[Operations]([Id] [int] IDENTITY(1,1) NOT NULL
                                 ,[TransactionId] [int] NOT NULL
                                 ,[TableName] [varchar](25) NOT NULL
                                 ,[Action] [varchar](15) NOT NULL
                                 ,[LastRecord] [varchar](max) NULL
                                 ,[ActualRecord] [varchar](max) NOT NULL
                                 ,[IsConfirmed] [bit] NULL
                                 ,[CreatedAt] datetime NOT NULL
                                 ,[CreatedBy] varchar(25) NOT NULL
                                 ,[UpdatedAt] datetime NULL
                                 ,[UpdatedBy] varchar(25) NULL)
ALTER TABLE [crudax].[Operations] ADD CONSTRAINT PK_Operations PRIMARY KEY CLUSTERED([Id])
CREATE INDEX [IDX_Operations_TransactionId_TableName_Action_IsConfirmed] ON [crudax].[Operations]([TransactionId], [TableName], [Action], [IsConfirmed])
GO
ALTER TABLE [crudax].[Operations] WITH CHECK 
    ADD CONSTRAINT [FK_Operations_Transactions] 
    FOREIGN KEY([TransactionId]) 
    REFERENCES [crudax].[Transactions] ([Id])
GO
ALTER TABLE [crudax].[Operations] CHECK CONSTRAINT [FK_Operations_Transactions]
GO
