# ==========================================================================================
# UFRPE - Universidade Federal Rural de Pernambuco
# Disciplina: Arquitetura e Organizacao de Computadores - 2026.1
# Atividade: Projeto 01 (1a VA) - Assembly MIPS e Simulador MARS
# Grupo: Murilo, Alisson, Otavio
# Arquivo principal do sistema de gerenciamento de restaurante (MOA)
# Descricao: Interpretador de comandos (shell) implementando os Requisitos de 1 a 4.
# ==========================================================================================

.data
	# --- STRINGS DE INTERFACE ---
	banner:        .asciiz "\nrestaurante-MOA>>"                  # Banner padrao impresso a cada linha
	input_buffer:  .space 128                                    # Buffer de 128 bytes para ler os comandos do usuario
	
	# --- COMANDOS ACEITOS PELO SISTEMA ---
	cmd_cardapio_list: .asciiz "cardapio_list"                   # Comando R1: Lista itens
	cmd_cardapio_ad:   .asciiz "cardapio_ad"                     # Comando R1: Adiciona item no cardapio
	cmd_format:        .asciiz "cardapio_format"                 # Comando R1: Apaga cardapio
	cmd_mesa_iniciar:  .asciiz "mesa_iniciar"                    # Comando R2: Abre atendimento
	cmd_mesa_ad_item:  .asciiz "mesa_ad_item"                    # Comando R3: Adiciona pedido na conta
	cmd_mesa_rm_item:  .asciiz "mesa_rm_item"                    # Comando R3: Remove pedido da conta
	cmd_mesa_pagar:    .asciiz "mesa_pagar"                      # Comando R4: Paga valor parcial
	cmd_exit:          .asciiz "exit"                            # Comando: Encerra o interpretador
	
	# --- MENSAGENS DE SUCESSO E ERRO ---
	msg_invalid:  .asciiz "Comando invalido\n"                         # Erro padrao do shell
	msg_list_h:   .asciiz "--- ITENS DO CARDAPIO ---\n"                # Cabecalho R1
	msg_exit:     .asciiz "Encerrando sistema...\n"                    # Saida
	
	msg_add_ok:   .asciiz "Item adicionado com sucesso\n"              # R1 Sucesso
	msg_err_id:   .asciiz "Falha: código de item inválido\n"           # R1 Erro
	msg_err_dup:  .asciiz "Falha: número de item já cadastrado\n"      # R1 Erro
	msg_fmt_ok:   .asciiz "Cardapio formatado com sucesso\n"           # R1 Sucesso
	
	msg_mesa_ok:     .asciiz "Atendimento iniciado com sucesso\n"      # R2 Sucesso
	msg_err_mesa_oc: .asciiz "Falha: mesa ocupada\n"                   # R2 Erro
	msg_err_mesa_in: .asciiz "Falha: mesa inexistente\n"               # R2/R3/R4 Erro
	
	msg_mesa_ad_ok:         .asciiz "Item adicionado com sucesso\n"              # R3 Sucesso
	msg_mesa_rm_ok:         .asciiz "Item removido com sucesso\n"                # R3 Sucesso
	msg_err_mesa_vazia:     .asciiz "Falha: mesa nao iniciou atendimento\n"      # R3/R4 Erro
	msg_err_item_in:        .asciiz "Falha: codigo do item invalido\n"           # R3 Erro
	msg_err_item_nc:        .asciiz "Falha: item não cadastrado no cardápio\n"   # R3 Erro
	msg_err_item_nao_conta: .asciiz "Falha: item nao consta na conta\n"          # R3 Erro
	
	msg_pagamento_ok:       .asciiz "Pagamento realizado com sucesso\n"          # R4 Sucesso
	
	# --- ESTRUTURAS DE DADOS (MEMORIA) ---
	# R1 (Cardapio): Arrays para 20 itens. (Tamanho 21 para ID 1 = Indice 1)
	precos:      .word 0:21     # Array de inteiros para guardar precos em centavos
	descricoes:  .word 0:21     # Array de ponteiros para as strings de descricao na heap
	
	# R2 (Mesas): Arrays para 15 mesas. (Tamanho 16 para ID 1 = Indice 1)
	mesas_status:   .word 0:16  # Inteiros: 0 = desocupada, 1 = ocupada
	mesas_nome:     .word 0:16  # Ponteiros para as strings dos nomes na heap
	mesas_telefone: .word 0:16  # Ponteiros para as strings dos telefones na heap

	# R3 (Pedidos): Matriz 16x21. Indice = (ID_Mesa * 21) + ID_Item
	mesas_pedidos_qtd: .word 0:336 # Contadores de quantidade de cada pedido

	# R4 (Pagamento): Array para 15 mesas registrando o valor pago
	mesas_pago:     .word 0:16  # Inteiros com o valor parcial ja pago em centavos

