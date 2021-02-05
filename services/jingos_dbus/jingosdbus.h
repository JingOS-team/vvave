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
#ifndef __HARUHA_PLAYER__
#define __HARUHA_PLAYER__

#include <QQmlApplicationEngine>
class JingosDbus : public QObject
{
    Q_OBJECT
public:
    JingosDbus(const QQmlApplicationEngine &engine);

public slots:
    Q_SCRIPTABLE void updateLately(int index);
    Q_SCRIPTABLE void play();
    Q_SCRIPTABLE void nextTrack();
    Q_SCRIPTABLE void previousTrack();

private:
    const QQmlApplicationEngine &m_engine;
};
#endif