# ==========================================================================================
# UFRPE - Universidade Federal Rural de Pernambuco
# Disciplina: Arquitetura e Organizacao de Computadores - 2026.1
# Atividade: Projeto 01 (1a VA) - Assembly MIPS e Simulador MARS
# Grupo: Murilo, Alisson, Otavio
# Arquivo principal do sistema de gerenciamento de restaurante (MOA)
# Descricao: Implementacao do interpretador de comandos (shell), Requisito 1 (Cardapio) 
# e Requisito 2 (Mesas).
# ==========================================================================================

.data
	# --- STRINGS DE INTERFACE ---
	banner:        .asciiz "\nrestaurante-MOA>>"           # Banner padrao do terminal
	input_buffer:  .space 128                             # Buffer para leitura da entrada do usuario
	
	# --- COMANDOS ACEITOS ---
	cmd_cardapio_list: .asciiz "cardapio_list"            # Comando para listar o cardapio
	cmd_cardapio_ad:   .asciiz "cardapio_ad"              # Comando para adicionar item ao cardapio
	cmd_format:        .asciiz "cardapio_format"          # Comando para formatar o cardapio
	cmd_mesa_iniciar:  .asciiz "mesa_iniciar"             # Comando para iniciar atendimento na mesa
	cmd_exit:          .asciiz "exit"                     # Comando para encerrar o programa
	
	# --- MENSAGENS DO SISTEMA ---
	msg_invalid:  .asciiz "Comando invalido\n"                         # Erro genérico
	msg_list_h:   .asciiz "--- ITENS DO CARDAPIO ---\n"                # Cabecalho da lista
	msg_exit:     .asciiz "Encerrando sistema...\n"                    # Mensagem de saida
	msg_add_ok:   .asciiz "Item adicionado com sucesso\n"              # Sucesso R1
	msg_err_id:   .asciiz "Falha: código de item inválido\n"           # Erro R1
	msg_err_dup:  .asciiz "Falha: número de item já cadastrado\n"      # Erro R1
	msg_fmt_ok:   .asciiz "Cardapio formatado com sucesso\n"           # Sucesso format
	msg_mesa_ok:     .asciiz "Atendimento iniciado com sucesso\n"      # Sucesso R2
	msg_err_mesa_oc: .asciiz "Falha: mesa ocupada\n"                   # Erro R2
	msg_err_mesa_in: .asciiz "Falha: mesa inexistente\n"               # Erro R2
	
	# --- ESTRUTURA DE DADOS: R1 (CARDAPIO) ---
	# Arrays para 20 itens. Tamanho 21 usado para que o ID 01 aponte para o indice 1
	precos:      .word 0:21     # Array para guardar os precos em centavos
	descricoes:  .word 0:21     # Array para guardar os ponteiros das strings de descricao
	
	# --- ESTRUTURA DE DADOS: R2 (MESAS) ---
	# Arrays para 15 mesas. Tamanho 16 usado para que o ID 01 aponte para o indice 1
	mesas_status:   .word 0:16  # 0 = desocupada, 1 = ocupada
	mesas_nome:     .word 0:16  # Array de ponteiros para strings dos nomes dos responsaveis
	mesas_telefone: .word 0:16  # Array de ponteiros para strings dos telefones

.text
.globl main

