# 程式碼解釋：
這個程式實現了 Question 1.4 的要求：let x = 2, let y =x * x, print (y + x)
.text 段包含程式碼：
1. main 標籤是程式的入口點
2. movq $2, %rax 將常數 2 載入到 %rax 暫存器
3. movq %rax, x(%rip) 將 %rax 的值存入全域變數 x
4. movq x(%rip), %rax 將全域變數 x 的值載入 %rax
5. imulq x(%rip), %rax 將 %rax 乘以 x 的值 (計算 x * x)
6. movq %rax, y(%rip) 將結果存入全域變數 y
7. movq y(%rip), %rax 將 y 的值載入 %rax
8. addq x(%rip), %rax 將 x 的值加到 %rax (計算 y + x)
9. 設定 printf 呼叫：%rsi 放第二個參數(結果)，%rdi 放第個參數(格式字串)
10. movq $0, %rax 設定向量參數個數為 0 (printf 的要求)
11. call printf 呼叫 printf 函數
12. movq $0, %rax 設定返回值為 0
13. ret 返回並結束程式
.data 段包含全域變數：
1. x 和 y 都是 64 位元整數(.quad)，初始化為 0
2. format 是 printf 用的格式字串，包含 "%d\n"

 執行結果：x = 2, y = 2 * 2 = 4, print(4 + 2) = 6
