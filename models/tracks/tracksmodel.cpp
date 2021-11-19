/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#include "tracksmodel.h"
#include "db/collectionDB.h"

#ifdef STATIC_MAUIKIT
#include "fmstatic.h"
#else
#include <MauiKit/fmstatic.h>
#endif

#include <services/local/taginfo.h>

#include <QProcess>
#include<QDBusConnection>
#include <QDBusMessage>
#include <QStringList>
#include <QVariantMap>
#include <QFile>
#include <QUrl>

TracksModel::TracksModel(QObject *parent) : MauiList(parent),
    db(CollectionDB::getInstance()) {
}

void TracksModel::componentComplete()
{
    connect(this, &TracksModel::queryChanged, this, &TracksModel::setList);
}

const FMH::MODEL_LIST &TracksModel::items() const
{
    return this->list;
}


void TracksModel::setQuery(const QString &query)
{
    this->query = query;
    emit this->queryChanged();
}

QString TracksModel::getQuery() const
{
    return this->query;
}

void TracksModel::setSortBy(const SORTBY &sort)
{
    if(this->sort == sort)
        return;

    this->sort = sort;

    emit this->preListChanged();
    this->sortList();
    emit this->postListChanged();
    emit this->sortByChanged();
}

TracksModel::SORTBY TracksModel::getSortBy() const
{
    return this->sort;
}

QVariantMap TracksModel::currentTrack() const
{
    return m_currentTrack;
}

int TracksModel::currentIndex() const
{
    return m_currentIndex;
}

void TracksModel::sortList()
{
    if(this->sort == TracksModel::SORTBY::NONE)
        return;

    const auto key = static_cast<FMH::MODEL_KEY>(this->sort);
    qSort(this->list.begin(), this->list.end(), [key](const FMH::MODEL &e1, const FMH::MODEL &e2) -> bool
    {
        switch(key)
        {
        case FMH::MODEL_KEY::RATE:
        case FMH::MODEL_KEY::FAV:
        case FMH::MODEL_KEY::COUNT:
        {
            if(e1[key].toInt() > e2[key].toInt())
                return true;
            break;
        }

        case FMH::MODEL_KEY::TRACK:
        {
            if(e1[key].toInt() < e2[key].toInt())
                return true;
            break;
        }

        case FMH::MODEL_KEY::RELEASEDATE:
        case FMH::MODEL_KEY::ADDDATE:
        {
            if(e1[key].toLong() > e2[key].toLong())
            {
                return true;
            }
            break;
        }

        case FMH::MODEL_KEY::TITLE:
        case FMH::MODEL_KEY::ARTIST:
        case FMH::MODEL_KEY::ALBUM:
        case FMH::MODEL_KEY::FORMAT:
        {
            const auto str1 = QString(e1[key]).toLower();
            const auto str2 = QString(e2[key]).toLower();

            if(str1 < str2)
                return true;
            break;
        }

        default:
            if(e1[key] < e2[key])
                return true;
        }

        return false;
    });
}

void TracksModel::setList()
{
    emit this->preListChanged();

    if(this->query.startsWith("#")) {
        if(this->query == "#favs") {
            this->list.clear();
            const auto urls = FMStatic::getTagUrls("fav", {}, true);
            for(const auto &url : urls) {
                this->list << this->db->getDBData(QString("select t.*, al.artwork from tracks t inner join albums al on al.album = t.album and al.artist = "
                              "t.artist where t.url = %1").arg("\""+url.toString()+"\""), [](FMH::MODEL &item) {
                              item[FMH::MODEL_KEY::FAV]  = "1";
                return true;
            });
            }
        }
    } else {
        this->list = this->db->getDBData(this->query, [&](FMH::MODEL &item) {
        const auto url = QUrl(item[FMH::MODEL_KEY::URL]);
        if(FMH::fileExists(url)) {
        return true;
        } else {
            this->db->removeTrack(url.toString());
            return false;
        }
        });
    }
    this->sortList();
    emit this->postListChanged();
}

QVariantMap TracksModel::get(const int &index) const
{
    if(index >= this->list.size() || index < 0)
        return QVariantMap();

    return FMH::toMap(this->list.at( this->mappedIndex(index)));
}

