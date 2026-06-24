using CRUDEX.Classes;
using ExcelDataReader;
using System.Data;
using System.Text;

namespace crudex.Classes
{
    /// <summary>
    /// Carrega CRUDEX_Novissimo.xlsm (abas por Alias) e normaliza para o DataSet
    /// consumido por Scripts.Generate — fonte de verdade 2.0.
    /// </summary>
    public static class NovissimoExcel
    {
        const long DefaultEngineId = 1;

        public static bool IsNovissimoWorkbook(string filePath) =>
            Path.GetFileName(filePath).Contains("Novissimo", StringComparison.OrdinalIgnoreCase);

        public static async Task<DataSet> LoadAsync(string filePath)
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);

            await using var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 4096, useAsync: true);
            using var reader = ExcelReaderFactory.CreateReader(stream);

            var dataset = await Task.Run(() => reader.AsDataSet(new ExcelDataSetConfiguration
            {
                ConfigureDataTable = _ => new ExcelDataTableConfiguration { UseHeaderRow = true },
            }));

            var aliasToSql = BuildAliasMap(dataset);
            RenameTablesByAlias(dataset, aliasToSql);
            NormalizeTypoColumns(dataset);
            EnsureLegacyMetadataColumns(dataset);
            EnrichColumnsTable(dataset);
            EnrichTypesFromCategories(dataset);
            EnrichMappingsFromSqlServer(dataset);
            NormalizeOwnerIdColumnTypes(dataset);
            FixKnownColumnDataTypes(dataset);
            BridgeLegacySchema(dataset);
            BridgeLegacyCompatibility(dataset);

            return dataset;
        }

        static Dictionary<string, string> BuildAliasMap(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Tbl"))
                throw new Exception("Planilha Novíssimo sem aba Tbl.");

            var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (DataRow row in dataset.Tables["Tbl"]!.Rows)
            {
                var alias = Settings.ToString(row["Alias"]);
                var name = Settings.ToString(row["Name"]);
                if (string.IsNullOrWhiteSpace(alias) || string.IsNullOrWhiteSpace(name))
                    continue;
                map[alias] = name;
            }

            if (map.Count == 0)
                throw new Exception("Tbl não possui pares Alias/Name.");

            return map;
        }

        static void RenameTablesByAlias(DataSet dataset, Dictionary<string, string> aliasToSql)
        {
            foreach (DataTable table in dataset.Tables.Cast<DataTable>().ToList())
            {
                if (aliasToSql.TryGetValue(table.TableName, out var sqlName))
                    table.TableName = sqlName;
            }
        }

        static long GetRowId(DataRow row) =>
            Settings.ToLong(GetColumnValue(row, "Id"));

        static object GetColumnValue(DataRow row, string name)
        {
            if (TryGetColumnValue(row, name, out var value))
                return value!;

            throw new Exception($"Coluna '{name}' não encontrada em '{row.Table.TableName}'.");
        }

        static bool TryGetColumnValue(DataRow row, string name, out object? value)
        {
            if (row.Table.Columns.Contains(name))
            {
                value = row[name];
                return true;
            }

            var marked = $"*{name}";
            if (row.Table.Columns.Contains(marked))
            {
                value = row[marked];
                return true;
            }

            value = null;
            return false;
        }

        static void StripPrimaryKeyMarkers(DataSet dataset)
        {
            foreach (DataTable table in dataset.Tables)
            {
                foreach (DataColumn column in table.Columns.Cast<DataColumn>().ToList())
                {
                    var normalized = NormalizeHeader(column.ColumnName);
                    if (!string.Equals(column.ColumnName, normalized, StringComparison.Ordinal))
                        column.ColumnName = normalized;
                }
            }
        }

        static string NormalizeHeader(string header)
        {
            var value = (header ?? string.Empty).Trim();
            return value.StartsWith('*') ? value[1..].Trim() : value;
        }

        static void NormalizeTypoColumns(DataSet dataset)
        {
            foreach (DataTable table in dataset.Tables)
            {
                RenameColumnIfExists(table, "OwnertId", "OwnerId");
                RenameColumnIfExists(table, "IsParentChildren", "IsParentChild");
                NormalizeBooleanColumnNames(table);
            }

            if (dataset.Tables.Contains("Columns"))
                NormalizeColumnsMetadata(dataset.Tables["Columns"]!);

            if (dataset.Tables.Contains("References"))
                RenameColumnIfExists(dataset.Tables["References"]!, "IsParentChildren", "IsParentChild");
        }

        static void NormalizeBooleanColumnNames(DataTable table)
        {
            RenameColumnIfExists(table, "IsPrimaryKey", "IsPrimarykey");
            RenameColumnIfExists(table, "IsAutoincrement", "IsAutoIncrement");
        }

        static void NormalizeColumnsMetadata(DataTable columns)
        {
            if (!columns.Columns.Contains("Title") && columns.Columns.Contains("Description"))
                columns.Columns.Add("Title", typeof(string));

            foreach (DataRow row in columns.Rows)
            {
                if (TryGetColumnValue(row, "Name", out var nameValue))
                {
                    var name = Settings.ToString(nameValue);
                    if (string.Equals(name, "OwnertId", StringComparison.OrdinalIgnoreCase))
                        SetColumnValue(row, "Name", "OwnerId");
                    else if (string.Equals(name, "IsParentChildren", StringComparison.OrdinalIgnoreCase))
                        SetColumnValue(row, "Name", "IsParentChild");
                }

                if (string.IsNullOrWhiteSpace(Settings.ToString(TryGetColumnValue(row, "Title", out var title) ? title : null)))
                {
                    var caption = TryGetColumnValue(row, "Caption", out var captionValue) ? captionValue : null;
                    var description = TryGetColumnValue(row, "Description", out var descriptionValue) ? descriptionValue : null;
                    SetColumnValue(row, "Title", caption ?? description ?? string.Empty);
                }
            }
        }

        static void SetColumnValue(DataRow row, string name, object? value)
        {
            if (row.Table.Columns.Contains(name))
                row[name] = value ?? DBNull.Value;
            else if (row.Table.Columns.Contains($"*{name}"))
                row[$"*{name}"] = value ?? DBNull.Value;
        }

        static void RenameColumnIfExists(DataTable table, string from, string to)
        {
            if (!table.Columns.Contains(from) || table.Columns.Contains(to))
                return;

            table.Columns[from]!.ColumnName = to;
        }

        static void EnsureLegacyMetadataColumns(DataSet dataset)
        {
            if (dataset.Tables.Contains("Columns"))
            {
                var columns = dataset.Tables["Columns"]!;
                EnsureColumn(columns, "Default");
                EnsureColumn(columns, "Minimum");
                EnsureColumn(columns, "Maximum");
                EnsureColumn(columns, "ReferenceTableId");
            }

            if (dataset.Tables.Contains("Domains"))
            {
                var domains = dataset.Tables["Domains"]!;
                EnsureColumn(domains, "Minimum");
                EnsureColumn(domains, "Maximum");
                EnsureColumn(domains, "#CategoryName");
            }

            if (dataset.Tables.Contains("Types"))
            {
                var types = dataset.Tables["Types"]!;
                EnsureColumn(types, "Minimum");
                EnsureColumn(types, "Maximum");
                EnsureColumn(types, "AskPrimarykey");
            }

            if (dataset.Tables.Contains("Categories"))
            {
                var categories = dataset.Tables["Categories"]!;
                EnsureColumn(categories, "IsOrdenable");
            }
        }

        static void EnrichColumnsTable(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Columns"))
                throw new Exception("Tabela Columns não encontrada após mapear Novíssimo.");

            var columns = dataset.Tables["Columns"]!;
            var tables = dataset.Tables.Contains("Tables")
                ? dataset.Tables["Tables"]!.AsEnumerable().ToDictionary(row => GetRowId(row))
                : new Dictionary<long, DataRow>();
            var domains = dataset.Tables.Contains("Domains")
                ? dataset.Tables["Domains"]!.AsEnumerable().ToDictionary(row => GetRowId(row))
                : new Dictionary<long, DataRow>();
            var types = dataset.Tables.Contains("Types")
                ? dataset.Tables["Types"]!.AsEnumerable().ToDictionary(row => GetRowId(row))
                : new Dictionary<long, DataRow>();
            var categories = dataset.Tables.Contains("Categories")
                ? dataset.Tables["Categories"]!.AsEnumerable().ToDictionary(row => GetRowId(row))
                : new Dictionary<long, DataRow>();
            var maps = dataset.Tables.Contains("Mappings")
                ? dataset.Tables["Mappings"]!.AsEnumerable()
                    .Where(row => Settings.ToLong(GetColumnValue(row, "EngineId")) == DefaultEngineId)
                    .GroupBy(row => Settings.ToLong(GetColumnValue(row, "TypeId")))
                    .ToDictionary(group => group.Key, group => group.First())
                : new Dictionary<long, DataRow>();

            EnsureColumn(columns, "#DataType");
            EnsureColumn(columns, "#TypeName");
            EnsureColumn(columns, "#CategoryName");
            EnsureColumn(columns, "#TableName");
            EnsureColumn(columns, "#TableAlias");
            EnsureColumn(columns, "#DomainName");

            foreach (DataRow row in columns.Rows)
            {
                var tableId = Settings.ToLong(GetColumnValue(row, "TableId"));
                if (!tables.TryGetValue(tableId, out var table))
                    throw new Exception($"Columns.TableId {tableId} sem entrada em Tables.");

                var domainId = Settings.ToLong(GetColumnValue(row, "DomainId"));
                if (!domains.TryGetValue(domainId, out var domain))
                    throw new Exception($"Columns.DomainId {domainId} sem entrada em Domains.");

                var typeId = Settings.ToLong(GetColumnValue(domain, "TypeId"));
                if (!types.TryGetValue(typeId, out var type))
                    throw new Exception($"Domains.TypeId {typeId} sem entrada em Types.");

                if (!maps.TryGetValue(typeId, out var map))
                    throw new Exception($"Mappings sem tipo EngineId={DefaultEngineId}, TypeId={typeId}.");

                var categoryId = Settings.ToLong(GetColumnValue(type, "CategoryId"));
                categories.TryGetValue(categoryId, out var category);

                row["#TableName"] = GetColumnValue(table, "Name");
                row["#TableAlias"] = GetColumnValue(table, "Alias");
                row["#DomainName"] = GetColumnValue(domain, "Name");
                row["#TypeName"] = map["Name"];
                row["#CategoryName"] = category != null ? GetColumnValue(category, "Name") : domain["#CategoryName"];
                row["#DataType"] = BuildPhysicalType(domain, map);
            }
        }

        static void EnsureColumn(DataTable table, string name)
        {
            if (!table.Columns.Contains(name))
                table.Columns.Add(name, typeof(string));
        }

        static string BuildPhysicalType(DataRow domain, DataRow map)
        {
            var mapName = Settings.ToString(map["Name"]);
            var length = domain.Table.Columns.Contains("Length") ? Settings.ToLong(domain["Length"]) : 0L;
            var decimals = domain.Table.Columns.Contains("Decimals") ? Settings.ToLong(domain["Decimals"]) : 0L;

            if (mapName.Contains("(n)", StringComparison.OrdinalIgnoreCase))
                return length > 0 ? mapName.Replace("(n)", $"({length})", StringComparison.OrdinalIgnoreCase) : mapName;

            if (mapName.Contains("(max)", StringComparison.OrdinalIgnoreCase))
                return mapName;

            if (decimals > 0 && length > 0)
                return $"{mapName}({length},{decimals})";

            if (length > 0)
                return $"{mapName}({length})";

            return mapName;
        }

        static bool ParseBoolean(object? value)
        {
            if (value is bool boolean)
                return boolean;
            if (value is DBNull or null)
                return false;

            var text = Settings.ToString(value);
            if (string.Equals(text, "true", StringComparison.OrdinalIgnoreCase) || text == "1")
                return true;
            if (string.Equals(text, "false", StringComparison.OrdinalIgnoreCase) || text == "0" || text == string.Empty)
                return false;

            return Settings.ToLong(value) != 0;
        }

        static void EnrichTypesFromCategories(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Types") || !dataset.Tables.Contains("Categories"))
                return;

            var types = dataset.Tables["Types"]!;
            if (!types.Columns.Contains("IsLikeable"))
                types.Columns.Add("IsLikeable", typeof(bool));

            var categories = dataset.Tables["Categories"]!.AsEnumerable()
                .ToDictionary(row => GetRowId(row));

            foreach (DataRow type in types.Rows)
            {
                var isLikeable = false;
                if (TryGetColumnValue(type, "IsLikeable", out var existing))
                    isLikeable = ParseBoolean(existing);
                else if (categories.TryGetValue(Settings.ToLong(GetColumnValue(type, "CategoryId")), out var category))
                {
                    if (category.Table.Columns.Contains("IsLikeable"))
                        isLikeable = ParseBoolean(GetColumnValue(category, "IsLikeable"));
                    else
                        isLikeable = string.Equals(
                            Settings.ToString(GetColumnValue(category, "Name")),
                            "string",
                            StringComparison.OrdinalIgnoreCase);
                }

                type["IsLikeable"] = isLikeable;
            }
        }

        static void FixKnownColumnDataTypes(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Columns"))
                return;

            foreach (DataRow col in dataset.Tables["Columns"]!.Rows)
            {
                var table = Settings.ToString(col["#TableName"]);
                var name = Settings.ToString(GetColumnValue(col, "Name"));
                if (table == "Scripts" && name == "Script")
                {
                    col["#DataType"] = "nvarchar(max)";
                    col["#CategoryName"] = "text";
                }
                else if (table == "Scripts" && name == "DatabaseId")
                    col["#DataType"] = "bigint";
            }
        }

        static void NormalizeOwnerIdColumnTypes(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Columns"))
                return;

            var columns = dataset.Tables["Columns"]!.AsEnumerable().ToList();
            var ownersId = columns.FirstOrDefault(row =>
                string.Equals(Settings.ToString(row["#TableName"]), "Owners", StringComparison.OrdinalIgnoreCase)
                && string.Equals(Settings.ToString(GetColumnValue(row, "Name")), "Id", StringComparison.OrdinalIgnoreCase));
            if (ownersId == null)
                return;

            var ownerIdType = Settings.ToString(ownersId["#DataType"]);
            foreach (var row in columns.Where(row => string.Equals(Settings.ToString(GetColumnValue(row, "Name")), "OwnerId", StringComparison.OrdinalIgnoreCase)))
                row["#DataType"] = ownerIdType;
        }

        static void EnrichMappingsFromSqlServer(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Mappings"))
                return;

            var mappings = dataset.Tables["Mappings"]!;
            var engineOneNames = mappings.AsEnumerable()
                .Where(row => Settings.ToLong(GetColumnValue(row, "EngineId")) == DefaultEngineId)
                .GroupBy(row => Settings.ToLong(GetColumnValue(row, "TypeId")))
                .ToDictionary(group => group.Key, group => Settings.ToString(GetColumnValue(group.First(), "Name")));

            foreach (DataRow row in mappings.Rows)
            {
                if (!string.IsNullOrWhiteSpace(Settings.ToString(GetColumnValue(row, "Name"))))
                    continue;

                var typeId = Settings.ToLong(GetColumnValue(row, "TypeId"));
                if (engineOneNames.TryGetValue(typeId, out var name) && !string.IsNullOrWhiteSpace(name))
                    SetColumnValue(row, "Name", name);
            }
        }

        static void BridgeLegacySchema(DataSet dataset)
        {
            BridgeSystemsLegacyColumns(dataset);
            BridgeDatabasesLegacyColumns(dataset);
            BridgeConnectionsLegacyColumns(dataset);
            BridgeSessionsLegacyColumns(dataset);
            BridgeEnginesDefaults(dataset);
            BridgeStringsDefaults(dataset);
            FixLegacyColumnDataTypes(dataset);
        }

        static void FixLegacyColumnDataTypes(DataSet dataset)
        {
            OverrideColumnDataType(dataset, "Connections", "ConnectionString", "nvarchar(max)", "text");
            OverrideColumnDataType(dataset, "Databases", "IsLegacy", "bit", "boolean");
            OverrideColumnDataType(dataset, "Databases", "Folder", "nvarchar(max)", "text");
        }

        static void OverrideColumnDataType(DataSet dataset, string tableName, string columnName, string dataType, string categoryName)
        {
            if (!dataset.Tables.Contains("Columns"))
                return;

            var tableId = GetTableId(dataset, tableName);
            var column = FindColumnRow(dataset.Tables["Columns"]!, tableId, columnName);
            if (column == null)
                return;

            column["#DataType"] = dataType;
            column["#CategoryName"] = categoryName;
        }

        static long GetTableId(DataSet dataset, string tableName)
        {
            if (!dataset.Tables.Contains("Tables"))
                return 0;

            foreach (DataRow row in dataset.Tables["Tables"]!.Rows)
            {
                if (string.Equals(Settings.ToString(GetColumnValue(row, "Name")), tableName, StringComparison.OrdinalIgnoreCase))
                    return GetRowId(row);
            }

            return 0;
        }

        static long NextColumnId(DataTable columns)
        {
            long max = 0;
            foreach (DataRow row in columns.Rows)
                max = Math.Max(max, GetRowId(row));
            return max + 1;
        }

        static DataRow? FindColumnRow(DataTable columns, long tableId, string columnName) =>
            columns.AsEnumerable().FirstOrDefault(row =>
                Settings.ToLong(GetColumnValue(row, "TableId")) == tableId
                && string.Equals(Settings.ToString(GetColumnValue(row, "Name")), columnName, StringComparison.OrdinalIgnoreCase));

        static void EnsureLegacyPhysicalColumn(DataSet dataset, string tableName, string columnName, string cloneFromColumn, Action<DataRow>? populate = null)
        {
            if (!dataset.Tables.Contains("Columns") || !dataset.Tables.Contains(tableName))
                return;

            var columns = dataset.Tables["Columns"]!;
            var tableId = GetTableId(dataset, tableName);
            if (tableId == 0)
                return;

            if (FindColumnRow(columns, tableId, columnName) == null)
            {
                var source = FindColumnRow(columns, tableId, cloneFromColumn);
                if (source == null)
                    return;

                var newRow = columns.NewRow();
                foreach (DataColumn column in columns.Columns)
                {
                    var header = column.ColumnName;
                    if (header.StartsWith('#'))
                        newRow[header] = source[header];
                    else if (string.Equals(header, "Id", StringComparison.OrdinalIgnoreCase) || header == "*Id")
                        SetColumnValue(newRow, "Id", NextColumnId(columns));
                    else if (string.Equals(header, "Name", StringComparison.OrdinalIgnoreCase))
                        SetColumnValue(newRow, "Name", columnName);
                    else if (string.Equals(header, "Sequence", StringComparison.OrdinalIgnoreCase))
                        SetColumnValue(newRow, "Sequence", Settings.ToLong(GetColumnValue(source, "Sequence")) + 1);
                    else if (string.Equals(header, "IsAutoIncrement", StringComparison.OrdinalIgnoreCase) || header == "IsAutoincrement")
                        SetColumnValue(newRow, "IsAutoIncrement", false);
                    else if (string.Equals(header, "IsPrimarykey", StringComparison.OrdinalIgnoreCase) || header == "IsPrimaryKey")
                        SetColumnValue(newRow, "IsPrimarykey", false);
                    else if (header is "IsListable" or "IsFilterable" or "IsGridable" or "IsEditable" or "IsUnique")
                        SetColumnValue(newRow, header, false);
                    else if (source.Table.Columns.Contains(header))
                        newRow[header] = source[header];
                }

                columns.Rows.Add(newRow);
            }

            var data = dataset.Tables[tableName]!;
            if (!data.Columns.Contains(columnName) && !data.Columns.Contains($"*{columnName}"))
                data.Columns.Add(columnName, typeof(string));

            foreach (DataRow row in data.Rows)
                populate?.Invoke(row);
        }

        static void BridgeSystemsLegacyColumns(DataSet dataset)
        {
            EnsureLegacyPhysicalColumn(dataset, "Systems", "ClientName", "Name", row =>
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(TryGetColumnValue(row, "ClientName", out var value) ? value : null)))
                    SetColumnValue(row, "ClientName", "softlab");
            });

            EnsureLegacyPhysicalColumn(dataset, "Systems", "IsOffAir", "IsActive", row =>
            {
                if (TryGetColumnValue(row, "IsActive", out var isActive))
                    SetColumnValue(row, "IsOffAir", !ParseBoolean(isActive));
                else if (!TryGetColumnValue(row, "IsOffAir", out _))
                    SetColumnValue(row, "IsOffAir", false);
            });
        }

        static void BridgeDatabasesLegacyColumns(DataSet dataset)
        {
            var defaultFolder = Path.Combine(Settings.Builder.Environment.ContentRootPath, "StaticFiles", "db");

            EnsureLegacyPhysicalColumn(dataset, "Databases", "Alias", "Name", row =>
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(TryGetColumnValue(row, "Alias", out var value) ? value : null)))
                    SetColumnValue(row, "Alias", GetColumnValue(row, "Name"));
            });
            EnsureLegacyPhysicalColumn(dataset, "Databases", "Folder", "Name", row =>
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(TryGetColumnValue(row, "Folder", out var value) ? value : null)))
                    SetColumnValue(row, "Folder", defaultFolder);
            });
            EnsureLegacyPhysicalColumn(dataset, "Databases", "ConnectionId", "Id", row =>
            {
                if (Settings.ToLong(TryGetColumnValue(row, "ConnectionId", out var value) ? value : 0) == 0)
                    SetColumnValue(row, "ConnectionId", 1L);
            });
            EnsureLegacyPhysicalColumn(dataset, "Databases", "IsLegacy", "Name", row =>
            {
                if (!TryGetColumnValue(row, "IsLegacy", out var value) || value is DBNull)
                    SetColumnValue(row, "IsLegacy", false);
            });
            EnsureLegacyPhysicalColumn(dataset, "Databases", "CurrentOperationId", "Id", row =>
            {
                if (Settings.ToLong(TryGetColumnValue(row, "CurrentOperationId", out var value) ? value : 0) == 0)
                    SetColumnValue(row, "CurrentOperationId", 0L);
            });
        }

        static void BridgeConnectionsLegacyColumns(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Connections"))
                return;

            EnsureLegacyPhysicalColumn(dataset, "Connections", "Environment", "Name");
            EnsureLegacyPhysicalColumn(dataset, "Connections", "ConnectionString", "Name");

            var environments = dataset.Tables.Contains("Environments")
                ? dataset.Tables["Environments"]!.AsEnumerable().ToDictionary(row => GetRowId(row), row => Settings.ToString(GetColumnValue(row, "Name")))
                : new Dictionary<long, string>();

            foreach (DataRow connection in dataset.Tables["Connections"]!.Rows)
            {
                var connectionId = GetRowId(connection);
                DataRow? stringRow = null;
                if (dataset.Tables.Contains("Strings"))
                {
                    stringRow = dataset.Tables["Strings"]!.AsEnumerable()
                        .FirstOrDefault(row => Settings.ToLong(GetColumnValue(row, "ConnectionId")) == connectionId
                            && Settings.ToLong(GetColumnValue(row, "EnvironmentId")) == 1)
                        ?? dataset.Tables["Strings"]!.AsEnumerable()
                            .FirstOrDefault(row => Settings.ToLong(GetColumnValue(row, "ConnectionId")) == connectionId);
                }

                if (stringRow != null)
                {
                    SetColumnValue(connection, "ConnectionString", GetColumnValue(stringRow, "ConnectionString"));
                    var environmentId = Settings.ToLong(GetColumnValue(stringRow, "EnvironmentId"));
                    SetColumnValue(connection, "Environment",
                        environments.TryGetValue(environmentId, out var environment) ? environment : "prd");
                }
                else
                {
                    if (!TryGetColumnValue(connection, "Environment", out var environment) || string.IsNullOrWhiteSpace(Settings.ToString(environment)))
                        SetColumnValue(connection, "Environment", "prd");
                }
            }
        }

        static void BridgeSessionsLegacyColumns(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Sessions"))
                return;

            EnsureLegacyPhysicalColumn(dataset, "Sessions", "ClientRsaPublicKey", "PublicKey", row =>
            {
                if (!TryGetColumnValue(row, "ClientRsaPublicKey", out _))
                    SetColumnValue(row, "ClientRsaPublicKey", DBNull.Value);
            });
        }

        static void BridgeEnginesDefaults(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Engines"))
                return;

            foreach (DataRow row in dataset.Tables["Engines"]!.Rows)
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(TryGetColumnValue(row, "PackageVersion", out var value) ? value : null)))
                    SetColumnValue(row, "PackageVersion", "1.0.0");
            }
        }

        static void BridgeStringsDefaults(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Strings"))
                return;

            foreach (DataRow row in dataset.Tables["Strings"]!.Rows)
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(TryGetColumnValue(row, "Directory", out var value) ? value : null)))
                    SetColumnValue(row, "Directory", string.Empty);
            }
        }

        static void BridgeLegacyCompatibility(DataSet dataset)
        {
            BridgeSystems(dataset);
            BridgeDatabases(dataset);
            EnsureDatabasesTables(dataset);
            EnsureSystemsUsers(dataset);
        }

        static void BridgeSystems(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Systems"))
                return;

            var systems = dataset.Tables["Systems"]!;
            if (!systems.Columns.Contains("ClientName"))
                systems.Columns.Add("ClientName", typeof(string));
            if (!systems.Columns.Contains("IsOffAir"))
                systems.Columns.Add("IsOffAir", typeof(bool));

            foreach (DataRow row in systems.Rows)
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(row["ClientName"])))
                    row["ClientName"] = "softlab";

                if (systems.Columns.Contains("IsActive"))
                    row["IsOffAir"] = !Settings.ToBoolean(row["IsActive"]);
                else if (row["IsOffAir"] is DBNull)
                    row["IsOffAir"] = false;
            }
        }

        static void BridgeDatabases(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Databases"))
                return;

            var databases = dataset.Tables["Databases"]!;
            var defaultFolder = Path.Combine(Settings.Builder.Environment.ContentRootPath, "StaticFiles", "db");

            if (!databases.Columns.Contains("Alias"))
                databases.Columns.Add("Alias", typeof(string));
            if (!databases.Columns.Contains("Folder"))
                databases.Columns.Add("Folder", typeof(string));
            if (!databases.Columns.Contains("ConnectionId"))
                databases.Columns.Add("ConnectionId", typeof(long));
            if (!databases.Columns.Contains("IsLegacy"))
                databases.Columns.Add("IsLegacy", typeof(bool));
            if (!databases.Columns.Contains("CurrentOperationId"))
                databases.Columns.Add("CurrentOperationId", typeof(long));

            foreach (DataRow row in databases.Rows)
            {
                if (string.IsNullOrWhiteSpace(Settings.ToString(row["Alias"])))
                    row["Alias"] = GetColumnValue(row, "Name");
                if (string.IsNullOrWhiteSpace(Settings.ToString(row["Folder"])))
                    row["Folder"] = defaultFolder;
                if (Settings.ToLong(TryGetColumnValue(row, "ConnectionId", out var connectionId) ? connectionId : 0) == 0)
                    row["ConnectionId"] = 1L;
                if (row["IsLegacy"] is DBNull)
                    row["IsLegacy"] = false;
                if (Settings.ToLong(TryGetColumnValue(row, "CurrentOperationId", out var operationId) ? operationId : 0) == 0)
                    row["CurrentOperationId"] = 0L;
            }
        }

        static void EnsureDatabasesTables(DataSet dataset)
        {
            if (!dataset.Tables.Contains("Tables") || !dataset.Tables.Contains("Databases"))
                return;

            if (!dataset.Tables.Contains("DatabasesTables"))
                dataset.Tables.Add(new DataTable("DatabasesTables"));

            var link = dataset.Tables["DatabasesTables"]!;
            if (link.Columns.Count == 0)
            {
                link.Columns.Add("Id", typeof(long));
                link.Columns.Add("DatabaseId", typeof(long));
                link.Columns.Add("TableId", typeof(long));
                link.Columns.Add("Name", typeof(string));
            }

            if (link.Rows.Count > 0)
                return;

            long id = 1;
            foreach (DataRow table in dataset.Tables["Tables"]!.Rows)
            {
                var databaseId = Settings.ToLong(GetColumnValue(table, "DatabaseId"));
                if (databaseId == 0)
                    continue;

                link.Rows.Add(
                    id++,
                    databaseId,
                    GetRowId(table),
                    $"{Settings.ToString(GetColumnValue(table, "Name"))}");
            }
        }

        static void EnsureSystemsUsers(DataSet dataset)
        {
            if (!dataset.Tables.Contains("SystemsUsers"))
                dataset.Tables.Add(new DataTable("SystemsUsers"));

            var link = dataset.Tables["SystemsUsers"]!;
            if (link.Columns.Count == 0)
            {
                link.Columns.Add("Id", typeof(long));
                link.Columns.Add("SystemId", typeof(long));
                link.Columns.Add("UserId", typeof(long));
                link.Columns.Add("Name", typeof(string));
            }

            if (link.Rows.Count > 0)
                return;

            if (!dataset.Tables.Contains("Users") || !dataset.Tables.Contains("Systems"))
                return;

            long id = 1;
            foreach (DataRow user in dataset.Tables["Users"]!.Rows)
            {
                foreach (DataRow system in dataset.Tables["Systems"]!.Rows)
                {
                    link.Rows.Add(
                        id++,
                        GetRowId(system),
                        GetRowId(user),
                        $"{Settings.ToString(GetColumnValue(system, "Name"))} x {Settings.ToString(GetColumnValue(user, "Name"))}");
                }
            }
        }
    }
}
