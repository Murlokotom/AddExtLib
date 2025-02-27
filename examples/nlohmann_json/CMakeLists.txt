cmake_minimum_required(VERSION 3.14)
project(json_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(../../cmake/AddExtLibs.cmake)

AddExtLib("https://github.com/nlohmann/json.git@3.11.3" NAME "nlohmann_json" OPTIONS "JSON_MultipleHeaders OFF" "JSON_Install" "JSON_BuildTests OFF" SILENT)

if(ALL_EXTLIB_ADDED)
    add_executable(json_test "main.cpp")
    target_link_libraries(json_test nlohmann_json::nlohmann_json)
    set_target_properties(json_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
