.text
.globl mli~
.globl save1~,unknown~,mli4~

mli~:
	cmp	r0,$04
	bgt	1f
	beq	2f
	mov	(sp)+,r0
	mov	(sp)+,r1
	mul	(sp)+,r1
	mov	r1,-(sp)
	jmp	(r0)
2:	mov	(sp)+,save1~
	jsr	pc,mli4~
	mov	r1,-(sp)
	mov	r0,-(sp)
	jmp	*save1~
1:	jmp	unknown~
