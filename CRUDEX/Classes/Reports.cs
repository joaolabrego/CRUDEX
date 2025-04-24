using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using Newtonsoft.Json.Linq;

namespace CRUDEX.Classes
{
    public class Report() : IDisposable
    {
        private WordprocessingDocument? _document;
        private MainDocumentPart? _mainPart;
        private MemoryStream? _memStream;

        public void Teste()
        {
            // 1) Carrega o JSON
            var jsonText = File.ReadAllText("data.json");
            var json = JObject.Parse(jsonText);

            // 2) Carrega os bytes do template e cria um MemoryStream
            var templateBytes = File.ReadAllBytes("report_template.docx");
            using var templateStream = new MemoryStream(templateBytes);

            // 3) Instancia o Report e carrega o template em memória
            using var report = new Report();
            report.LoadTemplate(templateStream);

            // 4) Substitui os placeholders simples
            report.FillPlaceholders(json);

            // 5) Preenche a tabela “Items”
            report.FillTable(
                "Items",
                json["Items"]!.Children<JObject>(),
                (row, item) =>
                {
                    var cells = row.Elements<TableCell>().ToArray();
                    cells[0].RemoveAllChildren<Text>();
                    cells[0].AppendChild(new Text(item["Description"]!.ToString()));
                    cells[1].RemoveAllChildren<Text>();
                    cells[1].AppendChild(new Text(item["Quantity"]!.ToString()));
                    cells[2].RemoveAllChildren<Text>();
                    cells[2].AppendChild(new Text(item["Price"]!.ToString()));
                }
            );

            // 6) Preenche a tabela “Summary”
            report.FillTable(
                "Summary",
                json["Summary"]!.Children<JObject>(),
                (row, sum) =>
                {
                    var cells = row.Elements<TableCell>().ToArray();
                    cells[0].RemoveAllChildren<Text>();
                    cells[0].AppendChild(new Text(sum["Label"]!.ToString()));
                    cells[1].RemoveAllChildren<Text>();
                    cells[1].AppendChild(new Text(sum["Value"]!.ToString()));
                }
            );

            var fileBytes = report.SaveToBytes();
            File.WriteAllBytes("report_result.docx", fileBytes);
            report.Dispose();

            // Agora grava o _memStream com tudo já fechado
            if (report._memStream != null)
            {
                report._memStream.Position = 0;
                using var outputFile = File.Create("report_result.docx");
                report._memStream.CopyTo(outputFile);
            }
            Console.WriteLine("Relatório gerado em report_result.docx");
        }


        public void LoadTemplate(Stream templateStream)
        {
            _memStream = new MemoryStream();
            templateStream.CopyTo(_memStream);
            _memStream.Position = 0;

            _document = WordprocessingDocument.Open(_memStream, true);
            _mainPart = _document.MainDocumentPart;
        }

        public void FillPlaceholders(JObject json)
        {
            var body = _mainPart?.Document.Body;
            if (body == null) return;

            // Substituições a fazer
            var replacements = json.Properties()
                                   .ToDictionary(p => $"<{p.Name}>", p => p.Value.ToString());

            // Para cada parágrafo do corpo do documento
            foreach (var paragraph in body.Elements<Paragraph>())
            {
                var runs = paragraph.Elements<Run>().ToList();
                if (runs.Count == 0) continue;

                // Concatena todos os textos contidos nos runs
                var fullText = string.Concat(runs.SelectMany(r => r.Elements<Text>()).Select(t => t.Text));

                // Faz as substituições
                foreach (var pair in replacements)
                    fullText = fullText.Replace(pair.Key, pair.Value);

                // Apaga todos os runs originais
                paragraph.RemoveAllChildren<Run>();

                // Cria um único run com o texto final
                var newRun = new Run(new Text(fullText));
                paragraph.AppendChild(newRun);
            }
            // 🔥 ESSENCIAL: Salvar alterações no documento
            _mainPart?.Document.Save();

        }



        public void FillTable<T>(string tableTag,
                                 IEnumerable<T> items,
                                 Action<TableRow, T> mapRow)
        {
            var tbl = _mainPart?.Document?.Body?
                .Descendants<Table>()
                .FirstOrDefault(t =>
                {
                    var cap = t.GetFirstChild<TableProperties>()?
                               .GetFirstChild<TableCaption>()?
                               .Val?.Value;
                    return cap == tableTag;
                });
            if (tbl == null) return;

            var rows = tbl.Elements<TableRow>().ToList();
            if (rows.Count < 2) return;
            var templateRow = (TableRow)rows[1].CloneNode(true);

            // Remove linhas antigas (exceto cabeçalho)
            foreach (var r in rows.Skip(1).ToArray())
                tbl.RemoveChild(r);

            // Adiciona as novas linhas
            foreach (var item in items)
            {
                var newRow = (TableRow)templateRow.CloneNode(true);
                mapRow(newRow, item);
                tbl.AppendChild(newRow);
            }
        }

        public byte[] SaveToBytes()
        {
            _mainPart?.Document.Save();
            _document?.Dispose();
            return _memStream!.ToArray();
        }
        public Stream? SaveToStream()
        {
            // Garante que as alterações sejam salvas
            _mainPart?.Document.Save();

            // Reposiciona o stream original sem fechá-lo
            _memStream?.Flush();
            _memStream!.Position = 0;

            // ⚠️ NÃO DISPONIBILIZE OUTRO STREAM: use este até o final
            return _memStream;
        }


        public void Dispose()
        {
            _document?.Dispose();
            _memStream?.Dispose();
        }
    }
}
