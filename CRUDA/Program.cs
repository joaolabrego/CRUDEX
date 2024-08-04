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
                        context.Response.WriteAsync(new Config(systemName, "all").ToString(), Encoding.UTF8);
                        break;
                    case Actions.LOGIN:
                    case Actions.LOGOUT:
                    case Actions.EXECUTE:
                        var parameters = Config.ToDictionary(new
                        {
                            Login = JsonConvert.DeserializeObject(context.Request.Headers["Login"].ToString()),
                            Parameters = JsonConvert.DeserializeObject((body ?? new { }).ToString()),
                        });
                        if (action == Actions.EXECUTE)
                        {
                            context.Response.Headers.ContentType = "application/json";
                            Login.Execute(systemName, Actions.AUTHENTICATE, parameters);
                            context.Response.WriteAsync(SQLProcedure.Execute(systemName, parameters).ToString(), Encoding.UTF8);
                        }
                        else
                        {
                            context.Response.Headers.ContentType = "application/json";
                            context.Response.WriteAsync(Login.Execute(systemName, action, parameters).ToString(), Encoding.UTF8);
                        }
                        break;
                    default:
                        throw new Exception($"Ação '{action}' desconhecida em rota.");
                }
            }
            catch (Exception ex)
            {
                var message = action == Actions.CHECK_SYSTEM ? Config.GetHTML(systemName, ex.Message) : new Error(ex.Message, Actions.LOGIN).ToString();

                context.Response.WriteAsync(message, Encoding.UTF8);
            }
        }
    }
}