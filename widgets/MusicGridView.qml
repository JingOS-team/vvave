/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.0
import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12
import QtQml.Models 2.15
import QtQuick.Window 2.15
import org.kde.mauikit 1.0 as Maui
import org.kde.kirigami 2.15 as Kirigami
import jingos.display 1.0
import TracksList 1.0

Item {
    id: musicGridViewItem

    property var model: musicGrid.model
    property var gridView: musicGrid

    Tracks {
        id: myTracksList
    }

    Maui.BaseModel {
        id: myTracksModel
        list: myTracksList
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    GridView{
        id: musicGrid

        anchors.fill: parent
        cellWidth: parent.width / 2
        cellHeight: JDisplay.dp(77+5)
        delegate: musicDelegate
        focus: true
        clip: true
        visible:  currentPage >= 4 ? true : false
        model:  myTracksModel

        Connections  {
            target: vvaveControl.Vvave
            function onPlayThirdMusic(source) {

                setCurrentPage(4, true)
                var index = 0
                for(var i = 0; i < musicGrid.count; i++) {
                    if(source === musicGrid.model.get(i).url) {
                        index = i
                        break
                    }
                }
                playerOP.appendAll(musicGrid.model.getAll())
                playerOP.playAt(index)
                isFav()
                currentPlayPage = currentPage;
            }

            function onRefreshTracks(){
                if(currentPage == 4) {
                    if(vvaveControl.Vvave.readMusicEnd())
                        return;

                    musicGrid.model.list.query = queryjs.GET.allTracks

                    if(musicGrid.model.getAll().length == 0) {
                        emptyRect.visible = true
                    } else {
                        emptyRect.visible = false
                    }
                }
            }
        }
    }


    Component{
        id: musicDelegate

        Rectangle {
            id: wapper

            property bool checked

            width: JDisplay.dp(301 + 5)
            height: JDisplay.dp(77)
            radius: 10 * appScaleSize

            checked: selectionBar.contains(model.url)
            color: Kirigami.JTheme.cardBackground//"#FFFFFFFF"

            Rectangle{
                id:imageRect

                anchors.top: parent.top
                anchors.left: parent.left
                width: wapper.height
                height: wapper.height
                radius: 10 * appScaleSize

                color: "transparent"

                Image {
                    id: coverImage

                    property string path
                    anchors.fill: parent
                    source:(path == "file://") ?  "../assets/cover_default.png" : path
                    visible: false

                    Component.onCompleted: {
                        path = musicGrid.model.get(index).genre
                    }
                }

                Rectangle {
                    id:themask

                    anchors.fill: parent
                    radius: 10 * appScaleSize
                    visible: false
                }

                OpacityMask {
                    source: coverImage
                    maskSource: themask
                    anchors.fill: coverImage
                    visible: true
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: imageRect.right
                anchors.leftMargin: JDisplay.dp(15)
                width: wapper.width - wapper.height - JDisplay.dp(30)
                height: wapper.height - JDisplay.dp(27)

                clip: false
                color: "transparent"

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


                Text {
                    id:name

                    anchors.left: parent.left
                    anchors.bottom: album.top
                    anchors.bottomMargin: JDisplay.dp(5)
                    width: parent.width - gifImage.width - 10 * appScaleSize

                    font.pixelSize: 14 * appFontSize
                    elide: Text.ElideRight
                    text: model.title.lastIndexOf(".") === -1 ? model.title : model.title.substr(0,model.title.lastIndexOf("."))
                    color: (currentPlayPage == currentPage && currentTrack && currentTrack.title === model.title
                            && currentTrack.adddate === model.adddate) ? Kirigami.JTheme.highlightBlue : Kirigami.JTheme.majorForeground
                }

                AnimatedImage {
                    id: gifImage

                    anchors.bottom: album.top
                    anchors.bottomMargin: JDisplay.dp(5)
                    anchors.left: parent.left
                    anchors.leftMargin: name.contentWidth + 10 * appScaleSize
                    width: 10 * appScaleSize
                    height: width

                    fillMode: Image.PreserveAspectFit
                    visible: currentPlayPage === currentPage && currentTrack && currentTrack.title === model.title && currentTrack.adddate === model.adddate
                    playing: visible && player.playing
                    source: isDarkTheme ? "qrc:/assets/black_playing.gif" : "qrc:/assets/playing.gif"
                }

                Text {
                    id:album

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - checkStatusImage.width

                    font.pixelSize: 10 * appFontSize
                    elide: Text.ElideRight
                    color:(currentPlayPage == currentPage && currentTrack && currentTrack.title == model.title &&
                           currentTrack.adddate == model.adddate) ? Kirigami.JTheme.highlightBlue : Kirigami.JTheme.minorForeground//"#FF8E8E93"
                    text: {
                        if(model.artist === "UNKNOWN" && model.album === "UNKNOWN")  {
                            i18n(model.artist)
                        } else if(model.artist !== "UNKNOWN" && model.album === "UNKNOWN") {
                            i18n(model.artist)
                        } else if(model.artist === "UNKNOWN" && model.album !== "UNKNOWN") {
                            "《" + i18n(model.album) + "》"
                        } else {
                            i18n(model.artist) + " · 《" + i18n(model.album) + "》"
                        }
                    }
                }

                Text {
                    id: duration

                    anchors.top: album.bottom
                    anchors.topMargin: JDisplay.dp(5)

                    text: player.transformTime(model.duration)
                    font.pixelSize: 10 * appFontSize
                    color: {
                        if(currentPlayPage == currentPage && currentTrack && currentTrack.title == model.title && currentTrack.adddate == model.adddate) {
                            Kirigami.JTheme.highlightBlue
                        } else {
                            Kirigami.JTheme.minorForeground
                        }
                    }
                }
            }

            Image {
                id: checkStatusImage

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 9 * appScaleSize
                width: 22 * appScaleSize
                height: 22 * appScaleSize

                cache: false
                source: checked ? "../assets/select_rect.png" : "../assets/unselect_rect.png"
                visible: musicSelectionMode ? true : false
            }

            Kirigami.JMouseHoverMask {
                anchors.fill: parent
                radius: 9 * appScaleSize

                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressAndHold: {
                    if(!musicSelectionMode) {
                        musicGrid.currentIndex = index
                        var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                        musicPopup.popup(wholeScreen, test.x, test.y)
                    }
                }

                onClicked: {
                    if (mouse.button == Qt.RightButton) {
                        if(!musicSelectionMode) {
                            musicGrid.currentIndex = index
                            var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                            musicPopup.popup(wholeScreen, test.x, test.y)
                        }
                    } else if(mouse.button == Qt.LeftButton) {
                        if(musicSelectionMode) {
                            musicGrid.currentIndex = index
                            helpjs.addToSelection(musicGrid.model.get(index))
                            selectCountText.text = _selectionBar.items.length
                        } else {
                            playerviewleft.searchRect.focus = false
                            musicGrid.currentIndex = index
                            playerOP.playAt(index)
                            playMusicFlag = true
                            vvaveControl.JAppControl.setAppstatus(true)
                            isFav()
                            currentPlayPage = currentPage;
                        }
                    }
                }
            }
        }
    }

    Kirigami.JPopupMenu {
        id: musicPopup

        Action {
            text: i18n("Batch editing")
            icon.source: "qrc:/assets/popupDialog/bat_edit.png"
            onTriggered: {
                musicSelectionMode = true
                _selectionBar.clear()
                selectCountText.text = _selectionBar.items.length
            }
        }

        Kirigami.JMenuSeparator { }

        Action {
            text: i18n("Delete")
            icon.source: "qrc:/assets/popupDialog/delete.png"
            onTriggered: {
                jDialogType = 6
                viewOpPopup.open()
            }
        }
    }
}
