using Newtonsoft.Json;
using TDictionary = System.Collections.Generic.Dictionary<string, dynamic?>;

namespace CRUDEX.Classes
{
    public static class Api
    {
        public static async Task<byte[]?> ResolveRequestAesKey(HttpContext context, TDictionary outer, string requestText)
        {
            if (!TransportCrypto.IsEncryptedEnvelope(requestText))
                return null;

            var envelope = TransportCrypto.ParseEnvelope(requestText);
            if (string.IsNullOrWhiteSpace(envelope.Ek))
                throw new Exception("Campo ek é requerido em requisições criptografadas.");
            return TransportCrypto.UnwrapAesKey(envelope.Ek);
        }

        public static string DecryptRequestPayload(string requestText, byte[]? aesKey)
        {
            if (aesKey == null)
                return requestText;
            return TransportCrypto.DecryptValue(requestText, aesKey);
        }

        public static async Task WriteJsonResponse(HttpContext context, string response, byte[]? aesKey, string? clientRsaPublicKey = null)
        {
            if (aesKey != null)
            {
                if (string.IsNullOrWhiteSpace(clientRsaPublicKey))
                {
                    var loginId = ResolveLoginId(context, null);
                    if (loginId.HasValue)
                        clientRsaPublicKey = await Login.GetClientRsaPublicKey(loginId.Value);
                }
                if (string.IsNullOrWhiteSpace(clientRsaPublicKey))
                    throw new Exception("Chave pública RSA do cliente é requerida para cifrar a resposta.");
                response = TransportCrypto.EncryptTransport(response, aesKey, clientRsaPublicKey);
            }

            context.Response.ContentType = "application/json; charset=utf-8";
            await context.Response.WriteAsync(JsonConvert.SerializeObject(new { Response = response }));
        }

        static long? ResolveLoginId(HttpContext context, TDictionary? request)
        {
            if (context.Request.Headers.TryGetValue("LoginId", out var header) &&
                long.TryParse(header.ToString(), out var headerLoginId))
                return headerLoginId;

            if (request != null && request.TryGetValue("LoginId", out dynamic? loginIdValue))
            {
                if (long.TryParse(Convert.ToString(loginIdValue), out long requestLoginId))
                    return requestLoginId;
            }

            return null;
        }
    }
}
