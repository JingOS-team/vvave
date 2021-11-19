cmake_minimum_required(VERSION 3.0)
set(VVAVE_VERSION 1.1.1)
project(vvave VERSION ${VVAVE_VERSION})

find_package(ECM 1.7.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})
set(CMAKE_CXX_STANDARD 17)

find_package(MauiKit REQUIRED)
find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Qml Quick Network WebSockets Sql QuickControls2 Xml Multimedia DBus Svg WebView)
#find_package(KF5 ${KF5_VERSION} REQUIRED COMPONENTS I18n Notifications Config KIO Attica SyntaxHighlighting KIO)
find_package(KF5 ${KF5_VERSION} REQUIRED COMPONENTS I18n Notifications Config KIO Attica SyntaxHighlighting FileMetaData KIO)
find_package(Qt5QuickCompiler) #fast codeing
include(KDEInstallDirs)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)
include(ECMInstallIcons)
include(ECMAddAppIcon)
include(ECMSetupVersion)
include(FeatureSummary)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTORCC ON)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/services/web
    ${CMAKE_CURRENT_BINARY_DIR}/services/web
    )

qtquick_compiler_add_resources(hjyRec qml.qrc)

add_executable(media
    # qml.qrc
    ${hjyRec}
    main.cpp
    vvave.cpp
    JAppControl.cpp
    pulpo/services/lastfmService.cpp
    pulpo/pulpo.cpp
    pulpo/htmlparser.cpp
    pulpo/service.cpp
    services/local/taginfo.cpp
    services/local/mediastorage.cpp
    services/local/player.cpp
    services/local/youtubedl.cpp
    services/jingos_dbus/jingosdbus.cpp
    services/web/youtube.cpp
    services/web/NextCloud/nextmusic.cpp
    services/web/abstractmusicprovider.cpp
    db/collectionDB.cpp
    models/tracks/tracksmodel.cpp
    models/videos/videosmodel.cpp
    models/playlists/playlistsmodel.cpp
    models/albums/albumsmodel.cpp
    models/cloud/cloud.cpp
    )

ecm_setup_version(${VVAVE_VERSION}
    VARIABLE_PREFIX VVAVE
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/vvave_version.h"
    )

if (ANDROID)
    find_package(Qt5 REQUIRED COMPONENTS AndroidExtras WebView Xml)
    find_package(OpenSSL REQUIRED)

    include(ExternalProject)
    externalproject_add(taglib
        URL http://taglib.org/releases/taglib-1.11.1.tar.gz
        #CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr
        )
    #set(TAGLIB_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include ${CMAKE_INSTALL_PREFIX}/include/taglib)
    #set(TAGLIB_LIBRARIES ${CMAKE_INSTALL_PREFIX}/${LIB_INSTALL_DIR}/libtag.a)
    set(TAGLIB_INCLUDE_DIRS /usr/include /usr/include/taglib)
    set(TAGLIB_LIBRARIES /usr/${LIB_INSTALL_DIR}/libtag.a)

    target_link_libraries(vvave MauiKit Qt5::AndroidExtras Qt5::WebView Qt5::Xml OpenSSL::SSL)
    add_dependencies(vvave taglib)
    kde_source_files_enable_exceptions(vvave)
else()
    find_package(Taglib REQUIRED)
    target_sources(media PRIVATE
        kde/notify.cpp
        kde/mpris2/mpris2.cpp
        kde/mpris2/mediaplayer2.cpp
        kde/mpris2/mediaplayer2player.cpp
        )
    target_link_libraries(media Qt5::WebView KF5::ConfigCore KF5::Notifications KF5::KIOCore KF5::I18n Qt5::DBus KF5::Attica KF5::SyntaxHighlighting mediainfo jappcoreqt)
endif()

find_package(KF5I18n CONFIG REQUIRED)
ki18n_install(po)

find_package(KF5DBusAddons REQUIRED)

target_include_directories(media PRIVATE ${TAGLIB_INCLUDE_DIRS})
target_link_libraries(media MauiKit Qt5::Network Qt5::Sql Qt5::WebSockets Qt5::Qml Qt5::Xml Qt5::Multimedia  Qt5::QuickControls2 ${TAGLIB_LIBRARIES} KF5::KIOCore KF5::FileMetaData KF5::DBusAddons KF5::CoreAddons)
#target_link_libraries(media MauiKit Qt5::Network Qt5::Sql Qt5::WebSockets Qt5::Qml Qt5::Xml Qt5::Multimedia  Qt5::QuickControls2 ${TAGLIB_LIBRARIES})

install(TARGETS media ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES org.kde.media.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})

#TODO: port to ecm_install_icons()
install(FILES assets/media_new.svg DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)
install(FILES org.kde.media.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
