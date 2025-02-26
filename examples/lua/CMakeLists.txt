cmake_minimum_required(VERSION 3.14)
project(lua_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(../../cmake/AddExtLibs.cmake)

AddCode("gh:lua/lua@v5.4.7" EXL_SOURCES "lua.c" "luac.c" "onelua.c" MAKE_SHARED_LIB DISABLE_SEARCH_TAG SILENT)

if(ALL_EXTLIB_ADDED)
    add_executable(lua_test "${lua_INSTALL_DIR}/lua.c")
    target_link_libraries(lua_test lua::lua)
    set_target_properties(lua_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
