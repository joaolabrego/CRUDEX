using CRUDA.Classes.Models;
using Newtonsoft.Json;
using System;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public static class Login
    {
        public readonly static string ClassName = "Login";
        public static TResult Execute(TDictionary? parameters, bool forceAuthenticate = false)
        {
            if (parameters != null && parameters.TryGetValue("Login", out dynamic? login))
            {
                if (login == null)
                    throw new Exception("Login requerido em Parameters.");
                else if (login.ContainsKey("SystemName") && login.ContainsKey("UserName") && login.ContainsKey("Password") && login.ContainsKey("Action"))
                {
                    return SQLProcedure.Execute(
                        Settings.ConnecionString(),
                        Settings.Get("LOGIN_PROCEDURE"),
                        Config.ToDictionary(new
                        {
                            InputParams = new
                            {
                                Parameters = JsonConvert.SerializeObject(new
                                {
                                    SystemName = login["SystemName"],
                                    UserName = login["UserName"],
                                    Password = login["Password"],
                                    PublicKey = login["Action"] == Actions.LOGIN ? Crypto.GenerateCryptoKey() : null,
                                    LoginId = login["Action"] == Actions.LOGIN ? null : login["LoginId"],
                                    Action = forceAuthenticate ? Actions.AUTHENTICATE : login["Action"],
                                }),
                            },
                        }));
                }
                else
                    throw new Exception("Parâmetro(s) SystemName e/ou UserName e/ou Password e/ou Action requeridos em Login.");
            }
            throw new Exception("Parameters requerido.");
        }
        public static string GetPublicKey(long loginId)
        {
            return SQLProcedure.Execute(
                Settings.ConnecionString(),
                Settings.Get("PUBLICKEY_PROCEDURE"),
                Config.ToDictionary(new
                {
                    InputParams = new
                    {
                        LoginId = loginId,
                    }
                })).Tables[0].Rows[0]["PublicKey"].ToString() ?? string.Empty;
        }
    }
}
