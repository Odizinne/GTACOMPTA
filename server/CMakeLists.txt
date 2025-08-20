cmake_minimum_required(VERSION 3.30)

project(GTACOMPTAServer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Network)

set(SOURCES
    src/main.cpp
    src/databaseserver.cpp
    src/requesthandler.cpp
)

set(HEADERS
    include/databaseserver.h
    include/requesthandler.h
)

qt_add_executable(GTACOMPTAServer
    ${SOURCES}
    ${HEADERS}
)

target_include_directories(GTACOMPTAServer PRIVATE include)

target_link_libraries(GTACOMPTAServer
    PRIVATE
        Qt6::Core
        Qt6::Network
)
