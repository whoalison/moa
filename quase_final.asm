# ==========================================================================================
# UFRPE - Universidade Federal Rural de Pernambuco
# Disciplina: Arquitetura e Organizacao de Computadores - 2026.1
# Atividade: Projeto 01 (1a VA) - Assembly MIPS e Simulador MARS
# Grupo: Murilo, Alisson, Otavio
# Descricao: Sistema MOA - versao completa consolidada
# ==========================================================================================

.data
    # --- INTERFACE ---
    banner:        .asciiz "\nrestaurante-MOA>>"
    input_buffer:  .space 128

    # --- COMANDOS ---
    cmd_cardapio_list:   .asciiz "cardapio_list"
    cmd_cardapio_ad:     .asciiz "cardapio_ad"
    cmd_cardapio_rm:     .asciiz "cardapio_rm"
    cmd_cardapio_format: .asciiz "cardapio_format"

    cmd_mesa_iniciar:    .asciiz "mesa_iniciar"
    cmd_mesa_ad_item:    .asciiz "mesa_ad_item"
    cmd_mesa_rm_item:    .asciiz "mesa_rm_item"
    cmd_mesa_pagar:      .asciiz "mesa_pagar"
    cmd_mesa_parcial:    .asciiz "mesa_parcial"
    cmd_mesa_format:     .asciiz "mesa_format"
    cmd_mesa_fechar:     .asciiz "mesa_fechar"

    cmd_salvar:          .asciiz "salvar"
    cmd_recarregar:      .asciiz "recarregar"
    cmd_formatar:        .asciiz "formatar"
    cmd_exit:            .asciiz "exit"

    # --- ARQUIVO ---
    db_file: .asciiz "moa_db.bin" # ALTERAR ESSE CAMINHO TESTAR "/tmp/moa_db.bin" OU /Users/alison/Documents/BCC/arq

    # --- MENSAGENS ---
    msg_invalid:         .asciiz "Comando invalido\n"
    msg_exit:            .asciiz "Encerrando sistema...\n"

    # Cardapio
    msg_list_h:          .asciiz "--- ITENS DO CARDAPIO ---\n"
    msg_add_ok:          .asciiz "Item adicionado com sucesso\n"
    msg_rm_ok:           .asciiz "Item removido com sucesso\n"
    msg_fmt_ok:          .asciiz "Cardapio formatado com sucesso\n"
    msg_err_id:          .asciiz "Falha: codigo de item invalido\n"
    msg_err_dup:         .asciiz "Falha: numero de item ja cadastrado\n"
    msg_err_item_sem_cad:.asciiz "Codigo informado nao possui item cadastrado no cardapio\n"

    # Mesa/Pedidos
    msg_mesa_ok:         .asciiz "Atendimento iniciado com sucesso\n"
    msg_err_mesa_oc:     .asciiz "Falha: mesa ocupada\n"
    msg_err_mesa_in:     .asciiz "Falha: mesa inexistente\n"
    msg_err_mesa_vazia:  .asciiz "Falha: mesa nao iniciou atendimento\n"

    msg_mesa_ad_ok:         .asciiz "Item adicionado com sucesso\n"
    msg_mesa_rm_ok:         .asciiz "Item removido com sucesso\n"
    msg_err_item_in:        .asciiz "Falha: codigo do item invalido\n"
    msg_err_item_nc:        .asciiz "Falha: item nao cadastrado no cardapio\n"
    msg_err_item_nao_conta: .asciiz "Falha: item nao consta na conta\n"

    # Pagamento / Fechamento
    msg_pagamento_ok:     .asciiz "Pagamento realizado com sucesso\n"
    msg_mesa_fmt_ok:      .asciiz "Mesas formatadas com sucesso\n"
    msg_mesa_fechada_ok:  .asciiz "Mesa fechada com sucesso\n"
    msg_err_saldo_aberto: .asciiz "Falha: saldo devedor ainda nao quitado. Valor restante: R$ "

    # Relatorio
    msg_rel_h1:          .asciiz "\n--- RELATORIO MESA "
    msg_rel_h2:          .asciiz " ---\n"
    msg_rel_item:        .asciiz "x "
    msg_rel_traco:       .asciiz " - R$ "
    msg_rel_total:       .asciiz "----------------------\nTotal Consumido: R$ "
    msg_rel_pago:        .asciiz "\nValor ja Pago:   R$ "
    msg_rel_dev:         .asciiz "\nSaldo Devedor:   R$ "
    msg_rel_fim:         .asciiz "\n----------------------\n"

    # Persistencia
    msg_salvar_ok:       .asciiz "Dados salvos com sucesso\n"
    msg_recarregar_ok:   .asciiz "Dados recarregados com sucesso\n"
    msg_formatar_ok:     .asciiz "Dados da execucao formatados com sucesso\n"
    msg_file_err:        .asciiz "Falha de acesso ao arquivo\n"

    msg_nl:              .asciiz "\n"

    # --- ESTRUTURAS ---
    # Cardapio (1..20)
    precos:         .word 0:21
    descricoes:     .word 0:21      # ponteiros para strings

    # Mesas (1..15)
    mesas_status:   .word 0:16
    mesas_nome:     .word 0:16      # ponteiros
    mesas_telefone: .word 0:16      # ponteiros
    mesas_pago:     .word 0:16

    # Pedidos [mesa][item] => 16 x 21
    mesas_pedidos_qtd: .word 0:336

    # Buffers de serializacao de string (persistencia)
    tmp_desc_buf:   .space 64
    tmp_nome_buf:   .space 64
    tmp_fone_buf:   .space 16

