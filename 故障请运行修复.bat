@echo off
chcp 65001 > nul
echo 正在修复Insyde BIOS工具箱打包问题...

if not exist "dist\Insyde_BIOS_工具箱" (
    echo 错误：找不到打包输出目录！
    echo 请先运行原始打包命令，然后再运行此修复脚本。
    pause
    exit /b
)

echo 复制外部EXE文件和DLL到打包目录...
copy /y FPTW64.exe "dist\Insyde_BIOS_工具箱\"
copy /y H2OUVE-W-CONSOLEx64.exe "dist\Insyde_BIOS_工具箱\"
copy /y H2OUVE-W-GUIx64.exe "dist\Insyde_BIOS_工具箱\"
copy /y H2OEZE.exe "dist\Insyde_BIOS_工具箱\"
copy /y Idrvdll.dll "dist\Insyde_BIOS_工具箱\"
copy /y Pmxdll.dll "dist\Insyde_BIOS_工具箱\"
copy /y segwindrv.* "dist\Insyde_BIOS_工具箱\"

echo 创建必要目录...
if not exist "dist\Insyde_BIOS_工具箱\BIOSBackup" mkdir "dist\Insyde_BIOS_工具箱\BIOSBackup"
if not exist "dist\Insyde_BIOS_工具箱\BIOSExtract" mkdir "dist\Insyde_BIOS_工具箱\BIOSExtract"
if not exist "dist\Insyde_BIOS_工具箱\BIOSsetting" mkdir "dist\Insyde_BIOS_工具箱\BIOSsetting"

if exist runtime (
    echo 复制runtime目录...
    xcopy /y /i /e /q runtime "dist\Insyde_BIOS_工具箱\runtime\"
) else (
    echo 警告：runtime目录不存在！
)

if exist locales (
    echo 复制本地化文件...
    xcopy /y /i /e /q locales "dist\Insyde_BIOS_工具箱\locales\"
) else (
    echo 警告：locales目录不存在！
)

echo 修复完成！现在您的可执行文件应该包含所有必要的外部文件了。
pause 