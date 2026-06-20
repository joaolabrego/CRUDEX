-- Remove Comparators.IsOneChar (tratamento visual substituído por largura igual botão/lista).

IF COL_LENGTH('[dbo].[Comparators]', 'IsOneChar') IS NOT NULL
BEGIN
    DECLARE @df NVARCHAR(128);
    SELECT @df = dc.name
      FROM sys.default_constraints dc
      JOIN sys.columns c ON c.default_object_id = dc.object_id
     WHERE dc.parent_object_id = OBJECT_ID('[dbo].[Comparators]')
       AND c.name = 'IsOneChar';
    IF @df IS NOT NULL
        EXEC('ALTER TABLE [dbo].[Comparators] DROP CONSTRAINT [' + @df + ']');
    ALTER TABLE [dbo].[Comparators] DROP COLUMN [IsOneChar];
END
GO
