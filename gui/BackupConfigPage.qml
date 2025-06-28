import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import QtGraphicalEffects 1.15
import Qt.labs.folderlistmodel 2.15

Item {
    id: backupConfigPage
    
    // 信号
    signal backRequested()
    
    // 属性
    property string selectedBackupFile: ""
    property string selectedImportFile: ""
    property bool isBackingUp: false
    property bool isWriting: false
    property bool backupSuccessful: false
    property bool writeSuccessful: false
    property var backupFiles: []
    
    // 处理备份结果
    function handleBackupResult(success, message) {
        backupConfigPage.isBackingUp = false
        backupConfigPage.backupSuccessful = success
        
        if (success) {
            // 确保在备份成功后刷新文件列表
            loadBackupFiles()
            console.log("备份成功，刷新文件列表")
        } else {
            errorDialog.message = message
            errorDialog.open()
        }
    }
    
    // 处理写入结果
    function handleWriteResult(success, message) {
        backupConfigPage.isWriting = false
        backupConfigPage.writeSuccessful = success
        
        if (!success) {
            errorDialog.message = message
            errorDialog.open()
        }
    }
    
    // 加载备份文件列表
    function loadBackupFiles() {
        backupConfigPage.backupFiles = backend.getBackupFiles()
    }
    
    // 顶部导航栏
    Rectangle {
        id: topBar
        height: 50
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: "#1A1A1A"
        
        // 返回按钮
        Rectangle {
            id: backButton
            width: 100
            height: 36
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            radius: 5
            color: backMouseArea.containsMouse ? "#333333" : "#252525"
            
            Row {
                anchors.centerIn: parent
                spacing: 5
                
                Text {
                    text: "←"
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: "返回"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            MouseArea {
                id: backMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!isBackingUp && !isWriting) {
                        backRequested()
                    } else {
                        operationWarningDialog.open()
                    }
                }
            }
            
            // 动画效果
            Behavior on color {
                ColorAnimation { duration: 100 }
            }
        }
        
        // 页面标题
        Text {
            anchors.centerIn: parent
            text: "BIOS配置备份与写入"
            color: "#FFFFFF"
            font.pixelSize: 20
            font.bold: true
        }
        
        // 刷新按钮
        Rectangle {
            id: refreshButton
            width: 36
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            radius: 5
            color: refreshMouseArea.containsMouse ? "#333333" : "#252525"
            
            Text {
                anchors.centerIn: parent
                text: "⟳"
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
            }
            
            MouseArea {
                id: refreshMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    loadBackupFiles()
                }
            }
            
            // 动画效果
            Behavior on color {
                ColorAnimation { duration: 100 }
            }
        }
    }
    
    // 操作过程中返回的警告对话框
    Dialog {
        id: operationWarningDialog
        title: "警告"
        standardButtons: Dialog.Ok
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "正在进行BIOS配置操作，请等待完成后再返回。中断操作可能会导致配置不完整！"
            color: "#ff0000"
        }
    }
    
    // 主内容区域
    Rectangle {
        id: contentArea
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"
        
        // 分割视图
        SplitView {
            anchors.fill: parent
            anchors.margins: 10
            orientation: Qt.Horizontal
            
            // 左侧：备份文件列表
            Rectangle {
                id: fileListSection
                SplitView.preferredWidth: parent.width * 0.35
                SplitView.minimumWidth: 200
                color: "#252525"
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    // 标题
                    Text {
                        text: "已备份的配置文件"
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // 文件列表
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1A1A1A"
                        radius: 4
                        
                        ListView {
                            id: backupFileList
                            anchors.fill: parent
                            anchors.margins: 5
                            clip: true
                            model: backupConfigPage.backupFiles
                            
                            delegate: Rectangle {
                                width: backupFileList.width - 10
                                height: 40
                                color: selectedBackupFile === modelData.name ? "#3A3A3A" : "transparent"
                                radius: 3
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        selectedBackupFile = modelData.name
                                    }
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 5
                                    
                                    Text {
                                        text: "📄"
                                        color: "#AAAAAA"
                                        font.pixelSize: 16
                                    }
                                    
                                    Text {
                                        text: modelData.name
                                        color: "#FFFFFF"
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                    
                                    // 显示文件大小
                                    Text {
                                        text: modelData.size
                                        color: "#AAAAAA"
                                        font.pixelSize: 12
                                    }
                                    
                                    // 重命名按钮
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        color: renameMouseArea.containsMouse ? "#555555" : "transparent"
                                        radius: 3
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✎"
                                            color: "#FFFFFF"
                                        }
                                        
                                        MouseArea {
                                            id: renameMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                renameFileDialog.oldFileName = modelData.name
                                                renameFileDialog.newFileName = modelData.name
                                                renameFileDialog.open()
                                            }
                                        }
                                    }
                                    
                                    // 删除按钮
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        color: deleteMouseArea.containsMouse ? "#AA3333" : "transparent"
                                        radius: 3
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: "#FFFFFF"
                                        }
                                        
                                        MouseArea {
                                            id: deleteMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                deleteFileDialog.fileName = modelData.name
                                                deleteFileDialog.open()
                                            }
                                        }
                                    }
                                }
                            }
                            
                            ScrollBar.vertical: ScrollBar {}
                        }
                    }
                    
                    // 文件操作按钮
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        // 重命名按钮
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            color: renameBtnMouseArea.containsMouse ? "#0088FF" : "#007ACC"
                            radius: 4
                            enabled: selectedBackupFile !== ""
                            opacity: enabled ? 1.0 : 0.5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "重命名"
                                color: "#FFFFFF"
                                font.bold: true
                            }
                            
                            MouseArea {
                                id: renameBtnMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.enabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (selectedBackupFile !== "") {
                                        renameFileDialog.oldFileName = selectedBackupFile
                                        renameFileDialog.newFileName = selectedBackupFile
                                        renameFileDialog.open()
                                    }
                                }
                            }
                        }
                        
                        // 写入按钮
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            color: writeBtnMouseArea.containsMouse ? "#AA5500" : "#884400"
                            radius: 4
                            enabled: selectedBackupFile !== ""
                            opacity: enabled ? 1.0 : 0.5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "写入"
                                color: "#FFFFFF"
                                font.bold: true
                            }
                            
                            MouseArea {
                                id: writeBtnMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.enabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (selectedBackupFile !== "") {
                                        writeConfirmDialog.fileName = selectedBackupFile
                                        writeConfirmDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 右侧：操作区域
            Rectangle {
                id: operationSection
                SplitView.fillWidth: true
                color: "transparent"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 15
                    
                    // 备份区域
                    Rectangle {
                        Layout.fillWidth: true
                        height: 180
                        color: "#252525"
                        radius: 5
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 10
                            
                            Text {
                                text: "创建BIOS配置备份"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#333333"
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Text {
                                    text: "文件名称："
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    color: "#1A1A1A"
                                    radius: 3
                                    
                                    TextInput {
                                        id: backupFileNameInput
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        color: "#FFFFFF"
                                        selectionColor: "#007ACC"
                                        font.pixelSize: 14
                                        clip: true
                                        
                                        // 自动生成默认文件名
                                        Component.onCompleted: {
                                            var now = new Date()
                                            var year = now.getFullYear()
                                            var month = ("0" + (now.getMonth() + 1)).slice(-2)
                                            var day = ("0" + now.getDate()).slice(-2)
                                            var hours = ("0" + now.getHours()).slice(-2)
                                            var minutes = ("0" + now.getMinutes()).slice(-2)
                                            var seconds = ("0" + now.getSeconds()).slice(-2)
                                            text = "BIOS_Parameters_" + year + month + day + "_" + hours + minutes + seconds + ".txt"
                                        }
                                    }
                                }
                                
                                // 自动生成文件名按钮
                                Rectangle {
                                    width: 30
                                    height: 30
                                    color: autoGenMouseArea.containsMouse ? "#333333" : "#252525"
                                    radius: 3
                                    border.color: "#444444"
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⟳"
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                    }
                                    
                                    MouseArea {
                                        id: autoGenMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var now = new Date()
                                            var year = now.getFullYear()
                                            var month = ("0" + (now.getMonth() + 1)).slice(-2)
                                            var day = ("0" + now.getDate()).slice(-2)
                                            var hours = ("0" + now.getHours()).slice(-2)
                                            var minutes = ("0" + now.getMinutes()).slice(-2)
                                            var seconds = ("0" + now.getSeconds()).slice(-2)
                                            backupFileNameInput.text = "BIOS_Parameters_" + year + month + day + "_" + hours + minutes + seconds + ".txt"
                                        }
                                    }
                                }
                            }
                            
                            // 备份按钮
                            Rectangle {
                                Layout.fillWidth: true
                                height: 45
                                color: backupBtnMouseArea.containsMouse && !isBackingUp ? "#0088FF" : "#007ACC"
                                radius: 4
                                opacity: isBackingUp ? 0.7 : 1.0
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: isBackingUp ? "正在备份..." : "备份当前BIOS配置"
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 15
                                }
                                
                                MouseArea {
                                    id: backupBtnMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !isBackingUp && !isWriting
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (backupFileNameInput.text.trim() === "") {
                                            errorDialog.message = "请输入有效的文件名"
                                            errorDialog.open()
                                            return
                                        }
                                        
                                        backupConfigPage.isBackingUp = true
                                        backupConfigPage.backupSuccessful = false
                                        
                                        // 调用后端进行备份
                                        var params = {
                                            fileName: backupFileNameInput.text
                                        }
                                        
                                        backend.backupBiosConfig(JSON.stringify(params))
                                    }
                                }
                                
                                // 动画效果
                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }
                            }
                            
                            // 状态信息
                            Text {
                                id: backupStatusText
                                Layout.fillWidth: true
                                text: backupSuccessful ? "✓ 备份成功！文件已保存到BIOSsetting目录" : 
                                      (isBackingUp ? "正在备份BIOS配置..." : "")
                                color: backupSuccessful ? "#00AA00" : "#AAAAAA"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                visible: isBackingUp || backupSuccessful
                            }
                        }
                    }
                    
                    // 导入外部配置区域
                    Rectangle {
                        Layout.fillWidth: true
                        height: 180
                        color: "#252525"
                        radius: 5
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 10
                            
                            Text {
                                text: "导入外部配置文件"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#333333"
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 35
                                color: "#1A1A1A"
                                radius: 3
                                
                                Text {
                                    id: importFilePathText
                                    anchors.left: parent.left
                                    anchors.right: importBrowseButton.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 10
                                    text: selectedImportFile === "" ? "未选择文件" : selectedImportFile
                                    color: selectedImportFile === "" ? "#888888" : "#FFFFFF"
                                    elide: Text.ElideMiddle
                                    font.pixelSize: 14
                                }
                                
                                Rectangle {
                                    id: importBrowseButton
                                    width: 80
                                    height: 25
                                    anchors.right: parent.right
                                    anchors.rightMargin: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 3
                                    color: importBrowseMouseArea.containsMouse ? "#0088FF" : "#007ACC"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "浏览..."
                                        color: "#FFFFFF"
                                        font.bold: true
                                    }
                                    
                                    MouseArea {
                                        id: importBrowseMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            importFileDialog.open()
                                        }
                                    }
                                    
                                    // 动画效果
                                    Behavior on color {
                                        ColorAnimation { duration: 100 }
                                    }
                                }
                            }
                            
                            // 导入并写入按钮
                            Rectangle {
                                Layout.fillWidth: true
                                height: 45
                                color: importWriteBtnMouseArea.containsMouse && !isWriting ? "#AA5500" : "#884400"
                                radius: 4
                                opacity: isWriting || selectedImportFile === "" ? 0.7 : 1.0
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: isWriting ? "正在写入..." : "导入并写入BIOS配置"
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 15
                                }
                                
                                MouseArea {
                                    id: importWriteBtnMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !isBackingUp && !isWriting && selectedImportFile !== ""
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (selectedImportFile !== "") {
                                            importWriteConfirmDialog.open()
                                        }
                                    }
                                }
                                
                                // 动画效果
                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }
                            }
                            
                            // 状态信息
                            Text {
                                id: writeStatusText
                                Layout.fillWidth: true
                                text: writeSuccessful ? "✓ 配置写入成功！系统将在10秒后重启以应用更改" : 
                                      (isWriting ? "正在写入BIOS配置..." : "")
                                color: writeSuccessful ? "#00AA00" : "#AAAAAA"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                visible: isWriting || writeSuccessful
                            }
                        }
                    }
                    
                    // 操作说明
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#252525"
                        radius: 5
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 10
                            
                            Text {
                                text: "操作说明"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#333333"
                            }
                            
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                
                                Text {
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    color: "#CCCCCC"
                                    text: "• 备份功能：将当前BIOS配置备份到文件中，保存在BIOSsetting目录下\n\n" +
                                          "• 写入功能：将已备份的配置文件写入BIOS，需要重启系统生效\n\n" +
                                          "• 导入功能：导入外部的BIOS配置文件并写入BIOS\n\n" +
                                          "• 文件管理：可以查看、删除或写入已备份的配置文件\n\n" +
                                          "• 注意事项：\n" +
                                          "  - 写入不正确的配置可能导致系统不稳定\n" +
                                          "  - 写入配置后需要重启系统才能生效\n" +
                                          "  - 建议在写入前先备份当前配置"
                                    lineHeight: 1.3
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 导入文件对话框
    FileDialog {
        id: importFileDialog
        title: "选择BIOS配置文件"
        folder: shortcuts.home
        nameFilters: ["BIOS配置文件 (*.txt)", "所有文件 (*)"]
        selectExisting: true
        selectMultiple: false
        onAccepted: {
            selectedImportFile = importFileDialog.fileUrl.toString().replace("file:///", "")
        }
    }
    
    // 重命名文件对话框
    Dialog {
        id: renameFileDialog
        property string oldFileName: ""
        property string newFileName: ""
        title: "重命名文件"
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        ColumnLayout {
            width: parent.width
            spacing: 10
            
            Text {
                text: "请输入新的文件名:"
                Layout.fillWidth: true
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 30
                color: "#FFFFFF"
                border.color: "#CCCCCC"
                border.width: 1
                
                TextInput {
                    id: newFileNameInput
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    text: renameFileDialog.newFileName
                    onTextChanged: {
                        renameFileDialog.newFileName = text
                    }
                    
                    // 在对话框打开时选中所有文本
                    Component.onCompleted: {
                        renameFileDialog.opened.connect(function() {
                            newFileNameInput.selectAll()
                            newFileNameInput.forceActiveFocus()
                        })
                    }
                }
            }
        }
        
        onAccepted: {
            if (newFileName.trim() === "") {
                errorDialog.message = "文件名不能为空"
                errorDialog.open()
                return
            }
            
            if (oldFileName === newFileName) {
                return // 名称未变更
            }
            
            var success = backend.renameBackupFile(oldFileName, newFileName)
            if (success) {
                loadBackupFiles() // 重新加载文件列表
                if (selectedBackupFile === oldFileName) {
                    selectedBackupFile = newFileName
                }
            } else {
                errorDialog.message = "文件重命名失败"
                errorDialog.open()
            }
        }
    }
    
    // 删除文件确认对话框
    Dialog {
        id: deleteFileDialog
        property string fileName: ""
        title: "确认删除"
        standardButtons: Dialog.Yes | Dialog.No
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "确定要删除文件 " + deleteFileDialog.fileName + " 吗？"
        }
        
        onYes: {
            var success = backend.deleteBackupFile(deleteFileDialog.fileName)
            if (success) {
                // 短暂延迟后刷新列表，给删除操作留出时间
                deleteTimer.start()
            } else {
                errorDialog.message = "删除文件失败。请退出程序后手动删除文件。"
                errorDialog.open()
            }
        }
    }
    
    // 删除操作延迟计时器
    Timer {
        id: deleteTimer
        interval: 500
        repeat: false
        onTriggered: {
            var deletedFileName = selectedBackupFile
            // 如果当前选择的文件被删除，清空选择
            if (selectedBackupFile === deleteFileDialog.fileName) {
                selectedBackupFile = ""
            }
            loadBackupFiles() // 重新加载文件列表
        }
    }
    
    // 写入确认对话框
    Dialog {
        id: writeConfirmDialog
        property string fileName: ""
        title: "确认写入"
        standardButtons: Dialog.Yes | Dialog.No
        modality: Qt.ApplicationModal
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "您确定要将配置文件 " + writeConfirmDialog.fileName + " 写入BIOS吗？\n\n" +
                  "警告：写入后系统将重启以应用更改。请确保已保存所有工作。"
            color: "#000000"
        }
        
        onYes: {
            backupConfigPage.isWriting = true
            backupConfigPage.writeSuccessful = false
            
            // 调用后端进行写入
            var params = {
                fileName: writeConfirmDialog.fileName,
                isImport: false
            }
            
            backend.writeBiosConfig(JSON.stringify(params))
        }
    }
    
    // 导入写入确认对话框
    Dialog {
        id: importWriteConfirmDialog
        title: "确认导入并写入"
        standardButtons: Dialog.Yes | Dialog.No
        modality: Qt.ApplicationModal
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "您确定要导入并写入外部配置文件吗？\n\n" +
                  "文件: " + selectedImportFile + "\n\n" +
                  "警告：写入后系统将重启以应用更改。请确保已保存所有工作。"
            color: "#000000"
        }
        
        onYes: {
            backupConfigPage.isWriting = true
            backupConfigPage.writeSuccessful = false
            
            // 调用后端进行写入
            var params = {
                fileName: selectedImportFile,
                isImport: true
            }
            
            backend.writeBiosConfig(JSON.stringify(params))
        }
    }
    
    // 错误对话框
    Dialog {
        id: errorDialog
        property string message: ""
        title: "错误"
        standardButtons: Dialog.Ok
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: errorDialog.message
            color: "#FF0000"
        }
    }
    
    // 组件初始化
    Component.onCompleted: {
        // 初始加载文件列表
        loadBackupFiles()
        console.log("初始化时加载文件列表")
        
        // 连接后端信号
        backend.backupResultSignal.connect(handleBackupResult)
        backend.writeResultSignal.connect(handleWriteResult)
    }
} 