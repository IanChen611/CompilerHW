    .text
    .global main
    .extern __mingw_printf
    .extern __main
main:
    push %rbp
    mov %rsp, %rbp
    sub $48, %rsp

    call __main

    # =====================================
    # Exercise 1-3-1: true && false
    # =====================================

    # 設定 true = 1, false = 0
    mov $1, %eax      # true
    mov $0, %ebx      # false

    and %ebx, %eax          # eax = eax && ebx = false

    # 我們需要檢查 eax 是否為 0 來決定印出 "true" 還是 "false"
    cmp $0, %eax
    je print_1_false    # 如果 eax == 0，跳到 print_1_false

    # 如果不是 0，印出 "true"
    lea fmt_true(%rip), %rcx
    call __mingw_printf
    jmp end_1

print_1_false:
    # 印出 "false"
    lea fmt_false(%rip), %rcx
    call __mingw_printf

end_1:

    # =====================================
    # Exercise 1-3-2: if 3 != 4 then 10 * 2 else 14
    # =====================================

    mov $3, %eax      # eax = 3
    mov $4, %ebx      # ebx = 4
    cmp %ebx, %eax    # eax = eax - ebx
    jl print_2_false  # if eax < 0 jump print_2_false

    mov $14, %edx     # a = 10
    lea fmt_num(%rip), %rcx
    call __mingw_printf
    jmp end_2


print_2_false:
    mov $10, %eax     # a = 10
    mov $2, %ebx      # b = 2
    mul %ebx          # eax = eax * ebx = 10 * 2 = 20
    mov %eax, %edx    # 將結果移到 edx
    lea fmt_num(%rip), %rcx
    call __mingw_printf

end_2:
    # =====================================
    # Exercise 1-3-3: 2 = 3 || 4 <= 2 * 3
    # =====================================

    mov $2, %eax      # a = 2
    mov $3, %ebx      # b = 3
    cmp %eax, %ebx    # eax = (eax == ebx)
    je label_3_1_False
    mov $1, %r8d      # a = 1
    jmp label_3_2

label_3_1_False:
    mov $0, %r8d      # a = 0
    
label_3_2:
    mov $2, %eax      # eax = 2
    mov $3, %ebx      # ebx = 3
    mul %ebx          # eax = eax * ebx = 6
    cmp $4, %eax      # eax = eax - 4
    jl label_3_2_False      # eax < 0

    mov $1, %r9d      # b = 1
    jmp label_3_3

label_3_2_False:
    mov $0, %r9d      # b = 0

label_3_3:
    or %r9d, %r8d
    cmp $0, %r8d
    je label_3_3_False
    lea fmt_true(%rip), %rcx
    call __mingw_printf
    jmp end_program
label_3_3_False:
    lea fmt_false(%rip), %rcx
    call __mingw_printf

end_program:
    leave
    mov $0, %eax
    ret

    .data
fmt_true:
    .string "true\n"
fmt_false:
    .string "false\n"
fmt_num:
    .string "%d\n"