.text
.globl main

# ==========================================================================================
# LOOP PRINCIPAL DO SHELL (INTERPRETADOR DE COMANDOS)
# ==========================================================================================
main:
loop:
    # 1. IMPRIMIR BANNER
    li $v0, 4                       # Syscall 4: print string
    la $a0, banner                  # Carrega endereco do banner ("restaurante-MOA>>")
    syscall                         # Imprime no console

    # 2. LER COMANDO DO USUARIO
    li $v0, 8                       # Syscall 8: read string
    la $a0, input_buffer            # Carrega endereco do buffer de destino
    li $a1, 128                     # Limite de 128 bytes
    syscall                         # Aguarda usuario digitar e dar enter

    # 3. HIGIENIZAR STRING
    jal remove_newline              # Chama funcao que troca '\n' por '\0'
    
    # 4. AVALIAR COMANDOS (PARSER)
    
    # R1: TESTE cardapio_list
    la $a0, input_buffer            # Argumento 1: string digitada
    la $a1, cmd_cardapio_list       # Argumento 2: comando alvo
    jal strcmp                      # Compara strings completas
    beq $v0, $zero, do_list         # Se iguais ($v0 = 0), desvia pra rotina
    
    # R1: TESTE cardapio_format
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_format              # Parametro 2
    jal strcmp                      # Compara
    beq $v0, $zero, do_format       # Se iguais, formata
    
    # SISTEMA: TESTE exit
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_exit                # Parametro 2
    jal strcmp                      # Compara
    beq $v0, $zero, do_exit         # Se iguais, encerra
    
    # R1: TESTE cardapio_ad (Prefixo de 11 caracteres)
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_cardapio_ad         # Parametro 2
    jal strncmp_11                  # Compara os 11 primeiros bytes
    beq $v0, $zero, do_register     # Se prefixo bater, adiciona item no cardapio
    
    # R2: TESTE mesa_iniciar (Prefixo de 12 caracteres)
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_mesa_iniciar        # Parametro 2
    jal strncmp_12                  # Compara os 12 primeiros bytes
    beq $v0, $zero, do_mesa_iniciar # Se bater, abre mesa

    # R3: TESTE mesa_ad_item (Prefixo de 12 caracteres)
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_mesa_ad_item        # Parametro 2
    jal strncmp_12                  # Compara 12 bytes
    beq $v0, $zero, do_mesa_ad_item # Se bater, adiciona pedido

    # R3: TESTE mesa_rm_item (Prefixo de 12 caracteres)
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_mesa_rm_item        # Parametro 2
    jal strncmp_12                  # Compara 12 bytes
    beq $v0, $zero, do_mesa_rm_item # Se bater, remove pedido
    
    # R4: TESTE mesa_pagar (Prefixo de 10 caracteres)
    la $a0, input_buffer            # Parametro 1
    la $a1, cmd_mesa_pagar          # Parametro 2
    jal strncmp_10                  # Compara os 10 primeiros bytes
    beq $v0, $zero, do_mesa_pagar   # Se bater, registra pagamento parcial
    
    # FALLBACK: COMANDO INVALIDO
    li $v0, 4                       # Syscall print
    la $a0, msg_invalid             # Mensagem "Comando invalido"
    syscall                         # Imprime
    j loop                          # Volta ao loop

# ==========================================================================================
# ROTINAS DE COMANDOS (R1, R2, R3 e R4)
# ==========================================================================================

