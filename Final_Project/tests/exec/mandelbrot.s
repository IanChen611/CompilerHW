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
	movq $8, %rdi
	call my_malloc
	pushq %rax
	leaq class_Mandelbrot, %rbx
	popq %rax
	movq %rbx, 0(%rax)
	pushq %rax
	movq $30, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	call Mandelbrot_constructor
	addq $16, %rsp
	popq %rax
	pushq %rax
	movq 0(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 40(%rbx), %rbx
	call *%rbx
	addq $8, %rsp
	popq %rbx
	movq %rbp, %rsp
	popq %rbp
	ret
Main_constructor:
	pushq %rbp
	movq %rsp, %rbp
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_constructor:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	popq %rbx
	movq %rax, 8(%rbx)
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_add:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rax
	pushq %rax
	movq 24(%rbp), %rax
	popq %rbx
	addq %rbx, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_sub:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rax
	pushq %rax
	movq 24(%rbp), %rax
	movq %rax, %rbx
	popq %rax
	subq %rbx, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_mul:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	movq 16(%rbp), %rax
	pushq %rax
	movq 24(%rbp), %rax
	popq %rbx
	imulq %rbx, %rax
	movq %rax, -8(%rbp)
	movq -8(%rbp), %rax
	pushq %rax
	movq $8192, %rax
	pushq %rax
	movq $2, %rax
	movq %rax, %rbx
	popq %rax
	cqto
	idivq %rbx
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	movq $8192, %rax
	movq %rax, %rbx
	popq %rax
	cqto
	idivq %rbx
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_div:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	movq 16(%rbp), %rax
	pushq %rax
	movq $8192, %rax
	popq %rbx
	imulq %rbx, %rax
	movq %rax, -8(%rbp)
	movq -8(%rbp), %rax
	pushq %rax
	movq 24(%rbp), %rax
	pushq %rax
	movq $2, %rax
	movq %rax, %rbx
	popq %rax
	cqto
	idivq %rbx
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	movq 24(%rbp), %rax
	movq %rax, %rbx
	popq %rax
	cqto
	idivq %rbx
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_of_int:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rax
	pushq %rax
	movq $8192, %rax
	popq %rbx
	imulq %rbx, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_iter:
	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rsp
	movq 16(%rbp), %rax
	pushq %rax
	movq $100, %rax
	popq %rbx
	xorq %rcx, %rcx
	cmpq %rax, %rbx
	sete %cl
	movq %rcx, %rax
	testq %rax, %rax
	jz L1
	movq $1, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	jmp L2
L1:
L2:
	movq 16(%rbp), %rax
	pushq %rax
	movq 40(%rbp), %rax
	pushq %rax
	movq 40(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 24(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	movq %rax, -8(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq 48(%rbp), %rax
	pushq %rax
	movq 48(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 24(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	movq %rax, -16(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq -16(%rbp), %rax
	pushq %rax
	movq -8(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 32(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $4, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	popq %rbx
	xorq %rcx, %rcx
	cmpq %rax, %rbx
	setg %cl
	movq %rcx, %rax
	testq %rax, %rax
	jz L3
	movq $0, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
	jmp L4
L3:
L4:
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq 32(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq 48(%rbp), %rax
	pushq %rax
	movq 40(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 24(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $2, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 24(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 32(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq 24(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -16(%rbp), %rax
	pushq %rax
	movq -8(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 56(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 32(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 32(%rbp), %rax
	pushq %rax
	movq 24(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $1, %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	movq 40(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 48(%rbx), %rbx
	call *%rbx
	addq $48, %rsp
	popq %rbx
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_inside:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $0, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $0, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 24(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $0, %rax
	pushq %rax
	movq 40(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 48(%rbx), %rbx
	call *%rbx
	addq $48, %rsp
	popq %rbx
	movq %rbp, %rsp
	popq %rbp
	ret
	movq %rbp, %rsp
	popq %rbp
	ret
Mandelbrot_run:
	pushq %rbp
	movq %rsp, %rbp
	subq $80, %rsp
	movq 16(%rbp), %rax
	pushq %rax
	movq $2, %rax
	negq %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	movq %rax, -8(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq $1, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	movq %rax, -16(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq $2, %rax
	pushq %rax
	movq 16(%rbp), %rax
	movq 8(%rax), %rax
	popq %rbx
	imulq %rbx, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -8(%rbp), %rax
	pushq %rax
	movq -16(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 56(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 64(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	movq %rax, -24(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq $1, %rax
	negq %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	movq %rax, -32(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq $1, %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	movq %rax, -40(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	movq 8(%rax), %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -32(%rbp), %rax
	pushq %rax
	movq -40(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 56(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 64(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	movq %rax, -48(%rbp)
	movq $0, %rax
	movq %rax, -56(%rbp)
	movq $0, %rax
	movq %rax, -56(%rbp)
L5:
	movq -56(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	movq 8(%rax), %rax
	popq %rbx
	xorq %rcx, %rcx
	cmpq %rax, %rbx
	setl %cl
	movq %rcx, %rax
	testq %rax, %rax
	jz L6
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -48(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -56(%rbp), %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 24(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq -32(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 32(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	movq %rax, -64(%rbp)
	movq $0, %rax
	movq %rax, -72(%rbp)
	movq $0, %rax
	movq %rax, -72(%rbp)
L7:
	movq -72(%rbp), %rax
	pushq %rax
	movq $2, %rax
	pushq %rax
	movq 16(%rbp), %rax
	movq 8(%rax), %rax
	popq %rbx
	imulq %rbx, %rax
	popq %rbx
	xorq %rcx, %rcx
	cmpq %rax, %rbx
	setl %cl
	movq %rcx, %rax
	testq %rax, %rax
	jz L8
	movq 16(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -24(%rbp), %rax
	pushq %rax
	movq 16(%rbp), %rax
	pushq %rax
	movq -72(%rbp), %rax
	pushq %rax
	movq 8(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 8(%rbx), %rbx
	call *%rbx
	addq $16, %rsp
	popq %rbx
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 24(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	pushq %rax
	movq -8(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 32(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	movq %rax, -80(%rbp)
	movq 16(%rbp), %rax
	pushq %rax
	movq -64(%rbp), %rax
	pushq %rax
	movq -80(%rbp), %rax
	pushq %rax
	movq 16(%rsp), %rdi
	pushq %rdi
	movq 0(%rdi), %rbx
	movq 16(%rbx), %rbx
	call *%rbx
	addq $24, %rsp
	popq %rbx
	testq %rax, %rax
	jz L9
	leaq S2, %rax
	leaq 8(%rax), %rsi
	leaq string_format, %rdi
	xorq %rax, %rax
	call my_printf
	jmp L10
L9:
	leaq S1, %rax
	leaq 8(%rax), %rsi
	leaq string_format, %rdi
	xorq %rax, %rax
	call my_printf
L10:
	movq -72(%rbp), %rax
	pushq %rax
	movq $1, %rax
	popq %rbx
	addq %rbx, %rax
	movq %rax, -72(%rbp)
	jmp L7
L8:
	leaq S3, %rax
	leaq 8(%rax), %rsi
	leaq string_format, %rdi
	xorq %rax, %rax
	call my_printf
	movq -56(%rbp), %rax
	pushq %rax
	movq $1, %rax
	popq %rbx
	addq %rbx, %rax
	movq %rax, -56(%rbp)
	jmp L5
L6:
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
class_Mandelbrot:
	.quad class_Object
	.quad Mandelbrot_of_int
	.quad Mandelbrot_inside
	.quad Mandelbrot_mul
	.quad Mandelbrot_add
	.quad Mandelbrot_run
	.quad Mandelbrot_iter
	.quad Mandelbrot_sub
	.quad Mandelbrot_div
S3:
	.quad class_String
	.string "\n"
S2:
	.quad class_String
	.string "0"
S1:
	.quad class_String
	.string "1"
int_format:
	.string "%ld"
string_format:
	.string "%s"
cast_error:
	.string "cast failure"
