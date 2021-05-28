/*
 *   Copyright 2018 Camilo Higuita <milo.h@aol.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.7 as Kirigami
import org.kde.mauikit 1.0 as Maui
import QtGraphicalEffects 1.0

/**
 * SelectionBar
 *
 * A bar to group selected items with a list of actions to perform to the selection.
 * The list of actions is  positioned into a Kirigami ActionToolBar.
 * This control provides methods to append and query elements added to it. To add elements to it, it is necesary to map them,
 * so an item is mapped to an unique id refered here as an URI.
 */
Item
{
    id: control

    /**
      * uris : var
      * List of URIs associated to the grouped elements.
      */
    readonly property alias uris: _private._uris

    /**
      * items : var
      * List of items grouped.
      */
    readonly property alias items: _private._items

    /**
      * count : int
      * Size of the elements grouped.
      */
    // readonly property alias count : _private._items.length
    // readonly property alias count : _private._items.length

        /**
      * uriAdded :
      * Triggered when an item newly added to the selection. This signal only sends the refered URI of the item.
      */
    signal uriAdded(string uri)

    /** uriRemoved:
      * Triggered when an item has been removed from the selection. This signal only sends the refered URI of the item.
      */
    signal uriRemoved(string uri)

        /**
      * cleared :
      * Triggered when the selection is cleared by using the close button or calling the clear method.
      */
    signal cleared()



    property QtObject m_private : QtObject
    {
        id: _private
        property var _uris : []
        property var _items : []
    }

    /**
      * Removes all the items from the selection.
      */
    function clear()
    {
        _private._uris = []
        _private._items = []
        control.cleared()
    }

    /**
      * Returns an item at a given index
      */
    function itemAt(index)
    {
        if(index < 0 ||  index > count)
            return
        return items[index]
    }

    /**
      * Remove a single item at a given index
      */
    function removeAtIndex(index)
    {
        if(index < 0)
            return

            const item = items[index]
            const uri = item.uri

            if(contains(uri))
            {
                _private._uris.splice(index, 1)
                _private._items.splice(index, 1)
                control.uriRemoved(uri)
            }
    }

    /**
      * Removes an item from thge selection at a given URI
      */
    function removeAtUri(uri)
    {
        removeAtIndex(indexOf(uri))
    }

    /**
      *  Return the index of an item in the selection given its URI
      */
    function indexOf(uri)
    {
        return _private._uris.indexOf(uri)
    }

    /**
      * Append a new item to the selection associated to the given URI
      */
    function append(uri, item)
    {
        const index  = _private._uris.indexOf(uri)
        if(index < 0)
        {
            _private._items.push(item)
            _private._uris.push(uri)
            item.uri = uri
            control.uriAdded(uri)
        }
    }

    /**
      * Returns true if the selection contains an item associated to a given URI.
      */
    function contains(uri)
    {
        return _private._uris.includes(uri)
    }
}
