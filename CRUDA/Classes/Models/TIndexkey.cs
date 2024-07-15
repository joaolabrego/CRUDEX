namespace CRUDA.Classes.Models
{
    public class TIndexkey(object anonymousObject) : TBase(anonymousObject, "RecordIndexkey")
    {
        public long Id { get; init; }
        public long IndexId { get; init; }
        public short Sequence { get; init; }
        public long ColumnId { get; init; }
        public bool IsDescending { get; init; }
    }
}
