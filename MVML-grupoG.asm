# Integrantes: 
# 	Alvaro Avila 	15-10103
# 	Luis Paredes 	11-10740
# Proyecto: Maquina Virtual Mips Ligero (MVML)
# Objetivo: Desarrollar una maquina virtual capaz de reconocer instrucciones de 
#	un archivo externo y ejecutarlas.

.data

welcome: 	.asciiz "Bienvenido, por favor introduzca el archivo que contiene el programa ensamblado\n"
compiling: 	.asciiz "Analizando archivo\n"
searching_inst:	.asciiz "Buscando instrucciones\n"
decoding_regis:	.asciiz "Decodificando registros\n"
executing_prog:	.asciiz "Ejecutando Progama\n"
file_not_found:	.asciiz "No se encontro el archivo especificado\n"
invalid_inst: 	.asciiz "Instruccion invalida\n"
execution_end: 	.asciiz "Se ejecuto el programa exitosamente"

i_add: 		.asciiz "	R add" 
i_addi: 	.asciiz "	I addi"
i_and: 		.asciiz " 	R and"
i_andi: 	.asciiz "	I andi"
i_mult: 	.asciiz " 	R mult"
i_or: 		.asciiz " 	R or"
i_ori: 		.asciiz " 	I ori"
i_sllv: 	.asciiz " 	R sllv"
i_sub: 		.asciiz " 	R sub"

i_lw: 		.asciiz "	I lw"
i_sw: 		.asciiz "	I sw"

i_bne: 		.asciiz "	I bne"
i_beq: 		.asciiz " 	I beq"

i_halt: 	.asciiz "	R halt\n"

dollar_sign: 	.asciiz " $"
space: 		.asciiz " "
line_feed: 	.asciiz "\n"
open_brackets: 	.asciiz "($"
close_brackets: .asciiz ")\n"

.align 2
program_path: 	.space 64
buffer: 	.space 600
program: 	.space 400
registers: 	.space 128
.align 2
memoria: 	.space 2000

.text


# starts the virtual machine and asks for the file to read
_start:
	li 	$v0, 4 			# Print String syscall code	
	la 	$a0, welcome		# syscall String argument
	syscall
	
	li	$v0, 8 			# Read String syscall	
	la 	$a0, program_path
	li 	$a1, 64			# Max num of chars to read
	syscall				
	
	b	_open_file
	
	
_open_file:
	# Locates the line feed at the end of the input
	addi 	$a0, $a0, 1
	lb	$a1, ($a0)
	bne 	$a1, 10, _open_file 	# loop if this is not the line feed
	li 	$a1, 0
	sb 	$a1, ($a0) 		# Replace the line feed with /0
	
	# Open File
	li 	$v0, 13 		# Open File syscall
	la 	$a0, program_path
	li 	$a1, 0			# File for Read only
	li	$a2, 0
	syscall
	move 	$t0, $v0 		# Save File descriptor into $t0
	
	li 	$v0, 4	
	la 	$a0, compiling
	syscall
	
	bltz 	$t0, _err_file
	b 	_read_file
	
	
_read_file:
	la 	$a0, searching_inst
	li 	$v0, 4
	syscall
	
	li 	$v0, 14			# Read File syscall	
	move	$a0, $t0
	la 	$a1, buffer
	li 	$a2, 800
	syscall
	
	la 	$a2, program 		
	b 	_read_char_loop
	
	
_read_next_char:
	addi 	$a1, $a1, 1
	b 	_read_char_loop
	
	
_read_char_loop:
	lb 	$t0, ($a1) 		# $a1 points to the actual reading byte
	addi 	$t2, $t2, 1		# Counter to watch when we read a complete instruction
	bge 	$t0, 0x61, _read_letter	
	bge 	$t0, 0x30, _read_number
	beqz 	$t0, _execute_program
	b 	_err_invalid_instruction
	
	
_read_letter:
	sub 	$t1, $t0, 0x57
	addu 	$t3, $t3, $t1 		# $t3 stores the actual instruction being written
	beq 	$t2, 8, _save_word
	sll 	$t3, $t3, 4
	b 	_read_next_char


