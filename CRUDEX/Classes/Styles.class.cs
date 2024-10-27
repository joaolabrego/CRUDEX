namespace CRUDA_LIB
{
    public class Styles
    {
        public readonly string ClassName = "Styles";
        public readonly string Body = string.Empty;
        public readonly string Screen = string.Empty;
        public readonly string Dialog = string.Empty;
        public readonly string Login = string.Empty;
        public readonly string Menu = string.Empty;
        public readonly string Grid = string.Empty;
        public readonly string Form = string.Empty;
        public readonly string DropDown = string.Empty;
        public readonly string Spinner = string.Empty;
        public readonly string Scrollbar = string.Empty;
        public Styles()
        {
            var directory = Path.Combine(Directory.GetCurrentDirectory(), Settings.Get("DIRECTORY_STYLES"));

            Body = File.ReadAllText(Path.Combine(directory, Settings.Get("BODY_STYLE")));
            Screen = File.ReadAllText(Path.Combine(directory, Settings.Get("MAIN_STYLE"))) + '\n' +
                File.ReadAllText(Path.Combine(directory, Settings.Get("SCREEN_STYLE")));
            Dialog = File.ReadAllText(Path.Combine(directory, Settings.Get("DIALOG_STYLE")));
            Login = File.ReadAllText(Path.Combine(directory, Settings.Get("LOGIN_STYLE")));
            Menu = File.ReadAllText(Path.Combine(directory, Settings.Get("MENU_STYLE")));
            Grid = File.ReadAllText(Path.Combine(directory, Settings.Get("GRID_STYLE")));
            Form = File.ReadAllText(Path.Combine(directory, Settings.Get("FORM_STYLE")));
            DropDown = File.ReadAllText(Path.Combine(directory, Settings.Get("DROPDOWN_STYLE")));
            Spinner = File.ReadAllText(Path.Combine(directory, Settings.Get("SPINNER_STYLE")));
            Scrollbar = File.ReadAllText(Path.Combine(directory, Settings.Get("SCROLLBAR_STYLE")));
        }
    }
}