QVariantList TracksModel::getAll()
{
    QVariantList res;
    for(const auto &item : this->list)
        res << FMH::toMap(item);

    return res;
}

void TracksModel::append(const QVariantMap &item)
{
    if(item.isEmpty())
        return;

    emit this->preItemAppended();
    this->list << FMH::toModel(item);
    emit this->postItemAppended();
}

void TracksModel::justAppend(const QVariantMap &item)
{
    if(item.isEmpty())
        return;
    this->list << FMH::toModel(item);
}

void TracksModel::appendRefresh()
{
    emit this->preListChanged();
    emit this->postListChanged();
}

void TracksModel::append(const QVariantMap &item, const int &at)
{
    if(item.isEmpty())
        return;

    if(at > this->list.size() || at < 0)
        return;

    emit this->preItemAppendedAt(at);
    this->list.insert(at, FMH::toModel(item));
    emit this->postItemAppended();
}

void TracksModel::appendQuery(const QString &query)
{
    emit this->preListChanged();
    this->list << this->db->getDBData(query);
    emit this->postListChanged();
}

void TracksModel::searchQueries(const QStringList &queries, const int &type)
{
    emit this->preListChanged();
    this->list.clear();

    for(auto searchQuery : queries) {
        searchQuery = searchQuery.trimmed();

        if(!searchQuery.isEmpty()){
            auto queryTxt = QString("select * from tracks WHERE title LIKE \"%"+searchQuery+"%\" ORDER BY strftime(\"%s\", addDate) desc LIMIT 1000");//默认type为4 all
            if(type == 5) {
                const auto urls = FMStatic::getTagUrls("fav", {}, true);
                for(const auto &url : urls) {
                    this->list << this->db->getDBData(QString("select t.*, al.artwork from tracks t inner join albums al on al.album = t.album and al.artist = t.artist where t.title LIKE \"%"+searchQuery+"%\" and t.url = %1").arg("\""+url.toString()+"\""), [](FMH::MODEL &item) {item[FMH::MODEL_KEY::FAV]  = "1"; return true;});
                }
            emit this->postListChanged();
            return;
        } else if(type == 6) {
            queryTxt = QString("select * from tracks WHERE title LIKE \"%"+searchQuery+"%\" and count > 0 ORDER BY strftime(\"%s\", releaseDate) desc LIMIT 1000");
        }
        this->list << this->db->getDBData(queryTxt);
    }

}
emit this->postListChanged();
}

void TracksModel::clear()
{
    emit this->preListChanged();
    this->list.clear();
    emit this->postListChanged();
}

bool TracksModel::color(const int &index, const QString &color)
{
    if(index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);
    auto item = this->list[index_];
    if(this->db->colorTagTrack(item[FMH::MODEL_KEY::URL], color)) {
        this->list[index_][FMH::MODEL_KEY::COLOR] = color;
        emit this->updateModel(index_, {FMH::MODEL_KEY::COLOR});
        return true;
    }

    return false;
}

bool TracksModel::fav(const int &index, const bool &value)
{
    if(index >= this->list.size() || index < 0) {
        return false;
    }

    const auto index_ = this->mappedIndex(index);
    auto item = this->list[index_];

    if(value) {
        FMStatic::fav(item[FMH::MODEL_KEY::URL]);
        this->db->updateTimeToDB(item[FMH::MODEL_KEY::URL], 1);
    } else {
        FMStatic::unFav(item[FMH::MODEL_KEY::URL]);
    }

    this->list[index_][FMH::MODEL_KEY::FAV] = value ?  "1" : "0";
    emit this->updateModel(index_, {FMH::MODEL_KEY::FAV});

    return true;
}

