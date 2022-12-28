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

    Rectangle {
        id: before_card
        opacity: 0
		scale: 1.8
		width: before_card_img.width
		height: before_card_img.height
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
		transform: Rotation{
			origin.x: before_card_img.width/2
			origin.y: before_card_img.height/2
			axis{
				x: 0
				y: 1    //设置围绕y轴旋转
				z: 0
			}
			NumberAnimation on angle{   //定义角度上的动画
				id: before_card_rotate
				from: 0
				to: 90
				duration: 250
				running: false
			
				onCompleted: {
					change_to_after.start();
				}
			}
		}
		AnimatedImage{
			id: before_card_img
			source: "../image/card/backcard.png"
		}
	}

    Rectangle {
        id: after_card
        visible: false
		width: after_card_img.width
		height: after_card_img.height
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
		transform: Rotation{
			origin.x: after_card_img.width/2
			origin.y: after_card_img.height/2
			axis{
				x: 0
				y: 1    //设置围绕y轴旋转
				z: 0
			}
			NumberAnimation on angle{   //定义角度上的动画
				id: after_card_rotate
				from: 270
				to: 360
				duration: 250
				running: false
				
				onCompleted: {
					pause2.start();
				}
			}
		}
		AnimatedImage{		//卡图
			id: after_card_img
			source: "../image/card/" + hero.split(":")[1].split("+")[0] + ".png"
		}
		AnimatedImage{		//点数（根据花色取黑/红）
			x: -2
			y: -1
			source: (hero.split(":")[1].split("+")[1] == "spade" || hero.split(":")[1].split("+")[1] == "club") ? "../image/system/black/" + hero.split(":")[1].split("+")[2] + ".png" : "../image/system/red/" + hero.split(":")[1].split("+")[2] + ".png"
		}
		AnimatedImage{		//花色
			x: 1
			y: 17
			source: "../image/system/cardsuit/" + hero.split(":")[1].split("+")[1] + ".png"
		}
		AnimatedImage {		//弹孔
			id: bullet_hit
			visible: false
			width: 25
			height: 25
			x: after_card_img.width/2 - width/2 + ((Math.random()-0.5)*2*20)
			y: after_card_img.height/2 - height/2 + ((Math.random()-0.5)*2*20)
			source: "../image/animate/bullet_hit.png"
		}
	}

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: before_card
                property: "opacity"
                to: 1
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: before_card
                property: "scale"
                to: 1
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
            before_card_rotate.start();
        }
    }

    PauseAnimation {
        id: pause2
        duration: 100
        running: false

        onCompleted: {
            shoot.start()
        }
    }

    PauseAnimation {
        id: pause3
        duration: 150
        running: false

        onCompleted: {
            fade.start();
        }
    }

    ScriptAction {
		id: change_to_after
        running: false
        script: {
            after_card.visible = true
            after_card_rotate.start()
        }
    }
	
    SequentialAnimation {
        id: shoot
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: after_card
                property: "scale"
                to: 0.9
                duration: 20
            }
			ScriptAction {
				script: {
					bullet_hit.visible = true
				}
			}
        }
        ParallelAnimation {
            PropertyAnimation {
                target: after_card
                property: "scale"
                to: 1
                duration: 130
                easing.type: Easing.OutQuad
            }
        }
		
        onCompleted: {
            pause3.start();
        }
    }

    SequentialAnimation {
        id: fade
        running: false
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 200
            easing.type: Easing.InQuad
        }
		
        onCompleted: {
            container.animationCompleted()
        }
    }

    Component.onCompleted: {
        anim.start();
    }
}
