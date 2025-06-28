import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import QtGraphicalEffects 1.15

Item {
    id: flashFirmwarePage
    
    // 信号
    signal backRequested()
    
    // 属性
    property string selectedFilePath: ""
    property bool flashing: false
    property bool flashSuccessful: false
    
    // 顶部导航栏
    Rectangle {
        id: topBar
        height: 50
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: "#1A1A1A"
        z: 10  // 确保导航栏在最上层
        
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
                    if (!flashing) {
                        backRequested()
                    } else {
                        flashingWarningDialog.open()
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
            text: "BIOS固件刷写"
            color: "#FFFFFF"
            font.pixelSize: 20
            font.bold: true
        }
    }
    
    // 刷写过程中返回的警告对话框
    Dialog {
        id: flashingWarningDialog
        title: "警告"
        standardButtons: Dialog.Ok
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "BIOS刷写过程正在进行，请等待完成后再返回。中断刷写或断电会导致设备无法启动！"
            color: "#ff0000"
        }
    }
    
    // 主内容区域
    Flickable {
        id: contentFlickable
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: contentColumn.height + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        // 滚动条
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            active: true
            interactive: true
            
            contentItem: Rectangle {
                implicitWidth: 8
                radius: 4
                color: parent.pressed ? "#007ACC" : "#666666"
            }
        }
        
        // 主内容列
        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 20
            
            // 警告信息
            Rectangle {
                width: parent.width
                height: warningText.height + 30
                color: "#f6ff00"
                radius: 5
                
                Text {
                    id: warningText
                    anchors.centerIn: parent
                    width: parent.width - 30
                    wrapMode: Text.WordWrap
                    text: "警告：刷写固件是高风险操作！错误的固件或操作会导致设备无法启动。请确保选择正确的固件并在操作过程中不要关闭程序或断电。"
                    color: "#ff0000"
                    font.bold: true
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            // 文件选择区域
            Rectangle {
                width: parent.width
                height: 130
                color: "#252525"
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    Text {
                        text: "选择BIOS固件文件："
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: "#1A1A1A"
                        radius: 4
                        
                        Text {
                            id: filePathText
                            anchors.left: parent.left
                            anchors.right: browseButton.left
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 10
                            text: selectedFilePath === "" ? "未选择文件" : selectedFilePath
                            color: selectedFilePath === "" ? "#888888" : "#FFFFFF"
                            elide: Text.ElideMiddle
                            font.pixelSize: 14
                        }
                        
                        Rectangle {
                            id: browseButton
                            width: 80
                            height: 30
                            anchors.right: parent.right
                            anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 4
                            color: browseMouseArea.containsMouse ? "#0088FF" : "#007ACC"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "浏览..."
                                color: "#FFFFFF"
                                font.bold: true
                            }
                            
                            MouseArea {
                                id: browseMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!flashing) {
                                        fileDialog.open()
                                    }
                                }
                            }
                            
                            // 动画效果
                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }
                        }
                    }
                    
                    Text {
                        text: "支持的文件类型: .bin, .rom, .fd"
                        color: "#AAAAAA"
                        font.pixelSize: 12
                    }
                }
            }
            
            // 备份BIOS文件列表
            Rectangle {
                width: parent.width
                height: 200
                color: "#252525"
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    
                    Row {
                        spacing: 10
                        
                        Text {
                            text: "系统备份的BIOS文件："
                            color: "#FFFFFF"
                            font.pixelSize: 16
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: "#007ACC"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                anchors.centerIn: parent
                                text: "↻"
                                color: "#FFFFFF"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // 刷新备份文件列表
                                    backupFilesModel.clear()
                                    var extractedFiles = loadExtractedBiosFiles()
                                    for(var i = 0; i < extractedFiles.length; i++) {
                                        backupFilesModel.append(extractedFiles[i])
                                    }
                                }
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1A1A1A"
                        radius: 4
                        clip: true
                        
                        ListView {
                            id: backupFilesList
                            anchors.fill: parent
                            anchors.margins: 5
                            model: ListModel { id: backupFilesModel }
                            delegate: Rectangle {
                                width: backupFilesList.width
                                height: 40
                                color: backupFilesMA.containsMouse ? "#333333" : "transparent"
                                radius: 3
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10
                                    
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 3
                                        color: "#007ACC"
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "📂"
                                            color: "#FFFFFF"
                                            font.pixelSize: 14
                                        }
                                    }
                                    
                                    Text {
                                        text: model.name
                                        color: "#FFFFFF"
                                        font.pixelSize: 14
                                        width: parent.width - 140
                                        elide: Text.ElideMiddle
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Text {
                                        text: model.size
                                        color: "#AAAAAA"
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 70
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                                
                                MouseArea {
                                    id: backupFilesMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedFilePath = model.path
                                    }
                                }
                                
                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }
                            }
                            
                            ScrollBar.vertical: ScrollBar {}
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "没有找到备份的BIOS文件"
                            color: "#888888"
                            visible: backupFilesModel.count === 0
                        }
                    }
                    
                    // 组件加载时获取备份文件列表
                    Component.onCompleted: {
                        var extractedFiles = loadExtractedBiosFiles()
                        for(var i = 0; i < extractedFiles.length; i++) {
                            backupFilesModel.append(extractedFiles[i])
                        }
                    }
                }
            }
            
            // 选项区域
            Rectangle {
                width: parent.width
                height: 80
                color: "#252525"
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    
                    Text {
                        text: "刷写选项："
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    // 重启选项
                    CheckBox {
                        id: rebootCheckBox
                        text: "刷写完成后自动重启"
                        checked: true
                        
                        contentItem: Text {
                            text: rebootCheckBox.text
                            font.pixelSize: 14
                            color: "#FFFFFF"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: rebootCheckBox.indicator.width + 5
                        }
                    }
                }
            }
            
            // 命令预览区域
            Rectangle {
                width: parent.width
                height: 80
                color: "#252525"
                radius: 5
                visible: selectedFilePath !== ""
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8
                    
                    Text {
                        text: "将执行的命令："
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1A1A1A"
                        radius: 4
                        
                        Text {
                            anchors.fill: parent
                            anchors.margins: 10
                            text: selectedFilePath !== "" ? 
                                  "fptw64.exe -f \"" + (selectedFilePath.replace(/\//g, "\\")) + "\" -bios" : ""
                            color: "#00AAFF"
                            font.family: "Consolas"
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
            
            // 状态区域
            Rectangle {
                id: statusArea
                width: parent.width
                height: 50
                color: flashSuccessful ? "#005500" : (flashing ? "#555500" : "transparent")
                radius: 5
                visible: flashing || flashSuccessful
                
                Text {
                    anchors.centerIn: parent
                    text: flashSuccessful ? "BIOS刷写成功！" : "正在刷写BIOS，请勿关闭程序或断电..."
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 16
                }
                
                // 进度指示器
                Rectangle {
                    anchors.bottom: parent.bottom
                    height: 3
                    width: parent.width * flashProgress.progress
                    color: "#00AAFF"
                    visible: flashing && !flashSuccessful
                    
                    Behavior on width {
                        NumberAnimation { duration: 300 }
                    }
                }
                
                Timer {
                    id: flashProgress
                    property double progress: 0
                    interval: 500
                    running: flashing && !flashSuccessful
                    repeat: true
                    onTriggered: {
                        progress += 0.05
                        if (progress >= 1) {
                            stop()
                        }
                    }
                }
            }
            
            // 刷写按钮
            Rectangle {
                id: flashButton
                width: parent.width
                height: 60
                color: {
                    if (flashing) return "#555555"
                    if (selectedFilePath === "") return "#555555"
                    return flashMouseArea.containsMouse ? "#CC3300" : "#AA0000"
                }
                radius: 5
                
                Text {
                    anchors.centerIn: parent
                    text: flashing ? "正在刷写..." : "开始刷写固件"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 18
                }
                
                MouseArea {
                    id: flashMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (selectedFilePath !== "" && !flashing) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (selectedFilePath !== "" && !flashing) {
                            confirmFlashDialog.open()
                        }
                    }
                }
                
                // 动画效果
                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
            
            // 底部间距
            Item {
                width: parent.width
                height: 20
            }
        }
    }
    
    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: "选择BIOS固件文件"
        folder: shortcuts.home
        nameFilters: ["BIOS固件文件 (*.bin *.rom *.fd)", "所有文件 (*)"]
        selectExisting: true
        selectMultiple: false
        onAccepted: {
            selectedFilePath = fileDialog.fileUrl.toString().replace("file:///", "")
        }
    }
    
    // 确认刷写对话框
    Dialog {
        id: confirmFlashDialog
        title: "确认刷写"
        standardButtons: Dialog.Yes | Dialog.No
        modality: Qt.ApplicationModal
        
        Text {
            width: 400
            wrapMode: Text.WordWrap
            text: "您确定要刷写BIOS固件吗？\n\n" +
                  "固件文件: " + selectedFilePath.split('/').pop() + "\n\n" +
                  "执行命令: fptw64.exe -f " + selectedFilePath.split('/').pop() + " -bios\n\n" +
                  "警告：这是一个高风险操作，如果使用了错误的固件或在过程中断电，可能会导致设备无法启动！"
            color: "#000000"
        }
        
        onYes: {
            flashing = true
            flashProgress.progress = 0
            flashProgress.start()
            
            // 调用后端进行实际的刷写
            var params = {
                filePath: selectedFilePath,
                rebootAfter: rebootCheckBox.checked
            }
            
            backend.flashFirmware(JSON.stringify(params))
        }
    }
    
    // 后端回调函数，处理刷写结果
    function handleFlashResult(success, message) {
        flashing = false
        flashSuccessful = success
        
        if (success) {
            if (rebootCheckBox.checked) {
                rebootDialog.open()
            } else {
                flashSuccessDialog.message = message
                flashSuccessDialog.open()
            }
        } else {
            flashErrorDialog.message = message
            flashErrorDialog.open()
        }
    }
    
    // 刷写成功对话框
    Dialog {
        id: flashSuccessDialog
        property string message: ""
        title: "刷写成功"
        standardButtons: Dialog.Ok
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: flashSuccessDialog.message
            color: "#008800"
        }
    }
    
    // 刷写错误对话框
    Dialog {
        id: flashErrorDialog
        property string message: ""
        title: "刷写失败"
        standardButtons: Dialog.Ok
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: flashErrorDialog.message
            color: "#FF0000"
        }
    }
    
    // 重启确认对话框
    Dialog {
        id: rebootDialog
        title: "系统将重启"
        standardButtons: Dialog.Ok
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "BIOS刷写已完成，系统将在10秒内重启以应用更改。\n\n请保存好您的工作并关闭其他程序。"
            color: "#000000"
        }
        
        onAccepted: {
            // 倒计时将由后端处理
        }
    }
    
    // 获取提取的BIOS文件列表
    function loadExtractedBiosFiles() {
        var files = []
        var extractedFiles = backend.getExtractedBiosFiles()
        if (extractedFiles && extractedFiles.length > 0) {
            return extractedFiles
        }
        return files
    }
} 