using System.Data;
using crudex.Classes.Models;
using Microsoft.Data.SqlClient;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public static class Procedure
    {
        public readonly static string ClassName = "Procedure";
        public static async Task<TResult> Execute(string? connectionString, string? procedureName, TDictionary? parameters = null)
        {
            using var dataset = new DataSet();
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync(); // Tornando a abertura de conexão assíncrona

            using var command = new SqlCommand(procedureName, connection);
            command.CommandType = CommandType.StoredProcedure;

            if (parameters != null)
            {
                foreach (var item in parameters.Where(item => "InParams;OutParams;IOParams".Contains(item.Key)))
                {
                    var listParameters = parameters[item.Key];
                    var direction = item.Key == "InParams" ? ParameterDirection.Input :
                        item.Key == "OutParams" ? ParameterDirection.Output : ParameterDirection.InputOutput;

                    if (listParameters != null)
                        foreach (var subItem in listParameters)
                            command.Parameters.Add(new SqlParameter(subItem.Key, subItem.Value ?? DBNull.Value) { Direction = direction });
                }
            }
            command.Parameters.Add(new SqlParameter("ReturnValue", SqlDbType.BigInt) { Direction = ParameterDirection.Output });
            using var adapter = new SqlDataAdapter(command);
            adapter.Fill(dataset);
            
            return new TResult(dataset, command.Parameters);
        }

        public static async Task<TResult> GetConfig(string systemName, string? databaseName = null, string? tableName = null)
        {
            var parameters = Config.ToDictionary(new
            {
                InParams = new
                {
                    SystemName = systemName,
                    DatabaseName = databaseName,
                    TableName = tableName,
                },
            });

            return await Execute(Settings.ConnectionString(), Settings.Get("CONFIG_PROCEDURE"), parameters);
        }
        public static async Task<TResult> Execute(string systemName, TDictionary? parameters)
        {
            var parms = parameters?["Parameters"];
            string? databaseName = Convert.ToString(parms?["DatabaseName"]);
            string? tableName = Convert.ToString(parms?["TableName"]);
            string action = Convert.ToString(parms?["Action"]) ?? string.Empty;

            var configTables = (await GetConfig(systemName, databaseName, tableName)).DataSet.Tables;
            var connectionRow = configTables[1].Rows[0];
            var connectionString = Settings.ConnectionString(connectionRow);
            string procedureName;

            if (action == Actions.BEGIN) procedureName = "TransactionBegin";
            else if (action == Actions.COMMIT) procedureName = "TransactionCommit";
            else if (action == Actions.ROLLBACK) procedureName = "TransactionRollback";
            else if (action == Actions.READ) procedureName = $"{tableName}Read";
            else if (action == Actions.GENERATE) procedureName = "GenerateId";
            else throw new Exception($"Ação inválida.");

            return await Execute(connectionString, procedureName, parameters?["Parameters"]);
        }
    }
}