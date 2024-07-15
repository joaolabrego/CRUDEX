using CRUDA_LIB;
using NPOI;
using NPOI.SS.Formula.Functions;
using System.Reflection;

namespace CRUDA.Classes.Models
{
    public class TType(object anonymousObject) : TBase(anonymousObject, "RecordType")
    {
        public byte Id { get; init; }
        public byte CategoryId { get; init; }
        public string Name { get; init; } = string.Empty;
        public dynamic? Minimum { get; init; }
        public dynamic? Maximum { get; init; }
        public bool AskLength { get; init; }
        public bool AskDecimals { get; init; }
        public bool AskPrimarykey { get; init; }
        public bool AskAutoincrement { get; init; }
        public bool AskFilterable { get; init; }
        public bool AskBrowseable { get; init; }
        public bool AskCodification { get; init; }
        public bool AskFormula { get; init; }
        public bool AllowMaxLength { get; init; }
        public bool IsActive { get; init; }
    }
}
