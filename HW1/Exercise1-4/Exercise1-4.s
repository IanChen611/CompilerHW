.text
.globl main

main:
    # x = 2
    movq $2, %rax
    movq %rax, x(%rip)

    # y = x * x
    movq x(%rip), %rax
    imulq x(%rip), %rax
    movq %rax, y(%rip)

    # print (y + x)
    movq y(%rip), %rax
    addq x(%rip), %rax

    # Setup printf call
    movq %rax, %rdx         # second argument (the result)
    leaq format(%rip), %rcx  # first argument (format string)
    movq $0, %rax            # no vector arguments
    call __mingw_printf

    # exit
    movq $0, %rax
    ret

.data
x: .quad 0                   # global variable x => .quad = 8 bytes
y: .quad 0                   # global variable y
format: .string "%d\n"       # format string for printf