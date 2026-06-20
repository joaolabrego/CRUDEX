-- Remove SqlComparator/JsComparator de Comparators (lógica em ComparatorRegistry / TComparator).
-- Após aplicar: regerar SCRIPT-CRUDEX.sql (Scripts.Generate) e executar no SQL Server.

IF COL_LENGTH('[dbo].[Comparators]', 'SqlComparator') IS NOT NULL
    ALTER TABLE [dbo].[Comparators] DROP COLUMN [SqlComparator];
GO
IF COL_LENGTH('[dbo].[Comparators]', 'JsComparator') IS NOT NULL
    ALTER TABLE [dbo].[Comparators] DROP COLUMN [JsComparator];
GO
