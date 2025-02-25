cmake_minimum_required(VERSION 3.14)
project(fmt_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(../../cmake/AddExtLibs.cmake)

AddExtLib("https://github.com/fmtlib/fmt.git@11.1.3" OPTIONS "BUILD_SHARED_LIBS" "FMT_TEST=OFF" SILENT)

if(ALL_EXTLIB_ADDED)
    add_executable(fmt_test "main.cpp")
    target_link_libraries(fmt_test fmt::fmt)
    set_target_properties(fmt_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
