/*
   Babe - tiny music player
   Copyright (C) 2017  Camilo Higuita
   Copyright (C) 2021  Yu Jiashu <yujiashu@jingos.com>
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

#ifndef COLLECTIONDB_H
#define COLLECTIONDB_H
#include <QString>
#include <QStringList>
#include <QList>
#include <QSqlDatabase>
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlDriver>
#include <QFileInfo>
#include <QDir>
#include <QVariantMap>
#include <functional>
#include <QMutex>
#include "../utils/bae.h"

enum sourceTypes
{
    LOCAL, ONLINE, DEVICE
};

class CollectionDB : public QObject
{
    Q_OBJECT

public:
    static CollectionDB *getInstance();
    bool insert(const QString &tableName, const QVariantMap &insertData);
    bool update(const QString &tableName, const FMH::MODEL &updateData, const QVariantMap &where);
    bool update(const QString &table, const QString &column, const QVariant &newValue, const QVariant &op, const QString &id);
    bool remove(const QString &table, const QString &column, const QVariantMap &where);

    bool execQuery(QSqlQuery &query) const;
    bool execQuery(const QString &queryTxt);

    /*basic public actions*/
    void prepareCollectionDB();
    bool check_existance(const QString &tableName, const QString &searchId, const QString &search);

    /* usefull actions */

    void insertArtwork(const FMH::MODEL &track);

    bool addTrack(const FMH::MODEL &track);
    bool addVideo(const FMH::MODEL &video);
    bool updateTrack(const FMH::MODEL &track);

    Q_INVOKABLE bool rateTrack(const QString &path, const int &value);
    Q_INVOKABLE bool colorTagTrack(const QString &path, const QString &value);
    Q_INVOKABLE QString trackColorTag(const QString &path);

    bool lyricsTrack(const FMH::MODEL &track, const QString &value);
    Q_INVOKABLE bool playedTrack(const QString &url, const int &increment = 1);
    Q_INVOKABLE bool playedVideo(const QString &url, const int &increment = 1);
    Q_INVOKABLE bool updateTimeToDB(const QString &url, const int &trackOrVideo = 1);

    bool wikiTrack(const FMH::MODEL &track, const QString &value);
    bool tagsTrack(const FMH::MODEL &track, const QString &value, const QString &context);
    bool albumTrack(const FMH::MODEL &track, const QString &value);
    bool trackTrack(const FMH::MODEL &track, const QString &value);
    bool wikiArtist(const FMH::MODEL &track, const QString &value);
    bool tagsArtist(const FMH::MODEL &track, const QString &value, const QString &context = "");

    bool wikiAlbum(const FMH::MODEL &track, QString value);
    bool tagsAlbum(const FMH::MODEL &track, const QString &value, const QString &context = "");

    Q_INVOKABLE bool addPlaylist(const QString &title);
    bool trackPlaylist(const QString &url, const QString &playlist);
    bool addFolder(const QString &url);
    bool removeFolder(const QString &url);

    bool favTrack(const QString &path, const bool &value);

    FMH::MODEL_LIST getDBData(const QStringList &urls);
    FMH::MODEL_LIST getDBData(const QString &queryTxt, std::function<bool(FMH::MODEL &item)> modifier = nullptr);
    QVariantList getDBDataQML(const QString &queryTxt);
    static QStringList dataToList(const FMH::MODEL_LIST &list, const FMH::MODEL_KEY &key);

    FMH::MODEL_LIST getAlbumTracks(const QString &album, const QString &artist, const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::TRACK, const BAE::W &order = BAE::W::ASC);
    FMH::MODEL_LIST getArtistTracks(const QString &artist, const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::ALBUM, const BAE::W &order = BAE::W::ASC);
    FMH::MODEL_LIST getBabedTracks(const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::COUNT, const BAE::W &order = BAE::W::DESC);
    FMH::MODEL_LIST getSearchedTracks(const FMH::MODEL_KEY &where, const QString &search);
    FMH::MODEL_LIST getPlaylistTracks(const QString &playlist, const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::ADDDATE, const BAE::W &order = BAE::W::DESC);
    FMH::MODEL_LIST getMostPlayedTracks(const int &greaterThan = 1, const int &limit = 50, const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::COUNT, const BAE::W &order = BAE::W::DESC);
    FMH::MODEL_LIST getFavTracks(const int &stars = 1, const int &limit = 50, const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::RATE, const BAE::W &order = BAE::W::DESC);
    FMH::MODEL_LIST getRecentTracks(const int &limit = 50, const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::ADDDATE, const BAE::W &order = BAE::W::DESC);
    FMH::MODEL_LIST getOnlineTracks(const FMH::MODEL_KEY &orderBy = FMH::MODEL_KEY::ADDDATE, const BAE::W &order = BAE::W::DESC);

    Q_INVOKABLE QStringList getSourcesFolders();

    QStringList getTrackTags(const QString &path);
    Q_INVOKABLE int getTrackStars(const QString &path);
    QStringList getArtistAlbums(const QString &artist);

    FMH::MODEL_LIST getPlaylists();
    QStringList getPlaylistsList();

    Q_INVOKABLE bool removePlaylistTrack(const QString &url, const QString &playlist);
    Q_INVOKABLE bool removePlaylist(const QString &playlist);
    Q_INVOKABLE void removeMissingTracks();
    Q_INVOKABLE void  removeMissingVideos();
    bool removeArtwork(const QString &table, const QVariantMap &item);
    bool removeArtist(const QString &artist);
    bool cleanArtists();
    bool removeAlbum(const QString &album, const QString &artist);
    bool cleanAlbums();
    Q_INVOKABLE bool removeSource(const QString &url);
    Q_INVOKABLE bool removeTrack(const QString &path);
    Q_INVOKABLE bool removeVideo(const QString &path);
    QSqlQuery getQuery(const QString &queryTxt);
    sourceTypes sourceType(const QString &url);
    void openDB(const QString &name);

    static QMutex m_nMutext;

private:
    static CollectionDB* instance;

    QString name;
    QSqlDatabase m_db;
    explicit CollectionDB( QObject *parent = nullptr);

signals:
    void trackInserted();
    void artworkInserted(const FMH::MODEL &albumMap);
    void DBactionFinished();
    void albumsCleaned(const int &amount);
    void artistsCleaned(const int &amount);
};

#endif // COLLECTION_H
