using System.Diagnostics;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Drawing.Wordprocessing;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using Newtonsoft.Json.Linq;
using Paragraph = DocumentFormat.OpenXml.Wordprocessing.Paragraph;
using Run = DocumentFormat.OpenXml.Wordprocessing.Run;
using Table = DocumentFormat.OpenXml.Wordprocessing.Table;
using TableCell = DocumentFormat.OpenXml.Wordprocessing.TableCell;
using Text = DocumentFormat.OpenXml.Wordprocessing.Text;

namespace CRUDEX.Classes
{
    public class Report : IDisposable
    {
        private readonly MemoryStream memoryStream;
        private readonly WordprocessingDocument wordDoc;

        public Report(string templatePath)
        {
            var fileBytes = File.ReadAllBytes(templatePath);

            memoryStream = new MemoryStream();
            memoryStream.Write(fileBytes, 0, fileBytes.Length);
            memoryStream.Position = 0;
            wordDoc = WordprocessingDocument.Open(memoryStream, true);
        }

        public static void Teste()
        {
            using var report = new Report("./StaticFiles/testes/report_template.docx");
            report.Generate("./StaticFiles/testes/data.json", "./StaticFiles/testes/report_result.docx");

            string docxPath = @"D:\CRUDEX-C#\SGSI_CRUDEX\CRUDEX\StaticFiles\testes\report_result.docx";
            string outputFolder = Path.GetDirectoryName(docxPath)!;

            // Salva o PDF na mesma pasta
            report.SaveAsPdf(docxPath, outputFolder);
        }

        public void Generate(string jsonPath, string outputPath)
        {
            var json = JObject.Parse(File.ReadAllText(jsonPath));
            var main = wordDoc.MainDocumentPart!;
            var body = main.Document.Body;
            if (body == null) return;

            // ===== TAGS NO CORPO + CABEÇALHOS + RODAPÉS =====
            ReplaceTagsPreciselyPreservingFormatting(body, json);

            foreach (var hp in main.HeaderParts)
                ReplaceTagsPreciselyPreservingFormatting(hp.Header, json);

            foreach (var fp in main.FooterParts)
                ReplaceTagsPreciselyPreservingFormatting(fp.Footer, json);

            // ===== IMAGEM POR "NOME" (mantido como estava no seu código) =====
            this.ReplaceImageByNameInBody("EvadinLogo", File.ReadAllBytes("./StaticFiles/testes/logo.jpg"));
            this.ReplaceImageByNameInHeaders("EvadinLogo", File.ReadAllBytes("./StaticFiles/testes/logo.jpg"));
            this.ReplaceImageByNameInFooters("EvadinLogo", File.ReadAllBytes("./StaticFiles/testes/logo.jpg"));

            // ===== TABELAS (ficam no Body mesmo) =====

            FillTableHeader("Items", json["Items"]!.Children<JObject>(), (row, item) =>
            {
                var cells = row.Elements<TableCell>().ToArray();
                SetCellText(cells[0], item["Description"]!.ToString());
                SetCellText(cells[1], item["Quantity"]!.ToString());
                SetCellText(cells[2], item["Price"]!.ToString());
            });

            FillTableBody("Items", json["Items"]!.Children<JObject>(), (row, item) =>
            {
                var cells = row.Elements<TableCell>().ToArray();
                SetCellText(cells[0], item["Description"]!.ToString());
                SetCellText(cells[1], item["Quantity"]!.ToString());
                SetCellText(cells[2], item["Price"]!.ToString());
            });

            FillTableBody("Summary", json["Summary"]!.Children<JObject>(), (row, item) =>
            {
                var cells = row.Elements<TableCell>().ToArray();
                SetCellText(cells[0], item["Label"]!.ToString());
                SetCellText(cells[1], item["Value"]!.ToString());
            });

            FillTableFooter("Summary", json["Summary"]!.Children<JObject>(), (row, item) =>
            {
                var cells = row.Elements<TableCell>().ToArray();
                SetCellText(cells[0], item["Label"]!.ToString());
                SetCellText(cells[1], item["Value"]!.ToString());
            });

            main.Document.Save();
            wordDoc.Dispose();
            File.WriteAllBytes(outputPath, memoryStream.ToArray());
        }

