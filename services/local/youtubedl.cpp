/*
   Babe - tiny music player
   Copyright (C) 2017  Camilo Higuita
   Copyright (C) 2021 Yu Jiashu <yujiashu@jingos.com>
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


#include "youtubedl.h"
#include "../../pulpo/pulpo.h"
#include "../../db/collectionDB.h"
//#include "../../utils/babeconsole.h"

#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
#include "kde/notify.h"
#endif

using namespace BAE;

youtubedl::youtubedl(QObject *parent) : QObject(parent)
{
#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
    this->nof = new Notify(this);
#endif
}

youtubedl::~youtubedl(){}

void youtubedl::fetch(const QString &json)
{
    QJsonParseError jsonParseError;
    auto jsonResponse = QJsonDocument::fromJson(json.toUtf8(), &jsonParseError);

    if (jsonParseError.error != QJsonParseError::NoError) return;
    if (!jsonResponse.isObject()) return;

    QJsonObject mainJsonObject(jsonResponse.object());
    auto data = mainJsonObject.toVariantMap();

    auto id = data.value("id").toString().trimmed();
    auto title = data.value("title").toString().trimmed();
    auto artist = data.value("artist").toString().trimmed();
    auto album = data.value("album").toString().trimmed();
    auto playlist = data.value("playlist").toString().trimmed();
    auto page = data.value("page").toString().replace('"',"").trimmed();

//    bDebug::Instance()->msg("Fetching from Youtube: "+id+" "+title+" "+artist);

    FMH::MODEL infoMap;
    infoMap.insert(FMH::MODEL_KEY::TITLE, title);
    infoMap.insert(FMH::MODEL_KEY::ARTIST, artist);
    infoMap.insert(FMH::MODEL_KEY::ALBUM, album);
    infoMap.insert(FMH::MODEL_KEY::URL, page);
    infoMap.insert(FMH::MODEL_KEY::ID, id);
    infoMap.insert(FMH::MODEL_KEY::PLAYLIST, playlist);

    if(!this->ids.contains(infoMap[FMH::MODEL_KEY::ID]))
    {
        this->ids << infoMap[FMH::MODEL_KEY::ID];

        auto process = new QProcess(this);
        process->setWorkingDirectory(YoutubeCachePath);
        connect(process, static_cast<void(QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished),
                [=](int exitCode, QProcess::ExitStatus exitStatus)
        {
            processFinished_totally(exitCode, infoMap, exitStatus);
            process->deleteLater();
        });

#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
        this->nof->notify("Song received!", infoMap[FMH::MODEL_KEY::TITLE]+ " - "+ infoMap[FMH::MODEL_KEY::ARTIST]+".\nWait a sec while the track is added to your collection :)");
#endif
        auto command = ydl;

        command = command.replace("$$$",infoMap[FMH::MODEL_KEY::ID])+" "+infoMap[FMH::MODEL_KEY::ID];
        process->start(command);
    }
}

void youtubedl::processFinished_totally(const int &state,const FMH::MODEL &info,const QProcess::ExitStatus &exitStatus)
{
}


void youtubedl::processFinished()
{

}
