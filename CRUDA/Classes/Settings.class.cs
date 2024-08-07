using Microsoft.Extensions.FileProviders;
using System.Globalization;

namespace CRUDA_LIB
{
    public static class Settings
    {
        public static readonly string ClassName = "Settings";
        private static readonly WebApplication app;
        static Settings()
        {
            CultureInfo.DefaultThreadCurrentCulture =
                CultureInfo.DefaultThreadCurrentUICulture =
                new CultureInfo("pt-BR");
            app = WebApplication.CreateBuilder().Build();
            app.UseStaticFiles(new StaticFileOptions
            {
                FileProvider = new PhysicalFileProvider(Path.Combine(app.Environment.ContentRootPath, Get("STATIC_FILES_FOLDER"))),
            });
            app.UseRouting();
        }
        public static WebApplication GetApplication()
        {
            return app;
        }
        public static string ConnecionString()
        {
            return $"Password={Get("DB_PASSWORD")};Persist Security Info=True;User ID={Get("DB_LOGON")};Initial Catalog={Get("DB_ALIAS")};Data Source={Get("DB_SERVER")}";
        }
        public static string Get(string key)
        {
            return (Environment.GetEnvironmentVariable(key) ?? app.Configuration[key]) ?? throw new Exception($"Variável de ambiente '{key}' não encontrada.");
        }
    }
}
