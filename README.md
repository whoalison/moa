# moa
Projeto de arquitetura e organização de computadores

INTRODUÇÃO 
MOA projeto que tem como objetivo a implementação de um sistema de gerenciamento de restaurante operado via terminal interativo, desenvolvido em Assembly MIPS (utilizando o simulador MARS). A aplicação funciona como um interpretador de comandos em modo texto (shell), sendo capaz de processar entradas do usuário continuamente e executar operações relacionadas ao gerenciamento de cardápio, mesas e pedidos.
Simular um sistema real de restaurante em baixo nível
Praticar manipulação de memória, strings e controle de fluxo em Assembly
Implementar um interpretador de comandos (shell)
Utilizar chamadas de sistema (syscalls) para entrada/saída e manipulação de arquivos
Explorar comunicação MMIO (Memory-Mapped I/O)


VISÃO GERAL 

Plataforma : Simulador MARS (Assembly MIPS).
Interface : Terminal via Syscall (padrão) ou MMIO (Teclado/Display).
Persistência : Os dados devem ser salvos e carregados de um arquivo externo automaticamente.

ESTRUTURA DE MEMÓRIA 
__________
Cardápio : 
20 itens
Código, preço e descrição
_________
Mesas :
15 mesas
Código, status, nome, telefone, pedidos
_________
Pedidos :
20 tipos
código item, quantidade

