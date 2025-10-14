# Mini-Python WSL 編譯指南

> 本指南專門針對使用 WSL2 (Windows Subsystem for Linux) 環境的使用者

## 環境需求

- Windows 10/11 with WSL2
- OCaml 編譯器（已通過 opam 安裝）
- dune 構建系統
- menhir 解析器生成器

## 初次環境設置

### 1. 檢查 OCaml 和 opam 是否已安裝

在 WSL 終端中執行：

```bash
ocaml -version
opam --version
```

如果看到版本號，表示已安裝。如果未安裝，請參考 [OCaml 官方安裝指南](https://ocaml.org/install)。

### 2. 安裝 menhir（必需）

如果這是你第一次編譯 mini-python，需要安裝 menhir：

```bash
opam install menhir -y
```

安裝過程可能需要幾分鐘。成功後會看到：

```
Done.
# Run eval $(opam env) to update the current shell environment
```

## 編譯方法

### 方式一：在 WSL 終端中編譯（推薦）

1. 打開 WSL 終端
2. 切換到專案目錄：

```bash
cd /mnt/f/CompilerHW/HW2/mini-python
```

3. 設置 opam 環境並編譯：

```bash
export PATH=/home/$USER/.opam/default/bin:$PATH
dune build minipython.exe
```

4. 執行測試：

```bash
dune exec ./minipython.exe test.py
```

### 方式二：從 Windows 命令行調用 WSL

如果你在 Windows 的命令提示字元或 PowerShell 中工作：

```bash
wsl -e bash -c "cd /mnt/f/CompilerHW/HW2/mini-python && export PATH=/home/$USER/.opam/default/bin:\$PATH && dune build minipython.exe"
```

執行測試：

```bash
wsl -e bash -c "cd /mnt/f/CompilerHW/HW2/mini-python && export PATH=/home/$USER/.opam/default/bin:\$PATH && dune exec ./minipython.exe test.py"
```

## 測試方法

### 測試單一檔案

```bash
# 在 WSL 中
cd /mnt/f/CompilerHW/HW2/mini-python
export PATH=/home/$USER/.opam/default/bin:$PATH
dune exec ./minipython.exe test.py
```

### 測試其他範例檔案

```bash
dune exec ./minipython.exe tests/good/arith1.py
dune exec ./minipython.exe tests/good/bool1.py
dune exec ./minipython.exe tests/good/var1.py
```

### 比對輸出結果

```bash
dune exec ./minipython.exe tests/good/arith1.py > output.txt
diff output.txt tests/good/arith1.out
```

如果沒有輸出，表示結果完全正確。

## test.py 預期輸出

執行 `test.py` 應該看到以下輸出：

```
7
5
3
----------
False
True
ok
42
False
hello world!
```

這表示：
- ✓ 第一題（算術運算）通過
- ✓ 第二題（布林運算與條件判斷）通過
- ✓ 第三題（變數賦值與字串連接）通過

## 常見問題與解決方案

### 問題 1：`dune: command not found`

**原因**：opam 環境變數未正確設置

**解決方案**：

```bash
export PATH=/home/$USER/.opam/default/bin:$PATH
# 或者
eval $(opam env)
```

為了永久生效，可以將以下內容加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
eval $(opam env)
```

### 問題 2：`Program menhir not found`

**原因**：menhir 未安裝

**解決方案**：

```bash
opam install menhir -y
```

### 問題 3：`lexical error: illegal character`

**原因**：測試檔案包含 Windows 換行符 (CRLF) 或特殊字符

**解決方案**：

方法 A - 重新創建檔案（在 WSL 中）：

```bash
cd /mnt/f/CompilerHW/HW2/mini-python
cat > test.py << 'EOF'
# Question 1
print(1+2*3)
print((3*3 +4*4)//5)
print(10-3-4)
print("----------")

# Question 2
print(not True and 1//0==0)
print(1<2)
if False or True:
    print("ok")
else:
    print("oups")

# Question 3
x = 41
x = x+1
print(x)
b = True and False
print(b)
s = "hello" + " world!"
print(s)
EOF
```

方法 B - 使用編輯器：
- VS Code：點擊右下角 "CRLF"，改為 "LF"
- Vim：`:set ff=unix` 然後 `:wq`

### 問題 4：`Assert_failure` 錯誤

**原因**：代碼中還有未實現的 `assert false`

**解決方案**：檢查 `interp.ml` 中是否有需要實現的功能。例如：

- 第三題需要實現 `Sassign`（變數賦值）
- 第四題需要實現 `Sreturn` 和 `Ecall`（函數相關）
- 第五題需要實現 `Sfor`, `Sset`, `Elist` 等（列表相關）

## 編譯優化提示

### 快速重新編譯

修改 `interp.ml` 後，只需要：

```bash
dune build minipython.exe
```

Dune 會自動檢測變更並只重新編譯必要的部分。

### 清理編譯產物

如果遇到奇怪的編譯錯誤：

```bash
dune clean
dune build minipython.exe
```

### 查看詳細編譯訊息

```bash
dune build minipython.exe --verbose
```

## 路徑說明

在 WSL 中訪問 Windows 檔案系統：

- Windows 的 `F:\` 對應 WSL 的 `/mnt/f/`
- Windows 的 `C:\Users\YourName\` 對應 WSL 的 `/mnt/c/Users/YourName/`

## 與原版測試指南的差異

| 項目 | 原版測試指南 | WSL 版本 |
|------|-------------|----------|
| 編譯命令 | `dune build` | 需要先設置 PATH |
| 執行命令 | 直接執行 | 使用 `wsl -e bash -c` 或在 WSL 內執行 |
| 檔案格式 | 無限制 | 必須使用 LF 換行符 |
| 路徑格式 | 相對路徑 | 需要 `/mnt/` 前綴 |
| 環境變數 | 自動設置 | 需要手動 export PATH |

## 進階技巧

### 創建編譯腳本

在專案目錄創建 `build.sh`：

```bash
#!/bin/bash
export PATH=/home/$USER/.opam/default/bin:$PATH
cd /mnt/f/CompilerHW/HW2/mini-python
dune build minipython.exe
echo "編譯完成！"
```

賦予執行權限並使用：

```bash
chmod +x build.sh
./build.sh
```

### 自動測試所有範例

```bash
#!/bin/bash
export PATH=/home/$USER/.opam/default/bin:$PATH
cd /mnt/f/CompilerHW/HW2/mini-python

for test in tests/good/*.py; do
    echo "測試: $test"
    dune exec ./minipython.exe "$test" > temp.out
    expected="${test%.py}.out"
    if diff -q temp.out "$expected" > /dev/null 2>&1; then
        echo "✓ 通過"
    else
        echo "✗ 失敗"
        diff temp.out "$expected"
    fi
done
rm temp.out
```

## 結語

本指南涵蓋了在 WSL 環境下編譯和測試 Mini-Python 的所有必要步驟。如果遇到其他問題，請檢查：

1. WSL 版本是否為 WSL2
2. OCaml 和 opam 是否正確安裝
3. PATH 環境變數是否正確設置
4. 檔案是否使用正確的換行符格式

祝編譯順利！
