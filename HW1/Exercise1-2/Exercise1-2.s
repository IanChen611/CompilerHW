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
    # Exercise 1-2-1: 計算 4 + 6 = 10
    # =====================================
    mov $4, %r8d
    mov $6, %r9d
    mov $0, %edx
    add %r8d, %edx
    add %r9d, %edx

    # 輸出結果
    lea fmt1(%rip), %rcx
    call __mingw_printf

    # =====================================
    # Exercise 1-2-2: 計算 21 * 2 = 42
    # =====================================
    mov $21, %eax
    mov $2, %ebx
    mul %ebx          # eax = eax * ebx = 21 * 2
    mov %eax, %edx

    # 輸出結果
    lea fmt2(%rip), %rcx
    call __mingw_printf

    # =====================================
    # Exercise 1-2-3: 計算 4 + 7/2 = 7
    # =====================================
    # 先計算 7 / 2
    mov $7, %eax      # 被除數放在 eax
    mov $2, %ecx      # 除數放在 ecx
    xor %edx, %edx    # edx = 0
    div %ecx          # eax = eax / ecx = 7 / 2 = 3（整數除法）

    # 然後計算 4 + 3
    add $4, %eax      # eax = eax + 4 = 3 + 4 = 7
    mov %eax, %edx

    # 輸出結果
    lea fmt3(%rip), %rcx
    call __mingw_printf

    # =====================================
    # Exercise 1-2-4: 計算 3 - 6 * (10/5) = -9
    # =====================================
    # 先計算 10 / 5
    mov $10, %eax     # 被除數放在 eax
    mov $5, %ecx      # 除數放在 ecx
    xor %edx, %edx    # edx = 0
    div %ecx          # eax = eax / ecx = 10 / 5 = 2

    # 計算 6 * 2
    mov $6, %ebx      # 將 6 放入 ebx
    mul %ebx          # eax = eax * ebx = 2 * 6 = 12

    # 然後計算 3 - 12
    mov $3, %ecx      # 將 3 放入 ecx
    sub %eax, %ecx    # ecx = ecx - eax = 3 - 12 = -9
    mov %ecx, %eax    # 將結果移回 eax
    mov %eax, %edx    # 將結果移到 edx

    # 輸出結果
    lea fmt4(%rip), %rcx
    call __mingw_printf
    leave
    mov $0, %eax





    
    ret
    .data

fmt1:
    .string "Exercise 1-2-1: (4 + 6) = %d\n"
fmt2:
    .string "Exercise 1-2-2: (21 * 2) = %d\n"
fmt3:
    .string "Exercise 1-2-3: (4 + 7/2) = %d\n"
fmt4:
    .string "Exercise 1-2-4: (3 - 6 * (10/5)) = %d\n"