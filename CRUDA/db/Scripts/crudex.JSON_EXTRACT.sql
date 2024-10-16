IF (SELECT object_id('[crudex].[JSON_EXTRACT]', 'FN')) IS NULL
    EXEC('CREATE FUNCTION [crudex].[JSON_EXTRACT]() RETURNS NVARCHAR(MAX) AS BEGIN RETURN '''' END')
GO
ALTER FUNCTION [crudex].[JSON_EXTRACT](@json NVARCHAR(MAX),
                                              @propertyPath NVARCHAR(MAX))
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @result NVARCHAR(MAX);

    SET @result = JSON_QUERY(@json, @propertyPath);

    IF @result IS NULL
        SET @result = JSON_VALUE(@json, @propertyPath);

    RETURN @result;
END
GO
