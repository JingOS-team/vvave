/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
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
