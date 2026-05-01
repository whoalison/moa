# 🍽️ Restaurante MOA - Sistema de Gestão (MIPS Assembly)

Este repositório contém a implementação de um sistema de gerenciamento para restaurantes desenvolvido integralmente em **Assembly MIPS**. O projeto faz parte da disciplina de **Arquitetura e Organização de Computadores (2026.1)** da **UFRPE**, sob orientação do Prof. Vítor A. Coutinho.

O sistema opera via interface de linha de comando (CLI/Shell) e gerencia cardápios, mesas, pedidos e pagamentos.

---

## ✅ O que já foi feito (Sprint 1: Cardápio)

### 🛠️ Core & Parser
- **Interface de Terminal Interativo**: Sistema de prompt baseado em loop `restaurante-MOA>>`.
- **Analisador de Comandos (Parser)**: Lógica para processar strings complexas separadas por hifens (`-`) e identificação de prefixos.
- **Rotinas de Conversão**: Implementação de funções para transformar caracteres ASCII em inteiros (essencial para manipulação de Preços e IDs).
- **Gerenciamento de Memória**: Uso de alocação dinâmica (`heap`) via `syscall 9` para persistência das descrições dos itens.

### 📜 Comandos de Cardápio Implementados
- [x] `cardapio_ad-ID-PRECO-DESCRICAO`: Cadastro de itens com validação de ID (01-20), preço (5 dígitos) e duplicidade.
- [x] `cardapio_list`: Listagem formatada e em ordem crescente dos itens cadastrados.
- [x] `cardapio_format`: Reset completo dos dados do cardápio na memória.
- [x] `exit`: Encerramento seguro do simulador.

---

## ⏳ O que falta fazer (Backlog do Projeto)

### 🪑 Gestão de Mesas (Requisitos R2 a R6)
- [ ] **Estrutura de Dados das Mesas**: Criar blocos de memória para gerenciar 15 mesas simultâneas.
- [ ] **Comando `mesa_iniciar`**: Registro de ocupação com nome do responsável e telefone.
- [ ] **Comando `mesa_ad_item`**: Vínculo entre itens do cardápio e o consumo de cada mesa.
- [ ] **Comando `mesa_pagar`**: Lógica de abatimento de saldo devedor através de pagamentos parciais.
- [ ] **Comando `mesa_fechar`**: Validação de quitação de débitos e liberação da mesa (status "Desocupada").

### 💾 Persistência e Arquivos (Requisito R7)
- [ ] **Comando `salvar`**: Exportação dos dados da memória para arquivo externo via `syscall`.
- [ ] **Comando `recarregar`**: Importação automática de dados salvos ao iniciar o sistema.

### 🎯 Pontos Extras & Refinamentos
- [ ] **Interface MMIO**: Migração das chamadas de sistema para o simulador *Keyboard and Display MMIO* (**+1.0 ponto extra**).
- [ ] **Formatação de Moeda**: Implementar a exibição de preços com vírgula (centavos).

---

## 🚀 Como Executar

1. Utilize o simulador **MARS 4.5**.
2. Clone o repositório: 
   ```bash
   git clone https://github.com
   ```
3. Abra o código fonte `.asm` no MARS.
4. Monte o código (**F3**) e execute (**F5**).
5. Digite comandos no console conforme o padrão:
   - *Exemplo:* `cardapio_ad-15-00490-Coca Cola`

---

## 👥 Integrantes
- **Alison**
- **Otávio** 
- **Murilo** 

---
> **Aviso:** Este projeto segue as instruções do Projeto 01 de AOC 2026.1 - UFRPE.
