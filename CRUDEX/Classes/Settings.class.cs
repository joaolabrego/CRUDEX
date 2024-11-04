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
        public static readonly WebApplicationBuilder Builder = WebApplication.CreateBuilder();
        public static readonly WebApplication Application = Builder.Build();
        public static WebApplication Initialize()
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
            CultureInfo.DefaultThreadCurrentCulture = 
                CultureInfo.DefaultThreadCurrentUICulture = 
                new CultureInfo("pt-BR");
            Application.UseRouting();

            return Application;
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
                ["Initial Catalog"] = Get("DB_INITIAL_CATALOG"),
                ["Connect Timeout"] = Get("DB_CONNECTION_TIMEOUT"),
                ["Persist Security Info"] = Get("PERSIST_SECURITY_INFO"),
                ["Integrated Security"] = integratedSecurity ? "SSPI" : null,
                ["User ID"] = integratedSecurity ? null : Get("DB_USER_ID") ?? null,
                ["Password"] = integratedSecurity ? null : Get("DB_PASSWORD") ?? null,
            };

            return result.ToString();
        }
        public static string ConnectionString(string databaseAlias, DataRow connection)
        {
            var integratedSecurity = Convert.ToBoolean(Get("DB_INTEGRATED_SECURITY"));
            var result = new OleDbConnectionStringBuilder
            {
                Provider = ToString(connection["Provider"]),
                DataSource = $"{connection["HostName"]},{connection["Port"]}",
                ["Initial Catalog"] = databaseAlias,
                ["Connect Timeout"] = connection["ConnectionTimeout"],
                ["Persist Security Info"] = connection["PersistSecurityInfo"],
                ["Integrated Security"] = integratedSecurity ? "SSPI" : null,
                ["User ID"] = integratedSecurity ? null : connection["UserID"] ?? null,
                ["Password"] = integratedSecurity ? null : connection["Password"] ?? null,
            };

            return result.ToString();
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? Application.Configuration[key] ?? string.Empty;
        }
    }
}
