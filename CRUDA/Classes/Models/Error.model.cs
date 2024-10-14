using CRUDA_LIB;
using Newtonsoft.Json;

namespace crudax.Classes.Models
{
    public class Error(string message, string? action = null)
    {
        public readonly string ClassName = "Error";
        public readonly string Message = message;
        public readonly string? Action = action;

        override public string ToString()
        {
            return JsonConvert.SerializeObject(this, Formatting.Indented);
        }
    }
}
