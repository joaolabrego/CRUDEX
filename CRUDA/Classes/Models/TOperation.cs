namespace CRUDA.Classes.Models
{
    public class TOperation(object anonymousObject) : TBase(anonymousObject, "RecordOperation")
    {
        public long Id { get; init; }
        public long TransactionId { get; init; }
        public long TableId { get; init; }
        public string Action {  get; set; } = string.Empty;
        public string? LastRecord { get; init; }
        public string ActualRecord { get; init; } = string.Empty;
        public bool? IsConfirmed { get; init; }
    }
}