.text
.globl main

# ==========================================================================================
# MAIN
# ==========================================================================================
main:
    jal carregar_arquivo_auto

loop:
    li $v0, 4
    la $a0, banner
    syscall

    li $v0, 8
    la $a0, input_buffer
    li $a1, 128
    syscall

    jal remove_newline

    # ---------- comandos exatos ----------
    la $a0, input_buffer
    la $a1, cmd_cardapio_list
    jal strcmp
    beq $v0, $zero, do_list

    la $a0, input_buffer
    la $a1, cmd_cardapio_format
    jal strcmp
    beq $v0, $zero, do_cardapio_format

    la $a0, input_buffer
    la $a1, cmd_mesa_format
    jal strcmp
    beq $v0, $zero, do_mesa_format

    la $a0, input_buffer
    la $a1, cmd_salvar
    jal strcmp
    beq $v0, $zero, do_salvar

    la $a0, input_buffer
    la $a1, cmd_recarregar
    jal strcmp
    beq $v0, $zero, do_recarregar

    la $a0, input_buffer
    la $a1, cmd_formatar
    jal strcmp
    beq $v0, $zero, do_formatar_global

    la $a0, input_buffer
    la $a1, cmd_exit
    jal strcmp
    beq $v0, $zero, do_exit

    # ---------- prefixos ----------
    la $a0, input_buffer
    la $a1, cmd_cardapio_ad
    jal strncmp_11
    beq $v0, $zero, do_cardapio_ad

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
    la $a1, cmd_mesa_pagar
    jal strncmp_10
    beq $v0, $zero, do_mesa_pagar

    la $a0, input_buffer
    la $a1, cmd_mesa_parcial
    jal strncmp_12
    beq $v0, $zero, do_mesa_parcial

    la $a0, input_buffer
    la $a1, cmd_mesa_fechar
    jal strncmp_11
    beq $v0, $zero, do_mesa_fechar

    li $v0, 4
    la $a0, msg_invalid
    syscall
    j loop

# ==========================================================================================
# COMANDOS
# ==========================================================================================

# cardapio_ad-<id>-<preco5>-<descricao>
do_cardapio_ad:
    la $a0, input_buffer
    li $a1, '-'
    jal find_char
    move $s0, $v0
    beq $s0, $zero, err_id

    addi $a0, $s0, 1
    jal str_to_int_2
    move $s1, $v0       # id

    li $t8, 1
    blt $s1, $t8, err_id
    li $t8, 20
    bgt $s1, $t8, err_id

    sll $t1, $s1, 2
    lw $t2, descricoes($t1)
    bne $t2, $zero, err_dup

    # preco
    addi $a0, $s0, 1
    li $a1, '-'
    jal find_char
    move $s0, $v0
    beq $s0, $zero, err_id

    addi $a0, $s0, 1
    jal str_to_int_5
    move $s2, $v0       # preco

    # descricao
    addi $a0, $s0, 1
    li $a1, '-'
    jal find_char
    move $s0, $v0
    beq $s0, $zero, err_id
    addi $s3, $s0, 1

    li $v0, 9
    li $a0, 64
    syscall
    move $s4, $v0

    move $a0, $s4
    move $a1, $s3
    jal strcpy

    sll $t1, $s1, 2
    sw $s2, precos($t1)
    sw $s4, descricoes($t1)

    li $v0, 4
    la $a0, msg_add_ok
    syscall
    j loop

