# ==========================================================================================
# UFRPE - Universidade Federal Rural de Pernambuco
# Disciplina: Arquitetura e Organizacao de Computadores - 2026.1
# Atividade: Projeto 01 (1a VA) - Assembly MIPS e Simulador MARS
# Grupo: Murilo, Alisson, Otavio
# Descricao: Sistema MOA completo (Requisitos 1 ao 5 - Cardapio, Mesas, Pedidos, Pagamento e Relatorio)
# ==========================================================================================

.data
	# --- STRINGS DE INTERFACE ---
	banner:        .asciiz "\nrestaurante-MOA>>"                  # Banner impresso a cada linha
	input_buffer:  .space 128                                    # Buffer para ler os comandos do usuario
	
	# --- COMANDOS ACEITOS ---
	cmd_cardapio_list: .asciiz "cardapio_list"                   # Comando R1: Lista itens
	cmd_cardapio_ad:   .asciiz "cardapio_ad"                     # Comando R1: Adiciona item
	cmd_format:        .asciiz "cardapio_format"                 # Comando R1: Apaga cardapio
	cmd_mesa_iniciar:  .asciiz "mesa_iniciar"                    # Comando R2: Abre mesa
	cmd_mesa_ad_item:  .asciiz "mesa_ad_item"                    # Comando R3: Adiciona pedido
	cmd_mesa_rm_item:  .asciiz "mesa_rm_item"                    # Comando R3: Remove pedido
	cmd_mesa_pagar:    .asciiz "mesa_pagar"                      # Comando R4: Paga valor parcial
	cmd_mesa_parcial:  .asciiz "mesa_parcial"                    # Comando R5: Relatorio da conta
	cmd_exit:          .asciiz "exit"                            # Comando: Encerra o sistema
	
	# --- MENSAGENS DE SISTEMA ---
	msg_invalid:  .asciiz "Comando invalido\n"                         # Erro padrao
	msg_list_h:   .asciiz "--- ITENS DO CARDAPIO ---\n"                # Cabecalho R1
	msg_exit:     .asciiz "Encerrando sistema...\n"                    # Saida
	
	msg_add_ok:   .asciiz "Item adicionado com sucesso\n"              # R1 Sucesso
	msg_err_id:   .asciiz "Falha: código de item inválido\n"           # R1 Erro
	msg_err_dup:  .asciiz "Falha: número de item já cadastrado\n"      # R1 Erro
	msg_fmt_ok:   .asciiz "Cardapio formatado com sucesso\n"           # R1 Sucesso
	
	msg_mesa_ok:     .asciiz "Atendimento iniciado com sucesso\n"      # R2 Sucesso
	msg_err_mesa_oc: .asciiz "Falha: mesa ocupada\n"                   # R2 Erro
	msg_err_mesa_in: .asciiz "Falha: mesa inexistente\n"               # R2/R3/R4/R5 Erro
	
	msg_mesa_ad_ok:         .asciiz "Item adicionado com sucesso\n"              # R3 Sucesso
	msg_mesa_rm_ok:         .asciiz "Item removido com sucesso\n"                # R3 Sucesso
	msg_err_mesa_vazia:     .asciiz "Falha: mesa nao iniciou atendimento\n"      # R3/R4/R5 Erro
	msg_err_item_in:        .asciiz "Falha: codigo do item invalido\n"           # R3 Erro
	msg_err_item_nc:        .asciiz "Falha: item não cadastrado no cardápio\n"   # R3 Erro
	msg_err_item_nao_conta: .asciiz "Falha: item nao consta na conta\n"          # R3 Erro
	
	msg_pagamento_ok:       .asciiz "Pagamento realizado com sucesso\n"          # R4 Sucesso

	# --- STRINGS DO RELATORIO (R5) ---
	msg_rel_h1:       .asciiz "\n--- RELATORIO MESA "
	msg_rel_h2:       .asciiz " ---\n"
	msg_rel_item:     .asciiz "x "
	msg_rel_traco:    .asciiz " - R$ "
	msg_rel_total:    .asciiz "----------------------\nTotal Consumido: R$ "
	msg_rel_pago:     .asciiz "\nValor ja Pago:   R$ "
	msg_rel_dev:      .asciiz "\nSaldo Devedor:   R$ "
	msg_rel_fim:      .asciiz "\n----------------------\n"
	
	# --- ESTRUTURAS DE DADOS (MEMORIA) ---
	# R1 (Cardapio)
	precos:      .word 0:21     # Array de inteiros para precos em centavos
	descricoes:  .word 0:21     # Array de ponteiros para as descricoes
	
	# R2 (Mesas)
	mesas_status:   .word 0:16  # Inteiros: 0 = desocupada, 1 = ocupada
	mesas_nome:     .word 0:16  # Ponteiros para os nomes
	mesas_telefone: .word 0:16  # Ponteiros para os telefones

	# R3 (Pedidos)
	mesas_pedidos_qtd: .word 0:336 # Matriz 16x21. Indice = (ID_Mesa * 21) + ID_Item

	# R4 (Pagamento)
	mesas_pago:     .word 0:16  # Inteiros com o valor parcial pago em centavos

