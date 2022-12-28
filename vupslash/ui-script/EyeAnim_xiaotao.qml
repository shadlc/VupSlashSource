import QtQuick 1.0

Item {
    id: root

    Rectangle {
        id: mask
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
        width: sceneWidth
        height: sceneHeight
        color: "#800000"
        opacity: 0
        z: -500
    }
	
	Image {
		id: eye
		opacity: 1
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
        z: 100
		fillMode: Image.PreserveAspectCrop
		clip: true
		width: 2000
		height: 0
		source: "../image/animate/xiaotao.png"
	}
	
	Image {
		id: eye2
		visible: false
		opacity: 0.5
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
        z: 110
		fillMode: Image.PreserveAspectCrop
		clip: true
		width: 2000
		height: 100
		scale: 1
		source: eye.source
	}
	
    Rectangle {
        id: line
        x: sceneWidth
        y: sceneHeight / 2 - height / 2
        width: sceneWidth
        height: 5
        color: "white"
        opacity: 1
        z: -400
    }
	
    AnimatedImage {
		id: speedline
        source: "../image/animate/util/speedline.gif"
        playing: true
        asynchronous: true
        opacity: 0
        width: sceneWidth
        height: sceneHeight
    }

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: mask
                property: "opacity"
                to: 0.3
                duration: 300
                easing.type: Easing.InQuad
            }
            PropertyAnimation {
                target: line
                property: "x"
                to: 0
                duration: 300
                easing.type: Easing.InQuad
            }
        }
        PropertyAnimation {
            target: line
            property: "opacity"
            to: 0.6
            duration: 200
        }

		PauseAnimation {
			duration: 100
		}
		
        ParallelAnimation {
            PropertyAnimation {
                target: speedline
                property: "opacity"
                to: 0.3
                duration: 300
                easing.type: Easing.InQuad
            }
			PropertyAnimation {
				target: eye
				property: "height"
				to: 100
				duration: 300
				easing.type: Easing.InQuad
			}
		}
		
        ParallelAnimation {
			ScriptAction {
				script: {
					line.visible = false
					eye2.visible = true
				}
			}
            PropertyAnimation {
                target: eye2
                property: "opacity"
                to: 0
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: eye2
                property: "scale"
                to: 2
                duration: 300
                easing.type: Easing.OutQuad
            }
        }
		
		PropertyAnimation {
			target: eye
			property: "height"
			to: 606
			duration: 500
			easing.type: Easing.OutQuad
		}
		
		PauseAnimation {
			duration: 400
		}
		
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 400
                easing.type: Easing.InQuad
            }
        }

        onCompleted: {
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        anim.start();
    }
}
