DECLARE @ConstraintName sysname;

SELECT @ConstraintName = [name]
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID('[dbo].[Transactions]')
          AND COL_NAME(parent_object_id, parent_column_id) = 'IsConfirmed';

IF @ConstraintName IS NOT NULL
    EXEC('ALTER TABLE [dbo].[Transactions] DROP CONSTRAINT [' + @ConstraintName + ']');
GO
