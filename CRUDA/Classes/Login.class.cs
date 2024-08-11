using CRUDA.Classes.Models;
using System;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public static class Login
    {
        public readonly static string ClassName = "Login";
        public static SQLResult Execute(string systemName, string action, Dictionary? parameters)
        {
            if (parameters != null && parameters.TryGetValue("Login", out dynamic? login))
            {
                if (login == null)
                    throw new Exception("Login requerido em Parameters.");
                else if (login.ContainsKey("UserName") && login.ContainsKey("Password"))
                    return SQLProcedure.Execute(
                        Settings.ConnecionString(),
                        Settings.Get("LOGIN_PROCEDURE"),
                        Config.ToDictionary(new
                        {
                            InputParams = new
                            {
                                SystemName = systemName,
                                UserName = login["UserName"],
                                Password = login["Password"],
                                PublicKey = action == Actions.LOGIN ? login["PublicKey"] : null,
                                Action = action,
                            }
                        }));
                else
                    throw new Exception("Parâmetro(s) UserName e/ou Password e/ou Action requeridos em Login.");
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
                })).Tables[0].Rows[0]["PublicKey"].ToString() ?? "";
        }
    }
}
