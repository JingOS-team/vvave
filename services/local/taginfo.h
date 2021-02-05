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

#ifndef TAGINFO_H
#define TAGINFO_H

#include <QString>
#include <QByteArray>
#include <QObject>

#if defined Q_OS_ANDROID || defined Q_OS_IOS
#include <taglib/tag.h>
#include <taglib/fileref.h>
#elif defined Q_OS_WIN32 || defined Q_OS_MACOS || defined Q_OS_LINUX
#include <taglib/tag.h>
#include <taglib/fileref.h>
#endif

class TagInfo : public QObject
{

    Q_OBJECT
public:
    TagInfo(const QString &url, QObject *parent = nullptr);
    ~TagInfo();
    bool isNull();
    QString getAlbum() const;
    QString getTitle() const;
    QString getArtist() const;
    int getTrack() const;
    QString getGenre() const;
    QString fileName() const;
    QString getComment() const;
    bool getCover();
    int getDuration() const;
    uint getYear() const;

    void setAlbum(const QString &album) ;
    void setTitle(const QString &title);
    void setTrack(const int &track);
    void setArtist(const QString &artist);
    void setGenre(const QString &genre);
    void setComment(const QString &comment);
    void setCover(const QByteArray &array);

private:
    TagLib::FileRef *file;
    QString path;
    wchar_t * m_path;
    QString cover_path;
};

#endif // TAGINFO_H
