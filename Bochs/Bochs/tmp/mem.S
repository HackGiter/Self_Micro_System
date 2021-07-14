	.file	"mem.c"
	.section	.rodata
.LC0:
	.string	"in_b is %d\n"
.LC1:
	.string	"in_b now is %d\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushl	%ebp					;堆栈框架
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	andl	$-16, %esp
	subl	$32, %esp				;预留局部变量空间
	movl	$1, 28(%esp)			;变量in_a在栈中位置
	movl	$2, 24(%esp)			;变量in_b在栈中位置
	movl	24(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$.LC0, (%esp)
	call	printf
	movl	28(%esp), %eax			;内联汇编的input，将in_a赋值给eax
#APP
# 5 "tmp/mem.c" 1
	movb %al, 24(%esp);
# 0 "" 2
#NO_APP
	movl	24(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$.LC1, (%esp)
	call	printf
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (GNU) 4.8.5 20150623 (Red Hat 4.8.5-44)"
	.section	.note.GNU-stack,"",@progbits
