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

#ifndef PULPO_H
#define PULPO_H

#include <QPixmap>
#include <QList>
#include <QDebug>
#include <QImage>
#include <QtCore>
#include <QUrl>
#include <QObject>
#include <QVariantMap>

#include "../utils/bae.h"
#include "enums.h"

using namespace PULPO;

class Pulpo : public QObject
{
    Q_OBJECT

public:
    explicit Pulpo(QObject *parent = nullptr);
    ~Pulpo();

    void request(const PULPO::REQUEST &request);

private:
    void start();
    QList<SERVICES> services = {};

    PULPO::REQUEST req;

    void passSignal(const REQUEST &request, const RESPONSES &responses);

signals:
    void infoReady(PULPO::REQUEST request, PULPO::RESPONSES responses);
    void error();
    void finished();
};

#endif // ARTWORK_H
