# -*- mode: python ; coding: utf-8 -*-

import os
import sys
from PyInstaller.utils.hooks import collect_data_files

block_cipher = None

# 获取当前工作目录
current_dir = os.path.abspath(os.path.dirname('__file__'))

# 收集QML文件
qml_files = [
    ('gui/main.qml', 'gui'),
    ('gui/CardItem.qml', 'gui'),
    ('gui/ExtractFirmwarePage.qml', 'gui'),
    ('gui/FlashFirmwarePage.qml', 'gui'),
    ('gui/BackupConfigPage.qml', 'gui'),
    ('gui/insyde_bios_toolbox.qrc', 'gui')
]

# 收集图标文件
icon_files = []
for file in os.listdir(os.path.join(current_dir, 'icons')):
    if file.endswith('.png'):
        icon_files.append(('icons/' + file, 'icons'))

# 收集必要的可执行文件
exe_files = [
    ('FPTW64.exe', '.'),
    ('H2OUVE-W-CONSOLEx64.exe', '.'),
    ('H2OUVE-W-GUIx64.exe', '.'),
    ('H2OEZE.exe', '.')
]

# 收集DLL文件
dll_files = [
    ('Idrvdll.dll', '.'),
    ('Pmxdll.dll', '.')
]

# 合并所有数据文件
datas = qml_files + icon_files + exe_files + dll_files

# 添加BIOSUtilities模块
biosutils_path = os.path.join(current_dir, "BIOSUtilities-main", "BIOSUtilities-main")
biosutils_datas = []
if os.path.exists(biosutils_path):
    for root, dirs, files in os.walk(biosutils_path):
        for file in files:
            if file.endswith('.py'):
                rel_dir = os.path.relpath(root, current_dir)
                biosutils_datas.append((os.path.join(rel_dir, file), rel_dir))

datas.extend(biosutils_datas)

# 创建Analysis对象
a = Analysis(
    ['insyde_bios_toolbox.py'],
    pathex=[current_dir],
    binaries=[],
    datas=datas,
    hiddenimports=['PyQt5.QtQml', 'PyQt5.QtQuick', 'PyQt5.QtCore', 'PyQt5.QtGui'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# 创建PYZ对象
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# 创建可执行文件
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Insyde_BIOS_工具箱',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='icons/editor_icon.png',  # 设置应用图标
)

# 创建集合
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Insyde_BIOS_工具箱',
) 