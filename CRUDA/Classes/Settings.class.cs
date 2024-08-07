using Microsoft.Extensions.FileProviders;
using NPOI.OpenXmlFormats.Dml;
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
                FileProvider = new PhysicalFileProvider(Path.Combine(builder.Environment.ContentRootPath, "StaticFiles"))
            });
            app.UseRouting();

            return app;
        }
        public static string ConnecionString()
        {
            return $"Password={Get("DB_PASSWORD")};Persist Security Info=True;User ID={Get("DB_LOGON")};Initial Catalog={Get("DB_ALIAS")};Data Source={Get("DB_SERVER")}";
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? app.Configuration[key] ?? string.Empty;
        }
        public static string GetStaticFile(string filename)
        {
            var path = Path.Combine(builder.Environment.ContentRootPath, "StaticFiles");

            return Path.Combine(path, filename);
        }
    }
}
