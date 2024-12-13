# Projeto Pipeline

Este repositório contém a implementação de uma arquitetura de pipeline em VHDL para execução de instruções. O objetivo é simular e estudar o comportamento de uma CPU com pipeline, analisando as interações entre diferentes estágios e como os hazards são tratados. Este documento explica a estrutura do código e como configurá-lo para execução.

## Estrutura do Projeto

O projeto segue uma estrutura clássica de pipeline de CPU com múltiplos estágios: **IF (Instruction Fetch)**, **ID (Instruction Decode)**, **EX (Execute)**, **MEM (Memory Access)** e **WB (Write Back)**. O VHDL utilizado implementa os seguintes componentes principais:

### Entidade `Proj_Pipeline`

A entidade define as entradas e saídas principais do sistema:
- **Entradas**:
  - `clock`: Sinal de clock para sincronização.
  - `reset`: Sinal de reset para inicialização dos registradores e memórias.

### Arquitetura `behavior`

A arquitetura `behavior` implementa a lógica do pipeline. Aqui estão os elementos principais:

#### Tipos e Sinais Declarados
1. **Memórias**:
   - `memoria_dados`: Memória de dados com 256 posições de 8 bits.
   - `memoria_instrucao`: Memória de instruções com 256 posições de 16 bits.
   - `banco_regs`: Banco de 16 registradores de 8 bits cada.

2. **Sinais para Pipeline**:
   - Registradores de pipeline para propagar dados entre estágios (e.g., `inst_ID`, `inst_EX`, `inst_MEM`, `inst_WB`).
   - `PC`: Registrador de contador de programa.
   - `desvio`: Sinal para controle de desvios.

3. **Execução de Operações**:
   - `mul` e `muli`: Multiplicações de registradores e imediatos.
   - `ula`: Unidade Lógica e Aritmética para operações básicas.
   - `equal`: Comparador para desvios condicionais.

#### Memórias
- **Instruções**: A memória `mem_inst` contém instruções que simulam diferentes cenários, incluindo desvios, operações aritméticas e acessos à memória.
- **Dados**: A memória `mem_dados` armazena valores a serem manipulados durante a execução.

#### Processos
1. **Inicialização**:
   O sinal `reset` garante que todos os registradores e sinais sejam zerados antes do início da execução.

2. **Propagação de Instruções**:
   - As instruções são carregadas em `inst_ID` a partir da memória de instruções com base no valor do PC.
   - Os dados são propagados entre os estágios por meio dos registradores de pipeline (e.g., `inst_EX`, `inst_MEM`).

3. **Controle de Desvios**:
   - `desvio` é ativado para instruções de branch (`BEQ`, `BNE`) e `JMP`.
   - Atualização do PC baseada na condição de desvio.

4. **Execução de Operações**:
   - A ULA executa operações aritméticas ou lógicas dependendo do opcode.
   - Multiplicação imediata (“MUI”) e entre registradores (“MUL”) estão incluídas.

5. **Acesso à Memória e Write Back**:
   - `LOAD`, `STORE` e instruções aritméticas são processadas com base em `inst_WB`.

## Configuração e Execução

### Requisitos
- Simulador VHDL (e.g., ModelSim, GHDL).

### Passos para Simulação
1. **Clone o Repositório**:
   ```bash
   git clone <link-do-repositorio>
   ```

2. **Compile o Arquivo VHDL**:
   Certifique-se de incluir as bibliotecas **IEEE** e todas as dependências no ambiente de simulação.
   ```bash
   vcom Proj_Pipeline.vhd
   ```

3. **Configure a Simulação**:
   Defina o clock e reset no testbench. Certifique-se de que as memórias de instrução e dados contêm os valores corretos para o cenário desejado.

4. **Execute a Simulação**:
   Observe os valores propagados entre os estágios e a correção do comportamento em casos de hazards ou desvios.

## Características Implementadas
- Tratamento de hazards de dados por meio de bolhas artificiais.
- Controle de desvios condicionais (`BEQ`, `BNE`) e incondicionais (`JMP`).
- Execução de operações aritméticas e lógicas.
- Manipulação de memórias para instruções de LOAD e STORE.

### Observação
Se você deseja integrar este projeto com o modelo monociclo do repositório, certifique-se de ajustar as memórias e controlar os sinais de clock e reset corretamente.