# cardapio_rm-<id>
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
    beq $t2, $zero, err_item_sem_cad

    sw $zero, precos($t1)
    sw $zero, descricoes($t1)

    # limpa item em todas mesas
    li $t0, 1
rm_item_mesa_loop:
    li $t8, 16
    beq $t0, $t8, rm_item_done
    li $t3, 21
    mul $t4, $t0, $t3
    add $t4, $t4, $s1
    sll $t4, $t4, 2
    sw $zero, mesas_pedidos_qtd($t4)
    addi $t0, $t0, 1
    j rm_item_mesa_loop

rm_item_done:
    li $v0, 4
    la $a0, msg_rm_ok
    syscall
    j loop

# cardapio_list (contador em $s0 para nao corromper em jal)
do_list:
    li $v0, 4
    la $a0, msg_list_h
    syscall

    li $s0, 1
list_l:
    li $t8, 21
    beq $s0, $t8, loop

    sll $t1, $s0, 2
    lw $t2, descricoes($t1)
    beq $t2, $zero, list_skip

    li $v0, 1
    move $a0, $s0
    syscall

    li $v0, 11
    li $a0, 32
    syscall

    lw $a0, precos($t1)
    jal print_centavos

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
    addi $s0, $s0, 1
    j list_l

# cardapio_format
do_cardapio_format:
    jal clear_cardapio
    li $v0, 4
    la $a0, msg_fmt_ok
    syscall
    j loop

# mesa_iniciar-<mesa>-<fone>-<nome>
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

    # fone
    addi $a0, $s0, 1
    li $a1, '-'
    jal find_char
    move $s0, $v0
    beq $s0, $zero, err_mesa_in
    addi $s4, $s0, 1

    # nome
    addi $a0, $s0, 1
    li $a1, '-'
    jal find_char
    move $s0, $v0
    beq $s0, $zero, err_mesa_in
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

# mesa_ad_item-<mesa>-<item>
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
    beq $s0, $zero, err_item_in

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

# mesa_rm_item-<mesa>-<item>
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
    beq $s0, $zero, err_item_in

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

# mesa_pagar-<mesa>-<valor6>
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
    beq $s0, $zero, err_mesa_in

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

# mesa_parcial-<mesa>
do_mesa_parcial:
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

    li $v0, 4
    la $a0, msg_rel_h1
    syscall
    li $v0, 1
    move $a0, $s1
    syscall
    li $v0, 4
    la $a0, msg_rel_h2
    syscall

    li $s6, 0
    li $s3, 1

rel_loop_itens:
    li $t8, 21
    beq $s3, $t8, rel_fim_itens

    li $t3, 21
    mul $t1, $s1, $t3
    add $t1, $t1, $s3
    sll $t1, $t1, 2

    lw $t2, mesas_pedidos_qtd($t1)
    beq $t2, $zero, rel_pula_item

    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, msg_rel_item
    syscall

    sll $t4, $s3, 2
    lw $t5, precos($t4)
    lw $t6, descricoes($t4)

    li $v0, 4
    move $a0, $t6
    syscall

    li $v0, 4
    la $a0, msg_rel_traco
    syscall

    mul $t7, $t5, $t2
    add $s6, $s6, $t7

    move $a0, $t7
    jal print_centavos

    li $v0, 11
    li $a0, 10
    syscall

rel_pula_item:
    addi $s3, $s3, 1
    j rel_loop_itens

rel_fim_itens:
    li $v0, 4
    la $a0, msg_rel_total
    syscall
    move $a0, $s6
    jal print_centavos

    li $v0, 4
    la $a0, msg_rel_pago
    syscall
    sll $t1, $s1, 2
    lw $s7, mesas_pago($t1)
    move $a0, $s7
    jal print_centavos

    li $v0, 4
    la $a0, msg_rel_dev
    syscall
    sub $s5, $s6, $s7
    bgez $s5, rel_imprime_dev
    li $s5, 0
rel_imprime_dev:
    move $a0, $s5
    jal print_centavos

    li $v0, 4
    la $a0, msg_rel_fim
    syscall
    j loop

# mesa_format
do_mesa_format:
    jal clear_mesas
    li $v0, 4
    la $a0, msg_mesa_fmt_ok
    syscall
    j loop

# mesa_fechar-<mesa>
do_mesa_fechar:
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

    li $s6, 0
    li $t0, 1
