import QtGraphicalEffects 1.0
import org.kde.kirigami 2.15 as Kirigami
import org.kde.mauikit 1.0 as Maui
import org.kde.mauikit 1.1 as MauiLab
import org.maui.vvave 1.0 as Vvave
import org.kde.kquickcontrolsaddons 2.0 as KQA

import Player 1.0
import AlbumsList 1.0
import TracksList 1.0
import VideosList 1.0
import PlaylistsList 1.0

import "utils"

import "widgets"
import "widgets/MainPlaylist"

import "view_models"
import "view_models/BabeTable"

import "db/Queries.js" as Q
import "utils/Help.js" as H
import "utils/Player.js" as Player

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12
import QtQml.Models 2.15

Kirigami.ApplicationWindow
{
    // fastBlurMode: true
    // fastBlurColor: "#CCF7F7F7"

    id: root
    
    title: currentTrack ? currentTrack.title + " - " +  currentTrack.artist + " | " + currentTrack.album : ""
    /***************************************************/
    /******************** ALIASES ********************/
    /*************************************************/
    property alias mainPlaylist: mainPlaylist
    property alias selectionBar: _selectionBar
    property alias progressBar: progressBar
    // property alias dialog : _dialogLoader.item
    

    background.opacity: translucency ? 0.5 : 1

    /***************************************************/
    /******************** PLAYBACK ********************/
    /*************************************************/
    property int playType: Maui.FM.loadSettings("SHUFFLE","PLAYBACK", 0)//0--顺序播放 1--随机播放 2--单曲循环

    property var currentTrack: mainPlaylist.listView.itemAtIndex(currentTrackIndex)

    property int currentTrackIndex: -1
    property int prevTrackIndex: 0

    property int currentPage: 1//1--视频all 2--视频like 3--视频lately 4--音乐all 5--音乐like 6--音乐lately
    property int currentPlayPage: 4//在某个列表中点击音乐播放后 其他列表中不进行音乐是否在播放的判断

    property alias durationTimeLabel: player.duration
    property string progressTimeLabel: player.transformTime((player.duration/1000) *(player.pos/ 1000))

    property alias isPlaying: player.playing
    property int onQueue: 0

    property bool mainlistEmpty: !mainPlaylist.table.count > 0

    property string syncPlaylist: ""
    property bool sync: false

    property bool focusView : false
    property bool musicSelectionMode : false //是否是音频编辑状态
    property bool videoSelectionMode : false //是否是视频编辑状态
    property bool noResultState: false //当前是否为搜索无结果的状态

    /***************************************************/
    /******************** UI COLORS *******************/
    /*************************************************/
    readonly property color babeColor: "#f84172"

    property bool translucency : Maui.Handy.isLinux

    /*SIGNALS*/
    signal missingAlert(var track)

    property string filterStatus: ""

    Tracks
    {
        id: myTracksList
    }

    Maui.BaseModel
    {
        id: myTracksModel
        list: myTracksList
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    Videos
    {
        id: myVideosList
    }

    Maui.BaseModel
    {
        id: myVideosModel
        list: myVideosList
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    property int jDialogType: 1 // 1--视频单独存储 2--视频单独删除 3--视频批量存储 4--视频批量删除 5--音频单独存储 6--音频单独删除 7--音频批量存储 8--音频批量删除
    Kirigami.JDialog
    {
        id: jDialog

        closePolicy: Popup.CloseOnEscape
        leftButtonText: i18n("Cancel")

        title: 
        {
            switch (jDialogType) 
            {
                case 1:
                case 3:
                case 5:
                case 7:
                {
                    i18n("Save to files")
                    break
                }
                case 2:
                case 4:
                case 6:
                case 8:
                {
                    i18n("Delete")
                    break
                }
            }
        }

        text: 
        {
            switch (jDialogType) 
            {
                case 1:
                case 5:
                {
                    i18n("Are you sure you want to save the file to file manager?")
                    break
                }
                case 2:
                case 6:
                {
                    i18n("Are you sure you want to delete the file?")
                    break
                }
                case 3:
                case 7:
                {
                    if(_selectionBar.items.length > 1)
                    {
                        i18n("Are you sure you want to save these files to file manager?")
                    }else
                    {
                        i18n("Are you sure you want to save the file to file manager?")
                    }
                    break
                }
                case 4:
                case 8:
                {
                    if(_selectionBar.items.length > 1)
                    {
                        i18n("Are you sure you want to delete these files?")
                    }else
                    {
                        i18n("Are you sure you want to delete the file?")
                    }
                    break
                }
            }
        }

        rightButtonText: 
        {
            switch (jDialogType) 
            {
                case 1:
                case 3:
                case 5:
                case 7:
                {
                    i18n("Save")
                    break
                }
                case 2:
                case 4:
                case 6:
                case 8:
                {
                    i18n("Delete")
                    break
                }
            }
        }

        onLeftButtonClicked:
        {
            close()
        }

        onRightButtonClicked:
        {
            switch (jDialogType) 
            {
                case 1://视频单独存储
                {
                    videoGridView.model.list.copyFileVideos(videoGridView.currentIndex, false)
                    break
                }
                case 2://视频单独删除
                {
                    if(videoGridView.model.list.deleteFileVideos(videoGridView.currentIndex))
                    {
                        videoGridView.model.list.removeVideos(videoGridView.currentIndex)
                        if(videoGridView.model.getAll().length == 0)
                        {
                            emptyRect.visible = true
                        }
                    }
                    break
                }
                case 3://视频批量存储
                {
                    for(var i = 0; i < _selectionBar.items.length; i++)
                    {
                        for(var j = 0; j < videoGridView.model.getAll().length; j++)
                        {
                            if(_selectionBar.items[i].url === videoGridView.model.get(j).url)
                            {
                                videoGridView.model.list.copyFileVideos(j, false)
                                break
                            }
                        }
                    }

                    if(videoGridView.model.getAll().length == 0)
                    {
                        emptyRect.visible = true
                    }
                    videoSelectionMode = false
                    _selectionBar.clear()
                    break
                }
                case 4://视频批量删除
                {
                    for(var i = 0; i < _selectionBar.items.length; i++)
                    {
                        for(var j = 0; j < videoGridView.model.getAll().length; j++)
                        {
                            if(_selectionBar.items[i].url === videoGridView.model.get(j).url)
                            {
                                if(videoGridView.model.list.deleteFileVideos(j))
                                {
                                    videoGridView.model.list.removeVideos(j)
                                }
                                break
                            }
                        }
                    }
                    if(videoGridView.model.getAll().length == 0)
                    {
                        emptyRect.visible = true
                    }
                    _selectionBar.clear()
                    selectCountText.text = _selectionBar.items.length 
                    videoSelectionMode = false
                    break
                }
                case 5://音乐单独存储
                {
                    musicGridView.model.list.copyFile(musicGridView.currentIndex, false)
                    break
                }
                case 6://音频单独删除
                {
                    var item = musicGridView.model.get(musicGridView.currentIndex)
                    if(musicGridView.model.list.deleteFile(musicGridView.currentIndex))
                    {
                        musicGridView.model.list.remove(musicGridView.currentIndex)
                        if(isPlaying)
                        {
                            if(musicGridView.model.getAll().length == 0)
                            {
                                player.playing = !player.playing
                                musicGridView.model.list.emitpPlayingState(player.playing)
                                clearPlayList()
                                currentTrack = mainPlaylist.listView.itemAtIndex(currentTrackIndex)
                                emptyRect.visible = true
                            }else
                            {
                                mainPlaylist.listModel.list.remove(musicGridView.currentIndex)
                                if(currentTrack && currentTrack.title == item.title && currentTrack.adddate == item.adddate)//如果删除的是当前播放的歌曲，则顺势播放下一首歌曲
                                {
                                    Player.playAt(musicGridView.currentIndex)
                                    isFav()
                                }

                            }
                        }
                        if(musicGridView.model.getAll().length == 0)
                        {
                            emptyRect.visible = true
                        }
                    }
                    break
                }
                case 7://音频批量存储
                {
                    for(var i = 0; i < _selectionBar.items.length; i++)
                    {
                        for(var j = 0; j < musicGridView.model.getAll().length; j++)
                        {
                            if(_selectionBar.items[i].url === musicGridView.model.get(j).url)
                            {
                                musicGridView.model.list.copyFile(j, false)
                                break
                            }
                        }
                    }
                    musicSelectionMode = false
                    _selectionBar.clear()
                    break
                }
                case 8://音频批量删除
                {
                    for(var i = 0; i < _selectionBar.items.length; i++)
                    {
                        for(var j = 0; j < musicGridView.model.getAll().length; j++)
                        {
                            if(_selectionBar.items[i].url === musicGridView.model.get(j).url)
                            {
                                if(musicGridView.model.list.deleteFile(j))
                                {
                                    musicGridView.model.list.remove(j)
                                    mainPlaylist.listModel.list.remove(j)
                                }
                                break
                            }
                        }
                    }
                    if(isPlaying)
                    {
                        if(musicGridView.model.getAll().length == 0)
                        {
                            player.playing = !player.playing
                            musicGridView.model.list.emitpPlayingState(player.playing)
                            clearPlayList()
                            currentTrack = mainPlaylist.listView.itemAtIndex(currentTrackIndex)
                            emptyRect.visible = true
                        }else
                        {
                            Player.playAt(0)
                            isFav()
                        }
                    }else
                    {
                        if(musicGridView.model.getAll().length == 0)
                        {
                            emptyRect.visible = true
                        }
                    }
                    _selectionBar.clear()
                    selectCountText.text = _selectionBar.items.length 
                    musicSelectionMode = false
                    break
                }
            }
            close()
        }
    }

    /*HANDLE EVENTS*/
    onClosing: 
    {
        Player.savePlaylist()
    }

    onMissingAlert:
    {
        var message = qsTr("Missing file")
        var messageBody = track.title + " by " + track.artist + " is missing.\nDo you want to remove it from your collection?"
        notify("dialog-question", message, messageBody, function ()
        {
            mainPlaylist.listModel.list.remove(mainPlaylist.table.currentIndex)
        })
    }

    Player
    {
        id: player

        volume: 100

        onFinishedChanged: 
        {
            if (!mainlistEmpty)
            {
                if (currentTrack && currentTrack.url)
                    Player.nextTrack(true)
                    isFav()
           }
        }
    }

    // SelectionBar
    // {
    //     id: _selectionBar

    //     visible: false
    //     property alias listView: _selectionBar.selectionList
    // }

    SelectionBar1
    {
        id: _selectionBar
    }

    Loader
    {
        id: _dialogLoader
    }

    Playlists
    {
        id: playlistsList
    }

    MainPlaylist
    {
        id: mainPlaylist

        anchors.fill: parent

        // Connections
        // {
        //     target: mainPlaylist
        //     onCoverPressed: Player.appendAll(tracks)
        //     onCoverDoubleClicked: Player.playAll(tracks)
        // }
    }      


    Kirigami.JPopupMenu 
    {
        id: musicPopup

        Action { 
            text: i18n("Batch editing")
            icon.source: "qrc:/assets/popupDialog/bat_edit.png"
            onTriggered:
            {
                musicSelectionMode = true
                _selectionBar.clear()
                selectCountText.text = _selectionBar.items.length
                // close()
            }
        }

        Kirigami.JMenuSeparator { }

        Action { 
            text: i18n("Delete")
            icon.source: "qrc:/assets/popupDialog/delete.png"
            onTriggered:
            {
                jDialogType = 6
                jDialog.open()
                // close()
            }
        }
    }

    Kirigami.JPopupMenu 
    {
        id: videoPopup

        Action { 
            text: i18n("Batch editing")
            icon.source: "qrc:/assets/popupDialog/bat_edit.png"
            onTriggered:
            {
                videoSelectionMode = true
                _selectionBar.clear()
                selectCountText.text = _selectionBar.items.length
                // close()
            }
        }

        Kirigami.JMenuSeparator { }

        Action { 
            text: i18n("Delete")
            icon.source: "qrc:/assets/popupDialog/delete.png"
            onTriggered:
            {
                jDialogType = 2
                jDialog.open()
                // close()
            }
        }
    }

    // readonly property color backGroundColor: "#FFF7F7F7"
    
    Rectangle//整个屏幕
    {
        id: wholeScreen

        anchors.fill: parent
        // width: 1920
        // height: 1080

        // color: "#00000000"
        color: "#FFE8EFFF"

        Row
        {
            anchors.fill: parent

            // anchors.top: topSpaceRect.bottom
            anchors.topMargin: 30

            spacing: parent.width / 30

            Rectangle//左侧菜单区域
            {
                id: menuColumn

                width: parent.width / 4.27
                height: parent.height
                color: "#00000000"

                Row
                {
                    id: mediaRom

                    anchors.top: parent.top
                    anchors.topMargin: wholeScreen.height / 30
                    
                    width: parent.width
                    height: wholeScreen.width / 28.23

                    // Image
                    // {   
                    //     id: mediaIcon    

                    //     anchors.left: parent.left
                    //     anchors.leftMargin: wholeScreen.width / 38.4 

                    //     width: wholeScreen.width / 28.23 
                    //     height: wholeScreen.width / 28.23 

                    //     source: "assets/media_title.png"
                    //     fillMode: Image.PreserveAspectFit

                    //     MouseArea {
                    //         anchors.fill: parent

                    //         onDoubleClicked:
                    //         {
                    //             Qt.quit()
                    //         }

                    //     }
                    // }

                    Text
                    {
                        id: mediaText

                        anchors.top: wholeScreen.top
                        anchors.topMargin: wholeScreen.height / 30
                        // anchors.left: mediaIcon.right
                        // anchors.leftMargin: wholeScreen.width / 96
                        anchors.left: parent.left
                        anchors.leftMargin: wholeScreen.width / 38.4 

                        width: parent.width

                        text: i18n("Media")
                        elide: Text.ElideRight
                        color: '#FF000000'
                        font
                        {
                            // pointSize: theme.defaultFont.pointSize + 18
                            pixelSize: 25
                            bold: true
                        }

                        MouseArea {
                            anchors.fill: parent

                            onDoubleClicked:
                            {
                                Qt.quit()
                            }

                        }
                    }
                }

                Kirigami.JSearchField
                {
                    id: searchRect

                    anchors.top: mediaRom.bottom
                    anchors.topMargin: wholeScreen.height / 48
                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 38.4 - wholeScreen.width / 96

                    width: parent.width - parent.width / 6.4 + wholeScreen.width / 96

                    focus: false
                    placeholderText: ""
                    Accessible.name: i18n("Search")
                    Accessible.searchEdit: true
                    focusSequence: "Ctrl+F"

                    onRightActionTrigger:
                    {
                        setCurrentPage(currentPage, true)
                    }

                    onTextChanged:
                    {
                        if(currentPage <= 3)//视频
                        {
                            filterStatus = text
                            if(text != "")
                            {
                                videoGridView.model.list.searchQueriesVideos(text, currentPage)
                            }
                        }else if(currentPage >= 4)//音频
                        {
                            filterStatus = text
                            if(text != "")
                            {
                                musicGridView.model.list.searchQueries(text, currentPage)
                            }
                        }

                        if(filterStatus != "")
                        {
                            if(currentPage <= 3)//视频
                            {
                                if(videoGridView.model.getAll().length == 0)
                                {
                                    noResultState = true
                                    emptyRect.visible = true
                                }else
                                {
                                    noResultState = false
                                    emptyRect.visible = false
                                }
                            }else //音频
                            {
                                if(musicGridView.model.getAll().length == 0)
                                {
                                    noResultState = true
                                    emptyRect.visible = true
                                }else
                                {
                                    noResultState = false
                                    emptyRect.visible = false
                                }
                            }
                        }
                        else if(text == "")
                        {
                            setCurrentPage(currentPage, false)
                        }
                    }
                }

                Text
                {
                    id: videoText

                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 38.4 
                    anchors.top: searchRect.bottom
                    anchors.topMargin: wholeScreen.height / 21.42

                    width: parent.width

                    text: i18n("Video")
                    elide: Text.ElideRight
                    color: '#4D000000'
                    font
                    {
                        pixelSize: 12
                    }
                }

                Rectangle//video--All
                {
                    id: videoAllRow

                    anchors.top: videoText.bottom
                    anchors.topMargin: wholeScreen.height / 100
                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 76.8

                    width: parent.width - parent.width / 9.6
                    height: 39

                    color: currentPage == 1 ? "#FF43BDF4" : "#00000000"  
                    radius: 10

                    MouseArea 
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: 
                        {  
                            if(currentPage != 1)
                            {
                                setCurrentPage(1, true)
                            }
                        }

                        onEntered: //进入鼠标区域触发，悬浮属性为false，需点击才触发
                        {
                            if(currentPage != 1)
                            {
                                videoAllRow.color = "#29787880"
                            }
                            
                        } 
                        onExited: //退出鼠标区域(hoverEnabled得为true)，或者点击退出的时触发
                        {
                            if(currentPage != 1)
                            {
                                videoAllRow.color = "#00000000"
                            }
                        }   
                    }

                    Image
                    {   
                        id: videoAllIcon    

                        anchors.left: parent.left
                        anchors.leftMargin: wholeScreen.width / 76.8
                        anchors.verticalCenter: parent.verticalCenter

                        width: 16
                        height: 16

                        source: currentPage == 1 ? "assets/menu/video_all_select.png" : "assets/menu/video_all_unselect.png"
                        fillMode: Image.PreserveAspectFit
                    }

                    Text
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: videoAllIcon.right
                        anchors.leftMargin: wholeScreen.width / 96

                        width: parent.width

                        text: i18n("All")
                        elide: Text.ElideRight
                        color: currentPage == 1 ? '#FFFFFFFF' : '#FF000000'
                        font
                        {
                            pixelSize: 14
                        }
                    }
                }

                Rectangle//video--Lately
                {
                    id: videoLatelyRow

                    anchors.top: videoAllRow.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 76.8

                    width: parent.width - parent.width / 9.6
                    height: 39

                    color: currentPage == 3 ? "#FF43BDF4" : "#00000000"
                    radius: 10

                    MouseArea 
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: 
                        {  
                            if(currentPage != 3)
                            {
                                setCurrentPage(3, true)
                            }
                        }

                        onEntered: //进入鼠标区域触发，悬浮属性为false，需点击才触发
                        {
                            if(currentPage != 3)
                            {
                                videoLatelyRow.color = "#29787880"
                            }
                            
                        } 
                        onExited: //退出鼠标区域(hoverEnabled得为true)，或者点击退出的时触发
                        {
                            if(currentPage != 3)
                            {
                                videoLatelyRow.color = "#00000000"
                            }
                        } 
                    }

                    Image
                    {   
                        id: videoLatelyIcon    

                        anchors.left: parent.left
                        anchors.leftMargin: wholeScreen.width / 76.8
                        anchors.verticalCenter: parent.verticalCenter

                        width: 16
                        height: 16

                        source: currentPage == 3 ? "assets/menu/video_lately_select.png" : "assets/menu/video_lately_unselect.png"
                        fillMode: Image.PreserveAspectFit

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {  
                            }
                        }
                    }

                    Text
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: videoLatelyIcon.right
                        anchors.leftMargin: wholeScreen.width / 96

                        width: parent.width

                        text: i18n("Lately")
                        elide: Text.ElideRight
                        color: currentPage == 3 ? '#FFFFFFFF' : '#FF000000'
                        font
                        {
                            pixelSize: 14
                        }
                    }
                }

                //music start
                Text
                {
                    id: musicText

                    width: parent.width

                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 38.4 
                    anchors.top: videoLatelyRow.bottom
                    anchors.topMargin: wholeScreen.height / 15.38

                    text: i18n("Music")
                    elide: Text.ElideRight
                    color: '#4D000000'
                    font
                    {
                        pixelSize: 12
                    }
                }

                Rectangle//music--All
                {
                    id: musicAllRow

                    anchors.top: musicText.bottom
                    anchors.topMargin: wholeScreen.height / 100
                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 76.8

                    width: parent.width - parent.width / 9.6
                    height: 39

                    color: currentPage == 4 ? "#FF43BDF4" : "#00000000"
                    radius: 10

                    MouseArea 
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: 
                        {  
                            if(currentPage != 4)
                            {
                                setCurrentPage(4, true)
                            }
                        }

                        onEntered: //进入鼠标区域触发，悬浮属性为false，需点击才触发
                        {
                            if(currentPage != 4)
                            {
                                musicAllRow.color = "#29787880"
                            }
                            
                        } 
                        onExited: //退出鼠标区域(hoverEnabled得为true)，或者点击退出的时触发
                        {
                            if(currentPage != 4)
                            {
                                musicAllRow.color = "#00000000"
                            }
                        } 
                    }

                    Image
                    {   
                        id: musicAllIcon    

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: wholeScreen.width / 76.8

                        width: 16
                        height: 16

                        source: currentPage == 4 ? "assets/menu/music_all_select.png" : "assets/menu/music_all_unselect.png"
                        fillMode: Image.PreserveAspectFit
                    }

                    Text
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: musicAllIcon.right
                        anchors.leftMargin: wholeScreen.width / 96

                        width: parent.width

                        text: i18n("All")
                        elide: Text.ElideRight
                        color: currentPage == 4 ? '#FFFFFFFF' : '#FF000000'
                        font
                        {
                           pixelSize: 14
                        }

                    }
                }


                Rectangle//music--Like
                {
                    id: musicLikeRow

                    anchors.top: musicAllRow.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 76.8

                    width: parent.width - parent.width / 9.6
                    height: 39

                    color: currentPage == 5 ? "#FF43BDF4" : "#00000000"
                    radius: 10

                    MouseArea 
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: 
                        {  
                            if(currentPage != 5)
                            {
                                setCurrentPage(5, true)
                            }
                        }

                        onEntered: //进入鼠标区域触发，悬浮属性为false，需点击才触发
                        {
                            if(currentPage != 5)
                            {
                                musicLikeRow.color = "#29787880"
                            }
                            
                        } 

                        onExited: //退出鼠标区域(hoverEnabled得为true)，或者点击退出的时触发
                        {
                            if(currentPage != 5)
                            {
                                musicLikeRow.color = "#00000000"
                            }
                        } 
                    }

                    Image
                    {   
                        id: musicLikeIcon    

                        anchors.left: parent.left
                        anchors.leftMargin: wholeScreen.width / 76.8
                        anchors.verticalCenter: parent.verticalCenter

                        width: 16
                        height: 16

                        source: currentPage == 5 ? "assets/menu/music_like_select1.svg" : "assets/menu/music_like_unselect1.svg"
                        fillMode: Image.PreserveAspectFit

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {  
                            }
                        }
                    }

                    Text
                    {
                        width: parent.width

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: musicLikeIcon.right
                        anchors.leftMargin: wholeScreen.width / 96

                        text: i18n("Like")
                        elide: Text.ElideRight
                        color: currentPage == 5 ? '#FFFFFFFF' : '#FF000000'
                        font
                        {
                            pixelSize: 14
                        }
                    }
                }

                Rectangle//music--Lately
                {
                    id: musicLatelyRow

                    anchors.top: musicLikeRow.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: wholeScreen.width / 76.8

                    width: parent.width - parent.width / 9.6
                    height: 39

                    color: currentPage == 6 ? "#FF43BDF4" : "#00000000"
                    radius: 10

                    MouseArea 
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: 
                        {  
                            if(currentPage != 6)
                            {
                                setCurrentPage(6, true)
                            }
                        }

                        onEntered: //进入鼠标区域触发，悬浮属性为false，需点击才触发
                        {
                            if(currentPage != 6)
                            {
                                musicLatelyRow.color = "#29787880"
                            }
                            
                        } 
                        onExited: //退出鼠标区域(hoverEnabled得为true)，或者点击退出的时触发
                        {
                            if(currentPage != 6)
                            {
                                musicLatelyRow.color = "#00000000"
                            }
                        } 
                    }

                    Image
                    {   
                        id: musicLatelyIcon    

                        anchors.left: parent.left
                        anchors.leftMargin: wholeScreen.width / 76.8
                        anchors.verticalCenter: parent.verticalCenter

                        width: 16
                        height: 16
                        source: currentPage == 6 ? "assets/menu/music_lately_select.png" : "assets/menu/music_lately_unselect.png"
                        fillMode: Image.PreserveAspectFit

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {  
                            }
                        }
                    }

                    Text
                    {
                        width: parent.width

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: musicLatelyIcon.right
                        anchors.leftMargin: wholeScreen.width / 96

                        text: i18n("Lately")
                        elide: Text.ElideRight
                        color: currentPage == 6 ? '#FFFFFFFF' : '#FF000000'
                        font
                        {
                            pixelSize: 14
                        }
                    }
                }
                //music end
            }

            Rectangle//菜单右边主界面
            {
                width: wholeScreen.width - wholeScreen.width / 4.27 - (wholeScreen.height / 30 * 2)
                height: parent.height
                color: "#00000000"

                Kirigami.JIconButton//搜索的返回箭头
                {
                    id: backImage

                    anchors.top: parent.top
                    anchors.topMargin: wholeScreen.height / 30 + ((wholeScreen.width / 28.23 - (wholeScreen.width / 43.63 + wholeScreen.height / 120))) / 2

                    width: 22 + 10
                    height: 22 + 10

                    source: "qrc:/assets/back_arrow.png"

                    visible:
                    {
                        if((filterStatus != "") && (!musicSelectionMode && !videoSelectionMode))
                        {
                            true
                        }else
                        {
                            false
                        }
                    }
                        onClicked: 
                        {
                            setCurrentPage(currentPage, true)
                        }
                }

                Text//顶部Title
                {
                    id: contentTitle

                    anchors.left: 
                    {
                        if(filterStatus != "")
                        {
                            backImage.right
                        }else
                        {
                            parent.left
                        }
                    }
                    anchors.leftMargin: 
                    {
                        if(filterStatus != "")
                        {
                            10
                        }else
                        {
                            0
                        }
                    }
                    anchors.top: parent.top
                    anchors.topMargin: wholeScreen.height / 30

                    height: wholeScreen.width / 28.23

                    visible: !musicSelectionMode && !videoSelectionMode            
                    text:
                    {
                        if(filterStatus != "")
                        {
                            i18n("Search Results")    
                        }else if(currentPage == 1 || currentPage == 4)
                        {
                           i18n("All")
                        }else if(currentPage == 2 || currentPage == 5)
                        {
                            i18n("Like")
                        }else if(currentPage == 3 || currentPage == 6)
                        {
                            i18n("Lately")
                        }
                    }
                    elide: Text.ElideRight
                    color: '#FF000000'
                    font
                    {
                        pixelSize: 25
                        bold: true
                    }
                    
                }

                Rectangle//编辑态的UI
                {
                    anchors.top: parent.top
                    anchors.topMargin: wholeScreen.height / 30

                    width: parent.width - wholeScreen.width / 48
                    height: wholeScreen.height / 17.64

                    visible: musicSelectionMode || videoSelectionMode
                    color: "#00000000"

                    // Image {//全选
                    Kirigami.JIconButton {
                        id: selectAllImage

                        anchors.verticalCenter: parent.verticalCenter

                        width: 22 + 10
                        height: 22 + 10

                        source: 
                        {
                                "qrc:/assets/check_status.png"
                        }
                        
                        // MouseArea {
                            // anchors.fill: parent
                            onClicked: {  
                                if(musicSelectionMode)//音乐
                                {
                                    if(_selectionBar.items.length == musicGridView.model.getAll().length)
                                    {
                                        _selectionBar.clear()
                                    }else
                                    {
                                        _selectionBar.clear()
                                        // for(var i = 0; i < musicGridView.model.getAll().length; i++)
                                        // {
                                        //     H.addToSelection(musicGridView.model.get(i))
                                        // }  
                                        selectAll(2)
                                    }
                                    selectCountText.text = _selectionBar.items.length
                                }else if(videoSelectionMode)//视频
                                {
                                    if(_selectionBar.items.length == videoGridView.model.getAll().length)
                                    {
                                        _selectionBar.clear()
                                    }else
                                    {
                                        _selectionBar.clear()
                                        // for(var i = 0; i < videoGridView.model.getAll().length; i++)
                                        // {
                                        //     H.addToSelection(videoGridView.model.get(i))
                                        // }  
                                        selectAll(1)
                                    }
                                    selectCountText.text = _selectionBar.items.length
                                }   
                            }
                        // }

                        Connections
                        {
                            target: _selectionBar

                            onUriRemoved:
                            {
                                if(_selectionBar.items.length == 0)
                                {
                                    selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
                                    // saveImage.source = "assets/save.png"
                                    deleteImage.source = "qrc:/assets/delete.png"
                                }
                                else if((currentPage < 4 && _selectionBar.items.length == videoGridView.model.getAll().length) || (currentPage >= 4 && _selectionBar.items.length == musicGridView.model.getAll().length))
                                {
                                    selectAllImage.source = "qrc:/assets/select_rect.png"
                                    deleteImage.source = "qrc:/assets/delete_enable.png"
                                }
                                else
                                {
                                    selectAllImage.source = "qrc:/assets/check_status_enable.png"
                                    deleteImage.source = "qrc:/assets/delete_enable.png"
                                }                                 
                            }

                            onUriAdded:
                            {
                                if(_selectionBar.items.length == 0)
                                {
                                    selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
                                    // saveImage.source = "assets/save.png"
                                    deleteImage.source = "qrc:/assets/delete.png"
                                }else if((currentPage < 4 && _selectionBar.items.length == videoGridView.model.getAll().length) || (currentPage >= 4 && _selectionBar.items.length == musicGridView.model.getAll().length))
                                {
                                    selectAllImage.source = "qrc:/assets/select_rect.png"
                                    deleteImage.source = "qrc:/assets/delete_enable.png"
                                }else
                                {
                                    selectAllImage.source = "qrc:/assets/check_status_enable.png"
                                    deleteImage.source = "qrc:/assets/delete_enable.png"
                                }
                            }

                            onCleared:
                            {
                                selectAllImage.source = "qrc:/assets/unselect_rect_enable.png"
                                // saveImage.source = "assets/save.png"
                                deleteImage.source = "qrc:/assets/delete.png"
                            }
                        }
                    }
                    Text {
                        id: selectCountText
                        anchors.left: selectAllImage.right
                        anchors.leftMargin: wholeScreen.width / 192
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 14
                        text: "1"
                        color: "#FF000000"
                    }

                    // Image {//批量存储文件
                    //     id: saveImage

                    //     anchors.verticalCenter: parent.verticalCenter
                    //     anchors.left: selectAllImage.right
                    //     anchors.leftMargin: wholeScreen.width / 4.43

                    //     width: wholeScreen.width / 43.63
                    //     height: wholeScreen.width / 43.63
                    //     source: "assets/save.png"
                    // }

                    // Image {//批量删除文件
                    Kirigami.JIconButton{
                        id: deleteImage

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: selectAllImage.right
                        anchors.leftMargin: (parent.width - width) / 2 - width

                        width: 22 + 10
                        height: 22 + 10

                        source: "qrc:/assets/delete.png"

                        // MouseArea {
                            // anchors.fill: parent
                            onClicked: {  
                                    if(_selectionBar.items.length > 0)
                                    {
                                        if(musicSelectionMode)
                                        {
                                            if(_selectionBar.items.length ==  1)
                                            {
                                                jDialog.text = i18n("Are you sure you want to delete the file?")
                                            }else if(_selectionBar.items.length > 1)
                                            {
                                                jDialog.text =  i18n("Are you sure you want to delete these files?")
                                            }
                                            jDialogType = 8
                                            jDialog.open()
                                        }else if(videoSelectionMode)
                                        {
                                            if(_selectionBar.items.length ==  1)
                                            {
                                                jDialog.text = i18n("Are you sure you want to delete the file?")
                                            }else if(_selectionBar.items.length > 1)
                                            {
                                                jDialog.text =  i18n("Are you sure you want to delete these files?")
                                            }
                                            jDialogType = 4
                                            jDialog.open()
                                        }
                                    }
                            }
                        // }
                    }

                    // Image {//取消编辑态
                    Kirigami.JIconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right

                        width: 22 + 10
                        height: 22 + 10

                        source: "qrc:/assets/cancel_enable.png"
                        
                        // MouseArea {
                            // anchors.fill: parent
                            onClicked: {  
                                cancelEdit()
                            }
                        // }
                    }
                }

                GridView //音乐内容列表
                {
                    id: musicGridView
                    
                    anchors.top: contentTitle.bottom
                    anchors.topMargin: wholeScreen.height / 48
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right   

                    width: parent.width
                    height: parent.height 
                    
                    cellWidth: parent.width / 2
                    cellHeight: (wholeScreen.width / 2.85 - wholeScreen.height / 60) / 4.37 + wholeScreen.height / 80//wholeScreen.height / 7 - wholeScreen.height / 80
                    delegate: musicDelegate
                    focus: true
                    clip: true
                    cacheBuffer: height * 1.5   
                    visible:
                    {
                        if(currentPage >= 4)
                        {
                            true
                        }else
                        {
                            false
                        }
                    }
                    
                    model:
                    {
                        myTracksModel
                    }

                    footer: ItemDelegate//因为播放时有底部播放器盖在最上层，会导致列表最底部被遮住。所以给一个同样高度的footer。避免这个问题
                    {
                        width: parent.width
                        height: 
                        {
                            if(visible)
                            {
                                playBarFooter.height
                            }else
                            {
                                0
                            }         
                        }

                        visible: 
                        {
                            if(currentPage >= 4 && currentTrack)
                            {
                                true
                            }else
                            {
                                false
                            }
                        }

                        background:Rectangle
                        {
                            color:"#00000000"
                        }
                    }

                    Connections
                    {
                        target: Vvave.Vvave
                        onPlayThirdMusic: //播放外部传入的音乐
                        {
                            
                            setCurrentPage(4, true)
                            var index = 0
                            for(var i = 0; i < musicGridView.model.getAll().length; i++)
                            {
                                if(source === musicGridView.model.get(i).url)
                                {
                                    index = i
                                    break
                                }
                            }

                            musicGridView.currentIndex = index
                            clearPlayList()
                            Player.appendAll(musicGridView.model.getAll())
                            Player.playAt(index)
                            isFav()
                            currentPlayPage = currentPage;
                        }
                    }

                    // Connections
                    // {
                    //     target: Vvave.Vvave
                    //     onRefreshTables: 
                    //     {
                    //         // setCurrentPage(currentPage, true)
                    //         if(currentPage == 4)
                    //         {
                    //             musicGridView.model.list.query = Q.GET.allTracks
                    //         }   
                            
                    //     }
                    // }
                }
                Component 
                {
                    id: musicDelegate

                    Rectangle {
                        id: wapper

                        width: wholeScreen.width / 2.85 - wholeScreen.height / 60
                        height: width / 4.37

                        property bool checked
                        checked: selectionBar.contains(model.url)
                        color: "#FFFFFFFF"
                        radius: 10

                        Rectangle{ 
                            id:imageRect

                            anchors.top: parent.top
                            anchors.left: parent.left
                            
                            width: wapper.height
                            height: wapper.height

                            radius: 10

                            Image {
                                id: coverImage

                                anchors.fill: parent

                                source:
                                {
                                    (path == "file://") ?  "assets/cover_default.png" : path
                                }
                                visible: false

                                property string path
                                Component.onCompleted:
                                {
                                    path = musicGridView.model.get(index).genre
                                }
                            }
                            Rectangle{
                                id:themask

                                anchors.fill: parent

                                radius: 10
                                visible: false
                            }
                            OpacityMask{
                                source: coverImage
                                maskSource: themask
                                anchors.fill: coverImage
                                visible: true
                            }
                        }
                        
                        Rectangle//音乐的信息
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: imageRect.right
                            anchors.leftMargin: wholeScreen.width / 64

                            width: wapper.width - wapper.height - wholeScreen.width / 64 - wholeScreen.width / 43.63 - wholeScreen.width / 106.67 * 2
                            height: wapper.height - wholeScreen.height / 60 * 2
                            
                            clip: false

                            Text {
                                id:name

                                anchors.left: parent.left
                                anchors.bottom: album.top
                                anchors.bottomMargin: wholeScreen.height / 150

                                width: parent.width

                                font.pixelSize: 14
                                text: model.title
                                color: 
                                {
                                    if(currentPlayPage == currentPage && currentTrack && currentTrack.title == model.title && currentTrack.adddate == model.adddate)
                                    {
                                        "#FF43BDF4"
                                    }else
                                    {
                                        "#FF000000"
                                    }
                                }
                                elide: Text.ElideRight
                            }

                            AnimatedImage
                            {
                                id: gifImage

                                width: 10
                                height: width

                                fillMode: Image.PreserveAspectFit

                                anchors.bottom: album.top
                                anchors.bottomMargin: wholeScreen.height / 150 + 5
                                anchors.left: parent.left
                                anchors.leftMargin: name.contentWidth + 10

                                source: "qrc:/assets/playing.gif"

                                visible: currentPlayPage == currentPage && currentTrack && currentTrack.title == model.title && currentTrack.adddate == model.adddate

                                playing: visible && player.playing
                            }

                            Text {
                                id:album

                                anchors.verticalCenter: parent.verticalCenter

                                width: wapper.width - wapper.height - wholeScreen.width / 64 - wholeScreen.width / 43.63 - wholeScreen.width / 106.67 * 2

                                text: //如果都是未知的 只展示一个UNKNOWN   如果是只识别到一个，另外一个没有识别到的就不写了
                                {
                                    if(model.artist == "UNKNOWN" && model.album == "UNKNOWN")
                                    {
                                        i18n(model.artist)
                                    }else if(model.artist != "UNKNOWN" && model.album == "UNKNOWN")
                                    {
                                        i18n(model.artist)
                                    }else if(model.artist == "UNKNOWN" && model.album != "UNKNOWN")
                                    {
                                        "《" + i18n(model.album) + "》"
                                    }else
                                    {
                                        i18n(model.artist) + " · 《" + i18n(model.album) + "》"
                                    }
                                }
                                font.pixelSize: 10
                                color: 
                                {
                                    if(currentPlayPage == currentPage && currentTrack && currentTrack.title == model.title && currentTrack.adddate == model.adddate)
                                    {
                                        "#FF43BDF4"
                                    }else
                                    {
                                        "#FF8E8E93"
                                    }
                                }
                                elide: Text.ElideRight
                            }

                            Text {
                                id: duration

                                anchors.top: album.bottom
                                anchors.topMargin: wholeScreen.height / 150

                                text: player.transformTime(model.duration) 
                                font.pixelSize: 10
                                color: 
                                {
                                    //if(currentPlayPage == currentPage && currentTrack && currentTrackIndex == index)
                                    if(currentPlayPage == currentPage && currentTrack && currentTrack.title == model.title && currentTrack.adddate == model.adddate)
                                    {
                                        "#FF43BDF4"
                                    }else
                                    {
                                        "#FF8E8E93"
                                    }
                                }
                            }
                        }

                        Image //编辑态时的选中 非选中状态
                        {
                            id: checkStatusImage

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 9

                            width: 22
                            height: 22

                            cache: false
                            source: 
                            {
                                if(checked)
                                {
                                    "assets/select_rect.png"
                                }else{
                                    "assets/unselect_rect.png"
                                }
                            }
                            
                            visible: 
                            {
                                if(musicSelectionMode)
                                {
                                    true
                                }else
                                {
                                    false
                                }
                            } 
                        }

                        Connections
                        {
                            target: _selectionBar

                            onUriRemoved:
                            {
                                if(uri === model.url)
                                    wapper.checked = false
                            }

                            onUriAdded:
                            {
                                if(uri === model.url)
                                    wapper.checked = true
                            }

                            onCleared: wapper.checked = false
                        }

                        Kirigami.JMouseHoverMask
                        {
                            anchors.fill: parent

                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            radius: 9
                            onPressAndHold:
                            {
                                if(!musicSelectionMode)
                                {
                                    musicGridView.currentIndex = index
                                    var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                                    musicPopup.popup(wholeScreen, test.x, test.y)
                                }
                            }

                            onClicked:
                            {
                                if (mouse.button == Qt.RightButton) 
                                { 
                                    if(!musicSelectionMode)
                                    {
                                        musicGridView.currentIndex = index
                                        var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                                        musicPopup.popup(wholeScreen, test.x, test.y)
                                    }
                                }else if(mouse.button == Qt.LeftButton)
                                {
                                    if(musicSelectionMode)//编辑态
                                    {
                                        musicGridView.currentIndex = index
                                        H.addToSelection(musicGridView.model.get(index))
                                        selectCountText.text = _selectionBar.items.length
                                    }else
                                    {
                                        searchRect.focus = false
                                        musicGridView.currentIndex = index
                                        clearPlayList()
                                        Player.appendAll(musicGridView.model.getAll())
                                        Player.playAt(index)
                                        isFav()
                                        currentPlayPage = currentPage;   
                                    } 
                                }
                            }
                        }
                    }
                }

                GridView //视频内容列表
                {
                    id: videoGridView

                    anchors.top: contentTitle.bottom
                    anchors.topMargin: wholeScreen.height / 48
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    
                    width: parent.width
                    height: parent.height

                    visible:
                    {
                        if(currentPage <= 3)
                        {
                            true
                        }else
                        {
                            false
                        }
                    }

                    model:
                    {
                        myVideosModel
                    }

                    cacheBuffer: height * 1.5
                    clip: true
                    cellWidth: parent.width / 4
                    cellHeight: (wholeScreen.width / 5.82 - wholeScreen.height / 120) / 16 * 9 + wholeScreen.height / 17.64 + wholeScreen.height / 35.29 + wholeScreen.height / 120//206 + 68 + 34
                    delegate: videoDelegate

                    Component.onCompleted://首页是视频 UI完毕后 填充数据
                    {
                        model.list.query = Q.GET.allVideos
                    }

                    Connections
                    {
                        target: Vvave.Vvave
                        onRefreshTables: 
                        {
                            // setCurrentPage(currentPage, true)
                            if(currentPage == 1)
                            {
                                videoGridView.model.list.query = Q.GET.allVideos
                            }
                        }
                    }
                }
                Component 
                {
                    id: videoDelegate

                    Rectangle {
                        id: wapper

                        width: wholeScreen.width / 5.82 - wholeScreen.height / 120
                        height: width / 16 * 10

                        property bool checked
                        checked: false//selectionBar.contains(model.url)
                        color: "#00000000"
                        radius: 8

                        Rectangle{ 
                            id:imageRect

                            anchors.top: parent.top
                            anchors.left: parent.left
                            
                            width: wapper.width
                            height: width / 16 * 9

                            radius: 8

                            Image {
                                id:theimage

                                anchors.fill: parent

                                source:
                                {
                                    (path == "file://") ?  "assets/video_cover/cover1.png" : path
                                }
                                visible: false
                                
                                property string path
                                Component.onCompleted:
                                {
                                    path = videoGridView.model.get(index).genre
                                }
                            }

                            Rectangle{
                                id:themask

                                anchors.fill: parent

                                radius: 8
                                visible: false
                            }

                            OpacityMask{
                                anchors.fill: theimage

                                source: theimage
                                maskSource: themask
                            }

                            Kirigami.JMouseHoverMask
                            {
                                anchors.fill: parent

                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                radius: 10

                                onPressAndHold:
                                {
                                    if(!videoSelectionMode)
                                    {
                                        videoGridView.currentIndex = index
                                        var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                                        videoPopup.popup(wholeScreen, test.x, test.y)
                                    }
                                }

                                onClicked:
                                {
                                    if (mouse.button == Qt.RightButton)
                                    {
                                        if(!videoSelectionMode)
                                        {
                                            videoGridView.currentIndex = index
                                            var test = mapToItem(wholeScreen, mouse.x, mouse.y)
                                            videoPopup.popup(wholeScreen, test.x, test.y)
                                        } 
                                    }else if(mouse.button == Qt.LeftButton)
                                    {
                                        if(videoSelectionMode)//编辑态
                                        {
                                            videoGridView.currentIndex = index
                                            H.addToSelection(videoGridView.model.get(index))
                                            selectCountText.text = _selectionBar.items.length
                                        }else
                                        {
                                            videoGridView.currentIndex = index
                                            player.playing = false
                                            musicGridView.model.list.emitpPlayingState(player.playing)
                                            searchRect.focus = false
                                            videoGridView.model.list.countUpVideos(index, true)
                                            if(videoGridView.model.list.updateHarunaArguments(index))//组织参数
                                            {
                                                videoGridView.model.list.playVideo()
                                            }
                                        }  
                                    }          
                                }
                            }
                        }
                        
                        Text {
                            id:name

                            anchors.top: imageRect.bottom
                            anchors.topMargin: wholeScreen.height / 150

                            width: parent.width - wholeScreen.width / 192

                            font.pixelSize: 14
                            text: model.title
                            color: "#FF000000"
                            lineHeight: 1//0.7显小
                            wrapMode: Text.WrapAnywhere //WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }

                        Image {
                            id:playIcon

                            anchors.bottom: imageRect.bottom
                            anchors.bottomMargin: 6
                            anchors.left: imageRect.left
                            anchors.leftMargin: 6
                            width: 18
                            height: 18
                            
                            source: "assets/video_mode_icon.png"
                            visible: !videoSelectionMode
                        }

                        Text {
                            id: duration

                            anchors.right: imageRect.right
                            anchors.rightMargin: 6//wholeScreen.width / 128
                            anchors.bottom: imageRect.bottom
                            anchors.bottomMargin: 6//wholeScreen.height / 70.59

                            text: player.transformTime(model.duration) 
                            font.pixelSize: 11
                            color: "#E6FFFFFF"
                            visible: !videoSelectionMode
                        }

                        Image //编辑态时的选中 非选中状态
                        {
                            id: checkStatusImage

                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.bottom: imageRect.bottom
                            anchors.bottomMargin: wholeScreen.width / 192

                            width: 22
                            height: 22

                            cache: false
                            source: 
                            {
                                if(checked)
                                {
                                    "assets/select_rect.png"
                                }else{
                                    "assets/unselect_rect.png"
                                }
                            }
                            
                            visible: 
                            {
                                if(videoSelectionMode)
                                {
                                    true
                                }else
                                {
                                    false
                                }
                            }
                        }

                        Connections
                        {
                            target: _selectionBar

                            onUriRemoved:
                            {
                                if(uri === model.url)
                                    wapper.checked = false
                            }

                            onUriAdded:
                            {
                                if(uri === model.url)
                                    wapper.checked = true
                            }

                            onCleared: wapper.checked = false
                        }
                    }
                }

                Item//空页面UI
                {
                    id: emptyRect

                    anchors.top: contentTitle.bottom
                    anchors.topMargin: wholeScreen.height / 48
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right   

                    width: parent.width
                    height: parent.height 

                    visible: false

                    Image
                    {
                        id: emptyIcon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 310//(572 + 120) / 2 

                        width: 60
                        height: width

                        source: 
                        {
                            if(noResultState)
                            {
                                "assets/search_empty.png"
                            }else
                            {
                                if(currentPage <= 3)
                                {
                                    "assets/video_empty.png"
                                }else
                                {
                                    "assets/music_empty.png"
                                }
                            }
                        }
                    }

                    Text {
                        anchors.top: emptyIcon.bottom
                        anchors.topMargin: 15
                        anchors.horizontalCenter: parent.horizontalCenter

                        font.pixelSize: 14
                        text:
                        {
                            if(noResultState)
                            {
                                i18n("Sorry,there are no search results.")
                            }else
                            {
                                if(currentPage <= 3)
                                {
                                    i18n("There is no video at present")
                                }else
                                {
                                    i18n("There is no music at present")
                                }
                            }
                        }
                        color: "#4D3C3C43"
                    }
                }
            }
        }
    }

    Rectangle//2.0 底部播放器
    {
        id: playBarFooter

        anchors.bottom: wholeScreen.bottom

        width: wholeScreen.width
        height: 81//wholeScreen.height / 7.41

        color: "#00000000"
        visible: 
        {
            if(currentPage >= 4 && currentTrack)
            {
                true
            }else
            {
                false
            }
        }
        
        Rectangle
        {
            width: parent.width//wholeScreen.width
            height: parent.height//wholeScreen.height / 7.41

            color: "#00000000"

            MouseArea//被播放器遮住item还可以响应右键菜单 hover效果 点击等鼠标操作 这里直接拦截掉 以避免这个问题
            {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: 
                {
                }
            }

            ShaderEffectSource
            {
                id: footerBlur

                width: parent.width

                visible: false
                height: parent.height
                sourceItem: wholeScreen
                sourceRect: Qt.rect(0, wholeScreen.height - height, width, height)
            }

            FastBlur{
                id:fastBlur

                anchors.fill: parent

                source: footerBlur
                radius: 50//128
                cached: true
                visible: false
            }
            Rectangle{
                id:maskRect

                anchors.fill:fastBlur

                visible: false
                clip: true
            }
            OpacityMask{
                id:mask

                anchors.fill: maskRect

                visible: true
                source: fastBlur
                maskSource: maskRect
            }

            Rectangle{
                anchors.fill: footerBlur
                color: "#DDF0F0F0"
            }

            Rectangle{ //歌曲封面
                id:currentIcon

                anchors.left: parent.left
                anchors.leftMargin: 14//wholeScreen.width / 50.53
                anchors.verticalCenter: parent.verticalCenter

                width: 56//wholeScreen.height / 14.29
                height: 56//wholeScreen.height / 14.29

                radius: 4

                Image {
                    id: currentCoverImage

                    anchors.fill: parent

                    source: currentCover
                    visible: false
                }

                Rectangle{
                    id:currentThemask

                    anchors.fill: parent

                    radius: 4
                    visible: false
                }

                OpacityMask{
                    anchors.fill: currentCoverImage

                    source: currentCoverImage
                    maskSource: currentThemask
                    visible: true
                }
            }
            
            Image
            {
                id: play_right

                anchors.left: currentIcon.right
                anchors.verticalCenter: parent.verticalCenter

                width: 15//wholeScreen.width / 80
                height: currentIcon.height//wholeScreen.height / 14.29

                source: "assets/play_right.png"
            }

            Text {//歌曲名称
                id:currentName

                anchors.left: play_right.right
                anchors.leftMargin: 16//wholeScreen.width / 80
                anchors.top: parent.top
                anchors.topMargin: wholeScreen.height / 30

                width: 145//wholeScreen.width / 6.62

                font.pixelSize: 17
                text: currentTrack ? currentTrack.title : ""
                color: "#FF000000"
                elide: Text.ElideRight
            }

            Text {//演唱者和专辑
                id:currentAlbum

                anchors.left: play_right.right
                anchors.leftMargin: 16//wholeScreen.width / 80
                anchors.top: currentName.bottom
                anchors.topMargin: wholeScreen.height / 200

                width: 145//wholeScreen.width / 6.62

                text: //currentTrack ? (currentTrack.artist + " · 《" + currentTrack.album + "》") : ""
                {
                    if(currentTrack)
                    {
                        if(currentTrack.artist == "UNKNOWN" && currentTrack.album == "UNKNOWN")
                        {
                            i18n(currentTrack.artist)
                        }else if(currentTrack.artist != "UNKNOWN" && currentTrack.album == "UNKNOWN")
                        {
                            i18n(currentTrack.artist)
                        }else if(currentTrack.artist == "UNKNOWN" && currentTrack.album != "UNKNOWN")
                        {
                            "《" + i18n(currentTrack.album) + "》"
                        }else
                        {
                            i18n(currentTrack.artist) + " · 《" + i18n(currentTrack.album) + "》"
                        }
                    }
                }
                font.pixelSize: 11
                color: "#99000000"
                elide: Text.ElideRight
            }

            Kirigami.JIconButton//播放模式
            {
                id: currentType

                anchors.left: currentName.right
                anchors.leftMargin: 30//wholeScreen.width / 28.23 / 2
                anchors.verticalCenter: parent.verticalCenter

                width: 22 + 10
                height: 22 + 10

                source:
                {
                    if(playType === 0)//循环播放
                    {
                        "qrc:/assets/loop.png"
                    }else if(playType === 1)//随机播放
                    {
                        "qrc:/assets/shuffle.png"
                    }else if(playType === 2){//单曲循环
                        "qrc:/assets/repeat_one.png"
                    }
                }
                

                    onClicked: 
                    {
                        playType++
                        if(playType > 2)
                        {
                            playType = 0;
                        }
                        Maui.FM.saveSettings("SHUFFLE", playType, "PLAYBACK")
                    }

                Component.onCompleted:
                {
                    Maui.FM.loadSettings("SHUFFLE","PLAYBACK", 0)
                }
            }
                                                                        
            Kirigami.JIconButton//添加和取消喜欢
            {
                id: currentFav

                anchors.left: currentType.right
                anchors.leftMargin: 30
                anchors.verticalCenter: parent.verticalCenter

                width: 22 + 10
                height: 22 + 10

                source: fav ? "qrc:/assets/fav.png" : "qrc:/assets/unfav.png"

                    onClicked: 
                    {
                        if (!mainlistEmpty)
                        {
                            mainPlaylist.listModel.list.fav(currentTrackIndex, !Maui.FM.isFav(currentTrack.url))
                            isFav()
                            if(currentPage === 5)
                            {
                                musicGridView.model.list.refresh()
                            }
                        }
                    }
            }

            Rectangle//播放进度条
            {
                id: currentTime

                anchors.left: currentFav.right
                anchors.leftMargin: 30//wholeScreen.width / 32
                
                
                width: wholeScreen.width / 2.96//300//wholeScreen.width / 3.01 + wholeScreen.width / 73.85 + wholeScreen.width / 16 - wholeScreen.width / 40.85 //260
                height: parent.height//wholeScreen.height / 7.41

                color: "#00000000"
                
                Rectangle//播放进度条
                {
                    id: playBar

                    width: currentTime.width                    
                    height: parent.height

                    visible: true
                    color: "#00000000"
                    
                    Slider
                    {
                        id: progressBar

                        property bool seekStarted: false

                        anchors.verticalCenter: parent.verticalCenter

                        width: currentTime.width - _label2.width - wholeScreen.width / 38.4

                        z: parent.z + 1
                        from: 0
                        to: 1000
                        // value: player.pos
                        spacing: 0
                        focus: true
                        // onMoved: player.pos = value
                        enabled: true//player.playing
                        
                        handle: Rectangle//选中拖动时候的效果
                        {
                            id: handleRect

                            anchors.verticalCenter:parent.verticalCenter

                            width: wholeScreen.width / 41.74
                            height: wholeScreen.height / 30

                            x: progressBar.leftPadding + progressBar.visualPosition
                            * (progressBar.availableWidth - width)
                            y: 0
                            color: 
                            {
                                "#FFFFFFFF"
                            }
                            radius: 4
                        }

                        DropShadow
                        {
                            anchors.fill: handleRect

                            radius: 4
                            samples: 16
                            color: "#50000000"
                            source: handleRect
                        }

                        background: Rectangle
                        {
                            id: rect1

                            anchors.verticalCenter: parent.verticalCenter

                            width: progressBar.availableWidth
                            height: wholeScreen.height / 120

                            color: "#3E3C3C43"
                            opacity: 0.4
                            radius: 2

                            Rectangle
                            {
                                id: rect2

                                width: progressBar.visualPosition * parent.width
                                height: wholeScreen.height / 120

                                color: "#FF43BDF4"
                                radius: 2
                            }
                        }

                        onPressedChanged: {
                            if (pressed) {
                                progressBar.seekStarted = true
                            } else {
                                player.pos = progressBar.value
                                progressBar.seekStarted = false
                            }
                        }

                        Connections {
                            target: player
                            onPosChanged: {
                                if (!progressBar.seekStarted) {
                                    progressBar.value = player.pos
                                }
                            }
                        }
                    }

                    Text//播放时间
                    {
                        id: _label2

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        visible: text.length
                        text: progressTimeLabel + "/" + player.transformTime(player.duration/1000)
                        elide: Text.ElideMiddle
                        wrapMode: Text.NoWrap
                        color: "#FF8E8E93"
                        font.weight: Font.Normal
                        font.pixelSize: 11
                        opacity: 0.7
                        
                        Component.onCompleted: {
                            _label2.width = contentWidth
                        }
                    }
                }

            }

            Kirigami.JIconButton//上一首
            {
                id: previousImage

                anchors.left: currentTime.right
                anchors.leftMargin: 30//wholeScreen.width / 27.43
                anchors.verticalCenter: parent.verticalCenter

                width: 22 + 10
                height: 22 + 10

                source: "qrc:/assets/previousTrack.png"

                    onClicked: 
                    {
                        Player.previousTrack()
                        isFav()
                    }
            }

            Kirigami.JIconButton//播放 暂停
            {
                id: playImage

                anchors.left: previousImage.right
                anchors.leftMargin: 30//wholeScreen.width / 29.09
                anchors.verticalCenter: parent.verticalCenter

                width: 30 + 10
                height: 30 + 10
                source: isPlaying ? "qrc:/assets/pause.png" : "qrc:/assets/play.png" 
                

                onClicked: 
                {
                    player.playing = !player.playing
                    musicGridView.model.list.emitpPlayingState(player.playing)
                }
            }
            
            Kirigami.JIconButton//下一首
            {
                id: nextTrackImage

                anchors.left: playImage.right
                anchors.leftMargin: 30//wholeScreen.width / 29.09
                anchors.verticalCenter: parent.verticalCenter

                width: 22 + 10
                height: 22 + 10

                source: "qrc:/assets/nextTrack.png"
                
                onClicked: 
                {
                    Player.nextTrack(false)
                    isFav()
                }
            }

        }
    }

    property Action playPauseAction: Action {//监听空格
        id: playPauseAction
        text: qsTr("Play/Pause")
        icon.name: "media-playback-pause"
        shortcut: "Space"

        onTriggered:
        {
            if(playBarFooter.visible)
            {
                player.playing = !player.playing
                musicGridView.model.list.emitpPlayingState(player.playing)
            }
        }
    }
    
    property string playlistQuery

    function populate(query, isPublic)
    {
        if(query == Q.GET.babedTracks || query == Q.GET.mostPlayedTracks)
        {
            musicGridView.model.list.sortBy = Tracks.RELEASEDATE
        }else{
            musicGridView.model.list.sortBy = Tracks.ADDDATE
        }
        playlistQuery = query
        musicGridView.model.list.query = playlistQuery
        filterStatus = ""
    }

    function populateVideo(query, isPublic)
    {
        if(query == Q.GET.mostPlayedVideos)
        {
            videoGridView.model.list.sortBy = Videos.RELEASEDATE
        }else
        {
            videoGridView.model.list.sortBy = Tracks.ADDDATE
        }
        videoGridView.model.list.query = query
        filterStatus = ""
    }

    property bool fav
    property var currentCover
    function isFav()
    {
        fav = currentTrack ? Maui.FM.isFav(currentTrack.url) : false
        //获取当前播放的歌曲封面路径
        var musicGenre = musicGridView.model.get(currentTrackIndex).genre
        if(musicGenre == "file://")
        {
            currentCover = "assets/cover_default.png"
        }else
        {
            currentCover = musicGenre
        }
    }

    function clearPlayList()
    {
        player.stop()
        mainPlaylist.table.list.clear()
        root.sync = false
        root.syncPlaylist = ""
    }

    function cancelEdit()
    {
        if(musicSelectionMode)
        {
            musicSelectionMode = false
        }

        if(videoSelectionMode)
        {
            videoSelectionMode = false
        }
        _selectionBar.clear()
    }

    function setCurrentPage(index, cancelFocus)
    {
        if(cancelFocus)
        {
            searchRect.focus = false
        }
        switch (index) 
        {
            case 1://video all
            {
                currentPage = 1
                videoAllRow.color = "#FF43BDF4"
                videoLatelyRow.color = "#00000000"
                musicAllRow.color = "#00000000"
                musicLikeRow.color = "#00000000"
                musicLatelyRow.color = "#00000000"
                populateVideo(Q.GET.allVideos, false);
                break
            }
            case 3://video lately
            {
                currentPage = 3
                videoAllRow.color = "#00000000"
                videoLatelyRow.color = "#FF43BDF4"
                musicAllRow.color = "#00000000"
                musicLikeRow.color = "#00000000"
                musicLatelyRow.color = "#00000000"
                populateVideo(Q.GET.mostPlayedVideos, false);
                break
            }
            case 4://music all
            {
                currentPage = 4
                videoAllRow.color = "#00000000"
                videoLatelyRow.color = "#00000000"
                musicAllRow.color = "#FF43BDF4"
                musicLikeRow.color = "#00000000"
                musicLatelyRow.color = "#00000000"
                populate(Q.GET.allTracks, false);
                break
            }
            case 5://music like
            {
                currentPage = 5
                videoAllRow.color = "#00000000"
                videoLatelyRow.color = "#00000000"
                musicAllRow.color = "#00000000"
                musicLikeRow.color = "#FF43BDF4"
                musicLatelyRow.color = "#00000000"
                populate(Q.GET.babedTracks, false);
                break
            }
            case 6://music lately
            {
                currentPage = 6
                videoAllRow.color = "#00000000"
                videoLatelyRow.color = "#00000000"
                musicAllRow.color = "#00000000"
                musicLikeRow.color = "#00000000"
                musicLatelyRow.color = "#FF43BDF4"
                populate(Q.GET.mostPlayedTracks, false);
                break
            }
        }
        searchRect.clear()
        filterStatus = ""
        noResultState = false
        cancelEdit()

    
        if(currentPage <= 3)
        {
            if(videoGridView.model.getAll().length == 0)
            {
                emptyRect.visible = true
            }else
            {
                emptyRect.visible = false
            }
        }else
        {
            if(musicGridView.model.getAll().length == 0)
            {
                emptyRect.visible = true
            }else
            {
                emptyRect.visible = false
            }
        }
    }

    //for dbus start
    function updateLately(index)
    {
        videoGridView.model.list.countUpVideos(index, true)
    }

    function play()
    {
        player.playing = !player.playing
    }

    function nextTrack()
    {
        Player.nextTrack(false)
        isFav()
    }

    function previousTrack()
    {
        Player.previousTrack()
        isFav()
    }
    //for dbus end

    //编辑态多选 start
    function addToSelection(item, index)
    {
        if(_selectionBar == null)
        {
            return
        }

        if(_selectionBar.contains(item.url))
        {
            _selectionBar.removeAtUri(item.url)
            return
        }

        _selectionBar.append(item.url, item)
    }

    function selectAll(type)
    {
        if(_selectionBar == null)
        {
            return
        }

        if(type == 1)//视频
        {
            selectIndexes([...Array(videoGridView.model.getAll().length).keys()], type)
        }else if(type == 2)//音频
        {
            selectIndexes([...Array(musicGridView.model.getAll().length).keys()], type)
        }
    }

    function selectIndexes(indexes, type)
    {
        if(_selectionBar == null)
        {
            return
        }

        if(type == 1)//视频
        {
            for(var i in indexes)
                addToSelection(videoGridView.model.get(indexes[i]), i)
        }else if(type == 2)//音频
        {
            for(var i in indexes)
                addToSelection(musicGridView.model.get(indexes[i]), i)
        }

    }

    //编辑态多选 end

}
