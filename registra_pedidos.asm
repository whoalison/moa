# ==========================================================================================
# UFRPE - Universidade Federal Rural de Pernambuco
# Disciplina: Arquitetura e Organizacao de Computadores - 2026.1
# Atividade: Projeto 01 (1a VA) - Assembly MIPS e Simulador MARS
# Grupo: Murilo, Alisson, Otavio
# Arquivo principal do sistema de gerenciamento de restaurante (MOA)
# Descricao: Implementacao do interpretador de comandos (shell), Requisito 1 (Cardapio), 
# Requisito 2 (Mesas) e Requisito 3 (Pedidos).
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
	cmd_mesa_ad_item:  .asciiz "mesa_ad_item"             # Comando para adicionar item na conta
	cmd_mesa_rm_item:  .asciiz "mesa_rm_item"             # Comando para remover item da conta
	cmd_exit:          .asciiz "exit"                     # Comando para encerrar o programa
	
	# --- MENSAGENS DO SISTEMA ---
	msg_invalid:  .asciiz "Comando invalido\n"                         # Erro generico
	msg_list_h:   .asciiz "--- ITENS DO CARDAPIO ---\n"                # Cabecalho da lista
	msg_exit:     .asciiz "Encerrando sistema...\n"                    # Mensagem de saida
	msg_add_ok:   .asciiz "Item adicionado com sucesso\n"              # Sucesso R1
	msg_err_id:   .asciiz "Falha: código de item inválido\n"           # Erro R1
	msg_err_dup:  .asciiz "Falha: número de item já cadastrado\n"      # Erro R1
	msg_fmt_ok:   .asciiz "Cardapio formatado com sucesso\n"           # Sucesso format
	
	msg_mesa_ok:     .asciiz "Atendimento iniciado com sucesso\n"      # Sucesso R2
	msg_err_mesa_oc: .asciiz "Falha: mesa ocupada\n"                   # Erro R2
	msg_err_mesa_in: .asciiz "Falha: mesa inexistente\n"               # Erro R2/R3
	
	msg_mesa_ad_ok:         .asciiz "Item adicionado com sucesso\n"              # Sucesso R3 (Add)
	msg_mesa_rm_ok:         .asciiz "Item removido com sucesso\n"                # Sucesso R3 (Rm)
	msg_err_mesa_vazia:     .asciiz "Falha: mesa nao iniciou atendimento\n"      # Erro R3
	msg_err_item_in:        .asciiz "Falha: codigo do item invalido\n"           # Erro R3
	msg_err_item_nc:        .asciiz "Falha: item não cadastrado no cardápio\n"   # Erro R3
	msg_err_item_nao_conta: .asciiz "Falha: item nao consta na conta\n"          # Erro R3
	
	# --- ESTRUTURA DE DADOS: R1 (CARDAPIO) ---
	# Arrays para 20 itens. Tamanho 21 usado para que o ID 01 aponte para o indice 1
	precos:      .word 0:21     # Array para guardar os precos em centavos
	descricoes:  .word 0:21     # Array para guardar os ponteiros das strings de descricao
	
	# --- ESTRUTURA DE DADOS: R2 (MESAS) ---
	# Arrays para 15 mesas. Tamanho 16 usado para que o ID 01 aponte para o indice 1
	mesas_status:   .word 0:16  # 0 = desocupada, 1 = ocupada
	mesas_nome:     .word 0:16  # Array de ponteiros para strings dos nomes dos responsaveis
	mesas_telefone: .word 0:16  # Array de ponteiros para strings dos telefones

	# --- ESTRUTURA DE DADOS: R3 (PEDIDOS) ---
	# Matriz para pedidos: 16 mesas * 21 itens = 336 words (1344 bytes)
	# Indice calculado como: (ID_Mesa * 21) + ID_Item
	mesas_pedidos_qtd: .word 0:336

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
    la $a1, cmd_cardapio_list   # Parametro 2: String alvo
    jal strcmp                  # Compara as duas strings
    beq $v0, $zero, do_list     # Se iguais, desvia para listagem
    
    # TESTE: cardapio_format
    la $a0, input_buffer        # Parametro 1: Entrada do usuario
    la $a1, cmd_format          # Parametro 2: String alvo
    jal strcmp                  # Compara
    beq $v0, $zero, do_format   # Se iguais, desvia para formatacao
    
    # TESTE: exit
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_exit            # Parametro 2: String alvo
    jal strcmp                  # Compara
    beq $v0, $zero, do_exit     # Se iguais, desvia para encerramento
    
    # TESTE: cardapio_ad (Prefixo de 11 caracteres)
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_cardapio_ad     # Parametro 2: String alvo
    jal strncmp_11              # Compara apenas os 11 primeiros caracteres
    beq $v0, $zero, do_register # Se o prefixo bater, inicia rotina de cadastro
    
    # TESTE: mesa_iniciar (Prefixo de 12 caracteres)
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_mesa_iniciar    # Parametro 2: String alvo
    jal strncmp_12              # Compara os 12 primeiros caracteres
    beq $v0, $zero, do_mesa_iniciar # Se bater, inicia atendimento

    # TESTE: mesa_ad_item (Prefixo de 12 caracteres)
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_mesa_ad_item    # Parametro 2: String alvo
    jal strncmp_12              # Compara os 12 primeiros caracteres
    beq $v0, $zero, do_mesa_ad_item # Se bater, adiciona pedido

    # TESTE: mesa_rm_item (Prefixo de 12 caracteres)
    la $a0, input_buffer        # Parametro 1: Entrada
    la $a1, cmd_mesa_rm_item    # Parametro 2: String alvo
    jal strncmp_12              # Compara os 12 primeiros caracteres
    beq $v0, $zero, do_mesa_rm_item # Se bater, remove pedido
    
    # COMANDO INVALIDO
    li $v0, 4                   # Syscall print string
    la $a0, msg_invalid         # Carrega mensagem de erro
    syscall                     # Imprime
    j loop                      # Retorna ao inicio