fechar_loop_itens:
    li $t8, 21
    beq $t0, $t8, fechar_total_ok

    li $t3, 21
    mul $t4, $s1, $t3
    add $t4, $t4, $t0
    sll $t4, $t4, 2

    lw $t5, mesas_pedidos_qtd($t4)
    beq $t5, $zero, fechar_next_item

    sll $t6, $t0, 2
    lw $t7, precos($t6)
    mul $t9, $t7, $t5
    add $s6, $s6, $t9

fechar_next_item:
    addi $t0, $t0, 1
    j fechar_loop_itens

fechar_total_ok:
    sll $t1, $s1, 2
    lw $s7, mesas_pago($t1)
    sub $s5, $s6, $s7
    blez $s5, fechar_limpar_mesa

    li $v0, 4
    la $a0, msg_err_saldo_aberto
    syscall
    move $a0, $s5
    jal print_centavos
    li $v0, 4
    la $a0, msg_nl
    syscall
    j loop

fechar_limpar_mesa:
    sll $t1, $s1, 2
    sw $zero, mesas_status($t1)
    sw $zero, mesas_nome($t1)
    sw $zero, mesas_telefone($t1)
    sw $zero, mesas_pago($t1)

    li $t0, 1
fechar_clear_itens:
    li $t8, 21
    beq $t0, $t8, fechar_ok_msg
    li $t3, 21
    mul $t4, $s1, $t3
    add $t4, $t4, $t0
    sll $t4, $t4, 2
    sw $zero, mesas_pedidos_qtd($t4)
    addi $t0, $t0, 1
    j fechar_clear_itens

fechar_ok_msg:
    li $v0, 4
    la $a0, msg_mesa_fechada_ok
    syscall
    j loop

# formatar (zera tudo em RAM, nao salva automaticamente)
do_formatar_global:
    jal clear_cardapio
    jal clear_mesas
    li $v0, 4
    la $a0, msg_formatar_ok
    syscall
    j loop

# salvar (persistencia completa)
do_salvar:
    li $v0, 13
    la $a0, db_file
    li $a1, 1          # write/create
    li $a2, 420        # 0644 em decimal
    syscall
    bltz $v0, file_err
    move $s0, $v0

    # 1) precos[1..20] (80 bytes)
    li $v0, 15
    move $a0, $s0
    la $a1, precos+4
    li $a2, 80
    syscall

    # 2) descricoes[1..20], cada uma 64 bytes
    li $t0, 1
salva_desc_loop:
    li $t8, 21
    beq $t0, $t8, salva_status

    sll $t1, $t0, 2
    lw $t2, descricoes($t1)

    la $a0, tmp_desc_buf
    li $a1, 64
    jal memset_zero

    beq $t2, $zero, salva_desc_write
    la $a0, tmp_desc_buf
    move $a1, $t2
    li $a2, 63
    jal strncpy_n

salva_desc_write:
    li $v0, 15
    move $a0, $s0
    la $a1, tmp_desc_buf
    li $a2, 64
    syscall

    addi $t0, $t0, 1
    j salva_desc_loop

salva_status:
    # 3) mesas_status[1..15] (60 bytes)
    li $v0, 15
    move $a0, $s0
    la $a1, mesas_status+4
    li $a2, 60
    syscall

    # 4) mesas_pago[1..15] (60 bytes)
    li $v0, 15
    move $a0, $s0
    la $a1, mesas_pago+4
    li $a2, 60
    syscall

    # 5) pedidos [1..15][1..20] (300 words)
    li $t0, 1
salva_ped_mesa:
    li $t8, 16
    beq $t0, $t8, salva_nomes
    li $t2, 1
salva_ped_item:
    li $t9, 21
    beq $t2, $t9, salva_ped_next_mesa

    li $t3, 21
    mul $t4, $t0, $t3
    add $t4, $t4, $t2
    sll $t4, $t4, 2

    li $v0, 15
    move $a0, $s0
    la $a1, mesas_pedidos_qtd($t4)
    li $a2, 4
    syscall

    addi $t2, $t2, 1
    j salva_ped_item

salva_ped_next_mesa:
    addi $t0, $t0, 1
    j salva_ped_mesa

salva_nomes:
    # 6) nomes[1..15], cada um 64 bytes
    li $t0, 1
salva_nome_loop:
    li $t8, 16
    beq $t0, $t8, salva_fones

    sll $t1, $t0, 2
    lw $t2, mesas_nome($t1)

    la $a0, tmp_nome_buf
    li $a1, 64
    jal memset_zero

    beq $t2, $zero, salva_nome_write
    la $a0, tmp_nome_buf
    move $a1, $t2
    li $a2, 63
    jal strncpy_n

