using Microsoft.Data.SqlClient;
using System.Data;
using System.Globalization;
using System.Text;

namespace CRUDEX.Classes
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
        /*
            try
            {
                DbProviderFactory factory = DbProviderFactories.GetFactory(providerName);
                using DbConnection conn = factory.CreateConnection();
                conn.ConnectionString = connectionString;
                conn.Open();
                if (!conn.Database.Equals(expectedDb, StringComparison.OrdinalIgnoreCase))
                    throw new Exception($"Conectado a '{conn.Database}', mas esperado '{expectedDb}'.");
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao abrir conexão para o engine '{providerName}': {ex.Message}");
            }         
         */
        public static string ConnectionString()
        {
            return new SqlConnectionStringBuilder(Get("ConnectionString")).ToString();
        }
        public static string ConnectionString(DataRow connection)
        {
            return new SqlConnectionStringBuilder(connection["ConnectionString"].ToString()).ToString();
        }
        public static string GetEnvironment()
        {
            var environment = Environment.GetEnvironmentVariable("CRUDEX_ENVIRONMENT")?.Trim().ToLowerInvariant();

            if (environment != null && (environment == "hml" || environment == "prd"))
                return environment;

            return "dev";
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? Application.Configuration[key] ?? string.Empty;
        }
    }
}
