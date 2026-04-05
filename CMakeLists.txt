cmake_minimum_required(VERSION 3.6.0)

project(asteroid-touchdown
    VERSION 1.0
    DESCRIPTION "Asteroid Lander Game for AsteroidOS")

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp REQUIRED)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

include(FeatureSummary)
include(GNUInstallDirs)
include(ECMFindQmlModule)
include(AsteroidCMakeSettings)
include(AsteroidTranslations)

add_executable(asteroid-touchdown
    main.cpp
    TouchdownStorage.cpp
    resources.qrc)

target_link_libraries(asteroid-touchdown PRIVATE
    AsteroidApp)

install(TARGETS asteroid-touchdown DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES asteroid-touchdown.desktop
        DESTINATION /usr/share/applications/)
install(FILES asteroid-touchdown.svg
        DESTINATION /usr/share/icons/asteroid/)
