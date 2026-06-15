using System.Data; using System.Text; using ExcelDataReader;
Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
var path = args.Length > 0 ? args[0] : @"D:\C#\SGSI_CRUDEX\CRUDEX\StaticFiles\Assets\CRUDEX.xlsm";
await using var stream = File.OpenRead(path);
using var reader = ExcelReaderFactory.CreateReader(stream);
var ds = reader.AsDataSet(new ExcelDataSetConfiguration { ConfigureDataTable = _ => new ExcelDataTableConfiguration { UseHeaderRow = true } });
foreach (var name in new[] { "Comparators", "Rules" })
{
    var tbl = ds.Tables[name]!;
    Console.WriteLine("\n=== " + name + " columns ===");
    foreach (DataColumn c in tbl.Columns) Console.Write(c.ColumnName + "\t");
    Console.WriteLine();
}
var cols = ds.Tables["Columns"]!.AsEnumerable()
    .Where(r => Convert.ToInt64(r["TableId"]) is 21 or 22);
foreach (var r in cols.OrderBy(r => Convert.ToInt64(r["TableId"])).ThenBy(r => Convert.ToInt64(r["Sequence"])))
    Console.WriteLine($"T{r["TableId"]} {r["Name"]} {r["#DataType"]}");
