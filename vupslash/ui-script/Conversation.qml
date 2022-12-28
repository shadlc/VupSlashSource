import QtQuick 1.0

Rectangle {
    id: root
    property alias text: text.rawText
    property string general: "caocao"
    x: -sceneWidth
    y: sceneHeight - 270
    opacity: 0

    FontLoader {
        id: textfont
        source: "../font/simli.ttf"
    }

    Image {
        id: bg
        height: 270
        //anchors.left: avatar.right
        width: sceneWidth
        source: "../image/animate/dialog.png"

        Text {
            id: text
            property string rawText: skill.split("+")[1]
            property int currentIndex: 0
            color: "white"
            text: rawText.substr(0, currentIndex)
            font.family: textfont.name
            style: Text.Outline
            font.pointSize: 36
            wrapMode: Text.WordWrap
            anchors.fill: parent
            anchors.topMargin: 100
            anchors.leftMargin: 40
            anchors.bottomMargin: 16
            anchors.rightMargin: 36

            NumberAnimation on currentIndex {
                id: printer
                to: text.rawText.length
                duration: 80 * text.rawText.length
                running: false

                onCompleted: {
                    pause.start();
                }
            }
        }
		
        Text {
            id: name
            color: "white"
            text: skill.split("+")[0]
            font.family: textfont.name
            style: Text.Outline
            font.pointSize: 30
            //wrapMode: Text.WordWrap
			elide: Text.ElideRight
            anchors.fill: parent
            anchors.topMargin: 0
            anchors.leftMargin: 65
            anchors.bottomMargin: 210
            anchors.rightMargin: 36
        }
    }

    ParallelAnimation {
        id: appearAnim
        running: false
		PropertyAnimation {
            target: root
            property: "x"
			to: 0
			duration: 300
			easing.type: Easing.OutQuad
		}
		PropertyAnimation {
            target: root
            property: "opacity"
			to: 100
			duration: 300
			easing.type: Easing.OutQuad
		}
		onCompleted: {
			printer.start();
		}
	}

    PauseAnimation {
        id: pause
        duration: 1200
        running: false

        onCompleted: {
            disappearAnim.start();
        }
    }

    ParallelAnimation {
        id: disappearAnim
        running: false
		PropertyAnimation {
            target: root
            property: "x"
			to: sceneWidth
			running: false
			duration: 300
			easing.type: Easing.InQuad
		}
		PropertyAnimation {
            target: root
            property: "opacity"
			to: 0
			duration: 300
			easing.type: Easing.OutQuad
		}
		onCompleted: {
			container.animationCompleted();
		}
	}

    Component.onCompleted: { appearAnim.start();}
}