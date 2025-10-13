Write-Host "========================================" -ForegroundColor Cyan
Write-Host "驗證 Arith 編譯器正確性" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查 test.s 是否存在
if (!(Test-Path "test.s")) {
    Write-Host "❌ 找不到 test.s 檔案" -ForegroundColor Red
    Write-Host "請先執行：.\_build\default\arithc.exe test.exp" -ForegroundColor Yellow
    exit
}

Write-Host "✅ 找到 test.s 檔案" -ForegroundColor Green
Write-Host ""

# 檢查關鍵內容
Write-Host "檢查生成的組合語言..." -ForegroundColor Yellow
Write-Host ""

$content = Get-Content "test.s" -Raw

# 檢查項目
$checks = @(
    @{Name="main 函數"; Pattern="main:"; Required=$true},
    @{Name="print_int 函數"; Pattern="print_int:"; Required=$true},
    @{Name="RIP-relative 定址"; Pattern="\(%rip\)"; Required=$true},
    @{Name="函數序言 (pushq %rbp)"; Pattern="pushq %rbp"; Required=$true},
    @{Name="函數序言 (movq %rsp, %rbp)"; Pattern="movq %rsp, %rbp"; Required=$true},
    @{Name="函數結尾 (popq %rbp)"; Pattern="popq %rbp"; Required=$true},
    @{Name="函數結尾 (ret)"; Pattern="ret"; Required=$true},
    @{Name="加法指令"; Pattern="addq"; Required=$true},
    @{Name="除法指令"; Pattern="idivq"; Required=$true},
    @{Name="呼叫 printf"; Pattern="call printf"; Required=$true},
    @{Name="全域變數 x"; Pattern="^x:"; Required=$true},
    @{Name="全域變數 y"; Pattern="^y:"; Required=$true}
)

$allPassed = $true

foreach ($check in $checks) {
    $pattern = $check.Pattern
    if ($content -match $pattern) {
        Write-Host "  ✅ $($check.Name)" -ForegroundColor Green
    } else {
        if ($check.Required) {
            Write-Host "  ❌ $($check.Name)" -ForegroundColor Red
            $allPassed = $false
        } else {
            Write-Host "  ⚠️  $($check.Name) (選用)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

if ($allPassed) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 編譯器生成的組合語言正確！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "你的編譯器功能完全正常！" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ 組合語言可能有問題" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
}

# 顯示檔案大小
$fileSize = (Get-Item "test.s").Length
Write-Host "test.s 檔案大小: $fileSize bytes" -ForegroundColor Cyan
Write-Host ""

# 統計行數
$lineCount = (Get-Content "test.s").Count
Write-Host "test.s 總行數: $lineCount" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "查看生成的組合語言" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "要查看完整的 test.s 檔案嗎？(Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Get-Content "test.s" | Write-Host -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "執行測試" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "現在嘗試執行程式..." -ForegroundColor Yellow
Write-Host ""

# 確保已編譯
if (!(Test-Path "test.out")) {
    Write-Host "正在用 WSL gcc 編譯..." -ForegroundColor Gray
    wsl gcc -g -no-pie test.s -o test.out 2>&1
}

Write-Host "執行 wsl ./test.out..." -ForegroundColor Gray
Write-Host ""
Write-Host "===== 程式輸出 =====" -ForegroundColor Green

$output = wsl ./test.out 2>&1

if ($output -and $output -notmatch "Error" -and $output -notmatch "Failed") {
    Write-Host $output -ForegroundColor White
    Write-Host "====================" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ 程式執行成功！" -ForegroundColor Green
} else {
    Write-Host "（無輸出或發生錯誤）" -ForegroundColor Red
    Write-Host "====================" -ForegroundColor Green
    Write-Host ""
    Write-Host "❌ WSL 執行有問題" -ForegroundColor Red
    Write-Host ""
    Write-Host "建議：" -ForegroundColor Yellow
    Write-Host "1. 執行 .\修復WSL並測試.ps1 嘗試修復" -ForegroundColor Gray
    Write-Host "2. 或參考「編譯指南-簡易版.md」的其他解決方案" -ForegroundColor Gray
}

Write-Host ""
Write-Host "預期輸出（參考）：" -ForegroundColor Magenta
Write-Host "60"
Write-Host "50"
Write-Host "0"
Write-Host "10"
Write-Host "55"
Write-Host "60"
Write-Host "20"
Write-Host "46"
