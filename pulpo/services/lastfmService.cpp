/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#include "lastfmService.h"

using namespace PULPO;

lastfm::lastfm()
{    
    this->scope.insert(ONTOLOGY::ALBUM, {INFO::ARTWORK, INFO::WIKI, INFO::TAGS});
    this->scope.insert(ONTOLOGY::ARTIST, {INFO::ARTWORK, INFO::WIKI, INFO::TAGS});
    this->scope.insert(ONTOLOGY::TRACK, {INFO::TAGS, INFO::WIKI, INFO::ARTWORK, INFO::METADATA});

    connect(this, &lastfm::arrayReady, this, &lastfm::parse);
}

lastfm::~lastfm()
{

}

void lastfm::set(const PULPO::REQUEST &request)
{
    this->request = request;

    auto url = this->API;

    QUrl encodedArtist(this->request.track[FMH::MODEL_KEY::ARTIST]);
    encodedArtist.toEncoded(QUrl::FullyEncoded);

    switch(this->request.ontology)
    {
        case PULPO::ONTOLOGY::ARTIST:
        {
            url.append("?method=artist.getinfo");
            url.append(KEY);
            url.append("&artist=" + encodedArtist.toString());
            break;
        }

        case PULPO::ONTOLOGY::ALBUM:
        {
            QUrl encodedAlbum(this->request.track[FMH::MODEL_KEY::ALBUM]);
            encodedAlbum.toEncoded(QUrl::FullyEncoded);

            url.append("?method=album.getinfo");
            url.append(KEY);
            url.append("&artist=" + encodedArtist.toString());
            url.append("&album=" + encodedAlbum.toString());
            break;
        }

        case PULPO::ONTOLOGY::TRACK:
        {
            QUrl encodedTrack(this->request.track[FMH::MODEL_KEY::TITLE]);
            encodedTrack.toEncoded(QUrl::FullyEncoded);

            url.append("?method=track.getinfo");
            url.append(KEY);
            url.append("&artist=" + encodedArtist.toString());
            url.append("&track=" + encodedTrack.toString());
            url.append("&format=json");
            break;
        }
    }
    this->retrieve(url);
}


void lastfm::parseArtist(const QByteArray &array)
{
    QString xmlData(array);
    QDomDocument doc;

    if (!doc.setContent(xmlData)) {
        emit this->responseReady(this->request, this->responses);
        return;
    }

    if (doc.documentElement().toElement().attributes().namedItem("status").nodeValue()!="ok") {
        emit this->responseReady(this->request, this->responses);

        return;
    }


    QStringList artistTags;
    QByteArray artistSimilarArt;
    QStringList artistSimilar;
    QStringList artistStats;

    const QDomNodeList nodeList = doc.documentElement().namedItem("artist").childNodes();

    for (int i = 0; i < nodeList.count(); i++) {
        QDomNode n = nodeList.item(i);

        if (n.isElement()) {
            if(n.nodeName() == "image" && n.hasAttributes()) {
                if(this->request.info.contains(INFO::ARTWORK)) {
                    const auto imgSize = n.attributes().namedItem("size").nodeValue();
                    if (imgSize == "large" && n.isElement()) {
                        const auto artistArt_url = n.toElement().text();
                        this->responses << PULPO::RESPONSE {CONTEXT::IMAGE, artistArt_url};
                        if(this->request.info.size() == 1) break;
                        else continue;

                    } else continue;

                } else continue;
            }
        }
    }
    emit this->responseReady(this->request, this->responses);
}

void lastfm::parseAlbum(const QByteArray &array)
{
    QString xmlData(array);
    QDomDocument doc;

    if (!doc.setContent(xmlData)){
        emit this->responseReady(this->request, this->responses);
        return;
    }

    if (doc.documentElement().toElement().attributes().namedItem("status").nodeValue()!="ok") {
        emit this->responseReady(this->request, this->responses);
        return;
    }

    const auto nodeList = doc.documentElement().namedItem("album").childNodes();

    for (int i = 0; i < nodeList.count(); i++) {
        QDomNode n = nodeList.item(i);

        if (n.isElement()) {
            if(n.nodeName() == "image" && n.hasAttributes()) {
                if(this->request.info.contains(INFO::ARTWORK)) {
                    const auto imgSize = n.attributes().namedItem("size").nodeValue();

                    if (imgSize == "large" && n.isElement()) {
                        const auto albumArt_url = n.toElement().text();
                        this->responses << PULPO::RESPONSE {CONTEXT::IMAGE, albumArt_url};

                        if(this->request.info.size() == 1) break;
                        else continue;

                    } else continue;

                } else continue;
            }

            if (n.nodeName() == "wiki") {
                if(this->request.info.contains(INFO::WIKI)) {
                   const auto albumWiki = n.childNodes().item(1).toElement().text();

                    this->responses << PULPO::RESPONSE {CONTEXT::WIKI, albumWiki};

                    if(this->request.info.size() == 1) break;
                    else continue;

                } else continue;
            }

            if (n.nodeName() == "tags") {
                if(this->request.info.contains(INFO::TAGS)) {
                    auto tagsList = n.toElement().childNodes();
                    QStringList albumTags;
                    for(int i=0; i<tagsList.count(); i++) {
                        QDomNode m = tagsList.item(i);
                        albumTags<<m.childNodes().item(0).toElement().text();
                    }

                    this->responses << PULPO::RESPONSE {CONTEXT::TAG, albumTags};

                    if(this->request.info.size() == 1) break;
                    else continue;

                } else continue;
            }
        }
    }

    emit this->responseReady(this->request, this->responses);
}

