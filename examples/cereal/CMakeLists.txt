cmake_minimum_required(VERSION 3.14)
project(cereal_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(../../cmake/AddExtLibs.cmake)

AddExtLib("gh:USCiLab/cereal@1.3.2"
          OPTIONS
              "BUILD_DOC OFF"
              "BUILD_SANDBOX OFF"
              "BUILD_TESTS OFF"
              "THREAD_SAFE ON"
              "CEREAL_INSTALL ON"
              "SKIP_PERFORMANCE_COMPARISON ON"
          SILENT)

if(ALL_EXTLIB_ADDED)
    add_executable(cereal_test "${cereal_SOURCE_DIR}/sandbox/sandbox.cpp")
    target_link_libraries(cereal_test cereal::cereal)
    set_target_properties(cereal_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
