section .data
str:		db "asm_print says hello world!", 0xa, 0
;0xa是换行符，0是手工加上的字符串结束符\0的ASCII码
str_len		equ $-str

section	.text
extern	c_print
global	_start
_start:
;;;;;;;;;;;;;;;;;;调用C代码中的函数c_print;;;;;;;;;;;;;;;;;;;;;;;
	push str		;传入参数
	call c_print		;调用C函数
	add esp, 4		;回收栈空间

;;;;;;;;;;;;;;;;;;退出程序;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, 1		;第1号子功能是exit系统调用
	int 0x80		;发起中断，通知Linux完成请求的功能

global asm_print		;相当于asm_print(str,size)
asm_print:
	push ebp		;备份ebp
	mov ebp, esp		
	mov eax, 4		;第4号子功能是write系统调用
	mov ecx, [ebp+8]	;第1个参数
	mov edx, [ebp+12]	;第2个参数
	int 0x80		;发起中断，通知Linux完成请求的功能
	pop ebp			;恢复ebp
	ret

