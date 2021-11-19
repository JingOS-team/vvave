/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.0
import QtQuick 2.15
import QtGraphicalEffects 1.15
import QtQuick.Controls 2.15
import org.kde.mauikit 1.0 as Maui
import org.kde.kirigami 2.15 as Kirigami
import jingos.display 1.0
import VideosList 1.0

Item {
    id: videoGridItem
    property var model: videoGrid.model
    property var gridView: videoGrid

    Videos {
        id: myVideosList
    }

    Maui.BaseModel {
        id: myVideosModel
        list: myVideosList
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    GridView {
        id: videoGrid

        anchors.fill: parent

        visible: currentPage <= 3 ? true : false
        model: myVideosModel
        clip: true
        cellWidth: parent.width / 4
        cellHeight: JDisplay.dp(8 + 81 + 20 + 34)
        delegate: videoDelegate

        Component.onCompleted: {
            model.list.query = queryjs.GET.allVideos
        }

        Connections {
            target: vvaveControl.Vvave
            function onRefreshVideos(size) {
                if(currentPage == 1){
                    videoGrid.model.list.query = queryjs.GET.allVideos
                    if(videoGrid.count == 0){
                        emptyRect.visible = true
                    } else {
                        emptyRect.visible = false
                    }
                }
            }
        }
    }

    Component{
        id: videoDelegate

        Rectangle {
            id: wapper

            property bool checked

            width: JDisplay.dp(144)
            height: JDisplay.dp(8 + 81 + 34)
            radius: 8 * appScaleSize
            checked: selectionBar.contains(model.url)
            color: "#00000000"

            Connections {
                target: _selectionBar

                function onUriRemoved(uri) {
                    if(uri === model.url)
                        wapper.checked = false
                }

                function onUriAdded(uri) {
                    if(uri === model.url)
                        wapper.checked = true
                }
                function onAddAll() {
                    wapper.checked = true
                }

                function onCleared() {
                    wapper.checked = false
                }
            }



            Rectangle {
                id:imageRect

                anchors.top: parent.top
                anchors.left: parent.left
                width: wapper.width
                height: JDisplay.dp(81)
                radius: 8 * appScaleSize
                color: "#00000000"

                Image {
                    id:theimage

                    property string path

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    asynchronous: true
                    sourceSize: Qt.size(imageRect.width,imageRect.height)
                    source: (path == "file://") ?  "../assets/video_cover/cover1.png" : path

                    Component.onCompleted: {
                        path = videoGrid.model.get(index).genre
                    }
                }

                Rectangle {
                    id:themask

                    anchors.fill: parent
                    radius: 8 * appScaleSize
                    // color: "#00000000"
                    visible: false
                }

                OpacityMask {
                    anchors.fill: theimage
                    source: theimage
                    maskSource: themask
                }

                Kirigami.JMouseHoverMask {
                    // anchors.fill: parent
                    width: parent.width - 1
                    height: parent.height - 1
                    radius: 8 * appScaleSize

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressAndHold: {
                        if(!videoSelectionMode) {
                            videoGrid.currentIndex = index
                            var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                            videoPopup.popup(wholeScreen, test.x, test.y)
                        }
                    }

                    onClicked: {
                        if (mouse.button == Qt.RightButton) {
                            if(!videoSelectionMode) {
                                videoGrid.currentIndex = index
                                var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                                videoPopup.popup(wholeScreen, test.x, test.y)
                            }
                        } else if(mouse.button == Qt.LeftButton) {
                            if(videoSelectionMode) {
                                videoGrid.currentIndex = index
                                helpjs.addToSelection(videoGrid.model.get(index))
                                selectCountText.text = _selectionBar.items.length
                            } else {
                                videoGrid.currentIndex = index
                                player.playing = false
                                musicGridView.model.list.emitpPlayingState(player.playing)
                                playerviewleft.searchRect.focus = false
                                videoGrid.model.list.countUpVideos(index, true)
                                playVideo(index)
                            }
                        }
                    }
                }
            }

            Text {
                id:name

                anchors.top: imageRect.bottom
                anchors.topMargin: JDisplay.dp(8)
                width: parent.width - JDisplay.dp(5)

                font.pixelSize: 14 * appFontSize
                text: model.title
                color: Kirigami.JTheme.majorForeground
                lineHeight: 1
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            Image {
                id:playIcon

                anchors.bottom: imageRect.bottom
                anchors.bottomMargin: 6 * appScaleSize
                anchors.left: imageRect.left
                anchors.leftMargin: 6 * appScaleSize
                width: 18 * appScaleSize
                height: 18 * appScaleSize
                visible: !videoSelectionMode

                source: "../assets/video_mode_icon.png"
            }

            Text {
                id: duration

                anchors.right: imageRect.right
                anchors.rightMargin: 6 * appScaleSize
                anchors.bottom: imageRect.bottom
                anchors.bottomMargin: 6 * appScaleSize

                text: player.transformTime(model.duration)
                font.pixelSize: 11 * appFontSize
                color: "#E6FFFFFF"
                visible: !videoSelectionMode
            }

            Image  {
                id: checkStatusImage

                anchors.right: parent.right
                anchors.rightMargin: 9 * appScaleSize
                anchors.bottom: imageRect.bottom
                anchors.bottomMargin: JDisplay.dp(5)
                width: 22 * appScaleSize
                height: 22 * appScaleSize

                cache: false
                visible: videoSelectionMode ? true :false
                source:  checked ? "../assets/select_rect.png" : "../assets/unselect_rect.png"
            }
        }
    }

    Kirigami.JPopupMenu {
        id: videoPopup

        Action {
            text: i18n("Batch editing")
            icon.source: "qrc:/assets/popupDialog/bat_edit.png"
            onTriggered:  {
                videoSelectionMode = true
                _selectionBar.clear()
                selectCountText.text = _selectionBar.items.length
            }
        }

        Kirigami.JMenuSeparator { }

        Action {
            text: i18n("Delete")
            icon.source: "qrc:/assets/popupDialog/delete.png"
            onTriggered: {
                jDialogType = 2
                viewOpPopup.open()
            }
        }
    }
}
