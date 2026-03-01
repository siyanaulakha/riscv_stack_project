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
	addi sp, sp, -68
    la t6, __stack_chk_guard
    lw t5, 0(t6)
    sw t5, 0(sp)
	sw ra, 64(sp)

	sw s0, 60(sp)

	addi s0, sp, 68
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
	lw ra, 64(sp)

	lw s0, 60(sp)

    la t6, __stack_chk_guard
    lw t5, 0(sp)
    lw t4, 0(t6)
    bne t5, t4, __stack_chk_fail
	addi sp, sp, 68
	jr	ra
	.size	leaf_buf, .-leaf_buf
	.align	2
	.globl	main
	.type	main, @function
main:
	addi sp, sp, -20
    la t6, __stack_chk_guard
    lw t5, 0(t6)
    sw t5, 0(sp)
	sw ra, 16(sp)

	sw s0, 12(sp)

	addi s0, sp, 20
	li	a0,3
	call	leaf_buf
	mv	a5,a0
	mv	a0,a5
	lw ra, 16(sp)

	lw s0, 12(sp)

    la t6, __stack_chk_guard
    lw t5, 0(sp)
    lw t4, 0(t6)
    bne t5, t4, __stack_chk_fail
	addi sp, sp, 20
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits

    .section .data
    .align 2
    .globl __stack_chk_guard
__stack_chk_guard:
    .word 0x4a6863fb

    .section .text
    .align 2
    .globl __stack_chk_fail
__stack_chk_fail:
    li a0, 1
    li a7, 93
    ecall
.L__stack_chk_fail_hang:
    j .L__stack_chk_fail_hang
