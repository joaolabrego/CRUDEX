using System.IO;
using System.Text;
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
                // Do work that can write to the Response.
                Console.WriteLine("teste");
                await next.Invoke();
                // Do logging or other work that doesn't write to the Response.
            });

            app.MapGet("/", (HttpResponse response) =>
            {
                response.Headers.ContentType = "text/html;";
                //Scripts.GetScript("cruda");
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
            app.MapPost("/{systemName}/" + Actions.CONFIG, (HttpResponse response, string systemName) =>
            {
                response.Headers.ContentType = "application/json";
                try
                {
                    var config = new Config(systemName, "all").ToString();

                    //File.WriteAllText($"{Directory.GetCurrentDirectory()}/config.json", config);
                    response.WriteAsync(config, Encoding.UTF8);
                }
                catch (Exception ex)
                {
                    response.WriteAsync(new Error(ex.Message).ToString(), Encoding.UTF8);
                }
            });
            app.MapPost("/{systemName}/" + Actions.LOGIN, (HttpContext context, string systemName, object body) =>
            {
                context.Response.Headers.ContentType = "application/json";
                try
                {
                    context.Response.WriteAsync(Login.Execute(systemName, Config.GetParameters(context.Request, body)).ToString(), Encoding.UTF8);
                }
                catch (Exception ex)
                {
                    context.Response.WriteAsync(new Error(ex.Message).ToString(), Encoding.UTF8);
                }
            });
            app.MapPost("/{systemName}/" + Actions.LOGOUT, (HttpContext context, string systemName, object body) =>
            {
                context.Response.Headers.ContentType = "application/json";
                try
                {
                    context.Response.WriteAsync(Login.Execute(systemName, Config.GetParameters(context.Request, body)).ToString(), Encoding.UTF8);
                }
                catch (Exception ex)
                {
                    context.Response.WriteAsync(new Error(ex.Message).ToString(), Encoding.UTF8);
                }
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
    }
}