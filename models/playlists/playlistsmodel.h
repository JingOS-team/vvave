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

#ifndef PLAYLISTSMODEL_H
#define PLAYLISTSMODEL_H

#ifdef STATIC_MAUIKIT
#include "fmh.h"
#include "mauilist.h"
#else
#include <MauiKit/fmh.h>
#include <MauiKit/mauilist.h>
#endif

class CollectionDB;
class PlaylistsModel : public MauiList
{
    Q_OBJECT
    Q_PROPERTY(PlaylistsModel::SORTBY sortBy READ getSortBy WRITE setSortBy NOTIFY sortByChanged)

public:
    enum SORTBY : uint_fast8_t
    {
        ADDDATE = FMH::MODEL_KEY::ADDDATE,
        TITLE = FMH::MODEL_KEY::TITLE,
        TYPE = FMH::MODEL_KEY::TYPE
    };
    Q_ENUM(SORTBY)

    explicit PlaylistsModel(QObject *parent = nullptr);

    const FMH::MODEL_LIST &items() const override;

    void setSortBy(const PlaylistsModel::SORTBY &sort);
    PlaylistsModel::SORTBY getSortBy() const;

private:
    CollectionDB *db;
    FMH::MODEL_LIST list;
    void sortList();
    void setList();

    FMH::MODEL packPlaylist(const QString &playlist);
    PlaylistsModel::SORTBY sort = PlaylistsModel::SORTBY::ADDDATE;

signals:
    void sortByChanged();

public slots:
    QVariantList defaultPlaylists();

    QVariantMap get(const int &index) const;
    void append(const QVariantMap &item);
    void append(const QVariantMap &item, const int &at);
    void insert(const QString &playlist);
    void insertAt(const QString &playlist, const int &at);

    void addTrack(const int &index, const QStringList &urls);
    void addTrack(const QString &playlist, const QStringList &urls);
    void removeTrack(const int &index, const QString &url);
    void removePlaylist(const int &index);
};

#endif // PLAYLISTSMODEL_H
