/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#ifndef JAPPCONTROL_H
#define JAPPCONTROL_H

#include <japplicationqt.h>
#include <QObject>

class JAppControl : public QObject
{
    Q_OBJECT
public:
    explicit JAppControl(QObject *parent = nullptr);
    Q_INVOKABLE void setAppstatus(bool flag);

private:
    JApplicationQt m_Japp;

};

#endif // JAPPCONTROL_H
