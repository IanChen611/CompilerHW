# Exercise1-1.s 組合語言程式解釋

## 程式概述
這是一個簡單的 x86-64 組合語言程式，功能是列印 "n = 42"。使用 Windows 的 MinGW 編譯環境和 Microsoft x64 calling convention。

## 逐行解釋

### 程式區段宣告
```assembly
.text
```
宣告這是程式碼區段（code section），包含可執行的指令。

```assembly
.global main
```
將 `main` 標籤設為全域符號，讓連結器可以找到程式的進入點。

### 外部函數宣告
```assembly
.extern __mingw_printf
.extern __main
```
宣告兩個外部函數：
- `__mingw_printf`: MinGW 版本的 printf 函數
- `__main`: MinGW 運行時初始化函數

### 主函數開始
```assembly
main:
```
主函數的標籤，程式執行的起始點。

### 函數序言 (Function Prologue)
```assembly
push %rbp
mov %rsp, %rbp
sub $48, %rsp
```
建立標準的函數堆疊框架：
1. `push %rbp`: 將舊的基底指標推入堆疊
2. `mov %rsp, %rbp`: 將當前堆疊指標設為新的基底指標
3. `sub $48, %rsp`: 分配 48 bytes 的本地變數空間（確保 16-byte 對齊）

### 運行時初始化
```assembly
call __main
```
呼叫 MinGW 運行時初始化函數，設定必要的執行環境。

### 準備函數參數 (Windows x64 Calling Convention)
```assembly
lea fmt(%rip), %rcx
mov $42, %edx
```
準備 `printf` 函數的參數：
- `lea fmt(%rip), %rcx`: 使用 RIP-relative 定址載入格式字串地址到 RCX（第一個參數）
- `mov $42, %edx`: 將整數 42 載入到 EDX（第二個參數）

**Windows x64 calling convention**: 前四個整數參數依序放在 RCX, RDX, R8, R9

### 函數呼叫
```assembly
call __mingw_printf
```
呼叫 printf 函數，列印格式化字串。

### 函數結尾 (Function Epilogue)
```assembly
leave
mov $0, %eax
ret
```
1. `leave`: 等同於 `mov %rbp, %rsp; pop %rbp`，恢復堆疊和基底指標
2. `mov $0, %eax`: 設定回傳值為 0 (成功執行)
3. `ret`: 回傳到呼叫者

### 資料區段
```assembly
.data

fmt:
    .string "n = %d\n"
```
在資料區段定義格式字串：
- `.data`: 宣告資料區段
- `fmt:`: 格式字串的標籤
- `.string "n = %d\n"`: 定義以 null 結尾的字串

## 執行結果
程式執行後會輸出：
```
n = 42
```

## 堆疊結構圖解

### 函數呼叫前的堆疊變化

```
進入 main 時：
┌─────────────────┐ ← %rsp (假設為 0x1000 - 8 = 0xFF8，16-byte對齊-8)
│   return addr   │
├─────────────────┤
│      ...        │
└─────────────────┘

執行 push %rbp：
┌─────────────────┐
│   return addr   │
├─────────────────┤ ← %rbp (舊值)
│    old %rbp     │ ← %rsp (0xFF8 - 8 = 0xFF0，16-byte對齊)
├─────────────────┤
│      ...        │
└─────────────────┘

執行 mov %rsp, %rbp：
┌─────────────────┐
│   return addr   │
├─────────────────┤ ← %rbp = %rsp = 0xFF0
│    old %rbp     │ ← %rsp
├─────────────────┤
│      ...        │
└─────────────────┘

執行 sub $48, %rsp：
┌─────────────────┐
│   return addr   │
├─────────────────┤ ← %rbp (0xFF0)
│    old %rbp     │
├─────────────────┤
│                 │
│   Shadow Space  │ 32 bytes
│   (for printf   │ (RCX, RDX, R8, R9)
│   parameters)   │
│                 │
├─────────────────┤
│                 │
│  Additional     │ 16 bytes
│  Alignment      │ (確保16-byte對齊)
│  Space          │
│                 │
├─────────────────┤ ← %rsp (0xFF0 - 48 = 0xFC0，16-byte對齊)
│      ...        │
└─────────────────┘
```

### Windows x64 Calling Convention 參數傳遞

```
printf("n = %d\n", 42) 的參數配置：

暫存器參數：
┌─────────┬──────────────────┬─────────────┐
│ 參數位置 │      暫存器       │    內容     │
├─────────┼──────────────────┼─────────────┤
│   1st   │      RCX        │ fmt字串地址  │
│   2nd   │      RDX        │     42      │
│   3rd   │      R8         │   (未使用)   │
│   4th   │      R9         │   (未使用)   │
└─────────┴──────────────────┴─────────────┘

對應的 Shadow Space (堆疊上的備份空間)：
┌─────────────────┐ ← %rbp
│    old %rbp     │
├─────────────────┤ ← %rbp - 8
│  RCX shadow     │ (8 bytes)
├─────────────────┤ ← %rbp - 16
│  RDX shadow     │ (8 bytes)
├─────────────────┤ ← %rbp - 24
│  R8 shadow      │ (8 bytes)
├─────────────────┤ ← %rbp - 32
│  R9 shadow      │ (8 bytes)
├─────────────────┤ ← %rbp - 40
│  Alignment      │ (8 bytes)
├─────────────────┤ ← %rbp - 48 = %rsp
│     ...         │
└─────────────────┘
```

### RIP-relative 定址示意圖

```
記憶體佈局：
┌──────────────────────────────────┐
│          .text 區段              │
│                                  │
│ 0x401020: lea fmt(%rip), %rcx   │ ← 當前執行指令
│ 0x401027: mov $42, %edx         │ ← %rip 指向這裡
│ ...                              │
└──────────────────────────────────┘
                │
                │ 計算位移
                ▼
┌──────────────────────────────────┐
│          .data 區段              │
│                                  │
│ 0x404020: fmt: .string "n=%d\n" │ ← 目標地址
│ ...                              │
└──────────────────────────────────┘

計算過程：
fmt 地址 = %rip + displacement
0x404020 = 0x401027 + 0x2FF9
         ↑          ↑       ↑
      目標地址   下一條指令  位移值
```

## 技術要點
1. **記憶體對齊**: 堆疊必須保持 16-byte 對齊
2. **Shadow Space**: Windows x64 要求為前4個參數預留 32 bytes
3. **RIP-relative 定址**: `lea fmt(%rip), %rcx` 使用相對於指令指標的定址方式
4. **Windows calling convention**: 使用 RCX, RDX 傳遞參數
5. **MinGW 特殊性**: 需要呼叫 `__main` 和使用 `__mingw_printf`