.text
.globl ilar~
.globl lar~,trp~

EILLINS = 18.

ilar~:
	mov	(sp)+,r0
	cmp	(sp)+,$02
	bne	1f
	mov	02(sp),r1
	mov	r0,02(sp)
	mov	(sp)+,r0
	jmp	lar~
1:	mov	$EILLINS,-(sp)
	jsr	pc,trp~
	add	$06,sp
	jmp	(r0)
