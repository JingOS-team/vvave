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

#include "vvave.h"

#include "db/collectionDB.h"
#include "services/local/fileloader.h"
#include "utils/brain.h"

#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
#include "kde/notify.h"
#endif

#include <QtConcurrent>
#include <QFuture>

#ifdef STATIC_MAUIKIT
#include "fm.h"
#else
#include <MauiKit/fm.h>
#endif

/*
 * Sets upthe app default config paths
 * BrainDeamon to get collection information
 * YoutubeFetcher ?
 *
 * */
vvave::vvave(QObject *parent) : QObject(parent),
    db(CollectionDB::getInstance())
{
}

//// PUBLIC SLOTS
QVariantList vvave::sourceFolders()
{
    const auto sources = CollectionDB::getInstance()->getDBData("select * from sources");
    QVariantList res;
    for (const auto &item : sources)
        res << FMH::getDirInfo(item[FMH::MODEL_KEY::URL]);
    return res;
}

bool vvave::removeSource(const QString &source)
{
    if (!this->getSourceFolders().contains(source))
        return false;
    return this->db->removeSource(source);
}

QString vvave::moodColor(const int &index)
{
    if (index < BAE::MoodColors.size() && index > -1)
        return BAE::MoodColors.at(index);
    else return "";
}

QStringList vvave::moodColors()
{
    return BAE::MoodColors;
}

void vvave::scanDir(const QStringList &paths)//hjy 启动时候会走这个方法
{
    QFutureWatcher<uint> *watcher = new QFutureWatcher<uint>;
    connect(watcher, &QFutureWatcher<uint>::finished, [&, watcher]()
    {
        emit this->refreshTables( watcher->future().result());
        watcher->deleteLater();
    });

    const auto func = [=]() -> uint
    {
        FLoader::getVideos(QUrl::fromStringList(paths), this);
        return FLoader::getTracks(QUrl::fromStringList(paths), this);
    };

    QFuture<uint> t1 = QtConcurrent::run(func);
    watcher->setFuture(t1);
}

QStringList vvave::getSourceFolders()
{
    return CollectionDB::getInstance()-> getSourcesFolders();
}

void vvave::openUrls(const QStringList &urls)
{
    if (urls.isEmpty()) return;

    QVariantList data;

    for (const auto &url : urls)
    {
        auto _url = QUrl::fromUserInput(url);
        if (db->check_existance(BAE::TABLEMAP[BAE::TABLE::TRACKS], FMH::MODEL_NAME[FMH::MODEL_KEY::URL], _url.toString()))
        {
            data << FMH::toMap(this->db->getDBData(QStringList() << _url.toString()).first());
        } else
        {
            TagInfo info(_url.toLocalFile());
            if (!info.isNull())
            {
                const auto album = BAE::fixString(info.getAlbum());
                const auto track= info.getTrack();
                const auto title = BAE::fixString(info.getTitle()); /* to fix*/
                const auto artist = BAE::fixString(info.getArtist());
                const auto genre = info.getGenre();
                const auto sourceUrl = QFileInfo(_url.toLocalFile()).dir().path();
                const auto duration = info.getDuration();
                const auto year = info.getYear();

                data << QVariantMap({
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::URL], _url.toString()},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::TRACK], QString::number(track)},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::TITLE], title},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::ARTIST], artist},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::ALBUM], album},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::DURATION],QString::number(duration)},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::GENRE], genre},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::SOURCE], sourceUrl},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::FAV],"0"},
                    {FMH::MODEL_NAME[FMH::MODEL_KEY::RELEASEDATE], QString::number(year)}

                });
            }
        }
    }

    emit this->openFiles(data);
}



