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

            string docxPath = @"D:\CRUDEX-C#\SGSI_CRUDEX\CRUDEX\StaticFilestestes\report_result.docx";
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

            // ===== IMAGEM POR PLACEHOLDER: CORPO + CABEÇALHOS + RODAPÉS =====
            InsertImageInlineFromBytes(wordDoc, "<Logo>", File.ReadAllBytes("./StaticFiles/testes/logo.png"), "Labrego");

            // ===== IMAGEM POR "NOME" (mantido como estava no seu código) =====
            this.ReplaceImageByName("EvadinLogo", File.ReadAllBytes("./StaticFiles/testes/logo.png"));

            // ===== TABELAS (ficam no Body mesmo) =====
            FillTable("Items", json["Items"]!.Children<JObject>(), (row, item) =>
            {
                var cells = row.Elements<TableCell>().ToArray();
                SetCellText(cells[0], item["Description"]!.ToString());
                SetCellText(cells[1], item["Quantity"]!.ToString());
                SetCellText(cells[2], item["Price"]!.ToString());
            });

            FillTable("Summary", json["Summary"]!.Children<JObject>(), (row, item) =>
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

        private void FillTable<T>(string tableTag, IEnumerable<T> items, Action<TableRow, T> mapRow)
        {
            var tbl = wordDoc?.MainDocumentPart?.Document?.Body?
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

            foreach (var r in rows.Skip(1).ToArray())
                tbl.RemoveChild(r);

            foreach (var item in items)
            {
                var newRow = (TableRow)templateRow.CloneNode(true);
                mapRow(newRow, item);
                tbl.AppendChild(newRow);
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

        // Substitui placeholder <Logo> por uma imagem, agora varrendo Body + Headers + Footers
        public static void InsertImageInlineFromBytes(WordprocessingDocument doc, string placeholder, byte[] imageBytes, string imageName)
        {
            var mainPart = doc.MainDocumentPart!;
            var imagePart = mainPart.AddImagePart(ImagePartType.Png);

            using (var imageStream = new MemoryStream(imageBytes))
                imagePart.FeedData(imageStream);

            var imageId = mainPart.GetIdOfPart(imagePart);

            using var imgStream = new MemoryStream(imageBytes);
            using var image = System.Drawing.Image.FromStream(imgStream);

            const int emusPerInch = 914400;
            const int defaultDpi = 96;

            long widthEmu = image.Width * emusPerInch / defaultDpi;
            long heightEmu = image.Height * emusPerInch / defaultDpi;

            var drawing = new Drawing(
                new Inline(
                    new Extent { Cx = widthEmu, Cy = heightEmu },
                    new EffectExtent
                    {
                        LeftEdge = 0L,
                        TopEdge = 0L,
                        RightEdge = 0L,
                        BottomEdge = 0L
                    },
                    new DocProperties
                    {
                        Id = (UInt32Value)1U,
                        Name = imageName
                    },
                    new NonVisualGraphicFrameDrawingProperties(
                        new DocumentFormat.OpenXml.Drawing.GraphicFrameLocks { NoChangeAspect = true }
                    ),
                    new DocumentFormat.OpenXml.Drawing.Graphic(
                        new DocumentFormat.OpenXml.Drawing.GraphicData(
                            new DocumentFormat.OpenXml.Drawing.Pictures.Picture(
                                new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureProperties(
                                    new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualDrawingProperties
                                    {
                                        Id = (UInt32Value)0U,
                                        Name = imageName
                                    },
                                    new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureDrawingProperties()
                                ),
                                new DocumentFormat.OpenXml.Drawing.Pictures.BlipFill(
                                    new DocumentFormat.OpenXml.Drawing.Blip
                                    {
                                        Embed = imageId,
                                        CompressionState = DocumentFormat.OpenXml.Drawing.BlipCompressionValues.Print
                                    },
                                    new DocumentFormat.OpenXml.Drawing.Stretch(
                                        new DocumentFormat.OpenXml.Drawing.FillRectangle())
                                ),
                                new DocumentFormat.OpenXml.Drawing.Pictures.ShapeProperties(
                                    new DocumentFormat.OpenXml.Drawing.Transform2D(
                                        new DocumentFormat.OpenXml.Drawing.Offset { X = 0L, Y = 0L },
                                        new DocumentFormat.OpenXml.Drawing.Extents { Cx = widthEmu, Cy = heightEmu }
                                    ),
                                    new DocumentFormat.OpenXml.Drawing.PresetGeometry(
                                        new DocumentFormat.OpenXml.Drawing.AdjustValueList()
                                    )
                                    { Preset = DocumentFormat.OpenXml.Drawing.ShapeTypeValues.Rectangle }
                                )
                            )
                        )
                        { Uri = "http://schemas.openxmlformats.org/drawingml/2006/picture" }
                    )
                )
            );

            bool replaced = ReplacePlaceholderWithDrawing(mainPart.Document.Body!, placeholder, drawing);

            foreach (var hp in mainPart.HeaderParts)
                replaced = ReplacePlaceholderWithDrawing(hp.Header, placeholder, drawing) || replaced;

            foreach (var fp in mainPart.FooterParts)
                replaced = ReplacePlaceholderWithDrawing(fp.Footer, placeholder, drawing) || replaced;

            if (!replaced)
                throw new Exception($"Placeholder '{placeholder}' não encontrado no corpo/cabeçalho/rodapé.");
        }

        // Procura placeholder mesmo quando o texto está quebrado em runs e substitui por Drawing preservando antes/depois
        private static bool ReplacePlaceholderWithDrawing(OpenXmlElement root, string placeholder, Drawing drawing)
        {
            foreach (var para in root.Descendants<Paragraph>())
            {
                var runs = para.Elements<Run>().ToList();
                if (runs.Count == 0) continue;

                var texts = runs.Select(r => r.GetFirstChild<Text>()?.Text ?? "").ToList();
                string fullText = string.Concat(texts);

                int index = fullText.IndexOf(placeholder, StringComparison.Ordinal);
                if (index < 0) continue;

                // refaz o parágrafo: (before) + (drawing) + (after)
                string before = fullText[..index];
                string after = fullText[(index + placeholder.Length)..];

                var refRunProps = runs.FirstOrDefault()?.RunProperties != null
                    ? (RunProperties)runs.First().RunProperties.CloneNode(true)
                    : null;

                para.RemoveAllChildren<Run>();

                if (!string.IsNullOrEmpty(before))
                {
                    var rBefore = new Run(new Text(before));
                    if (refRunProps != null) rBefore.RunProperties = (RunProperties)refRunProps.CloneNode(true);
                    para.Append(rBefore);
                }

                var rImg = new Run(drawing);
                if (refRunProps != null) rImg.RunProperties = (RunProperties)refRunProps.CloneNode(true);
                para.Append(rImg);

                if (!string.IsNullOrEmpty(after))
                {
                    var rAfter = new Run(new Text(after));
                    if (refRunProps != null) rAfter.RunProperties = (RunProperties)refRunProps.CloneNode(true);
                    para.Append(rAfter);
                }

                return true;
            }

            return false;
        }

        public void ReplaceImageByName(string imageNameToReplace, byte[] newImageBytes)
        {
            var mainPart = wordDoc.MainDocumentPart!;
            var drawing = mainPart?.Document?.Body?
                .Descendants<Drawing>()
                .FirstOrDefault(d =>
                    d.Inline?.DocProperties?.Description?.Value == imageNameToReplace);

            if (drawing == null)
                throw new Exception($"Imagem com o nome '{imageNameToReplace}' não encontrada.");

            var blip = drawing.Descendants<DocumentFormat.OpenXml.Drawing.Blip>().FirstOrDefault();
            var extent = drawing.Descendants<Extent>().FirstOrDefault();

            if (blip == null || extent == null)
                throw new Exception("Estrutura do Drawing não contém Blip ou Extent válidos.");

            var oldImagePartId = blip.Embed?.Value;
            var oldImagePart = mainPart?.GetPartById(oldImagePartId!)!;
            mainPart?.DeletePart(oldImagePart);

            var newImagePart = mainPart?.AddImagePart(ImagePartType.Png);
            using (var ms = new MemoryStream(newImageBytes))
                newImagePart?.FeedData(ms);

            if (newImagePart != null && blip.Embed != null)
            {
                var newId = mainPart?.GetIdOfPart(newImagePart);
                blip.Embed.Value = newId;
            }
        }

        public void SaveAsPdf(string docxPath, string outputFolder)
        {
            var command = Settings.Get("LIBRE_OFFICE_COMMAND");
            var arguments = Settings.Get("LIBRE_OFFICE_ARQGUMENTS");

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
