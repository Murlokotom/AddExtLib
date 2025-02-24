░█████╗░██████╗░██████╗░███████╗██╗░░██╗████████╗██╗░░░░░██╗██████╗░
██╔══██╗██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝╚══██╔══╝██║░░░░░██║██╔══██╗
███████║██║░░██║██║░░██║█████╗░░░╚███╔╝░░░░██║░░░██║░░░░░██║██████╦╝
██╔══██║██║░░██║██║░░██║██╔══╝░░░██╔██╗░░░░██║░░░██║░░░░░██║██╔══██╗
██║░░██║██████╔╝██████╔╝███████╗██╔╝╚██╗░░░██║░░░███████╗██║██████╦╝
╚═╝░░╚═╝╚═════╝░╚═════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝╚═════╝░


# `AddExtLib` Macro for CMake

The `AddExtLib` macro is designed to simplify the process of adding external libraries to CMake projects. It automates the downloading, building, and installation of external dependencies and ensures their integration into your project.

## Key Features

- Automatic downloading of source code from Git repositories.
- Support for specifying tags, branches, or commit hashes.
- Automatic building and installation of libraries using CMake.
- Support for configuring build parameters via CMake flags.
- Detection of configuration changes and automatic recompilation when necessary.
- Copying compiled libraries and executable files to target directories.
- Organized project structure.

## Usage

### CMake script for automatic download of AddExtLib

```cmake
file(DOWNLOAD
    "https://raw.githubusercontent.com/Murlokotom/AddExtLib/master/cmake/AddExtLibs.cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/AddExtLibs.cmake"
    TLS_VERIFY ON
)
include(cmake/AddExtLibs.cmake)
```
The script should be placed at the beginning of your CMakeLists.txt

### Basic Syntax

```cmake
AddExtLib(
    [SILENT]
    [NAME <library_name>]
    [REPO <repository_URL>]
    [TAG <tag_or_branch>]
    [OPTIONS <CMake_flags>]
    [DEPENDS <dependencies>]
)
```
or
```cmake
AddExtLib(
    <repository_URL>
    [SILENT]
    [NAME <library_name>]
    [TAG <tag_or_branch>]
    [OPTIONS <CMake_flags>]
    [DEPENDS <dependencies>]
)
```

### Parameters

- **SILENT**: If specified, the output information about the library will be minimized.
- **NAME**: The name of the library. If not specified, it will be extracted from the Git repository URL.
- **REPO**: The URL of the Git repository. Supported shorthand formats:
  - `gh:` for GitHub (e.g., `gh:user/repo`).
  - `gl:` for GitLab (e.g., `gl:user/repo`).
  - `bb:` for Bitbucket (e.g., `bb:user/repo`).
  - Full URL (e.g., `https://github.com/user/repo.git`).
- **TAG**: Tag, branch, or commit hash. If not specified, the latest found tag will be used. If the tag is not found, the macro will attempt to find the closest matching tag. The tag can also be specified after the Git repository URL using "@" (e.g., `gh:user/repo@1.0.0` or `https://github.com/user/repo.git@1.0.0`).
- **OPTIONS**: A list of CMake flags for configuring the build (e.g., `BUILD_TEST=OFF`). If the ON or OFF switch is not specified after the flag value, it is assumed to be "ON". A space can be used instead of "=".
- **DEPENDS**: A list of dependencies that must be built before this library.

### Examples

#### Simple Example

```cmake
AddExtLib(
    REPO "https://github.com/DCMTK/dcmtk.git"
    TAG "DCMTK-3.6.7"
    OPTIONS "BUILD_SHARED_LIBS=ON" "BUILD_TESTING=OFF"
)
```

#### Using Shorthand URL

```cmake
AddExtLib(
    "gh:google/googletest@1.21.1"
    OPTIONS "BUILD_GMOCK=ON"
)
```

#### Specifying Dependencies

```cmake
AddExtLib(
    NAME "MyLibrary"
    REPO "https://github.com/user/mylibrary.git"
    TAG "v1.0.0"
    OPTIONS "BUILD_SHARED_LIBS=ON"
    DEPENDS "SomeOtherLibrary"
)
```

## Project Compilation Procedure Using the `AddExtLib` Macro for CMake

During the first configuration and compilation pass, CMake downloads and compiles the libraries. During subsequent passes, the already downloaded and compiled libraries are linked to the main program. If the **OPTIONS** or **DEPENDS** parameter is changed, the library is forcibly recompiled. To control which stage is being executed, the `ALL_EXTLIB_ADDED` variable is used, which indicates that all external libraries are ready to be linked to the main project.

Example CMakeLists.txt:

```cmake
cmake_minimum_required(VERSION 3.14)
project(ael_test)
set(CMAKE_CXX_STANDARD 17)
include(cmake/AddExtLibs.cmake)
AddExtLib("gh:fmtlib/fmt.git@11.1.3" OPTIONS "BUILD_SHARED_LIBS" "FMT_TEST=OFF" SILENT)

if(ALL_EXTLIB_ADDED)
	file(GLOB_RECURSE MAIN_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src/*.cpp)
	list(APPEND ALL_SOURCES ${MAIN_SOURCE_FILES})
	add_executable(ael_test ${ALL_SOURCES})
	target_include_directories(ael_test PRIVATE "${PROJECT_SOURCE_DIR}/src/")
	target_link_libraries(ael_test fmt::fmt)
	set_target_properties(ael_test  PROPERTIES  RUNTIME_OUTPUT_DIRECTORY  ${PROJECT_BINARY_DIR})
endif()
```

## Additional Commands

The `AddExtLib` macro also creates several additional targets for managing source code and installed files:

- **`<library_name>_clear_sources`**: Clears the directory with the downloaded source code of the library.
- **`<library_name>_clear_install`**: Clears the directory with the installed files of the library.
- **`<library_name>_clear_all`**: Clears both directories (source code and installed files).

## Path Configuration

The macro uses the following variables to configure paths:

- **`AEL_EXEC_DIR`**: Directory for executable files (default: `exec`).
- **`AEL_BUILD_DIR`**: Directory for building (default: `build`).
- **`AEL_EXTERNAL_DIR`**: Directory for source code of external libraries (default: `external`).
- **`AEL_INSTALL_DIR`**: Directory for installing external libraries (default: `install`).

These variables can be redefined before including the macro.

## Notes

- The macro uses `ExternalProject_Add` to download and build libraries.
- Git and CMake are required for the macro to work.

## License

This macro is distributed under the MIT license. Use it at your own risk.

[Link to create a logo](https://fsymbols.com/ru/generatory/)
