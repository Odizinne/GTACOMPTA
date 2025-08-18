cmake_minimum_required(VERSION 3.30)

project(GTACOMPTA VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation directory" FORCE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(QT_QML_GENERATE_QMLLS_INI ON)
set(CMAKE_DISABLE_FIND_PACKAGE_WrapVulkanHeaders TRUE)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml)

qt_standard_project_setup(REQUIRES 6.8)

set(HEADERS
    include/basemodel.h
    include/employeemodel.h
    include/transactionmodel.h
    include/clientmodel.h
    include/awaitingtransactionmodel.h
)

set(SOURCES
    src/basemodel.cpp
    src/employeemodel.cpp
    src/transactionmodel.cpp
    src/clientmodel.cpp
    src/awaitingtransactionmodel.cpp
)

set(APP_ICON_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/icon.ico")
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/windows_metadata.rc.in"
    "${CMAKE_CURRENT_BINARY_DIR}/windows_metadata.rc"
    @ONLY
)

qt_add_executable(GTACOMPTA WIN32 MACOSX_BUNDLE
    src/main.cpp
    resources/icons/icons.qrc
    "${CMAKE_CURRENT_BINARY_DIR}/windows_metadata.rc"
)

set(QML_FILES
    qml/Main.qml
)

set(QML_SINGLETONS
    qml/Singletons/UserSettings.qml
    qml/Singletons/Constants.qml
)

set_source_files_properties(${QML_SINGLETONS}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

target_include_directories(GTACOMPTA PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

qt_add_qml_module(GTACOMPTA
    URI Odizinne.GTACOMPTA
    VERSION 1.0
    QML_FILES ${QML_FILES} ${QML_SINGLETONS}
    SOURCES ${SOURCES} ${HEADERS}
    QML_FILES qml/SortableLabel.qml
    QML_FILES qml/FakeUpgradeDialog.qml
    QML_FILES qml/WelcomeDialog.qml
)

set_target_properties(GTACOMPTA PROPERTIES
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(GTACOMPTA
    PRIVATE Qt6::Quick Qt6::Qml
)

include(GNUInstallDirs)

install(TARGETS GTACOMPTA
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET GTACOMPTA
    OUTPUT_SCRIPT deploy_script
    NO_TRANSLATIONS
    DEPLOY_TOOL_OPTIONS --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --skip-plugin-types designer,iconengines,qmllint,generic,networkinformation,help,qmltooling,sqldrivers,qmlls
)
install(SCRIPT ${deploy_script})
