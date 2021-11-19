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

#ifndef NOTIFY_H
#define NOTIFY_H

#include <QObject>
#include <QByteArray>

#include <klocalizedstring.h>
#include <knotifyconfig.h>
#include <knotification.h>

#include <QStandardPaths>
#include <QPixmap>
#include <QDebug>
#include <QMap>
#include "../utils/bae.h"

class Notify : public QObject
{
    Q_OBJECT

public:
    explicit Notify(QObject *parent = nullptr);
    ~Notify();
    void notifySong(const FMH::MODEL &);
    void notify(const QString &title, const QString &body);

private:
  FMH::MODEL track;

signals:
    void babeSong();
    void skipSong();

public slots:
    void actions(uint id);
};

#endif // NOTIFY_H
