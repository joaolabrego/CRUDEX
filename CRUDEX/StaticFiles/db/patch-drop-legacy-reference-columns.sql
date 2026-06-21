/*
  Remove colunas legadas ParentTableId (Tables) e ReferenceTableId (Columns).

  ORDEM RECOMENDADA:
  1. Remover as colunas das abas Columns em Tables e Columns no Excel
  2. Regenerar: dotnet run --project CRUDEX -- --generate-script
  3. Aplicar o SCRIPT-CRUDEX.sql (ou ao menos TableValidate + ColumnValidate + DDL)
  4. Se o banco já estiver atualizado nas procedures, aplicar só este patch para o DDL

  Sem regenerar TableValidate/ColumnValidate, editar metadados de Tables/Columns falhará
  enquanto as procedures ainda citarem ParentTableId ou ReferenceTableId.
*/

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE [name] = N'FK_Tables_Tables_11')
    ALTER TABLE [dbo].[Tables] DROP CONSTRAINT [FK_Tables_Tables_11];
GO

IF COL_LENGTH(N'dbo.Tables', N'ParentTableId') IS NOT NULL
    ALTER TABLE [dbo].[Tables] DROP COLUMN [ParentTableId];
GO

IF COL_LENGTH(N'dbo.Columns', N'ReferenceTableId') IS NOT NULL
    ALTER TABLE [dbo].[Columns] DROP COLUMN [ReferenceTableId];
GO