        // Agora recebe qualquer raiz (Body, Header, Footer) e percorre Descendants<Paragraph>()
        private static void ReplaceTagsPreciselyPreservingFormatting(OpenXmlElement root, JObject json)
        {
            var replacements = json.Properties().ToDictionary(p => $"<{p.Name}>", p => p.Value.ToString());

            foreach (var paragraph in root.Descendants<Paragraph>())
            {
                var runs = paragraph.Elements<Run>().ToList();
                if (runs.Count == 0) continue;

                var segments = runs.Select(r => (run: r, text: r.GetFirstChild<Text>()?.Text ?? "")).ToList();
                string fullText = string.Concat(segments.Select(s => s.text));

                foreach (var replacement in replacements)
                {
                    string tag = replacement.Key;
                    string value = replacement.Value;
                    int globalPos = 0;

                    while ((globalPos = fullText.IndexOf(tag, globalPos, StringComparison.Ordinal)) != -1)
                    {
                        int tagEnd = globalPos + tag.Length;

                        int startRun = -1, endRun = -1;
                        int currentPos = 0;

                        for (int i = 0; i < segments.Count; i++)
                        {
                            int len = segments[i].text.Length;

                            if (startRun == -1 && globalPos < currentPos + len)
                                startRun = i;

                            if (tagEnd <= currentPos + len)
                            {
                                endRun = i;
                                break;
                            }

                            currentPos += len;
                        }

                        if (startRun == -1 || endRun == -1) break;

                        var firstRun = segments[startRun].run;
                        var firstText = segments[startRun].text;

                        int tagOffsetStart = globalPos - segments.Take(startRun).Sum(s => s.text.Length);
                        if (tagOffsetStart > 0)
                        {
                            var preservedText = firstText.Substring(0, tagOffsetStart);
                            var runBefore = new Run(new Text(preservedText));
                            if (firstRun.RunProperties != null)
                                runBefore.RunProperties = (RunProperties)firstRun.RunProperties.CloneNode(true);
                            paragraph.InsertBefore(runBefore, firstRun);
                        }

                        var lastRun = segments[endRun].run;
                        var lastText = segments[endRun].text;

                        int tagOffsetEnd = tagEnd - segments.Take(endRun).Sum(s => s.text.Length);
                        if (tagOffsetEnd < lastText.Length)
                        {
                            var preservedText = lastText[tagOffsetEnd..];
                            var runAfter = new Run(new Text(preservedText));
                            if (lastRun.RunProperties != null)
                                runAfter.RunProperties = (RunProperties)lastRun.RunProperties.CloneNode(true);
                            paragraph.InsertAfter(runAfter, lastRun);
                        }

                        for (int i = startRun; i <= endRun; i++)
                            paragraph.RemoveChild(segments[i].run);

                        var newRun = new Run(new Text(value));
                        if (firstRun.RunProperties != null)
                            newRun.RunProperties = (RunProperties)firstRun.RunProperties.CloneNode(true);

                        // Coloca o valor no final do parágrafo (mantendo seu comportamento original)
                        paragraph.AppendChild(newRun);

                        runs = paragraph.Elements<Run>().ToList();
                        segments = runs.Select(r => (r, r.GetFirstChild<Text>()?.Text ?? "")).ToList();
                        fullText = string.Concat(segments.Select(s => s.text));
                        globalPos = 0;
                    }
                }
            }
        }

        // =======================
        // 1) BODY
        // =======================
        private void FillTableBody<T>(string tableTag, IEnumerable<T> items, Action<TableRow, T> mapRow)
        {
            var main = wordDoc.MainDocumentPart;
            if (main?.Document?.Body == null) return;

            var tbl = main.Document.Body
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
            if (rows.Count < 2) return; // precisa de pelo menos 1 linha template (ex: row[1])

            var templateRow = (TableRow)rows[1].CloneNode(true);

            foreach (var r in rows.Skip(1).ToArray())
                tbl.RemoveChild(r);

            foreach (var item in items)
            {
                var newRow = (TableRow)templateRow.CloneNode(true);
                mapRow(newRow, item);
                tbl.AppendChild(newRow);
            }
        }

