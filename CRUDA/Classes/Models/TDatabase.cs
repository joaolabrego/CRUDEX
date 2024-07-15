namespace CRUDA.Classes.Models
{
    public class TDatabase(object anonymousObject) : TBase(anonymousObject, "RecordDatabase")
    {
        public long Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public string Alias { get; init; } = string.Empty;
        public string? ServerName { get; init; }
        public string? HostName { get; init; }
        public int? Port { get; init; }
        public string? Logon { get; init; }
        public string? Password { get; init; }
        public string? Folder { get; init; }
    }
}
