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
		id: coin2
		opacity: 0
		width: front_img2.width
		height: front_img2.height
		x: sceneWidth / 2 - width / 2 - 60
		y: sceneHeight / 2 - height / 2
		transform: Rotation{
			origin.x: front_img2.width/2
			origin.y: front_img2.height/2
			axis{
				x: 0
				y: 1    //设置围绕y轴旋转
				z: 0
			}
			NumberAnimation on angle{   //定义角度上的动画
				id: coin_rotate2
				from: 0
				to: 360*4 + 180*((hero.split(":")[1].split("+")[0]=="A")?2:1)
				duration: 1000
				running: false
				easing.type: Easing.OutQuad
				
			}
		}
		front:AnimatedImage{
			id: front_img2
			source: "../image/animate/Coin_front.png"
		}
		back:AnimatedImage{
			id: back_img2
			source: "../image/animate/Coin_back.png"
		}
	}

	Flipable {
		id: coin3
		opacity: 0
		width: front_img3.width
		height: front_img3.height
		x: sceneWidth / 2 - width / 2 + 60
		y: sceneHeight / 2 - height / 2
		transform: Rotation{
			origin.x: front_img3.width/2
			origin.y: front_img3.height/2
			axis{
				x: 0
				y: 1    //设置围绕y轴旋转
				z: 0
			}
			NumberAnimation on angle{   //定义角度上的动画
				id: coin_rotate3
				from: 0
				to: 360*4 + 180*((hero.split(":")[1].split("+")[1]=="A")?2:1)
				duration: 1000
				running: false
				easing.type: Easing.OutQuad
				
			}
		}
		front:AnimatedImage{
			id: front_img3
			source: "../image/animate/Coin_front.png"
		}
		back:AnimatedImage{
			id: back_img3
			source: "../image/animate/Coin_back.png"
		}
	}

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: coin2
                property: "opacity"
                to: 1
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: coin2
                property: "scale"
                to: 2
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: coin3
                property: "opacity"
                to: 1
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: coin3
                property: "scale"
                to: 2
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

    SequentialAnimation {
		id: throw_coin
		running: false
		ParallelAnimation {
			ParallelAnimation {
				ScriptAction {
					script: {
						coin_rotate2.start();
					}
				}
				SequentialAnimation {
					PropertyAnimation {
						target: coin2
						property: "y"
						to: coin2.y - 200
						duration: 400
						easing.type: Easing.OutQuad
					}
					PropertyAnimation {
						target: coin2
						property: "y"
						to: coin2.y
						duration: 400
						easing.type: Easing.InQuad
					}
				}
			}
			SequentialAnimation {
				PauseAnimation {
					duration: 200
				}
				ParallelAnimation {
					ScriptAction {
						script: {
							coin_rotate3.start();
						}
					}
					SequentialAnimation {
						PropertyAnimation {
							target: coin3
							property: "y"
							to: coin3.y - 200
							duration: 400
							easing.type: Easing.OutQuad
						}
						PropertyAnimation {
							target: coin3
							property: "y"
							to: coin3.y
							duration: 400
							easing.type: Easing.InQuad
						}
					}
				}
			}
		}
		PauseAnimation {
			duration: 200
		}
		
		onCompleted: {
			rotate_finished.start();
		}
	}
	
    SequentialAnimation {
        id: rotate_finished
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: coin2
                property: "scale"
                to: 2.5
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAnimation {
                target: coin3
                property: "scale"
                to: 2.5
                duration: 300
                easing.type: Easing.OutQuad
            }
        }
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
