.define .xor


! Any size exclusive-or.
! Expects:	size in de-registers
!		operands on stack
! Yields:	result on stack

.xor:	pop h
	shld .retadr
	mov h,b
	mov l,c
	shld .bcreg

	lxi h,0
	dad sp
	mov c,l
	mov b,h		!now bc points to top of first operand
	dad d		!and hl points to top of second operand
	push h		!this will be the new stackpointer
1:	ldax b
	xra m
	mov m,a
	inx h
	inx b
	dcx d
	mov a,e
	ora d
	jnz 1b

	pop h
	sphl

	lhld .bcreg
	mov b,h
	mov c,l
	lhld .retadr
	pchl
