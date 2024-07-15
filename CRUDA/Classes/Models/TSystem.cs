namespace CRUDA.Classes.Models
{
    public class TSystem(object anonymousObject) : TBase(anonymousObject, "RecordSystem")
    {
        public long Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public string ClientName { get; init; } = string.Empty;
        public byte MaxRetryLogins { get; init; }
    }
}
