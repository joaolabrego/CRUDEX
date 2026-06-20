using System.Collections.Frozen;
using System.Text;
using CRUDEX.Classes;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace crudex.Classes
{
    /// <summary>
    /// Catálogo de comparadores (Cmp): SqlComparator e predicados derivados do Symbol, não do Excel.
    /// </summary>
    static class ComparatorRegistry
    {
        sealed record ComparatorSpec(string Symbol, string SqlOperator, long? ExpectedArity);

        static readonly FrozenDictionary<string, ComparatorSpec> BySymbol =
            new Dictionary<string, ComparatorSpec>(StringComparer.Ordinal)
            {
                ["<"] = new("<", "<", 2),
                ["≤"] = new("≤", "<=", 2),
                ["="] = new("=", "=", 2),
                ["≠"] = new("≠", "<>", 2),
                ["≥"] = new("≥", ">=", 2),
                [">"] = new(">", ">", 2),
                ["∈"] = new("∈", "IN", null),
                ["∉"] = new("∉", "NOT IN", null),
                ["⊃"] = new("⊃", "LIKE", 2),
                ["⊅"] = new("⊅", "NOT LIKE", 2),
                ["∃"] = new("∃", "BETWEEN", 3),
                ["∄"] = new("∄", "NOT BETWEEN", 3),
                ["∅"] = new("∅", "IS NULL", 1),
                ["⊗"] = new("⊗", "IS NOT NULL", 1),
            }.ToFrozenDictionary(StringComparer.Ordinal);

        public static string GetSqlOperator(string symbol)
        {
            var key = (symbol ?? string.Empty).Trim();
            if (!BySymbol.TryGetValue(key, out var spec))
                throw new Exception($"Comparators: símbolo '{symbol}' não possui handler registrado.");
            return spec.SqlOperator;
        }

        public static void ValidateArity(string symbol, object? arity, long id)
        {
            var key = (symbol ?? string.Empty).Trim();
            if (!BySymbol.TryGetValue(key, out var spec))
                throw new Exception($"Comparators (Id {id}): símbolo '{symbol}' não possui handler registrado.");

            var isNullArity = Settings.IsNull(arity) || string.IsNullOrWhiteSpace(Settings.ToString(arity));
            if (spec.ExpectedArity is null)
            {
                if (!isNullArity)
                    throw new Exception($"Comparators (Id {id}, '{symbol}'): Arity deve ser NULL.");
                return;
            }

            if (isNullArity)
                throw new Exception($"Comparators (Id {id}, '{symbol}'): Arity NULL inválida (esperado {spec.ExpectedArity}).");

            var arityValue = Settings.ToLong(arity);
            if (arityValue != spec.ExpectedArity)
                throw new Exception($"Comparators (Id {id}, '{symbol}'): Arity {arityValue} inválida (esperado {spec.ExpectedArity}).");
        }

        public static string BuildSqlPredicate(string columnRef, string parameterName, string dataType, string sqlOperator, object? arity)
        {
            if (IsNullArity(arity))
                return $"{columnRef} {sqlOperator} (SELECT CAST([value] AS {dataType}) FROM OPENJSON(@{parameterName}_vals))";

            var arityValue = Settings.ToLong(arity);
            if (arityValue > 2)
                return $"{columnRef} {sqlOperator} @{parameterName}_v1 AND @{parameterName}_v2";
            if (arityValue == 1)
                return $"{columnRef} {sqlOperator}";
            return $"{columnRef} {sqlOperator} @{parameterName}";
        }

        public static string BuildPredicateCaseById(TDictionary[] comparators, string opVariable, string columnRef, string parameterName, string dataType)
        {
            var result = new StringBuilder();
            result.Append($"CASE {opVariable}\r\n");
            foreach (var comparator in comparators.OrderBy(item => Settings.ToLong(item["Id"])))
            {
                var id = Settings.ToLong(comparator["Id"]);
                var predicate = BuildSqlPredicate(
                    columnRef,
                    parameterName,
                    dataType,
                    Settings.ToString(comparator["SqlComparator"]),
                    comparator["Arity"]);
                result.Append($"        WHEN {id} THEN N'{EscapeSqlStringLiteral(predicate)}'\r\n");
            }
            result.Append("    END");
            return result.ToString();
        }

        public static string BuildArityReadyExpression(string opVariable, string valueVarPrefix, TDictionary[] comparators, bool needsBetweenSlots)
        {
            var parts = new List<string>();
            foreach (var comparator in comparators)
            {
                var id = Settings.ToLong(comparator["Id"]);
                if (IsNullArity(comparator["Arity"]))
                    parts.Add($"({opVariable} = {id} AND {valueVarPrefix}vals IS NOT NULL)");
                else if (IsBetweenComparator(comparator) && needsBetweenSlots)
                    parts.Add($"({opVariable} = {id} AND {valueVarPrefix}v1 IS NOT NULL AND {valueVarPrefix}v2 IS NOT NULL)");
                else if (IsBinaryComparator(comparator))
                    parts.Add($"({opVariable} = {id} AND {valueVarPrefix}v IS NOT NULL)");
                else if (IsUnaryComparator(comparator))
                    parts.Add($"({opVariable} = {id})");
            }

            return parts.Count == 0 ? "0 = 1" : string.Join("\r\n               OR ", parts);
        }

        static bool IsNullArity(object? arity) =>
            Settings.IsNull(arity) || string.IsNullOrWhiteSpace(Settings.ToString(arity));

        static bool IsBetweenComparator(TDictionary comparator) =>
            !IsNullArity(comparator["Arity"]) && Settings.ToLong(comparator["Arity"]) > 2;

        static bool IsBinaryComparator(TDictionary comparator) =>
            !IsNullArity(comparator["Arity"]) && Settings.ToLong(comparator["Arity"]) == 2;

        static bool IsUnaryComparator(TDictionary comparator) =>
            !IsNullArity(comparator["Arity"]) && Settings.ToLong(comparator["Arity"]) == 1;

        static string EscapeSqlStringLiteral(string value) =>
            value.Replace("'", "''");
    }
}
