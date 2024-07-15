using NPOI.Util;
using System.Data;
using System.Data.OleDb;
using Dictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDA.Classes
{
    public static class ORM
    {
        //public static void Config()
        public static object GetDataTable(string connectionString, string tableName, Dictionary? filters = null, 
            string? orders = null, int startRecord = 0, int maxRecords = 0)
        {
            using var command = new OleDbCommand()
            {
                Connection = new OleDbConnection(connectionString),
                CommandType = CommandType.Text,
                CommandText = $"SELECT * FROM {tableName}",
                CommandTimeout = 60,
            };

            command.Connection.Open();
            if (filters != null)
            {
                var and = string.Empty;

                command.CommandText += " WHERE ";
                foreach (var item in filters)
                {
                    if (item.Value != null)
                    {
                        command.Parameters.Add(new OleDbParameter(item.Key, item.Value));
                        command.CommandText += $"{and} {item.Key} = ?";
                        and = " AND ";
                    }
                }
            }
            if (orders != null)
                command.CommandText += $" ORDER {orders}";

            var dataAdapter = new OleDbDataAdapter(command);
            var datatable = new DataTable();

            dataAdapter.Fill(datatable);
            command.Connection.Close();

            if (maxRecords < 0)
                maxRecords = 0;
            if (startRecord < 0)
               startRecord = datatable.Rows.Count + startRecord;

            return new
            {
                Table = startRecord > 0 || maxRecords > 0 
                            ? datatable.AsEnumerable()
                                .Skip(startRecord < 0 ? datatable.Rows.Count + startRecord : startRecord)
                                .Take(maxRecords > 0 ? maxRecords : datatable.Rows.Count)
                                .CopyToDataTable() 
                            : datatable,
                RecordCount = datatable.Rows.Count
            };
        }
    }
}