main:
loop:
    # 1. IMPRIMIR BANNER
    li $v0, 4                   # Prepara syscall para imprimir string
    la $a0, banner              # Carrega o endereco do banner
    syscall                     # Executa a impressao

    # 2. LER ENTRADA DO USUARIO
    li $v0, 8                   # Prepara syscall para ler string
    la $a0, input_buffer        # Aponta para o buffer de entrada
    li $a1, 128                 # Define o tamanho maximo de leitura
    syscall                     # Executa a leitura

    # 3. TRATAR STRING (Remover '\n')
    jal remove_newline          # Salta para a funcao que troca \n por \0
    
    # 4. AVALIAR COMANDOS (PARSER)
    
    # TESTE: cardapio_list
    la $a0, input_buffer        # Parametro 1: Entrada do usuario
    la $a1, cmd_cardapio_list   # Parametro 2: String "cardapio_list"
    jal strcmp                  # Compara as duas strings
    beq $v0, $zero, do_list     # Se retorno ($v0) for 0 (iguais), desvia para listagem
    
    # TESTE: cardapio_format
    la $a0, input_buffer        # Parametro 1: Entrada do usuario
    la $a1, cmd_format          # Parametro 2: String "cardapio_format"
    jal strcmp                  # Compara
    beq $v0, $zero, do_format   # Se iguais, desvia para formatacao
    
    # TESTE: exit
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_exit            # Parametro 2: String "exit"
    jal strcmp                  # Compara
    beq $v0, $zero, do_exit     # Se iguais, desvia para encerramento
    
    # TESTE: cardapio_ad (Prefixo de 11 caracteres)
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_cardapio_ad     # Parametro 2: String base
    jal strncmp_11              # Compara apenas os 11 primeiros caracteres
    beq $v0, $zero, do_register # Se o prefixo bater, inicia rotina de cadastro do cardapio
    
    # TESTE: mesa_iniciar (Prefixo de 12 caracteres)
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_mesa_iniciar    # Parametro 2: String base
    jal strncmp_12              # Compara apenas os 12 primeiros caracteres
    beq $v0, $zero, do_mesa_iniciar # Se bater, inicia atendimento
    
    # COMANDO INVALIDO
    li $v0, 4                   # Syscall print string
    la $a0, msg_invalid         # Carrega mensagem de comando nao reconhecido
    syscall                     # Imprime
    j loop                      # Retorna ao inicio do shell

# ==========================================================================================
# ROTINAS DE COMANDOS
# ==========================================================================================

# COMANDO: do_mesa_iniciar (R2 - Iniciar atendimento)
do_mesa_iniciar:
    la $a0, input_buffer        # Carrega buffer
    li $a1, '-'                 # Define caractere separador
    jal find_char               # Busca o 1º hifen
    move $s0, $v0               # Salva endereco do hifen em $s0
    beq $s0, $zero, err_mesa_in # Se nao achar hifen, erro

    # Extrai o Codigo da Mesa
    addi $a0, $s0, 1            # Avanca o ponteiro apos o hifen
    jal str_to_int_2            # Converte as proximas 2 strings para inteiro
    move $s1, $v0               # Salva ID da mesa em $s1

    # Valida ID da mesa (01 a 15)
    li $t8, 1                   # Carrega limite inferior
    blt $s1, $t8, err_mesa_in   # Erro se < 1
    li $t8, 15                  # Carrega limite superior
    bgt $s1, $t8, err_mesa_in   # Erro se > 15

    # Verifica Status da mesa
    sll $t1, $s1, 2             # Multiplica ID por 4 (offset de word)
    lw $t2, mesas_status($t1)   # Le o status no array
    bne $t2, $zero, err_mesa_oc # Se diferente de 0, mesa ja ocupada

    # Busca o 2º hifen (Telefone)
    addi $a0, $s0, 1            # Avanca para comecar nova busca
    li $a1, '-'                 # Carrega hifen
    jal find_char               # Busca hifen
    move $s0, $v0               # Atualiza ponteiro $s0
    addi $s4, $s0, 1            # Salva inicio do telefone em $s4

    # Busca o 3º hifen (Nome)
    addi $a0, $s0, 1            # Avanca
    li $a1, '-'                 # Carrega hifen
    jal find_char               # Busca
    move $s0, $v0               # Atualiza
    addi $s5, $s0, 1            # Salva inicio do nome em $s5

    # Isola a string de telefone
    sb $zero, 0($s0)            # Substitui o 3º hifen por \0

    # Aloca memoria para o telefone
    li $v0, 9                   # Syscall sbrk (aloca heap)
    li $a0, 16                  # Pede 16 bytes
    syscall                     # Executa
    move $s6, $v0               # Salva endereco da memoria do telefone

    # Copia a string do telefone
    move $a0, $s6               # Destino
    move $a1, $s4               # Origem (do buffer)
    jal strcpy                  # Copia

    # Aloca memoria para o nome
    li $v0, 9                   # Syscall sbrk
    li $a0, 64                  # Pede 64 bytes
    syscall                     # Executa
    move $s7, $v0               # Salva endereco da memoria do nome

    # Copia a string do nome
    move $a0, $s7               # Destino
    move $a1, $s5               # Origem (do buffer)
    jal strcpy                  # Copia

    # Salva tudo nas tabelas
    sll $t1, $s1, 2             # Offset da mesa (ID * 4)
    li $t2, 1                   # Status 1 (Ocupada)
    sw $t2, mesas_status($t1)   # Atualiza array status
    sw $s6, mesas_telefone($t1) # Atualiza array de telefones (ponteiro)
    sw $s7, mesas_nome($t1)     # Atualiza array de nomes (ponteiro)

    # Mensagem de sucesso
    li $v0, 4                   # Syscall print string
    la $a0, msg_mesa_ok         # Mensagem de inicio de atendimento
    syscall                     # Executa
    j loop                      # Retorna ao terminal

