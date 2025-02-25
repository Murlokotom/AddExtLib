cmake_minimum_required(VERSION 3.14)
project(imgui_test)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -static-libgcc -static-libstdc++ -pthread")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -static-libgcc -static-libstdc++ -pthread")

include(../../cmake/AddExtLibs.cmake)

AddExtLib("https://github.com/libsdl-org/SDL.git@3.2.4" NAME "SDL3" OPTIONS "SDL_STATIC=ON" "SDL_SHARED=OFF" SILENT)
AddCode("gh:ocornut/imgui@1.91.8*dock" ADD_SOURCES "backends/*sdl3.cpp" "backends/*sdlrenderer3.cpp" INCLUDES_DIR "backends" SILENT)

if(ALL_EXTLIB_ADDED)
    add_executable(imgui_test "${imgui_INSTALL_DIR}/examples/example_sdl3_sdlrenderer3/main.cpp" "${imgui_SOURCES}")
    target_include_directories(imgui_test PRIVATE "${imgui_INCLUDES}")
    target_link_libraries(imgui_test SDL3::SDL3)
    set_target_properties(imgui_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
endif()
