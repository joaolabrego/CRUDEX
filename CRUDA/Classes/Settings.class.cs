using Microsoft.Extensions.FileProviders;
using NPOI.SS.Formula.Functions;
using System.Globalization;

namespace CRUDA_LIB
{
    public static class Settings
    {
        public static readonly string ClassName = "Settings";
        private static readonly WebApplicationBuilder builder = WebApplication.CreateBuilder();
        private static readonly WebApplication app = builder.Build();
        public static WebApplication Initialize()
        {
            CultureInfo.DefaultThreadCurrentCulture = 
                CultureInfo.DefaultThreadCurrentUICulture = 
                new CultureInfo("pt-BR");
            app.UseStaticFiles(new StaticFileOptions
            {
                FileProvider = new PhysicalFileProvider(Path.Combine(builder.Environment.ContentRootPath, 
                                                                     Get("DIRECTORY_STATIC_FILES"))),
            });

            return app;
        }
        public static string ConnectionString(bool isOleDb = false)
        {
            var provider = (isOleDb ? $"Provider={ Get("DB_PROVIDER")};" : string.Empty);

            return $"{provider}Password={Get("DB_PASSWORD")};Persist Security Info=True;" +
                   $"User ID={Get("DB_LOGON")};Initial Catalog={Get("DB_ALIAS")};Data Source={Get("DB_SERVER")};" +
                   $"Connect Timeout={Get("DB_TIMEOUT")};";
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? app.Configuration[key] ?? string.Empty;
        }
    }
}
