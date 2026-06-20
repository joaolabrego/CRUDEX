using Microsoft.Data.SqlClient;
using System.Data;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CRUDEX.Classes
{
    public static class Settings
    {
        public const string DataEncryptionKeyName = "DATA_ENCRYPTION_KEY";
        public const string RsaPrivateKeyName = "RSA_PRIVATE_KEY";
        public const string RsaPublicKeyName = "RSA_PUBLIC_KEY";
        public static readonly string ClassName = "Settings";
        public static readonly WebApplicationBuilder Builder = WebApplication.CreateBuilder();
        public static readonly WebApplication Application = Builder.Build();
        static string? _dataEncryptionKey;
        static string? _rsaPrivateKey;
        static string? _rsaPublicKey;

        public static WebApplication Initialize()
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
            CultureInfo.DefaultThreadCurrentCulture = 
                CultureInfo.DefaultThreadCurrentUICulture = 
                new CultureInfo("pt-BR");
            EnsureDataEncryptionKey();
            EnsureRsaKeyPair();
            Application.UseRouting();

            return Application;
        }

        static bool IsValidDataEncryptionKey(string? base64)
        {
            if (string.IsNullOrWhiteSpace(base64))
                return false;
            try
            {
                return Convert.FromBase64String(base64).Length == 32;
            }
            catch
            {
                return false;
            }
        }

        static void EnsureDataEncryptionKey()
        {
            if (!string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(DataEncryptionKeyName)))
                return;

            var configured = Application.Configuration[DataEncryptionKeyName];
            if (IsValidDataEncryptionKey(configured))
            {
                _dataEncryptionKey = configured;
                return;
            }

            _dataEncryptionKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
            var path = Path.Combine(Builder.Environment.ContentRootPath, "appsettings.json");
            if (!File.Exists(path))
                throw new Exception($"Arquivo {path} não encontrado para gravar {DataEncryptionKeyName}.");

            var json = JObject.Parse(File.ReadAllText(path));
            json[DataEncryptionKeyName] = _dataEncryptionKey;
            File.WriteAllText(path, json.ToString(Formatting.Indented) + Environment.NewLine);
        }

        static bool IsValidRsaPrivateKey(string? base64)
        {
            if (string.IsNullOrWhiteSpace(base64))
                return false;
            try
            {
                using var rsa = RSA.Create();
                rsa.ImportPkcs8PrivateKey(Convert.FromBase64String(base64), out _);
                return true;
            }
            catch
            {
                return false;
            }
        }

        static void EnsureRsaKeyPair()
        {
            if (!string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(RsaPrivateKeyName)))
                return;

            var configuredPrivate = Application.Configuration[RsaPrivateKeyName];
            var configuredPublic = Application.Configuration[RsaPublicKeyName];
            if (IsValidRsaPrivateKey(configuredPrivate))
            {
                _rsaPrivateKey = configuredPrivate;
                _rsaPublicKey = configuredPublic;
                return;
            }

            using var rsa = RSA.Create(2048);
            _rsaPrivateKey = Convert.ToBase64String(rsa.ExportPkcs8PrivateKey());
            _rsaPublicKey = Convert.ToBase64String(rsa.ExportSubjectPublicKeyInfo());

            var path = Path.Combine(Builder.Environment.ContentRootPath, "appsettings.json");
            if (!File.Exists(path))
                throw new Exception($"Arquivo {path} não encontrado para gravar {RsaPrivateKeyName}.");

            var json = JObject.Parse(File.ReadAllText(path));
            json[RsaPrivateKeyName] = _rsaPrivateKey;
            json[RsaPublicKeyName] = _rsaPublicKey;
            File.WriteAllText(path, json.ToString(Formatting.Indented) + Environment.NewLine);
        }

        public static bool IsNull(object? value)
        {
            return value == DBNull.Value || value == null || value.ToString() == "";
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

            if (environment == "hml" || environment == "prd")
                return environment;

            return "dev";
        }
        public static string Get(string key)
        {
            if (key == DataEncryptionKeyName && !string.IsNullOrEmpty(_dataEncryptionKey))
                return _dataEncryptionKey;
            if (key == RsaPrivateKeyName && !string.IsNullOrEmpty(_rsaPrivateKey))
                return _rsaPrivateKey;
            if (key == RsaPublicKeyName && !string.IsNullOrEmpty(_rsaPublicKey))
                return _rsaPublicKey;
            return Environment.GetEnvironmentVariable(key) ?? Application.Configuration[key] ?? string.Empty;
        }
    }
}