# ----------------- R4: PAGAMENTO PARCIAL -----------------
do_mesa_pagar:
    la $a0, input_buffer            # Carrega buffer
    li $a1, '-'                     # Hifen separador
    jal find_char                   # Busca hifen
    move $s0, $v0                   # Salva endereco do hifen
    beq $s0, $zero, err_mesa_in     # Erro se nao formatado corretamente

    addi $a0, $s0, 1                # Ponteiro apos 1o hifen (ID da mesa)
    jal str_to_int_2                # Converte os 2 digitos pra int
    move $s1, $v0                   # Salva ID em $s1
    
    li $t8, 1                       # Valida limite minimo (1)
    blt $s1, $t8, err_mesa_in       # Erro se menor
    li $t8, 15                      # Valida limite maximo (15)
    bgt $s1, $t8, err_mesa_in       # Erro se maior

    sll $t1, $s1, 2                 # Offset = ID Mesa * 4 bytes
    lw $t2, mesas_status($t1)       # Carrega status da mesa
    beq $t2, $zero, err_mesa_vazia  # Erro se status for 0 (fechada)

    addi $a0, $s0, 1                # Ajusta ponteiro para buscar proximo dado
    li $a1, '-'                     # Caractere hifen
    jal find_char                   # Busca 2o hifen
    move $s0, $v0                   # Atualiza ponteiro do hifen
    addi $a0, $s0, 1                # Aponta para logo apos o 2o hifen (valor)
    jal str_to_int_6                # Converte os 6 digitos dos centavos para int
    move $s2, $v0                   # Salva valor do pagamento em $s2

    sll $t1, $s1, 2                 # Recalcula offset da mesa (x4 bytes)
    lw $t2, mesas_pago($t1)         # Carrega o valor parcial ja pago por esta mesa (se houver)
    add $t2, $t2, $s2               # Soma o pagamento novo com o saldo pago existente
    sw $t2, mesas_pago($t1)         # Atualiza a variavel do R4 na memoria

    li $v0, 4                       # Syscall print string
    la $a0, msg_pagamento_ok        # Mensagem "Pagamento realizado"
    syscall                         # Executa
    j loop                          # Volta ao shell

# ----------------- R2: INICIAR MESA -----------------
do_mesa_iniciar:
    la $a0, input_buffer            # Carrega buffer
    li $a1, '-'                     # Hifen separador
    jal find_char                   # Busca hifen
    move $s0, $v0                   # Salva posicao
    beq $s0, $zero, err_mesa_in     # Erro se mal formatado

    addi $a0, $s0, 1                # Aponta pro ID da mesa
    jal str_to_int_2                # Converte 2 bytes pra int
    move $s1, $v0                   # ID da mesa em $s1

    li $t8, 1                       # Minimo aceito
    blt $s1, $t8, err_mesa_in       # Desvio
    li $t8, 15                      # Maximo aceito
    bgt $s1, $t8, err_mesa_in       # Desvio

    sll $t1, $s1, 2                 # Offset em bytes
    lw $t2, mesas_status($t1)       # Verifica status atual
    bne $t2, $zero, err_mesa_oc     # Erro se ocupada (!= 0)

    addi $a0, $s0, 1                # Busca 2o hifen (Telefone)
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $s4, $s0, 1                # Salva ponteiro do telefone em $s4

    addi $a0, $s0, 1                # Busca 3o hifen (Nome)
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $s5, $s0, 1                # Salva ponteiro do nome em $s5

    sb $zero, 0($s0)                # Isola string do telefone trocando hifen por \0

    li $v0, 9                       # Syscall 9: aloca memoria
    li $a0, 16                      # Pede 16 bytes pra telefone
    syscall                         
    move $s6, $v0                   # Guarda ponteiro alocado

    move $a0, $s6                   # Copia telefone pra heap
    move $a1, $s4                   
    jal strcpy                      

    li $v0, 9                       # Syscall 9: aloca memoria
    li $a0, 64                      # Pede 64 bytes pro nome
    syscall                         
    move $s7, $v0                   # Guarda ponteiro alocado

    move $a0, $s7                   # Copia nome pra heap
    move $a1, $s5                   
    jal strcpy                      

    sll $t1, $s1, 2                 # Recalcula offset
    li $t2, 1                       # Valor 1 = ocupado
    sw $t2, mesas_status($t1)       # Atualiza status
    sw $s6, mesas_telefone($t1)     # Salva ponteiro do telefone no array
    sw $s7, mesas_nome($t1)         # Salva ponteiro do nome no array
    sw $zero, mesas_pago($t1)       # Zera o saldo pago (R4) para nova mesa

    li $v0, 4                       # Syscall print
    la $a0, msg_mesa_ok             # Mensagem de sucesso R2
    syscall                         
    j loop                          

