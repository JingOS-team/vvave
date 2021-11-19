/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtGraphicalEffects 1.0
import org.kde.kirigami 2.15 as Kirigami
import org.kde.mauikit 1.0 as Maui
import org.kde.mauikit 1.1 as MauiLab
import org.maui.vvave 1.0 as Vvave
import jingos.display 1.0

import Player 1.0
import AlbumsList 1.0
import PlaylistsList 1.0
import org.jingos.media 1.0

import "utils"
import "widgets"

import "db/Queries.js" as Q
import "utils/Help.js" as H
import "utils/Player.js" as PlayerOP

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12
import QtQml.Models 2.15
import QtQuick.Window 2.15

Kirigami.ApplicationWindow {
    id: root

    /***************************************************/
    /******************** ALIASES ********************/
    /*************************************************/
    property alias mainPlaylist: playerview.musicGridView
    property alias selectionBar: _selectionBar
    property alias progressBar: playerview.progressBar
    // property alias dialog : _dialogLoader.item
    

    /***************************************************/
    /******************** PLAYBACK ********************/
    /*************************************************/
    /******  0--play in order   1--Shuffle Playback   2--Single cycle  ********/
    property int playType: Maui.FM.loadSettings("SHUFFLE","PLAYBACK", 0)
    property var currentTrack: playerview.musicGridView.gridView.itemAtIndex(currentTrackIndex)

    property int currentTrackIndex: -1
    property int prevTrackIndex: 0
    /****** 1--storage 2--del 3--batch storage 4--batch del(video);  5--storage 6--del 7--batch storage 8--batch del(Music) ******/
    property int jDialogType: 1
    /******  1--all 2--like 3--lately(video);  4--all 5--like 6--lately(Music)   ******/
    property int currentPage: 1
    /******  ******/
    property int currentPlayPage: 4
    property alias durationTimeLabel: player.duration
    property string progressTimeLabel: "00:00"

    property alias isPlaying: player.playing
    property int onQueue: 0

    property bool mainlistEmpty: !playerview.musicGridView.gridView.count > 0

    property string syncPlaylist: ""
    property bool sync: false

    property bool focusView : false
    property bool musicSelectionMode : false
    property bool videoSelectionMode : false
    property bool noResultState: false
    property bool isDarkTheme:  Kirigami.JTheme.colorScheme === "jingosDark"

    /***************************************************/
    /******************** UI COLORS *******************/
    /*************************************************/
    readonly property color babeColor: "#f84172"

    property bool translucency : Maui.Handy.isLinux
    property string filterStatus: ""

    property var appScaleSize: JDisplay.dp(1.0)
    property var appFontSize: JDisplay.sp(1.0)

    /*SIGNALS*/
    signal missingAlert(var track)

    property int playStartIndex: -1
    property bool playMusicFlag: false
    property int selectAllLength: 0
    property bool fav
    property var currentCover
    property string playlistQuery
    property var queryjs: Q
    property var helpjs: H
    property var playerOP: PlayerOP
    property var vvaveControl: Vvave
    property var playerMainView: playerview

    width: root.screen.width
    height: root.screen.height

    title: currentTrack ? currentTrack.title + " - " +  currentTrack.artist + " | " + currentTrack.album : ""
    background.opacity: translucency ? 0.5 : 1
    color: Kirigami.JTheme.background
    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    pageStack.interactive: false

    Component.onCompleted:{
        Vvave.JAppControl.setAppstatus(false)
        playerview.playerviewleft.setCurrentPage(1, true)
    }

    /*HANDLE EVENTS*/
    onClosing: {
        PlayerOP.savePlaylist()
    }

    onMissingAlert: {
        var message = qsTr("Missing file")
        var messageBody = track.title + " by " + track.artist + " is missing.\nDo you want to remove it from your collection?"
        notify("dialog-question", message, messageBody, function () {
            playerview.musicGridView.model.list.remove(playerview.musicGridView.gridView.currentIndex)
        })
    }

    pageStack.initialPage: PlayerView {
         id: playerview
    }

    Loading {
        id: _loading
    }


    Timer {
        id: timer
        running: false
        repeat: false
        interval: 800
        onTriggered: {
            if (!mainlistEmpty) {
                if (currentTrack && currentTrack.url)
                    PlayerOP.nextTrack(true)
                playerview.isFav()
            }
        }
    }

    Player {
        id: player
        volume: 100

        onFinishedChanged: {
            timer.start()
        }
    }

    SelectionBar1 {
        id: _selectionBar
    }

    Loader {
        id: _dialogLoader
    }

    Mpris2 {
        id: mpris2Interface

        playListModel: playerview.musicGridView.model.list
        audioPlayer: player
        playerName: 'media'

        onRaisePlayer: {
            root.raise()
        }
    }

    ListModel {
        id:previewimagemodel
    }
}
