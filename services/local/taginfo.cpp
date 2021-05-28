/*
   Babe - tiny music player
   Copyright (C) 2017  Camilo Higuita
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

#include "taginfo.h"
#include "../../utils/bae.h"

#include <taglib/mpegfile.h>
#include <taglib/mp4file.h>
#include <taglib/id3v2tag.h>
#include <taglib/attachedpictureframe.h>

using namespace BAE;

TagInfo::TagInfo(const QString &url, QObject *parent) : QObject(parent)
{
    this->path = url;
    QFileInfo _file(this->path);

    if(_file.isReadable())
    {
        this->file = new TagLib::FileRef(TagLib::FileName(path.toUtf8()));
    }
    else
        this->file = new TagLib::FileRef();
}

TagInfo::~TagInfo()
{
    delete this->file;
}

bool TagInfo::isNull()
{
    return this->file->isNull();
}

QString TagInfo::getAlbum() const
{
    const auto value = QString::fromStdWString(file->tag()->album().toWString());
    return !value.isEmpty()
            ? value
            : SLANG[W::UNKNOWN];
}

QString TagInfo::getTitle() const
{
    const auto value = QString::fromStdWString(file->tag()->title().toWString());
    return !value.isEmpty()
            ? value
            : fileName();
}

QString TagInfo::getArtist() const
{
    const auto value = QString::fromStdWString(file->tag()->artist().toWString());
    return !value.isEmpty()
            ? value
            : SLANG[W::UNKNOWN];
}

int TagInfo::getTrack() const { return static_cast<signed int>(file->tag()->track()); }

QString TagInfo::getGenre() const
{
    const auto value = "file://" + this->cover_path;
    return !value.isEmpty()
            ? value
            : SLANG[W::UNKNOWN];
}

QString TagInfo::fileName() const
{
    return BAE::getNameFromLocation(path);
}

uint TagInfo::getYear() const
{
    return file->tag()->year();
}


int TagInfo::getDuration() const
{
    return file->audioProperties()->length();
}

QString TagInfo::getComment() const
{
    const auto value = QString::fromStdWString(file->tag()->comment().toWString());
    return !value.isEmpty()
            ?value
           : SLANG[W::UNKNOWN];
}

bool TagInfo::getCover() //const
{
    int index = path.lastIndexOf(".");
    QString newPath = path.mid(0, index);//path/name
    index = newPath.lastIndexOf("/");
    QString startPath = newPath.mid(0, index + 1);//path/
    QString endPath = newPath.mid(index + 1, newPath.length());//name
    this->cover_path = startPath + "." + endPath + ".png";

    QFileInfo fileInfo(path);
    QString fileExtension = fileInfo.completeSuffix();
    // if(fileExtension == "m4a")
    // {
    //     std::unique_ptr<TagLib::MP4::File> mp4File(new TagLib::MP4::File(
    //                 QFile::encodeName(path).constData()));
    //     if(mp4File->isOpen()) {
	// 		TagLib::MP4::ItemListMap itemListMap = mp4File->tag()->itemListMap();
	// 		TagLib::MP4::Item albumArtItem = itemListMap["covr"];
	// 		TagLib::MP4::CoverArtList albumArtList = albumArtItem.toCoverArtList();
	// 		TagLib::MP4::CoverArt albumArt = albumArtList.front();
	// 		QImage image = QImage::fromData((const uchar *)albumArt.data().data(),
	// 						albumArt.data().size());
    //         image.save(this->cover_path);
    //         return true;
	// 	}
    // }
    // else 
    if(fileExtension == "mp3")
    {
        std::unique_ptr<TagLib::MPEG::File> mpegFile(new TagLib::MPEG::File(
                    QFile::encodeName(path).constData()));
        if(mpegFile->isOpen())
        {
            auto tag = mpegFile->ID3v2Tag(false);
            auto list = tag->frameListMap()["APIC"];
            if(!list.isEmpty()) {
                auto frame = list.front();
                auto pic = reinterpret_cast<TagLib::ID3v2::AttachedPictureFrame *>(frame);
                if(pic && !pic->picture().isNull())
                {
                    QImage image = QImage::fromData((const uchar *)pic->picture().data(), pic->picture().size());
                    image.save(this->cover_path);
                    return true;
                }
            }

        }
    }

    this->cover_path = "";
	return false;
}

void TagInfo::setCover(const QByteArray &array)
{
    Q_UNUSED(array);
}

void TagInfo::setComment(const QString &comment)
{
    this->file->tag()->setComment(comment.toStdString());
    this->file->save();
}

void TagInfo::setAlbum(const QString &album)
{
    this->file->tag()->setAlbum(album.toStdString());
    this->file->save();
}

void TagInfo::setTitle(const QString &title)
{
    this->file->tag()->setTitle(title.toStdString());
    this->file->save();
}

void TagInfo::setTrack(const int &track)
{
    this->file->tag()->setTrack(static_cast<unsigned int>(track));
    this->file->save();
}

void TagInfo::setArtist(const QString &artist)
{
    this->file->tag()->setArtist(artist.toStdString());
    this->file->save();
}

void TagInfo::setGenre(const QString &genre)
{
    this->file->tag()->setGenre(genre.toStdString());
    this->file->save();
}