# ----------------- R3: ADICIONAR ITEM NA MESA -----------------
do_mesa_ad_item:
    la $a0, input_buffer            # Carrega entrada
    li $a1, '-'                     
    jal find_char                   # Busca 1o hifen
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     

    addi $a0, $s0, 1                # Pega ID da mesa
    jal str_to_int_2                
    move $s1, $v0                   
    
    li $t8, 1                       # Valida limite
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 # Checa se mesa ta ocupada
    lw $t2, mesas_status($t1)       
    beq $t2, $zero, err_mesa_vazia  # Erro se fechada

    addi $a0, $s0, 1                # Busca 2o hifen
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                # Pega ID do item
    jal str_to_int_2                
    move $s2, $v0                   

    li $t8, 1                       # Valida limite do item
    blt $s2, $t8, err_item_in       
    li $t8, 20                      
    bgt $s2, $t8, err_item_in       

    sll $t1, $s2, 2                 # Checa no R1 se tem descricao cadastrada
    lw $t2, descricoes($t1)         
    beq $t2, $zero, err_item_nc     # Erro se nulo

    li $t3, 21                      # Tamanho da linha da matriz (R3)
    mul $t1, $s1, $t3               # Mesa * 21
    add $t1, $t1, $s2               # + ID do Item
    sll $t1, $t1, 2                 # Converte pra bytes (x4)

    lw $t2, mesas_pedidos_qtd($t1)  # Le contador atual do item
    addi $t2, $t2, 1                # Adiciona +1 ao pedido
    sw $t2, mesas_pedidos_qtd($t1)  # Salva atualizacao

    li $v0, 4                       # Syscall print
    la $a0, msg_mesa_ad_ok          # Sucesso
    syscall                         
    j loop                          

# ----------------- R3: REMOVER ITEM DA MESA -----------------
do_mesa_rm_item:
    la $a0, input_buffer            # Carrega buffer
    li $a1, '-'                     
    jal find_char                   # Acha 1o hifen
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     

    addi $a0, $s0, 1                # Le ID da mesa
    jal str_to_int_2                
    move $s1, $v0                   
    
    li $t8, 1                       
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 # Verifica status da mesa
    lw $t2, mesas_status($t1)       
    beq $t2, $zero, err_mesa_vazia  

    addi $a0, $s0, 1                # Acha 2o hifen
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                # Le ID do item
    jal str_to_int_2                
    move $s2, $v0                   

    li $t8, 1                       
    blt $s2, $t8, err_item_in       
    li $t8, 20                      
    bgt $s2, $t8, err_item_in       

    li $t3, 21                      # Calcula offset na matriz
    mul $t1, $s1, $t3               
    add $t1, $t1, $s2               
    sll $t1, $t1, 2                 

    lw $t2, mesas_pedidos_qtd($t1)     # Carrega qtd atual pedida
    beq $t2, $zero, err_item_nao_conta # Se qtd for 0, nao tem o que remover

    addi $t2, $t2, -1               # Reduz 1 no contador do R3
    sw $t2, mesas_pedidos_qtd($t1)  # Salva

    li $v0, 4                       
    la $a0, msg_mesa_rm_ok          
    syscall                         
    j loop                          

# ----------------- R1: CARDAPIO (ADICIONAR) -----------------
do_register:
    la $a0, input_buffer            
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_id          

    addi $a0, $s0, 1                # ID
    jal str_to_int_2                
    move $s1, $v0                   

    li $t8, 1                       
    blt $s1, $t8, err_id            
    li $t8, 20                      
    bgt $s1, $t8, err_id            

    sll $t1, $s1, 2                 # Checa se ta ocupado no R1
    lw $t2, descricoes($t1)         
    bne $t2, $zero, err_dup         

    addi $a0, $s0, 1                # Preco
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                
    jal str_to_int_5                
    move $s2, $v0                   

    addi $a0, $s0, 1                # Descricao
    li $a1, '-'                     
    jal find_char                   
    addi $s0, $v0, 1                

    li $v0, 9                       # Aloca memoria
    li $a0, 64                      
    syscall                         
    move $s3, $v0                   

    move $a0, $s3                   # Copia string
    move $a1, $s0                   
    jal strcpy                      

    sll $t1, $s1, 2                 # Atualiza cardapio
    sw $s2, precos($t1)             
    sw $s3, descricoes($t1)         

    li $v0, 4                       
    la $a0, msg_add_ok              
    syscall                         
    j loop                          

