namespace CRUDA.Classes.Models
{
    public class TDatabaseTable(object anonymousObject) : TBase(anonymousObject, "RecordDatabaseTable")
    {
        public long Id { get; init; }
        public long DatabaseId { get; init; }
        public long TableId { get; init; }
        public string Description { get; init; } = string.Empty;
    }
}