bool TracksModel::rate(const int &index, const int &value)
{
    if(index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    auto item = this->list[index_];
    if(this->db->rateTrack(item[FMH::MODEL_KEY::URL], value)) {
        this->list[index_][FMH::MODEL_KEY::RATE] = QString::number(value);
        emit this->updateModel(index_, {FMH::MODEL_KEY::RATE});

        return true;
    }

    return false;
}

bool TracksModel::countUp(const int &index, const bool &value)
{
    if(index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);
    auto item = this->list[index_];
    int increment = 0;
    if(value) {
        if(this->list[index_][FMH::MODEL_KEY::COUNT].toInt() == 0) {
            increment = 1;
        }
    } else {
        if(this->list[index_][FMH::MODEL_KEY::COUNT].toInt() > 0) {
            increment = -1;
        }
    }
    this->db->playedTrack(item[FMH::MODEL_KEY::URL], increment);
    this->db->updateTimeToDB(item[FMH::MODEL_KEY::URL], 1);

    QString imagePath = item[FMH::MODEL_KEY::GENRE];
    QString title = item[FMH::MODEL_KEY::TITLE];
    QString artist = item[FMH::MODEL_KEY::ARTIST];
    QString album = item[FMH::MODEL_KEY::ALBUM];
    QString musicUrl = item[FMH::MODEL_KEY::URL];

    QDBusMessage msg = QDBusMessage::createSignal("/media/jingos/media",
                                                  "org.kde.media.jingos.media",
                                                  "updateTracksState");
    msg << imagePath;
    msg << title;
    msg << artist;
    msg << album;
    QDBusConnection::sessionBus().send(msg);
    m_currentIndex = index;
    m_currentTrack = QVariantMap();
    m_currentTrack["title"] = title;
    m_currentTrack["url"] = musicUrl;
    m_currentTrack["album"] = album;
    if (artist == "UNKNOWN") {
        artist = i18n("UNKNOWN");
    }
    m_currentTrack["artist"] = artist;
    if(imagePath == "file://") {
        m_currentTrack["artwork"] = "";
    } else {
        m_currentTrack["artwork"] = imagePath;
    }
    emit currentIndexChanged(index);
    emit currentTrackChanged(m_currentTrack);
    return false;
}

void TracksModel::emitpPlayingState(const bool &isPlay)
{
    QDBusMessage msg = QDBusMessage::createSignal("/media/jingos/media",
                                                  "org.kde.media.jingos.media",
                                                  "updatePlayingState");
    msg << isPlay;
    QDBusConnection::sessionBus().send(msg);
}


bool TracksModel::remove(const int &index)
{
    if(index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    emit this->preItemRemoved(index_);
    this->list.removeAt(index_);
    emit this->postItemRemoved();

    return true;
}

void TracksModel::refresh()
{
    this->setList();
}

bool TracksModel::update(const QVariantMap &data, const int &index)
{
    if(index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    auto newData = this->list[index_];
    QVector<int> roles;

    for(auto key : data.keys()) {
        if(newData[FMH::MODEL_NAME_KEY[key]] != data[key].toString()) {
            newData.insert(FMH::MODEL_NAME_KEY[key], data[key].toString());
            roles << FMH::MODEL_NAME_KEY[key];
        }
    }

    this->list[index_] = newData;
    emit this->updateModel(index_, roles);
    return true;
}

bool TracksModel::deleteFile(const int &index)
{
    if(index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);
    auto item = this->list[index_];
    auto url = item[FMH::MODEL_KEY::URL];


    QUrl tempUrl(item[FMH::MODEL_KEY::URL]);
    QFile fileTemp(tempUrl.toLocalFile());
    fileTemp.moveToTrash();

    auto tempPath = item[FMH::MODEL_KEY::GENRE];
    QFile filePngTemp(tempPath.mid(7));
    filePngTemp.remove();

    return true;
}

void TracksModel::deleteFiles(const QList<QUrl> &urls)
{
    for(const auto &url : urls) {
        QString path = url.toString();
        QFile fileTemp(url.toLocalFile());
        fileTemp.moveToTrash();

        int index = path.lastIndexOf(".");
        QString newPath = path.mid(0, index);
        index = newPath.lastIndexOf("/");
        QString startPath = newPath.mid(0, index + 1);
        QString endPath = newPath.mid(index + 1, newPath.length());
        auto tempPath = startPath + "." + endPath + ".png";;
        QFile filePngTemp(tempPath.mid(7));
        filePngTemp.remove();
    }
}


bool TracksModel::copyFile(const int &index, const bool &value)
{
    return true;
}

