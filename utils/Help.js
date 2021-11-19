/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

.import org.kde.kirigami 2.7 as Kirigami

function rootWidth()
{
    return root.width;
}

function rootHeight()
{
    return root.height;
}

function setStars(stars)
{
    switch (stars)
    {
    case "0":
    case 0:
        return  "";

    case "1":
    case 1:
        return  "\uf4CE";

    case "2":
    case 2:
        return "\uf4CE \uf4CE";

    case "3":
    case 3:
        return  "\uf4CE \uf4CE \uf4CE";

    case "4":
    case 4:
        return  "\uf4CE \uf4CE \uf4CE \uf4CE";

    case "5":
    case 5:
        return "\uf4CE \uf4CE \uf4CE \uf4CE \uf4CE";

    default: return "error";
    }
}

function notify(title, body)
{
    if(Kirigami.Settings.isMobile)
        root.notify(title+"\n"+body)
//    else
//        bae.notify(title, body)
}

function addPlaylist(playlist)
{
//    playlistsView.playlistViewModel.model.insert(0, playlist)
}

function searchFor(query)
{
//    if(currentView !== viewsIndex.search)
//        currentView = viewsIndex.search

//    searchView.runSearch(query)
}

function addSource()
{
//    sourcesDialog.open()
}

function addToSelection(item)
{
    if(selectionBar.contains(item.url))
    {
        selectionBar.removeAtUri(item.url)
        return
    }

    item.thumbnail= item.artwork
    item.icon = "audio-x-generic"
    item.label= item.title
    item.mime= "image/png"
    item.tooltip= item.url
    item.path= item.url
    selectionBar.append(item.url, item)
}

let myMap = new Map();

function clear()
{
    myMap.clear()
}

/**
  * Removes an item from thge selection at a given URI
  */
function removeAtUri(uri)
{
  myMap.delete(uri)
}

/**
  * Append a new item to the selection associated to the given URI
  */
function append(uri, item)
{
    myMap.set(uri, item)
}

/**
  * Returns true if the selection contains an item associated to a given URI.
  */
function contains(uri)
{
    return myMap.get(uri)
}

function getSize()
{
    return myMap.size
}

