/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Yu Jiashu <yujiashu@jingos.com>
 *
 */

#ifndef PLAYER_H
#define PLAYER_H

#include <QObject>
#include <QtMultimedia/QMediaPlayer>
#include <QTimer>
#include <QBuffer>

class Player : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl url READ getUrl WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(int volume READ getVolume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(Player::STATE state READ getPlayState NOTIFY stateChanged)
    Q_PROPERTY(double duration READ getDuration NOTIFY durationChanged)
    Q_PROPERTY(bool playing READ getPlaying WRITE setPlaying NOTIFY playingChanged)
    Q_PROPERTY(bool finished READ getFinished NOTIFY finishedChanged)
    Q_PROPERTY(double pos READ getPos WRITE setPos NOTIFY posChanged)

public:

    enum STATE : uint_fast8_t
    {
        PLAYING,
        PAUSED,
        STOPED
    };Q_ENUM(STATE)

    explicit Player(QObject *parent = nullptr);

    void setUrl(const QUrl &value);
    QUrl getUrl() const;

    void setVolume(const int &value);
    int getVolume() const;

    double getDuration() const;

    QMediaPlayer::State getState() const;
    Player::STATE getPlayState() const;

    void setPlaying(const bool &value);
    bool getPlaying() const;

    bool getFinished();

    double getPos() const;
    void setPos(const double &value);
    bool play();
    void pause();
    Q_INVOKABLE qint64 getPlayerPos();


private:
    QMediaPlayer *player;
    QTimer *updater;
    int amountBuffers = 0;
    double pos = 0;
    int volume = 100;

    QUrl url;
    Player::STATE state = STATE::STOPED;
    bool playing = false;
    bool finished = false;

    void update();

    void emitState();

signals:
    void durationChanged();
    void urlChanged();
    void volumeChanged();

    void stateChanged();
    void playingChanged();
    void finishedChanged();

    void posChanged();

public slots:
    static QString transformTime(const int &pos);
    void stop();

};

#endif // PLAYER_H
