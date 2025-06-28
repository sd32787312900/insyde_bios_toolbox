@echo off
chcp 65001 > nul
echo 正在构建Insyde BIOS工具箱可执行文件...

rem 创建日志文件
set LOG_FILE=build_log.txt
echo 构建日志 - %date% %time% > %LOG_FILE%

rem 清理旧的构建文件
echo 清理旧的构建文件... >> %LOG_FILE%
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist

rem 使用PyInstaller构建应用
echo 使用PyInstaller构建应用... >> %LOG_FILE%
pyinstaller --clean insyde_bios_toolbox.spec
if errorlevel 1 (
    echo PyInstaller构建失败！请检查错误信息。 >> %LOG_FILE%
    echo PyInstaller构建失败！请检查错误信息。
    goto :error
)

rem 复制运行时需要的额外文件到dist目录
if exist dist (
    echo 复制额外的运行时文件... >> %LOG_FILE%
    
    rem 复制EXE和DLL文件
    echo 复制EXE和DLL文件... >> %LOG_FILE%
    copy FPTW64.exe "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    copy H2OUVE-W-CONSOLEx64.exe "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    copy H2OUVE-W-GUIx64.exe "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    copy H2OEZE.exe "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    copy Idrvdll.dll "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    copy Pmxdll.dll "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    copy segwindrv.* "dist\Insyde_BIOS_工具箱\" >> %LOG_FILE% 2>&1
    
    rem 创建必要的目录
    echo 创建必要的目录... >> %LOG_FILE%
    if not exist "dist\Insyde_BIOS_工具箱\BIOSBackup" mkdir "dist\Insyde_BIOS_工具箱\BIOSBackup" >> %LOG_FILE% 2>&1
    if not exist "dist\Insyde_BIOS_工具箱\BIOSExtract" mkdir "dist\Insyde_BIOS_工具箱\BIOSExtract" >> %LOG_FILE% 2>&1
    if not exist "dist\Insyde_BIOS_工具箱\BIOSsetting" mkdir "dist\Insyde_BIOS_工具箱\BIOSsetting" >> %LOG_FILE% 2>&1
    
    rem 复制runtime目录
    if exist runtime (
        echo 复制runtime目录... >> %LOG_FILE%
        xcopy /y /i /e runtime "dist\Insyde_BIOS_工具箱\runtime\" >> %LOG_FILE% 2>&1
        if errorlevel 1 (
            echo runtime目录复制失败！ >> %LOG_FILE%
            echo runtime目录复制失败！
        ) else (
            echo runtime目录复制成功！ >> %LOG_FILE%
        )
    ) else (
        echo 警告：runtime目录不存在！ >> %LOG_FILE%
        echo 警告：runtime目录不存在！
    )
    
    rem 复制本地化文件
    if exist locales (
        echo 复制本地化文件... >> %LOG_FILE%
        xcopy /y /i /e locales "dist\Insyde_BIOS_工具箱\locales\" >> %LOG_FILE% 2>&1
        if errorlevel 1 (
            echo locales目录复制失败！ >> %LOG_FILE%
            echo locales目录复制失败！
        ) else (
            echo locales目录复制成功！ >> %LOG_FILE%
        )
    ) else (
        echo 警告：locales目录不存在！ >> %LOG_FILE%
        echo 警告：locales目录不存在！
    )
    
    echo 打包完成！ >> %LOG_FILE%
    echo 打包完成！
    goto :end
) else (
    echo 打包失败，PyInstaller未创建dist目录！请检查错误信息。 >> %LOG_FILE%
    echo 打包失败，PyInstaller未创建dist目录！请检查错误信息。
    goto :error
)

:error
echo 构建过程中出现错误，请查看 %LOG_FILE% 获取详细信息。
goto :end

:end
echo 日志文件保存在：%LOG_FILE%
pause 