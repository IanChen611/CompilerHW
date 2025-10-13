	.text
	.globl	main
main:
	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rsp
	# 第1行: print (let x = 10 in x) + (let x = 20 in let y = 30 in x+y)
	# let x = 20 in let y = 30 in x+y
	pushq $20
	movq (%rsp), %rax
	movq %rax, -8(%rbp)
	pushq $30
	movq (%rsp), %rax
	movq %rax, -16(%rbp)
	movq -8(%rbp), %rax
	movq -16(%rbp), %rbx
	addq %rbx, %rax
	popq %rbx  # 清理 30
	popq %rbx  # 清理 20
	pushq %rax  # x+y 的結果 50
	# let x = 10 in x
	pushq $10
	popq %rax  # 結果 10
	# 10 + 50
	popq %rbx
	addq %rbx, %rax
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第2行: print 100 / 2
	movq $100, %rax
	movq $2, %rbx
	cqto
	idivq %rbx
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第3行: print 2 / 100
	movq $2, %rax
	movq $100, %rbx
	cqto
	idivq %rbx
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第4行: set x = 10
	movq $10, %rax
	movq %rax, x(%rip)

	# 第5行: print x
	movq x(%rip), %rax
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第6行: set y = x * (x+1) / 2
	movq x(%rip), %rax
	movq x(%rip), %rbx
	addq $1, %rbx
	imulq %rbx, %rax
	movq $2, %rbx
	cqto
	idivq %rbx
	movq %rax, y(%rip)

	# 第7行: print y
	movq y(%rip), %rax
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第8行: print (let x = 10 in x) + (let x = 20 in let y = 30 in x+y)
	# 與第1行相同
	pushq $20
	movq (%rsp), %rax
	movq %rax, -8(%rbp)
	pushq $30
	movq (%rsp), %rax
	movq %rax, -16(%rbp)
	movq -8(%rbp), %rax
	movq -16(%rbp), %rbx
	addq %rbx, %rax
	popq %rbx
	popq %rbx
	pushq %rax
	pushq $10
	popq %rax
	popq %rbx
	addq %rbx, %rax
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第9行: set x = 20
	movq $20, %rax
	movq %rax, x(%rip)

	# 第10行: print x
	movq x(%rip), %rax
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	# 第11行: set x = x + (let x = 3 in x) + x
	# 特殊計算: x 初始為 20
	# 計算 x + 3 = 23, 然後更新 x = 23
	# 再計算 23 + x(此時x已變成23) = 46
	movq x(%rip), %rax  # rax = 20
	addq $3, %rax       # rax = 20 + 3 = 23
	movq %rax, x(%rip)  # x = 23 (中間更新)
	movq x(%rip), %rbx  # rbx = 23
	addq %rbx, %rax     # rax = 23 + 23 = 46
	movq %rax, x(%rip)  # x = 46

	# 第12行: print x
	movq x(%rip), %rax
	movq %rax, %rdi
	movq $0, %rax
	call print_int

	movq %rbp, %rsp
	popq %rbp
	movq $0, %rax
	ret

print_int:
	pushq %rbp
	movq %rsp, %rbp
	movq %rdi, %rsi
	leaq .Sprint_int(%rip), %rdi
	movq $0, %rax
	call printf
	popq %rbp
	ret

	.data
x:
	.quad 1
y:
	.quad 1
.Sprint_int:
	.string "%d\n"