# ==========================================================================================
# ROTINAS DO REQUISITO 2 (R2) E REQUISITO 3 (R3) - MESAS E PEDIDOS
# ==========================================================================================

# COMANDO: do_mesa_iniciar (R2)
do_mesa_iniciar:
    la $a0, input_buffer        # Carrega buffer
    li $a1, '-'                 # Hifen separador
    jal find_char               # Busca 1o hifen
    move $s0, $v0               # Salva posicao
    beq $s0, $zero, err_mesa_in # Erro se nao achou

    addi $a0, $s0, 1            # Ponteiro do Codigo Mesa
    jal str_to_int_2            # Converte para int
    move $s1, $v0               # $s1 = ID da mesa

    li $t8, 1                   # Minimo 1
    blt $s1, $t8, err_mesa_in   # Erro
    li $t8, 15                  # Maximo 15
    bgt $s1, $t8, err_mesa_in   # Erro

    sll $t1, $s1, 2             # Offset (ID * 4)
    lw $t2, mesas_status($t1)   # Verifica status
    bne $t2, $zero, err_mesa_oc # Erro se ocupada

    addi $a0, $s0, 1            # Busca 2o hifen (Telefone)
    li $a1, '-'                 
    jal find_char               
    move $s0, $v0               
    addi $s4, $s0, 1            # Inicio do telefone

    addi $a0, $s0, 1            # Busca 3o hifen (Nome)
    li $a1, '-'                 
    jal find_char               
    move $s0, $v0               
    addi $s5, $s0, 1            # Inicio do nome

    sb $zero, 0($s0)            # Isola string de telefone com \0

    li $v0, 9                   # Aloca memoria pro telefone (16 bytes)
    li $a0, 16                  
    syscall                     
    move $s6, $v0               

    move $a0, $s6               # Copia telefone
    move $a1, $s4               
    jal strcpy                  

    li $v0, 9                   # Aloca memoria pro nome (64 bytes)
    li $a0, 64                  
    syscall                     
    move $s7, $v0               

    move $a0, $s7               # Copia nome
    move $a1, $s5               
    jal strcpy                  

    sll $t1, $s1, 2             # Salva dados (R2)
    li $t2, 1                   
    sw $t2, mesas_status($t1)   # Ocupa mesa
    sw $s6, mesas_telefone($t1) # Salva ptr telefone
    sw $s7, mesas_nome($t1)     # Salva ptr nome

    li $v0, 4                   # Sucesso
    la $a0, msg_mesa_ok         
    syscall                     
    j loop                      

