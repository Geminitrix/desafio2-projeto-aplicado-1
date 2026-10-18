"""
Projeto Aplicado I - UniSENAI | Schulz S.A. (Laboratorio de Metrologia)
Entrega 02 - criar_banco.py

Cria o arquivo schulz.db e executa os scripts SQL da entrega, depois imprime a
estrutura criada para conferencia.

Uso (no VS Code, terminal integrado, dentro da pasta do projeto):
    python criar_banco.py

Requer apenas a biblioteca padrao do Python 3 (modulo sqlite3).
"""

import sqlite3
from pathlib import Path

PASTA = Path(__file__).resolve().parent
BANCO = PASTA / "schulz.db"

# 03_banco.sql e obrigatorio; os demais sao complementos e rodam se existirem.
SCRIPTS = ["03_banco.sql", "04_dados_exemplo.sql"]


def main() -> None:
    con = sqlite3.connect(BANCO)

    # IMPORTANTE: no SQLite a verificacao de chaves estrangeiras e por conexao e
    # nao fica gravada no arquivo .db. Alem disso, o PRAGMA e ignorado quando
    # executado dentro de executescript(), que abre uma transacao. Por isso ele
    # e ligado aqui, na conexao, antes de rodar os scripts.
    con.execute("PRAGMA foreign_keys = ON")

    for nome in SCRIPTS:
        caminho = PASTA / nome
        if not caminho.exists():
            print(f"[ignorado] {nome} nao encontrado")
            continue
        con.executescript(caminho.read_text(encoding="utf-8"))
        print(f"[ok] {nome} executado")
    con.commit()

    print("\nTabelas criadas:")
    for (nome,) in con.execute(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
    ):
        qtd = con.execute(f"SELECT COUNT(*) FROM {nome}").fetchone()[0]
        print(f" - {nome} ({qtd} registro(s))")

    print("\nColunas de medicao:")
    for col in con.execute("PRAGMA table_info(medicao)"):
        obrigatorio = "NOT NULL" if col[3] else ""
        print(f" - {col[1]:<16} {col[2]:<8} {obrigatorio}")

    print("\nChaves estrangeiras de medicao:")
    for fk in con.execute("PRAGMA foreign_key_list(medicao)"):
        print(f" - {fk[3]} -> {fk[2]}.{fk[4]}")

    print("\nVerificacao de integridade:")
    orfaos = con.execute("PRAGMA foreign_key_check").fetchall()
    print(f" - registros orfaos: {len(orfaos)}")
    print(f" - integrity_check: {con.execute('PRAGMA integrity_check').fetchone()[0]}")

    con.close()
    print(f"\nBanco gerado em: {BANCO}")


if __name__ == "__main__":
    main()