# ----------------- R1: CARDAPIO (LISTAR) -----------------
do_list:
    li $v0, 4                       
    la $a0, msg_list_h              
    syscall                         
    li $t0, 1                       # Contador = 1
list_l:
    li $t8, 21                      
    beq $t0, $t8, loop              # Sai do loop em 21
    sll $t1, $t0, 2                 
    lw $t2, descricoes($t1)         
    beq $t2, $zero, list_skip       # Pula se nulo

    li $v0, 1                       # Print ID
    move $a0, $t0                   
    syscall                         

    li $v0, 11                      # Espaco
    li $a0, 32                      
    syscall                         

    lw $a0, precos($t1)             # Print Preco
    li $v0, 1                       
    syscall                         

    li $v0, 11                      # Espaco
    li $a0, 32                      
    syscall                         

    move $a0, $t2                   # Print Descricao
    li $v0, 4                       
    syscall                         

    li $v0, 11                      # Quebra linha
    li $a0, 10                      
    syscall                         

list_skip:
    addi $t0, $t0, 1                
    j list_l                        

# ----------------- R1: CARDAPIO (FORMATAR) -----------------
do_format:
    li $t0, 1                       
fmt_l:
    li $t8, 21                      
    beq $t0, $t8, fmt_end           
    sll $t1, $t0, 2                 
    sw $zero, precos($t1)           # Zera preco
    sw $zero, descricoes($t1)       # Zera ponteiro descricao
    addi $t0, $t0, 1                
    j fmt_l                         
fmt_end:
    li $v0, 4                       
    la $a0, msg_fmt_ok              
    syscall                         
    j loop                          

# ==========================================================================================
# FUNCOES AUXILIARES (MANIPULACAO DE STRINGS E CONVERSOES)
# ==========================================================================================

# STRNCMP_10: Compara 10 bytes (Usado no R4)
strncmp_10:
    li $t7, 0                       
sn10_loop:
    li $t8, 10                      
    beq $t7, $t8, sn10_eq           
    lb $t2, 0($a0)                  
    lb $t3, 0($a1)                  
    bne $t2, $t3, sn10_diff         
    addi $a0, $a0, 1                
    addi $a1, $a1, 1                
    addi $t7, $t7, 1                
    j sn10_loop                     
sn10_diff: 
    li $v0, 1                       
    jr $ra                          
sn10_eq:  
    li $v0, 0                       
    jr $ra                          

# STRNCMP_11: Compara 11 bytes (Usado no R1)
strncmp_11:
    li $t7, 0                       
sn_loop:
    li $t8, 11                      
    beq $t7, $t8, sn_eq             
    lb $t2, 0($a0)                  
    lb $t3, 0($a1)                  
    bne $t2, $t3, sn_diff           
    addi $a0, $a0, 1                
    addi $a1, $a1, 1                
    addi $t7, $t7, 1                
    j sn_loop                       
sn_diff: 
    li $v0, 1                       
    jr $ra                          
sn_eq:  
    li $v0, 0                       
    jr $ra                          

# STRNCMP_12: Compara 12 bytes (Usado no R2 e R3)
strncmp_12:
    li $t7, 0                       
sn12_loop:
    li $t8, 12                      
    beq $t7, $t8, sn12_eq           
    lb $t2, 0($a0)                  
    lb $t3, 0($a1)                  
    bne $t2, $t3, sn12_diff         
    addi $a0, $a0, 1                
    addi $a1, $a1, 1                
    addi $t7, $t7, 1                
    j sn12_loop                     
sn12_diff: 
    li $v0, 1                       
    jr $ra                          
sn12_eq:  
    li $v0, 0                       
    jr $ra                          

# FIND_CHAR: Procura caractere (hifen)
find_char:
    lb $t4, 0($a0)                  
    beq $t4, $zero, f_err           
    beq $t4, $a1, f_ok              
    addi $a0, $a0, 1                
    j find_char                     
