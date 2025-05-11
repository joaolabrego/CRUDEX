using Newtonsoft.Json;
using Microsoft.Data.SqlClient;
using System.Data;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace crudex.Classes.Models
{
    public class Result
    {
        public readonly string ClassName = "Result";

        public readonly  DataSet DataSet;
        public TDictionary Parameters { get; } = [];
        public Result(DataSet dataset, SqlParameterCollection parameters)
        {
            DataSet = dataset;
            foreach (SqlParameter parameter in parameters)
                Parameters.Add(parameter.ParameterName[(parameter.ParameterName.StartsWith('@') ? 1 : 0)..], parameter.Value);
        }
    }
}