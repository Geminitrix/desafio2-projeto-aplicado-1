-- =============================================================================
-- Projeto Aplicado I - UniSENAI | Schulz S.A.
-- Arquivo: 04_dados_exemplo.sql  (COMPLEMENTO - nao exigido pelo roteiro)
--
-- Carrega no banco os dados reais do certificado de calibracao n. 00091/2026,
-- montados a partir da planilha "Registro MMC.xlsx" (duas repeticoes de cada
-- caracteristica) e do "Certificado de Calibracao (Modelo).pdf".
-- Serve para demonstrar que o modelo das 3 tabelas reproduz o certificado.
--
-- Executar DEPOIS de 03_banco.sql:
--   sqlite3 schulz.db ".read 04_dados_exemplo.sql"
-- =============================================================================

PRAGMA foreign_keys = ON;

-- 1) Cadastros -----------------------------------------------------------------
-- Matricula ficticia: nao consta nas planilhas fornecidas pela Schulz.
INSERT OR IGNORE INTO tecnico_solicitante (nome, matricula, tipo) VALUES
    ('Jose Alcides Rosa Junior', 'MET-001', 'tecnico'),
    ('Cleocir de Souza',         'MET-002', 'tecnico'),
    ('Usinagem I',                NULL,     'solicitante'),
    ('Metrologia',                NULL,     'solicitante');

-- Fabricante "CDM" vem do campo Fornecedor do relatorio da MMC.
-- (No certificado-modelo este campo aparece como "Nao consta" - divergencia
--  de dados registrada na Entrega 01.)
INSERT OR IGNORE INTO equipamento (codigo, tag, denominacao, fabricante, num_serie) VALUES
    ('703.1208', 'TAG-703.1208', 'Dispositivo de controle', 'CDM', NULL);

-- 2) Medicoes ------------------------------------------------------------------
-- As 14 caracteristicas do certificado 00091/2026.
-- m1 e m2 sao as duas repeticoes lidas no relatorio da MMC; valor_obtido e
-- status NAO sao digitados: o proprio INSERT os calcula, aplicando as regras
-- documentadas em 02_dicionario.md.
WITH leitura(parametro, nominal, tol_sup, tol_inf, m1, m2) AS (
    VALUES
        ('PLANICIDADE_REF',    0.0,    0.050,  0.0,    0.0021670,  0.0022670),
        ('ENTRE CENTROS_REF',  0.0,    0.040,  0.0,    0.0274147,  0.0274147),
        ('62P_DIÂMETRO 1',     6.075,  0.010, -0.010,  6.0787295,  6.0787295),
        ('62P_POSIÇÃO 1',      0.0,    0.100,  0.0,    0.4295522,  0.4295522),
        ('62P_DIÂMETRO 2',     6.075,  0.010, -0.010,  6.0781314,  6.0780314),
        ('62P_POSIÇÃO 2',      0.0,    0.100,  0.0,    0.2446114,  0.2446114),
        ('13P_DIÂMETRO 1',    16.964,  0.010, -0.010, 16.9684482, 16.9684482),
        ('13P_POSIÇÃO 1',      0.0,    0.100,  0.0,    0.9590437,  0.9590437),
        ('13P_DIÂMETRO 2',    16.964,  0.010, -0.010, 16.9698259, 16.9698259),
        ('13P_POSIÇÃO 2',      0.0,    0.100,  0.0,    0.2355755,  0.2355755),
        ('106P_DIÂMETRO 1',    6.345,  0.010, -0.010,  6.3463135,  6.3463135),
        ('106P_POSIÇÃO 1',     0.0,    0.100,  0.0,    0.1326897,  0.1316897),
        ('106P_DIÂMETRO 2',    6.345,  0.010, -0.010,  6.3485617,  6.3485617),
        ('106P_POSIÇÃO 2',     0.0,    0.100,  0.0,    0.8677580,  0.8677580)
)
INSERT INTO medicao (
    equipamento_id, tecnico_id, solicitante_id,
    num_certificado, dt_medicao,
    parametro, valor_nominal, tol_superior, tol_inferior,
    medida_1, medida_2, valor_obtido, status
)
SELECT
    (SELECT id FROM equipamento         WHERE codigo = '703.1208'),
    (SELECT id FROM tecnico_solicitante WHERE nome = 'Jose Alcides Rosa Junior' AND tipo = 'tecnico'),
    (SELECT id FROM tecnico_solicitante WHERE nome = 'Usinagem I'               AND tipo = 'solicitante'),
    '00091/2026',
    '2026-08-13 16:16:26',          -- Date/Time do relatorio da MMC
    l.parametro, l.nominal, l.tol_sup, l.tol_inf,
    l.m1, l.m2,
    (l.m1 + l.m2) / 2.0,            -- valor_obtido = media das duas repeticoes
    CASE
        WHEN (l.m1 + l.m2) / 2.0 BETWEEN l.nominal + l.tol_inf
                                     AND l.nominal + l.tol_sup THEN 'aprovado'
        ELSE 'reprovado'
    END                             -- status = dentro ou fora da faixa de tolerancia
FROM leitura l;
