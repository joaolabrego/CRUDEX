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
                        var response = new Crypto(context.Request.Headers["PublicKey"]).Encrypt(JsonConvert.SerializeObject(new Config(systemName, "all")));

                        context.Response.Headers.ContentType = "application/json";
                        context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response }), Encoding.UTF8);
                        break;
                    case Actions.LOGIN:
                    case Actions.LOGOUT:
                    case Actions.EXECUTE:
                        var publicKey = action == Actions.LOGIN 
                            ? context.Request.Headers["PublicKey"].ToString() 
                            : Login.GetPublicKey(Convert.ToInt64(context.Request.Headers["LoginId"]));
                        var request = Config.ToDictionary(JsonConvert.DeserializeObject(new Crypto(publicKey)
                            .Encrypt(Config.ToDictionary(JsonConvert.DeserializeObject(Convert.ToString(body)))["Request"])));
                        var parameters = Config.ToDictionary(new
                        {
                            Login = request["Login"],
                            Parameters = request["Parameters"],
                        });
                        response = new Crypto(publicKey).Encrypt(JsonConvert.SerializeObject(
                            action == Actions.EXECUTE 
                            ? SQLProcedure.Execute(systemName, parameters) 
                            : Login.Execute(systemName, action, parameters)));
                        context.Response.Headers.ContentType = "application/json";
                        context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response, }), Encoding.UTF8);
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
                    var response = new Crypto(context.Request.Headers["PublicKey"]).Encrypt(JsonConvert.SerializeObject(new Error(ex.Message, Actions.LOGIN)));

                    context.Response.Headers.ContentType = "application/json";
                    context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response }), Encoding.UTF8);
                }
            }
        }
    }
}