	.file	"test_tamper.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	sink
	.section	.sbss,"aw",@nobits
	.align	2
	.type	sink, @object
	.size	sink, 4
sink:
	.zero	4
	.text
	.align	2
	.globl	victim
	.type	victim, @function
victim:
	addi	sp,sp,-80
	sw	ra,76(sp)
	sw	s0,72(sp)
	addi	s0,sp,80
	sw	a0,-68(s0)
	lw	a5,-68(s0)
	sw	a5,-56(s0)
	sw	zero,-52(s0)
	j	.L2
.L3:
	lw	a4,-52(s0)
	lw	a5,-52(s0)
	andi	a4,a4,0xff
	addi	a5,a5,-16
	add	a5,a5,s0
	sb	a4,-32(a5)
	lw	a5,-52(s0)
	addi	a5,a5,1
	sw	a5,-52(s0)
.L2:
	lw	a4,-52(s0)
	li	a5,31
	bleu	a4,a5,.L3
	sw	zero,-52(s0)
	j	.L4
.L5:
	lw	a5,-52(s0)
	addi	a5,a5,-16
	add	a5,a5,s0
	lbu	a5,-32(a5)
	andi	a5,a5,0xff
	mv	a4,a5
	lw	a5,-56(s0)
	add	a5,a4,a5
	sw	a5,-56(s0)
	lw	a5,-52(s0)
	addi	a5,a5,1
	sw	a5,-52(s0)
.L4:
	lw	a4,-52(s0)
	li	a5,31
	bleu	a4,a5,.L5
	lw	a4,-56(s0)
	lui	a5,%hi(sink)
	sw	a4,%lo(sink)(a5)
	lw	a5,-56(s0)
	mv	a0,a5
	lw	ra,76(sp)
	lw	s0,72(sp)
	addi	sp,sp,80
	jr	ra
	.size	victim, .-victim
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	li	a0,5
	call	victim
	mv	a5,a0
	mv	a0,a5
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