# COMANDO: do_register (R1 - Cadastro de Item)
do_register:
    la $a0, input_buffer        # Carrega inicio da entrada
    li $a1, '-'                 # Define hifen
    jal find_char               # Busca o 1º hifen
    move $s0, $v0               # Salva posicao
    beq $s0, $zero, err_id      # Se zero, formato errado

    # Extrai Codigo
    addi $a0, $s0, 1            # Aponta para numero (01-20)
    jal str_to_int_2            # Converte 2 digitos para int
    move $s1, $v0               # Salva ID em $s1

    # Valida ID (01 a 20)
    li $t8, 1                   # Limite inferior
    blt $s1, $t8, err_id        # Desvia para erro
    li $t8, 20                  # Limite superior
    bgt $s1, $t8, err_id        # Desvia para erro

    # Verifica se ID ja existe
    sll $t1, $s1, 2             # Calcula offset de memoria (ID * 4)
    lw $t2, descricoes($t1)     # Carrega conteudo daquele indice
    bne $t2, $zero, err_dup     # Se diferente de 0, ja tem dado

    # Extrai Preco
    addi $a0, $s0, 1            # Avanca o ponteiro
    li $a1, '-'                 # Carrega hifen
    jal find_char               # Busca 2º hifen
    move $s0, $v0               # Atualiza posicao
    addi $a0, $s0, 1            # Aponta para o preco
    jal str_to_int_5            # Converte 5 digitos
    move $s2, $v0               # Salva preco convertido em $s2

    # Extrai Descricao
    addi $a0, $s0, 1            # Avanca ponteiro
    li $a1, '-'                 # Carrega hifen
    jal find_char               # Busca 3º hifen
    addi $s0, $v0, 1            # $s0 agora aponta para inicio do texto

    # Aloca memoria para string de descricao
    li $v0, 9                   # Syscall alocacao
    li $a0, 64                  # Reserva 64 bytes
    syscall                     # Executa
    move $s3, $v0               # $s3 recebe ponteiro alocado

    # Copia descricao
    move $a0, $s3               # Parametro destino
    move $a1, $s0               # Parametro origem
    jal strcpy                  # Copia string

    # Grava arrays do Cardapio
    sll $t1, $s1, 2             # Recalcula offset
    sw $s2, precos($t1)         # Grava inteiro do preco
    sw $s3, descricoes($t1)     # Grava ponteiro da descricao

    li $v0, 4                   # Print string
    la $a0, msg_add_ok          # Mensagem de sucesso
    syscall                     # Executa
    j loop                      # Retorna ao menu

# COMANDO: do_list (R1 - Listar Cardapio)
do_list:
    li $v0, 4                   # Print string
    la $a0, msg_list_h          # Imprime cabecalho
    syscall                     # Executa
    li $t0, 1                   # Inicia contador ($t0) em 1
