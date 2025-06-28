import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root
    width: 220
    height: 140
    radius: 12
    color: cardColor
    scale: 1.0
    
    // 属性
    property string cardTitle: ""
    property string cardDescription: ""
    property string cardColor: "#1A1A1A"
    property bool enabled: true
    
    // 信号
    signal clicked()
    
    // 卡片阴影 - 放在最底层
    DropShadow {
        anchors.fill: parent
        horizontalOffset: 0
        verticalOffset: 3
        radius: 10.0
        samples: 15
        color: Qt.rgba(0, 0, 0, 0.4)
        source: parent
        z: -1
    }
    
    // 渐变背景 - 增加高级感
    Rectangle {
        id: gradientBg
        anchors.fill: parent
        radius: parent.radius
        z: 0  // 确保背景在底层
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.darker(cardColor, 1.2) }
            GradientStop { position: 1.0; color: cardColor }
        }
        
        // 光泽效果
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.15) }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }
        
        // 添加斜线装饰元素
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.lineWidth = 1;
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.1);
                
                // 绘制一条从右上到左下的斜线
                ctx.beginPath();
                ctx.moveTo(width * 0.6, 0);
                ctx.lineTo(width, height * 0.4);
                ctx.stroke();
                
                // 绘制一条从左下到右上的斜线
                ctx.beginPath();
                ctx.moveTo(0, height * 0.6);
                ctx.lineTo(width * 0.4, height);
                ctx.stroke();
            }
        }
    }
  
    Item {
        id: contentContainer
        anchors.fill: parent
        z: 10  
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4
            
            // 添加一些垂直空间，使内容更居中
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
            }
            
            // 卡片标题
            Text {
                id: titleText
                text: cardTitle
                color: "#FFFFFF"
                font.pixelSize: 22
                font.weight: Font.Black
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                opacity: root.enabled ? 1.0 : 0.5
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.2)  
                layer.enabled: true  
                layer.samples: 4     
            }
            
            // 卡片描述
            Text {
                id: descriptionText
                text: cardDescription
                color: "#FFFFFF"
                font.pixelSize: 14
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: root.enabled ? 1.0 : 0.3
                layer.enabled: true 
                layer.samples: 4     
            }
            
            // 添加一些垂直空间，使内容更居中
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
            }
        }
    }
    
    // 鼠标交互区域 - 放在最顶层以捕获所有事件
    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: 20  // 确保鼠标区域在最顶层
        
        onEntered: {
            if (root.enabled) {
                cardAnimation.to = 1.05
                cardAnimation.start()
            }
        }
        
        onExited: {
            if (root.enabled) {
                cardAnimation.to = 1.0
                cardAnimation.start()
            }
        }
        
        onPressed: {
            if (root.enabled) {
                cardAnimation.to = 0.95
                cardAnimation.start()
            }
        }
        
        onReleased: {
            if (root.enabled) {
                cardAnimation.to = containsMouse ? 1.05 : 1.0
                cardAnimation.start()
            }
        }
        
        onClicked: {
            if (root.enabled) {
                clickAnimation.start()
                root.clicked()
            }
        }
    }
    
    // 缩放动画
    PropertyAnimation {
        id: cardAnimation
        target: root
        property: "scale"
        duration: 150
        easing.type: Easing.OutQuad
    }
    
    // 点击特效
    SequentialAnimation {
        id: clickAnimation
        
        PropertyAnimation {
            target: gradientBg
            property: "opacity"
            from: 1.0
            to: 0.7
            duration: 100
        }
        
        PropertyAnimation {
            target: gradientBg
            property: "opacity"
            from: 0.7
            to: 1.0
            duration: 100
        }
    }
} 