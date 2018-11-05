# Integrantes: 
# 	Alvaro Avila 	15-10103
# 	Luis Paredes 	11-10740
# Proyecto: Maquina Virtual Mips Ligero (MVML)
# Objetivo: Desarrollar una maquina virtual capaz de reconocer instrucciones de 
#	un archivo externo y ejecutarlas.


.data
msg: 		.word welcome compiling searching_inst decoding_regis file_not_found execution_end

welcome: 	.asciiz "Bienvenido, por favor introduzca el archivo que contiene el programa ensamblado\n"
compiling: 	.asciiz "Analizando archivo\n"
searching_inst:	.asciiz "Buscando instrucciones\n"
decoding_regis:	.asciiz "Decodificando registros\n"
file_not_found:	.asciiz "No se encontro el archivo especificado\n"
invalid_inst: 	.asciiz "Instruccion invalida\n"
execution_end: 	.asciiz "Se ejecuto el programa exitosamente"

.align 2
program_path: 	.space 64
buffer: 	.space 600
program: 	.space 400

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
	beqz 	$t0, _end_of_program
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
