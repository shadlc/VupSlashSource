import QtQuick 1.0

Item {
    id: root

    Rectangle {
        id: mask
        x: 0
        width: sceneWidth
        height: sceneHeight
        color: "black"
        opacity: 0
        z: -990
    }

    Rectangle {
        id: mask2
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
        width: sceneWidth
        height: 0
        color: "black"
        opacity: 0
        z: -500
    }

	Image {
		id: duel_spark
        property int currentImage: 0
		//width: 412
		rotation: 45
        source: "../image/animate/duel/" + currentImage + ".png"
		x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
		scale: 2.6
		z: 50
		opacity: 0
		
		NumberAnimation on currentImage {
			from: 0
			to: 24
			loops: Animation.Infinite
			duration: 600
		}
	}

	Image {
		id: player1
		source: "../image/generals/card/" + hero.split(":")[1].split("+")[0] + "." + hero.split(":")[2].split("+")[0]
		x: sceneWidth / 2 - width / 2 - 350
		y: sceneHeight / 2 - height / 2
		scale: 2
		rotation: 0
		opacity: 0
	}

    Image {
        id: player2
        source: "../image/generals/card/" + hero.split(":")[1].split("+")[1] + "." + hero.split(":")[2].split("+")[1]
        x: sceneWidth / 2 - width / 2 - 200
        y: sceneHeight / 2 - height / 2
        scale: 2
		rotation: 0
		opacity: 0
    }

    Image {
        id: player3
        source: "../image/generals/card/" + hero.split(":")[1].split("+")[2] + "." + hero.split(":")[2].split("+")[2]
        x: sceneWidth / 2 - width / 2 + 200
        y: sceneHeight / 2 - height / 2
        scale: 2
		rotation: 0
		opacity: 0
    }

    Image {
        id: player4
        source: "../image/generals/card/" + hero.split(":")[1].split("+")[3] + "." + hero.split(":")[2].split("+")[3]
        x: sceneWidth / 2 - width / 2 + 350
        y: sceneHeight / 2 - height / 2
        scale: 2
		rotation: 0
		opacity: 0
    }

	/*
    Image {
        id: ji
        source: "../image/animate/util/ji.png"
        opacity: 0
        scale: 3
        x: sceneWidth / 2 - width / 2 - 30
        y: sceneHeight / 2 - 240
    }

    Image {
        id: po
        source: "../image/animate/util/po.png"
        opacity: 0
        scale: 3
        x: sceneWidth / 2 - width / 2 + 25
        y: sceneHeight / 2 - 100
    }
	*/
	

    FontLoader {
        id: font
        source: "../font/simli.ttf"
    }

    Text {
        id: duel
        text: "对决"
        //width: 300
        wrapMode: Text.WordWrap
        font.family: font.name
        font.pixelSize: 200
        style: Text.Outline
        color: "#fff"
        opacity: 0
        x: sceneWidth / 2 - width / 2
        y: sceneHeight / 2 - height / 2
    }

    SequentialAnimation {
        id: anim
        running: false
        SequentialAnimation {
			PropertyAnimation {
				target: mask
				property: "opacity"
				to: 0.2
				duration: 500
				easing.type: Easing.InQuad
			}
			ParallelAnimation {
				PropertyAnimation {
					target: player1
					property: "scale"
					to: 0.6
					duration: 300
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player1
					property: "opacity"
					to: 1
					duration: 300
					easing.type: Easing.InQuad
				}
			}
			
			ParallelAnimation {
				PropertyAnimation {
					target: player2
					property: "scale"
					to: 0.6
					duration: 300
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player2
					property: "opacity"
					to: 1
					duration: 300
					easing.type: Easing.InQuad
				}
				ParallelAnimation {
					PropertyAnimation {
						target: mask2
						property: "opacity"
						to: 0.3
						duration: 500
						easing.type: Easing.InQuad
					}
					PropertyAnimation {
						target: mask2
						property: "height"
						to: 120
						duration: 500
						easing.type: Easing.InQuad
					}
				}
			}
			
			ParallelAnimation {
				PropertyAnimation {
					target: player3
					property: "scale"
					to: 0.6
					duration: 300
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player3
					property: "opacity"
					to: 1
					duration: 300
					easing.type: Easing.InQuad
				}
			}
			
			ParallelAnimation {
				PropertyAnimation {
					target: player4
					property: "scale"
					to: 0.6
					duration: 300
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player4
					property: "opacity"
					to: 1
					duration: 300
					easing.type: Easing.InQuad
				}
			}
			
            PauseAnimation {
                duration: 100
            }
			
			ParallelAnimation {
				PropertyAnimation {
					target: duel
					property: "scale"
					to: 0.6
					duration: 300
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: duel
					property: "opacity"
					to: 1
					duration: 300
					easing.type: Easing.InQuad
				}
			}
			
			ParallelAnimation {
				PropertyAnimation {
					target: duel_spark
					property: "opacity"
					to: 0.8
					duration: 100
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player1
					property: "scale"
					to: 0.75
					duration: 200
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player2
					property: "scale"
					to: 0.75
					duration: 200
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player3
					property: "scale"
					to: 0.75
					duration: 200
					easing.type: Easing.InQuad
				}
				PropertyAnimation {
					target: player4
					property: "scale"
					to: 0.75
					duration: 200
					easing.type: Easing.InQuad
				}
			}
			
            PauseAnimation {
                duration: 2200
            }
			
            PropertyAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 300
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
