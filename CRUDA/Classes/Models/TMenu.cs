namespace CRUDA.Classes.Models
{
    public class TMenu(object anonymousObject) : TBase(anonymousObject, "RecordMenu")
    {
        public long Id { get; init; }
        public long SystemId { get; init; }
        public short Sequence { get; init; }
        public string Caption { get; init; } = string.Empty;
        public string Message { get; init; } = string.Empty;
        public string? Action { get; init; }
        public long? ParentMenuId { get; init; }
    }
}
