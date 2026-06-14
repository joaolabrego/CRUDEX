namespace CRUDEX.Classes
{
    public class Actions
    {
        public const string CONFIG = "config";
        public const string SCREEN = "screen";
        public const string MENU = "menu";
        public const string GRID = "grid";
        public const string LOGIN = "login";
        public const string LOGOUT = "logout";
        public const string AUTHENTICATE = "authenticate";
        public const string CHANGE = "change";
        public const string EXECUTE = "execute";
        public const string QUERY = "query";
        public const string FILTER = "filter";
        public const string BEGIN = "begin";
        public const string COMMIT = "commit";
        public const string ROLLBACK = "rollback";
        public const string PERSIST = "persist";
        public const string READ = "read";
        public const string CREATE = "create";
        public const string UPDATE = "update";
        public const string DELETE = "delete";
        public const string GENERATE = "generate";
        public const string CHECK = "check";
        public const string RELOAD = "reload";
        public const string EXIT = "exit";
        public const string NONE = "none";
        static public object GetObject()
        {
            return Config.ToJsonObject<Actions>();
        }
    }
}