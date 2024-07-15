namespace CRUDA.Classes.Models
{
    public class TSystemUser(object anonymousObject) : TBase(anonymousObject, "RecordSystemUser")
    {
        public long Id { get; init; }
        public long SystemId { get; init; }
        public long UserId { get; init; }
        public string Description { get; init; } = string.Empty;
    }
}
