cmake_minimum_required(VERSION 3.14)
project(ael_test)

add_subdirectory("examples/magic_enum")
add_subdirectory("examples/fmt")
add_subdirectory("examples/imgui")
add_subdirectory("examples/cereal")
add_subdirectory("examples/lua")
add_subdirectory("examples/nlohmann_json")

#[[AddExtLib("gh:rhuijben/sqlite-amalgamation@3.49.0" NAME sqlite3 OPTIONS "BUILD_SHELL OFF" "ENABLE_STATIC_SHELL OFF" "ENABLE_ICU ON" SILENT)
AddExtLib(
    REPO "https://github.com/DCMTK/dcmtk.git@3.6.7"
    NAME DCMTK
    OPTIONS "BUILD_SHARED_LIBS" "BUILD_TESTING=OFF"
    SILENT
)#]]
