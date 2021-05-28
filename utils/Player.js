.import org.kde.mauikit 1.0 as Maui

function playTrack(index)
{
    if((index < mainPlaylist.listView.count) && (mainPlaylist.listView.count > 0) && (index > -1))
    {
        prevTrackIndex = currentTrackIndex
        currentTrackIndex = index
        mainPlaylist.listView.currentIndex = currentTrackIndex


        // currentTrack = mainPlaylist.listView.itemAtIndex(currentTrackIndex)//如果用这个方法 那么当size>30的时候 播放第一个 再次点击播放第一个 就会currentTrack为null 而且唯独第一个不行 其他的都ok 不知道为什么
        currentTrack = mainPlaylist.listModel.get(currentTrackIndex)//这个方法ok

        if(typeof(currentTrack) === "undefined") return

        if(!Maui.FM.fileExists(currentTrack.url) && String(currentTrack.url).startsWith("file://"))
        {
            missingAlert(currentTrack)
            return
        }

        player.url = currentTrack.url;
        player.playing = true

        mainPlaylist.listModel.list.countUp(currentTrackIndex, true)//add by hjy  用mostPlayedTracks当做最近的播放
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
    infoView.lyricsText.text = lyrics
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
        if(playType === 0)//顺序播放
        {
            next = currentTrackIndex+1 >= mainPlaylist.listView.count? 0 : currentTrackIndex+1
        }else if(playType === 1)//随机播放
        {
            next = shuffle()
        }else if(playType === 2)//单曲循环
        {
            if(onFinish)
            {
                next = currentTrackIndex
            }else
            {
                next = currentTrackIndex+1 >= mainPlaylist.listView.count? 0 : currentTrackIndex + 1
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
        if(playType === 1)//随机播放
        {
           var pre = shuffle()
           prevTrackIndex = currentTrackIndex
           playAt(pre)
        }else
        {
            const previous = currentTrackIndex-1 >= 0 ? mainPlaylist.listView.currentIndex-1 : mainPlaylist.listView.count-1
            prevTrackIndex = currentTrackIndex
            playAt(previous)
        }
    }
}

function shuffle()
{
    var pos =  Math.floor(Math.random() * mainPlaylist.listView.count)
    return pos
}

function playAt(index)
{
    if((index < mainPlaylist.listView.count) && (index > -1))
    {
        playTrack(index)
    }
}

function justRefreshPlayerUI(index)
{
    if((index < mainPlaylist.listView.count) && (mainPlaylist.listView.count > 0) && (index > -1))
    {
        player.playing = false
        prevTrackIndex = currentTrackIndex
        currentTrackIndex = index
        mainPlaylist.listView.currentIndex = currentTrackIndex

        currentTrack = mainPlaylist.listModel.get(currentTrackIndex)

        if(typeof(currentTrack) === "undefined") return

        if(!Maui.FM.fileExists(currentTrack.url) && String(currentTrack.url).startsWith("file://"))
        {
            missingAlert(currentTrack)
            return
        }

        player.url = currentTrack.url;
        mainPlaylist.listModel.list.countUp(currentTrackIndex, true)//add by hjy  用mostPlayedTracks当做最近的播放
    }
}

function quickPlay(track)
{
    //    root.pageStack.currentIndex = 0
    appendTrack(track)
    playAt(mainPlaylist.listView.count-1)
    mainPlaylist.listView.positionViewAtEnd()
}

function appendTracksAt(tracks, at)
{
    if(tracks)
        for(var i in tracks)
        {
            mainPlaylist.listModel.list.append(tracks[i], parseInt(at)+parseInt(i))
        }
}

function appendTrack(track)
{
    if(track)
    {
        mainPlaylist.listModel.list.append(track)
        // mainPlaylist.list.append(track)
        if(sync === true)
        {
           playlistsList.addTrack(syncPlaylist, [track.url])
        }
    }
}

function addTrack(track)
{
    if(track)
    {
        appendTrack(track)
        mainPlaylist.listView.positionViewAtEnd()
    }
}

function appendAll(tracks)
{
    if(tracks)
    {
        for(var i in tracks)
            appendTrack(tracks[i])

        mainPlaylist.listView.positionViewAtEnd()
    }
}

function savePlaylist()
{
    var list = []
    var n =  mainPlaylist.listView.count
    n = n > 15 ? 15 : n

    for(var i=0 ; i < n; i++)
    {
        var url = mainPlaylist.listModel.list.get(i).url
        list.push(url)
    }

    Maui.FM.saveSettings("LASTPLAYLIST", list, "PLAYLIST");
    Maui.FM.saveSettings("PLAYLIST_POS", mainPlaylist.listView.currentIndex, "MAINWINDOW")
}


function clearOutPlaylist()
{
    mainPlaylist.listModel.list.clear()
    stop()
}

function cleanPlaylist()
{
    var urls = []

    for(var i = 0; i < mainPlaylist.listView.count; i++)
    {
        var url = mainPlaylist.listModel.list.get(i).url

        if(urls.indexOf(url)<0)
            urls.push(url)
        else mainPlaylist.listModel.list.remove(i)
    }
}

function playAll(tracks)
{
    sync = false
    syncPlaylist = ""

    mainPlaylist.listModel.list.clear()
    appendAll(tracks)

    if(_drawer.modal && !_drawer.visible)
        _drawer.visible = true

    mainPlaylist.listView.positionViewAtBeginning()
    playAt(0)
}

function getCover(track)
{
    return mainPlaylist.listModel.list.getCover(track.url)
}
