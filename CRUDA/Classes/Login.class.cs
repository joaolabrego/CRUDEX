using CRUDA.Classes.Models;
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
                {
                    return SQLProcedure.Execute(
                        Settings.ConnecionString(),
                        Settings.Get("LOGIN_PROCEDURE"),
                        Config.ToDictionary(new
                        {
                            InputParams = new
                            {
                                Action = action,
                                SystemName = systemName,
                                UserName = login["UserName"],
                                Password = login["Password"],
                            }
                        }));
                }
                else
                    throw new Exception("Parâmetro(s) UserName e/ou Password requerido(s) em Login.");
            }
            throw new Exception("Parameters requerido.");
        }
    }
}
