using System.Data;
using System.Data.SqlClient;
using CRUDA.Classes.Models;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public static class SQLProcedure
    {
        public readonly static string ClassName = "SQLProcedure";
        public static SQLResult Execute(string? connectionString, string? procedureName, Dictionary? parameters = null)
        {
            using var dataset = new DataSet();
            using var connection = new SqlConnection(connectionString);
            using var command = new SqlCommand(procedureName, connection);

            command.CommandType = CommandType.StoredProcedure;
            if (parameters != null)
            {
                foreach (var item in parameters.Where(item => "InputParams;OutputParams;IOParams".Contains(item.Key)))
                {
                    var listParameters = parameters[item.Key];
                    var direction = item.Key == "InputParams" ? ParameterDirection.Input :
                        item.Key == "OutputParams" ? ParameterDirection.Output : ParameterDirection.InputOutput;

                    if (listParameters != null)
                        foreach (var subItem in listParameters)
                            command.Parameters.Add(new SqlParameter(subItem.Key, subItem.Value ?? DBNull.Value) { Direction = direction });
                }
            }
            command.Parameters.Add(new SqlParameter("ReturnValue", DBNull.Value) { Direction = ParameterDirection.ReturnValue });
            
            new SqlDataAdapter(command).Fill(dataset);

            return new SQLResult(dataset.Tables, command.Parameters);
        }
        public static SQLResult GetConfig(string systemName, string? databaseName = null, string? tableName = null)
        {
            var parameters = Config.ToDictionary(new
            {
                InputParams = new
                {
                    SystemName = systemName,
                    DatabaseName = databaseName,
                    TableName = tableName,
                },
            });

            return Execute(Settings.ConnecionString(), Settings.Get("CONFIG_PROCEDURE"), parameters);
        }
        public static SQLResult Execute(string systemName, string databaseName, string tableName, string action, Dictionary? parameters = null)
        {
            var config = GetConfig(systemName, databaseName, tableName);
            var databaseRow = config.Tables[1].Rows[0];
            var tableRow = config.Tables[2].Rows[0];
            var connectionString = $"Password={databaseRow["Password"]};Persist Security Info=True;User ID={databaseRow["Logon"]};" +
                                   $"Initial Catalog={databaseRow["Alias"]};Data Source={databaseRow["ServerName"]}";
            var procedureName = action switch
            {
                Actions.CREATE => tableRow["ProcedureCreate"].ToString(),
                Actions.READ => tableRow["ProcedureRead"].ToString(),
                Actions.UPDATE => tableRow["ProcedureUpdate"].ToString(),
                Actions.DELETE => tableRow["ProcedureDelete"].ToString(),
                Actions.LIST => tableRow["ProcedureList"].ToString(),
                Actions.GEN_ID => "Gen_Id",
                _ => throw new Exception($"Ação inválida."),
            };

            return Execute(connectionString, procedureName, parameters?["Parameters"]);
        }
    }
}