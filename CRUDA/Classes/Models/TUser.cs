namespace CRUDA.Classes.Models
{
    public class TUser: TBase
    {
        public long Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Password { get; init; } = string.Empty;
        public string FullName { get; init; } = string.Empty;
        public byte RetryLogins { get; init; }
        public bool IsActive { get; init; }
    }
}
