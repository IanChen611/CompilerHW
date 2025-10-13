    .text
    .global main
    .extern __mingw_printf
    .extern __main
main:
    push %rbp
    mov %rsp, %rbp
    sub $48, %rsp

    call __main

    # Windows calling convention: 第一個參數放在 rcx, 第二個參數放在 rdx
    lea fmt(%rip), %rcx
    mov $42, %edx
    call __mingw_printf
    leave
    mov $0, %eax
    ret
    .data

fmt:
    .string "n = %d\n"