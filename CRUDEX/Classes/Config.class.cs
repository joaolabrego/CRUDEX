using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using System.Data;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA_LIB
{
    public class Config
    {
        public readonly string ClassName = "Config";
        public readonly int RowsPerPage = Convert.ToInt32(Settings.Get("ROWS_PER_PAGE"));
        public readonly int IdleTimeInMinutesLimit = Convert.ToInt32(Settings.Get("IDLE_TIME_IN_MINUTES_LIMIT"));
        public readonly bool PaddingGridLastPage = Convert.ToBoolean(Settings.Get("PADDING_GRID_LAST_PAGE"));
        public dynamic? Data;
        public TDictionary? Parameters;
        public Styles? Styles;
        public Images? Images;

        public static async Task<Config> Create(string systemName, string? databaseName = null, string? tableName = null)
        {
            var config = new Config();
            var result = await SQLProcedure.GetConfig(systemName, databaseName, tableName);

            config.Parameters = result.Parameters;
            if (databaseName == null)
                config.Data = new { };
            else if (databaseName == "all")
            {
                config.Data = new
                {
                    System = result.DataSet.Tables[0].Rows[0].Table,
                    Databases = result.DataSet.Tables[1].Rows[0].Table,
                    Tables = result.DataSet.Tables[2].Rows[0].Table,
                    Columns = result.DataSet.Tables[3].Rows[0].Table,
                    Domains = result.DataSet.Tables[4].Rows[0].Table,
                    Types = result.DataSet.Tables[5].Rows[0].Table,
                    Categories = result.DataSet.Tables[6].Rows[0].Table,
                    Menus = result.DataSet.Tables[7].Rows[0].Table,
                    Indexes = result.DataSet.Tables[8].Rows[0].Table,
                    Indexkeys = result.DataSet.Tables[9].Rows[0].Table,
                    Masks = result.DataSet.Tables[10].Rows[0].Table,
                    Associations = result.DataSet.Tables[11].Rows[0].Table,
                    Uniques = result.DataSet.Tables[12].Rows[0].Table,
                };
                config.Styles = new Styles();
                config.Images = new Images(config.Data.System.Rows[0]["ClientName"]);
            }
            else
                config.Data = new
                {
                    System = result.DataSet.Tables[0].Rows[0].Table,
                    Connections = result.DataSet.Tables[1].Rows[0].Table,
                    Databases = result.DataSet.Tables[2].Rows[0].Table,
                    Tables = result.DataSet.Tables[3].Rows[0].Table,
                };

            return config;
        }
        public static string GetHTML(string systemName, string? message = null)
        {
            var favIcon = Images.ReadImageFile($"{Path.Combine(Directory.GetCurrentDirectory(), "Assets/Images", Settings.Get("FAVICON_IMAGE"))}");

            return $"<!DOCTYPE html>" +
                   $"<html lang='pt-br'>\r\n" +
                   $"    <head>\r\n" +
                   $"        <meta charset='utf-8' />\r\n" +
                   $"        <meta http-equiv='X-UA-Compatible' content='IE=edge' />\r\n" +
                   $"        <meta http-equiv='pragma' content='no-cache, no-store' />\r\n" +
                   $"        <meta http-equiv='content-type' content='text/html; X-Content-Type-Options=nosniff;' />\r\n" +
                   $"        <meta name='viewport' content='width=device-width, initial-scale=1.0, user-scalable=no\">' />\r\n" +
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
    }
}