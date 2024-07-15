namespace CRUDA.Classes.Models
{
    public class TTransaction(object anonymousObject) : TBase(anonymousObject, "RecordTransaction")
    {
        public long Id { get; init; }
        public long LogId { get; init; }
        public long SystemId { get; init; }
        public long DatabaseId { get; init; }
        public bool? IsConfirmed { get; init; }
    }
}
