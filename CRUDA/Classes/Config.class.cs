using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using System.Data;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public class Config
    {
        public readonly string ClassName = "Config";
        public readonly int RowsPerPage = Convert.ToInt32(Settings.Get("ROWS_PER_PAGE"));
        public readonly int IdleTimeInMinutesLimit = Convert.ToInt32(Settings.Get("IDLE_TIME_IN_MINUTES_LIMIT"));
        public readonly bool PaddingGridLastPage = Convert.ToBoolean(Settings.Get("PADDING_GRID_LAST_PAGE"));
        public readonly dynamic Data;
        public readonly Dictionary? Parameters;
        public readonly Styles? Styles;
        public readonly Images? Images;

        public Config(string systemName, string? databaseName = null, string? tableName = null)
        {
            var result = SQLProcedure.GetConfig(systemName, databaseName, tableName);

            Parameters = result.Parameters;
            if (databaseName == null)
                Data = new { };
            else if (databaseName == "all")
            {
                Data = new
                {
                    System = result.Tables[0].Rows[0].Table,
                    Databases = result.Tables[1].Rows[0].Table,
                    Tables = result.Tables[2].Rows[0].Table,
                    Columns = result.Tables[3].Rows[0].Table,
                    Domains = result.Tables[4].Rows[0].Table,
                    Types = result.Tables[5].Rows[0].Table,
                    Categories = result.Tables[6].Rows[0].Table,
                    Menus = result.Tables[7].Rows[0].Table,
                    Indexes = result.Tables[8].Rows[0].Table,
                    Indexkeys = result.Tables[9].Rows[0].Table,
                    Masks = result.Tables[10].Rows[0].Table,
                };
                Styles = new Styles();
                Images = new Images();
            }
            else
                Data = new
                {
                    System = result.Tables[0].Rows[0].Table,
                    Databases = result.Tables[1].Rows[0].Table,
                    Tables = result.Tables[2].Rows[0].Table,
                };
        }
        override public string ToString()
        {
            return JsonConvert.SerializeObject(this, Formatting.Indented);
        }
        public static Dictionary GetParameters(HttpRequest request, dynamic body)
        {
            return ToDictionary(new
            {
                Login = JsonConvert.DeserializeObject(request.Headers["Login"].ToString()),
                Parameters = JsonConvert.DeserializeObject(body.ToString()),
            });
        }
        private static string GetHeaderHTML(string systemName)
        {
            var favIcon = Images.ReadImageFile($"{Path.Combine(Directory.GetCurrentDirectory(), "Assets/Images", Settings.Get("FAVICON_IMAGE"))}");

            return $"<!DOCTYPE html>\n" +
                   $"<html lang='pt-br'>\n" +
                   $"    <head>\n" +
                   $"        <meta charset='utf-8' />\n" +
                   $"        <meta http-equiv='X-UA-Compatible' content='IE=edge' />\n" +
                   $"        <meta http-equiv='pragma' content='no-cache, no-store' />\n" +
                   $"        <meta http-equiv='content-type' content='text/html; X-Content-Type-Options=nosniff;' />\n" +
                   $"        <meta name='viewport' content='width=device-width, initial-scale=1.0' />\n" +
                   $"        <meta name='application-name' content='CRUDA - CRUD Automático' />\n" +
                   $"        <meta name='author' content='João da Rocha Labrego' />\n" +
                   $"        <meta name='copyright' content='© 2024 Labrego' />\n" +
                   $"        <meta name='description' content='Sistema de operações CRUD em tabelas de bancos-de-dados MS-SQL Server' />\n" +
                   $"        <link rel='icon' href='{favIcon}' />\n" +
                   $"        <title>{systemName.ToUpper()}</title>\n"; 
        }
        public string GetHTML(string systemName)
        {
            return GetHeaderHTML(systemName) +
                   $"        <script type='module' defer>\n" +
                   $"            import TSystem from './Classes/TSystem.class.mjs'\n" +
                   $"            TSystem.Run({Settings.Get("WITH_BACKGROUND_IMAGE").ToLower()})\n" +
                   $"        </script>\n" +
                   $"    </head>\n" +
                   $"    <body>\n" +
                   $"        <noscript><h1 style='color: red;'>Seu navegador não suporta JavaScript ou o JavaScript está desabilitado.</h1></noscript>\n" +
                   GetFooterHTML();
        }
        public static string GetHTML(string systemName, string message)
        {
            return GetHeaderHTML(systemName) +
                   $"    <body>\n" +
                   $"        <h1 style='color: red;'>{message}</h1>\n" +
                   GetFooterHTML();
        }
        private static string GetFooterHTML()
        {
            return $"    </body>\n" +
                   $"</html>";
        }
        public static string Serialize(dynamic json)
        {
            return JsonConvert.SerializeObject(json, Formatting.Indented);
        }
        public static object Deserialize(dynamic json)
        {
            return JsonConvert.DeserializeObject(json.ToString());
        }
        public static Dictionary ToDictionary(object json)
        {
            var result = JsonConvert.DeserializeObject<Dictionary>(Serialize(json)) ?? [];

            foreach (var item in result.Where(item => item.Value is JObject))
                result[item.Key] = ToDictionary(item.Value);

            return result;
        }
    }
}
