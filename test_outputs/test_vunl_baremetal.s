	.file	"test_vunl.c"
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
	.globl	safe_small
	.type	safe_small, @function
safe_small:
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
	.size	safe_small, .-safe_small
	.align	2
	.globl	vulnerable
	.type	vulnerable, @function
vulnerable:
	addi sp, sp, -84
    la t6, __stack_chk_guard
    lw t5, 0(t6)
    sw t5, 0(sp)
	sw ra, 80(sp)

	sw s0, 76(sp)

	addi s0, sp, 84
	sw	a0,-68(s0)
	lw	a5,-68(s0)
	sw	a5,-56(s0)
	sw	zero,-52(s0)
	j	.L4
.L5:
	lw	a5,-52(s0)
	andi	a4,a5,0xff
	lw	a5,-52(s0)
	addi	a4,a4,1
	andi	a4,a4,0xff
	addi	a5,a5,-16
	add	a5,a5,s0
	sb	a4,-32(a5)
	lw	a5,-52(s0)
	addi	a5,a5,1
	sw	a5,-52(s0)
.L4:
	lw	a4,-52(s0)
	li	a5,31
	bleu	a4,a5,.L5
	sw	zero,-52(s0)
	j	.L6
.L7:
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
.L6:
	lw	a4,-52(s0)
	li	a5,31
	bleu	a4,a5,.L7
	lw	a4,-56(s0)
	lui	a5,%hi(sink)
	sw	a4,%lo(sink)(a5)
	lw	a5,-56(s0)
	mv	a0,a5
	lw ra, 80(sp)

	lw s0, 76(sp)

    la t6, __stack_chk_guard
    lw t5, 0(sp)
    lw t4, 0(t6)
    bne t5, t4, __stack_chk_fail
	addi sp, sp, 84
	jr	ra
	.size	vulnerable, .-vulnerable
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
	li	a5,5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	mv	a0,a5
	call	vulnerable
	mv	a5,a0
	sw	a5,-24(s0)
	lw	a4,-24(s0)
	lui	a5,%hi(sink)
	sw	a4,%lo(sink)(a5)
	li	a5,0
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
    .word 0x0d50e41b

    .section .text
    .align 2
    .globl __stack_chk_fail
__stack_chk_fail:
    ebreak
.L__stack_chk_fail_hang:
    j .L__stack_chk_fail_hang
