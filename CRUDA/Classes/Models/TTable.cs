namespace CRUDA.Classes.Models
{
    public class TTable(object anonymousObject) : TBase(anonymousObject, "RecordTable")
    {
        public long Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Alias {  get; set; } = string.Empty;
        public string Description { get; init; } = string.Empty;
        public long? ParentTableId { get; init; }
        public string? ProcedureCreate {  get; set; }
        public string? ProcedureRead { get; init; }
        public string? ProcedureUpdate { get; init; }
        public string? ProcedureDelete { get; init; }
        public string? ProcedureList { get; init; }
        public bool IsPaged { get; init; }
        public long LastId { get; init; }
    }
}
