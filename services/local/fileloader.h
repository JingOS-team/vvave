/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 * Copyright (C) 2020 Wang Rui <wangrui@jingos.com>
 * Copyright (C) 2021 Yu Jiashu <yujiashu@jingos.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef FILELOADER_H
#define FILELOADER_H

#include <QObject>
#include <QDirIterator>
#include <QUrl>
#include <QPixmap>
#include <QTextStream>
#include <QElapsedTimer>

#include "services/local/taginfo.h"
#include "services/local/mediastorage.h"
#include "db/collectionDB.h"
#include "utils/bae.h"

#define UNICODE
#include <MediaInfo/MediaInfo.h>
#include <QProcess>
#include "vvave.h"
#include <KFileMetaData/PropertyInfo>
#include <KFileMetaData/UserMetaData>
#include <kio/previewjob.h>

namespace FLoader
{

static inline QList<QUrl> getPathContents(QList<QUrl> &urls, const QUrl &url)
{
    if(!FMH::fileExists(url) && !url.isLocalFile())
        return urls;

    if (QFileInfo(url.toLocalFile()).isDir()){
        QDirIterator it(url.toLocalFile(), QStringList() << FMH::FILTER_LIST[FMH::FILTER_TYPE::AUDIO] << "*.m4a", QDir::Files, QDirIterator::Subdirectories);

        while (it.hasNext())
            urls << QUrl::fromLocalFile(it.next());

    }else if (QFileInfo(url.toLocalFile()).isFile())
        urls << url.toString();

    return urls;
}


static bool needRefresh = false;
// returns the number of new items added to the collection db
static inline uint getTracks(const QList<QUrl>& paths, vvave *babe)
{
    const auto db = CollectionDB::getInstance();
    const auto urls = std::accumulate(paths.begin(), paths.end(), QList<QUrl>(), getPathContents);

    for(const auto &path : paths)
        if(path.isLocalFile() && FMH::fileExists(path))
            db->addFolder(path.toString());

    uint newTracks = 0;

    if(urls.isEmpty()) {
        return newTracks;
    }

    int resetTimecount = 0;
    QElapsedTimer timer;
    timer.start();
    babe->setReadMusicEnd(false);
    for(const auto &url : urls) {

        if(db->check_existance(BAE::TABLEMAP[BAE::TABLE::TRACKS], FMH::MODEL_NAME[FMH::MODEL_KEY::URL], url.toString())){
            continue;
        }

        TagInfo info(url.toLocalFile());
        if(info.isNull())
            continue;
        info.getCover();
        const auto track = info.getTrack();
        const auto genre = info.getGenre();
        const auto album = BAE::fixString(info.getAlbum());
        const auto title = BAE::fixString(info.getTitle()); /* to fix*/
        const auto artist = BAE::fixString(info.getArtist());
        const auto sourceUrl = FMH::parentDir(url).toString();
        const auto duration = info.getDuration();
        const auto year = info.getYear();

        FMH::MODEL trackMap ={
            {FMH::MODEL_KEY::URL, url.toString()},
            {FMH::MODEL_KEY::TRACK, QString::number(track)},
            {FMH::MODEL_KEY::TITLE, title},
            {FMH::MODEL_KEY::ARTIST, artist},
            {FMH::MODEL_KEY::ALBUM, album},
            {FMH::MODEL_KEY::DURATION,QString::number(duration)},
            {FMH::MODEL_KEY::GENRE, genre},
            {FMH::MODEL_KEY::SOURCE, sourceUrl},
            {FMH::MODEL_KEY::FAV, "0"},
            {FMH::MODEL_KEY::RELEASEDATE, QString::number(year)}
        };

        BAE::artworkCache(trackMap, FMH::MODEL_KEY::ALBUM);

        if(db->addTrack(trackMap)){
            newTracks++;
        }

        if(timer.elapsed() >= 100){
            resetTimecount ++ ;
            if(resetTimecount >3) {
                if(newTracks > 50) {
                    if(timer.elapsed() >= 2000) {
                        emit babe->refreshTracks();
                        timer.restart();
                    }
                } else {
                    emit babe->refreshTracks();
                    timer.restart();
                }
            } else {
                emit babe->refreshTracks();
                timer.restart();
            }
        }
    }

    timer.invalidate();
    emit babe->refreshTracks();
    needRefresh = true;
    babe->setReadMusicEnd(true);
    return newTracks;
}

static inline QList<QUrl> getPathContentsForVideo(QList<QUrl> &urls, const QUrl &url)
{
    if(!FMH::fileExists(url) && !url.isLocalFile())
        return urls;

    if (QFileInfo(url.toLocalFile()).isDir())
    {
        auto videoTypeList = QStringList() << FMH::FILTER_LIST[FMH::FILTER_TYPE::VIDEO];
        videoTypeList.removeOne("*.ogg");
        videoTypeList << "*.mov";
        videoTypeList << "*.ts";
        QDirIterator it(url.toLocalFile(), videoTypeList, QDir::Files, QDirIterator::Subdirectories);

        while (it.hasNext())
            urls << QUrl::fromLocalFile(it.next());

    }else if (QFileInfo(url.toLocalFile()).isFile())
        urls << url.toString();

    return urls;
}

// returns the number of new video added to the collection db
static inline uint getVideos(const QList<QUrl>& paths, vvave *babe)
{
    const auto db = CollectionDB::getInstance();
    const auto urls = std::accumulate(paths.begin(), paths.end(), QList<QUrl>(), getPathContentsForVideo);

    for(const auto &path : paths)
        if(path.isLocalFile() && FMH::fileExists(path))
            db->addFolder(path.toString());

    uint newVideos = 0;

    if(urls.isEmpty()){
        return newVideos;
    }

    QElapsedTimer timer;
    timer.start();

    for(const auto &url : urls) {
        if(db->check_existance(BAE::TABLEMAP[BAE::TABLE::VIDEOS], FMH::MODEL_NAME[FMH::MODEL_KEY::URL], url.toString()))
            continue;
        MediaInfoLib::MediaInfo MI;
        auto duration = 0;
        auto width = 800;
        auto height = 600;
        int videorotation = 0;
        if(MI.Open(url.toLocalFile().toStdWString())) {
            duration = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_General, 0, __T("Duration"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt() / 1000;
            if(duration == 0) {
                duration = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Duration"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt() / 1000;
            }
            width = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Width"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            width = width > 0 ? width : 800;
            height = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Height"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            height = height > 0 ? height : 600;

            videorotation = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Rotation"))).toDouble();
        }

        auto indexOfname = url.toString().lastIndexOf("/");
        auto name = url.toString().mid(indexOfname + 1);
        
        auto path = url.toString();
        int index = path.lastIndexOf(".");
        QString newPath = path.mid(0, index);
        index = newPath.lastIndexOf("/");
        QString startPath = newPath.mid(0, index + 1);
        QString endPath = newPath.mid(index + 1, newPath.length());
        path = startPath + "." + endPath + ".jpg";

        QStringList plugins;
        plugins << KIO::PreviewJob::availablePlugins();
        KFileItemList list;
        list.append(KFileItem(url, QString(), 0));
        KIO::PreviewJob *job = KIO::filePreview(list, QSize(width, height), &plugins);
        job->setIgnoreMaximumSize(true);
        job->setScaleType(KIO::PreviewJob::ScaleType::Unscaled);
        
        QObject::connect(job, &KIO::PreviewJob::gotPreview, [=] (const KFileItem &item, const QPixmap &preview) {

            QTransform tranform;
            tranform.rotate(videorotation);
            QPixmap transPix = QPixmap(preview.transformed(tranform,Qt::SmoothTransformation));

            transPix.save(path.mid(7), "JPG");
        });
        QObject::connect(job, &KIO::PreviewJob::failed, [=] (const KFileItem &item) {
            qDebug()<<" get thumb fail:::" << item.url();
        });
        job->exec();

        const auto sourceUrl = FMH::parentDir(url).toString();
        FMH::MODEL videoMap = {
            {FMH::MODEL_KEY::URL, url.toString()},
            {FMH::MODEL_KEY::SOURCE, sourceUrl},
            {FMH::MODEL_KEY::TITLE, name},
            {FMH::MODEL_KEY::DURATION, QString::number(duration)},
            {FMH::MODEL_KEY::GENRE, path}
        };

        if(db->addVideo(videoMap)) {
            newVideos++;
        }   

        if(timer.elapsed() >= 100){
            emit babe->refreshVideos();
            timer.restart();
        }
    }

    timer.invalidate();
    emit babe->refreshVideos();
    return newVideos;
}

}

#endif // FILELOADER_H
