-- Correção do filtro com comparador no browse
--
-- Problema: o frontend envia {"DomainId":{"op":3,"value":1}}
-- O SQL lia $.DomainId.op mas NÃO lia $.DomainId.value (só $.DomainId escalar).
-- Resultado: @G_DomainId_op=3, @G_DomainId_v=NULL → WHERE não era aplicado.
-- Checkbox funcionava porque envia true/false (escalar), não {op,value}.
--
-- O Id 1 para BigInteger está CORRETO (Domains.Id=1, Name='BigInteger').
-- O dropdown mostrar "1" ao reabrir era só falta de resolver o rótulo FK (fix no JS).
--
-- Aplicar: executar no SSMS a procedure ColumnsRead (ou SCRIPT-CRUDEX.sql completo)
-- a partir da linha "Criar stored procedure [dbo].[ColumnsRead]".

DECLARE @j NVARCHAR(MAX) = N'{"DomainId":{"op":3,"value":1}}';
SELECT
    TRY_CAST(JSON_VALUE(@j, '$.DomainId.op') AS TINYINT) AS op,
    TRY_CAST(JSON_VALUE(@j, '$.DomainId.value') AS BIGINT) AS val;
