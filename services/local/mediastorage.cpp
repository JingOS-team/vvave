/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 * Copyright (C) 2021  Yu Jiashu <yujiashu@jingos.com>
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

#include "mediastorage.h"

#include <QDataStream>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>
#include <QSize>
#include <QPixmap>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QMimeDatabase>

#include <kio/copyjob.h>
#include <kio/previewjob.h>

MediaStorage::MediaStorage(const QString &url, QObject *parent)
    : QObject(parent)
{
    this->path = url;
    QFileInfo _file(this->path);
}

MediaStorage::~MediaStorage()
{
}


void MediaStorage::getCover()
{
    QStringList plugins;
    plugins << KIO::PreviewJob::availablePlugins();
    KFileItemList list;
    list.append(KFileItem(QUrl("file://" + this->path),  QString(), 0));
    KIO::PreviewJob *job = KIO::filePreview(list, QSize(330, 206), &plugins);
    job->setIgnoreMaximumSize(true);
    job->setScaleType(KIO::PreviewJob::ScaleType::Unscaled);
    connect(job, &KIO::PreviewJob::gotPreview, this, &MediaStorage::gotPreviewed);
}

void MediaStorage::gotPreviewed(const KFileItem &item, const QPixmap &preview)
{   

}
