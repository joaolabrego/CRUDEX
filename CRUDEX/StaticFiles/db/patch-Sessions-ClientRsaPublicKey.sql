IF COL_LENGTH('[dbo].[Sessions]', 'ClientRsaPublicKey') IS NULL
    ALTER TABLE [dbo].[Sessions] ADD [ClientRsaPublicKey] nvarchar(512) NULL;
GO
