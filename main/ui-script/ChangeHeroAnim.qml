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
	
	Flipable {
		id: coin
		opacity: 0
		width: front_img.width
		height: front_img.height
		x: sceneWidth / 2 - width / 2
		y: sceneHeight / 2 - height / 2
		transform: Rotation{
			origin.x: front_img.width/2
			origin.y: front_img.height/2
			axis{
				x: 0
				y: 1    //设置围绕y轴旋转
				z: 0
			}
			NumberAnimation on angle{   //定义角度上的动画
				id: coin_rotate
				from: 0
				to: 180
				duration: 800
				running: false
				easing.type: Easing.OutQuad
				
				onCompleted: {
					rotate_finished.start();
				}
			}
		}
		front:AnimatedImage{
			id: front_img
			source: "../image/generals/card/" + hero.split(":")[1].split("+")[0] + ".png"
		}
		back:AnimatedImage{
			id: back_img
			source: "../image/generals/card/" + hero.split(":")[1].split("+")[1] + ".png"
		}
	}

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: coin
                property: "opacity"
                to: 1
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: coin
                property: "scale"
                to: 1.5
                duration: 300
                easing.type: Easing.OutQuad
            }
			PropertyAnimation {
				target: mask
				property: "opacity"
				to: 0.25
				duration: 300
				easing.type: Easing.InQuad
			}
        }
		
        onCompleted: {
            pause.start();
        }
    }

    PauseAnimation {
        id: pause
        duration: 200
        running: false

        onCompleted: {
            throw_coin.start();
        }
    }

	ParallelAnimation {
		id: throw_coin
		running: false
		ScriptAction {
			script: {
				coin_rotate.start();
			}
		}
		SequentialAnimation {
			PropertyAnimation {
				target: coin
				property: "scale"
				to: 1.875
				duration: 400
				easing.type: Easing.OutQuad
			}
			PropertyAnimation {
				target: coin
				property: "scale"
				to: 1.5
				duration: 400
				easing.type: Easing.InQuad
			}
		}
	}
	
    SequentialAnimation {
        id: rotate_finished
        running: false
		
		PauseAnimation {
			duration: 200
		}

        onCompleted: {
            fade.start();
        }
    }
	
    PropertyAnimation {
		id: fade
        target: root
        property: "opacity"
        to: 0
        duration: 100
		
        onCompleted: {
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        anim.start();
    }
}
