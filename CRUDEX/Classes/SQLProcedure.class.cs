using System.Data;
using System.Data.OleDb;
using crudex.Classes.Models;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public static class SQLProcedure
    {
        public readonly static string ClassName = "SQLProcedure";
        public static async Task<TResult> Execute(string? connectionString, string? procedureName, TDictionary? parameters = null)
        {
            using var dataset = new DataSet();
            using var connection = new OleDbConnection(connectionString);
            await connection.OpenAsync(); // Tornando a abertura de conexão assíncrona

            using var command = new OleDbCommand(procedureName, connection);
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
                            command.Parameters.Add(new OleDbParameter(subItem.Key, subItem.Value ?? DBNull.Value) { Direction = direction });
                }
            }
            command.Parameters.Add(new OleDbParameter("ReturnValue", OleDbType.BigInt) { Direction = ParameterDirection.Output });
            using var adapter = new OleDbDataAdapter(command);
            await Task.Run(() => adapter.Fill(dataset));

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
            var databaseName = parms?["DatabaseName"];
            var tableName = parms?["TableName"];
            var action = parms?["Action"];
            var config = GetConfig(systemName, databaseName, tableName).Result.DataSet.Tables;
            var databaseAlias = config[2].Rows[0]["Alias"];
            var connectionRow = config[1].Rows[0];
            var connectionString = Settings.ConnectionString(databaseAlias, connectionRow);
            var procedureName = action switch
            {
                Actions.BEGIN => $"TransactionBegin",
                Actions.COMMIT => $"TransactionCommit",
                Actions.ROLLBACK => $"TransactionRollback",
                Actions.READ => $"{tableName}Read",
                Actions.GENERATE => "GenerateId",
                _ => throw new Exception($"Ação inválida."),
            };

            return await Execute(connectionString, procedureName, parameters?["Parameters"]);
        }
    }
}