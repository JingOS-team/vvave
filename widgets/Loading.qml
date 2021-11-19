/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.14
import QtQml 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.15 as Kirigami
import org.kde.mauikit 1.2 as Maui
import QtGraphicalEffects 1.0

Popup
{
    id: control
    width: 350
    height: 162 - 16
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape

    background: Kirigami.JBlurBackground{
        id:blurBk
        anchors.fill: parent
        sourceItem: control.parent
        backgroundColor: Kirigami.JTheme.floatBackground
    }

    AnimatedImage
    {
        id: gifImage

        fillMode: Image.PreserveAspectFit
        anchors.fill: parent
        anchors.centerIn: parent.centerIn
        source: "qrc:/assets/loading.gif"
        visible: true
        playing: true
    }

    function show()
    {
        control.x = (wholeScreen.width - control.width) / 2
        control.y = (wholeScreen.height - control.height) / 2
        open()

    }
}
