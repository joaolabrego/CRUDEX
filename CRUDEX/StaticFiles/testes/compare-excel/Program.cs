using System.Data; using System.Text; using ExcelDataReader;
Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
var path = @"D:\C#\SGSI_CRUDEX\CRUDEX\StaticFiles\Assets\CRUDEX_Novissimo.xlsm";
await using var stream = File.OpenRead(path);
using var reader = ExcelReaderFactory.CreateReader(stream);
var ds = reader.AsDataSet(new ExcelDataSetConfiguration { ConfigureDataTable = _ => new ExcelDataTableConfiguration { UseHeaderRow = true } });
var cmp = ds.Tables["Cmp"]!;
foreach (DataRow r in cmp.Rows)
    Console.WriteLine($"{r["Id"]} {r["Symbol"]} ({r["Description"]}) Arity={r["Arity"]}");
