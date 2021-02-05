// Copyright 2021 Wang Rui <wangrui@jingos.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "videosmodel.h"
#include "db/collectionDB.h"

#ifdef STATIC_MAUIKIT
#include "fmstatic.h"
#else
#include <MauiKit/fmstatic.h>
#endif

#include <services/local/taginfo.h>

#include <QProcess>

VideosModel::VideosModel(QObject *parent) : MauiList(parent),
    db(CollectionDB::getInstance()) {}

void VideosModel::componentComplete()
{
    connect(this, &VideosModel::queryChangedVideos, this, &VideosModel::setList);
}

const FMH::MODEL_LIST &VideosModel::items() const
{
    return this->list;
}


void VideosModel::setQuery(const QString &query)
{
    this->query = query;
    emit this->queryChangedVideos();
}

QString VideosModel::getQuery() const
{
    return this->query;
}

void VideosModel::setSortBy(const SORTBY &sort)
{
    if (this->sort == sort)
        return;

    this->sort = sort;

    emit this->preListChanged();
    this->sortList();
    emit this->postListChanged();
    emit this->sortByChangedVideos();
}

VideosModel::SORTBY VideosModel::getSortBy() const
{
    return this->sort;
}

void VideosModel::sortList()
{
    if (this->sort == VideosModel::SORTBY::NONE)
        return;

    const auto key = static_cast<FMH::MODEL_KEY>(this->sort);
    qSort(this->list.begin(), this->list.end(), [key](const FMH::MODEL &e1, const FMH::MODEL &e2) -> bool
    {
        switch (key)
        {
        case FMH::MODEL_KEY::RATE:
        case FMH::MODEL_KEY::FAV:
        case FMH::MODEL_KEY::COUNT:
        {
            if (e1[key].toInt() > e2[key].toInt())
                return true;
            break;
        }

        case FMH::MODEL_KEY::TRACK:
        {
            if (e1[key].toInt() < e2[key].toInt())
                return true;
            break;
        }

        case FMH::MODEL_KEY::ADDDATE:
        case FMH::MODEL_KEY::RELEASEDATE:
        {
            if (e1[key].toLong() > e2[key].toLong())
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

            if (str1 < str2)
                return true;
            break;
        }

        default:
            if (e1[key] < e2[key])
                return true;
        }

        return false;
    });
}

void VideosModel::setList()
{
    emit this->preListChanged();

    if (this->query.startsWith("#"))
    {
        //do sth
    } else
    {
        this->list = this->db->getDBData(this->query, [&](FMH::MODEL &item)
        {
            const auto url = QUrl(item[FMH::MODEL_KEY::URL]);

            if (FMH::fileExists(url))
            {
                return true;
            } else
            {
                this->db->removeVideo(url.toString());
                return false;
            }
        });
    }

    this->sortList();
    emit this->postListChanged();
}

QVariantMap VideosModel::getVideos(const int &index) const
{
    if (index >= this->list.size() || index < 0)
        return QVariantMap();

    return FMH::toMap(this->list.at( this->mappedIndex(index)));
}

QVariantList VideosModel::getAllVideos()
{
    QVariantList res;
    for (const auto &item : this->list)
        res << FMH::toMap(item);

    return res;
}

void VideosModel::appendVideos(const QVariantMap &item)
{
    if (item.isEmpty())
        return;

    emit this->preItemAppended();
    this->list << FMH::toModel(item);
    emit this->postItemAppended();
}

void VideosModel::appendVideos(const QVariantMap &item, const int &at)
{
    if (item.isEmpty())
        return;

    if (at > this->list.size() || at < 0)
        return;

    emit this->preItemAppendedAt(at);
    this->list.insert(at, FMH::toModel(item));
    emit this->postItemAppended();
}

void VideosModel::appendQueryVideos(const QString &query)
{
    emit this->preListChanged();
    this->list << this->db->getDBData(query);
    emit this->postListChanged();
}

void VideosModel::searchQueriesVideos(const QStringList &queries, const int &type)
{
    emit this->preListChanged();
    this->list.clear();

    for (auto searchQuery : queries)
    {

        searchQuery = searchQuery.trimmed();

        if (!searchQuery.isEmpty())
        {
            auto queryTxt = QString("select * from videos WHERE title LIKE \"%"+searchQuery+"%\" ORDER BY strftime(\"%s\", addDate) desc LIMIT 1000");//默认type为1 all
            if (type == 3) //lately中搜索
            {
                queryTxt = QString("select * from videos WHERE title LIKE \"%"+searchQuery+"%\" and count > 0 ORDER BY strftime(\"%s\", releaseDate) desc LIMIT 1000");
            }
            this->list << this->db->getDBData(queryTxt);
        }
    }

    emit this->postListChanged();
}

void VideosModel::clearVideos()
{
    emit this->preListChanged();
    this->list.clear();
    emit this->postListChanged();
}

