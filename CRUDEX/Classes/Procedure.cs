using System.Data;
using crudex.Classes.Models;
using Microsoft.Data.SqlClient;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public static class Procedure
    {
        public readonly static string ClassName = "Procedure";
        static readonly HashSet<string> LoginEmbeddedActions = new(StringComparer.OrdinalIgnoreCase)
        {
            Actions.READ,
            Actions.PERSIST,
            Actions.COMMIT,
        };
        static readonly HashSet<string> ActionsWithoutReturnValueOut = new(StringComparer.OrdinalIgnoreCase)
        {
            Actions.PERSIST,
            Actions.ROLLBACK,
        };
        public static async Task<TResult> Execute(string? connectionString, string? procedureName, TDictionary? parameters = null, bool withReturnValueOut = true)
        {
            using var dataset = new DataSet();
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

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
            if (withReturnValueOut)
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

            return await Execute(Settings.ConnectionString(), "[dbo].[Config]", parameters);
        }
        static string GetLoginJson(TDictionary? parameters)
        {
            if (parameters == null || !parameters.TryGetValue("Login", out dynamic? login) || login is not TDictionary loginDict)
                throw new Exception("Login requerido.");
            return Login.SerializeParameters(loginDict, forceAuthenticate: true);
        }
        static string GetTableAlias(DataSet configDataSet, string? tableName)
        {
            var tables = configDataSet.Tables[3];
            foreach (System.Data.DataRow row in tables.Rows)
            {
                if (string.Equals(Convert.ToString(row["Name"]), tableName, StringComparison.OrdinalIgnoreCase))
                    return Convert.ToString(row["Alias"]) ?? tableName ?? throw new Exception("Alias da tabela não encontrado.");
            }
            throw new Exception($"Tabela '{tableName}' não encontrada na configuração.");
        }
        static TDictionary BuildProcedureParameters(TDictionary? parameters, string action)
        {
            var procedureParameters = Config.ToDictionary(parameters?["Parameters"] ?? new { });
            TDictionary inParams;
            if (procedureParameters.TryGetValue("InParams", out dynamic? inParamsValue) && inParamsValue != null)
                inParams = Config.ToDictionary(inParamsValue);
            else
                inParams = new TDictionary();

            if (LoginEmbeddedActions.Contains(action))
            {
                inParams["Login"] = GetLoginJson(parameters);
                inParams.Remove("LoginId");
                inParams.Remove("SessionId");
                inParams.Remove("UserName");
            }

            procedureParameters["InParams"] = inParams;
            return procedureParameters;
        }
        public static async Task<TResult> Execute(string systemName, TDictionary? parameters)
        {
            var parms = parameters?["Parameters"];
            string? databaseName = Convert.ToString(parms?["DatabaseName"]);
            string? tableName = Convert.ToString(parms?["TableName"]);
            if (parms is not TDictionary parmsDict || !parmsDict.TryGetValue("Action", out dynamic? actionValue))
                throw new Exception("Parameters.Action é obrigatório no JSON.");
            string action = Convert.ToString(actionValue) ?? string.Empty;

            var configResult = await GetConfig(systemName, databaseName, tableName);
            var configTables = configResult.DataSet.Tables;
            var connectionRow = configTables[1].Rows[0];
            var connectionString = Settings.ConnectionString(connectionRow);
            string procedureName;
            var configDataSet = configResult.DataSet;

            var alias = GetTableAlias(configDataSet, tableName);

            if (action == Actions.READ)
                procedureName = $"[dbo].[{tableName}Read]";
            else if (action == Actions.LIST)
                procedureName = $"[dbo].[{tableName}List]";
            else if (action == Actions.PERSIST)
                procedureName = $"[dbo].[{alias}Persist]";
            else if (action == Actions.CREATE)
                procedureName = $"[dbo].[{alias}Create]";
            else if (action == Actions.COMMIT)
                procedureName = $"[dbo].[{alias}Commit]";
            else if (action == Actions.ROLLBACK)
                procedureName = $"[dbo].[{alias}Rollback]";
            else if (action == Actions.GENERATE)
                procedureName = "[dbo].[GenerateId]";
            else
                throw new Exception($"Ação inválida.");

            var procedureParameters = LoginEmbeddedActions.Contains(action)
                ? BuildProcedureParameters(parameters, action)
                : parameters?["Parameters"];

            var withReturnValueOut = !ActionsWithoutReturnValueOut.Contains(action);
            return await Execute(connectionString, procedureName, procedureParameters, withReturnValueOut);
        }
    }
}
