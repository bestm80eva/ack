.text
.globl sbi~
.globl unknown~

sbi~:
	mov	(sp)+,r1
	cmp	r0,$04
	bgt	1f
	cmp	r0,$02
	bgt	2f
	sub	(sp)+,(sp)
	jmp	(r1)
2:	sub	(sp)+,02(sp)
	sub	(sp)+,02(sp)
	sbc	(sp)
	jmp	(r1)
1:
	jmp	unknown~
