namespace CRUDA.Classes.Models
{
    public class TIndex(object anonymousObject) : TBase(anonymousObject, "RecordIndex")
    {
        public long Id { get; init; }
        public long DatabaseId { get; init; }
        public long TableId { get; init; }
        public string Name { get; init; } = string.Empty;
        public bool IsUnique { get; init; }
    }
}
