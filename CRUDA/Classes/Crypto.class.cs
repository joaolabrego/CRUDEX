using System.Text;

namespace CRUDA_LIB
{
    public class Crypto
    {
        public readonly string ClassName = "Crypto";
        private readonly static string CryptoPrefix = "encrypted";
        public readonly string CryptoKey = string.Empty;
        private static readonly string CHARSET = "0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz+*&%$#!?.:=@<>,;/[]{}()";
        private static readonly Random Rnd = new();
        private static readonly int DEFAULT_LENGTH = 100;
        private static readonly char DELIMITER_VALUE = (char)5;

        public Crypto(string? cryptoKey = null)
        {
            if (string.IsNullOrEmpty(cryptoKey))
                CryptoKey = GenerateCryptoKey();
            else
                CryptoKey = cryptoKey;
        }
        private static string GenerateCryptoKey(int? length = null)
        {
            var result = string.Empty;

            if (length == null || length <= 0)
                length = DEFAULT_LENGTH;
            for (var i = 0; i < length; i++)
                result += CHARSET[Rnd.Next(0, CHARSET.Length)];

            return result;
        }
        public static bool IsEncrypted(string value)
        {
            return value.Length >= CryptoPrefix.Length && value[..CryptoPrefix.Length] == CryptoPrefix;
        }
        public string Encrypt(ref string value, string? keys = null)
        {
            var SPACE = (int)' ';
            var factor = -1;
            var prefix = CryptoPrefix;
            var result = new StringBuilder();
            var encrypted = IsEncrypted(value);

            if (string.IsNullOrEmpty(keys))
                keys = CryptoKey;
            if (encrypted)
            {
                factor = 1;
                value = value[CryptoPrefix.Length..] + DELIMITER_VALUE;
                prefix = string.Empty;
            }
            else
            {
                if (value.IndexOf(DELIMITER_VALUE) > 0)
                    throw new Exception($"Encrypt: Valor para criptografar não pode conter {DELIMITER_VALUE}.");
                value += DELIMITER_VALUE;
                for (var i = value.Length; i <= DEFAULT_LENGTH; i++)
                    value += CHARSET[Rnd.Next(0, CHARSET.Length)];
            }
            for (var i = 0; i < value.Length; i++)
            {
                var ascii = (int)value[i];

                if (ascii >= SPACE)
                {
                    ascii -= SPACE;
                    ascii += keys[i % keys.Length] * factor;
                    ascii %= 256 - SPACE;
                    if (ascii < 0)
                        ascii += 256 - SPACE;
                    ascii += SPACE;
                }
                result.Append((char)ascii);
            }

            var res = result.ToString();

            if (encrypted)
                res = res[..res.IndexOf(DELIMITER_VALUE)];

            return prefix + res;
        }
    }
}