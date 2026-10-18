# 01 — Organização dos Dados (Modelo Conceitual Simplificado)

**Projeto Aplicado I — UniSENAI | Empresa parceira: Schulz S.A. (Laboratório de Metrologia)**
**Entrega 02 — Modelagem e Implementação de Banco de Dados (SQLite)**
**Tema:** automação da emissão de certificados de calibração de dispositivos medidos na MMC.

## 1. Contexto

Na Entrega 01 mapeamos o processo atual: os dados de um certificado de calibração estão
espalhados entre o relatório da máquina de medição por coordenadas (MMC), o software de
gerenciamento dos meios de medição e uma planilha Excel de várias abas
(Importação → Registro → Incerteza → Certificado) preenchida à mão por um segundo metrologista.
São de 600 a 700 certificados por mês, dos quais 100 a 150 vêm da MMC.

Para substituir essa leitura estática de planilhas, o sistema passa a armazenar os dados em um
banco relacional (SQLite), garantindo histórico, integridade e rastreabilidade.
Conforme o roteiro da Entrega 02, o banco foi dividido em **3 entidades principais**:
Técnico/Solicitante, Equipamento e Medição.

## 2. As três entidades

### 2.1 Técnico/Solicitante (`tecnico_solicitante`)

Guarda as **pessoas e os setores** envolvidos na calibração: o metrologista que executa a medição
(na planilha "Registro MMC" aparecem dois, um por turno — José A. Rosa Jr e Cleocir de Souza) e o
cliente interno que pediu a calibração (ex.: Usinagem I, Metrologia, Pintura).
Campos: nome, matrícula e tipo. O campo `tipo` (`tecnico` ou `solicitante`) é o que diferencia uma
pessoa de um setor dentro da mesma tabela.
Hoje o certificado registra apenas o nome do técnico, sem matrícula; cadastrando essa informação
uma única vez, o certificado passa a identificar quem executou de forma completa e consistente.

### 2.2 Equipamento (`equipamento`)

Guarda o **instrumento ou dispositivo que está sendo calibrado** (o mensurando): código, TAG,
denominação, fabricante e número de série. O código vem do nome do programa de medição no
relatório da MMC — o campo *Measurement Plan* traz `703.1208_TESTE`, de onde se extrai `703.1208`,
que é exatamente o código impresso no certificado.
Essas informações hoje ficam no software de gerenciamento dos meios de medição e são copiadas à
mão para a planilha a cada emissão. No banco, cada equipamento existe **uma única vez**, não
importa quantas vezes seja calibrado.

### 2.3 Medição (`medicao`)

Guarda o **resultado de cada característica (parâmetro) avaliada** em uma calibração: número do
certificado, data/hora, parâmetro, valor nominal, tolerâncias superior e inferior, as duas medidas
realizadas, o valor obtido e o status (aprovado ou reprovado).
É a entidade que mais cresce: o certificado-modelo nº 00091/2026 tem 14 características, e João
Carlos informou que um dispositivo pode ter de 3 a 30.
Ela se liga a três registros de cadastro: o equipamento medido, o técnico que executou e o setor
solicitante.

## 3. Relacionamentos

- Um **equipamento** tem **várias medições** ao longo do tempo (1:N). Cada medição pertence a um
  único equipamento, por `equipamento_id`.
- Um **técnico/solicitante** está ligado a **várias medições** (1:N).
- A tabela `medicao` tem **duas chaves estrangeiras apontando para a mesma tabela**
  `tecnico_solicitante`:
  - `tecnico_id` → o metrologista que **executou** a medição (`tipo = 'tecnico'`);
  - `solicitante_id` → o setor que **pediu** a calibração (`tipo = 'solicitante'`).
- Isso é possível porque técnico e solicitante exercem **papéis diferentes**, mas são cadastros com
  a mesma estrutura (nome, matrícula, tipo). Em vez de criar uma tabela por papel, mantemos uma só
  e o campo `tipo` indica o papel — o que respeita a divisão em 3 entidades pedida no roteiro.
- Todas as ligações são chaves estrangeiras com `ON DELETE RESTRICT`, o que impede registrar uma
  medição de um equipamento, técnico ou solicitante que não existe, e impede apagar um cadastro que
  ainda tem medições ligadas a ele.

```
tecnico_solicitante (1) ──< (N) medicao >── (1) equipamento
        │                        │
        └──── solicitante_id ────┘   (segunda FK para a mesma tabela)
```

## 4. Por que evitar dados duplicados

1. **Consistência:** se os dados do equipamento fossem repetidos em cada linha de medição, uma
   correção (a grafia do fabricante, por exemplo) teria de ser feita em dezenas de linhas, e alguma
   ficaria para trás. Com o dado em um único lugar, corrige-se uma vez e vale para todos.
2. **Redução de erros reais já observados:** nas planilhas fornecidas, o mesmo técnico aparece como
   "José A. Rosa Jr" no relatório da MMC e como "Jose Alcides Rosa Junior" no certificado; o
   fornecedor do dispositivo é "CDM" no relatório e "Não consta" no certificado; e a MMC usada é
   500008 no relatório e 500.011 no certificado. Toda divergência desse tipo é consequência direta
   de o mesmo dado ser digitado em mais de um lugar.
3. **Economia de espaço e de digitação:** um dispositivo com 30 características calibrado várias
   vezes por ano repetiria os dados de cadastro centenas de vezes. Referenciando por chave, a
   medição guarda apenas um número inteiro.
4. **Rastreabilidade em auditoria:** com cada informação em um só lugar e ligada por chaves, é
   possível consultar todo o histórico de um equipamento ou de um técnico sem ambiguidade — o que
   hoje não existe, porque cada certificado é um arquivo Excel isolado.
5. **Integridade:** chaves primárias e estrangeiras impedem medição "órfã", sem equipamento,
   técnico ou solicitante correspondente. As restrições `UNIQUE` impedem cadastrar duas vezes o
   mesmo equipamento (`codigo`) ou a mesma característica dentro do mesmo certificado
   (`num_certificado` + `parametro`).

## 5. Limites conhecidos deste modelo

Por exigência do roteiro, o banco tem exatamente 3 tabelas. Isso traz duas limitações que a equipe
reconhece e pretende tratar na Entrega 03:

- O **cabeçalho da calibração** (número do certificado, data, técnico e solicitante) se repete em
  todas as linhas de um mesmo certificado. Numa normalização completa ele viraria uma quarta
  entidade (`calibracao`), e `medicao` guardaria apenas `calibracao_id`. O campo `num_certificado`
  já foi incluído justamente para agrupar as linhas de uma mesma emissão e tornar essa evolução
  simples.
- O **padrão utilizado** (a MMC 500.011 Carl Zeiss, com seu certificado e sua próxima calibração) e
  o **cálculo de incerteza** ficam fora desta entrega e seriam uma quinta entidade (`padrao`).

## 6. Conclusão

A divisão em Técnico/Solicitante, Equipamento e Medição separa o que é **cadastro** (dados que
mudam pouco e são reutilizados) do que é **evento** (cada característica medida em cada
calibração). Essa separação elimina a duplicação de dados, dá suporte ao histórico de calibrações e
prepara o banco para o script de criação das tabelas (`03_banco.sql`).
