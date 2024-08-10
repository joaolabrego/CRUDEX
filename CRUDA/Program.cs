using System;
using System.Text;
using CRUDA.Classes.Models;
using Newtonsoft.Json;
using NPOI.XWPF.UserModel;

namespace CRUDA_LIB
{
    public class Program
    {
        public static void Main()
        {
            var app = Settings.Initialize();

            app.Use(async (context, next) =>
            {
                //Scripts.GenerateScript("cruda", "cruda");
                await next.Invoke();
            });

            app.MapGet("/", (HttpContext context) =>
            {
                ExecuteRoute(context);
            });
            app.MapGet("/{systemName}", (HttpContext context, string systemName) =>
            {
                ExecuteRoute(context, systemName, Actions.CHECK_SYSTEM);
            });
            app.MapPost("/{systemName}/{action}", (HttpContext context, string systemName, string action, dynamic body) =>
            {
                ExecuteRoute(context, systemName, action, body);
            });
            app.Run();
        }
        private static void ExecuteRoute(HttpContext context, string systemName = "", string? action = null, dynamic? body = null)
        {
            try
            {
                switch (action)
                {
                    case null:
                        context.Request.Headers.ContentType = "text/html;";
                        context.Response.WriteAsync(Config.GetHTML("cruda", "Nome do sistema é requerido na URL."), Encoding.UTF8);
                        break;
                    case Actions.CHECK_SYSTEM:
                        context.Response.Headers.ContentType = "text/html";
                        SQLProcedure.GetConfig(systemName);
                        context.Response.WriteAsync(Config.GetHTML(systemName), Encoding.UTF8);
                        break;
                    case Actions.CONFIG:
                        context.Response.Headers.ContentType = "application/json";
                        context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = new Config(systemName, "all"), }), Encoding.UTF8);
                        break;
                    case Actions.LOGIN:
                    case Actions.LOGOUT:
                    case Actions.EXECUTE:
                        var decryptedBody = new Crypto(context.Request.Headers["PublicKey"]).Encrypt(Config.ToDictionary(JsonConvert.DeserializeObject(Convert.ToString(body)))["Request"]);
                        var request = Config.ToDictionary(JsonConvert.DeserializeObject(decryptedBody));
                        var parameters = Config.ToDictionary(new
                        {
                            Login = JsonConvert.DeserializeObject(request["Login"].ToString()),
                            Parameters = JsonConvert.DeserializeObject((request["Parameters"] ?? new { })),
                        });
                        if (action == Actions.EXECUTE)
                        {
                            context.Response.Headers.ContentType = "application/json";
                            context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = SQLProcedure.Execute(systemName, parameters), }), Encoding.UTF8);
                        }
                        else
                        {
                            context.Response.Headers.ContentType = "application/json";
                            context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = Login.Execute(systemName, action, parameters) }), Encoding.UTF8);
                        }
                        break;
                    default:
                        throw new Exception($"Ação '{action}' desconhecida em rota.");
                }
            }
            catch (Exception ex)
            {
                if (action == Actions.CHECK_SYSTEM)
                {
                    context.Response.Headers.ContentType = "text/html";
                    context.Response.WriteAsync(Config.GetHTML(systemName, ex.Message), Encoding.UTF8);
                }
                else
                {
                    context.Response.Headers.ContentType = "application/json";
                    context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = new Error(ex.Message, Actions.LOGIN) }), Encoding.UTF8);
                }
            }
        }
    }
}