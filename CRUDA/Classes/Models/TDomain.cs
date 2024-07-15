namespace CRUDA.Classes.Models
{
    public class TDomain(object anonymousObject) : TBase(anonymousObject, "RecordDomain")
    {
        public long Id { get; init; }
        public long TypeId { get; init; }
        public long? MaskId { get; init; }
        public string Name { get; init; } = string.Empty;
        public short? Length { get; init; }
        public byte? Decimals { get; init; }
        public string? ValidValues { get; init; }
        public dynamic? Default { get; init; }
        public dynamic? Minimum { get; init; }
        public dynamic? Maximum { get; init; }
        public string? Codification { get; init; }
    }
}
