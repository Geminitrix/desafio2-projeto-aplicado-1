-- =============================================================================
-- Projeto Aplicado I - UniSENAI | Schulz S.A. (Laboratorio de Metrologia)
-- Entrega 02 - Modelagem e Implementacao de Banco de Dados
-- Arquivo: 03_banco.sql  |  SGBD: SQLite 3
--
-- Script DDL de criacao das 3 tabelas do banco de certificados de calibracao.
-- Como executar:
--   sqlite3 schulz.db ".read 03_banco.sql"
--   ou pelo script Python criar_banco.py
-- =============================================================================

-- Habilita a verificacao de chaves estrangeiras.
-- ATENCAO: no SQLite esta opcao vale por CONEXAO e NAO fica gravada no arquivo .db.
-- Toda aplicacao que abrir este banco precisa executar este PRAGMA de novo.
PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- 1) TECNICO / SOLICITANTE
--    Metrologistas que executam a calibracao e setores (clientes internos)
--    que a solicitam. O campo "tipo" distingue o papel de cada registro.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tecnico_solicitante (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    nome      TEXT    NOT NULL,
    matricula TEXT    UNIQUE,
    tipo      TEXT    NOT NULL CHECK (tipo IN ('tecnico', 'solicitante')),

    -- Impede cadastrar duas vezes o mesmo tecnico ou o mesmo setor.
    CONSTRAINT uk_tecnico_solicitante_nome_tipo UNIQUE (nome, tipo),

    -- Todo tecnico precisa de matricula; setores solicitantes podem nao ter.
    CONSTRAINT ck_tecnico_tem_matricula
        CHECK (tipo <> 'tecnico' OR matricula IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- 2) EQUIPAMENTO
--    Instrumento ou dispositivo submetido a calibracao (o mensurando).
--    O codigo vem do campo "Measurement Plan" do relatorio da MMC,
--    sem o sufixo _TESTE (ex.: 703.1208_TESTE -> 703.1208).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS equipamento (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo      TEXT    NOT NULL UNIQUE,
    tag         TEXT,
    denominacao TEXT    NOT NULL,
    fabricante  TEXT,
    num_serie   TEXT
);

-- -----------------------------------------------------------------------------
-- 3) MEDICAO
--    Resultado de cada caracteristica avaliada em uma calibracao.
--    Liga equipamento, tecnico executante e setor solicitante.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS medicao (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Chaves estrangeiras
    equipamento_id  INTEGER NOT NULL,
    tecnico_id      INTEGER NOT NULL,
    solicitante_id  INTEGER NOT NULL,

    -- Identificacao da emissao
    num_certificado TEXT    NOT NULL,
    dt_medicao      TEXT    NOT NULL CHECK (dt_medicao LIKE '____-__-__%'),

    -- Resultado da caracteristica (valores em milimetro)
    parametro       TEXT    NOT NULL,
    valor_nominal   REAL    NOT NULL,
    tol_superior    REAL    NOT NULL CHECK (tol_superior >= 0),
    tol_inferior    REAL    NOT NULL CHECK (tol_inferior <= 0),
    medida_1        REAL    NOT NULL,
    medida_2        REAL    NOT NULL,
    valor_obtido    REAL    NOT NULL,
    status          TEXT    NOT NULL CHECK (status IN ('aprovado', 'reprovado')),

    -- Uma mesma caracteristica nao pode aparecer duas vezes no mesmo certificado.
    CONSTRAINT uk_medicao_certificado_parametro UNIQUE (num_certificado, parametro),

    CONSTRAINT fk_medicao_equipamento
        FOREIGN KEY (equipamento_id) REFERENCES equipamento (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_medicao_tecnico
        FOREIGN KEY (tecnico_id) REFERENCES tecnico_solicitante (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_medicao_solicitante
        FOREIGN KEY (solicitante_id) REFERENCES tecnico_solicitante (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- -----------------------------------------------------------------------------
-- Indices de apoio as consultas de historico (historico por equipamento,
-- por tecnico e por certificado). O SQLite nao cria indice de FK sozinho.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS ix_medicao_equipamento  ON medicao (equipamento_id);
CREATE INDEX IF NOT EXISTS ix_medicao_tecnico      ON medicao (tecnico_id);
CREATE INDEX IF NOT EXISTS ix_medicao_solicitante  ON medicao (solicitante_id);
CREATE INDEX IF NOT EXISTS ix_medicao_certificado  ON medicao (num_certificado);

-- =============================================================================
-- COMPLEMENTO (nao exigido pelo roteiro)
-- View que reproduz a secao "4. Resultados (mm)" do certificado de calibracao
-- a partir das 3 tabelas, ja com o erro calculado e o arredondamento de
-- apresentacao em 3 casas decimais.
-- =============================================================================
CREATE VIEW IF NOT EXISTS vw_certificado AS
SELECT
    m.num_certificado                            AS certificado,
    date(m.dt_medicao)                           AS data_medicao,
    e.codigo                                     AS codigo,
    e.denominacao                                AS denominacao,
    e.fabricante                                 AS fabricante,
    s.nome                                       AS solicitante,
    t.nome                                       AS tecnico_executante,
    m.parametro                                  AS parametro_avaliado,
    ROUND(m.valor_nominal, 3)                    AS valor_nominal,
    ROUND(m.tol_superior, 3)                     AS tol_mais,
    ROUND(m.tol_inferior, 3)                     AS tol_menos,
    ROUND(m.valor_obtido, 3)                     AS valor_obtido,
    ROUND(m.valor_obtido - m.valor_nominal, 3)   AS erro,
    m.status                                     AS status
FROM medicao m
JOIN equipamento         e ON e.id = m.equipamento_id
JOIN tecnico_solicitante t ON t.id = m.tecnico_id
JOIN tecnico_solicitante s ON s.id = m.solicitante_id
ORDER BY m.num_certificado, m.id;
