.data
msg: 		.word welcome compiling searchingInst decodingRegis fileNotFound executionEnd

welcome: 	.asciiz "Bienvenido, por favor introduzca el archivo que contiene el programa ensamblado\n"
compiling: 	.asciiz "Analizando archivo\n"
searchingInst:	.asciiz "Buscando instrucciones\n"
decodingRegis:	.asciiz "Decodificando registros\n"
fileNotFound:	.asciiz "No se encontro el archivo especificado\n"
executionEnd: 	.asciiz "Se ejecuto el programa exitosamente"

.align 2
programPath: 	.space 16
buffer: 	.space 8
program: 	.space 400

.text

main:
	la 	$a0, welcome		# syscall String argument
	li 	$v0, 4 			# Print String syscall code
	syscall
	
	la 	$a0, programPath
	li 	$a1, 16			# Max num of chars to read
	li	$v0, 8 			# Read String syscall
	syscall				# Read String is stored in buffer
	
	# Open File
	li 	$a1, 0			# File for Read only
	li	$a2, 0
	li 	$v0, 13 		# Open File syscall
	syscall
	move 	$t0, $v0 		# Save File descriptor into $t0
	
	la 	$a0, compiling
	li 	$v0, 4
	syscall
	
	bltz 	$t0, err_file
	b 	read_file
	
	
read_file:
	la 	$a0, searchingInst
	li 	$v0, 4
	syscall
	
	move	$a0, $t0
	la 	$a1, buffer
	li 	$a2, 8
	li 	$v0, 14			# Read File syscall
	syscall
	
	b 	end_of_program
	
	
end_of_program:
	la	$a0, executionEnd
	li 	$v0, 4
	syscall
	b 	exit

# Error labels
err_file:
	la 	$a0, fileNotFound
	li 	$v0, 4
	syscall
	b 	exit

	
exit: