include(FetchContent)
include(ExternalProject)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

set(ALL_EXTLIB_ADDED ON)
set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/exec/${CMAKE_BUILD_TYPE}")
set(CMAKE_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/${CMAKE_BUILD_TYPE}")
set(EXTERNAL_PROJECT_PREFIX "${CMAKE_SOURCE_DIR}/external")
set(EXTERNAL_PROJECT_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/install")

function(ael_fix_tag git_url git_tag fixed_tag)
    # Corrects or finds the latest Git tag for a repository.
    # Parameters:
    #   git_url  - Repository URL (e.g., "https://github.com/DCMTK/dcmtk.git").
    #   git_tag  - Tag to search for. If empty, retrieves the latest finded tag.
    #   fixed_tag - Output variable for the corrected/latest finded tag.
    if("${git_tag}" STREQUAL "")
        set(GIT_COMMAND ${GIT_EXECUTABLE} ls-remote --tags --refs ${git_url} "*")
    else()
        set(GIT_COMMAND ${GIT_EXECUTABLE} ls-remote --tags --refs ${git_url} "*${git_tag}*")
    endif()

    execute_process(
        COMMAND ${GIT_COMMAND}
        OUTPUT_VARIABLE REMOTE_TAGS
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    set(TAG_LIST "")
    string(REPLACE "\n" ";" TAG_LINES "${REMOTE_TAGS}")
    
    foreach(line ${TAG_LINES})
        string(REGEX REPLACE "^.*refs/tags/" "" TAG_NAME "${line}")
        list(APPEND TAG_LIST "${TAG_NAME}")
    endforeach()

    if(TAG_LIST)
        list(SORT TAG_LIST ORDER DESCENDING)
        list(GET TAG_LIST 0 LATEST_TAG)
    else()
        set(LATEST_TAG "")
    endif()

    set(${fixed_tag} "${LATEST_TAG}" PARENT_SCOPE)
endfunction()

function(ael_transform_flags input_list output_variable)
# Function to transform a list of flags into a CMake-style -D flag list
# Usage: transform_flags(input_list output_variable)
# input_list: A list of flags (e.g., "BUILD_TEST OFF" "SHARED_LIBS ON" "BUILD_DEMO" "EXEC=main")
# output_variable: The variable to store the transformed result as a list (e.g., "-DBUILD_TEST=OFF" "-DSHARED_LIBS=ON" "-DBUILD_DEMO=ON" "-DEXEC=main")
    set(result "")
    foreach(flag ${input_list})
        string(FIND "${flag}" " " space_pos)
        string(FIND "${flag}" "=" equal_pos)
        if(NOT equal_pos EQUAL -1)
            string(SUBSTRING "${flag}" 0 ${equal_pos} key)
            math(EXPR value_pos "${equal_pos} + 1")
            string(SUBSTRING "${flag}" ${value_pos} -1 value)
        else()
            if(NOT space_pos EQUAL -1)
                string(SUBSTRING "${flag}" 0 ${space_pos} key)
                math(EXPR value_pos "${space_pos} + 1")
                string(SUBSTRING "${flag}" ${value_pos} -1 value)
            else()
                set(key "${flag}")
                set(value "ON")
            endif()
        endif()
        list(APPEND result "-D${key}=${value}")
    endforeach()
    set(${output_variable} "${result}" PARENT_SCOPE)
endfunction()

function(ael_parse_url arg lib_name git_url git_tag)
# Parse URL
    set(url "")
    set(tag "")
    set(name "")

    # Check for shortened URL prefixes
    if(arg MATCHES "^gh:(.+)")
        set(base_url "https://github.com/")
        set(remaining "${CMAKE_MATCH_1}")
    elseif(arg MATCHES "^gl:(.+)")
        set(base_url "https://gitlab.com/")
        set(remaining "${CMAKE_MATCH_1}")
    elseif(arg MATCHES "^bb:(.+)")
        set(base_url "https://bitbucket.org/")
        set(remaining "${CMAKE_MATCH_1}")
    else()
        set(base_url "")
    endif()

    if(base_url)
        # Process shortened URL: Split remaining into repo_path and tag
        string(FIND "${remaining}" "@" at_pos REVERSE)
        if(NOT at_pos EQUAL -1)
            string(SUBSTRING "${remaining}" 0 ${at_pos} repo_path)
            math(EXPR tag_pos "${at_pos} + 1")
            string(SUBSTRING "${remaining}" ${tag_pos} -1 tag)
        else()
            set(repo_path "${remaining}")
            set(tag "")
        endif()
        # Construct the full Git URL
        set(url "${base_url}${repo_path}.git")
    else()
        # Process full URL: Split into URL and tag
        string(FIND "${arg}" "@" at_pos REVERSE)
        if(NOT at_pos EQUAL -1)
            string(SUBSTRING "${arg}" 0 ${at_pos} url_part)
            math(EXPR tag_pos "${at_pos} + 1")
            string(SUBSTRING "${arg}" ${tag_pos} -1 tag)
        else()
            set(url_part "${arg}")
            set(tag "")
        endif()
        # Ensure the URL ends with .git
        if(NOT url_part MATCHES "\\.git$")
            set(url "${url_part}.git")
        else()
            set(url "${url_part}")
        endif()
    endif()

    # Extract lib_name from the URL
    string(REGEX REPLACE "^.*/([^/]+)\\.git$" "\\1" name "${url}")

    # Set the output variables
    set(${lib_name} "${name}" PARENT_SCOPE)
    set(${git_url} "${url}" PARENT_SCOPE)
    set(${git_tag} "${tag}" PARENT_SCOPE)
endfunction()

macro(AddExtLib ARGV0)
    set(ALL_EXTLIB_ADDED OFF)

    set(options ONLY_SOURCE SILENT)
    set(oneValueArgs NAME REPO TAG)       
    set(multiValueArgs OPTIONS DEPENDS)

    list(FIND options "${ARGV0}" options_index)
    list(FIND oneValueArgs "${ARGV0}" oneValueArg_index)
    list(FIND multiValueArgs "${ARGV0}" multiValueArg_index)
    if ((options_index EQUAL -1) AND (oneValueArg_index EQUAL -1) AND (multiValueArg_index EQUAL -1))
        cmake_parse_arguments(AEL_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
        if(NOT AEL_ARGS_REPO)
            set(AEL_ARGS_REPO "${ARGV0}")
        endif()
    else()
        cmake_parse_arguments(AEL_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGV0} ${ARGN})
    endif()    

    unset(options)
    unset(oneValueArgs)
    unset(multiValueArgs)
    unset(options_index)
    unset(oneValueArg_index)
    unset(multiValueArg_index)

    ael_parse_url("${AEL_ARGS_REPO}" LIB_NAME AEL_ARGS_REPO LIB_TAG)
    if(NOT AEL_ARGS_NAME)
        set(AEL_ARGS_NAME "${LIB_NAME}")
    endif()
    if(NOT AEL_ARGS_TAG)
        set(AEL_ARGS_TAG "${LIB_TAG}")
    endif()

    ael_transform_flags("${AEL_ARGS_OPTIONS}" AEL_ARGS_OPTIONS)
    ael_fix_tag("${AEL_ARGS_REPO}" "${AEL_ARGS_TAG}" AEL_ARGS_TAG)

    if(NOT SILENT)
        message(STATUS "---------------------------------------------------------------")
        message(STATUS "Name: ${AEL_ARGS_NAME}, URL: ${AEL_ARGS_REPO}, Tag: ${AEL_ARGS_TAG}")
        message(STATUS "ONLY_SOURCE: ${AEL_ARGS_ONLY_SOURCE}")
        message(STATUS "OPTIONS: ${AEL_ARGS_OPTIONS}")
        message(STATUS "DEPENDS: ${AEL_ARGS_DEPENDS}")
        message(STATUS "UNPARSED_ARGUMENTS: ${AEL_ARGS_UNPARSED_ARGUMENTS}")
    endif()

    set(PREFIX_DIR          "${EXTERNAL_PROJECT_PREFIX}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/${CMAKE_BUILD_TYPE}")
    set(SOURCE_DIR          "${EXTERNAL_PROJECT_PREFIX}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/src")
    set(INSTALL_SOURCE_DIR  "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/src")
    set(INSTALL_DIR         "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/${CMAKE_BUILD_TYPE}")

    set(CLEAR_SOURCE_DIR    "${EXTERNAL_PROJECT_PREFIX}/${AEL_ARGS_NAME}/")
    set(CLEAR_INSTALL_DIR   "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/")

    if(NOT SILENT)
        message(STATUS "PREFIX_DIR: ${PREFIX_DIR}")
        message(STATUS "SOURCE_DIR: ${SOURCE_DIR}")
        message(STATUS "INSTALL_SOURCE_DIR: ${INSTALL_SOURCE_DIR}")
        message(STATUS "INSTALL_DIR: ${INSTALL_DIR}")
        message(STATUS "CLEAR_SOURCE_DIR: ${CLEAR_SOURCE_DIR}")
        message(STATUS "CLEAR_INSTALL_DIR: ${CLEAR_INSTALL_DIR}")
    endif()

    add_custom_target(${AEL_ARGS_NAME}_clear_sources
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_SOURCE_DIR}"
    COMMENT "Clearing source directory for ${LIB_NAME}"
    )

    add_custom_target(${AEL_ARGS_NAME}_clear_install
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_INSTALL_DIR}"
    COMMENT "Clearing install directory for ${LIB_NAME}"
    )

    add_custom_target(${AEL_ARGS_NAME}_clear_all
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_SOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_INSTALL_DIR}"
    COMMENT "Clearing all directories for ${LIB_NAME}"
    )
    
    find_package(${AEL_ARGS_NAME} CONFIG PATHS "${INSTALL_DIR}")
    if(NOT ${AEL_ARGS_NAME}_FOUND)
        message(STATUS "Fetching ${AEL_ARGS_NAME} (${AEL_ARGS_TAG})...")
        file(MAKE_DIRECTORY
        "${INSTALL_DIR}/bin"
        "${INSTALL_DIR}/include"
        "${INSTALL_DIR}/lib"
        )

        if(AEL_ARGS_DEPENDS)
            ExternalProject_Add(
                ${AEL_ARGS_NAME}
                GIT_REPOSITORY  ${AEL_ARGS_REPO}
                GIT_TAG         ${AEL_ARGS_TAG}
                DEPENDS         ${AEL_ARGS_DEPENDS}
                PREFIX          "${PREFIX_DIR}"
                TMP_DIR         "${PREFIX_DIR}/tmp"
                STAMP_DIR       "${PREFIX_DIR}/stamp"
                LOG_DIR         "${PREFIX_DIR}/log"
                BINARY_DIR      "${PREFIX_DIR}/bin"
                SOURCE_DIR      "${SOURCE_DIR}"
                CMAKE_ARGS
                    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
                    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                    ${AEL_ARGS_OPTIONS}
                BUILD_ALWAYS OFF
            )
        elseif()
            ExternalProject_Add(
                ${AEL_ARGS_NAME}
                GIT_REPOSITORY  ${AEL_ARGS_REPO}
                GIT_TAG         ${AEL_ARGS_TAG}
                PREFIX          "${PREFIX_DIR}"
                TMP_DIR         "${PREFIX_DIR}/tmp"
                STAMP_DIR       "${PREFIX_DIR}/stamp"
                LOG_DIR         "${PREFIX_DIR}/log"
                BINARY_DIR      "${PREFIX_DIR}/bin"
                SOURCE_DIR      "${SOURCE_DIR}"
                CMAKE_ARGS
                    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
                    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                    ${AEL_ARGS_OPTIONS}
                BUILD_ALWAYS OFF
            )
        endif()
        message(STATUS "${AEL_ARGS_NAME} will be built. Re-run configuration after build completes.")
    else()
        message(STATUS "${AEL_ARGS_NAME} ${AEL_ARGS_TAG} found in ${INSTALL_DIR}")

        list(APPEND CMAKE_PREFIX_PATH "${INSTALL_DIR}")

        set(${AEL_ARGS_NAME}_INSTALL_DIR ${INSTALL_DIR}) 
        set(${AEL_ARGS_NAME}_ADDED TRUE)
        set(${AEL_ARGS_NAME}_INCLUDE_DIRS "${${AEL_ARGS_NAME}_INCLUDE_DIRS}")
        set(${AEL_ARGS_NAME}_LIBRARIES "${${AEL_ARGS_NAME}_LIBRARIES}")
        set(ALL_EXTLIB_ADDED ON)
        
        if(NOT SILENT)
            message(STATUS "${AEL_ARGS_NAME}_INSTALL_DIR: ${${AEL_ARGS_NAME}_INSTALL_DIR}")
            message(STATUS "${AEL_ARGS_NAME}_ADDED: ${${AEL_ARGS_NAME}_ADDED}")
            #message(STATUS "${AEL_ARGS_NAME}_INCLUDE_DIRS: ${${AEL_ARGS_NAME}_INCLUDE_DIRS}")
            #message(STATUS "${AEL_ARGS_NAME}_LIBRARIES: ${${AEL_ARGS_NAME}_LIBRARIES}")
        endif()

        if(WIN32)
            file(GLOB DLL_FILES "${INSTALL_DIR}/bin/*.dll")
        else()
            file(GLOB DLL_FILES "${INSTALL_DIR}/bin/*.so")
        endif()
        if(DLL_FILES)
            if(NOT SILENT)
                message(STATUS "Copying runtime libraries to ${PROJECT_BINARY_DIR}: ${DLL_FILES}")
            endif()
            file(COPY ${DLL_FILES} DESTINATION "${PROJECT_BINARY_DIR}")
        else()
            if(NOT SILENT)
                message(STATUS "No runtime libraries found in ${INSTALL_DIR}/bin")
            endif()
        endif()
    endif()
endmacro()
#[[
set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/exec/${CMAKE_BUILD_TYPE}")
set(CMAKE_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/${CMAKE_BUILD_TYPE}")
set(EXTERNAL_PROJECT_PREFIX "${CMAKE_SOURCE_DIR}/external")
set(EXTERNAL_PROJECT_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/install/${CMAKE_BUILD_TYPE}")

set(ALL_CLEAN_CODE_SOURCES "")
set(ALL_CLEAN_CODE_INCLUDE_DIRS "")

include(FetchContent)
include(ExternalProject)

# -------------------------- add clean code ----------------------------------------
macro(add_clean_code LIB_NAME GIT_REPO GIT_TAG)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs EXTRA_ADD_SOURCE)
    cmake_parse_arguments(ARG "" "" "${multiValueArgs}" ${ARGN})

    set(SOURCE_DIR "${EXTERNAL_PROJECT_PREFIX}/${LIB_NAME}/${GIT_TAG}/src")
    set(INSTALL_SOURCE_DIR "${EXTERNAL_PROJECT_INSTALL_DIR}/${LIB_NAME}/${GIT_TAG}/src")
    set(CLEAR_SOURCE_DIR "${EXTERNAL_PROJECT_PREFIX}/${LIB_NAME}/")
    set(CLEAR_INSTALL_DIR "${EXTERNAL_PROJECT_INSTALL_DIR}/${LIB_NAME}/")

    add_custom_target(${LIB_NAME}_clear
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_SOURCE_DIR}"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_INSTALL_DIR}"
        COMMENT "Clearing all directories for ${LIB_NAME}"
    )

    set(DOWNLOAD_STAMP "${EXTERNAL_PROJECT_PREFIX}/${LIB_NAME}/download.stamp")

    # Generate current stamp content
    set(CURRENT_STAMP_CONTENT "GIT_REPO ${GIT_REPO}\nGIT_TAG ${GIT_TAG}\nEXTRA_ADD_SOURCE ${ARG_EXTRA_ADD_SOURCE}")

    set(NEED_UPDATE OFF)
    if(EXISTS ${DOWNLOAD_STAMP})
        file(READ ${DOWNLOAD_STAMP} EXISTING_STAMP_CONTENT)
        string(COMPARE NOTEQUAL "${EXISTING_STAMP_CONTENT}" "${CURRENT_STAMP_CONTENT}" NEED_UPDATE)

        if(NEED_UPDATE)
            message(STATUS "Git configuration changed for ${LIB_NAME}, forcing redownload")
            file(REMOVE_RECURSE ${SOURCE_DIR})
            file(REMOVE_RECURSE ${INSTALL_SOURCE_DIR})
        endif()
    else()
        message(STATUS "No existing download stamp found for ${LIB_NAME}, will download sources.")
        file(REMOVE_RECURSE ${SOURCE_DIR})
        file(REMOVE_RECURSE ${INSTALL_SOURCE_DIR})
    endif()

    if(NEED_UPDATE OR NOT EXISTS ${SOURCE_DIR} OR NOT EXISTS ${INSTALL_SOURCE_DIR})
        file(REMOVE_RECURSE ${SOURCE_DIR})
        make_directory(${SOURCE_DIR})
        cmake_policy(SET CMP0153 OLD)
        exec_program(git
            ARGS clone --branch ${GIT_TAG} ${GIT_REPO} "${SOURCE_DIR}"
            RETURN_VALUE GIT_CLONE_RESULT
            OUTPUT_VARIABLE GIT_CLONE_OUTPUT
        )

        if (GIT_CLONE_RESULT STREQUAL "0")
            message(STATUS "Repository cloned successfully to ${SOURCE_DIR}")
            file(WRITE ${DOWNLOAD_STAMP} ${CURRENT_STAMP_CONTENT})
            file(MAKE_DIRECTORY ${INSTALL_SOURCE_DIR})
            file(GLOB_RECURSE COPY_SOURCES
                "${SOURCE_DIR}/*.c"
                "${SOURCE_DIR}/*.cpp"
                "${SOURCE_DIR}/*.h"
                "${SOURCE_DIR}/*.hpp"
            )
            foreach(source_file IN LISTS COPY_SOURCES)
                file(RELATIVE_PATH rel_path ${SOURCE_DIR} ${source_file})
                set(target_file "${INSTALL_SOURCE_DIR}/${rel_path}")
                get_filename_component(target_dir ${target_file} DIRECTORY)
                file(MAKE_DIRECTORY ${target_dir})
                configure_file(${source_file} ${target_file} COPYONLY)
            endforeach()
        else()
            message(FATAL_ERROR "Failed to clone repository : ${GIT_CLONE_ERROR}")
        endif()
    endif()

    if(EXISTS "${INSTALL_SOURCE_DIR}")
        set(${LIB_NAME}_SOURCE_DIR "${INSTALL_SOURCE_DIR}")
        set(${LIB_NAME}_INCLUDE_DIR "${INSTALL_SOURCE_DIR}")

        file(GLOB ${LIB_NAME}_SOURCES
            "${INSTALL_SOURCE_DIR}/*.c"
            "${INSTALL_SOURCE_DIR}/*.cpp"
        )
        if(ARG_EXTRA_ADD_SOURCE)
            foreach(mask IN LISTS ARG_EXTRA_ADD_SOURCE)
                file(GLOB_RECURSE EXTRA_SOURCES "${INSTALL_SOURCE_DIR}/${mask}")
                list(APPEND ${LIB_NAME}_SOURCES ${EXTRA_SOURCES})
            endforeach()
        endif()

        list(REMOVE_DUPLICATES ${LIB_NAME}_SOURCES)
        list(FILTER ${LIB_NAME}_SOURCES EXCLUDE REGEX "^$")

        message(STATUS "Sources for ${LIB_NAME} from ${GIT_REPO} (tag ${GIT_TAG}):")
        foreach(mask IN LISTS ${LIB_NAME}_SOURCES)
            message(STATUS "Added ${mask}")
        endforeach()

        list(APPEND ALL_CLEAN_CODE_SOURCES ${${LIB_NAME}_SOURCES})
        list(APPEND ALL_CLEAN_CODE_INCLUDE_DIRS "${${LIB_NAME}_INCLUDE_DIR}")

        set(${LIB_NAME}_FOUND ON)
    endif()
endmacro()

# -------------------------- add external library ----------------------------------------
macro(add_external_library LIB_NAME GIT_REPO GIT_TAG)
    cmake_parse_arguments(ARG "" "" "EXTRA_CMAKE_ARGS" ${ARGN})

    set(INSTALL_DIR "${EXTERNAL_PROJECT_INSTALL_DIR}/${LIB_NAME}/${GIT_TAG}")
    set(PREFIX_DIR "${EXTERNAL_PROJECT_PREFIX}/${LIB_NAME}/${GIT_TAG}/${CMAKE_BUILD_TYPE}")
    set(SOURCE_DIR "${EXTERNAL_PROJECT_PREFIX}/${LIB_NAME}/${GIT_TAG}/src")
    set(CLEAR_SOURCE_DIR "${EXTERNAL_PROJECT_PREFIX}/${LIB_NAME}/")
    set(CLEAR_INSTALL_DIR "${EXTERNAL_PROJECT_INSTALL_DIR}/${LIB_NAME}/")

    file(MAKE_DIRECTORY
        "${INSTALL_DIR}/bin"
        "${INSTALL_DIR}/include"
        "${INSTALL_DIR}/lib"
    )

    add_custom_target(${LIB_NAME}_clear_sources
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_SOURCE_DIR}"
    COMMENT "Clearing source directory for ${LIB_NAME}"
    )

    add_custom_target(${LIB_NAME}_clear_install
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_INSTALL_DIR}"
    COMMENT "Clearing install directory for ${LIB_NAME}"
    )

    add_custom_target(${LIB_NAME}_clear
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_SOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_INSTALL_DIR}"
    COMMENT "Clearing all directories for ${LIB_NAME}"
    )

    find_package(${LIB_NAME} CONFIG PATHS "${INSTALL_DIR}")
    if(NOT ${LIB_NAME}_FOUND)
        message(STATUS "Fetching ${LIB_NAME} (${GIT_TAG})...")

        ExternalProject_Add(
            ${LIB_NAME}
            GIT_REPOSITORY  ${GIT_REPO}
            GIT_TAG         ${GIT_TAG}
            PREFIX          "${PREFIX_DIR}"
            TMP_DIR         "${PREFIX_DIR}/tmp"
            STAMP_DIR       "${PREFIX_DIR}/stamp"
            LOG_DIR         "${PREFIX_DIR}/log"
            BINARY_DIR      "${PREFIX_DIR}/bin"
            SOURCE_DIR      "${SOURCE_DIR}"
            CMAKE_ARGS
                -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
                -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                ${ARG_EXTRA_CMAKE_ARGS}
            BUILD_ALWAYS OFF
        )
        message(STATUS "${LIB_NAME} will be built. Re-run configuration after build completes.")
    else()
        message(STATUS "${LIB_NAME} ${GIT_TAG} found in ${INSTALL_DIR}")

        list(APPEND CMAKE_PREFIX_PATH "${INSTALL_DIR}")

        set(${LIB_NAME}_INSTALL_DIR ${INSTALL_DIR})
        set(${LIB_NAME}_FOUND TRUE)
        set(${LIB_NAME}_INCLUDE_DIRS "${${LIB_NAME}_INCLUDE_DIRS}")
        set(${LIB_NAME}_LIBRARIES "${${LIB_NAME}_LIBRARIES}")

        if(WIN32)
            file(GLOB DLL_FILES "${INSTALL_DIR}/bin/*.dll")
        else()
            file(GLOB DLL_FILES "${INSTALL_DIR}/bin/*.so")
        endif()
        if(DLL_FILES)
            message(STATUS "Copying runtime libraries to ${PROJECT_BINARY_DIR}")
            file(COPY ${DLL_FILES} DESTINATION "${PROJECT_BINARY_DIR}")
        else()
            message(STATUS "No runtime libraries found in ${INSTALL_DIR}/bin")
        endif()
    endif()
endmacro()
#]]