salva_nome_write:
    li $v0, 15
    move $a0, $s0
    la $a1, tmp_nome_buf
    li $a2, 64
    syscall

    addi $t0, $t0, 1
    j salva_nome_loop

salva_fones:
    # 7) telefones[1..15], cada um 16 bytes
    li $t0, 1
salva_fone_loop:
    li $t8, 16
    beq $t0, $t8, salva_close

    sll $t1, $t0, 2
    lw $t2, mesas_telefone($t1)

    la $a0, tmp_fone_buf
    li $a1, 16
    jal memset_zero

    beq $t2, $zero, salva_fone_write
    la $a0, tmp_fone_buf
    move $a1, $t2
    li $a2, 15
    jal strncpy_n

salva_fone_write:
    li $v0, 15
    move $a0, $s0
    la $a1, tmp_fone_buf
    li $a2, 16
    syscall

    addi $t0, $t0, 1
    j salva_fone_loop

salva_close:
    li $v0, 16
    move $a0, $s0
    syscall

    li $v0, 4
    la $a0, msg_salvar_ok
    syscall
    j loop

# recarregar (descarta nao salvo e le do arquivo)
do_recarregar:
    jal carregar_arquivo_forcado
    j loop

do_exit:
    li $v0, 4
    la $a0, msg_exit
    syscall
    li $v0, 10
    syscall

# ==========================================================================================
# PERSISTENCIA
# ==========================================================================================

# autoload sem mensagem de erro se nao existir
carregar_arquivo_auto:
    li $v0, 13
    la $a0, db_file
    li $a1, 0
    li $a2, 0
    syscall
    bltz $v0, cauto_end

    move $s0, $v0
    jal carregar_blocos_com_fd

    li $v0, 16
    move $a0, $s0
    syscall
cauto_end:
    jr $ra

carregar_arquivo_forcado:
    li $v0, 13
    la $a0, db_file
    li $a1, 0
    li $a2, 0
    syscall
    bltz $v0, file_err_ret

    move $s0, $v0
    jal carregar_blocos_com_fd

    li $v0, 16
    move $a0, $s0
    syscall

    li $v0, 4
    la $a0, msg_recarregar_ok
    syscall
    jr $ra

# leitura do layout binario completo com fd em $s0
carregar_blocos_com_fd:
    # limpa tudo antes de carregar
    jal clear_cardapio
    jal clear_mesas

    # 1) precos[1..20]
    li $v0, 14
    move $a0, $s0
    la $a1, precos+4
    li $a2, 80
    syscall

    # 2) descricoes[1..20], blocos de 64
    li $t0, 1
load_desc_loop:
    li $t8, 21
    beq $t0, $t8, load_status

    li $v0, 14
    move $a0, $s0
    la $a1, tmp_desc_buf
    li $a2, 64
    syscall

    lb $t2, tmp_desc_buf
    beq $t2, $zero, load_desc_null

    li $v0, 9
    li $a0, 64
    syscall
    move $t3, $v0

    move $a0, $t3
    la $a1, tmp_desc_buf
    jal strcpy

    sll $t1, $t0, 2
    sw $t3, descricoes($t1)
    j load_desc_next

load_desc_null:
    sll $t1, $t0, 2
    sw $zero, descricoes($t1)

load_desc_next:
    addi $t0, $t0, 1
    j load_desc_loop

load_status:
    # 3) mesas_status[1..15]
    li $v0, 14
    move $a0, $s0
    la $a1, mesas_status+4
    li $a2, 60
    syscall

    # 4) mesas_pago[1..15]
    li $v0, 14
    move $a0, $s0
    la $a1, mesas_pago+4
    li $a2, 60
    syscall

    # 5) pedidos [1..15][1..20]
    li $t0, 1
load_ped_mesa:
    li $t8, 16
    beq $t0, $t8, load_nomes
    li $t2, 1
load_ped_item:
    li $t9, 21
    beq $t2, $t9, load_ped_next_mesa

    li $t3, 21
    mul $t4, $t0, $t3
    add $t4, $t4, $t2
    sll $t4, $t4, 2

    li $v0, 14
    move $a0, $s0
    la $a1, mesas_pedidos_qtd($t4)
    li $a2, 4
    syscall

    addi $t2, $t2, 1
    j load_ped_item

load_ped_next_mesa:
    addi $t0, $t0, 1
    j load_ped_mesa

load_nomes:
    # 6) nomes[1..15], blocos de 64
    li $t0, 1