_read_number:
	sub 	$t1, $t0, 0x30
	addu 	$t3, $t3, $t1 		# $t3 stores the actual instruction being written
	beq 	$t2, 8, _save_word
	sll 	$t3, $t3, 4
	b 	_read_next_char
	

_save_word:
	sw 	$t3, ($a2) 		# Save the instruction at $t3
	addi 	$a2, $a2, 4
	li 	$t2, 0
	li 	$t3, 0
	addi 	$a1, $a1, 3 		# Makes $a1 point to the next instruction
	b 	_read_char_loop


_execute_program:
	li 	$v0, 4
	la 	$a0, executing_prog
	syscall
	
	la 	$a2, program
	b 	_read_instruction
	

_read_next_instruction:
	addi 	$a2, $a2, 4


_read_instruction:
	# At the end of the label:
	# 	$t0 stores the number of the 1st Register found
	# 	$t1 stores the number of the 2nd Register found
	li 	$v0, 34 		# Prints hexadecimal value of the instruction
	lw 	$a0, ($a2)
	syscall
	
	move	$t4, $a0

	# The 4 lines below assume that every instruction is either R or I type
	srl 	$t0, $t4, 21 		# Retrieves 1st Register
	andi 	$t0, $t0, 0x1f
	srl 	$t1, $t4, 16 		# Retrieves 2nd Register
	andi 	$t1, $t1, 0x1f
	
	srl 	$a1, $t4, 26 		# Retrieves Operation Code
	li 	$v0, 4
	beq 	$a1, 0x20, _add
	beq 	$a1, 0x08, _addi
	beq 	$a1, 0x28, _and
	beq 	$a1, 0x0c, _andi
	beq 	$a1, 0x18, _mult
	beq 	$a1, 0x25, _or
	beq 	$a1, 0x0d, _ori
	beq 	$a1, 0x04, _sllv
	beq 	$a1, 0x22, _sub
	
	beq 	$a1, 0x23, _lw
	beq 	$a1, 0x2b, _sw
	
	beq 	$a1, 0x05, _bne
	beq 	$a1, 0x06, _beq
	
	beqz 	$a1, _halt
	
	b 	_err_invalid_instruction


_print_3regs:
	# When this label is executed:
	# 	$t0 stores the number of the 1st register of the instruction
	# 	$t1 stores the number of the 2nd register of the instruction
	srl 	$t2, $t4, 11		# Extracts the destiny register
	andi 	$t2, $t2, 0x1f
	
	la 	$a0, dollar_sign
	syscall
	li 	$v0, 1 			# Prints destiny register
	move 	$a0, $t2		
	syscall
	li 	$v0, 4
	la 	$a0, dollar_sign
	syscall
	li 	$v0, 1 			# Prints 1st source register
	move 	$a0, $t0
	syscall
	li 	$v0, 4
	la 	$a0, dollar_sign
	syscall
	li 	$v0, 1 			# Prints 2nd source register
	move 	$a0, $t1
	syscall
	li 	$v0, 4
	la 	$a0, line_feed
	syscall
	
	# At this point, $t2 stores the 3rd register found in the instruction
	# This means:
	# 	$t2 stores the destiny register
	# 	$t0 stores the 1st source register
	# 	$t1 stores the 2nd source register
	# Now we access to the direction of these registers in the virtual machine
	sll 	$t0, $t0, 2
	lw 	$t0, registers($t0)
	sll 	$t1, $t1, 2
	lw 	$t1, registers($t1)
	sll 	$t2, $t2, 2
	la 	$t2, registers($t2)
	
	jr 	$ra


