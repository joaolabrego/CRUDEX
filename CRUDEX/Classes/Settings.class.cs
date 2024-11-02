using Microsoft.Extensions.FileProviders;
using System.Data;
using System.Data.OleDb;
using System.Globalization;
using System.Text;
using Windows.System;

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
        public static bool IsNull(object? value)
        {
            return value == DBNull.Value || value == null;
        }
        public static bool ToBoolean(object? value)
        {
            if (IsNull(value))
                return false;

            return Convert.ToBoolean(Convert.ToUInt16(value));
        }
        public static long ToLong(object? value)
        {
            if (IsNull(value))
                return 0;

            return Convert.ToInt64((value ?? 0).ToString());
        }
        public static double ToDouble(object? value)
        {
            if (IsNull(value))
                return 0.0;

            return Convert.ToDouble(value ?? 0.0);
        }
        public static string ToString(object? value)
        {
            if (IsNull(value))
                return string.Empty;

            return Convert.ToString(value) ?? string.Empty;
        }
        public static string ConnectionString()
        {
            var integratedSecurity = Convert.ToBoolean(Get("DB_INTEGRATED_SECURITY"));
            var result = new OleDbConnectionStringBuilder
            {
                Provider = Get("DB_PROVIDER"),
                DataSource = $"{Get("DB_HOST")},{Get("DB_PORT")}",
                ["Initial Catalog"] = Get("DB_INITIAL_CATALOG") ?? null,
                ["Connect Timeout"] = Get("DB_CONNECT_TIMEOUT") ?? null,
                ["Persist Security Info"] = Get("PERSIST_SECURITY_INFO") ?? null,
                ["Integrated Security"] = integratedSecurity ? "SSPI" : null,
                ["User ID"] = integratedSecurity ? null : Get("DB_USER_ID") ?? null,
                ["Password"] = integratedSecurity ? null : Get("DB_PASSWORD") ?? null,
            };

            return result.ToString();
        }
        public static string ConnectionString(DataRow connection)
        {
            var integratedSecurity = Convert.ToBoolean(Get("DB_INTEGRATED_SECURITY"));
            var result = new OleDbConnectionStringBuilder
            {
                Provider = ToString(connection["Provider"]),
                DataSource = $"{connection["HostName"]},{connection["Port"]}",
                ["Initial Catalog"] = connection["InitialCatalog"] ?? null,
                ["Connect Timeout"] = connection["ConnectionTimeout"] ?? null,
                ["Persist Security Info"] = connection["PersistSecurityInfo"] ?? null,
                ["Integrated Security"] = integratedSecurity ? "SSPI;" : null,
                ["User ID"] = integratedSecurity ? null : connection["UserID"] ?? null,
                ["Password"] = integratedSecurity ? null : connection["Password"] ?? null,
            };

            return result.ToString();
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? app.Configuration[key] ?? string.Empty;
        }
    }
}
