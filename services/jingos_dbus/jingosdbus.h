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