Write-Host "========================================" -ForegroundColor Cyan
Write-Host "修復 WSL 並測試程式" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "步驟 1: 關閉 WSL systemd（修復啟動問題）..." -ForegroundColor Yellow
Write-Host "正在修改 WSL 配置檔..." -ForegroundColor Gray

# 修改 WSL 配置以禁用 systemd
wsl -u root bash -c "echo '[boot]' > /etc/wsl.conf && echo 'systemd=false' >> /etc/wsl.conf"

Write-Host "配置已更新，需要重啟 WSL..." -ForegroundColor Gray
Write-Host ""

# 關閉 WSL
Write-Host "步驟 2: 重啟 WSL..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 2

Write-Host "WSL 已重啟！" -ForegroundColor Green
Write-Host ""

# 重新編譯（確保使用最新的 test.s）
Write-Host "步驟 3: 重新用 WSL gcc 編譯..." -ForegroundColor Yellow
wsl gcc -g -no-pie test.s -o test.out

Write-Host ""
Write-Host "步驟 4: 執行程式..." -ForegroundColor Yellow
Write-Host ""
Write-Host "===== 程式輸出 =====" -ForegroundColor Green

# 執行程式
$output = wsl ./test.out 2>&1

if ($output) {
    Write-Host $output -ForegroundColor White
} else {
    Write-Host "（沒有輸出或發生錯誤）" -ForegroundColor Red
    Write-Host ""
    Write-Host "嘗試用 strace 診斷問題..." -ForegroundColor Yellow
    wsl strace -o trace.log ./test.out 2>&1
    Write-Host "診斷資訊已儲存到 trace.log" -ForegroundColor Gray
}

Write-Host "====================" -ForegroundColor Green
Write-Host ""

Write-Host "預期輸出：" -ForegroundColor Magenta
Write-Host "60"
Write-Host "50"
Write-Host "0"
Write-Host "10"
Write-Host "55"
Write-Host "60"
Write-Host "20"
Write-Host "46"
Write-Host ""

Write-Host "完成！" -ForegroundColor Green
Write-Host ""
Write-Host "如果還是沒有輸出，請嘗試：" -ForegroundColor Yellow
Write-Host "1. 在 PowerShell（系統管理員）執行：wsl --update" -ForegroundColor Gray
Write-Host "2. 重新啟動電腦" -ForegroundColor Gray
Write-Host "3. 或查看下方的其他解決方案" -ForegroundColor Gray
