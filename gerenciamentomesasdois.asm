.data
	# INTERFACE
	banner:         .asciiz "\nrestaurante-MOA>>"
	input_buffer:   .space 128
	
	# COMANDOS 
	cmd_cardapio_list:   .asciiz "cardapio_list"
	cmd_cardapio_ad:     .asciiz "cardapio_ad"
	cmd_cardapio_rm:     .asciiz "cardapio_rm"
	cmd_cardapio_format: .asciiz "cardapio_format"
	cmd_mesa_iniciar:    .asciiz "mesa_iniciar"
	cmd_mesa_ad_item:    .asciiz "mesa_ad_item"
	cmd_mesa_rm_item:    .asciiz "mesa_rm_item"
	cmd_mesa_format:     .asciiz "mesa_format"
	cmd_mesa_parcial:    .asciiz "mesa_parcial"
	cmd_exit:            .asciiz "exit"
	
	# MENSAGENS DO SISTEMA
	msg_invalid:    .asciiz "Comando invalido\n"
	msg_list_h:     .asciiz "--- ITENS DO CARDAPIO ---\n"
	msg_exit:       .asciiz "Encerrando sistema...\n"
	msg_add_ok:     .asciiz "Item adicionado com sucesso\n"
	msg_rm_ok:      .asciiz "Item removido com sucesso\n"
	msg_fmt_ok:     .asciiz "Operacao realizada com sucesso\n"
	
	msg_err_id:     .asciiz "Falha: codigo de item invalido\n"
	msg_err_dup:    .asciiz "Falha: numero de item ja cadastrado\n"
	msg_err_rm_vazio: .asciiz "Codigo informado nao possui item cadastrado no cardapio\n"
	
	msg_mesa_ok:     .asciiz "Atendimento iniciado com sucesso\n"
	msg_err_mesa_oc: .asciiz "Falha: mesa ocupada\n"
	msg_err_mesa_in: .asciiz "Falha: mesa inexistente\n"
	
	msg_mesa_ad_ok:         .asciiz "Item adicionado com sucesso\n"
	msg_mesa_rm_ok:         .asciiz "Item removido com sucesso\n"
	msg_err_mesa_vazia:     .asciiz "Falha: mesa nao iniciou atendimento\n"
	msg_err_item_in:        .asciiz "Falha: codigo do item invalido\n"
	msg_err_item_nc:        .asciiz "Falha: item nao cadastrado no cardapio\n"
	msg_err_item_nao_conta: .asciiz "Falha: item nao consta na conta\n"
	
	# EXTRATO DA MESA
	msg_parcial_h:   .asciiz "\n=== EXTRATO PARCIAL DA MESA "
	msg_parcial_it:  .asciiz "Item: "
	msg_parcial_qt:  .asciiz " | Qtd: "
	msg_parcial_pr:  .asciiz " | Valor Un: "
	msg_parcial_tot: .asciiz "\nTOTAL DA CONTA: "
	msg_pago:        .asciiz "\nTOTAL PAGO: "
	msg_devedor:     .asciiz "\nSALDO DEVEDOR: "
	char_fechar:     .asciiz " ===\n"

	# ESTRUTURA DE DADOS 
	precos:            .word 0:21    # R1: Preços em centavos
	descricoes:        .word 0:21    # R1: Ponteiros para strings
	mesas_status:      .word 0:16    # R2: 0=livre, 1=ocupada
	mesas_nome:        .word 0:16    # R2: Ponteiros nomes
	mesas_telefone:    .word 0:16    # R2: Ponteiros fones
	mesas_pedidos_qtd: .word 0:336   # R3: Matriz (Mesa * 21) + Item
	mesas_pagas_total: .word 0:16    # R4: Saldo já pago

.text
.globl main

