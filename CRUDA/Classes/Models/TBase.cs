using CRUDA_LIB;
using NPOI.SS.Formula.Functions;
using System.Data;
using System.Diagnostics.CodeAnalysis;

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
                throw new ArgumentNullException(nameof(anonymousObject), "Objeto anônimo requerido.");

            var classNameProperty = anonymousObject.GetType().GetProperty("ClassName") ?? 
                throw new ArgumentException("Propriedade ClassName indefinida em objeto anônimo.", nameof(anonymousObject));

            if (classNameProperty.GetValue(anonymousObject)?.ToString() != expectedClassName)
                throw new ArgumentException($"Objeto anônimo deve ser do tipo {expectedClassName}.", nameof(anonymousObject));
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
                throw new ArgumentNullException(nameof(objects), "Array de objetos anônimos requerido.");

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
