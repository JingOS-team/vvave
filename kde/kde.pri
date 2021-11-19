QT       += dbus
QT       += KConfigCore
QT       += KNotifications
QT       += KI18n
QT       += webengine
QT       += KIOCore KIOFileWidgets KIOWidgets KNTLM

HEADERS += \
    $$PWD/mpris2/mediaplayer2.h \
    $$PWD/mpris2/mediaplayer2player.h \
    $$PWD/mpris2/mpris2.h \
    $$PWD/notify.h 

SOURCES += \
    $$PWD/mpris2/mediaplayer2.cpp \
    $$PWD/mpris2/mediaplayer2player.cpp \
    $$PWD/mpris2/mpris2.cpp \
    $$PWD/notify.cpp 

LIBS += -ltag

WEBENGINE_CONFIG+=proprietary_codecs
