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

#include <QQmlApplicationEngine>
#include <QFontDatabase>

#include <QIcon>
#include <QLibrary>
#include <QCommandLineParser>

#ifdef STATIC_KIRIGAMI
#include "3rdparty/kirigami/src/kirigamiplugin.h"
#endif

#ifdef STATIC_MAUIKIT
#include "3rdparty/mauikit/src/mauikit.h"
#include "fmstatic.h"
#include "mauiapp.h"
#else
#include <MauiKit/fmstatic.h>
#include <MauiKit/mauiapp.h>
#endif

#if defined Q_OS_ANDROID || defined Q_OS_IOS
#include <QGuiApplication>
#include <QIcon>
#else
#include <QApplication>
#endif

#ifdef Q_OS_ANDROID
#include "mauiandroid.h"
#endif

#ifdef Q_OS_MACOS
#include "mauimacos.h"
#endif

#ifdef Q_OS_WIN
#include <QtWebEngine>
#else
#include <QtWebView>
#endif

#include "vvave.h"

#include "utils/bae.h"
#include "services/local/player.h"

#include "models/tracks/tracksmodel.h"
#include "models/videos/videosmodel.h"
#include "models/albums/albumsmodel.h"
#include "models/playlists/playlistsmodel.h"
#include <QSurfaceFormat>
#include "services/jingos_dbus/jingosdbus.h"
#include <QDBusConnection>
#include <QDBusError>

#ifdef Q_OS_ANDROID
Q_DECL_EXPORT
#endif

#define SERVICE_NAME            "org.kde.media.jingos.media"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#if defined Q_OS_LINUX || defined Q_OS_ANDROID
    QtWebView::initialize();
#else
    QtWebEngine::initialize();
#endif

#ifdef Q_OS_WIN32
    qputenv("QT_MULTIMEDIA_PREFERRED_PLUGINS", "w");
#endif

#if defined Q_OS_ANDROID | defined Q_OS_IOS
    QGuiApplication app(argc, argv);
#else
    QApplication app(argc, argv);
#endif

#ifdef Q_OS_ANDROID
    if (!MAUIAndroid::checkRunTimePermissions({"android.permission.WRITE_EXTERNAL_STORAGE"}))
        return -1;
#endif

    app.setApplicationName(BAE::appName);
    app.setApplicationVersion(BAE::version);
    app.setApplicationDisplayName(BAE::displayName);
    app.setOrganizationName(BAE::orgName);
    app.setOrganizationDomain(BAE::orgDomain);
    app.setWindowIcon(QIcon("qrc:/assets/media_icon.png"));

    QCommandLineParser parser;
    parser.setApplicationDescription(BAE::description);

    const QCommandLineOption versionOption = parser.addVersionOption();
    parser.process(app);

    const QStringList args = parser.positionalArguments();
    static auto babe = new vvave;

    QFontDatabase::addApplicationFont(":/assets/materialdesignicons-webfont.ttf");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, args](QObject *obj, const QUrl &objUrl)
    {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
        if (FMStatic::loadSettings("Settings", "ScanCollectionOnStartUp", true ).toBool())
        {
            const auto currentSources = vvave::getSourceFolders();
            babe->scanDir(currentSources.isEmpty() ? BAE::defaultSources : currentSources);
        }

        if (!args.isEmpty())
        {
            babe->openUrls(args);
        }
    }, Qt::QueuedConnection);

    qmlRegisterSingletonType<vvave>("org.maui.vvave", 1, 0, "Vvave",
    [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject* {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return babe;
    });

    qmlRegisterType<TracksModel>("TracksList", 1, 0, "Tracks");
    qmlRegisterType<PlaylistsModel>("PlaylistsList", 1, 0, "Playlists");
    qmlRegisterType<AlbumsModel>("AlbumsList", 1, 0, "Albums");
    qmlRegisterType<Player>("Player", 1, 0, "Player");

    qmlRegisterType<VideosModel>("VideosList", 1, 0, "Videos");


    if (!QDBusConnection::sessionBus().isConnected()) {
        fprintf(stderr, "Cannot connect to the D-Bus session bus.\n"
                "To start it, run:\n"
                "\teval `dbus-launch --auto-syntax`\n");
        return 1;
    }

    if (!QDBusConnection::sessionBus().registerService(SERVICE_NAME)) {
        fprintf(stderr, "%s\n",
                qPrintable(QDBusConnection::sessionBus().lastError().message()));
        exit(1);
    }

    JingosDbus jingosDbus(engine);
    QDBusConnection::sessionBus().registerObject("/services/jingos_dbus/jingosdbus", &jingosDbus, QDBusConnection::ExportAllSlots);

#ifdef STATIC_KIRIGAMI
    KirigamiPlugin::getInstance().registerTypes();
#endif

#ifdef STATIC_MAUIKIT
    MauiKit::getInstance().registerTypes();
#endif
    engine.load(url);

#ifdef Q_OS_MACOS
//	MAUIMacOS::removeTitlebarFromWindow();
#endif

    return app.exec();
}