list_l:
    li $t8, 21                  # Limite do loop
    beq $t0, $t8, loop          # Se chegar no 21, volta ao shell
    sll $t1, $t0, 2             # Offset
    lw $t2, descricoes($t1)     # Carrega ponteiro da descricao
    beq $t2, $zero, list_skip   # Se for zero, item vazio, pula

    # Imprime ID
    li $v0, 1                   # Syscall print int
    move $a0, $t0               # Move contador para argumento
    syscall                     # Executa

    # Imprime Espaco
    li $v0, 11                  # Syscall print char
    li $a0, 32                  # ASCII do espaco
    syscall                     # Executa

    # Imprime Preco
    lw $a0, precos($t1)         # Carrega o preco do array
    li $v0, 1                   # Print int
    syscall                     # Executa

    # Imprime Espaco
    li $v0, 11                  # Print char
    li $a0, 32                  # Espaco
    syscall                     # Executa

    # Imprime Descricao
    move $a0, $t2               # Move ponteiro da string
    li $v0, 4                   # Print string
    syscall                     # Executa

    # Imprime Quebra de linha
    li $v0, 11                  # Print char
    li $a0, 10                  # ASCII do \n
    syscall                     # Executa

list_skip:
    addi $t0, $t0, 1            # Incrementa ID
    j list_l                    # Repete loop

# COMANDO: do_format (R1 - Formatar Cardapio)
do_format:
    li $t0, 1                   # Contador inicia em 1
fmt_l:
    li $t8, 21                  # Limite
    beq $t0, $t8, fmt_end       # Fim do loop
    sll $t1, $t0, 2             # Offset
    sw $zero, precos($t1)       # Zera array de precos
    sw $zero, descricoes($t1)   # Zera array de descricoes
    addi $t0, $t0, 1            # Incrementa
    j fmt_l                     # Repete
fmt_end:
    li $v0, 4                   # Print
    la $a0, msg_fmt_ok          # Mensagem de ok
    syscall                     # Executa
    j loop                      # Retorna ao terminal

# ==========================================================================================
# FUNCOES AUXILIARES (STRINGS E CONVERSOES)
# ==========================================================================================

# STRNCMP_11: Compara 11 primeiros bytes
strncmp_11:
    li $t7, 0                   # Zera contador
sn_loop:
    li $t8, 11                  # Limite 11
    beq $t7, $t8, sn_eq         # Se alcançou limite e passou, strings iguais
    lb $t2, 0($a0)              # Carrega byte str1
    lb $t3, 0($a1)              # Carrega byte str2
    bne $t2, $t3, sn_diff       # Se diferentes, desvia
    addi $a0, $a0, 1            # Avanca ponteiro 1
    addi $a1, $a1, 1            # Avanca ponteiro 2
    addi $t7, $t7, 1            # Incrementa contador
    j sn_loop                   # Repete
sn_diff: 
    li $v0, 1                   # Retorna 1 (diferentes)
    jr $ra                      # Volta
sn_eq:  
    li $v0, 0                   # Retorna 0 (iguais)
    jr $ra                      # Volta

# STRNCMP_12: Compara 12 primeiros bytes
strncmp_12:
    li $t7, 0                   # Zera contador
sn12_loop:
    li $t8, 12                  # Limite 12
    beq $t7, $t8, sn12_eq       # Limite atingido, strings iguais
    lb $t2, 0($a0)              # Byte str1
    lb $t3, 0($a1)              # Byte str2
    bne $t2, $t3, sn12_diff     # Se deferente, desvia
    addi $a0, $a0, 1            # Avanca
    addi $a1, $a1, 1            # Avanca
    addi $t7, $t7, 1            # Incrementa
    j sn12_loop                 # Loop
sn12_diff: 
    li $v0, 1                   # Retorna 1
    jr $ra                      # Volta
sn12_eq:  
    li $v0, 0                   # Retorna 0
    jr $ra                      # Volta

# FIND_CHAR: Busca caractere ($a1) na string ($a0)
find_char:
    lb $t4, 0($a0)              # Carrega caractere atual
    beq $t4, $zero, f_err       # Se for \0, encerrou sem achar
    beq $t4, $a1, f_ok          # Se achou caractere alvo
    addi $a0, $a0, 1            # Avanca ponteiro
    j find_char                 # Loop
f_ok:  
    move $v0, $a0               # Retorna endereco onde achou
    jr $ra                      # Volta
f_err: 
    li $v0, 0                   # Retorna 0 (falha)
    jr $ra                      # Volta

