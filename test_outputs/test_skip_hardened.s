	.file	"test_skip.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	tiny
	.type	tiny, @function
tiny:
	addi sp, sp, -36
    la t6, __stack_chk_guard
    lw t5, 0(t6)
    sw t5, 0(sp)
	sw ra, 32(sp)

	sw s0, 28(sp)

	addi s0, sp, 36
	sw	a0,-20(s0)
	lw	a5,-20(s0)
	addi	a5,a5,1
	mv	a0,a5
	lw ra, 32(sp)

	lw s0, 28(sp)

    la t6, __stack_chk_guard
    lw t5, 0(sp)
    lw t4, 0(t6)
    bne t5, t4, __stack_chk_fail
	addi sp, sp, 36
	jr	ra
	.size	tiny, .-tiny
	.align	2
	.globl	main
	.type	main, @function
main:
	addi sp, sp, -36
    la t6, __stack_chk_guard
    lw t5, 0(t6)
    sw t5, 0(sp)
	sw ra, 32(sp)

	sw s0, 28(sp)

	addi s0, sp, 36
	li	a5,7
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	call	tiny
	mv	a5,a0
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	mv	a0,a5
	lw ra, 32(sp)

	lw s0, 28(sp)

    la t6, __stack_chk_guard
    lw t5, 0(sp)
    lw t4, 0(t6)
    bne t5, t4, __stack_chk_fail
	addi sp, sp, 36
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits

    .section .data
    .align 2
    .globl __stack_chk_guard
__stack_chk_guard:
    .word 0xa740d7f3

    .section .text
    .align 2
    .globl __stack_chk_fail
__stack_chk_fail:
    li a0, 1
    li a7, 93
    ecall
.L__stack_chk_fail_hang:
    j .L__stack_chk_fail_hang
