cmake_minimum_required(VERSION 3.16)

project(GTACOMPTA VERSION 1.5.0 LANGUAGES CXX)

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
    include/versiongetter.h
    include/supplementmodel.h
    include/offermodel.h
    include/filterproxymodel.h
    include/datamanager.h
    include/wasmfilehandler.h
    include/remotedatabasemanager.h
    include/companysummarymodel.h
    include/notemodel.h
)

set(SOURCES
    src/basemodel.cpp
    src/employeemodel.cpp
    src/transactionmodel.cpp
    src/clientmodel.cpp
    src/awaitingtransactionmodel.cpp
    src/versiongetter.cpp
    src/supplementmodel.cpp
    src/offermodel.cpp
    src/filterproxymodel.cpp
    src/datamanager.cpp
    src/wasmfilehandler.cpp
    src/remotedatabasemanager.cpp
    src/companysummarymodel.cpp
    src/notemodel.cpp
)

# Get git commit hash
find_package(Git QUIET)
if(GIT_FOUND AND EXISTS "${PROJECT_SOURCE_DIR}/.git")
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
else()
    set(GIT_COMMIT_HASH "unknown")
endif()

string(TIMESTAMP BUILD_TIMESTAMP "%Y-%m-%d %H:%M:%S UTC" UTC)

# Only configure Windows resources for non-WASM builds
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    set(APP_ICON_PATH "${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/icon.ico")
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/src/windows_metadata.rc.in"
        "${CMAKE_CURRENT_BINARY_DIR}/windows_metadata.rc"
        @ONLY
    )
    set(WINDOWS_RESOURCES "${CMAKE_CURRENT_BINARY_DIR}/windows_metadata.rc")
else()
    set(WINDOWS_RESOURCES "")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/version.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/version.h"
)

# WebAssembly specific settings
if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    qt_add_executable(GTACOMPTA
        src/main.cpp
        resources/icons/icons.qrc
        resources/fonts/fonts.qrc
    )

    set_target_properties(GTACOMPTA PROPERTIES
        QT_WASM_PTHREAD_POOL_SIZE 4
        QT_WASM_INITIAL_MEMORY 100MB
        QT_WASM_MAXIMUM_MEMORY 2GB
    )

    target_link_options(GTACOMPTA PRIVATE
        "-sALLOW_MEMORY_GROWTH=1"
        "-sFILESYSTEM=1"
        "-sEXPORTED_RUNTIME_METHODS=['FS','stringToUTF8','lengthBytesUTF8']"
        "-sEXPORTED_FUNCTIONS=['_main','_saveFileSelectedCallback','_loadFileSelectedCallback','_malloc','_free']"
    )
else()
    # Native platforms
    qt_add_executable(GTACOMPTA WIN32 MACOSX_BUNDLE
        src/main.cpp
        resources/icons/icons.qrc
        resources/fonts/fonts.qrc
        ${WINDOWS_RESOURCES}
    )

    set_target_properties(GTACOMPTA PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

set(QML_FILES
    qml/Main.qml
    qml/Components/DatePicker.qml
    qml/Components/SortableLabel.qml
    qml/Components/RemoteDatabaseConfig.qml
    qml/Dialogs/AwaitingTransactionDialog.qml
    qml/Dialogs/ClearAllDialog.qml
    qml/Dialogs/ClientDialog.qml
    qml/Dialogs/ConfirmDialog.qml
    qml/Dialogs/EmployeeDialog.qml
    qml/Dialogs/ExportDialog.qml

    qml/Dialogs/ImportDialog.qml
    qml/Dialogs/MessageDialog.qml
    qml/Dialogs/NotesDialog.qml
    qml/Dialogs/SettingsDialog.qml
    qml/Dialogs/SupplementOfferManagementDialog.qml
    qml/Dialogs/SupplementSelectionDialog.qml
    qml/Dialogs/TransactionDialog.qml
    qml/Dialogs/VersionDialog.qml
    qml/Dialogs/WelcomeDialog.qml
    qml/Dialogs/DatePickerDialog.qml
    qml/Pages/MainPage.qml
    qml/Pages/SplashScreen.qml
    qml/Tabs/AwaitingTransactionTab.qml
    qml/Tabs/ClientTab.qml
    qml/Tabs/EmployeeTab.qml
    qml/Tabs/TransactionTab.qml
    qml/Tabs/HomeTab.qml
)

set(QML_SINGLETONS
    qml/Singletons/UserSettings.qml
    qml/Singletons/Constants.qml
    qml/Singletons/AppState.qml
)

set_source_files_properties(${QML_SINGLETONS}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

target_include_directories(GTACOMPTA PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}
)

qt_add_qml_module(GTACOMPTA
    URI Odizinne.GTACOMPTA
    VERSION 1.0
    QML_FILES ${QML_FILES} ${QML_SINGLETONS}
    SOURCES ${SOURCES} ${HEADERS}
    DEPENDENCIES QtCore QtQml
)

target_link_libraries(GTACOMPTA
    PRIVATE Qt6::Quick Qt6::Qml
)

# Only do installation stuff for non-WebAssembly builds
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
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
endif()

# -------------------------------------------
# Optional server subproject
# -------------------------------------------
option(BUILD_GTACOMPTA_SERVER "Build the GTACOMPTAServer subproject" OFF)

if(BUILD_GTACOMPTA_SERVER)
    add_subdirectory(server)
endif()
