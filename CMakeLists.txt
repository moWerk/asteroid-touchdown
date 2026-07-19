cmake_minimum_required(VERSION 3.6.0)

project(asteroid-touchdown
    VERSION 1.0
    DESCRIPTION "Asteroid Lander Game for AsteroidOS")

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp6 REQUIRED)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

include(FeatureSummary)
include(GNUInstallDirs)
include(ECMFindQmlModule)
include(Asteroid6CMakeSettings)
include(Asteroid6Translations)

add_executable(asteroid-touchdown
    src/main.cpp
    src/TouchdownStorage.cpp
    src/resources.qrc)

target_link_libraries(asteroid-touchdown PRIVATE
    Asteroid::AsteroidApp6)

install(TARGETS asteroid-touchdown DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES asteroid-touchdown.desktop
        DESTINATION /usr/share/applications/)
install(FILES asteroid-touchdown.svg
        DESTINATION /usr/share/icons/asteroid/)
