.text
main:
    jal verificar_teclado      # Vai ver se o usuário digitou algo
    jal verificar_monitor      # Vai ver se o monitor pode mostrar a letra
    
    j main  # Loop infinito: volta pra o início

verificar_teclado:	     	# Fica esperando até que uma tecla seja pressionada.
    li $t0, 0xFFFF0000         	# Endereço que avisa se houve digitação
    lw $t1, 0($t0)            	# Lê o aviso (0 = nada, 1 = tecla pronta)
    beqz $t1, verificar_teclado # Se for 0, continua perguntando (loop)

    # Salva o endereço de retorno na pilha para não se perder
    addi $sp, $sp, -4          
    sw $ra, 0($sp)             
    
    jal pegar_letra_digitada   # Vai buscar a letra que foi apertada
    
    lw $ra, 0($sp)             # Recupera o endereço de retorno
    addi $sp, $sp, 4           
    
    jr $ra                     # Volta para a main
    

verificar_monitor:		# Espera o monitor estar pronto para receber uma nova letra.
    li $t0, 0xFFFF0008         	# Endereço que avisa se o monitor está pronto
    lw $t1, 0($t0)             	# Lê o aviso (0 = ocupado, 1 = pronto)
    beqz $t1, verificar_monitor # Se for 0, espera o monitor liberar

    # Salva o endereço de retorno na pilha
    addi $sp, $sp, -4          
    sw $ra, 0($sp)
    
    jal enviar_letra_ao_monitor # Vai mandar a letra para a tela
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra                     # Volta para a main

pegar_letra_digitada:
    li $t0, 0xFFFF0004         # Endereço onde a letra digitada fica guardada
    lw $t2, 0($t0)             # Salva a letra no registrador $t2
    jr $ra                     

enviar_letra_ao_monitor:
    li $t0, 0xFFFF000C         # Endereço que mostra a letra na tela
    sw $t2, 0($t0)             # Pega a letra de $t2 e joga no monitor
    jr $ra