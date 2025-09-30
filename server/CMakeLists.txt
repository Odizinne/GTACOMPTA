cmake_minimum_required(VERSION 3.30)

project(GTACOMPTAServer VERSION 1.4.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Network)

set(SOURCES
    src/main.cpp
    src/databaseserver.cpp
)

set(HEADERS
    include/databaseserver.h
)

qt_add_executable(GTACOMPTAServer
    ${SOURCES}
    ${HEADERS}
    include/usermanager.h src/usermanager.cpp
)

target_include_directories(GTACOMPTAServer PRIVATE include)

target_link_libraries(GTACOMPTAServer
    PRIVATE
        Qt6::Core
        Qt6::Network
)
