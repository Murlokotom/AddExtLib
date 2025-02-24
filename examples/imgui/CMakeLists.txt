AddExtLib("https://github.com/libsdl-org/SDL.git@3.2.4" NAME "SDL3" OPTIONS "SDL_STATIC=ON" "SDL_SHARED=OFF")
AddCode("gh:ocornut/imgui@1.91.8*dock" ADD_SOURCES "backends/*sdl3.cpp" "backends/*sdlrenderer3.cpp" INCLUDES_DIR "backends")
