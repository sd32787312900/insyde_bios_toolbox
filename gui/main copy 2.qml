import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "."

Window {
    id: mainWindow
    width: 1000
    height: 650
    visible: true
    title: "Insyde BIOS 工具箱"
    color: "#121212"
    
    // 恢复正常的窗口模式，保留标题栏
    // 禁止窗口调整大小
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    
    // 设置窗口居中
    Screen.onWidthChanged: x = Screen.width / 2 - width / 2
    Screen.onHeightChanged: y = Screen.height / 2 - height / 2
    
    // 页面堆栈
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainMenuPage
    }
    
    // 主菜单页面组件
    Component {
        id: mainMenuPage
        
        Item {
            width: stackView.width
            height: stackView.height
            
            // 标题区域
            Rectangle {
                id: headerArea
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 100
                color: "transparent"
                
                Text {
                    id: mainTitle
                    text: "Insyde BIOS 工具箱"
                    color: "#FFFFFF"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    anchors.centerIn: parent
                }
                
                // 标题下的蓝色条
                Rectangle {
                    width: mainTitle.width * 0.6
                    height: 3
                    radius: 1.5
                    color: "#0078D7"
                    anchors.top: mainTitle.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: mainTitle.horizontalCenter
                }
            }
            
            // 副标题
            Text {
                id: subTitle
                text: "请选择一个功能开始"
                color: "#AAAAAA"
                font.pixelSize: 16
                anchors.top: headerArea.bottom
                anchors.topMargin: -15
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // 卡片容器
            Item {
                id: cardsContainer
                anchors.top: subTitle.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: copyrightText.top
                anchors.bottomMargin: 20
                
                // 卡片网格布局
                GridLayout {
                    id: cardsGrid
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 60, 700)
                    
                    columns: 3
                    rows: 2
                    columnSpacing: 15
                    rowSpacing: 15
                    
                    // BIOS固件提取卡片
                    CardItem {
                        id: extractFirmwareCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        cardTitle: "BIOS固件提取"
                        cardDescription: "从系统中提取BIOS固件"
                        cardColor: "#1E3A8A"
                        
                        onClicked: {
                            backend.handle_menu_item_clicked("extract_firmware")
                            extractFirmwarePage.active = true
                            
                            // 确保页面已加载
                            if (extractFirmwarePage.status === Loader.Ready) {
                                stackView.push(extractFirmwarePage.item)
                            } else {
                                extractFirmwarePage.onLoaded.connect(function() {
                                    stackView.push(extractFirmwarePage.item)
                                })
                            }
                        }
                    }
                    
                    // BIOS配置备份卡片
                    CardItem {
                        id: backupFirmwareCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        cardTitle: "BIOS配置备份"
                        cardDescription: "备份当前BIOS配置和设置"
                        cardColor: "#3730A3"
                        
                        onClicked: {
                            backend.handle_menu_item_clicked("backup_firmware")
                            backupConfigPage.active = true
                            
                            // 确保页面已加载
                            if (backupConfigPage.status === Loader.Ready) {
                                stackView.push(backupConfigPage.item)
                            } else {
                                backupConfigPage.onLoaded.connect(function() {
                                    stackView.push(backupConfigPage.item)
                                })
                            }
                        }
                    }
                    
                    // BIOS固件刷写卡片
                    CardItem {
                        id: flashFirmwareCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        cardTitle: "BIOS固件刷写"
                        cardDescription: "将BIOS固件刷写到系统"
                        cardColor: "#5B21B6"
                        
                        onClicked: {
                            backend.handle_menu_item_clicked("flash_firmware")
                            flashFirmwarePage.active = true
                            
                            // 确保页面已加载
                            if (flashFirmwarePage.status === Loader.Ready) {
                                stackView.push(flashFirmwarePage.item)
                            } else {
                                flashFirmwarePage.onLoaded.connect(function() {
                                    stackView.push(flashFirmwarePage.item)
                                })
                            }
                        }
                    }
                    
                    // H2OUVE编辑器卡片
                    CardItem {
                        id: h2ouveEditorCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        cardTitle: "H2OUVE编辑器"
                        cardDescription: "使用H2OUVE工具编辑BIOS设置"
                        cardColor: "#0E7490"
                        
                        onClicked: {
                            backend.handle_menu_item_clicked("h2ouve_editor")
                        }
                    }
                    
                    // H2OEZE编辑器卡片
                    CardItem {
                        id: h2oezeEditorCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        cardTitle: "H2OEZE编辑器"
                        cardDescription: "使用H2OEZE工具编辑BIOS设置"
                        cardColor: "#0369A1"
                        
                        onClicked: {
                            backend.handle_menu_item_clicked("h2oeze_editor")
                        }
                    }
                    
                    // 预留功能卡片
                    CardItem {
                        id: reservedCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        cardTitle: "更多功能"
                        cardDescription: "即将推出更多实用工具"
                        cardColor: "#404040"
                        enabled: false
                        
                        onClicked: {
                            backend.handle_menu_item_clicked("reserved")
                        }
                    }
                }
            }
            
            // 版权信息
            Text {
                id: copyrightText
                text: "© 2025 Insyde BIOS 工具箱@余生的客栈"
                color: "#666666"
                font.pixelSize: 11
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // BIOS固件提取页面
    Loader {
        id: extractFirmwarePage
        source: "ExtractFirmwarePage.qml"
        active: false
        asynchronous: true
        
        onLoaded: {
            item.width = stackView.width
            item.height = stackView.height
            
            // 连接信号
            item.backRequested.connect(function() {
                stackView.pop()
            })
        }
    }
    
    // BIOS固件刷写页面
    Loader {
        id: flashFirmwarePage
        source: "FlashFirmwarePage.qml"
        active: false
        asynchronous: true
        
        onLoaded: {
            item.width = stackView.width
            item.height = stackView.height
            
            // 连接信号
            item.backRequested.connect(function() {
                stackView.pop()
            })
        }
    }
    
    // BIOS配置备份页面
    Loader {
        id: backupConfigPage
        source: "BackupConfigPage.qml"
        active: false
        asynchronous: true
        
        onLoaded: {
            item.width = stackView.width
            item.height = stackView.height
            
            // 连接信号
            item.backRequested.connect(function() {
                stackView.pop()
            })
        }
    }
} 