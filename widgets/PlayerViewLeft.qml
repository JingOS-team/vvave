/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.0

import org.kde.kirigami 2.15 as Kirigami
import jingos.display 1.0

Rectangle {
    id: menuColumn

    property var searchRect: searchRect

    color: "#00000000"

    function setCurrentPage(index, cancelFocus) {
        if(cancelFocus) {
            searchRect.focus = false
        }
        switch (index) {
        case 1: {
            currentPage = 1
            videoAllRow.color = "#FF43BDF4"
            videoLatelyRow.color = "#00000000"
            musicAllRow.color = "#00000000"
            musicLikeRow.color = "#00000000"
            musicLatelyRow.color = "#00000000"
            populateVideo(queryjs.GET.allVideos, false);
            break
        }
        case 3: {
            currentPage = 3
            videoAllRow.color = "#00000000"
            videoLatelyRow.color = "#FF43BDF4"
            musicAllRow.color = "#00000000"
            musicLikeRow.color = "#00000000"
            musicLatelyRow.color = "#00000000"
            populateVideo(queryjs.GET.mostPlayedVideos, false);
            break
        }
        case 4: {
            currentPage = 4
            videoAllRow.color = "#00000000"
            videoLatelyRow.color = "#00000000"
            musicAllRow.color = "#FF43BDF4"
            musicLikeRow.color = "#00000000"
            musicLatelyRow.color = "#00000000"
            populate(queryjs.GET.allTracks, false);
            break
        }
        case 5: {
            currentPage = 5
            videoAllRow.color = "#00000000"
            videoLatelyRow.color = "#00000000"
            musicAllRow.color = "#00000000"
            musicLikeRow.color = "#FF43BDF4"
            musicLatelyRow.color = "#00000000"
            populate(queryjs.GET.babedTracks, false);
            break
        }
        case 6: {
            currentPage = 6
            videoAllRow.color = "#00000000"
            videoLatelyRow.color = "#00000000"
            musicAllRow.color = "#00000000"
            musicLikeRow.color = "#00000000"
            musicLatelyRow.color = "#FF43BDF4"
            populate(queryjs.GET.mostPlayedTracks, false);
            break
        }
        }
        searchRect.clear()
        filterStatus = ""
        noResultState = false
        cancelEdit()
        if(currentPage <= 3) {
            if(videoGridView.gridView.count == 0) {
                emptyRect.visible = true
            } else {
                emptyRect.visible = false
            }
        } else {
            if(musicGridView.gridView.count == 0) {
                emptyRect.visible = true
            } else {
                emptyRect.visible = false
            }
        }
    }

    Text {
        id: mediaText

        anchors.top: parent.top
        anchors.topMargin: JDisplay.dp(41)
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(25)

        text: i18n("Media")
        elide: Text.ElideRight
        color: Kirigami.JTheme.majorForeground
        font{
            pixelSize: 25 * appFontSize
            bold: true
        }
    }

    Kirigami.JSearchField {
        id: searchRect

        anchors.top: mediaText.bottom
        anchors.topMargin: JDisplay.dp(21)
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(26)
        width: JDisplay.dp(180)

        focus: false
        placeholderText: ""
        Accessible.name: i18n("Search")
        Accessible.searchEdit: true
        focusSequence: "Ctrl+F"
        font.pixelSize: 17 * appFontSize

        onTextChanged: {
            if(currentPage <= 3) {
                filterStatus = searchRect.text
                if(searchRect.text !== "") {
                    videoGridView.model.list.searchQueriesVideos(searchRect.text, currentPage)
                }
            } else if(currentPage >= 4) {
                filterStatus = searchRect.text
                if(searchRect.text !== "") {
                    musicGridView.model.list.searchQueries(searchRect.text, currentPage)
                }
            }
            if(filterStatus != "") {
                if(currentPage <= 3) {
                    if(videoGridView.gridView.count === 0) {
                        noResultState = true
                        emptyRect.visible = true
                    } else {
                        noResultState = false
                        emptyRect.visible = false
                    }
                } else {
                    if(musicGridView.gridView.count === 0) {
                        noResultState = true
                        emptyRect.visible = true
                    } else {
                        noResultState = false
                        emptyRect.visible = false
                    }
                }
            }
            else if(searchRect.text === "") {
                setCurrentPage(currentPage, false)
            }
        }

        onRightActionTrigger: {
            setCurrentPage(currentPage, true)
        }
    }

    Text {
        id: videoText

        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(25)
        anchors.top: searchRect.bottom
        anchors.topMargin: JDisplay.dp(28)
        width: parent.width

        text: i18n("Video")
        elide: Text.ElideRight
        color: Kirigami.JTheme.minorForeground
        font.pixelSize: 12 * appFontSize
    }

    Rectangle {
        id: videoAllRow

        anchors.top: videoText.bottom
        anchors.topMargin: JDisplay.dp(6)
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(13)
        width: JDisplay.dp(197)
        height: JDisplay.dp(39)
        radius: JDisplay.dp(10)

        color: currentPage == 1 ? Kirigami.JTheme.highlightBlue : "#00000000"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(currentPage != 1) {
                    setCurrentPage(1, true)
                }
            }

            onEntered: {
                if(currentPage != 1) {
                    videoAllRow.color = Kirigami.JTheme.hoverBackground
                }
            }
            onExited: {
                if(currentPage != 1) {
                    videoAllRow.color = "#00000000"
                }
            }
        }

        Image {
            id: videoAllIcon

            anchors.left: parent.left
            anchors.leftMargin: JDisplay.dp(12)
            anchors.verticalCenter: parent.verticalCenter
            width: 16 * appScaleSize
            height: 16 * appScaleSize

            fillMode: Image.PreserveAspectFit
            source: isDarkTheme ? "../assets/menu/video_all_select.png" : (currentPage == 1 ?
                                                   "../assets/menu/video_all_select.png" : "../assets/menu/video_all_unselect.png")
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: videoAllIcon.right
            anchors.leftMargin: JDisplay.dp(10)

            text: i18n("All")
            elide: Text.ElideRight
            color: isDarkTheme ? '#FFFFFFFF' : (currentPage == 1 ? '#FFFFFFFF' : '#FF000000')
            font.pixelSize: 14 * appFontSize
        }
    }

    Rectangle {
        id: videoLatelyRow

        anchors.top: videoAllRow.bottom
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(13)
        width: JDisplay.dp(197)
        height: JDisplay.dp(39)

        color: currentPage == 3 ? Kirigami.JTheme.highlightBlue : "#00000000"
        radius: JDisplay.dp(10)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(currentPage != 3) {
                    setCurrentPage(3, true)
                }
            }

            onEntered: {
                if(currentPage != 3) {
                    videoLatelyRow.color = Kirigami.JTheme.hoverBackground
                }

            }
            onExited: {
                if(currentPage != 3) {
                    videoLatelyRow.color = "#00000000"
                }
            }
        }

        Image {
            id: videoLatelyIcon

            anchors.left: parent.left
            anchors.leftMargin: JDisplay.dp(12)
            anchors.verticalCenter: parent.verticalCenter
            width: 16 * appScaleSize
            height: 16 * appScaleSize

            fillMode: Image.PreserveAspectFit
            source: isDarkTheme ? "../assets/menu/video_lately_select.png" : (currentPage == 3 ?
                                                       "../assets/menu/video_lately_select.png" : "../assets/menu/video_lately_unselect.png")

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }
        }

        Text  {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: videoLatelyIcon.right
            anchors.leftMargin: JDisplay.dp(12)

            text: i18n("Lately")
            elide: Text.ElideRight
            color: isDarkTheme ? '#FFFFFFFF' : (currentPage == 3 ? '#FFFFFFFF' : '#FF000000')
            font.pixelSize: 14 * appFontSize
        }
    }

    Text {
        id: musicText

        width: parent.width

        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(25)
        anchors.top: videoLatelyRow.bottom
        anchors.topMargin:JDisplay.dp(28)

        text: i18n("Music")
        elide: Text.ElideRight
        color: Kirigami.JTheme.minorForeground
        font.pixelSize: 12 * appFontSize
    }

    Rectangle {
        id: musicAllRow

        anchors.top: musicText.bottom
        anchors.topMargin: JDisplay.dp(6)
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(13)
        width: JDisplay.dp(197)
        height: JDisplay.dp(39)
        radius: JDisplay.dp(10)

        color: currentPage == 4 ? Kirigami.JTheme.highlightBlue : "#00000000"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(currentPage != 4) {
                    setCurrentPage(4, true)
                }
            }

            onEntered:  {
                if(currentPage != 4) {
                    musicAllRow.color = Kirigami.JTheme.hoverBackground
                }

            }
            onExited: {
                if(currentPage != 4) {
                    musicAllRow.color = "#00000000"
                }
            }
        }

        Image {
            id: musicAllIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: JDisplay.dp(12)
            width: 16 * appScaleSize
            height: 16 * appScaleSize

            fillMode: Image.PreserveAspectFit
            source: isDarkTheme ? "../assets/menu/music_all_select.png" : (currentPage == 4 ?
                                                   "../assets/menu/music_all_select.png" : "../assets/menu/music_all_unselect.png")
        }

        Text  {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: musicAllIcon.right
            anchors.leftMargin: JDisplay.dp(12)

            text: i18n("All")
            elide: Text.ElideRight
            color: isDarkTheme ? '#FFFFFFFF' : (currentPage == 4 ? '#FFFFFFFF' : '#FF000000')
            font.pixelSize: 14 * appFontSize
        }
    }


    Rectangle {
        id: musicLikeRow

        anchors.top: musicAllRow.bottom
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(13)
        width: JDisplay.dp(197)
        height: JDisplay.dp(39)
        radius: JDisplay.dp(10)

        color: currentPage == 5 ? Kirigami.JTheme.highlightBlue : "#00000000"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(currentPage != 5) {
                    setCurrentPage(5, true)
                }
            }

            onEntered: {
                if(currentPage != 5) {
                    musicLikeRow.color = Kirigami.JTheme.hoverBackground
                }

            }

            onExited: {
                if(currentPage != 5) {
                    musicLikeRow.color = "#00000000"
                }
            }
        }

        Image {
            id: musicLikeIcon

            anchors.left: parent.left
            anchors.leftMargin: JDisplay.dp(10)
            anchors.verticalCenter: parent.verticalCenter
            width: 16 * appScaleSize
            height: 16 * appScaleSize

            fillMode: Image.PreserveAspectFit
            source: isDarkTheme ? "../assets/menu/music_like_select1.svg" : (currentPage == 5 ?
                                                       "../assets/menu/music_like_select1.svg" : "../assets/menu/music_like_unselect1.svg")

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }
        }

        Text {
            width: parent.width

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: musicLikeIcon.right
            anchors.leftMargin: JDisplay.dp(12)

            text: i18n("Like")
            elide: Text.ElideRight
            color: isDarkTheme ? '#FFFFFFFF' : (currentPage == 5 ? '#FFFFFFFF' : '#FF000000')
            font.pixelSize: 14 * appFontSize
        }
    }

    Rectangle {
        id: musicLatelyRow

        anchors.top: musicLikeRow.bottom
        anchors.left: parent.left
        anchors.leftMargin: JDisplay.dp(13)
        width: JDisplay.dp(197)
        height: JDisplay.dp(39)

        color: currentPage == 6 ? Kirigami.JTheme.highlightBlue : "#00000000"
        radius: JDisplay.dp(10)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if(currentPage != 6) {
                    setCurrentPage(6, true)
                }
            }

            onEntered: {
                if(currentPage != 6) {
                    musicLatelyRow.color = Kirigami.JTheme.hoverBackground
                }

            }
            onExited: {
                if(currentPage != 6) {
                    musicLatelyRow.color = "#00000000"
                }
            }
        }

        Image {
            id: musicLatelyIcon

            anchors.left: parent.left
            anchors.leftMargin: JDisplay.dp(12)
            anchors.verticalCenter: parent.verticalCenter
            width: 16 * appScaleSize
            height: 16 * appScaleSize
            source: isDarkTheme ? "../assets/menu/music_lately_select.png" : (currentPage == 6 ?
                                                      "../assets/menu/music_lately_select.png" : "../assets/menu/music_lately_unselect.png")
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }
        }

        Text {

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: musicLatelyIcon.right
            anchors.leftMargin: JDisplay.dp(12)
            width: parent.width

            text: i18n("Lately")
            elide: Text.ElideRight
            color: isDarkTheme ? '#FFFFFFFF' : (currentPage == 6 ? '#FFFFFFFF' : '#FF000000')
            font. pixelSize: 14 * appFontSize
        }
    }
    //music end
}
