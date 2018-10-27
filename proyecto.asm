.data
msg: 		.word welcome compiling searching_inst decoding_regis file_not_found execution_end

welcome: 	.asciiz "Bienvenido, por favor introduzca el archivo que contiene el programa ensamblado\n"
compiling: 	.asciiz "Analizando archivo\n"
searching_inst:	.asciiz "Buscando instrucciones\n"
decoding_regis:	.asciiz "Decodificando registros\n"
file_not_found:	.asciiz "No se encontro el archivo especificado\n"
execution_end: 	.asciiz "Se ejecuto el programa exitosamente"

.align 2
program_path: 	.space 16
buffer: 	.space 800
program: 	.space 400

.text

_start:
	la 	$a0, welcome		# syscall String argument
	li 	$v0, 4 			# Print String syscall code
	syscall
	
	la 	$a0, program_path
	li 	$a1, 16			# Max num of chars to read
	li	$v0, 8 			# Read String syscall
	syscall				
	
	b	_open_file
	
_open_file:
	# Locates the line feed at the end of the input
	addi 	$a0, $a0, 1
	lb	$a1, ($a0)
	bne 	$a1, 10, _open_file 	# loop if this is not the line feed
	li 	$a1, 0
	sb 	$a1, ($a0) 		# Replace the line feed with /0
	
	la 	$a0, program_path
	li 	$a1, 0			# File for Read only
	li	$a2, 0
	li 	$v0, 13 		# Open File syscall
	syscall
	move 	$t0, $v0 		# Save File descriptor into $t0
	
	la 	$a0, compiling
	li 	$v0, 4
	syscall
	
	bltz 	$t0, _err_file
	b 	_read_file
	
	
_read_file:
	la 	$a0, searching_inst
	li 	$v0, 4
	syscall
	
	move	$a0, $t0
	la 	$a1, buffer
	li 	$a2, 800
	li 	$v0, 14			# Read File syscall
	syscall
	
	b 	_read_char_loop
	
	
_read_next_char:
	addi 	$a1, $a1, 1
	b 	_read_char_loop
	
	
_read_char_loop:
	lb 	$t0, ($a1)
	bge 	$t0, 0x61, _read_letter
	bge 	$t0, 0x30, _read_number
	beqz 	$t0, _end_of_program
	# Else, it is reading a line feed
	addi 	$a1, $a1, 2
	b 	_read_char_loop
	
	
_read_letter:
	sub 	$t1, $t0, 0x61
	sb 	$t1, ($a1)
	b 	_read_next_char


_read_number:
	sub 	$t1, $t0, 0x30
	sb 	$t1, ($a1)
	b 	_read_next_char
	

_end_of_program:
	la	$a0, execution_end
	li 	$v0, 4
	syscall
	b 	_exit

# Error labels
_err_file:
	la 	$a0, file_not_found
	li 	$v0, 4
	syscall
	b 	_exit

	
_exit:
