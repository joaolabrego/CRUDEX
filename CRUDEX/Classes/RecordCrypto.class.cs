using System.Collections.Concurrent;
using System.Data;
using Microsoft.Data.SqlClient;
using Newtonsoft.Json;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public static class RecordCrypto
    {
        static readonly ConcurrentDictionary<string, HashSet<string>> EncryptedColumnsByTable = new(StringComparer.OrdinalIgnoreCase);
        static volatile bool _columnsLoaded;

        static async Task EnsureEncryptedColumnsAsync()
        {
            if (_columnsLoaded)
                return;

            using var connection = new SqlConnection(Settings.ConnectionString());
            await connection.OpenAsync();
            using var command = new SqlCommand(@"
                SELECT [T].[Name] AS [TableName], [C].[Name] AS [ColumnName]
                FROM [dbo].[Columns] [C]
                    INNER JOIN [dbo].[Tables] [T] ON [T].[Id] = [C].[TableId]
                WHERE [C].[IsEncrypted] = 1", connection);
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var tableName = Convert.ToString(reader["TableName"]) ?? string.Empty;
                var columnName = Convert.ToString(reader["ColumnName"]) ?? string.Empty;
                if (string.IsNullOrWhiteSpace(tableName) || string.IsNullOrWhiteSpace(columnName))
                    continue;
                var columns = EncryptedColumnsByTable.GetOrAdd(tableName, _ => new HashSet<string>(StringComparer.OrdinalIgnoreCase));
                columns.Add(columnName);
            }
            _columnsLoaded = true;
        }

        static async Task<HashSet<string>> GetEncryptedColumnsAsync(string tableName)
        {
            await EnsureEncryptedColumnsAsync();
            return EncryptedColumnsByTable.TryGetValue(tableName, out var columns)
                ? columns
                : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        static string TransformRecordJson(string? json, HashSet<string> encryptedColumns, bool encrypt)
        {
            if (string.IsNullOrWhiteSpace(json) || encryptedColumns.Count == 0)
                return json ?? string.Empty;

            var record = JsonConvert.DeserializeObject<TDictionary>(json);
            if (record == null)
                return json;

            foreach (var columnName in encryptedColumns)
            {
                if (!record.TryGetValue(columnName, out dynamic? value) || value == null)
                    continue;
                var text = Convert.ToString(value);
                if (string.IsNullOrEmpty(text))
                    continue;
                record[columnName] = encrypt
                    ? TransportCrypto.EncryptStoredValue(text)
                    : TransportCrypto.DecryptStoredValue(text);
            }

            return JsonConvert.SerializeObject(record);
        }

        static string TransformJsonArray(string? json, HashSet<string> encryptedColumns, bool encrypt)
        {
            if (string.IsNullOrWhiteSpace(json) || encryptedColumns.Count == 0)
                return json ?? string.Empty;

            var rows = JsonConvert.DeserializeObject<List<TDictionary>>(json);
            if (rows == null)
                return json;

            foreach (var record in rows)
            {
                foreach (var columnName in encryptedColumns)
                {
                    if (!record.TryGetValue(columnName, out dynamic? value) || value == null)
                        continue;
                    var text = Convert.ToString(value);
                    if (string.IsNullOrEmpty(text))
                        continue;
                    record[columnName] = encrypt
                        ? TransportCrypto.EncryptStoredValue(text)
                        : TransportCrypto.DecryptStoredValue(text);
                }
            }

            return JsonConvert.SerializeObject(rows);
        }

        public static async Task EncryptPersistParametersAsync(TDictionary? procedureParameters, string tableName)
        {
            if (procedureParameters == null || string.IsNullOrWhiteSpace(tableName))
                return;

            var encryptedColumns = await GetEncryptedColumnsAsync(tableName);
            if (encryptedColumns.Count == 0)
                return;

            if (!procedureParameters.TryGetValue("InParams", out dynamic? inParamsValue) || inParamsValue == null)
                return;

            var inParams = Config.ToDictionary(inParamsValue);
            if (inParams.TryGetValue("ActualRecord", out dynamic? actualRecord) && actualRecord != null)
                inParams["ActualRecord"] = TransformRecordJson(Convert.ToString(actualRecord), encryptedColumns, encrypt: true);
            if (inParams.TryGetValue("LastRecord", out dynamic? lastRecord) && lastRecord != null)
                inParams["LastRecord"] = TransformRecordJson(Convert.ToString(lastRecord), encryptedColumns, encrypt: true);

            procedureParameters["InParams"] = inParams;
        }

        public static async Task<string?> DecryptRecordJsonAsync(string? json, string tableName)
        {
            if (string.IsNullOrWhiteSpace(json))
                return json;
            var encryptedColumns = await GetEncryptedColumnsAsync(tableName);
            return TransformRecordJson(json, encryptedColumns, encrypt: false);
        }

        public static async Task DecryptReadResultAsync(DataSet dataSet, string mainTableName)
        {
            if (dataSet.Tables.Count == 0 || dataSet.Tables[0].Rows.Count == 0)
                return;

            var table = dataSet.Tables[0];
            if (table.Columns.Contains("result"))
            {
                var header = table.Rows[0];
                var mainColumns = await GetEncryptedColumnsAsync(mainTableName);
                if (mainColumns.Count > 0 && header["result"] != DBNull.Value)
                    header["result"] = TransformJsonArray(Convert.ToString(header["result"]), mainColumns, encrypt: false);

                foreach (DataColumn column in table.Columns)
                {
                    if (column.ColumnName.Equals("result", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (header[column.ColumnName] == DBNull.Value)
                        continue;

                    var refColumns = await GetEncryptedColumnsAsync(column.ColumnName);
                    if (refColumns.Count == 0)
                        continue;

                    header[column.ColumnName] = TransformJsonArray(
                        Convert.ToString(header[column.ColumnName]),
                        refColumns,
                        encrypt: false);
                }
                return;
            }

            var encryptedColumns = await GetEncryptedColumnsAsync(mainTableName);
            if (encryptedColumns.Count == 0)
                return;

            foreach (DataRow row in table.Rows)
            {
                foreach (var columnName in encryptedColumns)
                {
                    if (!table.Columns.Contains(columnName) || row[columnName] == DBNull.Value)
                        continue;
                    row[columnName] = TransportCrypto.DecryptStoredValue(Convert.ToString(row[columnName]));
                }
            }
        }
    }
}