main:
loop:
    # 1. IMPRIMIR BANNER
    li $v0, 4
    la $a0, banner
    syscall

    # 2. LER ENTRADA
    li $v0, 8
    la $a0, input_buffer
    li $a1, 128
    syscall

    # 3. LIMPAR STRING (Remover \n)
    jal remove_newline
    
    # 4. PARSER DE COMANDOS
    la $a0, input_buffer
    
    # Comandos de String Exata
    la $a1, cmd_cardapio_list
    jal strcmp
    beq $v0, $zero, do_list
    
    la $a0, input_buffer
    la $a1, cmd_cardapio_format
    jal strcmp
    beq $v0, $zero, do_format
    
    la $a0, input_buffer
    la $a1, cmd_mesa_format
    jal strcmp
    beq $v0, $zero, do_mesa_format

    la $a0, input_buffer
    la $a1, cmd_exit
    jal strcmp
    beq $v0, $zero, do_exit
    
    # Comandos com Argumentos (Prefixos)
    la $a0, input_buffer
    la $a1, cmd_cardapio_ad
    jal strncmp_11
    beq $v0, $zero, do_register
    
    la $a0, input_buffer
    la $a1, cmd_cardapio_rm
    jal strncmp_11
    beq $v0, $zero, do_cardapio_rm
    
    la $a0, input_buffer
    la $a1, cmd_mesa_iniciar
    jal strncmp_12
    beq $v0, $zero, do_mesa_iniciar

    la $a0, input_buffer
    la $a1, cmd_mesa_ad_item
    jal strncmp_12
    beq $v0, $zero, do_mesa_ad_item

    la $a0, input_buffer
    la $a1, cmd_mesa_rm_item
    jal strncmp_12
    beq $v0, $zero, do_mesa_rm_item

    la $a0, input_buffer
    la $a1, cmd_mesa_parcial
    jal strncmp_12
    beq $v0, $zero, do_mesa_parcial
    
    # Invalido
    li $v0, 4
    la $a0, msg_invalid
    syscall
    j loop

# ==========================================================================================
# IMPLEMENTACAO DOS COMANDOS
# ==========================================================================================

# --- MESA PARCIAL (R4/R5) ---
do_mesa_parcial:
    la $a0, input_buffer
    li $a1, '-'
    jal find_char
    move $s0, $v0
    beq $s0, $zero, err_mesa_in

    addi $a0, $s0, 1
    jal str_to_int_2
    move $s1, $v0           # $s1 = ID da Mesa

    li $t8, 1
    blt $s1, $t8, err_mesa_in
    li $t8, 15
    bgt $s1, $t8, err_mesa_in

    # Cabecalho
    li $v0, 4
    la $a0, msg_parcial_h
    syscall
    li $v0, 1
    move $a0, $s1
    syscall
    li $v0, 4
    la $a0, char_fechar
    syscall

    li $s2, 0               # $s2 = Total Acumulado
    li $t0, 1               # $t0 = Contador Itens 1-20
loop_p_itens:
    li $t8, 21
    beq $t0, $t8, fim_p_itens
    li $t1, 21
    mul $t2, $s1, $t1
    add $t2, $t2, $t0
    sll $t2, $t2, 2
    lw $t3, mesas_pedidos_qtd($t2)
    beq $t3, $zero, p_item_skip
    
    sll $t4, $t0, 2
    lw $t5, precos($t4)     # Preco
    lw $t6, descricoes($t4) # Nome
    mul $t7, $t3, $t5       # Subtotal
    add $s2, $s2, $t7

    li $v0, 4
    la $a0, msg_parcial_it
    syscall
    move $a0, $t6
    syscall
    li $v0, 4
    la $a0, msg_parcial_qt
    syscall
    li $v0, 1
    move $a0, $t3
    syscall
    li $v0, 4
    la $a0, msg_parcial_pr
    syscall
    li $v0, 1
    move $a0, $t5
    syscall
    li $v0, 11
    li $a0, 10
    syscall
p_item_skip:
    addi $t0, $t0, 1
    j loop_p_itens
fim_p_itens:
    li $v0, 4
    la $a0, msg_parcial_tot
    syscall
    li $v0, 1
    move $a0, $s2
    syscall
    sll $t1, $s1, 2
    lw $t2, mesas_pagas_total($t1)
    li $v0, 4
    la $a0, msg_pago
    syscall
    li $v0, 1
    move $a0, $t2
    syscall
    sub $t3, $s2, $t2
    li $v0, 4
    la $a0, msg_devedor
    syscall
    li $v0, 1
    move $a0, $t3
    syscall
    li $v0, 11
    li $a0, 10
    syscall
    j loop

# --- CARDAPIO RM ---
do_cardapio_rm:
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
    beq $t2, $zero, err_rm_vazio
    sw $zero, precos($t1)       
    sw $zero, descricoes($t1)   
    li $v0, 4
    la $a0, msg_rm_ok
    syscall
    j loop

err_rm_vazio:
    li $v0, 4
    la $a0, msg_err_rm_vazio
    syscall
    j loop

# --- MESA FORMAT ---
do_mesa_format:
    li $t0, 1                   
