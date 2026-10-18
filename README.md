# Desafio 2 — Projeto Aplicado I (UniSENAI)

**Tema 02: Modelagem e Implementação de Banco de Dados (SQLite)**
Empresa parceira: **Schulz S.A.** — Laboratório de Metrologia
Prof. MSc. Hugo Menezes Barra

Modelagem do banco relacional que substitui a planilha Excel usada hoje para emitir
os certificados de calibração dos dispositivos medidos na máquina de medição por
coordenadas (MMC).

## Arquivos

| Arquivo | O que é |
|---|---|
| `01_estrutura.md` | Entregável 1 — modelo conceitual simplificado (3 entidades) |
| `02_dicionario.md` | Entregável 2 — dicionário de dados (24 campos) |
| `03_banco.sql` | Entregável 3 — script DDL das 3 tabelas em SQLite |
| `04_dados_exemplo.sql` | Complemento — carrega os dados reais do certificado nº 00091/2026 |
| `05_consultas.sql` | Complemento — consultas de verificação |
| `criar_banco.py` | Complemento — executa os scripts e confere a estrutura |
| `Scripts - Desafio 2.txt` | Tudo em um arquivo só, com a lista de correções |

## Como executar

```bash
python criar_banco.py
```

Gera o `schulz.db` com as 3 tabelas, os 4 índices e a view `vw_certificado`,
já carregado com as 14 características do certificado nº 00091/2026.

Sem Python, direto pelo SQLite:

```bash
sqlite3 schulz.db ".read 03_banco.sql" ".read 04_dados_exemplo.sql"
```

## Modelo

```
tecnico_solicitante (1) ──< (N) medicao >── (1) equipamento
        │                        │
        └──── solicitante_id ────┘   (segunda FK para a mesma tabela)
```

- **`tecnico_solicitante`** — metrologistas e setores solicitantes, separados pelo campo `tipo`.
- **`equipamento`** — o instrumento calibrado (o mensurando).
- **`medicao`** — o resultado de cada característica avaliada; liga as três entidades.

## Verificação

Os scripts foram executados em um banco SQLite real. Os valores calculados batem
com o PDF do certificado da Schulz: 6,079 / 6,078 / 16,970 / 0,430 / 0,132 / 0,868
e os erros 0,004 / 0,003 / 0,006 / 0,001. Resultado: **8 características aprovadas
e 6 reprovadas**, `0` registros órfãos e `integrity_check = ok`.

## Abrindo no VS Code

Abra a pasta no VS Code e rode `python criar_banco.py` no terminal integrado.
Para inspecionar o banco gerado sem sair do editor, use a extensão
*SQLite Viewer* e abra o `schulz.db`.
