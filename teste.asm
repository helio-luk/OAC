.data 
array:	.word	1 2 3 4 5 6 7 8 9 10

.text
	addi	$t0, $zero, 10		# t0 = 10
	addi	$t1, $zero, 20 		# t1 = 20
	add	$t2, $t1, $t0		# t2 = t1+t0 = 30
	sub	$t3, $t1, $t0		# t3 = t1-t0 = 10
	addi	$t4, $zero, 0x30F0	# t4 = 0x000030F0
	addi 	$t5, $zero, 0x3F00	# t5 = 0x00003F00
	and	$t6, $t5, $t4		# t6 = 0x00003000
	la	$s2, array		# s7 = &array[0]
	add	$v0, $zero, $zero 	# v0 = 0
	add	$v1, $zero, $zero	# v1 = 0
next:	
	add	$s0, $s2, $v1		# s0 = &array[i]
	lw	$s1, 0($s0)		# s1 = array[i]
	sll	$s1, $s1, 1		# s1 = s1 * 2
	slt	$a0, $v0, $t0		# a0 = v0 < 10
	addi	$v0, $v0, 1		# v0 = v0 + 1
	sll 	$v1, $v0, 2		# v1 = v0 * 4
	sw 	$s1, 0($s0)		# array[s0] = array[s0]*2
	beq 	$a0, $zero, fim		# se v0 ≥ 10 go fim
	sll	$zero, $zero, 0		# nop - beq não tem forward
	j 	next
	sll	$zero, $zero, 0		# nop - j não tem forward
fim:

