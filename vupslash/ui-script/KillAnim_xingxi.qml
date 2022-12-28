import QtQuick 1.0

Item {
    id: root

    AnimatedImage {
        source: "../image/animate/util/speedline.gif"
        playing: true
        asynchronous: true
        opacity: 0.3
        width: sceneWidth
        height: sceneHeight
    }

    Item {
        Image {
            id: victim
            source: "../image/generals/card/" + hero.split(":")[1].split("+")[1] + "." + hero.split(":")[2].split("+")[1]
            //x: sceneWidth / 2 + 150
            //y: sceneHeight + 100
            x: -200
            y: sceneHeight / 2 - height / 2
			rotation: 10
        }

        Rectangle {
            id: mask
            color: "#800080"
            opacity: 0
            anchors.fill: victim
			rotation: 10
        }

        Image {
            id: damageEmotion
            property int current: 0
            scale: 1.5
            anchors.centerIn: victim
            source: "../image/system/emotion/meteorite/" + current + ".png"
            visible: false
            NumberAnimation on current {
                id: emotion
                from: 0
                to: 8
                duration: 800
                running: false
            }
        }
    }

    AnimatedImage {
        id: killer
        source: "../image/animate/山猪.gif"
        playing: true
        asynchronous: true
        x: sceneWidth + 200
        y: sceneHeight / 2 - height / 2
        scale: 1.4
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
        id: kf
        source: "../font/kill_font.ttf"
    }

    Text {
        id: ji
        text: "华丽"
        //width: 300
        wrapMode: Text.WordWrap
        font.family: kf.name
        font.pixelSize: 320
        style: Text.Outline
        color: "#EE82EE"
        opacity: 0
        x: sceneWidth / 2 - width / 2 - 10
        y: sceneHeight / 2 - 240
    }

    Text {
        id: po
        text: "击败"
        //width: 300
        wrapMode: Text.WordWrap
        font.family: kf.name
        font.pixelSize: 320
        style: Text.Outline
        color: "#EE82EE"
        opacity: 0
        x: sceneWidth / 2 - width / 2 + 55
        y: sceneHeight / 2 - 100
    }

    FontLoader {
        id: simli
        source: "../font/simli.ttf"
    }

    Text {
        id: lastword
        text: skill
        width: victim.width * 2.8
        wrapMode: Text.WordWrap
        font.family: simli.name
        font.pixelSize: 44
        style: Text.Outline
        color: "white"
        opacity: 0
        x: victim.x - victim.width * 0.2
        y: victim.y + victim.height * 0.75
    }

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            PropertyAnimation {
                target: killer
                property: "x"
                to: sceneWidth / 2 - killer.width / 2 - 200
                duration: 300
                easing.type: Easing.InQuad
            }
            PropertyAnimation {
                target: victim
                property: "x"
                to: sceneWidth / 2 - victim.width / 2 + 160
                duration: 300
                easing.type: Easing.InQuad
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: killer
                property: "x"
                to: sceneWidth / 2 - killer.width / 2 - 240
                duration: 2640
            }
            PropertyAnimation {
                target: victim
                property: "x"
                to: sceneWidth / 2 - victim.width / 2 + 190
                duration: 2640
            }

            ParallelAnimation {
                PauseAnimation {
                    duration: 500
                }
                PropertyAnimation {
                    target: mask
                    property: "opacity"
                    to: 0.7
                    duration: 200
                    easing.type: Easing.InQuad
                }
                PropertyAnimation {
                    target: victim
                    property: "opacity"
                    to: 0.7
                    duration: 200
                    easing.type: Easing.InQuad
                }
                PropertyAnimation {
                    target: lastword
                    property: "opacity"
                    to: 1
                    duration: 200
                    easing.type: Easing.InQuad
                }
                ScriptAction {
                    script: {
                        damageEmotion.visible = true
                        emotion.start()
                    }
                }
                SequentialAnimation {
                    PauseAnimation {
                        duration: 140
                    }
                    ParallelAnimation {
                        PropertyAnimation {
                            target: ji
                            property: "opacity"
                            to: 0.8
                            duration: 300
                            easing.type: Easing.InQuad
                        }
                        PropertyAnimation {
                            target: ji
                            property: "scale"
                            to: 0.5
                            duration: 300
                            easing.type: Easing.InQuad
                        }
                        SequentialAnimation {
                            PauseAnimation {
                                duration: 200
                            }
                            ParallelAnimation {
                                PropertyAnimation {
                                    target: po
                                    property: "opacity"
                                    to: 0.8
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                                PropertyAnimation {
                                    target: po
                                    property: "scale"
                                    to: 0.5
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                            }
                            PropertyAnimation {
                                target: victim
                                property: "opacity"
                                to: 0.33
                                duration: 1200
                            }
                            /*PauseAnimation {
                                duration: 1200
                            }*/
                            PropertyAnimation {
                                target: root
                                property: "opacity"
                                to: 0
                                duration: 300
                            }
                        }
                    }
                }
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
