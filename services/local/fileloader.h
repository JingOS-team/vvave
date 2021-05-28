// Copyright 2020 Wang Rui <wangrui@jingos.com>

#ifndef FILELOADER_H
#define FILELOADER_H

#include <QObject>
#include <QDirIterator>
#include <QUrl>
#include <QPixmap>
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

    if (QFileInfo(url.toLocalFile()).isDir())
    {
        QDirIterator it(url.toLocalFile(), QStringList() << FMH::FILTER_LIST[FMH::FILTER_TYPE::AUDIO] << "*.m4a", QDir::Files, QDirIterator::Subdirectories);

        while (it.hasNext())
            urls << QUrl::fromLocalFile(it.next());

    }else if (QFileInfo(url.toLocalFile()).isFile())
        urls << url.toString();

    return urls;
}

// returns the number of new items added to the collection db
static inline uint getTracks(const QList<QUrl>& paths, vvave *babe)
{
    const auto db = CollectionDB::getInstance();
    const auto urls = std::accumulate(paths.begin(), paths.end(), QList<QUrl>(), getPathContents);

    for(const auto &path : paths)
        if(path.isLocalFile() && FMH::fileExists(path))
            db->addFolder(path.toString());

    uint newTracks = 0;

    if(urls.isEmpty())
        return newTracks;

    for(const auto &url : urls)
    {
        if(db->check_existance(BAE::TABLEMAP[BAE::TABLE::TRACKS], FMH::MODEL_NAME[FMH::MODEL_KEY::URL], url.toString()))
            continue;

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

        FMH::MODEL trackMap =
        {
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

        if(db->addTrack(trackMap))
        {
            newTracks++;
        }

        if(newTracks % 5 == 0)
        {
            emit babe->refreshTables(20);
        }
    }
    emit babe->refreshTables(20);
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

    if(urls.isEmpty())
        return newVideos;

    for(const auto &url : urls)
    {
        if(db->check_existance(BAE::TABLEMAP[BAE::TABLE::VIDEOS], FMH::MODEL_NAME[FMH::MODEL_KEY::URL], url.toString()))
            continue;

        MediaInfoLib::MediaInfo MI;
        auto duration = 0;
        auto width = 800;
        auto height = 600;
        if(MI.Open(url.toLocalFile().toStdWString())) {
            duration = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Duration"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt() / 1000;
            width = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Width"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            width = width > 0 ? width : 800;
            height = QString::fromStdWString(MI.Get(MediaInfoLib::Stream_Video, 0, __T("Height"), MediaInfoLib::Info_Text, MediaInfoLib::Info_Name)).toInt();
            height = height > 0 ? height : 600;
        }


        auto indexOfname = url.toString().lastIndexOf("/");
        auto name = url.toString().mid(indexOfname + 1);
        
        //获取缩略图
        auto path = url.toString();
        int index = path.lastIndexOf(".");
        QString newPath = path.mid(0, index);//path/name
        index = newPath.lastIndexOf("/");
        QString startPath = newPath.mid(0, index + 1);//path/
        QString endPath = newPath.mid(index + 1, newPath.length());//name
        path = startPath + "." + endPath + ".jpg";

        QStringList plugins;
        plugins << KIO::PreviewJob::availablePlugins();
        KFileItemList list;
        list.append(KFileItem(url, QString(), 0));
        KIO::PreviewJob *job = KIO::filePreview(list, QSize(width, height), &plugins);
        job->setIgnoreMaximumSize(true);
        job->setScaleType(KIO::PreviewJob::ScaleType::Unscaled);
        
        QObject::connect(job, &KIO::PreviewJob::gotPreview, [=] (const KFileItem &item, const QPixmap &preview) {
            preview.save(path.mid(7), "JPG");
        });
        QObject::connect(job, &KIO::PreviewJob::failed, [=] (const KFileItem &item) {
        });
        job->exec();
        //获取缩略图 end


        const auto sourceUrl = FMH::parentDir(url).toString();
        FMH::MODEL videoMap =
        {
            {FMH::MODEL_KEY::URL, url.toString()},
            {FMH::MODEL_KEY::SOURCE, sourceUrl},
            {FMH::MODEL_KEY::TITLE, name},
            {FMH::MODEL_KEY::DURATION, QString::number(duration)},
            {FMH::MODEL_KEY::GENRE, path}
        };

        if(db->addVideo(videoMap))
        {
            newVideos++;
        }   

        if(newVideos % 5 == 0)
        {
            emit babe->refreshTables(20);
        }
        
    }

    emit babe->refreshTables(20);

    return newVideos;
}

}

#endif // FILELOADER_H
