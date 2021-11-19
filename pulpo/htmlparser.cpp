/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#include "htmlparser.h"

htmlParser::htmlParser(QObject *parent) : QObject(parent)
{

}

void htmlParser::setHtml(const QByteArray &array)
{
    this->html = array;

}


QString htmlParser::extractProp(const QString &tag,const QString &prop)
{
    auto list = tag.split(" ");
    auto result =list.filter(prop,Qt::CaseInsensitive);
    auto url = result.first().replace(prop,"").replace('\"',"");
    return url;
}

QStringList htmlParser::parseTag(const QString &tagRef, const QString &attribute)
{

    QStringList results;
    QStringList html(QString(this->html).split(">"));

    for(auto i =0; i<html.size(); i++) {
        QString tag = html.at(i);
        tag+=">";

        if(findTag(tag,"<"+tagRef+">") && tag.contains(attribute)) {
            QString subResult;
            while(!html.at(i).contains("</"+tagRef)) {
                auto subTag=html.at(i);
                subTag+=">";
                subResult+=subTag;
                i++;
                if(i>html.size()) break;
            }
            results<<subResult.simplified();
        }
    }
    return results;
}


bool htmlParser::findTag(const QString &txt, const QString &tagRef)
{
    int i =0;
    QString subTag;
    while(i<txt.size())
    {
        if(txt.at(i).toLatin1()=='<')
        {
            while(!txt.at(i).isSpace() && txt.at(i).toLatin1()!='>')
            {
                subTag+=txt.at(i);
                i++;
                if(i>txt.size()) break;
            }
            subTag+=">";
        }

        i++;
        if(i>txt.size()) break;
    }


    if(tagRef==subTag) return true;
    else return false;
}
