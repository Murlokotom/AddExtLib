cmake_minimum_required(VERSION 3.14)
project(ael_test)

add_subdirectory("examples/magic_enum")
add_subdirectory("examples/fmt")
add_subdirectory("examples/imgui")

#[[AddExtLib("gh:rhuijben/sqlite-amalgamation@3.49.0" NAME sqlite3 OPTIONS "BUILD_SHELL OFF" "ENABLE_STATIC_SHELL OFF" "ENABLE_ICU ON" SILENT)
AddExtLib("gh:USCiLab/cereal@v1.3.2" OPTIONS "BUILD_DOC OFF" "BUILD_SANDBOX OFF" "BUILD_TESTS OFF" "THREAD_SAFE ON" "CEREAL_INSTALL ON" "SKIP_PERFORMANCE_COMPARISON ON" SILENT)
AddExtLib(
    REPO "https://github.com/DCMTK/dcmtk.git@3.6.7"
    NAME DCMTK
    OPTIONS "BUILD_SHARED_LIBS" "BUILD_TESTING=OFF"
    SILENT
)#]]
