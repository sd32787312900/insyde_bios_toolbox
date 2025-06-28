import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import QtGraphicalEffects 1.15

Item {
    id: extractFirmwarePage
    
    // 信号
    signal backRequested()
    
    // 属性
    property string selectedFirmwareFile: ""
    property bool isExtracting: false
    property bool extractionSuccessful: false
    property var extractedFiles: []
    property string selectedFilePath: ""
    
    // 处理提取结果
    function handleExtractResult(success, message, files) {
        extractFirmwarePage.isExtracting = false
        extractFirmwarePage.extractionSuccessful = success
        
        if (success) {
            extractFirmwarePage.extractedFiles = files
            console.log("BIOS固件提取成功，获取到文件列表")
            
            // 更新ListModel
            extractedFilesModel.clear()
            for(var i = 0; i < files.length; i++) {
                extractedFilesModel.append(files[i])
            }
        } else {
            errorDialog.message = message
            errorDialog.open()
        }
    }
    
    // 组件加载时自动加载BIOS备份文件
    Component.onCompleted: {
        // 连接后端信号
        backend.extractResultSignal.connect(handleExtractResult)
        // 加载现有BIOS备份
        loadBiosBackups()
    }
    
    // 加载BIOS备份文件
    function loadBiosBackups() {
        var files = backend.getExtractedBiosFiles()
        if(files && files.length > 0) {
            extractFirmwarePage.extractedFiles = files
            extractFirmwarePage.extractionSuccessful = true
            
            // 更新ListModel
            extractedFilesModel.clear()
            for(var i = 0; i < files.length; i++) {
                extractedFilesModel.append(files[i])
            }
        }
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
                    if (!isExtracting) {
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
            text: "BIOS固件提取与解析"
            color: "#FFFFFF"
            font.pixelSize: 20
            font.bold: true
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
            text: "正在进行BIOS固件提取操作，请等待完成后再返回。中断操作可能会导致数据损坏！"
            color: "#ff0000"
        }
    }
    
    // 错误对话框
    Dialog {
        id: errorDialog
        title: "操作失败"
        standardButtons: Dialog.Ok
        property string message: ""
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: errorDialog.message
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
        anchors.bottomMargin: 0 
        color: "transparent"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            // 主操作区
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                color: "#252525"
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    
                    Text {
                        text: "选择BIOS固件文件或直接提取当前系统BIOS"
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    // 文件选择区域
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: "#1E1E1E"
                            border.color: "#444444"
                            border.width: 1
                            radius: 3
                            
                            TextInput {
                                id: filePathInput
                                anchors.fill: parent
                                anchors.margins: 8
                                verticalAlignment: Text.AlignVCenter
                                color: "#FFFFFF"
                                readOnly: true
                                text: extractFirmwarePage.selectedFirmwareFile
                                clip: true
                                font.pixelSize: 14
                                
                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    color: "#888888"
                                    font.pixelSize: 14
                                    text: "请选择BIOS固件文件..."
                                    visible: filePathInput.text.length === 0
                                }
                            }
                        }
                        
                        Button {
                            text: "浏览..."
                            height: 40
                            onClicked: {
                                fileDialog.open()
                            }
                            
                            background: Rectangle {
                                radius: 3
                                color: parent.pressed ? "#0055A5" : (parent.hovered ? "#006FD6" : "#0078D7")
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    
                    // 操作按钮区域
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15
                        
                        Button {
                            text: "提取系统BIOS"
                            Layout.preferredWidth: 180
                            height: 45
                            enabled: !isExtracting
                            
                            background: Rectangle {
                                radius: 3
                                color: parent.enabled ? (parent.pressed ? "#4B21A6" : (parent.hovered ? "#5E34B0" : "#5B21B6")) : "#444444"
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: {
                                extractFirmwarePage.isExtracting = true
                                extractFirmwarePage.selectedFirmwareFile = ""
                                backend.extractSystemBios()
                            }
                        }
                        
                        Button {
                            text: "解析BIOS文件"
                            Layout.preferredWidth: 180
                            height: 45
                            enabled: !isExtracting && extractFirmwarePage.selectedFirmwareFile !== ""
                            
                            background: Rectangle {
                                radius: 3
                                color: parent.enabled ? (parent.pressed ? "#0055A5" : (parent.hovered ? "#006FD6" : "#0078D7")) : "#444444"
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: {
                                extractFirmwarePage.isExtracting = true
                                backend.extractBiosFile(extractFirmwarePage.selectedFirmwareFile)
                            }
                        }
                    }
                }
            }
            
            // 提取结果区域
            Rectangle {
                id: resultArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#252525"
                radius: 5
                border.color: "#444444"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8
                    
                    // 顶部标题和刷新按钮
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        
                        Text {
                            text: isExtracting ? "正在提取BIOS..." : (extractedFiles.length > 0 ? "提取的文件:" : "尚无提取文件")
                            color: "#FFFFFF"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        
                        // 刷新按钮
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: refreshMouseArea.containsMouse ? "#0088FF" : "#007ACC"
                            visible: !isExtracting
                            
                            Text {
                                anchors.centerIn: parent
                                text: "↻"
                                color: "#FFFFFF"
                                font.bold: true
                                font.pixelSize: 18
                            }
                            
                            MouseArea {
                                id: refreshMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    loadBiosBackups()
                                }
                            }
                            
                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }
                        }
                    }
                    
                    // 文件列表容器
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1A1A1A"
                        radius: 4
                        clip: true
                        
                        // 文件列表 - 如果有文件则显示
                        ListView {
                            id: fileListView
                            anchors.fill: parent
                            anchors.margins: 5
                            model: ListModel { id: extractedFilesModel }
                            visible: extractedFiles.length > 0 && !isExtracting
                            spacing: 5
                            clip: true
                            
                            // 滚动条设置
                            ScrollBar.vertical: ScrollBar { 
                                active: true
                                policy: ScrollBar.AsNeeded
                                anchors.right: fileListView.right
                                anchors.rightMargin: 1
                            }
                            
                            delegate: Rectangle {
                                width: fileListView.width
                                height: 60
                                color: fileMouseArea.containsMouse ? "#333333" : "transparent"
                                radius: 3
                                
                                // 定义鼠标区域
                                MouseArea {
                                    id: fileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedFilePath = model.path
                                    }
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 3
                                        color: "#007ACC"
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "📄"
                                            color: "#FFFFFF"
                                            font.pixelSize: 14
                                        }
                                    }
                                    
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        
                                        Text {
                                            text: model.name
                                            color: "#FFFFFF"
                                            font.pixelSize: 14
                                            width: parent.width
                                            elide: Text.ElideMiddle
                                        }
                                        
                                        Text {
                                            text: model.size + (model.time ? " | " + model.time : "")
                                            color: "#AAAAAA"
                                            font.pixelSize: 12
                                        }
                                    }
                                    
                                    // 文件操作按钮
                                    Row {
                                        spacing: 5
                                        
                                        Button {
                                            text: "打开位置"
                                            width: 80
                                            height: 30
                                            
                                            background: Rectangle {
                                                radius: 3
                                                color: parent.pressed ? "#333333" : (parent.hovered ? "#444444" : "#383838")
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                color: "#FFFFFF"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                backend.openFileLocation(model.path)
                                            }
                                        }
                                        
                                        Button {
                                            text: "重命名"
                                            width: 70
                                            height: 30
                                            
                                            background: Rectangle {
                                                radius: 3
                                                color: parent.pressed ? "#333333" : (parent.hovered ? "#444444" : "#383838")
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                color: "#FFFFFF"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                renameDialog.fileName = model.name
                                                renameDialog.filePath = model.path
                                                renameDialog.open()
                                            }
                                        }
                                        
                                        Button {
                                            text: "删除"
                                            width: 60
                                            height: 30
                                            
                                            background: Rectangle {
                                                radius: 3
                                                color: parent.pressed ? "#993333" : (parent.hovered ? "#AA4444" : "#883333")
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                color: "#FFFFFF"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                deleteConfirmDialog.fileName = model.path.split('/').pop()
                                                deleteConfirmDialog.filePath = model.path
                                                deleteConfirmDialog.open()
                                            }
                                        }
                                    }
                                }
                                
                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }
                            }
                        }
                        
                        // 空状态提示 - 仅在无文件且不在提取时显示
                        Text {
                            anchors.centerIn: parent
                            text: "尚未提取任何BIOS数据"
                            color: "#888888"
                            visible: extractedFiles.length === 0 && !isExtracting
                        }
                        
                        // 进度指示器 - 仅在提取时显示
                        Column {
                            anchors.centerIn: parent
                            spacing: 15
                            visible: isExtracting
                            
                            BusyIndicator {
                                running: isExtracting
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 40
                                height: 40
                                
                                contentItem: Item {
                                    implicitWidth: 40
                                    implicitHeight: 40
                                    
                                    RotationAnimator {
                                        target: rotatingItem
                                        from: 0
                                        to: 360
                                        duration: 1500
                                        loops: Animation.Infinite
                                        running: isExtracting
                                    }
                                    
                                    Rectangle {
                                        id: rotatingItem
                                        width: parent.width
                                        height: parent.height
                                        radius: width / 2
                                        border.width: 3
                                        border.color: "#0078D7"
                                        color: "transparent"
                                    }
                                }
                            }
                            
                            Text {
                                text: "正在提取BIOS固件，请稍候..."
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                    
                    // 文件上下文菜单
                    Menu {
                        id: fileContextMenu
                        
                        property string filePath: ""
                        
                        MenuItem {
                            text: "打开文件位置"
                            onTriggered: {
                                backend.openFileLocation(selectedFilePath)
                            }
                        }
                        
                        MenuItem {
                            text: "重命名文件"
                            onTriggered: {
                                renameDialog.fileName = selectedFilePath.split('/').pop().split('\\').pop()
                                renameDialog.filePath = selectedFilePath
                                renameDialog.open()
                            }
                        }
                        
                        MenuItem {
                            text: "删除文件"
                            onTriggered: {
                                deleteConfirmDialog.fileName = selectedFilePath.split('/').pop()
                                deleteConfirmDialog.filePath = selectedFilePath
                                deleteConfirmDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: "选择BIOS固件文件"
        nameFilters: ["BIOS固件文件 (*.bin *.rom *.fd)", "所有文件 (*)"]
        selectExisting: true
        onAccepted: {
            extractFirmwarePage.selectedFirmwareFile = fileDialog.fileUrl.toString().replace("file:///", "")
        }
    }

    // 重命名对话框
    Dialog {
        id: renameDialog
        title: "重命名文件"
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        property string fileName: ""
        property string filePath: ""
        property string fileDir: ""
        
        // 对话框打开时初始化
        onVisibleChanged: {
            if (visible) {
                // 确保只显示文件名，不包含路径
                fileDir = filePath.substring(0, Math.max(filePath.lastIndexOf('/'), filePath.lastIndexOf('\\')) + 1)
                
                // 处理Windows路径分隔符
                var baseName = fileName
                if (!baseName) {
                    baseName = filePath.split('/').pop().split('\\').pop()
                }
                
                // 如果文件名包含.bin扩展名，则去掉扩展名
                if (baseName.toLowerCase().endsWith('.bin')) {
                    baseName = baseName.substring(0, baseName.length - 4)
                }
                
                fileName = baseName
                newNameField.text = baseName
            }
        }
        
        ColumnLayout {
            spacing: 10
            width: parent.width
            
            Text {
                text: "请输入新文件名:"
                Layout.fillWidth: true
            }
            
            TextField {
                id: newNameField
                Layout.fillWidth: true
                selectByMouse: true
                
                // 限制文件名中的非法字符
                validator: RegExpValidator {
                    regExp: /[^\\/:*?"<>|]+/
                }
            }
        }
        
        onAccepted: {
            if(newNameField.text.trim() !== "") {
                // 确保新文件名有.bin扩展名
                var newName = newNameField.text.trim()
                if (!newName.toLowerCase().endsWith('.bin')) {
                    newName += '.bin'
                }
                
                console.log("重命名文件: " + renameDialog.filePath + " -> " + newName)
                
                if(backend.renameBiosFile(renameDialog.filePath, newName)) {
                    // 成功重命名后刷新列表
                    loadBiosBackups()
                } else {
                    errorDialog.message = "重命名失败，可能文件被占用或已存在同名文件"
                    errorDialog.open()
                }
            }
        }
    }
    
    // 删除确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: "确认删除"
        standardButtons: Dialog.Yes | Dialog.No
        
        property string fileName: ""
        property string filePath: ""
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "您确定要删除文件 \"" + deleteConfirmDialog.fileName + "\" 吗？\n此操作不可恢复。"
        }
        
        onYes: {
            if(backend.deleteBiosFile(deleteConfirmDialog.filePath)) {
                // 成功删除后刷新列表
                loadBiosBackups()
            } else {
                errorDialog.message = "删除失败，可能文件被占用"
                errorDialog.open()
            }
        }
    }
}