        // =======================
        // 2) HEADER (em TODOS os headers)
        // =======================
        private void FillTableHeader<T>(string tableTag, IEnumerable<T> items, Action<TableRow, T> mapRow)
        {
            var main = wordDoc.MainDocumentPart;
            if (main == null) return;

            foreach (var hp in main.HeaderParts)
            {
                var header = hp.Header;
                if (header == null) continue;

                var tbl = header
                    .Descendants<Table>()
                    .FirstOrDefault(t =>
                    {
                        var cap = t.GetFirstChild<TableProperties>()?
                                   .GetFirstChild<TableCaption>()?
                                   .Val?.Value;
                        return cap == tableTag;
                    });

                if (tbl == null) continue;

                var rows = tbl.Elements<TableRow>().ToList();
                if (rows.Count < 2) continue;

                var templateRow = (TableRow)rows[1].CloneNode(true);

                foreach (var r in rows.Skip(1).ToArray())
                    tbl.RemoveChild(r);

                foreach (var item in items)
                {
                    var newRow = (TableRow)templateRow.CloneNode(true);
                    mapRow(newRow, item);
                    tbl.AppendChild(newRow);
                }
            }
        }

        // =======================
        // 3) FOOTER (em TODOS os footers)
        // =======================
        private void FillTableFooter<T>(string tableTag, IEnumerable<T> items, Action<TableRow, T> mapRow)
        {
            var main = wordDoc.MainDocumentPart;
            if (main == null) return;

            foreach (var fp in main.FooterParts)
            {
                var footer = fp.Footer;
                if (footer == null) continue;

                var tbl = footer
                    .Descendants<Table>()
                    .FirstOrDefault(t =>
                    {
                        var cap = t.GetFirstChild<TableProperties>()?
                                   .GetFirstChild<TableCaption>()?
                                   .Val?.Value;
                        return cap == tableTag;
                    });

                if (tbl == null) continue;

                var rows = tbl.Elements<TableRow>().ToList();
                if (rows.Count < 2) continue;

                var templateRow = (TableRow)rows[1].CloneNode(true);

                foreach (var r in rows.Skip(1).ToArray())
                    tbl.RemoveChild(r);

                foreach (var item in items)
                {
                    var newRow = (TableRow)templateRow.CloneNode(true);
                    mapRow(newRow, item);
                    tbl.AppendChild(newRow);
                }
            }
        }

        private static void SetCellText(TableCell cell, string value)
        {
            var originalPara = cell.Elements<Paragraph>().FirstOrDefault();
            ParagraphProperties? originalParaProps = null;
            RunProperties? originalRunProps = null;

            if (originalPara != null)
            {
                originalParaProps = originalPara.ParagraphProperties != null
                    ? (ParagraphProperties)originalPara.ParagraphProperties.CloneNode(true)
                    : null;

                originalRunProps = originalPara.Descendants<Run>().FirstOrDefault()?.RunProperties != null
                    ? originalPara.Descendants<Run>().First().RunProperties?.CloneNode(true) as RunProperties
                    : null;
            }

            var newRun = new Run(new Text(value));
            if (originalRunProps != null)
                newRun.RunProperties = originalRunProps;

            var newPara = new Paragraph(newRun);
            if (originalParaProps != null)
                newPara.ParagraphProperties = originalParaProps;

            cell.RemoveAllChildren<Paragraph>();
            cell.AppendChild(newPara);
        }

