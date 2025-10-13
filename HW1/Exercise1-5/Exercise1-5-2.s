.text
.global main
.extern __mingw_printf
.extern __main

main:
    push %rbp
    mov %rsp, %rbp
    sub $56, %rsp // rbp 後可以放參數的量
    // rbp ~ rbp-8 => x
    // rbp-8 ~ rbp-16 => y
    // rbp-16~ rbp-24 => z
    // rbp-16 ~ rbp-48 => Shadow space
    
    call __main
    
    # print (let x = 3 in let y = x * x in x + y)
    # 相當於：x = 3; y = x * x; print(x + y)
    
    # Step 1: let x = 3 (將 x 存放在 %rbp-8)
    movq $3, %rax
    movq %rax, -8(%rbp)      # x 存放在 %rbp-8
    
    # Step 2: let y = x * x (將 y 存放在 %rbp-16)
    movq -8(%rbp), %rax      # 載入 x 的值到 %rax
    addq -8(%rbp), %rax     # %rax = x + x => y
    movq %rax, -16(%rbp)     # y 存放在 %rbp-16
    
    # Step 3: 計算 x * y
    movq -8(%rbp), %rax      # 載入 x 的值到 %rax
    imulq -16(%rbp), %rax     # (rbp-16) = x * y
    movq %rax, -16(%rbp)      # (rbp-8) = x * y

    
    # Step 4: 計算 z = x + 3
    movq -8(%rbp), %rax      # 載入 x 的值到 %rax
    addq $3, %rax            # x = x + 3
    movq %rax, -24(%rbp)      # z(rbp-24) = x

    # Step 5: 計算 z / z
    movq -24(%rbp), %rax     # 載入 z 的值到 %rax
    cqo
    movq -24(%rbp), %rbx     # rbx = z
    idivq %rbx               # z = z / z
    movq %rax, -24(%rbp)      # (rbp-24) = z
    
    # Step 6: *(rbp - 16) + *(rbp - 24)
    movq -16(%rbp), %rax     # 載入 y 的值到 %rax
    movq -24(%rbp), %rbx     # 載入 z 的值到 %rbx
    addq %rbx, %rax          # *(rbp - 16) + *(rbp - 24)

    # Windows calling convention: 呼叫 printf
    lea format(%rip), %rcx
    mov %eax, %edx
    call __mingw_printf
    
    leave
    mov $0, %eax
    ret

.data
format: .string "%d\n"