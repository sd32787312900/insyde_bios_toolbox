# Insyde BIOS 工具箱 (insyde_bios_toolbox)

一款图形化的BIOS管理工具，用于备份、恢复和修改Insyde BIOS配置，支持BIOS固件提取、解析与刷写功能。

## 技术架构

- **编程语言**: Python 3
- **GUI框架**: PyQt5 + QML
- **外部工具**: H2OUVE-W-CONSOLEx64.exe, FPTW64.exe等(已集成)

## 项目主要结构

```
Edit_BIOS_Setting_Interface/
├── insyde_bios_toolbox.py   # 主程序
├── BIOS_Parameters.txt      # BIOS参数模板
├── gui/                    # QML界面文件
│   ├── main.qml            # 主界面
│   └── ...
├── icons/                  # 图标资源
├── BIOSsetting/            # BIOS配置备份存储目录
├── BIOSExtract/            # BIOS固件提取目录
└── BIOSBackup/             # BIOS备份专用目录
```

## 功能特点

- 📊 BIOS配置备份与恢复
- 💾 BIOS固件提取
- 🔍 BIOS固件解析
- 📝 BIOS固件刷写
- 🖼️ 友好的图形界面

## 安装说明

### 从源码运行
1. 克隆本仓库:
   ```bash
   git clone https://github.com/YUSHENKZ/insyde_bios_toolbox.git
   cd Edit_BIOS_Setting_Interface
   ```

2. 安装依赖:
   ```bash
   pip install -r requirements.txt
   ```

3. 运行程序:
   ```bash
   python insyde_bios_toolbox.py
   ```

### 使用预编译版本
   运行根目录打包.bat即可

## 编译打包
使用PyInstaller打包为独立可执行程序:
```bash
pyinstaller insyde_bios_toolbox.spec

## 系统要求

- Windows 10/11 (64位)
- 管理员权限
- Insyde BIOS系统 (H2O BIOS)

## 使用方法

### BIOS配置备份
1. 点击主界面"备份BIOS配置"按钮
2. 备份文件将自动保存到`BIOSsetting`目录，格式为日期时间命名

### BIOS配置恢复
1. 从备份列表中选择配置文件
2. 点击"恢复BIOS配置"按钮
3. 确认操作后等待完成
4. 重启系统应用更改

### BIOS固件提取
1. 点击"提取系统BIOS"按钮
2. 提取的固件将保存到`BIOSBackup`目录

### BIOS固件刷写
1. 选择需要刷写的固件文件
2. 点击"刷写BIOS固件"按钮
3. 完成操作后重启系统

## 常见问题

### 权限问题
**问题**: 无法执行BIOS操作，提示权限不足  
**解决**: 以管理员身份运行程序

### 工具找不到问题
**问题**: 找不到外部工具如H2OUVE-W-CONSOLEx64.exe  
**解决**: 确保工具与程序在同一目录

### BIOS备份失败
**问题**: 无法备份BIOS配置  
**解决**: 检查日志中的详细错误信息，常见原因包括驱动加载失败

### 日志乱码
**问题**: 日志文件显示乱码  
**解决**: 修改setup_logging()函数中的编码设置为UTF-8-SIG



```

### 贡献指南
1. Fork仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 提交Pull Request

## 警告

⚠️ **使用风险自负** ⚠️  
修改BIOS设置和刷写固件可能导致系统不稳定或无法启动。请在操作前备份重要数据。

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

如果你喜欢这个项目，请给它一个星标 ⭐ 
