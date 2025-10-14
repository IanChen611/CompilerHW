    .text
    .global main
    .extern __mingw_printf
    .extern __main
main:
    push %rbp
    mov %rsp, %rbp
    sub $48, %rsp

    call __main

    # print (let x = 3 in x * x)
    # 相當於：x = 3; print(x * x)

    # let x = 3 (將 x 存放在堆疊上，位址為 %rbp-8)
    movq $3, %rax
    movq %rax, -8(%rbp)      # x 存放在 %rbp-8

    # 計算 x * x
    movq -8(%rbp), %rax      # 載入 x 的值到 %rax
    imulq -8(%rbp), %rax     # %rax = %rax * x = x * x

    # Windows calling convention: 第一個參數放在 rcx, 第二個參數放在 rdx
    lea format(%rip), %rcx
    mov %eax, %edx
    call __mingw_printf
    leave
    mov $0, %eax
    ret

.data
format: .string "%d\n"