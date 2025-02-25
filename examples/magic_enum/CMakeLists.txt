cmake_minimum_required(VERSION 3.14)
project(magic_enum_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(../../cmake/AddExtLibs.cmake)

AddExtLib("gh:Neargye/magic_enum@0.9.7" OPTIONS "MAGIC_ENUM_OPT_BUILD_EXAMPLES OFF" "MAGIC_ENUM_OPT_BUILD_TESTS OFF" "MAGIC_ENUM_OPT_INSTALL ON" SILENT)

if(ALL_EXTLIB_ADDED)
    add_executable(magic_enum_test "${magic_enum_SOURCE_DIR}/example/example.cpp")
    target_link_libraries(magic_enum_test magic_enum::magic_enum)
    set_target_properties(magic_enum_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
