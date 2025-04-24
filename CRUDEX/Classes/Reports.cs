using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using Newtonsoft.Json.Linq;
using A = DocumentFormat.OpenXml.Drawing;
using DW = DocumentFormat.OpenXml.Drawing.Wordprocessing;
using PIC = DocumentFormat.OpenXml.Drawing.Pictures;
public class Report : IDisposable
{
    private MemoryStream _memoryStream;
    private WordprocessingDocument _wordDoc;

    public Report(string templatePath)
    {
        byte[] fileBytes = File.ReadAllBytes(templatePath);
        _memoryStream = new MemoryStream();
        _memoryStream.Write(fileBytes, 0, fileBytes.Length);
        _memoryStream.Position = 0;
        _wordDoc = WordprocessingDocument.Open(_memoryStream, true);
    }

    public static void Teste()
    {
        using var report = new Report("report_template.docx");
        report.Generate("data.json", "report_result.docx");

        string docxPath = @"D:\CRUDEX-C#\SGSI_CRUDEX\CRUDEX\report_result.docx";
        string outputFolder = Path.GetDirectoryName(docxPath)!;

        // Salva o PDF na mesma pasta
        report.SaveAsPdf(docxPath, outputFolder);
    }


    public void Generate(string jsonPath, string outputPath)
    {
        var json = JObject.Parse(File.ReadAllText(jsonPath));
        var body = _wordDoc.MainDocumentPart!.Document.Body;
        if (body == null) return;

        ReplaceTagsPreciselyPreservingFormatting(body, json);

        //InsertImageInline(_wordDoc, "<Logo>", "logo.png");
        string base64 = File.ReadAllText("logo_base64.txt");
        InsertImageInlineFromBase64(_wordDoc, "<Logo>", base64, "Logo.png");


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

        _wordDoc.MainDocumentPart.Document.Save();
        _wordDoc.Dispose();
        File.WriteAllBytes(outputPath, _memoryStream.ToArray());
    }

    private void ReplaceTagsPreciselyPreservingFormatting(Body body, JObject json)
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
                        var preservedText = lastText.Substring(tagOffsetEnd);
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
        var tbl = _wordDoc.MainDocumentPart!.Document.Body
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

    private void SetCellText(TableCell cell, string value)
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
                ? (RunProperties)originalPara.Descendants<Run>().First().RunProperties.CloneNode(true)
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

    public static void InsertImageInline(WordprocessingDocument doc, string placeholder, string imagePath)
    {
        var mainPart = doc.MainDocumentPart!;
        var body = mainPart.Document.Body!;

        // Cria e carrega o ImagePart
        var imagePart = mainPart.AddImagePart(ImagePartType.Png);
        using (var stream = new FileStream(imagePath, FileMode.Open, FileAccess.Read))
            imagePart.FeedData(stream);

        var imageId = mainPart.GetIdOfPart(imagePart);

        // Dimensões em EMUs (1cm = 360000 EMUs aprox)
        long widthEmu = 990000L;   // ~9,9cm
        long heightEmu = 792000L;  // ~7,9cm

        // Cria o Drawing com imagem inline
        var drawing = new Drawing(
            new DocumentFormat.OpenXml.Drawing.Wordprocessing.Inline(
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.Extent { Cx = widthEmu, Cy = heightEmu },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.EffectExtent
                {
                    LeftEdge = 0L,
                    TopEdge = 0L,
                    RightEdge = 0L,
                    BottomEdge = 0L
                },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.DocProperties
                {
                    Id = (UInt32Value)1U,
                    Name = "Imagem"
                },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.NonVisualGraphicFrameDrawingProperties(
                    new DocumentFormat.OpenXml.Drawing.GraphicFrameLocks { NoChangeAspect = true }
                ),
                new DocumentFormat.OpenXml.Drawing.Graphic(
                    new DocumentFormat.OpenXml.Drawing.GraphicData(
                        new DocumentFormat.OpenXml.Drawing.Pictures.Picture(
                            new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureProperties(
                                new DocumentFormat.OpenXml.Drawing.Pictures.NonVisualDrawingProperties
                                {
                                    Id = (UInt32Value)0U,
                                    Name = Path.GetFileName(imagePath)
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

        // Procura a tag mesmo que esteja quebrada entre vários runs
        foreach (var para in body.Elements<Paragraph>())
        {
            var allTexts = para.Descendants<Text>().ToList();
            string fullText = string.Concat(allTexts.Select(t => t.Text));

            int index = fullText.IndexOf(placeholder);
            if (index < 0) continue;

            // Remove todo conteúdo do parágrafo e reinsere com imagem
            para.RemoveAllChildren<Run>();

            string before = fullText[..index];
            string after = fullText[(index + placeholder.Length)..];

            if (!string.IsNullOrEmpty(before))
                para.Append(new Run(new Text(before)));

            // ⚠ Envolve imagem em Run e Paragraph
            para.Append(new Run(drawing));

            if (!string.IsNullOrEmpty(after))
                para.Append(new Run(new Text(after)));

            break;
        }
    }
    public static void InsertImageInlineFromBase64(WordprocessingDocument doc, string placeholder, string base64, string imageName = "Imagem.png")
    {
        var mainPart = doc.MainDocumentPart!;
        var body = mainPart.Document.Body!;

        // Converte a string base64 em stream de imagem
        byte[] imageBytes = Convert.FromBase64String(base64);
        using var imageStream = new MemoryStream(imageBytes);

        var imagePart = mainPart.AddImagePart(ImagePartType.Png);
        imagePart.FeedData(imageStream);
        var imageId = mainPart.GetIdOfPart(imagePart);

        long widthEmu = 990000L;   // 9,9 cm
        long heightEmu = 792000L;  // 7,9 cm

        var drawing = new Drawing(
            new DocumentFormat.OpenXml.Drawing.Wordprocessing.Inline(
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.Extent { Cx = widthEmu, Cy = heightEmu },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.EffectExtent
                {
                    LeftEdge = 0L,
                    TopEdge = 0L,
                    RightEdge = 0L,
                    BottomEdge = 0L
                },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.DocProperties
                {
                    Id = (UInt32Value)1U,
                    Name = imageName
                },
                new DocumentFormat.OpenXml.Drawing.Wordprocessing.NonVisualGraphicFrameDrawingProperties(
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

    public void SaveAsPdf(string docxPath, string outputFolder)
    {
        var libreOfficePath = "soffice"; // ou o caminho absoluto se necessário

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
        _wordDoc?.Dispose();
        _memoryStream?.Dispose();
    }
}