m_fmt_loop:
    li $t8, 16
    beq $t0, $t8, m_fmt_end
    sll $t1, $t0, 2
    sw $zero, mesas_status($t1)
    sw $zero, mesas_nome($t1)
    sw $zero, mesas_telefone($t1)
    sw $zero, mesas_pagas_total($t1) # Zera pagamentos tb
    li $t2, 1                   
m_fmt_ped_l:
    li $t8, 21
    beq $t2, $t8, m_fmt_next
    li $t3, 21
    mul $t4, $t0, $t3
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    sw $zero, mesas_pedidos_qtd($t4)
    addi $t2, $t2, 1
    j m_fmt_ped_l
m_fmt_next:
    addi $t0, $t0, 1
    j m_fmt_loop
m_fmt_end:
    li $v0, 4
    la $a0, msg_fmt_ok
    syscall
    j loop

# --- CARDAPIO AD ---
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

# --- CARDAPIO LIST ---
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

# --- CARDAPIO FORMAT ---
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

# --- MESA INICIAR ---
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
    li $v0, 4
    la $a0, msg_mesa_ok
    syscall
    j loop

# --- MESA AD ITEM ---
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
    move $s2, $v0 # ID Item
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

# --- MESA RM ITEM ---
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
    move $s2, $v0 # ID Item
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

# ==========================================================================================
# FUNCOES AUXILIARES
# ==========================================================================================

strncmp_11:
    li $t7, 0
sn11_l:
    li $t8, 11
    beq $t7, $t8, sn11_e
    lb $t2, 0($a0)
    lb $t3, 0($a1)
    bne $t2, $t3, sn11_d
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j sn11_l
sn11_d: li $v0, 1
    jr $ra
sn11_e: li $v0, 0
    jr $ra

strncmp_12:
    li $t7, 0
sn12_l:
    li $t8, 12
    beq $t7, $t8, sn12_e
    lb $t2, 0($a0)
    lb $t3, 0($a1)
    bne $t2, $t3, sn12_d
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j sn12_l
sn12_d: li $v0, 1
    jr $ra
sn12_e: li $v0, 0
    jr $ra

find_char:
    lb $t4, 0($a0)
    beq $t4, $zero, f_err
    beq $t4, $a1, f_ok
    addi $a0, $a0, 1
    j find_char
f_ok: move $v0, $a0
    jr $ra
f_err: li $v0, 0
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
s5_l: beq $t7, 5, s5_e
    lb $t4, 0($a0)
    addi $t4, $t4, -48
    mul $v0, $v0, $t5
    add $v0, $v0, $t4
    addi $a0, $a0, 1
    addi $t7, $t7, 1
    j s5_l
s5_e: jr $ra

strcmp:
    move $t0, $a0
strcmp_l:
    lb $t2, 0($t0)
    lb $t3, 0($a1)
    bne $t2, $t3, strcmp_d
    beq $t2, $zero, strcmp_e
    addi $t0, $t0, 1
    addi $a1, $a1, 1
    j strcmp_l
strcmp_d: li $v0, 1
    jr $ra
strcmp_e: li $v0, 0
    jr $ra

strcpy:
    lb $t4, 0($a1)
    sb $t4, 0($a0)
    beq $t4, $zero, stcy_e
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    j strcpy
stcy_e: jr $ra

remove_newline:
    la $t0, input_buffer
rem_l:
    lb $t1, 0($t0)
    beq $t1, $zero, rem_e
    li $t2, 10
    beq $t1, $t2, rem_r
    addi $t0, $t0, 1
    j rem_l
rem_r: sb $zero, 0($t0)
rem_e: jr $ra

# --- ERROS ---
err_id: li $v0, 4
    la $a0, msg_err_id
    syscall
    j loop
err_dup: li $v0, 4
    la $a0, msg_err_dup
    syscall
    j loop
err_mesa_oc: li $v0, 4
    la $a0, msg_err_mesa_oc
    syscall
    j loop
err_mesa_in: li $v0, 4
    la $a0, msg_err_mesa_in
    syscall
    j loop
err_mesa_vazia: li $v0, 4
    la $a0, msg_err_mesa_vazia
    syscall
    j loop
err_item_in: li $v0, 4
    la $a0, msg_err_item_in
    syscall
    j loop
err_item_nc: li $v0, 4
    la $a0, msg_err_item_nc
    syscall
    j loop
err_item_nao_conta: li $v0, 4
    la $a0, msg_err_item_nao_conta
    syscall
    j loop
do_exit: li $v0, 4
    la $a0, msg_exit
    syscall
    li $v0, 10
    syscall