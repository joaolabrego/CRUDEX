using System.Text;
using CRUDA.Classes;
using CRUDA.Classes.Models;
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
                var objects = new object[]
                {
                    new { Id = 1, Name = "John", Password = "password1", FullName = "John Doe", RetryLogins = (byte)3, IsActive = true },
                    new { Id = 2, Name = "Jane", Password = "password2", FullName = "Jane Doe", RetryLogins = (byte)2, IsActive = false }
                };

                foreach (var user in TUser.ToArray<TUser>(objects))
                    Console.WriteLine($"Id: {user.Id}, Name: {user.Name}, Password: {user.Password}, FullName: {user.FullName}, RetryLogins: {user.RetryLogins}, IsActive: {user.IsActive}");
                await next.Invoke();
            });

            app.MapGet("/", (HttpResponse response) =>
            {
                response.Headers.ContentType = "text/html;";
                Scripts.GenerateScript("cruda", "cruda");
                //var a = ORM.GetDataTable(Settings.ConnectionString(true), "Columns", null, null, 0, 10);
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
            app.MapPost("/{systemName}/{action}", (HttpContext context, string systemName, string action, object body) =>
            {
                context.Response.Headers.ContentType = "application/json";
                try
                {
                    switch (action)
                    {
                        case Actions.CONFIG:
                            var config = new Config(systemName, "all").ToString();

                            //File.WriteAllText($"{Directory.GetCurrentDirectory()}/config.json", config);
                            context.Response.WriteAsync(config, Encoding.UTF8);
                            break;
                        case Actions.LOGIN:
                        case Actions.LOGOUT:
                            context.Response.WriteAsync(Login.Execute(systemName, Config.GetParameters(context.Request, body)).ToString(), Encoding.UTF8);
                            break;
                        default:
                            throw new Exception("Ação inválida na URL.");
                    }
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
                    context.Response.WriteAsync(SQLProcedure.Execute(systemName, databaseName, tableName, action, Config.GetParameters(context.Request, body)).ToString(), Encoding.UTF8);
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