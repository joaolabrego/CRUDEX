namespace CRUDA.Classes.Models
{
    public class TColumn(object anonymousObject) : TBase(anonymousObject, "RecordColumn")
    {
        public long Id { get; init; }
        public long TableId { get; init; }
        public short Sequence { get; init; }
        public long DomainId { get; init; }
        public long? ReferenceTableId { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public string Title { get; init; } = string.Empty;
        public string Caption { get; init; } = string.Empty;
        public dynamic? Default { get; init; }
        public dynamic? Minimum { get; init; }
        public dynamic? Maximum { get; init; }
        public bool? IsPrimarykey { get; init; }
        public bool? IsAutoIncrement { get; init; }
        public bool IsRequired { get; init; }
        public bool? IsListable { get; init; }
        public bool? IsFilterable { get; init; }
        public bool? IsEditable { get; init; }
        public bool? IsGridable { get; init; }
        public bool? IsEncrypted { get; init; }
        public bool IsCalculated { get; init; }
    }
}
