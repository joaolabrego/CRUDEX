using CRUDA_LIB;
using Newtonsoft.Json;
using System.Data;
using System.Data.SqlClient;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA.Classes.Models
{
    public class TResult
    {
        public readonly string ClassName = "TResult";
        public readonly DataTableCollection Tables;
        public TDictionary Parameters { get; } = [];
        public TResult(DataTableCollection datatables, SqlParameterCollection parameters)
        {
            Tables = datatables;

            foreach (SqlParameter parameter in parameters)
                Parameters.Add(parameter.ParameterName[(parameter.ParameterName.StartsWith('@') ? 1 : 0)..], parameter.Value);
        }
        public override string ToString()
        {
            return JsonConvert.SerializeObject(this, Formatting.Indented);
        }
    }
}