/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#include "JAppControl.h"

JAppControl::JAppControl(QObject *parent) : QObject(parent)
{
     m_Japp.enableBackgroud(true);
}
void JAppControl::setAppstatus(bool flag)
{
     m_Japp.enableBackgroud(true);
}
