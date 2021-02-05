/*
   Babe - tiny music player
   Copyright 2021 Wang Rui <wangrui@jingos.com>
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software Foundation,
   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
   */

import QtQuick 2.0
import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Layouts 1.3
import "../utils"
import ".."
import "../utils/Help.js" as H
import "../utils/Player.js" as Player
import "../view_models"
import "../view_models/BabeTable"

import org.kde.kirigami 2.7 as Kirigami
import org.kde.mauikit 1.0 as Maui
import org.kde.mauikit 1.1 as MauiLab

MauiLab.SelectionBar
{
    id: control
    width: Maui.Style.unit * 200

    property int rate : 0
    property string starColor : "#FFC107"
    property string starReg : Kirigami.Theme.textColor
    property string starIcon: "draw-star"

    signal rateClicked(int rate)

    listDelegate: TableDelegate
    {
        isCurrentItem: false
        Kirigami.Theme.inherit: true
        width: 100
        number: false
        coverArt: true
        showQuickActions: false
        checked: true
        checkable: true
        onToggled: control.removeAtIndex(index)
        background: Item {}
    }

    Action
    {
        text: qsTr("Play")
        icon.name: "media-playlist-play"
        onTriggered:
        {
            mainPlaylist.listModel.list.clear()
            Player.playAll(control.items)
        }
    }

    Action
    {
        text: qsTr("Append")
        icon.name: "media-playlist-append"
        onTriggered: Player.appendAll(control.items)
    }

    Action
    {
        text: qsTr("Queue")
        icon.name: "view-media-recent"
        onTriggered:
        {
            Player.queueTracks(control.items)
        }
    }

    Action
    {
        text: qsTr("Add to")
        icon.name: "document-save"
        onTriggered:
        {
            playlistDialog.tracks = control.uris
            playlistDialog.open()
        }
    }

    Action
    {
        text: qsTr("Share")
        icon.name: "document-share"
        onTriggered:
        {
            if(isAndroid)
            {
                 Maui.Android.shareDialog(control.uris)
                return
            }

            _dialogLoader.sourceComponent = _shareDialogComponent
            root.dialog.urls = control.uris
            root.dialog.open()
        }
    }

    Action
    {
        text: qsTr("Remove")
        icon.name: "edit-delete"
        Kirigami.Theme.textColor: Kirigami.Theme.negativeTextColor
        onTriggered:
        {
        }
    }

}
