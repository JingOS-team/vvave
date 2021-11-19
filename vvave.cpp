/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#include "vvave.h"

#include "db/collectionDB.h"
#include "services/local/fileloader.h"

#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
#include "kde/notify.h"
#endif

#include <QtConcurrent>
#include <QFuture>
#include <QDebug>
#ifdef STATIC_MAUIKIT
#include "fm.h"
#else
#include <MauiKit/fm.h>
#endif

#include <kdirwatch.h>

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

bool vvave::readVideoEnd()
{
    return readVideoFileEnd;
}

void vvave::setReadVideoEnd(bool flag)
{
    if(readVideoFileEnd != flag) {
          readVideoFileEnd = flag;
    }
}

bool vvave::readMusicEnd()
{
    return readMusicFileEnd;
}

void vvave::setReadMusicEnd(bool flag)
{
    if(readMusicFileEnd != flag) {
          readMusicFileEnd = flag;
    }
}

//// PUBLIC SLOTS
QVariantList vvave::sourceFolders()
{
    const auto sources = CollectionDB::getInstance()->getDBData("select * from sources");
    QVariantList res;
    for(const auto &item : sources)
        res << FMH::getDirInfo(item[FMH::MODEL_KEY::URL]);
    return res;
}

bool vvave::removeSource(const QString &source)
{
    if(!this->getSourceFolders().contains(source))
        return false;
    return this->db->removeSource(source);
}

QString vvave::moodColor(const int &index)
{
    if(index < BAE::MoodColors.size() && index > -1)
        return BAE::MoodColors.at(index);
    else return "";
}

QStringList vvave::moodColors()
{
    return BAE::MoodColors;
}

void vvave::scanDir(const QStringList &paths)
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
    if(urls.isEmpty()) return;

    for(const auto &url : urls)
    {
        auto _url = QUrl::fromUserInput(url);
        emit this->playThirdMusic(_url.toString());
        break;
    }
}



