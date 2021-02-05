// Copyright 2021 Wang Rui <wangrui@jingos.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#ifndef VIDEOSMODEL_H
#define VIDEOSMODEL_H

#include <QObject>

#ifdef STATIC_MAUIKIT
#include "fmh.h"
#include "mauilist.h"
#else
#include <MauiKit/fmh.h>
#include <MauiKit/mauilist.h>
#endif


class CollectionDB;
class VideosModel : public MauiList
{
    Q_OBJECT
    Q_PROPERTY(QString query READ getQuery WRITE setQuery NOTIFY queryChangedVideos())
    Q_PROPERTY(VideosModel::SORTBY sortBy READ getSortBy WRITE setSortBy NOTIFY sortByChangedVideos)

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

    explicit VideosModel(QObject *parent = nullptr);

    void componentComplete() override final;

    const FMH::MODEL_LIST &items() const override;

    void setQuery(const QString &query);
    QString getQuery() const;

    void setSortBy(const VideosModel::SORTBY &sort);
    VideosModel::SORTBY getSortBy() const;

    QStringList harunaArguments;

private:
    CollectionDB *db;
    FMH::MODEL_LIST list;
    void sortList();
    void setList();

    QString query;
    VideosModel::SORTBY sort = VideosModel::SORTBY::ADDDATE;

signals:
    void queryChangedVideos();
    void sortByChangedVideos();

public slots:
    QVariantMap getVideos(const int &index) const;
    QVariantList getAllVideos();
    void appendVideos(const QVariantMap &item);
    void appendVideos(const QVariantMap &item, const int &at);
    void appendQueryVideos(const QString &query);
    void searchQueriesVideos(const QStringList &queries, const int &type);
    void clearVideos();
    bool colorVideos(const int &index, const QString &color);
    bool favVideos(const int &index, const bool &value);
    bool rateVideos(const int &index, const int &value);
    bool countUpVideos(const int &index, const bool &value);
    bool removeVideos(const int &index);
    void refreshVideos();
    bool updateVideos(const QVariantMap &data, const int &index);
    bool deleteFileVideos(const int &index);
    bool copyFileVideos(const int &index, const bool &value);
    bool playVideo();
    bool updateHarunaArguments(const int &index);
};

#endif // VIDEOSMODEL_H
