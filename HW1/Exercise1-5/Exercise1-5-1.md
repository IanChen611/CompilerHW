# Exercise1-5-1.s 組合語言程式分析

## 程式概述

這是一個 x86-64 組合語言程式，使用 AT&T 語法編寫，實現了函數式程式語言中的 `let` 表達式：`let x = 3 in x * x`。程式會計算並輸出結果 9。

## 程式結構分析

### 1. 程式段聲明
```assembly
.text
.globl main
.extern __mingw_printf
.extern __main
```
- `.text`: 程式碼段
- `.globl main`: 將 main 符號設為全域可見
- `.extern`: 聲明外部函數

### 2. 主程式 (main function)

#### 函數前置設定
```assembly
main:
    push %rbp           # 保存舊的基底指標
    mov %rsp, %rbp      # 設定新的基底指標
    sub $16, %rsp       # 分配16位元組堆疊空間 (16位元組對齊)
    call __main         # MinGW 初始化
```

#### Let 表達式實現
```assembly
# let x = 3 (將 x 存放在堆疊上)
movq $3, %rax           # 將常數 3 載入到 %rax
movq %rax, -8(%rbp)     # 將 x 的值存放在 %rbp-8 位置
```

#### 計算 x * x
```assembly
movq -8(%rbp), %rax     # 載入 x 的值到 %rax
imulq -8(%rbp), %rax    # %rax = %rax * x = x * x
```

#### 呼叫 printf 輸出結果
```assembly
movq %rax, %rdx         # 第二個參數：計算結果 (9)
leaq format(%rip), %rcx # 第一個參數：格式字串位址
movq $0, %rax           # 向量參數個數為 0
call __mingw_printf
```

#### 程式結束
```assembly
leave                   # 等同於 mov %rbp, %rsp; pop %rbp
movq $0, %rax          # 返回值 0
ret
```

### 3. 資料段
```assembly
.data
format: .string "%d\n"  # printf 的格式字串
```

## 記憶體配置圖

```
高位址
┌──────────────┐
│   舊的 %rbp   │ ← %rbp+8
├──────────────┤
│  返回位址     │ ← %rbp
├──────────────┤
│              │ ← %rbp-8 (變數 x 的位置)
│     x = 3    │
├──────────────┤
│   (未使用)    │ ← %rbp-16
└──────────────┘ ← %rsp
低位址
```

## 暫存器使用情況

| 暫存器 | 用途 |
|--------|------|
| %rbp   | 基底指標 (frame pointer) |
| %rsp   | 堆疊指標 (stack pointer) |
| %rax   | 累加器，用於運算和函數返回值 |
| %rcx   | printf 第一個參數 (格式字串) |
| %rdx   | printf 第二個參數 (要輸出的數值) |

## 程式執行流程

1. **初始化階段**: 設定堆疊框架，呼叫 MinGW 初始化
2. **變數宣告**: `let x = 3` - 將 3 存放在堆疊位置 %rbp-8
3. **運算階段**: 計算 `x * x` = 3 × 3 = 9
4. **輸出階段**: 使用 printf 輸出結果
5. **清理階段**: 恢復堆疊，返回 0

## 輸出結果

程式執行後會在控制台輸出：
```
9
```

## 關鍵特點

- **堆疊對齊**: 分配 16 位元組空間符合 x86-64 ABI 要求
- **函數式語法**: 實現了 `let` 表達式的語義
- **MinGW 相容**: 使用 MinGW 的 printf 函數進行輸出
- **AT&T 語法**: 使用 AT&T 組合語言語法 (來源在右，目標在左)