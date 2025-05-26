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
            using var report = new Report("./testes/report_template.docx");
            report.Generate("./testes/data.json", "./testes/report_result.docx");

            string docxPath = @"D:\CRUDEX-C#\SGSI_CRUDEX\CRUDEX\testes\report_result.docx";
            string outputFolder = Path.GetDirectoryName(docxPath)!;
            
            // Salva o PDF na mesma pasta
            report.SaveAsPdf(docxPath, outputFolder);
        }

        public void Generate(string jsonPath, string outputPath)
        {
            var json = JObject.Parse(File.ReadAllText(jsonPath));
            var body = wordDoc.MainDocumentPart!.Document.Body;
            if (body == null) return;

            ReplaceTagsPreciselyPreservingFormatting(body, json);

            InsertImageInlineFromBase64(wordDoc, "<Logo>", File.ReadAllBytes("./testes/logo.png"), "Labrego");
            this.ReplaceImageByName("EvadinLogo", File.ReadAllBytes("./testes/logo.png"));

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

            wordDoc.MainDocumentPart.Document.Save();
            wordDoc.Dispose();
            File.WriteAllBytes(outputPath, memoryStream.ToArray());
        }

        private static void ReplaceTagsPreciselyPreservingFormatting(Body body, JObject json)
        {
            var replacements = json.Properties().ToDictionary(p => $"<{p.Name}>", p => p.Value.ToString());

            foreach (var paragraph in body.Elements<Paragraph>())
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
                        int currentPos = 0, startRun = -1, endRun = -1;

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

                        paragraph.AppendChild(newRun);

                        runs = [.. paragraph.Elements<Run>()];
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
                    ? originalPara?.Descendants<Run>().First().RunProperties?.CloneNode(true) as RunProperties : null;
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
        public static void InsertImageInlineFromBase64(WordprocessingDocument doc, string placeholder, byte[] base64, string imageName)
        {
            var mainPart = doc.MainDocumentPart!;
            var body = mainPart.Document.Body!;

            // Converte a string base64 em stream de imagem
            using var imageStream = new MemoryStream(base64);

            var imagePart = mainPart.AddImagePart(ImagePartType.Png);
            imagePart.FeedData(imageStream);
            var imageId = mainPart.GetIdOfPart(imagePart);

            using var imgStream = new MemoryStream(base64);
            using var image = System.Drawing.Image.FromStream(imgStream);

            // Converte para EMU (1 polegada = 914400 EMUs, 1 polegada = 96 DPI padrão)
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

            // Substituição da tag <Logo> pelo Drawing
            foreach (var para in body.Elements<Paragraph>())
            {
                var allTexts = para.Descendants<Text>().ToList();
                string fullText = string.Concat(allTexts.Select(t => t.Text));

                int index = fullText.IndexOf(placeholder);
                if (index < 0) continue;

                para.RemoveAllChildren<Run>();

                string before = fullText[..index];
                string after = fullText[(index + placeholder.Length)..];

                if (!string.IsNullOrEmpty(before))
                    para.Append(new Run(new Text(before)));

                para.Append(new Run(drawing));

                if (!string.IsNullOrEmpty(after))
                    para.Append(new Run(new Text(after)));

                break;
            }
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

            // Remove a imagem antiga
            var oldImagePartId = blip.Embed?.Value;
            var oldImagePart = mainPart?.GetPartById(oldImagePartId!)!;
            mainPart?.DeletePart(oldImagePart);

            // Adiciona nova imagem
            var newImagePart = mainPart?.AddImagePart(ImagePartType.Png);
            using (var ms = new MemoryStream(newImageBytes))
                newImagePart?.FeedData(ms);

            // Atualiza referência para nova imagem
            if (newImagePart != null && blip.Embed != null)
            {
                var newId = mainPart?.GetIdOfPart(newImagePart);
                blip.Embed.Value = newId;
            }
            // Mantém as dimensões (Cx, Cy)
            // Nada mais a fazer, pois o `Extent` já está certo
        }


        public void SaveAsPdf(string docxPath, string outputFolder)
        {
            var libreOfficePath = Settings.Get("LIBRE_OFFICE_COMMAND");

            var startInfo = new ProcessStartInfo
            {
                FileName = libreOfficePath,
                Arguments = $"--headless --convert-to pdf \"{docxPath}\" --outdir \"{outputFolder}\"",
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