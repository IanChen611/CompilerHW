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
my_printf:
	pushq %rbp
	movq %rsp, %rbp
	andq $-16, %rsp
	call printf
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
	movq $15, %rax
	movq %rax, %r12
	movq $32, %rdi
	call my_malloc
	leaq class_String, %rbx
	movq %rbx, 0(%rax)
	pushq %rax
	leaq 8(%rax), %rdi
	leaq int_format, %rsi
	movq %r12, %rdx
	xorq %rax, %rax
	call my_sprintf
	popq %rax
	pushq %rax
	leaq S1, %rax
	movq %rax, %rsi
	popq %rdi
	call my_strcat
	movq %rax, %rax
	leaq 8(%rax), %rsi
	leaq string_format, %rdi
	xorq %rax, %rax
	call my_printf
	movq %rbp, %rsp
	popq %rbp
	ret
Main_constructor:
	pushq %rbp
	movq %rsp, %rbp
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
S1:
	.quad class_String
	.string "\n"
int_format:
	.string "%ld"
string_format:
	.string "%s"
cast_error:
	.string "cast failure"