_print_2regs:
	andi 	$t3, $t4, 0x0000ffff	# Extracts the Integer offset
	
	la 	$a0, dollar_sign
	syscall
	li 	$v0, 1 			# Prints destiny register
	move 	$a0, $t1		
	syscall
	li 	$v0, 4
	la 	$a0, dollar_sign
	syscall
	li 	$v0, 1 			# Prints base register
	move 	$a0, $t0
	syscall
	li 	$v0, 4
	la 	$a0, space
	syscall
	li 	$v0, 1 			# Prints Integer Offset
	move 	$a0, $t3
	syscall
	li 	$v0, 4
	la 	$a0, line_feed
	syscall
	
	# At this point, $t3 stores the Integer Offset found in the instruction
	# This means:
	# 	$t3 stores the Integer Offset
	# 	$t0 stores the source register
	# 	$t1 stores the destiny register
	# Now we access to the value of these registers in the virtual machine
	sll	$t0, $t0, 2
	lw 	$t0, registers($t0)
	sll 	$t1, $t1, 2
	la 	$t1, registers($t1)
	
	jr	$ra
	

_print_lw_sw:
	andi 	$t3, $t4, 0x0000ffff	# Extracts the Integer offset
	
	la 	$a0, dollar_sign
	syscall
	li 	$v0, 1 			# Prints destiny register
	move 	$a0, $t1		
	syscall
	li 	$v0, 4
	la 	$a0, space
	syscall
	li 	$v0, 1 			# Prints Integer Offset
	move 	$a0, $t3
	syscall
	li 	$v0, 4
	la 	$a0, open_brackets
	syscall
	li 	$v0, 1 			# Prints source register
	move 	$a0, $t0
	syscall
	li 	$v0, 4
	la 	$a0, close_brackets
	syscall
	
	# At this point, $t3 stores the Integer Offset found in the instruction
	# This means:
	# 	$t3 stores the Integer Offset
	# 	$t0 stores the source register
	# 	$t1 stores the destiny register
	# Now we access to the value of these registers in the virtual machine
	sll 	$t0, $t0, 2
	lw 	$t0, registers($t0)
	sll 	$t1, $t1, 2
	la 	$t1, registers($t1)
	
	jr	$ra
	

# The following instructions with label equal to "_<name of MIPS instruction>"
# assume that:
# 	$t0 stores the 1st register found in the instruction
# 	$t1 stores the 2nd register found in the instruction
_add:
	la 	$a0, i_add
	syscall
	jal 	_print_3regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the 1st source register in the virtual machine
	# 	$t1 stores the value of the 2nd source register in the virtual machine
	# 	$t2 stores the value of the destiny register in te virtual machine
	# Executes the function and stores the result in $v0
	add 	$v0, $t0, $t1
	# Saves the function result in the desired register
	sw 	$v0, ($t2)
	b 	_read_next_instruction
_addi:
	la 	$a0, i_addi
	syscall
	jal 	_print_2regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the source register in the virtual machine
	# 	$t1 stores the value of the destiny register in the virtual machine
	# 	$t3 stores the Integer Offset of the instruction
	# Executes the function and stores the result in $v0
	add 	$v0, $t0, $t3
	# Saves the function result in the desired register
	sw 	$v0, ($t1)
	b 	_read_next_instruction
_and:
	la 	$a0, i_and
	syscall
	jal 	_print_3regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the 1st source register in the virtual machine
	# 	$t1 stores the value of the 2nd source register in the virtual machine
	# 	$t2 stores the value of the destiny register in te virtual machine
	# Executes the function and stores the result in $v0
	and 	$v0, $t0, $t1
	# Saves the function result in the desired register
	sw 	$v0, ($t2)
	b 	_read_next_instruction
_andi:
	la 	$a0, i_andi
	syscall
	jal 	_print_2regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the source register in the virtual machine
	# 	$t1 stores the value of the destiny register in the virtual machine
	# 	$t3 stores the Integer Offset of the instruction
	# Executes the function and stores the result in $v0
	and 	$v0, $t0, $t3
	# Saves the function result in the desired register
	sw 	$v0, ($t1)
	b 	_read_next_instruction
_mult:
	la 	$a0, i_mult
	syscall
	jal 	_print_3regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the 1st source register in the virtual machine
	# 	$t1 stores the value of the 2nd source register in the virtual machine
	# 	$t2 stores the value of the destiny register in te virtual machine
	# Executes the function and stores the result in $v0
	mult 	$t0, $t1
	mfhi	$v0
	# Saves the function result in the desired register
	sw	$v0, ($t2)
	b 	_read_next_instruction
