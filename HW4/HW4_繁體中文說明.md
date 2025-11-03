# 337883 編譯器 - 作業 4
## Mini-turtle (迷你海龜)
### 114-1
---
這是我請claude code幫我翻譯成中文的作業要求
---

本作業的目標是實作一個小型 Logo 語言（圖形海龜）的語法分析，其直譯器已經提供。不需要事先了解 Logo 語言。

本作業需要使用工具 `menhir` 和 `graphics` 函式庫。如果尚未安裝，請使用以下指令安裝：
```bash
opam install menhir graphics
```

基本架構已提供（一個包含 OCaml 檔案和 Makefile 的壓縮檔）：[mini-turtle.tar.gz](mini-turtle.tar.gz)

解壓縮後（例如使用 `tar zxvf mini-turtle.tar.gz`），你會得到一個 `mini-turtle/` 目錄，包含以下檔案：

| 檔案 | 說明 |
|------|------|
| `turtle.ml(i)` | 圖形海龜（完整） |
| `ast.ml` | 抽象語法樹 mini-Turtle（完整） |
| `lexer.mll` | 詞法分析器（**需要完成**） |
| `parser.mly` | 語法分析器（**需要完成**） |
| `interp.ml` | 直譯器（完整） |
| `miniturtle.ml` | 主程式檔案（完整） |
| `Makefile/dune` | 自動化建置（完整） |

程式碼可以編譯（執行 `make`，會執行 `dune build`）但尚未完成。需要填寫的地方標記為 `(* to be completed */)`。程式從命令列接受一個要被直譯的檔案，副檔名為 `.logo`。執行 `make` 時，程式會在 `test.logo` 檔案上執行。

---

## Mini-Turtle 的語法

### 詞法慣例

空格、Tab 和換行符號都是空白字元。有兩種註解：
1. 從 `//` 到該行結束
2. 被 `(*` 和 `*)` 包圍（且不能巢狀）

以下識別字是關鍵字：
```
if else def repeat penup pendown forward turnleft
turnright color black white red green blue
```

一個識別字 `ident` 包含字母、數字和底線，且以字母開頭。
一個整數字面值 `integer` 是一串數字序列。

### 語法規則

斜體名稱（如 *expr*）是非終端符號。
- 符號 `stmt*` 表示非終端符號 `stmt` 的零次、一次或多次重複。
- 符號 `expr*,` 表示非終端符號 `expr` 的重複，各次出現之間用終端符號 `,`（逗號）分隔。

```
file  ::= def* stmt*

def   ::= def ident ( ident*, ) stmt

stmt  ::= penup
        | pendown
        | forward expr
        | turnleft expr
        | turnright expr
        | color color
        | ident ( expr*, )
        | if expr stmt
        | if expr stmt else stmt
        | repeat expr stmt
        | { stmt* }

expr  ::= integer
        | ident
        | expr + expr
        | expr - expr
        | expr * expr
        | expr / expr
        | - expr
        | ( expr )

color ::= black | white | red | green | blue
```

算術運算的優先順序是一般常見的順序，單元負號的優先順序最高。

---

## 作業內容

你需要填寫檔案 [lexer.mll](lexer.mll)（ocamllex）和 [parser.mly](parser.mly)（Menhir）。以下問題建議一個漸進式的完成方式。在每個步驟，你可以修改檔案 `test.logo` 來測試。

指令 `make`（在目錄根目錄執行）會執行工具 ocamllex 和 menhir（來建置/更新 OCaml 檔案 `lexer.ml`、`parser.mli` 和 `parser.ml`），然後編譯 OCaml 程式碼，最後在檔案 `test.logo` 上執行程式。如果解析成功，會開啟一個圖形視窗並顯示程式的直譯結果。按任意鍵關閉視窗。

如有需要，執行 `make explain` 來顯示 menhir 偵測到的衝突。

---

### 1. 註解

**問題 1** 完成檔案 [lexer.mll](lexer.mll)，忽略空白和註解，並在輸入結束時回傳 token `EOF`。指令 `make` 應該會開啟一個空白視窗，因為此時檔案 `test.logo` 只包含註解。

---

### 2. 算術表達式

**問題 2** 更新解析器以接受算術表達式和 `forward` 陳述式。

檔案 `test.logo` 包含：
```
forward 100
```

應該被接受，並且視窗應該開啟並顯示一條水平線（100 像素長）。檢查算術運算的優先順序，例如：
```
forward 100 + 1 * 0
```

如果優先順序錯誤，你會得到一個點而不是一條線。

---

### 3. 其他基本陳述式

**問題 3** 新增其他基本陳述式的語法，即 `penup`、`pendown`、`turnleft`、`turnright` 和 `color`。

使用以下程式測試：
```
forward 100
turnleft 90
color red
forward 100
```

---

### 4. 區塊和控制結構

**問題 4** 新增區塊和控制結構 `if` 和 `repeat` 的語法。`if` 的兩個文法規則應該會觸發一個 shift/reduce 衝突。識別它、理解它，並以最適當的方式解決它。

使用以下程式測試：
```
repeat 4 {
    forward 100
    turnleft 90
}
```

---

### 5. 函數

**問題 5** 最後，新增函數宣告和函數呼叫的語法。

你可以使用子目錄 `tests` 中提供的檔案來測試。

指令 `make tests` 會在這些檔案上分別執行程式。你應該會得到以下圖片（中間按鍵切換）：

![測試結果圖片](tests結果示意圖)
（顯示六個不同的圖形輸出：網格、紅色圓圈、三角形碎形、謝爾賓斯基三角形、花形圖案、紅色網格）

---

## 總結

完成此作業後，你將實作一個完整的 Mini-Turtle 語言解析器，包括：
1. 詞法分析（註解和 token）
2. 算術表達式解析
3. 基本繪圖指令
4. 控制結構（條件和迴圈）
5. 函數定義和呼叫

祝你順利完成作業！