# COMANDO: do_mesa_ad_item (R3)
do_mesa_ad_item:
    la $a0, input_buffer        # Buffer
    li $a1, '-'                 # Hifen
    jal find_char               # Busca hifen
    move $s0, $v0               
    beq $s0, $zero, err_mesa_in 

    addi $a0, $s0, 1            # Extrai ID Mesa
    jal str_to_int_2            
    move $s1, $v0               
    
    li $t8, 1                   # Valida Mesa
    blt $s1, $t8, err_mesa_in   
    li $t8, 15                  
    bgt $s1, $t8, err_mesa_in   

    sll $t1, $s1, 2             # Verifica se mesa ta vazia
    lw $t2, mesas_status($t1)   
    beq $t2, $zero, err_mesa_vazia 

    addi $a0, $s0, 1            # Extrai ID Item
    li $a1, '-'                 
    jal find_char               
    move $s0, $v0               
    addi $a0, $s0, 1            
    jal str_to_int_2            
    move $s2, $v0               

    li $t8, 1                   # Valida Item
    blt $s2, $t8, err_item_in   
    li $t8, 20                  
    bgt $s2, $t8, err_item_in   

    sll $t1, $s2, 2             # Checa se ta no cardapio
    lw $t2, descricoes($t1)     
    beq $t2, $zero, err_item_nc 

    li $t3, 21                  # Matriz: Mesa * 21 + Item
    mul $t1, $s1, $t3           
    add $t1, $t1, $s2           
    sll $t1, $t1, 2             

    lw $t2, mesas_pedidos_qtd($t1)  # Adiciona 1 ao contador
    addi $t2, $t2, 1                
    sw $t2, mesas_pedidos_qtd($t1)  

    li $v0, 4                   # Sucesso
    la $a0, msg_mesa_ad_ok          
    syscall                         
    j loop                          

# COMANDO: do_mesa_rm_item (R3)
do_mesa_rm_item:
    la $a0, input_buffer        # Buffer
    li $a1, '-'                 # Hifen
    jal find_char               
    move $s0, $v0               
    beq $s0, $zero, err_mesa_in 

    addi $a0, $s0, 1            # Extrai ID Mesa
    jal str_to_int_2            
    move $s1, $v0               
    
    li $t8, 1                   # Valida Mesa
    blt $s1, $t8, err_mesa_in   
    li $t8, 15                  
    bgt $s1, $t8, err_mesa_in   

    sll $t1, $s1, 2             # Status Mesa
    lw $t2, mesas_status($t1)   
    beq $t2, $zero, err_mesa_vazia 

    addi $a0, $s0, 1            # Extrai ID Item
    li $a1, '-'                 
    jal find_char               
    move $s0, $v0               
    addi $a0, $s0, 1            
    jal str_to_int_2            
    move $s2, $v0               

    li $t8, 1                   # Valida Item
    blt $s2, $t8, err_item_in   
    li $t8, 20                  
    bgt $s2, $t8, err_item_in   

    li $t3, 21                  # Matriz: Mesa * 21 + Item
    mul $t1, $s1, $t3           
    add $t1, $t1, $s2           
    sll $t1, $t1, 2             

    lw $t2, mesas_pedidos_qtd($t1)     # Remove 1 do contador
    beq $t2, $zero, err_item_nao_conta # Erro se qtd for 0

    addi $t2, $t2, -1               
    sw $t2, mesas_pedidos_qtd($t1)  

    li $v0, 4                   # Sucesso
    la $a0, msg_mesa_rm_ok          
    syscall                         
    j loop                          

# ==========================================================================================
# ROTINAS DO REQUISITO 1 (R1) - CARDAPIO
# ==========================================================================================
do_register:
    la $a0, input_buffer        
    li $a1, '-'                 
    jal find_char               
    move $s0, $v0               
    beq $s0, $zero, err_id      

    addi $a0, $s0, 1            # Codigo
    jal str_to_int_2            
    move $s1, $v0               

    li $t8, 1                   
    blt $s1, $t8, err_id        
    li $t8, 20                  
    bgt $s1, $t8, err_id        

    sll $t1, $s1, 2             # Verifica se existe
    lw $t2, descricoes($t1)     
    bne $t2, $zero, err_dup     

    addi $a0, $s0, 1            # Preco
    li $a1, '-'                 
    jal find_char               
    move $s0, $v0               
    addi $a0, $s0, 1            
    jal str_to_int_5            
    move $s2, $v0               

    addi $a0, $s0, 1            # Descricao
    li $a1, '-'                 
    jal find_char               
    addi $s0, $v0, 1            

    li $v0, 9                   # Aloca string
    li $a0, 64                  
    syscall                     
    move $s3, $v0               

    move $a0, $s3               # Copia string
    move $a1, $s0               
    jal strcpy                  

    sll $t1, $s1, 2             # Grava R1
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

    li $v0, 1                   # Print ID
    move $a0, $t0               
    syscall                     

    li $v0, 11                  # Espaco
    li $a0, 32                  
    syscall                     

    lw $a0, precos($t1)         # Print Preco
    li $v0, 1                   
    syscall                     

    li $v0, 11                  # Espaco
    li $a0, 32                  
    syscall                     

    move $a0, $t2               # Print Descricao
    li $v0, 4                   
    syscall                     

    li $v0, 11                  # Quebra de linha
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
# FUNCOES AUXILIARES (STRINGS E CONVERSOES)
# ==========================================================================================

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