using crudex.Classes.Models;
using Newtonsoft.Json;
using System;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public static class Login
    {
        public readonly static string ClassName = "Login";
        public static string SerializeParameters(TDictionary login, bool forceAuthenticate = false)
        {
            var action = Convert.ToString(login["Action"]) ?? string.Empty;
            return JsonConvert.SerializeObject(new
            {
                SystemName = login["SystemName"],
                UserName = login["UserName"],
                Password = login["Password"],
                LoginId = action == Actions.LOGIN || action == Actions.CHANGE ? null : login["LoginId"],
                Action = forceAuthenticate ? Actions.AUTHENTICATE : login["Action"],
                NewPassword = login["NewPassword"],
                RetypedPassword = login["RetypedPassword"],
                PublicKey = login.TryGetValue("PublicKey", out dynamic? publicKey) ? publicKey : null,
                ClientRsaPublicKey = login.TryGetValue("ClientRsaPublicKey", out dynamic? clientRsa) ? clientRsa : null,
            });
        }
        public static async Task<TResult> Execute(TDictionary? parameters, bool forceAuthenticate = false)
        {
            if (parameters != null && parameters.TryGetValue("Login", out dynamic? login))
            {
                if (login == null)
                    throw new Exception("Login requerido em Parameters.");
                else if (login.ContainsKey("SystemName") && login.ContainsKey("UserName") && login.ContainsKey("Password") && login.ContainsKey("Action"))
                {
                    return await Procedure.Execute(
                        Settings.ConnectionString(),
                        "[dbo].[Login]",
                        Config.ToDictionary(new
                        {
                            InParams = new
                            {
                                Parameters = SerializeParameters(login, forceAuthenticate),
                            },
                        }));
                }
                else
                    throw new Exception("Parâmetro(s) SystemName e/ou UserName e/ou Password e/ou Action requeridos em Login.");
            }
            throw new Exception("Parameters requerido.");
        }
        public static async Task<string> GetPublicKey(long loginId)
        {
            return (await GetSessionKeys(loginId)).AesKey;
        }

        public static async Task<string> GetClientRsaPublicKey(long loginId)
        {
            return (await GetSessionKeys(loginId)).ClientRsaPublicKey;
        }

        static async Task<(string AesKey, string ClientRsaPublicKey)> GetSessionKeys(long loginId)
        {
            var row = (await Procedure.Execute(
                Settings.ConnectionString(),
                "[dbo].[GetPublicKey]",
                Config.ToDictionary(new
                {
                    InParams = new
                    {
                        SessionId = loginId,
                    }
                }))).DataSet.Tables[0].Rows[0];
            return (
                row["PublicKey"].ToString() ?? string.Empty,
                row["ClientRsaPublicKey"].ToString() ?? string.Empty);
        }
    }
}
