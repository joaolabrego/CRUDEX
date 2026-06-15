using System.Text;
using crudex.Classes;
using crudex.Classes.Models;
using Newtonsoft.Json;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public class Program
    {
        static readonly HashSet<string> LoginOnlyActions = new(StringComparer.OrdinalIgnoreCase)
        {
            Actions.LOGIN,
            Actions.LOGOUT,
            Actions.CHANGE,
        };
        static readonly HashSet<string> LoginEmbeddedProcedureActions = new(StringComparer.OrdinalIgnoreCase)
        {
            Actions.READ,
            Actions.PERSIST,
            Actions.COMMIT,
        };

        private static async Task Main(string[] args)
        {
            if (args.Length > 0 && args[0] == "--generate-script")
            {
                var withInsertData = args.Any(arg => arg.Equals("--with-data", StringComparison.OrdinalIgnoreCase));
                await Scripts.Generate(withInsertData: withInsertData);
                return;
            }

            var app = Settings.Initialize();

            app.Use(async (context, next) =>
            {
                var path = context.Request.Path.Value;

                if (context.Request.Method == "GET" &&
                    (path?.EndsWith(".class.mjs") == true || path?.EndsWith(".min.js") == true))
                {
                    var relativePath = path.TrimStart('/');

                    if (relativePath.Contains("..") || relativePath.Contains(':') || relativePath.Contains('\\'))
                    {
                        context.Response.StatusCode = 400;
                        return;
                    }

                    var file = Path.Combine(Settings.Builder.Environment.ContentRootPath, "StaticFiles", relativePath);

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
                await ExecuteRoute(context);
            });
            app.MapGet("/{systemName}", async (HttpContext context, string systemName) => await ExecuteRoute(context, systemName, Actions.CHECK));
            app.MapPost("/{systemName}", async (HttpContext context, string systemName) => await ExecuteRoute(context, systemName));
            await app.RunAsync();
        }

        static TDictionary? GetChildDictionary(TDictionary? parent, string key)
        {
            if (parent == null || !parent.TryGetValue(key, out dynamic? child) || child is not TDictionary childDictionary)
                return null;
            return childDictionary;
        }

        static string RequireDictionaryValue(TDictionary? dictionary, string key, string context)
        {
            if (dictionary == null || !dictionary.TryGetValue(key, out dynamic? value))
                throw new Exception($"{context}.{key} é obrigatório no JSON.");
            var text = Convert.ToString(value) ?? string.Empty;
            if (string.IsNullOrWhiteSpace(text))
                throw new Exception($"{context}.{key} não pode ser vazio.");
            return text;
        }

        static async Task ExecuteRoute(HttpContext context, string systemName = "", string? routeAction = null)
        {
            var isApiRequest = context.Request.Method == "POST";
            byte[]? aesKey = null;
            string? clientRsaPublicKey = null;

            try
            {
                var systemParameters = systemName.Split('.');

                if (systemParameters.Length < 2)
                {
                    context.Response.ContentType = "text/html; charset=utf-8";
                    await context.Response.WriteAsync(Config.GetHTML("crudex", "Nomes do sistema e do ambiente são requeridos na URL."), Encoding.UTF8);
                    return;
                }
                systemName = systemParameters.FirstOrDefault()!;

                string response = "";

                if (routeAction == Actions.CHECK)
                {
                    context.Response.Headers.ContentType = "text/html";
                    await Procedure.GetConfig(systemName);
                    await context.Response.WriteAsync(Config.GetHTML(systemName), Encoding.UTF8);
                    return;
                }

                if (!isApiRequest)
                {
                    context.Response.ContentType = "text/html; charset=utf-8";
                    await context.Response.WriteAsync(Config.GetHTML("crudex", "Nome do sistema é requerido na URL."), Encoding.UTF8);
                    return;
                }

                using var reader = new StreamReader(context.Request.Body);
                var bodyText = await reader.ReadToEndAsync();
                var outer = Config.ToDictionary(JsonConvert.DeserializeObject(string.IsNullOrWhiteSpace(bodyText) ? "{}" : bodyText) ?? new object());
                var requestText = Convert.ToString(outer["Request"] ?? "{}") ?? "{}";
                aesKey = await Api.ResolveRequestAesKey(context, outer, requestText);
                var requestJson = Api.DecryptRequestPayload(requestText, aesKey);
                var request = Config.ToDictionary(JsonConvert.DeserializeObject(requestJson) ?? new object());
                var parameters = Config.ToDictionary(new
                {
                    Login = request.TryGetValue("Login", out dynamic? login) ? login : null,
                    Parameters = request.TryGetValue("Parameters", out dynamic? parms) ? parms : null,
                });

                var loginDict = GetChildDictionary(parameters, "Login");
                var parmsDict = GetChildDictionary(parameters, "Parameters");
                if (loginDict?.TryGetValue("ClientRsaPublicKey", out dynamic? clientRsa) == true)
                    clientRsaPublicKey = Convert.ToString(clientRsa);
                var hasLoginAction = loginDict?.ContainsKey("Action") == true;
                var hasParametersAction = parmsDict?.ContainsKey("Action") == true;
                var loginAction = hasLoginAction ? RequireDictionaryValue(loginDict, "Action", "Login") : string.Empty;
                var parametersAction = hasParametersAction ? RequireDictionaryValue(parmsDict, "Action", "Parameters") : string.Empty;

                if (parametersAction == Actions.CONFIG)
                    response = JsonConvert.SerializeObject(await Config.Create(systemName, "all"));
                else if (hasLoginAction && LoginOnlyActions.Contains(loginAction))
                    response = JsonConvert.SerializeObject(await Login.Execute(parameters));
                else if (hasParametersAction)
                {
                    if (!LoginEmbeddedProcedureActions.Contains(parametersAction))
                        await Login.Execute(parameters, true);
                    response = JsonConvert.SerializeObject(await Procedure.Execute(systemName, parameters));
                }
                else
                    throw new Exception("Ação não especificada no JSON (Login.Action ou Parameters.Action).");

                await Api.WriteJsonResponse(context, response, aesKey, clientRsaPublicKey);
            }
            catch (Exception ex)
            {
                if (!isApiRequest || routeAction == Actions.CHECK)
                {
                    context.Response.Headers.ContentType = "text/html";
                    await context.Response.WriteAsync(Config.GetHTML(systemName, ex.Message), Encoding.UTF8);
                }
                else
                {
                    var response = JsonConvert.SerializeObject(new Error(ex.Message));
                    await Api.WriteJsonResponse(context, response, aesKey, clientRsaPublicKey);
                }
            }
        }
    }
}
