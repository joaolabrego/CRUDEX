using Microsoft.AspNetCore.Http.HttpResults;
using System.Threading.Tasks;

namespace CRUDA.Classes.Models
{
    public class TMask(object anonymousObject) : TBase(anonymousObject, "RecordMask")
    {
        public long Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string Mask { get; init; } = string.Empty;
    }
}
