.data
banner:        .asciiz "\nrestaurante-MOA>>"
input_buffer:  .space 128

cmd_cardapio_list: .asciiz "cardapio_list"
cmd_exit:          .asciiz "exit"

msg_invalid:  .asciiz "Comando invalido\n"
msg_list:     .asciiz "MENU - CARDAPIO...\n"
msg_exit:     .asciiz "Encerrando sistema...\n"

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

    jal remove_newline # remover '\n' da string

    la $a0, input_buffer	
    la $a1, cmd_cardapio_list # verifica cardapio_list
    jal strcmp
    beq $v0, $zero, do_list

    la $a0, input_buffer
    la $a1, cmd_exit # verifica exit
    jal strcmp
    beq $v0, $zero, do_exit

    li $v0, 4
    la $a0, msg_invalid # retorno de erro
    syscall
    j loop


do_list:
    li $v0, 4
    la $a0, msg_list
    syscall
    j loop


do_exit:
    li $v0, 4
    la $a0, msg_exit
    syscall

    li $v0, 10
    syscall

strcmp:
    add $t0, $a0, $zero # compara strings
    add $t1, $a1, $zero # retorna 0 se iguais

strcmp_loop:
    lb $t2, 0($t0)
    lb $t3, 0($t1)

    bne $t2, $t3, strcmp_diff
    beq $t2, $zero, strcmp_equal

    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j strcmp_loop

strcmp_diff:
    li $v0, 1
    jr $ra

strcmp_equal:
    li $v0, 0
    jr $ra

remove_newline:
    la $t0, input_buffer # troca '\n' por '\0'

remove_loop:
    lb $t1, 0($t0)
    beq $t1, $zero, end_remove

    li $t2, 10   # '\n'
    beq $t1, $t2, replace_null

    addi $t0, $t0, 1
    j remove_loop

replace_null:
    sb $zero, 0($t0)

end_remove:
    jr $ra