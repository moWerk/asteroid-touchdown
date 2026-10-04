TARGET = harbour-asteroid-touchdown

CONFIG += sailfishapp

SOURCES += src/main.cpp \
    src/TouchdownStorage.cpp

HEADERS += src/TouchdownStorage.h

DISTFILES += qml/harbour-asteroid-touchdown.qml \
    qml/game/*.qml \
    qml/game/qmldir \
    rpm/harbour-asteroid-touchdown.spec \
    harbour-asteroid-touchdown.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