# STR_TO_INT_2: Converte string numerica de 2 posicoes
str_to_int_2:
    lb $t4, 0($a0)              # Carrega dezena ASCII
    addi $t4, $t4, -48          # Converte de ASCII para decimal
    li $t5, 10                  # Multiplicador 10
    mul $v0, $t4, $t5           # V0 = Dezena * 10
    lb $t4, 1($a0)              # Carrega unidade ASCII
    addi $t4, $t4, -48          # Converte para decimal
    add $v0, $v0, $t4           # Soma unidade ao total
    jr $ra                      # Volta

# STR_TO_INT_5: Converte string numerica de 5 posicoes
str_to_int_5:
    li $v0, 0                   # Zera acumulador
    li $t7, 0                   # Zera contador
    li $t5, 10                  # Fator de multiplicacao
s5_l:
    beq $t7, 5, s5_e            # Fim apos 5 caracteres
    lb $t4, 0($a0)              # Carrega digito
    addi $t4, $t4, -48          # Converte
    mul $v0, $v0, $t5           # Desloca casa decimal (x10)
    add $v0, $v0, $t4           # Soma digito atual
    addi $a0, $a0, 1            # Avanca string
    addi $t7, $t7, 1            # Avanca contador
    j s5_l                      # Loop
s5_e: 
    jr $ra                      # Retorna inteiro

# STRCMP: Compara duas strings ate o \0
strcmp:
    add $t0, $a0, $zero         # Ponteiro temp 1
strcmp_loop:
    lb $t2, 0($t0)              # Carrega byte 1
    lb $t3, 0($a1)              # Carrega byte 2
    bne $t2, $t3, strcmp_diff   # Verifica diferenca
    beq $t2, $zero, strcmp_equal # Atingiu \0 juntos = iguais
    addi $t0, $t0, 1            # Avanca
    addi $a1, $a1, 1            # Avanca
    j strcmp_loop               # Loop
strcmp_diff: 
    li $v0, 1                   # Retorna 1 (diferentes)
    jr $ra                      # Volta
strcmp_equal: 
    li $v0, 0                   # Retorna 0 (iguais)
    jr $ra                      # Volta

# STRCPY: Copia string da origem ($a1) para destino ($a0)
strcpy:
    lb $t4, 0($a1)              # Carrega byte origem
    sb $t4, 0($a0)              # Grava byte destino
    beq $t4, $zero, stcy_e      # Termina se for \0
    addi $a0, $a0, 1            # Avanca destino
    addi $a1, $a1, 1            # Avanca origem
    j strcpy                    # Loop
stcy_e: 
    jr $ra                      # Volta

# REMOVE_NEWLINE: Troca \n por \0
remove_newline:
    la $t0, input_buffer        # Carrega buffer
remove_loop:
    lb $t1, 0($t0)              # Carrega caractere
    beq $t1, $zero, end_remove  # Chegou no fim da string real
    li $t2, 10                  # Codigo ASCII do \n
    beq $t1, $t2, replace_null  # Se igual, vai substituir
    addi $t0, $t0, 1            # Avanca string
    j remove_loop               # Loop
replace_null: 
    sb $zero, 0($t0)            # Insere \0 no lugar
end_remove: 
    jr $ra                      # Volta

# ==========================================================================================
# TRATAMENTO DE ERROS GENERICOS
# ==========================================================================================
err_id: 
    li $v0, 4                   # Print string
    la $a0, msg_err_id          # Carrega mensagem
    syscall                     # Executa
    j loop                      # Retorna ao terminal
    
err_dup: 
    li $v0, 4                   # Print string
    la $a0, msg_err_dup         # Carrega mensagem
    syscall                     # Executa
    j loop                      # Retorna
    
err_mesa_oc:
    li $v0, 4                   # Print string
    la $a0, msg_err_mesa_oc     # Carrega mensagem (Ocupada)
    syscall                     # Executa
    j loop                      # Retorna
    
err_mesa_in:
    li $v0, 4                   # Print string
    la $a0, msg_err_mesa_in     # Carrega mensagem (ID Invalido)
    syscall                     # Executa
    j loop                      # Retorna
    
do_exit: 
    li $v0, 4                   # Print string
    la $a0, msg_exit            # Mensagem de saida
    syscall                     # Executa
    li $v0, 10                  # Syscall EXIT (encerra programa)
    syscall                     # Executa