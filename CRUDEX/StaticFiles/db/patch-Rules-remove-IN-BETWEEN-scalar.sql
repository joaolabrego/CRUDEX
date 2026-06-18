-- Remove IN / NOT IN / BETWEEN / NOT BETWEEN das categorias escalares (string, number, date, datetime, time).
-- Fonte de verdade: aba Rules em CRUDEX.xlsm — manter alinhado após editar a planilha.

DELETE FROM [dbo].[Rules]
 WHERE [ComparatorId] IN (7, 8, 11, 12)
   AND [CategoryId] IN (1, 2, 3, 4, 5);
GO
