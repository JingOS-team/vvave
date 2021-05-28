/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef MEDIASTORAGE_H
#define MEDIASTORAGE_H

#include <QDataStream>
#include <QDateTime>
#include <QObject>

#include <QMutex>
#include <QMutexLocker>

#include <kdirmodel.h>

class MediaStorage : public QObject
{
    Q_OBJECT
public:
    //MediaStorage(QObject *parent = 0);
    MediaStorage(const QString &url, QObject *parent = nullptr);
    virtual ~MediaStorage();

    void getCover();

protected Q_SLOTS:
    void gotPreviewed(const KFileItem &item, const QPixmap &preview);

private:
    QString path;
    QString cover_path;
};

#endif // MediaStorage_H
