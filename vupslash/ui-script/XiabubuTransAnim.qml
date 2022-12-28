import QtQuick 1.0

Item {
    id: root

    Rectangle {
        id: mask
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
        width: sceneWidth
        height: sceneHeight
        color: "black"
        opacity: 0
        z: -500
    }

    AnimatedImage {
		id: the_gif
        source: "../image/animate/xiabubu.gif"
        playing: true
        asynchronous: true
        opacity: 1
		fillMode: Image.PreserveAspectCrop
        width: sceneWidth
        height: sceneHeight
		
    }

    SequentialAnimation {
        id: anim
        running: false

		PauseAnimation {
			id: pause
			duration: 4000
			running: false
		}
		
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 300
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
