	.file	"test_leaf.c"
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
	.globl	leaf_buf
	.type	leaf_buf, @function
leaf_buf:
	addi	sp,sp,-64
	sw	ra,60(sp)
	sw	s0,56(sp)
	addi	s0,sp,64
	sw	a0,-52(s0)
	lw	a5,-52(s0)
	sw	a5,-48(s0)
	sw	zero,-44(s0)
	j	.L2
.L3:
	lw	a5,-44(s0)
	andi	a4,a5,0xff
	lw	a5,-44(s0)
	addi	a4,a4,1
	andi	a4,a4,0xff
	addi	a5,a5,-16
	add	a5,a5,s0
	sb	a4,-24(a5)
	lw	a5,-44(s0)
	addi	a5,a5,1
	sw	a5,-44(s0)
.L2:
	lw	a4,-44(s0)
	li	a5,23
	bleu	a4,a5,.L3
	sw	zero,-44(s0)
	j	.L4
.L5:
	lw	a5,-44(s0)
	addi	a5,a5,-16
	add	a5,a5,s0
	lbu	a5,-24(a5)
	andi	a5,a5,0xff
	mv	a4,a5
	lw	a5,-48(s0)
	add	a5,a4,a5
	sw	a5,-48(s0)
	lw	a5,-44(s0)
	addi	a5,a5,1
	sw	a5,-44(s0)
.L4:
	lw	a4,-44(s0)
	li	a5,23
	bleu	a4,a5,.L5
	lw	a4,-48(s0)
	lui	a5,%hi(sink)
	sw	a4,%lo(sink)(a5)
	lw	a5,-48(s0)
	mv	a0,a5
	lw	ra,60(sp)
	lw	s0,56(sp)
	addi	sp,sp,64
	jr	ra
	.size	leaf_buf, .-leaf_buf
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	li	a0,3
	call	leaf_buf
	mv	a5,a0
	mv	a0,a5
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
