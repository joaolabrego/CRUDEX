-- Adiciona ElseValue em Behaviors (valor quando a expressão é falsa).
-- Executar numa base já existente; o SCRIPT-CRUDEX.sql regenerado já inclui a coluna.

IF COL_LENGTH('dbo.Behaviors', 'ElseValue') IS NULL
    ALTER TABLE [dbo].[Behaviors] ADD [ElseValue] nvarchar(max) NULL;
GO