_or:
	la 	$a0, i_or
	syscall
	jal 	_print_3regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the 1st source register in the virtual machine
	# 	$t1 stores the value of the 2nd source register in the virtual machine
	# 	$t2 stores the value of the destiny register in te virtual machine
	# Executes the function and stores the result in $v0
	or 	$v0, $t0, $t1
	# Saves the function result in the desired register
	sw	$v0, ($t2)
	b 	_read_next_instruction
_ori:
	la 	$a0, i_ori
	syscall
	jal 	_print_2regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the source register in the virtual machine
	# 	$t1 stores the value of the destiny register in the virtual machine
	# 	$t3 stores the Integer Offset of the instruction
	# Executes the function and stores the result in $v0
	or 	$v0, $t0, $t3
	# Saves the function result in the desired register
	sw 	$v0, ($t1)
	b 	_read_next_instruction
_sllv:
	la 	$a0, i_sllv
	syscall
	jal 	_print_3regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the 1st source register in the virtual machine
	# 	$t1 stores the value of the 2nd source register in the virtual machine
	# 	$t2 stores the value of the destiny register in te virtual machine
	# Executes the function and stores the result in $v0
	sllv 	$v0, $t0, $t1
	# Saves the function result in the desired register
	sw	$v0, ($t2)
	b 	_read_next_instruction
_sub:
	la 	$a0, i_sub
	syscall
	jal 	_print_3regs
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the 1st source register in the virtual machine
	# 	$t1 stores the value of the 2nd source register in the virtual machine
	# 	$t2 stores the value of the destiny register in te virtual machine
	# Executes the function and stores the result in $v0
	sub 	$v0, $t0, $t1
	# Saves the function result in the desired register
	sw	$v0, ($t2)
	b 	_read_next_instruction
_lw:
	la 	$a0, i_lw
	syscall
	jal 	_print_lw_sw
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the source register in the virtual machine
	# 	$t1 stores the value of the destiny register in the virtual machine
	# 	$t3 stores the Integer Offset of the instruction
	# Executes the function and stores the result in $v0
	add 	$t0, $t0, $t3 		# Calculates the total offset from the memory address
	la 	$t0, memoria($t0)	# Point $t0 to the requested memory address
	lw 	$v0, ($t0)		# Moves to $v0 the desired value to load from memory
	# Saves the function result in the desired register
	sw 	$v0, ($t1)
	b 	_read_next_instruction
_sw:
	la 	$a0, i_sw
	syscall
	jal 	_print_lw_sw
	# When the jal execution ends, we have that:
	# 	$t0 stores the value of the source register in the virtual machine
	# 	$t1 stores the value of the destinty register in the virtual machine
	# 	$t3 stores the Integer Offset of the instruction
	# Executes the function and stores the result in $v0
	add 	$t0, $t0, $t3 		# Calculates the total offset from the memory adress	
	lw 	$v0, ($t1)		# Moves to $v0 the desired value to store in memory
	# Saves the function result in the desired memory adress
	sw 	$v0, memoria($t0)
	b 	_read_next_instruction
_bne:
	la 	$a0, i_bne
	syscall
	jal 	_print_2regs
	b 	_read_next_instruction
_beq:
	la 	$a0, i_beq
	syscall
	jal 	_print_2regs
	b 	_read_next_instruction
_halt: 	
	la 	$a0, i_halt
	syscall
	jal 	_end_of_program
	b 	_read_next_instruction
	

_end_of_program:
	li 	$v0, 4
	la	$a0, execution_end
	syscall
	b 	_exit


# Error labels
_err_file:
	li 	$v0, 4
	la 	$a0, file_not_found
	syscall
	b 	_exit


_err_invalid_instruction:
	li 	$v0, 4
	la 	$a0, invalid_inst
	syscall
	b 	_exit
	
	
_exit:
