Write-Host "========================================" -ForegroundColor Cyan
Write-Host "在 WSL 中編譯和執行 test.exp" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "步驟 1: 在 WSL 中重新編譯組合語言..." -ForegroundColor Yellow
wsl gcc -g -no-pie test.s -o test_linux.out

Write-Host ""
Write-Host "步驟 2: 執行程式..." -ForegroundColor Yellow
Write-Host ""
Write-Host "===== 程式輸出 =====" -ForegroundColor Green
wsl ./test_linux.out
Write-Host "====================" -ForegroundColor Green
Write-Host ""
Write-Host "完成！" -ForegroundColor Green

# 顯示預期輸出對比
Write-Host ""
Write-Host "預期輸出（來自 assignment01.pdf）：" -ForegroundColor Magenta
Write-Host "60"
Write-Host "50"
Write-Host "0"
Write-Host "10"
Write-Host "55"
Write-Host "60"
Write-Host "20"
Write-Host "46"
