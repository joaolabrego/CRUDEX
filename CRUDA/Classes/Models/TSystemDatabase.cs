namespace CRUDA.Classes.Models
{
    public class TSystemDatabase(object anonymousObject) : TBase(anonymousObject, "RecordSystemDatabase")
    {
        public long Id { get; init; }
        public long SystemId { get; init; }
        public long DatabaseId { get; init; }
        public string Description { get; init; } = string.Empty;
    }
}
