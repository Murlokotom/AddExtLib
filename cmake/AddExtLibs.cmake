find_package(Git REQUIRED)
include(ExternalProject)
include(FetchContent)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

if(NOT AEL_EXEC_DIR)
    set(AEL_EXEC_DIR "exec")
endif()

if(NOT AEL_BUILD_DIR)
    set(AEL_BUILD_DIR "build")
endif()

if(NOT AEL_EXTERNAL_DIR)
    set(AEL_EXTERNAL_DIR "external")
endif()

if(NOT AEL_INSTALL_DIR)
    set(AEL_INSTALL_DIR "install")
endif()

set(ALL_ADDCODE_INCLUDES "")
set(ALL_ADDCODE_SOURCES "")

set(ALL_EXTLIB_ADDED ON)

set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${AEL_EXEC_DIR}/${CMAKE_BUILD_TYPE}")
set(CMAKE_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${AEL_BUILD_DIR}/${CMAKE_BUILD_TYPE}")
set(EXTERNAL_PROJECT_PREFIX "${CMAKE_SOURCE_DIR}/${AEL_EXTERNAL_DIR}")
set(EXTERNAL_PROJECT_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${AEL_INSTALL_DIR}")

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
    set(options SILENT DISABLE_SEARCH_TAG)
    set(oneValueArgs NAME REPO TAG)       
    set(multiValueArgs OPTIONS DEPENDS COMPONENTS)

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
    if(NOT AEL_ARGS_DISABLE_SEARCH_TAG)
        ael_fix_tag("${AEL_ARGS_REPO}" "${AEL_ARGS_TAG}" AEL_ARGS_TAG)
    endif()

    message(STATUS "---------------------------------------------------------------------------------------------")
    message(STATUS "Name: ${AEL_ARGS_NAME}, URL: ${AEL_ARGS_REPO}, Tag: ${AEL_ARGS_TAG}")
    if(NOT AEL_ARGS_SILENT)
        message(STATUS "OPTIONS: ${AEL_ARGS_OPTIONS}")
        message(STATUS "DEPENDS: ${AEL_ARGS_DEPENDS}")
        message(STATUS "UNPARSED_ARGUMENTS: ${AEL_ARGS_UNPARSED_ARGUMENTS}")
    endif()

    set(PREFIX_DIR          "${EXTERNAL_PROJECT_PREFIX}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/${CMAKE_BUILD_TYPE}")
    set(SOURCE_DIR          "${EXTERNAL_PROJECT_PREFIX}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/src")
    set(INSTALL_DIR         "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/${CMAKE_BUILD_TYPE}")
    set(CLEAR_SOURCE_DIR    "${EXTERNAL_PROJECT_PREFIX}/${AEL_ARGS_NAME}/")
    set(CLEAR_INSTALL_DIR   "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/")

    if(NOT AEL_ARGS_SILENT)
        message(STATUS "PREFIX_DIR: ${PREFIX_DIR}")
        message(STATUS "SOURCE_DIR: ${SOURCE_DIR}")
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

    set(DOWNLOAD_STAMP          "${INSTALL_DIR}/libcompile.stamp")
    set(CURRENT_STAMP_CONTENT   "OPTIONS ${AEL_ARGS_OPTIONS}\nDEPENDS ${AEL_ARGS_DEPENDS}")
    set(NEED_RECOMPILE          OFF)
    if(EXISTS ${DOWNLOAD_STAMP})
        file(READ ${DOWNLOAD_STAMP} EXISTING_STAMP_CONTENT)
        string(COMPARE NOTEQUAL "${EXISTING_STAMP_CONTENT}" "${CURRENT_STAMP_CONTENT}" NEED_RECOMPILE)
        if(NEED_RECOMPILE)
            message(STATUS "Configuration changed for ${LIB_NAME}, forcing recompile")
            file(REMOVE_RECURSE ${INSTALL_DIR})
        endif()
    else()
        message(STATUS "No existing libcompile stamp found for ${LIB_NAME}, forcing recompile")
        file(REMOVE_RECURSE ${INSTALL_DIR})
    endif()    

    unset(${AEL_ARGS_NAME}_DIR CACHE)
    if(AEL_ARGS_COMPONENTS)
        find_package(${AEL_ARGS_NAME} CONFIG HINTS "${INSTALL_DIR}" COMPONENTS ${AEL_ARGS_COMPONENTS} NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH)
    else()
        find_package(${AEL_ARGS_NAME} CONFIG HINTS "${INSTALL_DIR}" NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH)
    endif()
    if(NOT ${AEL_ARGS_NAME}_FOUND)
        message(STATUS "Fetching ${AEL_ARGS_NAME} (${AEL_ARGS_TAG})...")

        set(ALL_EXTLIB_ADDED OFF)

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
        else()
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
        file(WRITE ${DOWNLOAD_STAMP} "${CURRENT_STAMP_CONTENT}")
        message(STATUS "${AEL_ARGS_NAME} will be built. Re-run configuration after build completes.")
    else()
        message(STATUS "${AEL_ARGS_NAME} ${AEL_ARGS_TAG} found in ${INSTALL_DIR}")

        list(APPEND CMAKE_PREFIX_PATH "${INSTALL_DIR}")

        set(${AEL_ARGS_NAME}_SOURCE_DIR ${SOURCE_DIR}) 
        set(${AEL_ARGS_NAME}_INSTALL_DIR ${INSTALL_DIR}) 
        set(${AEL_ARGS_NAME}_ADDED TRUE)

        if(NOT AEL_ARGS_SILENT)
            message(STATUS "${AEL_ARGS_NAME}_INSTALL_DIR: ${${AEL_ARGS_NAME}_INSTALL_DIR}")
            message(STATUS "${AEL_ARGS_NAME}_ADDED: ${${AEL_ARGS_NAME}_ADDED}")
        endif()

        if(WIN32)
            file(GLOB DLL_FILES "${INSTALL_DIR}/bin/*.dll")
        else()
            file(GLOB DLL_FILES "${INSTALL_DIR}/bin/*.so")
        endif()
        if(DLL_FILES)
            if(NOT AEL_ARGS_SILENT)
                message(STATUS "Copying runtime libraries to ${PROJECT_BINARY_DIR}:")
                foreach(SINGLE_DLL IN LISTS DLL_FILES)
                    message(STATUS "${SINGLE_DLL}")
                endforeach()
            endif()
            file(COPY ${DLL_FILES} DESTINATION "${PROJECT_BINARY_DIR}")
        else()
            if(NOT AEL_ARGS_SILENT)
                message(STATUS "No runtime libraries found in ${INSTALL_DIR}/bin")
            endif()
        endif()
    endif()
    unset(DOWNLOAD_STAMP)
    unset(CURRENT_STAMP_CONTENT)
    unset(NEED_RECOMPILE)
    unset(PREFIX_DIR)
    unset(SOURCE_DIR)
    unset(INSTALL_DIR)
    unset(CLEAR_SOURCE_DIR)
    unset(CLEAR_INSTALL_DIR)
endmacro()

macro(AddCode ARGV0)
    set(options SILENT MAKE_SHARED_LIB MAKE_STATIC_LIB DISABLE_SEARCH_TAG)
    set(oneValueArgs NAME REPO TAG)       
    set(multiValueArgs ADD_SOURCES EXL_SOURCES INCLUDES_DIR)

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

    if(AEL_ARGS_MAKE_STATIC_LIB AND AEL_ARGS_MAKE_SHARED_LIB)
        unset(AEL_ARGS_MAKE_SHARED_LIB)
    endif()

    ael_parse_url("${AEL_ARGS_REPO}" LIB_NAME AEL_ARGS_REPO LIB_TAG)
    if(NOT AEL_ARGS_NAME)
        set(AEL_ARGS_NAME "${LIB_NAME}")
    endif()
    if(NOT AEL_ARGS_TAG)
        set(AEL_ARGS_TAG "${LIB_TAG}")
    endif()

    if(NOT AEL_ARGS_DISABLE_SEARCH_TAG)
        ael_fix_tag("${AEL_ARGS_REPO}" "${AEL_ARGS_TAG}" AEL_ARGS_TAG)
    endif()

    set(INSTALL_DIR         "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/src/")
    set(INSTALL_LIB_DIR     "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/${AEL_ARGS_TAG}/lib/${CMAKE_BUILD_TYPE}/")
    set(CLEAR_INSTALL_DIR   "${EXTERNAL_PROJECT_INSTALL_DIR}/${AEL_ARGS_NAME}/")
    set(${AEL_ARGS_NAME}_INSTALL_DIR "${INSTALL_DIR}")

    message(STATUS "---------------------------------------------------------------------------------------------")
    message(STATUS "Name: ${AEL_ARGS_NAME}, URL: ${AEL_ARGS_REPO}, Tag: ${AEL_ARGS_TAG}")

    add_custom_target(${AEL_ARGS_NAME}_clear_install
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CLEAR_INSTALL_DIR}"
    COMMENT "Clearing install directory for ${LIB_NAME}"
    )

    if(NOT AEL_ARGS_SILENT)
        message(STATUS "INSTALL_DIR: ${INSTALL_DIR}")
        message(STATUS "INSTALL_LIB_DIR: ${INSTALL_LIB_DIR}")
        message(STATUS "CLEAR_INSTALL_DIR: ${CLEAR_INSTALL_DIR}")
        message(STATUS "MAKE_SHARED_LIB: ${AEL_ARGS_MAKE_SHARED_LIB}")
        message(STATUS "MAKE_STATIC_LIB: ${AEL_ARGS_MAKE_STATIC_LIB}")
        message(STATUS "ADD_SOURCES: ${AEL_ARGS_ADD_SOURCES}")
        message(STATUS "EXL_SOURCES: ${AEL_ARGS_EXL_SOURCES}")
        message(STATUS "INCLUDES_DIR: ${AEL_ARGS_INCLUDES_DIR}")
        message(STATUS "INCLUDES_DIR: ${AEL_ARGS_INCLUDES_DIR}")
        message(STATUS "UNPARSED_ARGUMENTS: ${AEL_ARGS_UNPARSED_ARGUMENTS}")        
    endif() 

    FetchContent_Populate(
        ${AEL_ARGS_NAME}
        GIT_REPOSITORY      ${AEL_ARGS_REPO}
        GIT_TAG             ${AEL_ARGS_TAG}
        SOURCE_DIR          ${INSTALL_DIR}
    )

    foreach(list_el IN LISTS AEL_ARGS_ADD_SOURCES)
        file(GLOB_RECURSE finded_sources "${INSTALL_DIR}${list_el}")
        list(APPEND ${AEL_ARGS_NAME}_SOURCES ${finded_sources})
    endforeach()
    file(GLOB finded_sources "${INSTALL_DIR}*.c")
    list(APPEND ${AEL_ARGS_NAME}_SOURCES ${finded_sources})
    file(GLOB finded_sources "${INSTALL_DIR}*.cpp")
    list(APPEND ${AEL_ARGS_NAME}_SOURCES ${finded_sources})
    file(GLOB finded_sources "${INSTALL_DIR}*.cc")
    list(APPEND ${AEL_ARGS_NAME}_SOURCES ${finded_sources})
    
    if(AEL_ARGS_EXL_SOURCES)
        foreach(src_file IN LISTS ${AEL_ARGS_NAME}_SOURCES)
            set(exclude_file OFF)
            foreach(mask IN LISTS AEL_ARGS_EXL_SOURCES)
                set(mask_full "${INSTALL_DIR}${mask}")
                if(src_file MATCHES ${mask_full})
                    set(exclude_file ON)
                    break()    
                endif()
            endforeach()
            if(NOT exclude_file)
                list(APPEND filtered_source "${src_file}")
            endif()
        endforeach()
        set(${AEL_ARGS_NAME}_SOURCES "${filtered_source}")
    endif()

    foreach(list_el IN LISTS AEL_ARGS_INCLUDES_DIR)
       list(APPEND ${AEL_ARGS_NAME}_INCLUDES "${INSTALL_DIR}${list_el}") 
    endforeach()
    list(APPEND ${AEL_ARGS_NAME}_INCLUDES "${INSTALL_DIR}")

    if(NOT AEL_ARGS_SILENT)
        message(STATUS "Added source files ${AEL_ARGS_NAME}_SOURCES:")
        foreach(list_el IN LISTS ${AEL_ARGS_NAME}_SOURCES)
            message(STATUS "${list_el}")
        endforeach()
        message(STATUS "Includes dirs ${AEL_ARGS_NAME}_INCLUDES:")
        foreach(list_el IN LISTS ${AEL_ARGS_NAME}_INCLUDES)
            message(STATUS "${list_el}")
        endforeach()
    endif()

    if(AEL_ARGS_MAKE_SHARED_LIB OR AEL_ARGS_MAKE_STATIC_LIB)
        if(AEL_ARGS_MAKE_STATIC_LIB)
            add_library(${AEL_ARGS_NAME} STATIC ${${AEL_ARGS_NAME}_SOURCES})
        endif()
        if(AEL_ARGS_MAKE_SHARED_LIB)
            add_library(${AEL_ARGS_NAME} SHARED ${${AEL_ARGS_NAME}_SOURCES})
        endif()
        set_target_properties(${AEL_ARGS_NAME} PROPERTIES
            OBJECT_OUTPUT_DIRECTORY  ${INSTALL_LIB_DIR}
            ARCHIVE_OUTPUT_DIRECTORY ${INSTALL_LIB_DIR}
            LIBRARY_OUTPUT_DIRECTORY ${INSTALL_LIB_DIR}
            RUNTIME_OUTPUT_DIRECTORY ${INSTALL_LIB_DIR}
        )
        target_include_directories(${AEL_ARGS_NAME} PUBLIC ${${AEL_ARGS_NAME}_INCLUDES})
        add_library(${AEL_ARGS_NAME}::${AEL_ARGS_NAME} ALIAS ${AEL_ARGS_NAME})
        set(${AEL_ARGS_NAME}_INSTALL_LIB_DIR ${INSTALL_LIB_DIR})    

        if(WIN32)
            file(GLOB DLL_FILES "${INSTALL_LIB_DIR}/*.dll")
        else()
            file(GLOB DLL_FILES "${INSTALL_LIB_DIR}/*.so")
        endif()
        if(DLL_FILES)
            if(NOT AEL_ARGS_SILENT)
                message(STATUS "Copying runtime libraries to ${PROJECT_BINARY_DIR}:")
                foreach(SINGLE_DLL IN LISTS DLL_FILES)
                    message(STATUS "${SINGLE_DLL}")
                endforeach()
            endif()
            file(COPY ${DLL_FILES} DESTINATION "${PROJECT_BINARY_DIR}")
        else()
            if(NOT AEL_ARGS_SILENT)
                message(STATUS "No runtime libraries found in ${INSTALL_LIB_DIR}")
            endif()
        endif()
    endif()

    unset(list_el)
    unset(finded_sources)
    unset(src_file)
    unset(src_lower)
    unset(mask_lower)
endmacro()