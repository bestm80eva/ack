.sect .text; .sect .rom; .sect .data; .sect .bss
.define .exg

	! #bytes in cx
.sect .text
.exg:
	push	di
	mov	di,sp
	add	di,4
	mov	bx,di
	add	bx,cx
	sar     cx,1
1:
	mov	ax,(bx)
	xchg	ax,(di)
	mov	(bx),ax
	add	di,2
	add	bx,2
	loop	1b
2:
	pop	di
	ret