.text
.globl main

# ==========================================================================================
# LOOP PRINCIPAL DO SHELL (PARSER)
# ==========================================================================================
main:
loop:
    li $v0, 4                       # Syscall print string
    la $a0, banner                  # Carrega banner
    syscall                         # Imprime

    li $v0, 8                       # Syscall read string
    la $a0, input_buffer            # Buffer
    li $a1, 128                     # Maximo 128 bytes
    syscall                         

    jal remove_newline              # Limpa '\n'
    
    # R1: TESTE cardapio_list
    la $a0, input_buffer            
    la $a1, cmd_cardapio_list       
    jal strcmp                      
    beq $v0, $zero, do_list         
    
    # R1: TESTE cardapio_format
    la $a0, input_buffer            
    la $a1, cmd_format              
    jal strcmp                      
    beq $v0, $zero, do_format       
    
    # SISTEMA: TESTE exit
    la $a0, input_buffer            
    la $a1, cmd_exit                
    jal strcmp                      
    beq $v0, $zero, do_exit         
    
    # R1: TESTE cardapio_ad (11 char)
    la $a0, input_buffer            
    la $a1, cmd_cardapio_ad         
    jal strncmp_11                  
    beq $v0, $zero, do_register     
    
    # R2: TESTE mesa_iniciar (12 char)
    la $a0, input_buffer            
    la $a1, cmd_mesa_iniciar        
    jal strncmp_12                  
    beq $v0, $zero, do_mesa_iniciar 

    # R3: TESTE mesa_ad_item (12 char)
    la $a0, input_buffer            
    la $a1, cmd_mesa_ad_item        
    jal strncmp_12                  
    beq $v0, $zero, do_mesa_ad_item 

    # R3: TESTE mesa_rm_item (12 char)
    la $a0, input_buffer            
    la $a1, cmd_mesa_rm_item        
    jal strncmp_12                  
    beq $v0, $zero, do_mesa_rm_item 
    
    # R4: TESTE mesa_pagar (10 char)
    la $a0, input_buffer            
    la $a1, cmd_mesa_pagar          
    jal strncmp_10                  
    beq $v0, $zero, do_mesa_pagar   

    # R5: TESTE mesa_parcial (12 char)
    la $a0, input_buffer            
    la $a1, cmd_mesa_parcial        
    jal strncmp_12                  
    beq $v0, $zero, do_mesa_parcial 
    
    # COMANDO INVALIDO
    li $v0, 4                       
    la $a0, msg_invalid             
    syscall                         
    j loop                          

# ==========================================================================================
# ROTINAS DE COMANDOS
# ==========================================================================================

# ----------------- R5: RELATORIO PARCIAL -----------------
do_mesa_parcial:
    la $a0, input_buffer            # Carrega buffer
    li $a1, '-'                     # Hifen separador
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     # Erro de formatacao

    addi $a0, $s0, 1                # ID mesa
    jal str_to_int_2                
    move $s1, $v0                   
    
    li $t8, 1                       
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 # Offset
    lw $t2, mesas_status($t1)       # Status
    beq $t2, $zero, err_mesa_vazia  # Erro se vazia

    # Imprime Cabecalho
    li $v0, 4                       
    la $a0, msg_rel_h1              
    syscall                         
    li $v0, 1                       
    move $a0, $s1                   
    syscall                         
    li $v0, 4                       
    la $a0, msg_rel_h2              
    syscall                         

    li $s6, 0                       # $s6 = TOTAL ACUMULADO
    li $s3, 1                       # $s3 = ID item (1 a 20) CORRIGIDO

rel_loop_itens:
    li $t8, 21                      
    beq $s3, $t8, rel_fim_itens     # Termina em 21
    
    li $t3, 21                      # Matriz
    mul $t1, $s1, $t3               
    add $t1, $t1, $s3               # Usa o $s3 como iterador de coluna
    sll $t1, $t1, 2                 

    lw $t2, mesas_pedidos_qtd($t1)  # Qtd
    beq $t2, $zero, rel_pula_item   # Pula se 0

    li $v0, 1                       # Print Qtd
    move $a0, $t2                   
    syscall                         
    li $v0, 4                       
    la $a0, msg_rel_item            # Print "x "
    syscall                         

    sll $t4, $s3, 2                 # Info do item no R1 usando $s3
    lw $t5, precos($t4)             
    lw $t6, descricoes($t4)         

    li $v0, 4                       # Print Descricao
    move $a0, $t6                   
    syscall                         

    li $v0, 4                       
    la $a0, msg_rel_traco           # Print " - R$ "
    syscall                         

    mul $t7, $t5, $t2               # Subtotal = Preco * Qtd
    add $s6, $s6, $t7               # Soma no Total da Conta ($s6)

    move $a0, $t7                   
    jal print_centavos              # Print subtotal formatado

    li $v0, 11                      
    li $a0, 10                      # Nova linha
    syscall                         

