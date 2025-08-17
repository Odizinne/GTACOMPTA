cmake_minimum_required(VERSION 3.16)

project(GTACOMPTA VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

set(SOURCES
    src/basemodel.cpp
    src/employeemodel.cpp
    src/transactionmodel.cpp
    src/clientmodel.cpp
    src/main.cpp
)

set(HEADERS
    include/basemodel.h
    include/employeemodel.h
    include/transactionmodel.h
    include/clientmodel.h
)

qt_add_executable(GTACOMPTA WIN32 MACOSX_BUNDLE
    ${SOURCES}
    ${HEADERS}
)

set(QML_FILES
    qml/Main.qml
)

set(QML_SINGLETONS
    qml/Singletons/UserSettings.qml
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
)

set_target_properties(GTACOMPTA PROPERTIES
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(GTACOMPTA
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS GTACOMPTA
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
