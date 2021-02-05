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

#ifndef VVAVE_H
#define VVAVE_H

#include <QObject>
#include "utils/bae.h"
#include <functional>

class CollectionDB;
class vvave : public QObject
{
    Q_OBJECT
private:
    CollectionDB *db;
    void checkCollection(const QStringList &paths = BAE::defaultSources, std::function<void (uint)> cb = nullptr);

public:
    explicit vvave(QObject *parent = nullptr);

signals:
    void refreshTables(uint size);
    void refreshTracks();
    void refreshAlbums();
    void refreshArtists();
    void openFiles(QVariantList tracks);
    void refreshVideos();

public slots:
    ///DB Interfaces
    /// useful functions for non modeled views and actions with not direct access to a tracksmodel or its own model
    static QVariantList sourceFolders();
    bool removeSource(const QString &source);
    static QString moodColor(const int &index);
    static QStringList moodColors();
    void scanDir(const QStringList &paths = BAE::defaultSources);

    static QStringList getSourceFolders();
    void openUrls(const QStringList &urls);
};

#endif // VVAVE_H
