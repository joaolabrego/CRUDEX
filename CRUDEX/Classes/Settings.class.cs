using Microsoft.Extensions.FileProviders;
using System.Globalization;
using System.Text;

namespace CRUDA_LIB
{
    public static class Settings
    {
        public static readonly string ClassName = "Settings";
        private static readonly WebApplicationBuilder builder = WebApplication.CreateBuilder();
        private static readonly WebApplication app = builder.Build();
        public static WebApplication Initialize()
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
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
            return $"Provider=SQLOLEDB;Data Source={Get("DB_SERVER")};Initial Catalog={Get("DB_ALIAS")};User ID={Get("DB_LOGON")};Password={Get("DB_PASSWORD")};";
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? app.Configuration[key] ?? string.Empty;
        }
    }
}
