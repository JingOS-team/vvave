/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

import QtQuick 2.0
import QtQuick.Controls 2.15
import org.kde.kirigami 2.15 as Kirigami

Kirigami.JDialog {
    id: jDialog

    closePolicy: Popup.CloseOnEscape
    leftButtonText: i18n("Cancel")
    title: {
        switch (jDialogType) {
        case 1:
        case 3:
        case 5:
        case 7: {
            i18n("Save to files")
            break
        }
        case 2:
        case 4:
        case 6:
        case 8: {
            i18n("Delete")
            break
        }
        }
    }

    text: {
        switch (jDialogType) {
        case 1:
        case 5: {
            i18n("Are you sure you want to save the file to file manager?")
            break
        }
        case 2:
        case 6: {
            i18n("Are you sure you want to delete the file?")
            break
        }
        case 3:
        case 7: {
            if(_selectionBar.items.length > 1) {
                i18n("Are you sure you want to save these files to file manager?")
            } else {
                i18n("Are you sure you want to save the file to file manager?")
            }
            break
        }
        case 4:
        case 8: {
            if(_selectionBar.items.length > 1) {
                i18n("Are you sure you want to delete these files?")
            } else {
                i18n("Are you sure you want to delete the file?")
            }
            break
        }
        }
    }

    rightButtonText: {
        switch (jDialogType) {
        case 1:
        case 3:
        case 5:
        case 7: {
            i18n("Save")
            break
        }
        case 2:
        case 4:
        case 6:
        case 8: {
            i18n("Delete")
            break
        }
        }
    }

    onLeftButtonClicked: {
        close()
    }

    onRightButtonClicked: {
        switch (jDialogType) {
        case 1:{
            videoGridView.model.list.copyFileVideos(videoGridView.gridView.currentIndex, false)
            break
        }
        case 2: {
            if(videoGridView.model.list.deleteFileVideos(videoGridView.gridView.currentIndex)) {
                videoGridView.model.list.removeVideos(videoGridView.gridView.currentIndex)
                if(videoGridView.gridView.count == 0) {
                    emptyRect.visible = true
                }
            }
            break
        }
        case 3: {
            for(var i = 0; i < _selectionBar.items.length; i++) {
                for(var j = 0; j < videoGridView.gridView.count; j++) {
                    if(_selectionBar.items[i].url === videoGridView.model.get(j).url) {
                        videoGridView.model.list.copyFileVideos(j, false)
                        break
                    }
                }
            }

            if(videoGridView.gridView.count == 0) {
                emptyRect.visible = true
            }
            videoSelectionMode = false
            _selectionBar.clear()
            break
        }
        case 4: {
            for(var i = 0; i < _selectionBar.items.length; i++) {
                for(var j = 0; j < videoGridView.gridView.count; j++)
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
            if(videoGridView.gridView.count == 0) {
                emptyRect.visible = true
            }
            _selectionBar.clear()
            selectCountText.text = _selectionBar.items.length
            videoSelectionMode = false
            break
        }
        case 5: {
            musicGridView.model.list.copyFile(musicGridView.gridView.currentIndex, false)
            break
        }
        case 6: {
            var item = musicGridView.model.get(musicGridView.gridView.currentIndex)
            if(musicGridView.model.list.deleteFile(musicGridView.gridView.currentIndex)) {
                musicGridView.model.list.remove(musicGridView.gridView.currentIndex)
                if(musicGridView.gridView.count == 0) {
                    if(isPlaying) {
                        player.playing = !player.playing
                        musicGridView.model.list.emitpPlayingState(player.playing)
                    }
                    currentTrack = musicGridView.gridView.itemAtIndex(currentTrackIndex)
                    emptyRect.visible = true
                } else {
                    musicGridView.model.list.remove(musicGridView.gridView.currentIndex)
                    if(musicGridView.gridView.currentIndex == musicGridView.gridView.count) {
                        playerOP.playAtByFlag(0,isPlaying)
                        isFav()
                    } else if(currentTrack && currentTrack.title === item.title && currentTrack.adddate === item.adddate) {
                        playerOP.playAtByFlag(musicGridView.gridView.currentIndex,isPlaying)
                        isFav()
                    }
                }
                if(musicGridView.gridView.count == 0) {
                    emptyRect.visible = true
                }
            }
            break
        }
        case 7: {
            for(var i = 0; i < _selectionBar.items.length; i++) {
                for(var j = 0; j < musicGridView.gridView.count; j++) {
                    if(_selectionBar.items[i].url === musicGridView.model.get(j).url) {
                        musicGridView.model.list.copyFile(j, false)
                        break
                    }
                }
            }
            musicSelectionMode = false
            _selectionBar.clear()
            break
        }
        case 8: {
            var playNext = false;
            if(currentTrack) {
                for(var i = 0; i < _selectionBar.items.length; i++) {
                    if(_selectionBar.items[i].title === currentTrack.title && currentTrack.adddate == _selectionBar.items[i].adddate) {
                        playNext = true
                        break
                    }
                }
            }

            // Maui.FM.removeFiles(_selectionBar.uris)
            musicGridView.model.list.deleteFiles(_selectionBar.uris)
            musicGridView.model.list.refresh()

            if(musicGridView.gridView.count === 0) {
                if(isPlaying) {
                    player.playing = !player.playing
                    musicGridView.model.list.emitpPlayingState(player.playing)
                }
                currentTrack = musicGridView.gridView.itemAtIndex(currentTrackIndex)
                emptyRect.visible = true
            } else {
                if(musicGridView.gridView.currentIndex == musicGridView.gridView.count) {
                    playerOP.playAtByFlag(0,isPlaying)
                    isFav()
                } else if(playNext) {
                    playerOP.playAtByFlag(musicGridView.gridView.currentIndex,isPlaying)
                    isFav()
                } else {
                    if(currentTrack) {
                        for(var i = 0; i < musicGridView.gridView.count; i++) {
                            if(musicGridView.model.get(i).title === currentTrack.title && currentTrack.adddate == musicGridView.model.get(i).adddate) {
                                playerOP.playAtByFlag(i,isPlaying)
                                isFav()
                                break
                            }
                        }
                    }
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
