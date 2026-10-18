# 02 — Dicionário de Dados do Sistema

**Projeto Aplicado I — UniSENAI | Schulz S.A. (Laboratório de Metrologia) — Entrega 02**

Este dicionário mapeia todos os campos do banco SQLite que armazenará os dados dos equipamentos,
técnicos e medições dos certificados de calibração. São **3 tabelas** e **24 campos** no total
(4 + 6 + 14).

**Legenda de restrições:** PK = chave primária · FK = chave estrangeira · UK = valor único ·
NN = obrigatório (NOT NULL).

**Legenda de tipos:** Texto (`TEXT`), Real (`REAL`), Inteiro (`INTEGER`).
No SQLite datas são guardadas como Texto no padrão ISO 8601 (`AAAA-MM-DD HH:MM:SS`), porque o
SQLite não possui tipo de data nativo. Todas as grandezas dimensionais estão em **milímetro**, com
precisão de até décimos de micrômetro (7 casas decimais), conforme informado por João Carlos.

---

## Tabela `tecnico_solicitante` — 4 campos

Técnicos (metrologistas) e setores solicitantes, diferenciados pelo campo `tipo`.

| Campo | Tipo | Chave / Restrição | Descrição | Exemplo |
|---|---|---|---|---|
| `id` | Inteiro | PK, autoincremento | Identificador único do registro | 1 |
| `nome` | Texto | NN, UK junto com `tipo` | Nome do metrologista ou do setor solicitante | Jose Alcides Rosa Junior ; Usinagem I |
| `matricula` | Texto | UK, opcional para setores e obrigatória para técnicos | Matrícula do metrologista | MET-001 |
| `tipo` | Texto | NN, valores `tecnico` ou `solicitante` | Papel do registro | tecnico |

---

## Tabela `equipamento` — 6 campos

Instrumento ou dispositivo submetido à calibração (o mensurando).

| Campo | Tipo | Chave / Restrição | Descrição | Exemplo |
|---|---|---|---|---|
| `id` | Inteiro | PK, autoincremento | Identificador único do equipamento | 1 |
| `codigo` | Texto | NN, UK | Código do instrumento, extraído do campo *Measurement Plan* do relatório da MMC, sem o sufixo `_TESTE` | 703.1208 |
| `tag` | Texto | opcional | TAG de identificação usada no software de gerenciamento dos meios de medição | TAG-703.1208 |
| `denominacao` | Texto | NN | Nome/descrição do equipamento, como sai no certificado | Dispositivo de controle |
| `fabricante` | Texto | opcional | Fabricante/fornecedor do mensurando (campo *Fornecedor* do relatório da MMC) | CDM |
| `num_serie` | Texto | opcional | Número de série do instrumento | Não consta |

---

## Tabela `medicao` — 14 campos

Resultado de cada característica (parâmetro) avaliada em uma calibração. Cada característica é
medida duas vezes (duas repetições no relatório da MMC), e o certificado publica a média.

| Campo | Tipo | Chave / Restrição | Descrição | Exemplo |
|---|---|---|---|---|
| `id` | Inteiro | PK, autoincremento | Identificador único da linha de medição | 3 |
| `equipamento_id` | Inteiro | FK → `equipamento.id`, NN | Equipamento medido | 1 |
| `tecnico_id` | Inteiro | FK → `tecnico_solicitante.id`, NN | Metrologista que executou a medição | 1 |
| `solicitante_id` | Inteiro | FK → `tecnico_solicitante.id`, NN | Setor (cliente interno) que solicitou a calibração | 2 |
| `num_certificado` | Texto | NN, UK junto com `parametro` | Número do certificado que agrupa as características de uma mesma emissão | 00091/2026 |
| `dt_medicao` | Texto | NN, formato ISO 8601 | Data e hora da execução da medição na MMC (campos *Date* e *Time* do relatório) | 2026-08-13 16:16:26 |
| `parametro` | Texto | NN | Nome da característica avaliada: cota do desenho, tipo de medição e índice | 62P_DIÂMETRO 1 |
| `valor_nominal` | Real | NN | Valor nominal (de projeto) da característica, em mm | 6.0750000 |
| `tol_superior` | Real | NN, ≥ 0 | Tolerância superior, em mm | 0.0100000 |
| `tol_inferior` | Real | NN, ≤ 0 | Tolerância inferior, em mm. É **zero** em características geométricas (planicidade, posição) e negativa em dimensionais | -0.0100000 |
| `medida_1` | Real | NN | Primeira repetição da característica, em mm | 6.0787295 |
| `medida_2` | Real | NN | Segunda repetição da característica, em mm | 6.0787295 |
| `valor_obtido` | Real | NN | Média das duas repetições, em mm — é o valor publicado no certificado | 6.0787295 |
| `status` | Texto | NN, valores `aprovado` ou `reprovado` | Situação da característica em relação à faixa de tolerância | aprovado |

---

## Observações e regras de cálculo

1. **`valor_obtido` é calculado:** `valor_obtido = (medida_1 + medida_2) / 2`.
   Validação com o certificado nº 00091/2026: `62P_DIÂMETRO 2` tem medidas 6,0781314 e 6,0780314;
   a média é 6,0780814, que arredondada para três casas dá **6,078** — exatamente o valor impresso
   no certificado.

2. **`status` é calculado** comparando o valor obtido com os limites de aceitação:
   `limite_inferior = valor_nominal + tol_inferior` e `limite_superior = valor_nominal + tol_superior`.
   É `aprovado` quando `valor_obtido` está dentro da faixa, e `reprovado` fora dela.
   Nos dados fornecidos, 8 das 14 características estão aprovadas e 6 reprovadas (todas as
   características de POSIÇÃO, cujo limite é 0,100 mm). Esta é exatamente a verificação que hoje o
   metrologista faz "linha por linha" na planilha, segundo João Carlos.

3. **`erro` não é armazenado**, para não duplicar informação: é derivado por
   `valor_obtido - valor_nominal` e aparece apenas na apresentação, através da view
   `vw_certificado` criada em `03_banco.sql`.

4. **Arredondamento:** os campos Real guardam o valor completo; o arredondamento para três casas
   decimais é aplicado apenas na apresentação do certificado, nunca no armazenamento.

5. **As colunas `tecnico_id` e `solicitante_id` apontam para a mesma tabela** `tecnico_solicitante`,
   e o campo `tipo` indica o papel de cada registro.

6. **Campos de origem que ficaram fora desta entrega** (não cabem nas 3 tabelas pedidas e entram na
   Entrega 03): padrão utilizado (MMC 500.011), certificado e validade do padrão, procedimento
   (ITL-0026 rev. 2), desvio padrão, incerteza de medição, fator k e signatário autorizado.
