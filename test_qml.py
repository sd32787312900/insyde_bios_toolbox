#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
from PyQt5.QtCore import QUrl
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine

def main():
    """测试QML加载"""
    try:
        # 创建应用程序
        app = QGuiApplication(sys.argv)
        app.setOrganizationName("InsydeBiosTool")
        app.setApplicationName("Insyde BIOS Toolbox - Test")
        
        # 创建QML引擎
        engine = QQmlApplicationEngine()
        
        # 添加QML导入路径
        engine.addImportPath("qrc:/")
        
        # 加载QML文件
        qml_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "gui", "main.qml")
        print(f"加载QML文件: {qml_file}")
        engine.load(QUrl.fromLocalFile(qml_file))
        
        # 检查是否成功加载QML
        if not engine.rootObjects():
            print("无法加载QML文件")
            sys.exit(-1)
        
        print("QML加载成功")
        # 启动应用程序
        sys.exit(app.exec_())
    except Exception as e:
        import traceback
        error_msg = traceback.format_exc()
        print(f"错误: {str(e)}")
        print(error_msg)

if __name__ == "__main__":
    main() 