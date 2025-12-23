	.text
my_malloc:
	pushq %rbp
	movq %rsp, %rbp
	andq $-16, %rsp
	call malloc
	movq %rbp, %rsp
	popq %rbp
	ret
my_puts:
	pushq %rbp
	movq %rsp, %rbp
	andq $-16, %rsp
	call puts
	movq %rbp, %rsp
	popq %rbp
	ret
my_sprintf:
	pushq %rbp
	movq %rsp, %rbp
	andq $-16, %rsp
	call sprintf
	movq %rbp, %rsp
	popq %rbp
	ret
my_strcat:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rdi
	pushq %rsi
	call strlen
	movq %rax, %r12
	movq -8(%rbp), %rdi
	call strlen
	addq %r12, %rax
	addq $9, %rax
	movq %rax, %rdi
	call malloc
	movq %rax, %r13
	leaq class_String, %r12
	movq %r12, 0(%rax)
	leaq 8(%rax), %rdi
	movq -16(%rbp), %rsi
	leaq 8(%rsi), %rsi
	call strcpy
	leaq 8(%r13), %rdi
	call strlen
	addq %r13, %rax
	addq $8, %rax
	movq %rax, %rdi
	movq -8(%rbp), %rsi
	leaq 8(%rsi), %rsi
	call strcat
	movq %r13, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
Main_main:
	pushq %rbp
	movq %rsp, %rbp
	movq %rbp, %rsp
	popq %rbp
	ret
B_m:
	pushq %rbp
	movq %rsp, %rbp
	movq %rbp, %rsp
	popq %rbp
	ret
A_m:
	pushq %rbp
	movq %rsp, %rbp
	movq $0, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
	.globl	main
main:
	pushq %rbp
	movq %rsp, %rbp
	call Main_main
	xorq %rax, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
String_equals:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rdi
	leaq 8(%rdi), %rdi
	movq 24(%rbp), %rsi
	leaq 8(%rsi), %rsi
	call strcmp
	testq %rax, %rax
	sete %al
	movzbq %al, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	.data
class_Object:
	.quad 0
class_String:
	.quad class_Object
	.quad String_equals
class_Main:
	.quad class_Object
	.quad Main_main
class_B:
	.quad class_A
	.quad B_m
class_A:
	.quad class_Object
	.quad A_m
int_format:
	.string "%ld"
cast_error:
	.string "cast failure"
