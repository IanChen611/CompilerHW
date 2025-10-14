@echo off
echo ========================================
echo 在 WSL 中編譯和執行 test.exp
echo ========================================
echo.

echo 步驟 1: 在 WSL 中重新編譯組合語言...
wsl gcc -g -no-pie test.s -o test_linux.out

echo.
echo 步驟 2: 執行程式...
echo.
echo ===== 程式輸出 =====
wsl ./test_linux.out
echo ====================
echo.
echo 完成！

pause
