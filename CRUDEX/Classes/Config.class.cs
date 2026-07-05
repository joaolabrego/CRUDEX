using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Net;
using System.Net.Mail;
using System.Reflection;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public class Config
    {
        public readonly string ClassName = "Config";
        public readonly int RowsPerPage = Convert.ToInt32(Settings.Get("ROWS_PER_PAGE"));
        public readonly int RowsPerChildPage = Convert.ToInt32(Settings.Get("ROWS_PER_CHILD_PAGE"));
        public readonly int RowsPerDropdownPage = Convert.ToInt32(Settings.Get("ROWS_PER_DROPDOWN_PAGE"));
        public readonly int IdleTimeInMinutesLimit = Convert.ToInt32(Settings.Get("IDLE_TIME_IN_MINUTES_LIMIT"));
        public readonly bool PaddingGridLastPage = Convert.ToBoolean(Settings.Get("PADDING_BROWSE_LAST_PAGE"));
        public readonly bool ReverseItemsWhenOpenUp = Convert.ToBoolean(Settings.Get("REVERSE_ITEMS_WHEN_OPEN_UP"));
        public string RsaPublicKey { get; private set; } = string.Empty;
        public dynamic? Data;
        public TDictionary? Parameters;
        public Styles? Styles;
        public Images? Images;

        static DataTable ConfigTable(DataSet dataSet, int index) => dataSet.Tables[index];

        public static async Task<Config> Create(string systemName, string? databaseName = null, string? tableName = null)
        {
            var config = new Config();
            var result = await Procedure.GetConfig(systemName, databaseName, tableName);

            config.Parameters = result.Parameters;
            if (databaseName == null)
                config.Data = new { };
            else if (databaseName == "all")
            {
                var dataSet = result.DataSet;
                config.Data = new
                {
                    System = ConfigTable(dataSet, 0),
                    Databases = ConfigTable(dataSet, 1),
                    Tables = ConfigTable(dataSet, 2),
                    Columns = ConfigTable(dataSet, 3),
                    Domains = ConfigTable(dataSet, 4),
                    Types = ConfigTable(dataSet, 5),
                    Categories = ConfigTable(dataSet, 6),
                    Menus = ConfigTable(dataSet, 7),
                    Indexes = ConfigTable(dataSet, 8),
                    Indexkeys = ConfigTable(dataSet, 9),
                    Masks = ConfigTable(dataSet, 10),
                    Unicities = ConfigTable(dataSet, 11),
                    Comparators = ConfigTable(dataSet, 12),
                    Rules = ConfigTable(dataSet, 13),
                    Expressions = ConfigTable(dataSet, 14),
                    Conditions = ConfigTable(dataSet, 15),
                    Properties = ConfigTable(dataSet, 16),
                    Behaviors = ConfigTable(dataSet, 17),
                    References = ConfigTable(dataSet, 18),
                    Referencekeys = ConfigTable(dataSet, 19),
                    Actions = Actions.GetObject(),
                };
                config.Styles = new Styles();
                config.Images = new Images(config.Data.System.Rows[0]["ClientName"]);
            }
            else
            {
                var dataSet = result.DataSet;
                config.Data = new
                {
                    System = ConfigTable(dataSet, 0),
                    Connections = ConfigTable(dataSet, 1),
                    Databases = ConfigTable(dataSet, 2),
                    Tables = ConfigTable(dataSet, 3),
                };
            }

            config.RsaPublicKey = TransportCrypto.ServerPublicKeySpki;

            return config;
        }
        public static async Task SendMailAsync(string recipients, string subject, string body, bool isHtml = true)
        {
            using var smtp = new SmtpClient("smtp.seuservidor.com")
            {
                Port = 587,
                EnableSsl = true,
                Credentials = new NetworkCredential("usuario@dominio.com", "senha")
            };

            var mail = new MailMessage
            {
                From = new MailAddress("crudex@dominio.com", "CRUDEX Notifier"),
                Subject = subject,
                Body = body,
                IsBodyHtml = isHtml
            };
            foreach (var addr in recipients.Split(';'))
                mail.To.Add(addr.Trim());

            await smtp.SendMailAsync(mail);
        }
        public static string GetHTML(string systemName, string? message = null)
        {
            var favIcon = Images.ReadImageFile($"{Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_IMAGES"), Settings.Get("FAVICON_IMAGE"))}");

            return $"<!DOCTYPE html>" +
                   $"<html lang='pt-br'>\r\n" +
                   $"    <head>\r\n" +
                   $"        <meta charset='utf-8' />\r\n" +
                   $"        <meta http-equiv='X-UA-Compatible' content='IE=edge' />\r\n" +
                   $"        <meta http-equiv='pragma' content='no-cache, no-store' />\r\n" +
                   $"        <meta http-equiv='content-type' content='text/html; X-Content-Type-Options=nosniff;' />\r\n" +
                   $"        <meta name='viewport' content='width=device-width, initial-scale=1.0'>\r\n" +
                   $"        <meta name='application-name' content='CRUDEX - CRUD Express' />\r\n" +
                   $"        <meta name='author' content='João da Rocha Labrego' />\r\n" +
                   $"        <meta name='copyright' content='© 2024 Labrego' />\r\n" +
                   $"        <meta name='description' content='Sistema de operações CRUD em tabelas de bancos-de-dados MS-SQL Server' />\r\n" +
                   $"        <link rel='icon' href='{favIcon}' />\r\n" +
                   $"        <title>{systemName.ToUpper()}</title>\r\n" +
                   (message == null ? $"        <script type='module' defer>\r\n" +
                                      $"            import TSystem from './Classes/TSystem.class.mjs'\r\n" +
                                      $"            TSystem.Run({Settings.Get("WITH_BACKGROUND_IMAGE").ToLower()})\r\n" +
                                      $"        </script>\r\n" +
                                      $"    </head>\r\n" +
                                      $"    <body>\r\n" +
                                      $"        <noscript><h1 style='color: red;'>Seu navegador não suporta JavaScript ou o JavaScript está desabilitado.</h1></noscript>\n"
                                    : $"    <body>\r\n" +
                                      $"        <h1 style='color: red;'>{message}</h1>\r\n") +
                   $"    </body>\r\n" +
                   $"</html>";
        }
        public static TDictionary ToDictionary(object json)
        {
            var result = JsonConvert.DeserializeObject<TDictionary>(JsonConvert.SerializeObject(json, Formatting.Indented)) ?? [];

            foreach (var item in result.Where(item => item.Value is JObject))
                result[item.Key] = ToDictionary(item.Value);

            return result;
        }
        public static Dictionary<string, object?> ToJsonObject<T>()
        {
            var obj = new Dictionary<string, object?>();

            var fields = typeof(T).GetFields(
                BindingFlags.Public |
                BindingFlags.Static |
                BindingFlags.FlattenHierarchy
            );

            foreach (var field in fields)
            {
                if (field.IsLiteral && !field.IsInitOnly)
                {
                    obj[field.Name] = field.GetRawConstantValue();
                }
            }

            return obj;
        }
    }
}