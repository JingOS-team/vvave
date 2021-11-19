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

#ifndef YOUTUBEDL_H
#define YOUTUBEDL_H
#include <QObject>
#include <QWidget>
#include <QProcess>
#include <QByteArray>
#include <QMovie>
#include <QDebug>
#include <QDirIterator>

#include "../../utils/bae.h"
#include "../local/taginfo.h"

#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
class Notify;
#endif
class youtubedl : public QObject
{
    Q_OBJECT

public:
    explicit youtubedl(QObject *parent = nullptr);
    ~youtubedl();
    void fetch(const QString &json);
    QStringList ids;

private slots:
    void processFinished();
    void processFinished_totally(const int &state, const FMH::MODEL &info, const QProcess::ExitStatus &exitStatus);

private:
    const QString ydl="youtube-dl -f m4a --youtube-skip-dash-manifest -o \"$$$.%(ext)s\"";
#if (defined (Q_OS_LINUX) && !defined (Q_OS_ANDROID))
    Notify *nof;
#endif

signals:
    void done();
};

#endif // YOUTUBEDL_H