f_ok:  
    move $v0, $a0                   
    jr $ra                          
f_err: 
    li $v0, 0                       
    jr $ra                          

# STR_TO_INT_2: Converte 2 digitos ASCII para inteiro
str_to_int_2:
    lb $t4, 0($a0)                  
    addi $t4, $t4, -48              
    li $t5, 10                      
    mul $v0, $t4, $t5               
    lb $t4, 1($a0)                  
    addi $t4, $t4, -48              
    add $v0, $v0, $t4               
    jr $ra                          

# STR_TO_INT_5: Converte 5 digitos ASCII para inteiro
str_to_int_5:
    li $v0, 0                       
    li $t7, 0                       
    li $t5, 10                      
s5_l:
    beq $t7, 5, s5_e                
    lb $t4, 0($a0)                  
    addi $t4, $t4, -48              
    mul $v0, $v0, $t5               
    add $v0, $v0, $t4               
    addi $a0, $a0, 1                
    addi $t7, $t7, 1                
    j s5_l                          
s5_e: 
    jr $ra                          

# STR_TO_INT_6: Converte 6 digitos ASCII para inteiro (R4)
str_to_int_6:
    li $v0, 0                       
    li $t7, 0                       
    li $t5, 10                      
s6_l:
    beq $t7, 6, s6_e                
    lb $t4, 0($a0)                  
    addi $t4, $t4, -48              
    mul $v0, $v0, $t5               
    add $v0, $v0, $t4               
    addi $a0, $a0, 1                
    addi $t7, $t7, 1                
    j s6_l                          
s6_e: 
    jr $ra                          

# STRCMP: Compara duas strings ate o '\0'
strcmp:
    add $t0, $a0, $zero             
strcmp_loop:
    lb $t2, 0($t0)                  
    lb $t3, 0($a1)                  
    bne $t2, $t3, strcmp_diff       
    beq $t2, $zero, strcmp_equal    
    addi $t0, $t0, 1                
    addi $a1, $a1, 1                
    j strcmp_loop                   
strcmp_diff: 
    li $v0, 1                       
    jr $ra                          
strcmp_equal: 
    li $v0, 0                       
    jr $ra                          

# STRCPY: Copia string da origem pro destino na heap
strcpy:
    lb $t4, 0($a1)                  
    sb $t4, 0($a0)                  
    beq $t4, $zero, stcy_e          
    addi $a0, $a0, 1                
    addi $a1, $a1, 1                
    j strcpy                        
stcy_e: 
    jr $ra                          

# REMOVE_NEWLINE: Limpa a string trocando '\n' por '\0'
remove_newline:
    la $t0, input_buffer            
remove_loop:
    lb $t1, 0($t0)                  
    beq $t1, $zero, end_remove      
    li $t2, 10                      # ASCII do \n
    beq $t1, $t2, replace_null      
    addi $t0, $t0, 1                
    j remove_loop                   
replace_null: 
    sb $zero, 0($t0)                
end_remove: 
    jr $ra                          

# ==========================================================================================
# TRATAMENTO DE ERROS GENERICOS E ESPECIFICOS
# ==========================================================================================
err_id: 
    li $v0, 4                   
    la $a0, msg_err_id          
    syscall                     
    j loop                      
    
err_dup: 
    li $v0, 4                   
    la $a0, msg_err_dup         
    syscall                     
    j loop                      
    
err_mesa_oc:
    li $v0, 4                   
    la $a0, msg_err_mesa_oc     
    syscall                     
    j loop                      
    
err_mesa_in:
    li $v0, 4                   
    la $a0, msg_err_mesa_in     
    syscall                     
    j loop                      

err_mesa_vazia:
    li $v0, 4                   
    la $a0, msg_err_mesa_vazia  
    syscall                     
    j loop                      
    
err_item_in:
    li $v0, 4                   
    la $a0, msg_err_item_in     
    syscall                     
    j loop                      

err_item_nc:
    li $v0, 4                   
    la $a0, msg_err_item_nc     
    syscall                     
    j loop                      
    
err_item_nao_conta:
    li $v0, 4                   
    la $a0, msg_err_item_nao_conta 
    syscall                     
    j loop                      
    
do_exit: 
    li $v0, 4                   
    la $a0, msg_exit            
    syscall                     
    li $v0, 10                  
    syscall