using CRUDA_LIB;
using Newtonsoft.Json;
using System.Data;
using System.Data.SqlClient;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA.Classes.Models
{
    public class SQLResult
    {
        public readonly string ClassName = "SQLResult";
        public readonly DataTableCollection Tables;
        public Dictionary Parameters { get; } = [];
        public SQLResult(DataTableCollection datatables, SqlParameterCollection parameters)
        {
            Tables = datatables;

            foreach (SqlParameter parameter in parameters)
                if (parameter.Direction != ParameterDirection.Input)
                    Parameters.Add(parameter.ParameterName[(parameter.ParameterName.StartsWith('@') ? 1 : 0)..], parameter.Value);
        }
        public override string ToString()
        {
            return JsonConvert.SerializeObject(this, Formatting.Indented);
        }
    }
}