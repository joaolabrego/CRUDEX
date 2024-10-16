namespace CRUDA_LIB
{
    public class Images
    {
        public readonly string ClassName = "Images";
        public readonly string Background;
        public readonly string Question;
        public readonly string Alert;
        public readonly string Error;
        public readonly string Insert;
        public readonly string Edit;
        public readonly string Filter;
        public readonly string Unfilter;
        public readonly string Delete;
        public readonly string Query;
        public readonly string Exit;
        public readonly string Confirm;
        public readonly string Cancel;
        public Images(string clientName)
        {
            var directory = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_IMAGES"));

            Background = ReadImageFile(Path.Combine(directory, $"{clientName}.{Settings.Get("BACKGROUND_IMAGE_EXTENSION")}"), true);
            Question = ReadImageFile(Path.Combine(directory, $"{Settings.Get("QUESTION_IMAGE")}"));
            Alert = ReadImageFile(Path.Combine(directory, $"{Settings.Get("ALERT_IMAGE")}"));
            Error = ReadImageFile(Path.Combine(directory, $"{Settings.Get("ERROR_IMAGE")}"));
            Insert = ReadImageFile(Path.Combine(directory, $"{Settings.Get("INSERT_IMAGE")}"), true);
            Edit = ReadImageFile(Path.Combine(directory, $"{Settings.Get("EDIT_IMAGE")}"), true);
            Filter = ReadImageFile(Path.Combine(directory, $"{Settings.Get("FILTER_IMAGE")}"), true);
            Unfilter = ReadImageFile(Path.Combine(directory, $"{Settings.Get("UNFILTER_IMAGE")}"), true);
            Delete = ReadImageFile(Path.Combine(directory, $"{Settings.Get("DELETE_IMAGE")}"), true);
            Query = ReadImageFile(Path.Combine(directory, $"{Settings.Get("ZOOM_IMAGE")}"), true);
            Exit = ReadImageFile(Path.Combine(directory, $"{Settings.Get("EXIT_IMAGE")}"), true);
            Confirm = ReadImageFile(Path.Combine(directory, $"{Settings.Get("CONFIRM_IMAGE")}"), true);
            Cancel = ReadImageFile(Path.Combine(directory, $"{Settings.Get("CANCEL_IMAGE")}"), true);
        }
        public static string ReadImageFile(string fileName, bool withURL = false)
        {
            var image = $"data:image;base64,{Convert.ToBase64String(File.ReadAllBytes(fileName))}";

            if (withURL)
                return $"url(\"{image}\")";

            return image;
        }
    }
}
