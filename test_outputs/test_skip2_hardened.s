	.file	"test_skip2.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	tiny
	.type	tiny, @function
tiny:
	addi	a0,a0,1
	ret
	.size	tiny, .-tiny
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	li	a0,8
	ret
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits

    .section .data
    .align 2
    .globl __stack_chk_guard
__stack_chk_guard:
    .word 0xd2e6f3af

    .section .text
    .align 2
    .globl __stack_chk_fail
__stack_chk_fail:
    li a0, 1
    li a7, 93
    ecall
.L__stack_chk_fail_hang:
    j .L__stack_chk_fail_hang
