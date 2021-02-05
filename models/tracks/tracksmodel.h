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

#ifndef TRACKSMODEL_H
#define TRACKSMODEL_H

#include <QObject>

#ifdef STATIC_MAUIKIT
#include "fmh.h"
#include "mauilist.h"
#else
#include <MauiKit/fmh.h>
#include <MauiKit/mauilist.h>
#endif

class CollectionDB;
class TracksModel : public MauiList
{
    Q_OBJECT
    Q_PROPERTY(QString query READ getQuery WRITE setQuery NOTIFY queryChanged())
    Q_PROPERTY(TracksModel::SORTBY sortBy READ getSortBy WRITE setSortBy NOTIFY sortByChanged)

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

    explicit TracksModel(QObject *parent = nullptr);

    void componentComplete() override final;

    const FMH::MODEL_LIST &items() const override;

    void setQuery(const QString &query);
    QString getQuery() const;

    void setSortBy(const TracksModel::SORTBY &sort);
    TracksModel::SORTBY getSortBy() const;

private:
    CollectionDB *db;
    FMH::MODEL_LIST list;
    void sortList();
    void setList();

    QString query;
    TracksModel::SORTBY sort = TracksModel::SORTBY::ADDDATE;

signals:
    void queryChanged();
    void sortByChanged();

public slots:
    QVariantMap get(const int &index) const;
    QVariantList getAll();
    void append(const QVariantMap &item);
    void append(const QVariantMap &item, const int &at);
    void appendQuery(const QString &query);
    void searchQueries(const QStringList &queries, const int &type);
    void clear();
    bool color(const int &index, const QString &color);
    bool fav(const int &index, const bool &value);
    bool rate(const int &index, const int &value);
    bool countUp(const int &index, const bool &value);
    bool remove(const int &index);
    void refresh();
    bool update(const QVariantMap &data, const int &index);
    bool deleteFile(const int &index);
    bool copyFile(const int &index, const bool &value);
    void emitpPlayingState(const bool &isPlay);
};

#endif // TRACKSMODEL_H
