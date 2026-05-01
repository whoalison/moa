.data
	banner:        .asciiz "\nrestaurante-MOA>>"
	input_buffer:  .space 128
	
	cmd_cardapio_list: .asciiz "cardapio_list"
	cmd_cardapio_ad:   .asciiz "cardapio_ad"
	cmd_format:        .asciiz "cardapio_format"
	cmd_exit:          .asciiz "exit"
	
	msg_invalid:  .asciiz "Comando invalido\n"
	msg_list_h:   .asciiz "--- ITENS DO CARDAPIO ---\n"
	msg_exit:     .asciiz "Encerrando sistema...\n"
	msg_add_ok:   .asciiz "Item adicionado com sucesso\n"
	msg_err_id:   .asciiz "Falha: código de item inválido\n"
	msg_err_dup:  .asciiz "Falha: número de item já cadastrado\n"
	msg_fmt_ok:   .asciiz "Cardapio formatado com sucesso\n"
	
	# Usamos 21 para o ID 01 ser o índice 1
	precos:      .word 0:21
	descricoes:  .word 0:21
	
.text
.globl main

main:
loop:
    li $v0, 4
    la $a0, banner
    syscall

    li $v0, 8
    la $a0, input_buffer
    li $a1, 128
    syscall

    jal remove_newline
    
    #TESTE: cardapio_list (Comparação exata)
    la $a0, input_buffer
    la $a1, cmd_cardapio_list
    jal strcmp
    beq $v0, $zero, do_list
    
    #TESTE: cardapio_format (Comparação exata)
    la $a0, input_buffer
    la $a1, cmd_format
    jal strcmp
    beq $v0, $zero, do_format
    
    #TESTE: exit
    la $a0, input_buffer
    la $a1, cmd_exit
    jal strcmp
    beq $v0, $zero, do_exit
    
    #TESTE: cardapio_ad (Prefixo de 11 caracteres)
    la $a0, input_buffer
    la $a1, cmd_cardapio_ad
    jal strncmp_11
    beq $v0, $zero, do_register

    li $v0, 4
    la $a0, msg_invalid
    syscall
    j loop
	
# FUNÇÃO: strncmp_11 (Analisa o Prefixo do Comando)
# Sintaxe: Compara os primeiros 11 bytes. Se bater, o comando é 'ad'.
strncmp_11:
    li $t7, 0   # Contador
    
sn_loop:
    li $t8, 11
    beq $t7, $t8, sn_eq         # Chegou a 11 e tudo igual
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
    
# FUNÇÃO: find_char (O "cortador" de hífens)
# Sintaxe: Percorre a string até achar o caractere em $a1.
find_char:
    lb $t4, 0($a0)
    beq $t4, $zero, f_err       # Fim da string sem achar '-'
    beq $t4, $a1, f_ok          # Achou o hífen
    addi $a0, $a0, 1
    j find_char
    
f_ok:  
    move $v0, $a0
    jr $ra    # Retorna o endereço exato do hífen
    
f_err: 
    li $v0, 0
    jr $ra
    
# FUNÇÃO: str_to_int_2 e str_to_int_5 (Conversores)
# Sintaxe: Subtrai 48 (ASCII de '0') para converter texto em número.
str_to_int_2:
    lb $t4, 0($a0)
    addi $t4, $t4, -48          # Dezena
    li $t5, 10
    mul $v0, $t4, $t5
    lb $t4, 1($a0)
    addi $t4, $t4, -48          # Unidade
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
    
# COMANDO: do_register (O Parser do Cadastro)
# Sintaxe: Usa find_char e conversores para preencher os arrays.
do_register:
    la $a0, input_buffer
    li $a1, '-'
    jal find_char               # Busca o 1º '-' (após cardapio_ad)
    move $s0, $v0
    beq $s0, $zero, err_id

    # Extrai Código
    addi $a0, $s0, 1            # Aponta para o ID (01-20)
    jal str_to_int_2
    move $s1, $v0               # $s1 = ID Inteiro

    # Valida ID
    li $t8, 1
    blt $s1, $t8, err_id
    li $t8, 20
    bgt $s1, $t8, err_id

    # Verifica se duplicado
    sll $t1, $s1, 2             # ID * 4
    lw $t2, descricoes($t1)
    bne $t2, $zero, err_dup     # Já existe descrição ali?

    # Extrai Preço
    addi $a0, $s0, 1
    li $a1, '-'
    jal find_char               # Busca o 2º '-'
    move $s0, $v0
    addi $a0, $s0, 1            # Aponta para o preço
    jal str_to_int_5
    move $s2, $v0               # $s2 = Preço em centavos

    # Extrai Descrição
    addi $a0, $s0, 1
    li $a1, '-'
    jal find_char               # Busca o 3º '-'
    addi $s0, $v0, 1            # $s0 = Início do texto da descrição

    # Salva no "Banco"
    li $v0, 9                   # Aloca memória para a string
    li $a0, 64
    syscall
    move $s3, $v0               # Endereço novo em $s3

    # Copia a string do buffer para a memória alocada
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

# COMANDO: do_list (Listagem Ordenada)
# Sintaxe: Percorre os índices 1 a 20.
do_list:
    li $v0, 4
    la $a0, msg_list_h
    syscall
    li $t0, 1   
                    # Contador de 1 a 20
list_l:
    li $t8, 21
    beq $t0, $t8, loop          # Fim da lista
    sll $t1, $t0, 2
    lw $t2, descricoes($t1)
    beq $t2, $zero, list_skip   # Pula se não houver item no ID

    li $v0, 1                   # Imprime ID
    move $a0, $t0
    syscall

    li $v0, 11                  # Espaço
    li $a0, 32
    syscall

    lw $a0, precos($t1)         # Imprime Preço
    li $v0, 1
    syscall

    li $v0, 11                  # Espaço
    li $a0, 32
    syscall

    move $a0, $t2               # Imprime Descrição
    li $v0, 4
    syscall

    li $v0, 11                  # Nova linha
    li $a0, 10
    syscall

list_skip:
    addi $t0, $t0, 1
    j list_l

# COMANDO: do_format (Limpa os Arrays)
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

# --- 1ª Questão ---
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

# --- TRATAMENTO DE ERROS ---
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
    
do_exit: 
    li $v0, 4
    la $a0, msg_exit
    syscall
    li $v0, 10
    syscall