rel_pula_item:
    addi $s3, $s3, 1                # Prox item
    j rel_loop_itens                

rel_fim_itens:
    li $v0, 4                       # Print Total Consumido
    la $a0, msg_rel_total           
    syscall                         
    move $a0, $s6                   
    jal print_centavos              

    li $v0, 4                       # Print Pago
    la $a0, msg_rel_pago            
    syscall                         
    sll $t1, $s1, 2                 
    lw $s7, mesas_pago($t1)         # Puxa saldo do R4
    move $a0, $s7                   
    jal print_centavos              

    li $v0, 4                       # Print Devedor
    la $a0, msg_rel_dev             
    syscall                         
    sub $s5, $s6, $s7               # Total - Pago
    bgez $s5, rel_imprime_dev       
    li $s5, 0                       # Zera se negativo (troco)

rel_imprime_dev:
    move $a0, $s5                   
    jal print_centavos              

    li $v0, 4                       # Fim do relatorio
    la $a0, msg_rel_fim             
    syscall                         
    j loop                          

# ----------------- R4: PAGAMENTO PARCIAL -----------------
do_mesa_pagar:
    la $a0, input_buffer            
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     

    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s1, $v0                   
    
    li $t8, 1                       
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 
    lw $t2, mesas_status($t1)       
    beq $t2, $zero, err_mesa_vazia  

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                
    jal str_to_int_6                
    move $s2, $v0                   

    sll $t1, $s1, 2                 
    lw $t2, mesas_pago($t1)         
    add $t2, $t2, $s2               
    sw $t2, mesas_pago($t1)         

    li $v0, 4                       
    la $a0, msg_pagamento_ok        
    syscall                         
    j loop                          

# ----------------- R2: INICIAR MESA -----------------
do_mesa_iniciar:
    la $a0, input_buffer            
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     

    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s1, $v0                   

    li $t8, 1                       
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 
    lw $t2, mesas_status($t1)       
    bne $t2, $zero, err_mesa_oc     

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $s4, $s0, 1                

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $s5, $s0, 1                

    sb $zero, 0($s0)                

    li $v0, 9                       
    li $a0, 16                      
    syscall                         
    move $s6, $v0                   

    move $a0, $s6                   
    move $a1, $s4                   
    jal strcpy                      

    li $v0, 9                       
    li $a0, 64                      
    syscall                         
    move $s7, $v0                   

    move $a0, $s7                   
    move $a1, $s5                   
    jal strcpy                      

    sll $t1, $s1, 2                 
    li $t2, 1                       
    sw $t2, mesas_status($t1)       
    sw $s6, mesas_telefone($t1)     
    sw $s7, mesas_nome($t1)         
    sw $zero, mesas_pago($t1)       

    li $v0, 4                       
    la $a0, msg_mesa_ok             
    syscall                         
    j loop                          

# ----------------- R3: ADICIONAR ITEM NA MESA -----------------
do_mesa_ad_item:
    la $a0, input_buffer            
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     

    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s1, $v0                   
    
    li $t8, 1                       
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 
    lw $t2, mesas_status($t1)       
    beq $t2, $zero, err_mesa_vazia  

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s2, $v0                   

    li $t8, 1                       
    blt $s2, $t8, err_item_in       
    li $t8, 20                      
    bgt $s2, $t8, err_item_in       

    sll $t1, $s2, 2                 
    lw $t2, descricoes($t1)         
    beq $t2, $zero, err_item_nc     

    li $t3, 21                      
    mul $t1, $s1, $t3               
    add $t1, $t1, $s2               
    sll $t1, $t1, 2                 

    lw $t2, mesas_pedidos_qtd($t1)  
    addi $t2, $t2, 1                
    sw $t2, mesas_pedidos_qtd($t1)  

    li $v0, 4                       
    la $a0, msg_mesa_ad_ok          
    syscall                         
    j loop                          

