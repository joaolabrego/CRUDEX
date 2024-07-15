namespace CRUDA.Classes.Models
{
    public class TLogin(object anonymousObject) : TBase(anonymousObject, "RecordLogin")
    {
        public long Id { get; init; }
        public long SystemId { get; init; }
        public long UserId { get; init; }
        public string PublicKey { get; init; } = string.Empty;
        public bool Logged { get; init; }
    }
}
