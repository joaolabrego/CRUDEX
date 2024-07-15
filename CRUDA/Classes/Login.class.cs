using CRUDA.Classes.Models;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public static class Login
    {
        public readonly static string ClassName = "Login";
        public static SQLResult Execute(string systemName, Dictionary? parameters)
        {
            if (parameters != null && parameters.TryGetValue("Login", out dynamic? login))
            {
                if (login == null)
                    throw new Exception("Parâmetro Login não passado para SQLResult.Execute.");
                else if (login.ContainsKey("UserName") && login.ContainsKey("Password") && login.ContainsKey("Action"))
                    return SQLProcedure.Execute(Settings.ConnectionString(),
                                                Settings.Get("LOGIN_PROCEDURE"),
                                                Config.ToDictionary(new
                                                {
                                                    InputParams = new
                                                    {
                                                        SystemName = systemName,
                                                        UserName = login["UserName"],
                                                        Password = login["Password"],
                                                        Action = login["Action"],
                                                    }
                                                }));
                else
                    throw new Exception("Parâmetro(s) UserName e/ou Password e/ou Action não definidos no parâmetro Login de Execute.");
            }
            throw new Exception("Parâmetros não passados para Execute.");
        }
    }
}
