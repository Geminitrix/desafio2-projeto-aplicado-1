-- =============================================================================
-- Projeto Aplicado I - UniSENAI | Schulz S.A.
-- Arquivo: 05_consultas.sql  (COMPLEMENTO - nao exigido pelo roteiro)
-- Consultas de verificacao do banco. Executar depois de 03 e 04.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- 1) O certificado 00091/2026 reconstruido a partir das 3 tabelas.
--    Comparar com a secao "4. Resultados (mm)" do PDF do certificado.
SELECT parametro_avaliado, valor_nominal, tol_mais, tol_menos, valor_obtido, erro, status
FROM vw_certificado
WHERE certificado = '00091/2026';

-- 2) Resumo de aprovados x reprovados por certificado.
SELECT num_certificado,
       COUNT(*)                                            AS caracteristicas,
       SUM(CASE WHEN status = 'aprovado'  THEN 1 ELSE 0 END) AS aprovadas,
       SUM(CASE WHEN status = 'reprovado' THEN 1 ELSE 0 END) AS reprovadas
FROM medicao
GROUP BY num_certificado;

-- 3) Historico de calibracoes de um equipamento (o que hoje nao existe,
--    porque cada certificado e um arquivo Excel separado).
SELECT e.codigo, e.denominacao, m.num_certificado,
       date(m.dt_medicao) AS data, t.nome AS tecnico, COUNT(*) AS caracteristicas
FROM medicao m
JOIN equipamento e         ON e.id = m.equipamento_id
JOIN tecnico_solicitante t ON t.id = m.tecnico_id
GROUP BY m.num_certificado, e.codigo, e.denominacao, data, t.nome
ORDER BY m.dt_medicao DESC;

-- 4) Verificacao de integridade do banco.
PRAGMA foreign_key_check;
PRAGMA integrity_check;
