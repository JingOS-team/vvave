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

#ifndef CLOUD_H
#define CLOUD_H

#include <QObject>

#ifdef STATIC_MAUIKIT
#include "fmh.h"
#include "mauilist.h"
#else
#include <MauiKit/fmh.h>
#include <MauiKit/mauilist.h>
#endif

class FM;
class AbstractMusicProvider;
class Cloud : public MauiList
{
    Q_OBJECT
    Q_PROPERTY(Cloud::SORTBY sortBy READ getSortBy WRITE setSortBy NOTIFY sortByChanged)
    Q_PROPERTY(QVariantList artists READ getArtists NOTIFY artistsChanged)
    Q_PROPERTY(QVariantList albums READ getAlbums NOTIFY albumsChanged)

public:
    enum SORTBY : uint_fast8_t
    {
        ADDDATE = FMH::MODEL_KEY::ADDDATE,
        RELEASEDATE = FMH::MODEL_KEY::RELEASEDATE,
        FORMAT = FMH::MODEL_KEY::FORMAT,
        ARTIST = FMH::MODEL_KEY::ARTIST,
        TITLE = FMH::MODEL_KEY::TITLE,
        ALBUM = FMH::MODEL_KEY::ALBUM,
        RATE = FMH::MODEL_KEY::RATE,
        FAV = FMH::MODEL_KEY::FAV,
        TRACK = FMH::MODEL_KEY::TRACK,
        COUNT = FMH::MODEL_KEY::COUNT,
        NONE

    };
    Q_ENUM(SORTBY)

    explicit Cloud(QObject *parent = nullptr);
    void componentComplete() override final;

    void setSortBy(const Cloud::SORTBY &sort);
    Cloud::SORTBY getSortBy() const;

    QVariantList getAlbums() const;
    QVariantList getArtists() const;

private:
    AbstractMusicProvider *provider;
    FMH::MODEL_LIST list;
    void sortList();
    void setList();

    Cloud::SORTBY sort = Cloud::SORTBY::ARTIST;

public slots:
    QVariantMap get(const int &index) const;
    QVariantList getAll();

    void upload(const QUrl &url);

    void getFileUrl(const QString &id);
    void getFileUrl(const int &index);

signals:
    void sortByChanged();
    void fileReady(QVariantMap track);
    void warning(QString error);

    void artistsChanged();
    void albumsChanged();
};

#endif // CLOUD_H
