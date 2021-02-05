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
#include <QObject>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include "services/jingos_dbus/jingosdbus.h"

JingosDbus::JingosDbus(const QQmlApplicationEngine &engine)
    : m_engine(engine)
{

}
void JingosDbus::updateLately(int index) {
    QObject* root = m_engine.rootObjects().first();
    if (root)
    {
        QVariant returnedValue;
        QMetaObject::invokeMethod(root, "updateLately", Q_RETURN_ARG(QVariant, returnedValue),Q_ARG(QVariant, index));
    }
}

void JingosDbus::play() {
    QObject* root = m_engine.rootObjects().first();
    if (root)
    {
        QVariant returnedValue;
        QMetaObject::invokeMethod(root, "play");
    }
}

void JingosDbus::nextTrack() {
    QObject* root = m_engine.rootObjects().first();
    if (root)
    {
        QVariant returnedValue;
        QMetaObject::invokeMethod(root, "nextTrack");
    }
}

void JingosDbus::previousTrack() {
    QObject* root = m_engine.rootObjects().first();
    if (root)
    {
        QVariant returnedValue;
        QMetaObject::invokeMethod(root, "previousTrack");
    }
}