# ----------------- R3: REMOVER ITEM DA MESA -----------------
do_mesa_rm_item:
    la $a0, input_buffer            
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_mesa_in     

    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s1, $v0                   
    
    li $t8, 1                       
    blt $s1, $t8, err_mesa_in       
    li $t8, 15                      
    bgt $s1, $t8, err_mesa_in       

    sll $t1, $s1, 2                 
    lw $t2, mesas_status($t1)       
    beq $t2, $zero, err_mesa_vazia  

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s2, $v0                   

    li $t8, 1                       
    blt $s2, $t8, err_item_in       
    li $t8, 20                      
    bgt $s2, $t8, err_item_in       

    li $t3, 21                      
    mul $t1, $s1, $t3               
    add $t1, $t1, $s2               
    sll $t1, $t1, 2                 

    lw $t2, mesas_pedidos_qtd($t1)     
    beq $t2, $zero, err_item_nao_conta 

    addi $t2, $t2, -1               
    sw $t2, mesas_pedidos_qtd($t1)  

    li $v0, 4                       
    la $a0, msg_mesa_rm_ok          
    syscall                         
    j loop                          

# ----------------- R1: CARDAPIO (ADICIONAR/LISTAR/FORMATAR) -----------------
do_register:
    la $a0, input_buffer            
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    beq $s0, $zero, err_id          

    addi $a0, $s0, 1                
    jal str_to_int_2                
    move $s1, $v0                   

    li $t8, 1                       
    blt $s1, $t8, err_id            
    li $t8, 20                      
    bgt $s1, $t8, err_id            

    sll $t1, $s1, 2                 
    lw $t2, descricoes($t1)         
    bne $t2, $zero, err_dup         

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    move $s0, $v0                   
    addi $a0, $s0, 1                
    jal str_to_int_5                
    move $s2, $v0                   

    addi $a0, $s0, 1                
    li $a1, '-'                     
    jal find_char                   
    addi $s0, $v0, 1                

    li $v0, 9                       
    li $a0, 64                      
    syscall                         
    move $s3, $v0                   

    move $a0, $s3                   
    move $a1, $s0                   
    jal strcpy                      

    sll $t1, $s1, 2                 
    sw $s2, precos($t1)             
    sw $s3, descricoes($t1)         

    li $v0, 4                       
    la $a0, msg_add_ok              
    syscall                         
    j loop                          

do_list:
    li $v0, 4                       
    la $a0, msg_list_h              
    syscall                         
    li $t0, 1                       
list_l:
    li $t8, 21                      
    beq $t0, $t8, loop              
    sll $t1, $t0, 2                 
    lw $t2, descricoes($t1)         
    beq $t2, $zero, list_skip       

    li $v0, 1                       
    move $a0, $t0                   
    syscall                         

    li $v0, 11                      
    li $a0, 32                      
    syscall                         

    lw $a0, precos($t1)             
    li $v0, 1                       
    syscall                         

    li $v0, 11                      
    li $a0, 32                      
    syscall                         

    move $a0, $t2                   
    li $v0, 4                       
    syscall                         

    li $v0, 11                      
    li $a0, 10                      
    syscall                         

list_skip:
    addi $t0, $t0, 1                
    j list_l                        

do_format:
    li $t0, 1                       
fmt_l:
    li $t8, 21                      
    beq $t0, $t8, fmt_end           
    sll $t1, $t0, 2                 
    sw $zero, precos($t1)           
    sw $zero, descricoes($t1)       
    addi $t0, $t0, 1                
    j fmt_l                         
fmt_end:
    li $v0, 4                       
    la $a0, msg_fmt_ok              
    syscall                         
    j loop                          

# ==========================================================================================
# FUNCOES AUXILIARES (STRINGS E FORMATACAO)
# ==========================================================================================
print_centavos:
    move $t9, $a0                   
    li $t8, 100                     
    div $t9, $t8                    
    mflo $t0                        
    mfhi $t1                        

    li $v0, 1                       
    move $a0, $t0                   
    syscall                         

    li $v0, 11                      
    li $a0, 44                      
    syscall                         

    li $t8, 10                      
    bge $t1, $t8, pt_print_resto    
    
    li $v0, 11                      
    li $a0, 48                      
    syscall                         

pt_print_resto:
    li $v0, 1                       
    move $a0, $t1                   
    syscall                         
    jr $ra                          

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

str_to_int_2:
    lb $t4, 0($a0)                  
    addi $t4, $t4, -48              
    li $t5, 10                      
    mul $v0, $t4, $t5               
    lb $t4, 1($a0)                  
    addi $t4, $t4, -48              
    add $v0, $v0, $t4               
    jr $ra                          

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

strcpy:
    lb $t4, 0($a1)                  
    sb $t4, 0($a0)                  
    beq $t4, $zero, stcy_e          
    addi $a0, $a0, 1                
    addi $a1, $a1, 1                
    j strcpy                        
stcy_e: 
    jr $ra                          

remove_newline:
    la $t0, input_buffer            
remove_loop:
    lb $t1, 0($t0)                  
    beq $t1, $zero, end_remove      
    li $t2, 10                      
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