        // BODY (MainDocumentPart)
        public void ReplaceImageByNameInBody(string imageNameToReplace, byte[] newImageBytes)
        {
            var mainPart = wordDoc.MainDocumentPart!;

            var drawing = mainPart.Document.Body?
                .Descendants<Drawing>()
                .FirstOrDefault(d =>
                    d.Inline?.DocProperties?.Description?.Value == imageNameToReplace)
                ?? throw new Exception($"Imagem '{imageNameToReplace}' não encontrada no BODY.");

            var blip = drawing.Descendants<DocumentFormat.OpenXml.Drawing.Blip>().FirstOrDefault()
                ?? throw new Exception("Drawing sem Blip.");

            var oldRelId = blip.Embed?.Value ?? throw new Exception("Blip sem Embed.");

            var oldPart = mainPart.GetPartById(oldRelId);
            mainPart.DeletePart(oldPart);

            var newImagePart = mainPart.AddImagePart(ImagePartType.Png);
            using (var ms = new MemoryStream(newImageBytes))
                newImagePart.FeedData(ms);

            blip.Embed!.Value = mainPart.GetIdOfPart(newImagePart);
        }


        // HEADER (HeaderPart) - substitui em TODOS os headers do doc
        public void ReplaceImageByNameInHeaders(string imageNameToReplace, byte[] newImageBytes)
        {
            var mainPart = wordDoc.MainDocumentPart!;

            foreach (var headerPart in mainPart.HeaderParts)
            {
                var drawing = headerPart.Header?
                    .Descendants<Drawing>()
                    .FirstOrDefault(d =>
                        d.Inline?.DocProperties?.Description?.Value == imageNameToReplace);

                if (drawing == null) continue;

                var blip = drawing.Descendants<DocumentFormat.OpenXml.Drawing.Blip>().FirstOrDefault()
                    ?? throw new Exception("Drawing sem Blip.");

                var oldRelId = blip.Embed?.Value ?? throw new Exception("Blip sem Embed.");

                var oldPart = headerPart.GetPartById(oldRelId);
                headerPart.DeletePart(oldPart);

                var newImagePart = headerPart.AddImagePart(ImagePartType.Png);
                using (var ms = new MemoryStream(newImageBytes))
                    newImagePart.FeedData(ms);

                blip.Embed!.Value = headerPart.GetIdOfPart(newImagePart);
                return; // achou e substituiu em algum header
            }

            throw new Exception($"Imagem '{imageNameToReplace}' não encontrada em nenhum HEADER.");
        }


        // FOOTER (FooterPart) - substitui em TODOS os footers do doc
        public void ReplaceImageByNameInFooters(string imageNameToReplace, byte[] newImageBytes)
        {
            var mainPart = wordDoc.MainDocumentPart!;

            foreach (var footerPart in mainPart.FooterParts)
            {
                var drawing = footerPart.Footer?
                    .Descendants<Drawing>()
                    .FirstOrDefault(d =>
                        d.Inline?.DocProperties?.Description?.Value == imageNameToReplace);

                if (drawing == null) continue;

                var blip = drawing.Descendants<DocumentFormat.OpenXml.Drawing.Blip>().FirstOrDefault()
                    ?? throw new Exception("Drawing sem Blip.");

                var oldRelId = blip.Embed?.Value ?? throw new Exception("Blip sem Embed.");

                var oldPart = footerPart.GetPartById(oldRelId);
                footerPart.DeletePart(oldPart);

                var newImagePart = footerPart.AddImagePart(ImagePartType.Png);
                using (var ms = new MemoryStream(newImageBytes))
                    newImagePart.FeedData(ms);

                blip.Embed!.Value = footerPart.GetIdOfPart(newImagePart);
                return; // achou e substituiu em algum footer
            }

            throw new Exception($"Imagem '{imageNameToReplace}' não encontrada em nenhum FOOTER.");
        }

        public void SaveAsPdf(string docxPath, string outputFolder)
        {
            var command = Settings.Get("LIBRE_OFFICE_COMMAND");
            var arguments = Settings.Get("LIBRE_OFFICE_ARGUMENTS");

            var startInfo = new ProcessStartInfo
            {
                FileName = command,
                Arguments = string.Format(arguments, docxPath, outputFolder),
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using var process = new Process { StartInfo = startInfo };
            process.Start();

            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();

            process.WaitForExit();

            if (process.ExitCode != 0)
                throw new Exception($"Erro ao converter para PDF:\n{error}");
        }

        public void Dispose()
        {
            wordDoc?.Dispose();
            memoryStream?.Dispose();
            GC.SuppressFinalize(this);
        }
    }
}
