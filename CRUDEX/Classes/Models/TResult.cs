using CRUDA_LIB;
using Newtonsoft.Json;
using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace crudex.Classes.Models
{
    public class TResult
    {
        public readonly string ClassName = "TResult";
        public readonly DataSet DataSet;
        public TDictionary Parameters { get; } = [];
        public TResult(DataSet dataset, OleDbParameterCollection parameters)
        {
            DataSet = dataset;
            foreach (OleDbParameter parameter in parameters)
                Parameters.Add(parameter.ParameterName[(parameter.ParameterName.StartsWith('@') ? 1 : 0)..], parameter.Value);
        }
        public override string ToString()
        {
            return JsonConvert.SerializeObject(this, Formatting.Indented);
        }
    }
}