/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

.import org.kde.mauikit 1.0 as Maui

function playTrack(index)
{
    if((index < mainPlaylist.gridView.count) && (mainPlaylist.gridView.count > 0) && (index > -1))
    {

        prevTrackIndex = currentTrackIndex
        currentTrackIndex = index
        mainPlaylist.gridView.currentIndex = currentTrackIndex
        currentTrack = mainPlaylist.model.get(currentTrackIndex)

        if(typeof(currentTrack) === "undefined") return

        if(!Maui.FM.fileExists(currentTrack.url) && String(currentTrack.url).startsWith("file://"))
        {
            missingAlert(currentTrack)
            return
        }

        player.url = currentTrack.url;
        player.playing = true

        mainPlaylist.model.list.countUp(currentTrackIndex, true)
    }
}

function playTrackByFlag(index,flag)
{
    if((index < mainPlaylist.gridView.count) && (mainPlaylist.gridView.count > 0) && (index > -1))
    {
        prevTrackIndex = currentTrackIndex
        currentTrackIndex = index
        mainPlaylist.gridView.currentIndex = currentTrackIndex
        currentTrack = mainPlaylist.model.get(currentTrackIndex)

        if(typeof(currentTrack) === "undefined") return

        if(!Maui.FM.fileExists(currentTrack.url) && String(currentTrack.url).startsWith("file://"))
        {
            missingAlert(currentTrack)
            return
        }

        player.url = currentTrack.url;
        player.playing = flag

        mainPlaylist.model.list.countUp(currentTrackIndex, true)
    }
}

function playTrackByFlag(index,flag)
{
    if((index < mainPlaylist.gridView.count) && (mainPlaylist.gridView.count > 0) && (index > -1))
    {
        prevTrackIndex = currentTrackIndex
        currentTrackIndex = index
        mainPlaylist.gridView.currentIndex = currentTrackIndex
        currentTrack = mainPlaylist.model.get(currentTrackIndex)

        if(typeof(currentTrack) === "undefined") return

        if(!Maui.FM.fileExists(currentTrack.url) && String(currentTrack.url).startsWith("file://"))
        {
            missingAlert(currentTrack)
            return
        }

        player.url = currentTrack.url;
        player.playing = flag

        mainPlaylist.model.list.countUp(currentTrackIndex, true)
    }
}

function queueTracks(tracks)
{
    if(tracks && tracks.length > 0)
    {
        appendTracksAt(tracks, currentTrackIndex+onQueue+1)
        root.notify("", "Queue", tracks.length + " tracks added put on queue")
        onQueue++
    }
}

function setLyrics(lyrics)
{
    currentTrack.lyrics = lyrics
//    infoView.lyricsText.text = lyrics
}

function stop()
{
    player.stop()
    progressBar.value = 0
    progressBar.enabled = false
    root.title = "Babe..."
}

function pauseTrack()
{
    player.playing = false
}

function resumeTrack()
{
    if(!player.play() && !mainlistEmpty)
        playAt(0)
}

function nextTrack(onFinish)
{
    if(!mainlistEmpty)
    {
        var next = 0
        if(playType === 0)
        {
            next = currentTrackIndex + 1 >= mainPlaylist.gridView.count ? 0 : currentTrackIndex+1
        }else if(playType === 1)
        {
            next = shuffle()
        }else if(playType === 2)
        {
            if(onFinish)
            {
                next = currentTrackIndex
            }else
            {
                next = currentTrackIndex + 1 >= mainPlaylist.gridView.count ? 0 : currentTrackIndex + 1
            }
        }

        if(playType != 2)
        {
            prevTrackIndex = currentTrackIndex
        }
        playAt(next)

        if(onQueue > 0)
        {
            onQueue--
        }
    }
}

