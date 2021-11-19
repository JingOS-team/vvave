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

#ifndef YOUTUBE_H
#define YOUTUBE_H
#include <QObject>
#include <QWidget>
#include <QMap>
#include <QUrl>
#include <QVariant>

class YouTube : public QObject
{
    Q_OBJECT

    enum class METHOD : uint8_t
    {
        SEARCH
    };

public:
    explicit YouTube(QObject *parent = nullptr);
    ~YouTube();
    Q_INVOKABLE bool getQuery(const QString &query, const int &limit = 5);
    bool packQueryResults(const QByteArray &array);
    void getId(const QString &results);
    void getUrl(const QString &id);

    Q_INVOKABLE QString getKey() const;
    QByteArray startConnection(const QString &url, const QMap<QString, QString> &headers = {});

    Q_INVOKABLE static QUrl fromUserInput(const QString &userInput);
private:
    const QString KEY = "AIzaSyDMLmTSEN7i6psE2tHdaG6hy3ljWKXIYBk";
    const QMap<METHOD, QString> API =
    {
        {METHOD::SEARCH, "https://www.googleapis.com/youtube/v3/search?"}
    };

signals:
    void queryResultsReady(QVariantList res);
};

#endif // YOUTUBE_H
