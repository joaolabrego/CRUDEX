namespace CRUDA.Classes.Models
{
    public abstract class TBase
    {
        protected TBase()
        {
        }
        protected TBase(object anonymousObject, string expectedClassName)
        {
            ValidAnonymousObject(anonymousObject, expectedClassName);
            SetProperties(anonymousObject);
        }
        private static void ValidAnonymousObject(object anonymousObject, string expectedClassName)
        {
            if (anonymousObject == null)
                throw new Exception( "Objeto anônimo requerido.");

            var classNameProperty = anonymousObject.GetType().GetProperty("ClassName") ?? 
                throw new Exception("Propriedade ClassName indefinida em objeto anônimo.");

            if (classNameProperty.GetValue(anonymousObject)?.ToString() != expectedClassName)
                throw new Exception($"Objeto anônimo deve ser do tipo {expectedClassName}.");
        }
        public void SetProperties(object anonymousObject)
        {
            foreach (var instanceProperty in GetType().GetProperties())
            {
                var anonymousProperty = anonymousObject.GetType().GetProperty(instanceProperty.Name);

                if (anonymousProperty != null && instanceProperty.CanWrite)
                    instanceProperty.SetValue(this, anonymousProperty.GetValue(anonymousObject));
            }
        }
        public static T[] ToArray<T>(object[] objects) where T : TBase, new()
        {
            if (objects == null)
                throw new Exception("Array de objetos anônimos requerido.");

            T[] instances = new T[objects.Length];

            for (int i = 0; i < objects.Length; i++)
            {
                var instance = new T();

                instance.SetProperties(objects[i]);
                instances[i] = instance;
            }

            return instances;
        }
    }
}
