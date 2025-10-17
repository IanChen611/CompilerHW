	.text
	.globl	main
main:
	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rsp
	pushq $20
	pushq $30
	pushq -16(%rbp)
	pushq -8(%rbp)
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	popq %rax
	movq %rax, -16(%rbp)
	popq %rbx
	pushq -16(%rbp)
	popq %rax
	movq %rax, -8(%rbp)
	popq %rbx
	pushq -8(%rbp)
	pushq $10
	pushq -8(%rbp)
	popq %rax
	movq %rax, -8(%rbp)
	popq %rbx
	pushq -8(%rbp)
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $2
	pushq $100
	popq %rax
	popq %rbx
	cqto
	idivq %rbx
	pushq %rax
	popq %rdi
	call print_int
	pushq $100
	pushq $2
	popq %rax
	popq %rbx
	cqto
	idivq %rbx
	pushq %rax
	popq %rdi
	call print_int
	pushq $10
	popq %rax
	movq %rax, x(%rip)
	movq x(%rip), %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $2
	pushq $1
	movq x(%rip), %rax
	pushq %rax
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	movq x(%rip), %rax
	pushq %rax
	popq %rax
	popq %rbx
	imulq %rbx, %rax
	pushq %rax
	popq %rax
	popq %rbx
	cqto
	idivq %rbx
	pushq %rax
	popq %rax
	movq %rax, y(%rip)
	movq y(%rip), %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $20
	pushq $30
	pushq -16(%rbp)
	pushq -8(%rbp)
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	popq %rax
	movq %rax, -16(%rbp)
	popq %rbx
	pushq -16(%rbp)
	popq %rax
	movq %rax, -8(%rbp)
	popq %rbx
	pushq -8(%rbp)
	pushq $10
	pushq -8(%rbp)
	popq %rax
	movq %rax, -8(%rbp)
	popq %rbx
	pushq -8(%rbp)
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	popq %rdi
	call print_int
	pushq $20
	popq %rax
	movq %rax, x(%rip)
	movq x(%rip), %rax
	pushq %rax
	popq %rdi
	call print_int
	movq x(%rip), %rax
	pushq %rax
	pushq $3
	pushq -8(%rbp)
	popq %rax
	movq %rax, -8(%rbp)
	popq %rbx
	pushq -8(%rbp)
	movq x(%rip), %rax
	pushq %rax
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	popq %rax
	popq %rbx
	addq %rbx, %rax
	pushq %rax
	popq %rax
	movq %rax, x(%rip)
	movq x(%rip), %rax
	pushq %rax
	popq %rdi
	call print_int
	movq %rbp, %rsp
	popq %rbp
	movq $0, %rax
	ret
print_int:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	movq %rdi, %rsi
	leaq .Sprint_int(%rip), %rdi
	movq $0, %rax
	call printf
	movq %rbp, %rsp
	popq %rbp
	ret
	.data
x:
	.quad 1
y:
	.quad 1
.Sprint_int:
	.string "%d\n"
