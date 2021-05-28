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