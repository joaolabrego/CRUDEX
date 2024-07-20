using System.Text;
using CRUDA.Classes;
using CRUDA.Classes.Models;

namespace CRUDA_LIB
{
    public class Program
    {
        public static void Main()
        {
            var app = Settings.Initialize();

            app.Use(async (context, next) =>
            {
                Console.WriteLine("teste");
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
                ExecuteRoute(context, systemName, Actions.LOGIN);
            });
            app.MapPost($"/{{systemName}}/{Actions.LOGOUT}", (HttpContext context, string systemName, object body) =>
            {
                ExecuteRoute(context, systemName, Actions.LOGOUT);
            });
            app.MapPost("/{systemName}/{databaseName}/{tableName}/{action}", (HttpContext context, string systemName, string databaseName, string tableName, string action, object body) =>
            {
                context.Response.Headers.ContentType = "application/json";
                try
                {
                    var parameters = Config.GetParameters(context.Request, body);

                    Login.Execute(systemName, parameters);
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
                    context.Response.WriteAsync(new Error(ex.Message, Actions.MENU).ToString(), Encoding.UTF8);
                }
            });

            app.Run();
        }
        private static void ExecuteRoute(HttpContext context, string systemName, string action, object? body = null)
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
                        context.Response.WriteAsync(Login.Execute(systemName, Config.GetParameters(context.Request, body ?? new { })).ToString(), Encoding.UTF8);
                        break;
                }
            }
            catch (Exception ex)
            {
                context.Response.WriteAsync(new Error(ex.Message).ToString(), Encoding.UTF8);
            }
        }
    }
}