function previousTrack()
{
    if(!mainlistEmpty)
    {
        if(playType === 1)
        {
           var pre = shuffle()
           prevTrackIndex = currentTrackIndex
           playAt(pre)
        }else
        {
            const previous = currentTrackIndex-1 >= 0 ? mainPlaylist.gridView.currentIndex-1 : mainPlaylist.gridView.count-1
            prevTrackIndex = currentTrackIndex
            playAt(previous)
        }
    }
}

function shuffle()
{
    var pos =  Math.floor(Math.random() * mainPlaylist.gridView.count)
    return pos
}

function playAt(index)
{
    if((index < mainPlaylist.gridView.count) && (index > -1))
    {
        playTrack(index)
    }
}

function playAtByFlag(index,flag)
{
    if((index < mainPlaylist.gridView.count) && (index > -1))
    {
        playTrackByFlag(index,flag)
    }
}

function justRefreshPlayerUI(index)
{
    if((index < mainPlaylist.gridView.count) && (mainPlaylist.gridView.count > 0) && (index > -1))
    {
        player.playing = false
        prevTrackIndex = currentTrackIndex
        currentTrackIndex = index
        mainPlaylist.gridView.currentIndex = currentTrackIndex

        currentTrack = mainPlaylist.model.get(currentTrackIndex)

        if(typeof(currentTrack) === "undefined") return

        if(!Maui.FM.fileExists(currentTrack.url) && String(currentTrack.url).startsWith("file://"))
        {
            missingAlert(currentTrack)
            return
        }

        player.url = currentTrack.url;
        mainPlaylist.model.list.countUp(currentTrackIndex, true)
    }
}

function quickPlay(track)
{
    //    root.pageStack.currentIndex = 0
    appendTrack(track)
    playAt(mainPlaylist.gridView.count-1)
    mainPlaylist.gridView.positionViewAtEnd()
}

function appendTracksAt(tracks, at)
{
    if(tracks)
        for(var i in tracks)
        {
            mainPlaylist.model.list.append(tracks[i], parseInt(at)+parseInt(i))
        }
}

function appendTrack(track)
{
    if(track)
    {
        mainPlaylist.model.list.append(track)
        // mainPlaylist.list.append(track)
        // if(sync === true)
        // {
        //    playlistsList.addTrack(syncPlaylist, [track.url])
        // }
    }
}

function addTrack(track)
{
    if(track)
    {
        appendTrack(track)
        mainPlaylist.gridView.positionViewAtEnd()
    }
}

function appendAll(tracks)
{
    if(tracks)
    {
        for(var i in tracks)
        {
            // appendTrack(tracks[i])
            mainPlaylist.model.list.justAppend(tracks[i])
        }
        mainPlaylist.model.list.appendRefresh()
    }
}

function savePlaylist()
{
    var list = []
    var n =  mainPlaylist.gridView.count
    n = n > 15 ? 15 : n

    for(var i=0 ; i < n; i++)
    {
        var url = mainPlaylist.model.list.get(i).url
        list.push(url)
    }

    Maui.FM.saveSettings("LASTPLAYLIST", list, "PLAYLIST");
    Maui.FM.saveSettings("PLAYLIST_POS", mainPlaylist.gridView.currentIndex, "MAINWINDOW")
}


function clearOutPlaylist()
{
    mainPlaylist.model.list.clear()
    stop()
}

function cleanPlaylist()
{
    var urls = []

    for(var i = 0; i < mainPlaylist.gridView.count; i++)
    {
        var url = mainPlaylist.model.list.get(i).url

        if(urls.indexOf(url)<0)
            urls.push(url)
        else mainPlaylist.model.list.remove(i)
    }
}

function playAll(tracks)
{
    sync = false
    syncPlaylist = ""

    mainPlaylist.model.list.clear()
    appendAll(tracks)

    mainPlaylist.gridView.positionViewAtBeginning()
    playAt(0)
}

function getCover(track)
{
    return mainPlaylist.model.list.getCover(track.url)
}
