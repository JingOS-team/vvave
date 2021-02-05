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

import QtQuick 2.10
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.10
import QtGraphicalEffects 1.0

import org.kde.kirigami 2.7 as Kirigami
import org.kde.mauikit 1.0 as Maui

import "../../view_models"
import "../../utils/Help.js" as H

Maui.ListBrowserDelegate
{
    id: control

    property bool showQuickActions: true
    property bool number : false
    property bool coverArt : false

    readonly property string artist : model.artist
    readonly property string album : model.album
    readonly property string title : model.title
    readonly property url url : model.url
    readonly property int rate : model.rate
    readonly property int track : model.track

    property bool sameAlbum : false

    isCurrentItem: ListView.isCurrentItem || checked

    draggable: true

    iconSizeHint: height - Maui.Style.space.small
    label1.text: control.number ? control.track + ". " + control.title :  control.title
    label2.text: control.artist + " | " + control.album
    label2.visible: control.coverArt ? !control.sameAlbum : true

    label3.font.family: "Material Design Icons"
    label3.text: control.rate ? H.setStars(control.rate) : ""

    iconVisible: !control.sameAlbum && control.coverArt
    imageSource: coverArt ? "image://artwork/album:"+ control.artist+":"+control.album : ""
    template.leftMargin: iconVisible ? 0 : Maui.Style.space.medium

}
