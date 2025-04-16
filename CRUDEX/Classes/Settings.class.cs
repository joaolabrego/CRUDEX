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
            return new OleDbConnectionStringBuilder(Get("ConnectionString")).ToString();
        }
        public static string ConnectionString(DataRow connection)
        {
            return new OleDbConnectionStringBuilder(connection["ConnectionString"].ToString()).ToString();
        }
        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key) ?? Application.Configuration[key] ?? string.Empty;
        }
    }
}
