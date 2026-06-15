using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json;

namespace CRUDEX.Classes
{
    /// <summary>
    /// Envelope JSON v1 (AES-256-GCM). Transporte: ek = AES embrulhada em RSA (pública do destinatário).
    /// Colunas IsEncrypted: { v, iv, t, d } com chave mestra, sem ek.
    /// </summary>
    public sealed class CryptoEnvelope
    {
        [JsonProperty("v")]
        public int V { get; set; } = 1;

        [JsonProperty("ek")]
        public string? Ek { get; set; }

        [JsonProperty("iv")]
        public string Iv { get; set; } = string.Empty;

        [JsonProperty("t")]
        public string T { get; set; } = string.Empty;

        [JsonProperty("d")]
        public string D { get; set; } = string.Empty;
    }

    public static class TransportCrypto
    {
        public const int EnvelopeVersion = 1;
        private const int AesKeySize = 32;
        private const int IvSize = 12;
        private const int TagSize = 16;
        static RSA? _serverRsa;
        static byte[]? _masterKey;

        static RSA ServerRsa
        {
            get
            {
                if (_serverRsa != null)
                    return _serverRsa;
                var privateKey = Settings.Get(Settings.RsaPrivateKeyName);
                if (string.IsNullOrWhiteSpace(privateKey))
                    throw new Exception($"{Settings.RsaPrivateKeyName} não configurada.");
                _serverRsa = RSA.Create();
                _serverRsa.ImportPkcs8PrivateKey(Convert.FromBase64String(privateKey), out _);
                return _serverRsa;
            }
        }

        public static string ServerPublicKeySpki
        {
            get
            {
                var configured = Settings.Get(Settings.RsaPublicKeyName);
                if (!string.IsNullOrWhiteSpace(configured))
                    return configured;
                return Convert.ToBase64String(ServerRsa.ExportSubjectPublicKeyInfo());
            }
        }

        public static bool IsEncryptedEnvelope(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return false;
            value = value.Trim();
            if (!value.StartsWith('{'))
                return false;
            try
            {
                var envelope = JsonConvert.DeserializeObject<CryptoEnvelope>(value);
                return envelope?.V == 1 && !string.IsNullOrEmpty(envelope.D);
            }
            catch
            {
                return false;
            }
        }

        public static CryptoEnvelope ParseEnvelope(string value)
        {
            var envelope = JsonConvert.DeserializeObject<CryptoEnvelope>(value)
                ?? throw new Exception("Envelope de criptografia inválido.");
            if (envelope.V != 1)
                throw new Exception("Versão de envelope de criptografia não suportada.");
            return envelope;
        }

        static string SerializeEnvelope(CryptoEnvelope envelope)
        {
            return JsonConvert.SerializeObject(envelope);
        }

        public static byte[] DecodeKey(string base64Key)
        {
            if (string.IsNullOrWhiteSpace(base64Key))
                throw new Exception("Chave de sessão ausente.");
            var key = Convert.FromBase64String(base64Key);
            if (key.Length != AesKeySize)
                throw new Exception("Chave de sessão AES inválida.");
            return key;
        }

        public static byte[] UnwrapAesKey(string wrappedBase64)
        {
            if (string.IsNullOrWhiteSpace(wrappedBase64))
                throw new Exception("Campo ek é requerido no envelope criptografado.");
            var wrapped = Convert.FromBase64String(wrappedBase64);
            var key = ServerRsa.Decrypt(wrapped, RSAEncryptionPadding.OaepSHA256);
            if (key.Length != AesKeySize)
                throw new Exception("Chave de sessão RSA inválida.");
            return key;
        }

        public static string WrapAesKey(byte[] aesKey, string recipientPublicKeySpkiBase64)
        {
            if (string.IsNullOrWhiteSpace(recipientPublicKeySpkiBase64))
                throw new Exception("Chave pública RSA do destinatário é requerida.");
            using var rsa = RSA.Create();
            rsa.ImportSubjectPublicKeyInfo(Convert.FromBase64String(recipientPublicKeySpkiBase64), out _);
            return Convert.ToBase64String(rsa.Encrypt(aesKey, RSAEncryptionPadding.OaepSHA256));
        }

        public static string EncryptValue(string plaintext, byte[] aesKey, string? recipientPublicKeySpki = null)
            => Encrypt(plaintext, aesKey, recipientPublicKeySpki);

        public static string EncryptTransport(string plaintext, byte[] aesKey, string recipientPublicKeySpki)
        {
            if (string.IsNullOrWhiteSpace(recipientPublicKeySpki))
                throw new Exception("Chave pública RSA do destinatário é requerida para transporte.");
            return Encrypt(plaintext, aesKey, recipientPublicKeySpki);
        }

        public static string DecryptValue(string envelopeJson, byte[] aesKey)
            => Decrypt(envelopeJson, aesKey);

        public static bool HasMasterKey => IsValidDataEncryptionKey(Settings.Get(Settings.DataEncryptionKeyName));

        public static byte[] MasterKey
        {
            get
            {
                if (_masterKey != null)
                    return _masterKey;
                var keyText = Settings.Get(Settings.DataEncryptionKeyName);
                if (string.IsNullOrWhiteSpace(keyText))
                    throw new Exception($"{Settings.DataEncryptionKeyName} não configurada.");
                _masterKey = DecodeKey(keyText);
                return _masterKey;
            }
        }

        static bool IsValidDataEncryptionKey(string? base64)
        {
            if (string.IsNullOrWhiteSpace(base64))
                return false;
            try
            {
                return Convert.FromBase64String(base64).Length == AesKeySize;
            }
            catch
            {
                return false;
            }
        }

        public static string EncryptStoredValue(string? value)
        {
            if (string.IsNullOrEmpty(value))
                return value ?? string.Empty;
            if (IsEncryptedEnvelope(value))
                return value;
            return EncryptValue(value, MasterKey);
        }

        public static string DecryptStoredValue(string? value)
        {
            if (string.IsNullOrEmpty(value))
                return value ?? string.Empty;
            if (!IsEncryptedEnvelope(value))
                return value;
            return DecryptValue(value, MasterKey);
        }

        public static string Encrypt(string plaintext, byte[] aesKey, string? recipientPublicKeySpki = null)
        {
            var iv = RandomNumberGenerator.GetBytes(IvSize);
            var plainBytes = Encoding.UTF8.GetBytes(plaintext);
            var cipher = new byte[plainBytes.Length];
            var tag = new byte[TagSize];
            using var aes = new AesGcm(aesKey, TagSize);
            aes.Encrypt(iv, plainBytes, cipher, tag);

            var envelope = new CryptoEnvelope
            {
                Iv = Convert.ToBase64String(iv),
                T = Convert.ToBase64String(tag),
                D = Convert.ToBase64String(cipher),
            };
            if (!string.IsNullOrWhiteSpace(recipientPublicKeySpki))
                envelope.Ek = WrapAesKey(aesKey, recipientPublicKeySpki);

            return SerializeEnvelope(envelope);
        }

        public static string Decrypt(string envelopeJson, byte[] aesKey)
        {
            var envelope = ParseEnvelope(envelopeJson);
            var iv = Convert.FromBase64String(envelope.Iv);
            var tag = Convert.FromBase64String(envelope.T);
            var cipher = Convert.FromBase64String(envelope.D);
            var plain = new byte[cipher.Length];
            using var aes = new AesGcm(aesKey, TagSize);
            aes.Decrypt(iv, cipher, tag, plain);
            return Encoding.UTF8.GetString(plain);
        }
    }
}
