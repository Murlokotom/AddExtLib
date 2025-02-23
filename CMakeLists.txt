cmake_minimum_required(VERSION 3.14)
project(ael_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(cmake/AddExtLibs.cmake)

AddExtLib("https://github.com/fmtlib/fmt.git@11.1.3" OPTIONS "BUILD_SHARED_LIBS" "FMT_TEST=OFF" SILENT)
AddExtLib("gh:Neargye/magic_enum@0.9.7" OPTIONS "MAGIC_ENUM_OPT_BUILD_EXAMPLES OFF" "MAGIC_ENUM_OPT_BUILD_TESTS OFF" "MAGIC_ENUM_OPT_INSTALL ON" SILENT)
AddExtLib("gh:rhuijben/sqlite-amalgamation@3.49.0" NAME sqlite3 OPTIONS "BUILD_SHELL OFF" "ENABLE_STATIC_SHELL OFF" "ENABLE_ICU ON" SILENT)
AddExtLib("gh:USCiLab/cereal@v1.3.2" OPTIONS "BUILD_DOC OFF" "BUILD_SANDBOX OFF" "BUILD_TESTS OFF" "THREAD_SAFE ON" "CEREAL_INSTALL ON" "SKIP_PERFORMANCE_COMPARISON ON" SILENT)
AddExtLib(
    REPO "https://github.com/DCMTK/dcmtk.git@3.6.7"
    NAME DCMTK
    OPTIONS "BUILD_SHARED_LIBS" "BUILD_TESTING=OFF"
    SILENT
)

if(ALL_EXTLIB_ADDED)
    file(GLOB_RECURSE MAIN_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src/*.cpp)
    list(APPEND ALL_SOURCES ${MAIN_SOURCE_FILES}) 
    add_executable(ael_test ${ALL_SOURCES})

    target_include_directories(ael_test PRIVATE
        "${PROJECT_SOURCE_DIR}/src/"
    )
    target_link_libraries(ael_test fmt::fmt magic_enum::magic_enum)
    set_target_properties(ael_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