bool VideosModel::colorVideos(const int &index, const QString &color)
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    auto item = this->list[index_];
    if (this->db->colorTagTrack(item[FMH::MODEL_KEY::URL], color))
    {
        this->list[index_][FMH::MODEL_KEY::COLOR] = color;
        emit this->updateModel(index_, {FMH::MODEL_KEY::COLOR});
        return true;
    }

    return false;
}

bool VideosModel::favVideos(const int &index, const bool &value)
{
    if (index >= this->list.size() || index < 0)
    {
        return false;
    }


    const auto index_ = this->mappedIndex(index);

    auto item = this->list[index_];

    if (value)
        FMStatic::fav(item[FMH::MODEL_KEY::URL]);
    else
        FMStatic::unFav(item[FMH::MODEL_KEY::URL]);

    this->list[index_][FMH::MODEL_KEY::FAV] = value ?  "1" : "0";
    emit this->updateModel(index_, {FMH::MODEL_KEY::FAV});

    return true;
}

bool VideosModel::rateVideos(const int &index, const int &value)
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    auto item = this->list[index_];
    if (this->db->rateTrack(item[FMH::MODEL_KEY::URL], value))
    {
        this->list[index_][FMH::MODEL_KEY::RATE] = QString::number(value);
        emit this->updateModel(index_, {FMH::MODEL_KEY::RATE});

        return true;
    }

    return false;
}

bool VideosModel::countUpVideos(const int &index, const bool &value)//modify by hjy false 表示清空
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    auto item = this->list[index_];

    int increment = 0;
    if (value)
    {
        increment = 1;
    } else
    {
        if (this->list[index_][FMH::MODEL_KEY::COUNT].toInt() > 0)
        {
            increment = -1;
        }

    }
    this->db->playedVideo(item[FMH::MODEL_KEY::URL], increment);
    this->db->updateTimeToDB(item[FMH::MODEL_KEY::URL], 2);

    return false;
}


bool VideosModel::removeVideos(const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    emit this->preItemRemoved(index_);
    this->list.removeAt(index_);
    emit this->postItemRemoved();

    return true;
}

void VideosModel::refreshVideos()
{
    this->setList();
}

bool VideosModel::updateVideos(const QVariantMap &data, const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);

    auto newData = this->list[index_];
    QVector<int> roles;

    for (auto key : data.keys())
        if (newData[FMH::MODEL_NAME_KEY[key]] != data[key].toString())
        {
            newData.insert(FMH::MODEL_NAME_KEY[key], data[key].toString());
            roles << FMH::MODEL_NAME_KEY[key];
        }

    this->list[index_] = newData;
    emit this->updateModel(index_, roles);
    return true;
}

bool VideosModel::playVideo()
{
    if (harunaArguments.isEmpty())
    {
        return false;
    }

    QString kill = "killall -9 haruna";
    QProcess process(this);
    process.execute(kill);

    QString program = "/usr/bin/haruna";
    process.startDetached(program, harunaArguments);
    return true;
}

bool VideosModel::updateHarunaArguments(const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);
    harunaArguments.clear();
    harunaArguments << QString::number(1);
    harunaArguments << QString::number(index_);

    for (int i = 0; i < this->list.size(); i++)
    {
        auto item = this->list[i];
        auto url = item[FMH::MODEL_KEY::URL];
        harunaArguments << QString(url).mid(7);
    }

    return true;
}


bool VideosModel::deleteFileVideos(const int &index)
{
    if (index >= this->list.size() || index < 0)
        return false;

    const auto index_ = this->mappedIndex(index);
    auto item = this->list[index_];
    auto url = item[FMH::MODEL_KEY::URL];

    QString localPath = url.mid(7);
    QFile fileTemp(localPath);
    fileTemp.remove();

    auto tempPath = item[FMH::MODEL_KEY::GENRE];
    QFile filePngTemp(tempPath.mid(7));
    filePngTemp.remove();

    return true;
}



bool VideosModel::copyFileVideos(const int &index, const bool &value)//bool--是否覆盖文件  暂时不需要这个功能
{
    // if(index >= this->list.size() || index < 0)
    // 	return false;

    // const auto index_ = this->mappedIndex(index);
    // auto item = this->list[index_];
    // auto url = item[FMH::MODEL_KEY::URL].mid(7);

    // QString sourceDir = url;
    // auto indexOfname = url.lastIndexOf("/");
    // QString toDir(BAE::VideoPath.mid(7) + url.mid(indexOfname));

    // if (sourceDir == toDir){
    // 	return true;
    // }
    // if (!QFile::exists(sourceDir)){
    // 	return false;
    // }
    // QDir *createfile = new QDir;
    // bool exist = createfile->exists(toDir);
    // if (exist){
    // 	if(value){
    // 		createfile->remove(toDir);
    // 	}
    // }//end if

    // if(!QFile::copy(sourceDir, toDir))
    // {
    // 	return false;
    // }
    return true;
}