load_nome_loop:
    li $t8, 16
    beq $t0, $t8, load_fones

    li $v0, 14
    move $a0, $s0
    la $a1, tmp_nome_buf
    li $a2, 64
    syscall

    lb $t2, tmp_nome_buf
    beq $t2, $zero, load_nome_null

    li $v0, 9
    li $a0, 64
    syscall
    move $t3, $v0

    move $a0, $t3
    la $a1, tmp_nome_buf
    jal strcpy

    sll $t1, $t0, 2
    sw $t3, mesas_nome($t1)
    j load_nome_next

load_nome_null:
    sll $t1, $t0, 2
    sw $zero, mesas_nome($t1)

load_nome_next:
    addi $t0, $t0, 1
    j load_nome_loop

load_fones:
    # 7) telefones[1..15], blocos de 16
    li $t0, 1
load_fone_loop:
    li $t8, 16
    beq $t0, $t8, load_end

    li $v0, 14
    move $a0, $s0
    la $a1, tmp_fone_buf
    li $a2, 16
    syscall

    lb $t2, tmp_fone_buf
    beq $t2, $zero, load_fone_null

    li $v0, 9
    li $a0, 16
    syscall
    move $t3, $v0

    move $a0, $t3
    la $a1, tmp_fone_buf
    jal strcpy

    sll $t1, $t0, 2
    sw $t3, mesas_telefone($t1)
    j load_fone_next

load_fone_null:
    sll $t1, $t0, 2
    sw $zero, mesas_telefone($t1)

load_fone_next:
    addi $t0, $t0, 1
    j load_fone_loop

load_end:
    jr $ra

file_err_ret:
    li $v0, 4
    la $a0, msg_file_err
    syscall
    jr $ra

# ==========================================================================================
# LIMPEZA
# ==========================================================================================

clear_cardapio:
    li $t0, 1
cc_loop:
    li $t8, 21
    beq $t0, $t8, cc_end
    sll $t1, $t0, 2
    sw $zero, precos($t1)
    sw $zero, descricoes($t1)
    addi $t0, $t0, 1
    j cc_loop
cc_end:
    jr $ra

clear_mesas:
    li $t0, 1
cm_mesa_loop:
    li $t8, 16
    beq $t0, $t8, cm_end

    sll $t1, $t0, 2
    sw $zero, mesas_status($t1)
    sw $zero, mesas_nome($t1)
    sw $zero, mesas_telefone($t1)
    sw $zero, mesas_pago($t1)

    li $t2, 1
cm_item_loop:
    li $t8, 21
    beq $t2, $t8, cm_next_mesa
    li $t3, 21
    mul $t4, $t0, $t3
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    sw $zero, mesas_pedidos_qtd($t4)
    addi $t2, $t2, 1
    j cm_item_loop

cm_next_mesa:
    addi $t0, $t0, 1
    j cm_mesa_loop

cm_end:
    jr $ra

# ==========================================================================================
# AUXILIARES
# ==========================================================================================

# print_centavos($a0=valor_em_centavos)
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
    li $a0, 44          # ','
    syscall

    li $t8, 10
    bge $t1, $t8, pt_print_resto
    li $v0, 11
    li $a0, 48          # '0'
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
sn11_loop:
    li $t8, 11
    beq $t7, $t8, sn11_eq
    lb $t2, 0($a0)
    lb $t3, 0($a1)
    bne $t2, $t3, sn11_diff
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j sn11_loop
sn11_diff:
    li $v0, 1
    jr $ra
sn11_eq:
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

# memset_zero($a0=dst, $a1=len)
memset_zero:
    move $t0, $a0
    move $t1, $a1
mz_loop:
    beq $t1, $zero, mz_end
    sb $zero, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    j mz_loop
mz_end:
    jr $ra

# strncpy_n($a0=dst, $a1=src, $a2=max_chars)
# copia no max a2 chars e garante terminador
strncpy_n:
    move $t0, $a0
    move $t1, $a1
    move $t2, $a2
sncpy_loop:
    beq $t2, $zero, sncpy_term
    lb $t3, 0($t1)
    beq $t3, $zero, sncpy_term
    sb $t3, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    j sncpy_loop
sncpy_term:
    sb $zero, 0($t0)
    jr $ra

# ==========================================================================================
# ERROS
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

err_item_sem_cad:
    li $v0, 4
    la $a0, msg_err_item_sem_cad
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

file_err:
    li $v0, 4
    la $a0, msg_file_err
    syscall
    j loop
