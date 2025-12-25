#!/bin/bash

# 請修改為您的名字
STUDENT_NAME="112820025_MiniJavaCompiler"

# 創建提交目錄
SUBMIT_DIR="${STUDENT_NAME}"
rm -rf "${SUBMIT_DIR}" "${SUBMIT_DIR}.zip"
mkdir -p "${SUBMIT_DIR}"

echo "正在打包編譯器原始碼..."

# 複製原始碼檔案
cp mini-java-ocaml/ast.ml "${SUBMIT_DIR}/"
cp mini-java-ocaml/compile.ml "${SUBMIT_DIR}/"
cp mini-java-ocaml/lexer.mll "${SUBMIT_DIR}/"
cp mini-java-ocaml/minijava.ml "${SUBMIT_DIR}/"
cp mini-java-ocaml/parser.mly "${SUBMIT_DIR}/"
cp mini-java-ocaml/typing.ml "${SUBMIT_DIR}/"
cp mini-java-ocaml/x86_64.ml "${SUBMIT_DIR}/"
cp mini-java-ocaml/x86_64.mli "${SUBMIT_DIR}/"

# 複製建置檔案
cp mini-java-ocaml/Makefile "${SUBMIT_DIR}/"
cp mini-java-ocaml/dune "${SUBMIT_DIR}/"
cp mini-java-ocaml/dune-project "${SUBMIT_DIR}/"

echo "請創建報告檔案..."
echo "提示：在 ${SUBMIT_DIR}/ 目錄下創建 REPORT.md 或 REPORT.pdf"
echo ""
echo "報告應包含："
echo "1. 技術選擇 (使用的編譯方法、資料結構等)"
echo "2. 遇到的問題 (例如：字串拼接的記憶體問題及解決方法)"
echo "3. 未完成的功能列表 (如果全部完成可說明已完成所有功能)"
echo ""

# 創建簡單的 REPORT 模板
cat > "${SUBMIT_DIR}/REPORT.md" << 'EOF'
# Mini-Java 編譯器專案報告

## 學生資訊
- 姓名：[您的名字]
- 學號：[您的學號]

## 技術選擇

### 1. 型別檢查 (Typing)
- 使用三階段檢查：
  1. 宣告所有類別並檢查唯一性
  2. 建立繼承關係、屬性、方法
  3. 型別檢查方法主體
- 使用環境 (environment) 追蹤變數型別
- 實作子型別關係檢查支援繼承

### 2. 程式碼產生 (Code Generation)
- 物件佈局：第一個字組為類別描述子指標，其餘為屬性值
- 字串佈局：第一個字組為 String 類別指標，其餘為以 null 結尾的字串
- 堆疊對齊：使用 wrapper 函式確保 16-byte 對齊
- 方法呼叫：透過虛表 (vtable) 實現動態分派

## 遇到的問題與解決方法

### 問題 1: 字串拼接導致記憶體損壞
**症狀**: Josephus.java 測試在大規模循環鏈表時出現 `malloc.c assertion failed`

**根本原因**: `my_strcat` 函式在計算字串長度時，直接對 String 物件調用 `strlen`，但 String 物件的前 8 個字節是 vtable pointer，實際字串數據從偏移量 8 開始。這導致 `strlen` 讀取錯誤的記憶體位置，計算出錯誤的長度，最終導致堆積損壞。

**解決方法**: 在 `compile.ml` 的 `my_strcat` 函式中，於調用 `strlen` 之前添加 `leaq (ind ~ofs:8 rdi) rdi ++`，跳過 vtable pointer，直接訪問字串數據部分。修改後測試通過率從 98% 提升至 100%。

### 問題 2: [如有其他問題請補充]

## 完成狀況

### 已完成功能
- ✅ 語法分析 (Parsing)
- ✅ 型別檢查 (Type Checking)
- ✅ 程式碼產生 (Code Generation)
- ✅ 繼承與方法覆寫
- ✅ 字串操作與拼接
- ✅ 物件建立與方法呼叫
- ✅ 型別轉換 (Cast) 與 instanceof
- ✅ 所有測試通過 (72/72 = 100%)

### 未完成功能
- 無（所有功能已完成）

## 測試結果
```
Part 3:
Compilation : 72/72 : 100%
Generated Code : 72/72 : 100%
Code Behavior : 72/72 : 100%
```

## 總結
本專案成功實現了一個完整的 Mini-Java 編譯器，支援物件導向特性、繼承、方法覆寫等功能。通過仔細處理記憶體佈局和堆疊對齊問題，確保生成的 x86-64 組合語言程式碼能夠正確執行。
EOF

echo "已創建報告模板: ${SUBMIT_DIR}/REPORT.md"
echo "請編輯此檔案填入您的資訊！"
echo ""

# 創建 ZIP 檔案
echo "正在創建 ZIP 檔案..."
zip -r "${SUBMIT_DIR}.zip" "${SUBMIT_DIR}/"

echo ""
echo "✅ 完成！檔案已打包至: ${SUBMIT_DIR}.zip"
echo ""
echo "繳交前檢查清單："
echo "□ 已將 STUDENT_NAME 改為您的名字"
echo "□ 已編輯 REPORT.md 填入個人資訊"
echo "□ 已測試編譯器：cd ${SUBMIT_DIR} && make"
echo "□ 確認 make 可產生 minijava 執行檔"
echo ""
echo "準備好後，請將 ${SUBMIT_DIR}.zip 上傳至 i-school"
