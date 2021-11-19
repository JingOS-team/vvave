/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import org.kde.mauikit 1.0 as Maui
import org.kde.kirigami 2.15 as Kirigami
import jingos.display 1.0
import TracksList 1.0
import VideosList 1.0

Rectangle {

    id: wholeScreen

    property var playerviewleft: playerviewleft
    property alias progressBar: musicplayfooter.progressBar
    property alias musicGridView: musicGridView

    color: Kirigami.JTheme.background

    function populate(query, isPublic) {
        if(query === queryjs.GET.babedTracks || query === queryjs.GET.mostPlayedTracks) {
            musicGridView.model.list.sortBy = Tracks.RELEASEDATE
        } else {
            musicGridView.model.list.sortBy = Tracks.ADDDATE
        }
        playlistQuery = query
        musicGridView.model.list.query = playlistQuery
        filterStatus = ""
    }

    function populateVideo(query, isPublic) {
        if(query === queryjs.GET.mostPlayedVideos) {
            videoGridView.model.list.sortBy = Videos.RELEASEDATE
        } else {
            videoGridView.model.list.sortBy = Tracks.ADDDATE
        }
        videoGridView.model.list.query = query
        filterStatus = ""
    }


    function isFav() {
        fav = currentTrack ? Maui.FM.isFav(currentTrack.url) : false
        var musicGenre = musicGridView.model.get(currentTrackIndex).genre
        if(musicGenre === "file://") {
            currentCover = "../assets/cover_default.png"
        } else {
            currentCover = musicGenre
        }
    }

    function clearPlayList() {
        player.stop()
        musicGridView.model.list.clear()
        sync = false
        syncPlaylist = ""
    }

    function cancelEdit() {
        if(musicSelectionMode) {
            musicSelectionMode = false
        }

        if(videoSelectionMode) {
            videoSelectionMode = false
        }
        _selectionBar.clear()
    }

    function updateLately(index) {
        videoGridView.model.list.countUpVideos(index, true)
    }

    function play(){
        player.playing = !player.playing
    }

    function nextTrack() {
        playerOP.nextTrack(false)
        isFav()
    }

    function previousTrack() {
        playerOP.previousTrack()
        isFav()
    }
    //for dbus end

    function addToSelection(item, index) {
        if(_selectionBar.contains(item.url)) {
            _selectionBar.removeAtUri(item.url)
            return
        }
        _selectionBar.justAppend(item.url, item)
    }

    function selectAll(type) {
        if(_selectionBar == null) {
            return
        }

        if(type === 1) {
            selectIndexes([...Array(videoGridView.gridView.count).keys()], type)
            selectAllLength = videoGridView.gridView.count
        } else if(type === 2) {
            selectIndexes([...Array(musicGridView.gridView.count).keys()], type)
            selectAllLength = musicGridView.gridView.count
        }
    }

    function selectIndexes(indexes, type) {
        if(type === 1) {
            for(var i in indexes)
                addToSelection(videoGridView.model.get(indexes[i]), i)
        }else if(type === 2) {
            for(var i in indexes)
                addToSelection(musicGridView.model.get(indexes[i]), i)
        }

        _selectionBar.selectAllSignal()
    }


    function playVideo(index) {
        vvaveControl.JAppControl.setAppstatus(false)
        var videoModel
        for(var i = 0; i < videoGridView.gridView.count; i++) {
            videoModel = {"mimeType": "video/mp4", "mediaType": 1, "previewurl": "", "imageTime": "", "mediaurl": videoGridView.model.get(i).url}
            previewimagemodel.append(videoModel)
        }
        playStartIndex = index;
        var previousObj = applicationWindow().pageStack.layers.push(previewCom, {
                                                                        startIndex: index,//page.model.index(gridView.currentIndex, 0),//sortedListModel.index
                                                                        imagesModel: previewimagemodel,
                                                                        imageDetailTitle:""
                                                                    });

        previousObj.close.connect(previewPageRequestClose);
        previousObj.requestFullScreen.connect(previewPageRequestFullScreen);
    }

    function previewPageRequestClose(){
        if(playMusicFlag) {
            vvaveControl.JAppControl.setAppstatus(true)
        }
        applicationWindow().pageStack.layers.pop();
    }

    function previewPageRequestFullScreen(){
        applicationWindow().visibility = (applicationWindow().visibility === Window.FullScreen) ? Window.Windowed : Window.FullScreen;
    }

    Connections {
        target: _selectionBar

        function onUriRemoved(uri) {
            if(_selectionBar.items.length == 0) {
                selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
                deleteImage.source = "qrc:/assets/delete.png"
                deleteImage.color = Kirigami.JTheme.iconDisableForeground
            } else if((currentPage < 4 && _selectionBar.items.length === videoGridView.gridView.count) ||
                      (currentPage >= 4 && _selectionBar.items.length === musicGridView.gridView.count)) {
                selectAllImage.source = "qrc:/assets/select_rect.png"
                deleteImage.source = "qrc:/assets/delete_enable.png"
                deleteImage.color = isDarkTheme ? "#FFFFFFFF" : "#FF000000"
            } else {
                selectAllImage.source = "qrc:/assets/check_status_enable.png"
                deleteImage.source = "qrc:/assets/delete_enable.png"
                deleteImage.color = isDarkTheme ? "#FFFFFFFF" : "#FF000000"
            }
        }

        function onUriAdded(uri) {
            if(_selectionBar.items.length == 0) {
                selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
                // saveImage.source = "assets/save.png"
                deleteImage.source = "qrc:/assets/delete.png"
                deleteImage.color = Kirigami.JTheme.iconDisableForeground
            } else if((currentPage < 4 && _selectionBar.items.length === videoGridView.gridView.count) ||
                      (currentPage >= 4 && _selectionBar.items.length === musicGridView.gridView.count)) {
                selectAllImage.source = "qrc:/assets/select_rect.png"
                deleteImage.source = "qrc:/assets/delete_enable.png"
                deleteImage.color = isDarkTheme ? "#FFFFFFFF" : "#FF000000"
            } else {
                selectAllImage.source = "qrc:/assets/check_status_enable.png"
                deleteImage.source = "qrc:/assets/delete_enable.png"
                deleteImage.color = isDarkTheme ? "#FFFFFFFF" : "#FF000000"
            }
        }

        function  onAddAll() {
            if(_selectionBar.items.length == 0) {
                selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
                deleteImage.source = "qrc:/assets/delete.png"
                deAnimatedImageleteImage.color = Kirigami.JTheme.iconDisableForeground
            } else if((currentPage < 4 && _selectionBar.items.length === videoGridView.gridView.count) ||
                      (currentPage >= 4 && _selectionBar.items.length === musicGridView.gridView.count)) {
                selectAllImage.source = "qrc:/assets/select_rect.png"
                deleteImage.source = "qrc:/assets/delete_enable.png"
                deleteImage.color = isDarkTheme ? "#FFFFFFFF" : "#FF000000"
            } else {
                selectAllImage.source = "qrc:/assets/check_status_enable.png"
                deleteImage.source = "qrc:/assets/delete_enable.png"
                deleteImage.color = isDarkTheme ? "#FFFFFFFF" : "#FF000000"
            }
        }

        function onCleared() {
            selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
            deleteImage.source = "qrc:/assets/delete.png"
            deleteImage.color = Kirigami.JTheme.iconDisableForeground
        }
    }

    ViewOpPopup{
        id: viewOpPopup
    }

    Component {
        id:previewCom

        Kirigami.JImagePreviewItem{
            id: previewItem

            onClose:{
                previewimagemodel.clear()
            }
            onListCurrIndexChanged: {
                if(listCurrIndex === -1 || (listCurrIndex === 0 && playStartIndex !== 0))
                    return
                videoGridView.model.list.countUpVideos(listCurrIndex, true)
            }
        }
    }

    Row {
        anchors.fill: parent

        PlayerViewLeft {
            id: playerviewleft

            width: JDisplay.dp(225)
            height: parent.height
        }

        Rectangle {
            width: JDisplay.dp(663)
            height: parent.height
            color: "#00000000"

            Kirigami.JIconButton {
                id: backImage

                anchors.top: parent.top
                anchors.topMargin: JDisplay.dp(39)
                width: (22 + 10) * appScaleSize
                height: (22 + 10) * appScaleSize

                source: "qrc:/assets/back_arrow.png"
                visible: ((filterStatus != "") && (!musicSelectionMode && !videoSelectionMode)) ? true : false

                onClicked: {
                    playerviewleft.setCurrentPage(currentPage, true)
                }
            }

            Text {
                id: contentTitle

                anchors.left: filterStatus != "" ? backImage.right : parent.left
                anchors.leftMargin: filterStatus != "" ?  JDisplay.dp(10) : 0
                anchors.verticalCenter: backImage.verticalCenter

                visible: !musicSelectionMode && !videoSelectionMode
                elide: Text.ElideRight
                color: Kirigami.JTheme.majorForeground//'#FF000000'
                font {
                    pixelSize: 25 * appFontSize
                    bold: true
                }
                text: {
                    if(filterStatus != "") {
                        i18n("Search Results")
                    } else if(currentPage == 1 || currentPage == 4) {
                        i18n("All")
                    } else if(currentPage == 2 || currentPage == 5) {
                        i18n("Like")
                    } else if(currentPage == 3 || currentPage == 6) {
                        i18n("Lately")
                    }
                }
            }

            Rectangle {

                anchors.top: parent.top
                anchors.topMargin: JDisplay.dp(40)
                anchors.left: parent.left
                width: JDisplay.dp(623)
                height: JDisplay.dp(32)

                visible: musicSelectionMode || videoSelectionMode
                color: "#00000000"

                Kirigami.JIconButton {
                    id: selectAllImage

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: (22 + 10) * appScaleSize
                    height: (22 + 10) * appScaleSize

                    source: "qrc:/assets/check_status.png"

                    onClicked: {
                        if(musicSelectionMode) {
                            if(_selectionBar.items.length == musicGridView.gridView.count) {
                                _selectionBar.clear()
                            } else {
                                _selectionBar.clear()
                                selectAll(2)
                            }
                            selectCountText.text = _selectionBar.items.length
                        }else if(videoSelectionMode) {
                            if(_selectionBar.items.length == videoGridView.gridView.count) {
                                _selectionBar.clear()
                            } else {
                                _selectionBar.clear()
                                selectAll(1)
                            }
                            selectCountText.text = _selectionBar.items.length
                        }
                    }
                }
                Text {
                    id: selectCountText

                    anchors.left: selectAllImage.right
                    anchors.leftMargin: JDisplay.dp(5)
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 14 * appFontSize
                    text: "1"
                    color: Kirigami.JTheme.majorForeground//"#FF000000"
                }

                Kirigami.JIconButton{
                    id: deleteImage

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: (22 + 10) * appScaleSize
                    height: (22 + 10) * appScaleSize

                    color: Kirigami.JTheme.iconDisableForeground
                    source: "qrc:/assets/delete.png"

                    onClicked: {
                        if(_selectionBar.items.length > 0) {
                            if(musicSelectionMode) {
                                if(_selectionBar.items.length ==  1) {
                                    viewOpPopup.text = i18n("Are you sure you want to delete the file?")
                                } else if(_selectionBar.items.length > 1) {
                                    viewOpPopup.text =  i18n("Are you sure you want to delete these files?")
                                }
                                jDialogType = 8
                                viewOpPopup.open()
                            } else if(videoSelectionMode) {
                                if(_selectionBar.items.length ==  1) {
                                    viewOpPopup.text = i18n("Are you sure you want to delete the file?")
                                } else if(_selectionBar.items.length > 1)  {
                                    viewOpPopup.text =  i18n("Are you sure you want to delete these files?")
                                }
                                jDialogType = 4
                                viewOpPopup.open()
                            }
                        }
                    }
                }

                Kirigami.JIconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: (22 + 10) * appScaleSize
                    height: (22 + 10) * appScaleSize

                    source: "qrc:/assets/cancel_enable.png"

                    onClicked: {
                        cancelEdit()
                    }
                }
            }

            MusicGridView {
                id: musicGridView

                anchors.top: contentTitle.bottom
                anchors.topMargin: JDisplay.dp(13)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: musicplayfooter.visible ? musicplayfooter.height : 0
                anchors.left: parent.left
                anchors.right: parent.right
            }

            VideoGridView {

                id: videoGridView

                anchors.top: contentTitle.bottom
                anchors.topMargin: JDisplay.dp(13)
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                width: parent.width
                height: parent.height
            }

            Item {
                id: emptyRect

                anchors.top: contentTitle.bottom
                anchors.topMargin: JDisplay.dp(13)
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                width: parent.width
                height: parent.height

                visible: false

                Kirigami.Icon {
                    id: emptyIcon

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 310 * appScaleSize
                    width: 60 * appScaleSize
                    height: width

                    color: Kirigami.JTheme.majorForeground
                    source: noResultState ? "qrc:/assets/search_empty.png" : (currentPage <= 3 ?  "qrc:/assets/video_empty.png" : "qrc:/assets/music_empty.png")
                }

                Text {
                    anchors.top: emptyIcon.bottom
                    anchors.topMargin: 15 * appScaleSize
                    anchors.horizontalCenter: parent.horizontalCenter

                    color: Kirigami.JTheme.disableForeground
                    font.pixelSize: 14 * appFontSize
                    text: noResultState ? i18n("Sorry,there are no search results.") :
                                          (currentPage <= 3 ?  i18n("There are no videos at present") : i18n("There is no music at present"))
                }
            }
        }
    }

    MusicPlayControl {
        id: musicplayfooter

        anchors.bottom: parent.bottom
        width: wholeScreen.width
        height: JDisplay.dp(81)
    }
}
