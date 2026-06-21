using System.Data;
using CRUDEX.Classes;
using TDataRows = System.Collections.Generic.List<System.Data.DataRow>;

namespace crudex.Classes
{
    /// <summary>
    /// Resolve References + Referencekeys em pares FK↔PK (PK inferida por ordem).
    /// </summary>
    static class ReferenceModel
    {
        public sealed class KeyPair
        {
            public required DataRow FkColumn { get; init; }
            public required DataRow PkColumn { get; init; }
        }

        public sealed class ResolvedReference
        {
            public required long Id { get; init; }
            public required long FkTableId { get; init; }
            public required long PkTableId { get; init; }
            public required string Name { get; init; }
            public required bool IsParentChild { get; init; }
            public required DataRow FkTable { get; init; }
            public required DataRow PkTable { get; init; }
            public required List<KeyPair> Keys { get; init; }
            public string FkTableName => Settings.ToString(FkTable["Name"]);
            public string PkTableName => Settings.ToString(PkTable["Name"]);
            public string PkTableAlias => Settings.ToString(PkTable["Alias"]);
            public string JsonKey => string.IsNullOrWhiteSpace(PkTableAlias) ? PkTableName : PkTableAlias;
        }

        public static List<ResolvedReference> Build(
            TDataRows referenceRows,
            TDataRows referenceKeyRows,
            TDataRows tables,
            TDataRows columns)
        {
            var result = new List<ResolvedReference>();
            foreach (var reference in referenceRows.OrderBy(row => Settings.ToLong(row["Id"])))
            {
                var id = Settings.ToLong(reference["Id"]);
                var fkTableId = Settings.ToLong(reference["FkTableId"]);
                var pkTableId = Settings.ToLong(reference["PkTableId"]);
                var fkTable = RequireRow(tables, row => Settings.ToLong(row["Id"]) == fkTableId,
                    $"References (Id {id}): FkTableId {fkTableId} inexistente em Tables.");
                var pkTable = RequireRow(tables, row => Settings.ToLong(row["Id"]) == pkTableId,
                    $"References (Id {id}): PkTableId {pkTableId} inexistente em Tables.");

                var pkColumns = GetPrimaryKeyColumnRows(columns, pkTable);
                var keyRows = referenceKeyRows
                    .Where(row => Settings.ToLong(row["ReferenceId"]) == id)
                    .OrderBy(row => Settings.ToLong(row["Sequence"]))
                    .ToList();

                if (keyRows.Count == 0)
                    throw new Exception($"References (Id {id}, '{reference["Name"]}'): sem linhas em Referencekeys.");
                if (keyRows.Count != pkColumns.Count)
                    throw new Exception($"References (Id {id}, '{reference["Name"]}'): {keyRows.Count} chave(s) em Referencekeys, mas PK de '{pkTable["Name"]}' tem {pkColumns.Count} coluna(s).");

                var sequences = keyRows.Select(row => Settings.ToLong(row["Sequence"])).ToList();
                if (sequences.Distinct().Count() != sequences.Count)
                    throw new Exception($"References (Id {id}): Sequence duplicada em Referencekeys.");

                var keys = new List<KeyPair>();
                for (var i = 0; i < keyRows.Count; i++)
                {
                    var keyRow = keyRows[i];
                    var fkColumnId = Settings.ToLong(keyRow["FkColumnId"]);
                    var fkColumn = RequireRow(columns, row => Settings.ToLong(row["Id"]) == fkColumnId,
                        $"Referencekeys (Id {keyRow["Id"]}): FkColumnId {fkColumnId} inexistente em Columns.");
                    if (Settings.ToLong(fkColumn["TableId"]) != fkTableId)
                        throw new Exception($"Referencekeys (Id {keyRow["Id"]}): FkColumnId {fkColumnId} não pertence à tabela filha '{fkTable["Name"]}'.");

                    keys.Add(new KeyPair { FkColumn = fkColumn, PkColumn = pkColumns[i] });
                }

                var isParentChild = ReadIsParentChild(reference);
                result.Add(new ResolvedReference
                {
                    Id = id,
                    FkTableId = fkTableId,
                    PkTableId = pkTableId,
                    Name = Settings.ToString(reference["Name"]),
                    IsParentChild = isParentChild,
                    FkTable = fkTable,
                    PkTable = pkTable,
                    Keys = keys,
                });
            }

            return result;
        }

        public static IEnumerable<ResolvedReference> OutgoingFrom(IEnumerable<ResolvedReference> model, long fkTableId) =>
            model.Where(reference => reference.FkTableId == fkTableId);

        public static IEnumerable<ResolvedReference> IncomingTo(IEnumerable<ResolvedReference> model, long pkTableId) =>
            model.Where(reference => reference.PkTableId == pkTableId);

        static bool ReadIsParentChild(DataRow reference)
        {
            if (reference.Table.Columns.Contains("IsParentChild"))
                return Settings.ToBoolean(reference["IsParentChild"]);
            if (reference.Table.Columns.Contains("IsParentChildren"))
                return Settings.ToBoolean(reference["IsParentChildren"]);
            return false;
        }

        static List<DataRow> GetPrimaryKeyColumnRows(TDataRows columns, DataRow table) =>
            columns
                .FindAll(row => Settings.ToLong(row["TableId"]) == Settings.ToLong(table["Id"])
                    && Settings.ToBoolean(row["IsPrimarykey"]))
                .OrderBy(row => row.Table.Columns.Contains("PkSequence") && row["PkSequence"] != DBNull.Value
                    ? Settings.ToLong(row["PkSequence"])
                    : Settings.ToLong(row["Sequence"]))
                .ToList();

        static DataRow RequireRow(TDataRows rows, Func<DataRow, bool> predicate, string message) =>
            rows.FirstOrDefault(predicate) ?? throw new Exception(message);
    }
}
