/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.0
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12
import QtQml.Models 2.15
import org.kde.mauikit 1.0 as Maui
import org.kde.kirigami 2.15 as Kirigami
import jingos.display 1.0

Rectangle {
    id: playBarFooter

    property alias progressBar: progressBar
    property Action playPauseAction: Action {
        id: playPauseAction
        text: qsTr("Play/Pause")
        icon.name: "media-playback-pause"
        shortcut: "Space"
        enabled:  playBarFooter.visible

        onTriggered: {
            if(playBarFooter.visible) {
                player.playing = !player.playing
                musicGridView.model.list.emitpPlayingState(player.playing)
            }
        }
    }

    color: "#00000000"
    visible: (currentPage >= 4 && currentTrack) ? true : false

    Rectangle {
        width: parent.width
        height: parent.height

        color: "#00000000"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked:{
            }
        }

        //            ShaderEffectSource
        //            {
        //                id: footerBlur

        //                width: parent.width

        //                visible: false
        //                height: parent.height
        //                sourceItem: wholeScreen
        //                sourceRect: Qt.rect(0, wholeScreen.height - height, width, height)
        //            }

        //            FastBlur{
        //                id:fastBlur

        //                anchors.fill: parent

        //                source: footerBlur

        //                radius: 50//128
        //                cached: true
        //                visible: false
        //            }
        //            Rectangle{
        //                id:maskRect

        //                anchors.fill:fastBlur

        //               visible: false
        //                clip: true
        //            }
        //            OpacityMask{
        //                id:mask

        //                anchors.fill: maskRect

        //                visible: true
        //                source: fastBlur
        //                maskSource: maskRect
        //            }

        Rectangle{
            anchors.fill: parent
            color: Kirigami.JTheme.headerBackground
        }

        Rectangle{
            id:currentIcon

            anchors.left: parent.left
            anchors.leftMargin: JDisplay.dp(14)
            anchors.verticalCenter: parent.verticalCenter
            width: JDisplay.dp(55)
            height: JDisplay.dp(56)
            radius: JDisplay.dp(4)

            Image {
                id: currentCoverImage

                anchors.fill: parent
                visible: true

                source:  { //currentCover
                    if(currentTrack) {
                        var musicGenre = currentTrack.genre
                        if(musicGenre === "file://") {
                            "../assets/cover_default.png"
                        } else {
                            musicGenre
                        }
                    } else {
                        "../assets/cover_default.png"
                    }
                }
            }

            //                Rectangle{
            //                    id:currentThemask
            //                    anchors.fill: parent
            //                    radius: 4 * appScaleSize
            //                    visible: false
            //                }

            //                OpacityMask{
            //                    anchors.fill: currentCoverImage

            //                    source: currentCoverImage
            //                    maskSource: currentThemask
            //                    visible: true
            //                }
        }

        Image {
            id: play_right

            anchors.left: currentIcon.right
            anchors.verticalCenter: parent.verticalCenter
            width:  JDisplay.dp(15)
            height: currentIcon.height

            source: "../assets/play_right.png"
        }

        Text {
            id:currentName

            anchors.left: play_right.right
            anchors.leftMargin: JDisplay.dp(16)
            anchors.top: parent.top
            anchors.topMargin: JDisplay.dp(20)
            width: JDisplay.dp(145)

            color: Kirigami.JTheme.majorForeground
            elide: Text.ElideRight
            font.pixelSize: 17 * appFontSize
            text: currentTrack ? (currentTrack.title.lastIndexOf(".") === -1 ?
                                      currentTrack.title : currentTrack.title.substr(0,currentTrack.title.lastIndexOf("."))): ""
        }

        Text {
            id:currentAlbum

            anchors.left: play_right.right
            anchors.leftMargin: JDisplay.dp(16)
            anchors.top: currentName.bottom
            anchors.topMargin: JDisplay.dp(3)
            width: JDisplay.dp(145)

            color: Kirigami.JTheme.minorForeground
            font.pixelSize: 11 * appFontSize
            elide: Text.ElideRight
            text: {
                if(currentTrack) {
                    if(currentTrack.artist === "UNKNOWN" && currentTrack.album === "UNKNOWN") {
                        i18n(currentTrack.artist)
                    }else if(currentTrack.artist !== "UNKNOWN" && currentTrack.album === "UNKNOWN") {
                        i18n(currentTrack.artist)
                    }else if(currentTrack.artist === "UNKNOWN" && currentTrack.album !== "UNKNOWN") {
                        "《" + i18n(currentTrack.album) + "》"
                    }else {
                        i18n(currentTrack.artist) + " · 《" + i18n(currentTrack.album) + "》"
                    }
                }
            }
        }

        Kirigami.JIconButton {
            id: currentType

            anchors.left: currentName.right
            anchors.leftMargin: JDisplay.dp(5)  //30
            anchors.verticalCenter: parent.verticalCenter
            width: (22 + 10) * appScaleSize
            height: (22 + 10) * appScaleSize

            source: {
                if(playType === 0) {
                    "qrc:/assets/loop.png"
                } else if(playType === 1) {
                    "qrc:/assets/shuffle.png"
                } else if(playType === 2) {
                    "qrc:/assets/repeat_one.png"
                }
            }

            onClicked: {
                playType++
                if(playType > 2) {
                    playType = 0;
                }
                Maui.FM.saveSettings("SHUFFLE", playType, "PLAYBACK")
            }

            Component.onCompleted: {
                Maui.FM.loadSettings("SHUFFLE","PLAYBACK", 0)
            }
        }

        Kirigami.JIconButton {
            id: currentFav

            anchors.left: currentType.right
            anchors.leftMargin: JDisplay.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            width: (22 + 10) * appScaleSize
            height: (22 + 10) * appScaleSize

            source: fav ? "qrc:/assets/fav.png" : "qrc:/assets/unfav.png"

            onClicked: {
                if (!mainlistEmpty) {
                    musicGridView.model.list.fav(currentTrackIndex, !Maui.FM.isFav(currentTrack.url))
                    isFav()
                    if(currentPage === 5) {
                        musicGridView.model.list.refresh()
                    }
                }
            }
        }

        Rectangle {
            id: currentTime

            anchors.left: currentFav.right
            anchors.leftMargin: JDisplay.dp(25)
            width: JDisplay.dp(335)
            height: parent.height

            color: "#00000000"

            Rectangle {
                id: playBar

                width: currentTime.width
                height: parent.height
                visible: true
                color: "#00000000"

                Slider  {
                    id: progressBar

                    property bool seekStarted: false
                    property bool keyPress: false

                    anchors.verticalCenter: parent.verticalCenter
                    width: currentTime.width - _label2.width - JDisplay.dp(10)
                    z: parent.z + 1

                    from: 0
                    to: 1000
                    spacing: 0
                    focus: true
                    enabled: true
                    stepSize: 0.1


                    handle: Rectangle {
                        id: handleRect

                        anchors.verticalCenter:parent.verticalCenter
                        width: JDisplay.dp(19)
                        height: JDisplay.dp(20)
                        x: progressBar.leftPadding + progressBar.visualPosition * (progressBar.availableWidth - width)
                        y: 0
                        radius: 4 * appScaleSize

                        color: "#FFFFFFFF"
                    }

                    //                        DropShadow
                    //                        {
                    //                            anchors.fill: handleRect
                    //                            radius: 4
                    //                            samples: 16
                    //                            color: "#50000000"
                    //                            source: handleRect
                    //                        }

                    background: Rectangle {
                        id: rect1

                        anchors.verticalCenter: parent.verticalCenter
                        width: progressBar.availableWidth
                        height: JDisplay.dp(4)
                        radius: 2 * appScaleSize

                        color: Kirigami.JTheme.dividerForeground
                        // opacity: 0.4

                        Rectangle {
                            id: rect2

                            width: progressBar.visualPosition * parent.width
                            height: JDisplay.dp(4)

                            color: Kirigami.JTheme.highlightBlue
                            radius: 2 * appScaleSize
                        }
                    }

                    onPressedChanged: {
                        if(!keyPress) {
                            if (pressed) {
                                progressBar.seekStarted = true
                            } else {
                                player.pos = progressBar.value
                                progressBar.seekStarted = false
                            }
                        }
                    }

                    Connections {
                        target: player
                        function onPosChanged() {
                            if(player.pos === "Infinity") {
                                root.progressTimeLabel = "00:00"
                                return
                            }
                            if (!progressBar.seekStarted) {
                                root.progressTimeLabel = player.transformTime(player.getPlayerPos()/1000)
                                progressBar.value = player.pos
                            }
                        }
                    }

                    Keys.onPressed: {
                        if(event.key === Qt.Key_Right || event.key === Qt.Key_Left) {
                            progressBar.keyPress = true
                            progressBar.seekStarted = true
                            if(event.key === Qt.Key_Right) {
                                value += 10
                            } else {
                                value -= 10
                            }
                            keyEventTimer.restart()
                        }
                    }

                    Timer {
                        id: keyEventTimer

                        interval: 200
                        running: false
                        repeat: false
                        onTriggered: {
                            progressBar.keyPress = false
                            progressBar.seekStarted = false
                            player.pos = progressBar.value
                        }
                    }
                }

                Text {
                    id: _label2

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    visible: text.length
                    text: progressTimeLabel + "/" + player.transformTime(player.duration/1000)

                    elide: Text.ElideMiddle
                    wrapMode: Text.NoWrap
                    color: Kirigami.JTheme.majorForeground//"#FF8E8E93"
                    font.weight: Font.Normal
                    font.pixelSize: 11 * appFontSize
                    opacity: 0.7
                }
            }

        }

        Kirigami.JIconButton {
            id: previousImage

            anchors.left: currentTime.right
            anchors.leftMargin: JDisplay.dp(25)
            anchors.verticalCenter: parent.verticalCenter
            width: (22 + 10) * appScaleSize
            height: (22 + 10) * appScaleSize

            source: "qrc:/assets/previousTrack.png"

            onClicked: {
                playerOP.previousTrack()
                isFav()
            }
        }

        Kirigami.JIconButton {
            id: playImage

            anchors.left: previousImage.right
            anchors.leftMargin: JDisplay.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            width: (30 + 10) * appScaleSize
            height: (30 + 10) * appScaleSize

            source: isPlaying ? "qrc:/assets/pause.png" : "qrc:/assets/play.png"

            onClicked: {
                player.playing = !player.playing
                musicGridView.model.list.emitpPlayingState(player.playing)
            }
        }

        Kirigami.JIconButton {
            id: nextTrackImage

            anchors.left: playImage.right
            anchors.leftMargin: JDisplay.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            width: (22 + 10) * appScaleSize
            height: (22 + 10) * appScaleSize

            source: "qrc:/assets/nextTrack.png"

            onClicked: {
                playerOP.nextTrack(false)
                isFav()
            }
        }

    }
}
