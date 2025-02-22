cmake_minimum_required(VERSION 3.14)
project(uniview)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(cmake/AddExtLibs.cmake)
AddExtLib(REPO "gh:fmtlib/fmt@11.1.2" OPTIONS "BUILD_SHARED_LIBS" "FMT_TEST=OFF")
#AddExtLib("gh:Neargye/magic_enum@v0.9.7" OPTIONS "MAGIC_ENUM_OPT_BUILD_EXAMPLES OFF" "MAGIC_ENUM_OPT_BUILD_TESTS OFF" "MAGIC_ENUM_OPT_INSTALL ON")
#AddExtLib("gh:rhuijben/sqlite-amalgamation@3.49.0" NAME sqlite3 OPTIONS "BUILD_SHELL OFF" "ENABLE_STATIC_SHELL OFF" "ENABLE_ICU ON")
#AddExtLib("gh:USCiLab/cereal@v1.3.2" OPTIONS "BUILD_DOC OFF" "BUILD_SANDBOX OFF" "BUILD_TESTS OFF" "THREAD_SAFE ON" "CEREAL_INSTALL ON" "SKIP_PERFORMANCE_COMPARISON ON")


if(ALL_EXTLIB_ADDED)
    file(GLOB_RECURSE MAIN_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src/*.cpp)
    list(APPEND ALL_SOURCES ${MAIN_SOURCE_FILES}) 
    add_executable(addextlibtest ${ALL_SOURCES})

    target_include_directories(addextlibtest PRIVATE
        "${PROJECT_SOURCE_DIR}/src/"
    )
    target_link_libraries(uniview fmt::fmt)
    #target_compile_definitions(uniview PRIVATE IMGUI_USER_CONFIG="uniview_imconfig.h")
    set_target_properties(uniview PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()

#include(cmake/CPM.cmake)

#[[
CPMAddPackage(
  NAME lua
  GIT_REPOSITORY https://github.com/lua/lua.git
  VERSION 5.3.5
  DOWNLOAD_ONLY YES
)

if(lua_ADDED)
  # lua has no CMakeLists, so we create our own target
  file(GLOB lua_sources ${lua_SOURCE_DIR}/*.c)
  list(REMOVE_ITEM lua_sources "${lua_SOURCE_DIR}/lua.c" "${lua_SOURCE_DIR}/luac.c")
  add_library(lua STATIC ${lua_sources})
  target_include_directories(lua SYSTEM PUBLIC $<BUILD_INTERFACE:${lua_SOURCE_DIR}>)
endif()

CPMAddPackage("gh:ThePhD/sol2@3.3.0")

# ---- Executable ----

add_executable(uniview main.cpp)
target_compile_features(uniview PRIVATE cxx_std_17)
target_link_libraries(uniview sol2 lua)
#]]