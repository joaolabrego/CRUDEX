using System.Dynamic;
using System.Text;
using CRUDA.Classes;
using CRUDA.Classes.Models;
using Microsoft.AspNetCore.Http;
using Newtonsoft.Json;
using NPOI.XWPF.UserModel;
using Org.BouncyCastle.Asn1.Ocsp;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public class Program
    {
        public static void Main()
        {
            var app = Settings.Initialize();

            app.Use(async (context, next) =>
            {
                await next.Invoke();
            });

            app.MapGet("/", (HttpContext context) =>
            {
                //Scripts.GenerateScript("cruda", "cruda");
                ExecuteRoute(context, "", Actions.NO_SYSTEM);
            });
            app.MapGet("/{systemName}", (HttpContext context, string systemName) =>
            {
                ExecuteRoute(context, systemName, Actions.CHECK_SYSTEM);
            });
            app.MapPost($"/{{systemName}}/{Actions.CONFIG}", (HttpContext context, string systemName) =>
            {
                ExecuteRoute(context, systemName, Actions.CONFIG);
            });
            app.MapPost($"/{{systemName}}/{Actions.LOGIN}", (HttpContext context, string systemName, dynamic body) =>
            {
                ExecuteRoute(context, systemName, Actions.LOGIN, body);
            });
            app.MapPost($"/{{systemName}}/{Actions.LOGOUT}", (HttpContext context, string systemName, dynamic body) =>
            {
                ExecuteRoute(context, systemName, Actions.LOGOUT, body);
            });
            app.MapPost($"/{{systemName}}/{Actions.EXECUTE}", (HttpContext context, string systemName, dynamic body) =>
            {
                ExecuteRoute(context, systemName, Actions.EXECUTE, body);
            });

            app.Run();
        }
        private static void ExecuteRoute(HttpContext context, string systemName, string action, dynamic? body = null)
        {
            var response = context.Response;

            try
            {
                var parameters = Config.ToDictionary(new
                {
                    Login = JsonConvert.DeserializeObject(context.Request.Headers["Login"].ToString()),
                    Parameters = JsonConvert.DeserializeObject((body ?? new { }).ToString()),
                });

                switch (action)
                {
                    case Actions.NO_SYSTEM:
                        response.Headers.ContentType = "text/html;";
                        response.WriteAsync(Config.GetHTML("cruda", "Nome do sistema é requerido na URL."), Encoding.UTF8);
                        break;
                    case Actions.CHECK_SYSTEM:
                        response.Headers.ContentType = "text/html";
                        SQLProcedure.GetConfig(systemName);
                        response.WriteAsync(Config.GetHTML(systemName), Encoding.UTF8);
                        break;
                    case Actions.CONFIG:
                        response.Headers.ContentType = "application/json";
                        response.WriteAsync(new Config(systemName, "all").ToString(), Encoding.UTF8);
                        break;
                    case Actions.LOGIN:
                    case Actions.LOGOUT:
                        response.Headers.ContentType = "application/json";
                        response.WriteAsync(Login.Execute(systemName, action, parameters).ToString(), Encoding.UTF8);
                        break;
                    case Actions.EXECUTE:
                        response.Headers.ContentType = "application/json";
                        Login.Execute(systemName, Actions.AUTHENTICATE, parameters);
                        response.WriteAsync(SQLProcedure.Execute(systemName, parameters).ToString(), Encoding.UTF8);
                        break;
                    default:
                        throw new Exception("Ação inválida em rota.");
                }
            }
            catch (Exception ex)
            {
                var message = action == Actions.CHECK_SYSTEM ? Config.GetHTML(systemName, ex.Message) : new Error(ex.Message, Actions.LOGIN).ToString();

                response.WriteAsync(message, Encoding.UTF8);
            }
        }
    }
}