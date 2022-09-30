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
		id: gif1
        source: "../image/animate/dna_summon.gif"
        playing: true
        asynchronous: true
        opacity: 1
		fillMode: Image.PreserveAspectCrop
        width: sceneWidth
        height: sceneHeight
		
    }

    AnimatedImage {
		id: gif2
        source: "../image/animate/dna_background.gif"
        playing: false
        asynchronous: true
        opacity: 0
		fillMode: Image.PreserveAspectCrop
        width: sceneWidth
        height: sceneHeight
		
    }

	Item {
		Image {
			id: character
			source: "../image/generals/card/" + hero.split(":")[1].split("+")[0] + ".png"
			x: sceneWidth / 2 - width / 2
			y: sceneHeight / 2 - height / 2
			scale: 2
			opacity: 0
		}
		Rectangle {
			id: character_mask
			color: "#FFFFFF"
			scale: 2
			opacity: 0
			anchors.fill: character
		}
	}
	Image {
		id: character_2
		source: "../image/generals/card/" + hero.split(":")[1].split("+")[0] + ".png"
		x: sceneWidth / 2 - width / 2
		y: sceneHeight / 2 - height / 2
		scale: 1.35
		opacity: 0
	}


    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: mask
                property: "opacity"
                to: 1
                duration: 300
                //easing.type: Easing.InQuad
            }
        }

		PauseAnimation {
			duration: 2550
		}
		
        PropertyAnimation {
            target: gif1
            property: "opacity"
            to: 0
            duration: 50
            easing.type: Easing.InQuad
        }
		
        ParallelAnimation {
			ScriptAction {
				script: {
					gif2.playing = true;
				}
			}
            PropertyAnimation {
                target: gif2
                property: "opacity"
                to: 1
                duration: 300
                easing.type: Easing.InQuad
            }
        }

        ParallelAnimation {
			PropertyAnimation {
				target: character
				property: "opacity"
				to: 1
				duration: 200
				easing.type: Easing.OutQuad
			}
			PropertyAnimation {
				target: character_mask
				property: "opacity"
				to: 1
				duration: 200
				easing.type: Easing.OutQuad
			}
		}
		
        ParallelAnimation {
			PropertyAnimation {
				target: character
				property: "scale"
				to: 1.35
				duration: 500
				easing.type: Easing.InQuad
			}
			PropertyAnimation {
				target: character_mask
				property: "scale"
				to: 1.35
				duration: 500
				easing.type: Easing.InQuad
			}
			PropertyAnimation {
				target: character_mask
				property: "opacity"
				to: 0
				duration: 500
				easing.type: Easing.InQuad
			}
        }

        ParallelAnimation {
			SequentialAnimation {
				PropertyAnimation {
					target: character_2
					property: "opacity"
					to: 1
					duration: 1
				}
				PropertyAnimation {
					target: character_2
					property: "opacity"
					to: 0
					duration: 199
					easing.type: Easing.OutQuad
				}
			}
			PropertyAnimation {
				target: character_2
				property: "scale"
				to: 1.8
				duration: 200
				easing.type: Easing.OutQuad
			}
        }

		PauseAnimation {
			duration: 1000
		}
		
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 600
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
