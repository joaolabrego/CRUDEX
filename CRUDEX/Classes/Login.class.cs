using crudex.Classes.Models;
using Newtonsoft.Json;
using System;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public static class Login
    {
        public readonly static string ClassName = "Login";
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
                        Settings.Get("LOGIN_PROCEDURE"),
                        Config.ToDictionary(new
                        {
                            InParams = new
                            {
                                Parameters = JsonConvert.SerializeObject(new
                                {
                                    SystemName = login["SystemName"],
                                    UserName = login["UserName"],
                                    Password = login["Password"],
                                    LoginId = login["Action"] == Actions.LOGIN || login["Action"] == Actions.CHANGE ? null : login["LoginId"],
                                    Action = forceAuthenticate ? Actions.AUTHENTICATE : login["Action"],
                                    NewPassword = login["NewPassword"],
                                    RetypedPassword = login["RetypedPassword"],
                                }),
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
            return (await Procedure.Execute(
                Settings.ConnectionString(),
                Settings.Get("PUBLICKEY_PROCEDURE"),
                Config.ToDictionary(new
                {
                    InParams = new
                    {
                        LoginId = loginId,
                    }
                }))).DataSet.Tables[0].Rows[0]["PublicKey"].ToString() ?? string.Empty;
        }
    }
}
