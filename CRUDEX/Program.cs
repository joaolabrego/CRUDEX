using System.Text;
using crudex.Classes;
using crudex.Classes.Models;
using Newtonsoft.Json;

namespace CRUDEX.Classes
{
    public class Program
    {
        private static async Task Main()
        {
            var app = Settings.Initialize();

            app.Use(async (context, next) =>
            {
                var p = context.Request.Path.Value;

                if (context.Request.Method == "GET" &&
                    (p?.EndsWith(".class.mjs") == true || p?.EndsWith(".min.js") == true))
                {
                    var rel = p.TrimStart('/');

                    if (rel.Contains("..") || rel.Contains(':') || rel.Contains('\\'))
                    {
                        context.Response.StatusCode = 400;
                        return;
                    }

                    var file = Path.Combine(Settings.Builder.Environment.ContentRootPath, "StaticFiles", rel);

                    if (!File.Exists(file))
                    {
                        context.Response.StatusCode = 404;
                        return;
                    }

                    context.Response.ContentType = "text/javascript; charset=utf-8";
                    await context.Response.SendFileAsync(file);
                    return;
                }

                await next();
            });

            app.MapGet("/", async (HttpContext context) =>
            {
                await Scripts.Generate();
                Report.Teste();
                await ExecuteRoute(context);
            });
            app.MapGet("/{systemName}", async (HttpContext context, string systemName) => await ExecuteRoute(context, systemName, Actions.CHECK));
            app.MapPost("/{systemName}/{action}", async (HttpContext context, string systemName, string action, dynamic body) =>
            {
                await ExecuteRoute(context, systemName, action, body);
            });
            await app.RunAsync();
        }
        private static async Task ExecuteRoute(HttpContext context, string systemName = "", string? action = null, dynamic? body = null)
        {
            try
            {
                var systems = systemName.Split('.');

                if (systems.Length < 2)
                {
                    context.Response.ContentType = "text/html; charset=utf-8";
                    await context.Response.WriteAsync(Config.GetHTML("crudex", "Nomes do sistema e do ambiente são requeridos na URL."), Encoding.UTF8);
                    return;
                }
                systemName = systems.FirstOrDefault()!;

                var environment = systems.LastOrDefault();
                var json = Config.ToDictionary(JsonConvert.DeserializeObject(Convert.ToString(body ?? "{}")));

                switch (action)
                {
                    case null:                        
                        await context.Response.WriteAsync(Config.GetHTML("crudex", "Nome do sistema é requerido na URL."), Encoding.UTF8);
                        break;
                    case Actions.CHECK:
                        context.Response.Headers.ContentType = "text/html";
                        await Procedure.GetConfig(systemName);
                        await context.Response.WriteAsync(Config.GetHTML(systemName), Encoding.UTF8);
                        break;
                    case Actions.CONFIG:
                        var response = JsonConvert.SerializeObject(await Config.Create(systemName, "all"));

                        context.Response.ContentType = "application/json; charset=utf-8";
                        await context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response, }), Encoding.UTF8);
                        break;
                    case Actions.LOGIN:
                    case Actions.CHANGE:
                    case Actions.LOGOUT:
                    case Actions.EXECUTE:
                        var request = Config.ToDictionary(JsonConvert.DeserializeObject(json["Request"]));
                        var parameters = Config.ToDictionary(new
                        {
                            Login = request["Login"],
                            Parameters = request["Parameters"],
                        });

                        if (action == Actions.EXECUTE)
                        {
                            await Login.Execute(parameters, true);
                            response = JsonConvert.SerializeObject(await Procedure.Execute(systemName, parameters));
                        }
                        else
                            response = JsonConvert.SerializeObject(await Login.Execute(parameters));
                        context.Response.ContentType = "application/json; charset=utf-8";
                        await context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response, }), Encoding.UTF8);
                        break;
                    default:
                        throw new Exception($"Ação '{action}' desconhecida em rota.");
                }
            }
            catch (Exception ex)
            {
                if (action == null || action == Actions.CHECK || action == Actions.CONFIG)
                {
                    context.Response.Headers.ContentType = "text/html";
                    await context.Response.WriteAsync(Config.GetHTML(systemName, ex.Message), Encoding.UTF8);
                }
                else
                {
                    var response = JsonConvert.SerializeObject(new Error(ex.Message, Actions.LOGIN));

                    context.Response.ContentType = "application/json; charset=utf-8";
                    await context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response, }), Encoding.UTF8);
                }
            }
        }
    }
}