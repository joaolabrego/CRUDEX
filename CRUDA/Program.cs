using System.Text;
using CRUDA.Classes;
using CRUDA.Classes.Models;
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

            app.MapGet("/", (HttpResponse response) =>
            {
                response.Headers.ContentType = "text/html;";
                Scripts.GenerateScript("cruda", "cruda");
                response.WriteAsync(Config.GetHTML("cruda", "Nome do sistema é requerido na URL."), Encoding.UTF8);
            });
            app.MapGet("/{systemName}", (HttpResponse response, string systemName) =>
            {
                response.Headers.ContentType = "text/html"; 
                try
                {
                    response.WriteAsync(new Config(systemName).GetHTML(systemName), Encoding.UTF8);
                }
                catch(Exception ex)
                {
                    response.WriteAsync(Config.GetHTML(systemName, ex.Message), Encoding.UTF8);
                }
            });
            app.MapPost($"/{{systemName}}/{Actions.CONFIG}", (HttpContext context, string systemName) =>
            {
                ExecuteRoute(context, systemName, Actions.CONFIG);
            });
            app.MapPost($"/{{systemName}}/{Actions.LOGIN}", (HttpContext context, string systemName, object body) =>
            {
                ExecuteRoute(context, systemName, Actions.LOGIN, Config.GetParameters(context.Request, body));
            });
            app.MapPost($"/{{systemName}}/{Actions.LOGOUT}", (HttpContext context, string systemName, object body) =>
            {
                ExecuteRoute(context, systemName, Actions.LOGOUT, Config.GetParameters(context.Request, body));
            });
            app.MapPost("/{systemName}/{databaseName}/{tableName}/{action}", (HttpContext context, string systemName, string databaseName, 
                                                                              string tableName, string action, object body) =>
            {
                context.Response.Headers.ContentType = "application/json";
                try
                {
                    var parameters = Config.GetParameters(context.Request, body);
                    var login = Login.Execute(systemName, Actions.AUTHENTICATE, parameters);

                    try
                    {
                        context.Response.WriteAsync(SQLProcedure.Execute(systemName, databaseName, tableName, action, parameters).ToString(), Encoding.UTF8);
                    }
                    catch (Exception ex)
                    {
                        context.Response.WriteAsync(new Error(ex.Message, Actions.MENU).ToString(), Encoding.UTF8);
                    }
                }
                catch (Exception ex)
                {
                    context.Response.WriteAsync(new Error(ex.Message, Actions.LOGIN).ToString(), Encoding.UTF8);
                }
            });

            app.Run();
        }
        private static void ExecuteRoute(HttpContext context, string systemName, string action, Dictionary? parameters = null)
        {
            try
            {
                context.Response.Headers.ContentType = "application/json";
                switch (action)
                {
                    case Actions.CONFIG:
                        context.Response.WriteAsync(new Config(systemName, "all").ToString(), Encoding.UTF8);
                        break;
                    case Actions.LOGIN:
                    case Actions.LOGOUT:
                        context.Response.WriteAsync(Login.Execute(systemName, action, parameters).ToString(), Encoding.UTF8);
                        break;
                    default:
                        throw new Exception("Ação inválida em rota.");
                }
            }
            catch (Exception ex)
            {
                context.Response.WriteAsync(new Error(ex.Message).ToString(), Encoding.UTF8);
            }
        }
    }
}