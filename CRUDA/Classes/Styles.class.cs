namespace CRUDA_LIB
{
    public class Styles
    {
        public readonly string ClassName = "Styles";
        public readonly string Body = "";
        public readonly string Screen = "";
        public readonly string Dialog = "";
        public readonly string Login = "";
        public readonly string Menu = "";
        public readonly string Grid = "";
        public readonly string Form = "";
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
        }
    }
}