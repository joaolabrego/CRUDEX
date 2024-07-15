namespace CRUDA.Classes.Models
{
    public class TCategory(object anonymousObject) : TBase(anonymousObject, "RecordCategory")
    {
        public long Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string? HtmlInputType { get; init; }
        public string? HtmlInputAlign { get; init; }
        public bool AskEncrypted { get; init; }
        public bool AskMask { get; init; }
        public bool AskListable { get; init; }
        public bool AskDefault { get; init; }
        public bool AskMinimum { get; init; }
        public bool AskMaximum { get; init; }
    }
}
