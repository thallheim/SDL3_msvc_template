cmake_minimum_required(VERSION 3.30)
# Gen. compile_commands.json (no effect with msvc)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)

# Check if initial config has been done already
if(NOT DEFINED CACHE{FIRST_RUN})
  set(FIRST_RUN TRUE CACHE BOOL "Indicates whether this is the initial (config) CMake run")
  message(STATUS "FIRST_RUN: ${FIRST_RUN}")
else()
  set(FIRST_RUN FALSE)
  message(NOTICE "FIRST_RUN: ${FIRST_RUN}")
endif()

# Get the repository name & set project name to match
## Cache
set(REPO_NAME "" CACHE STRING "Name of parent repo")
set(REPO_PATH "" CACHE PATH "Path to parent repo")

execute_process(
  COMMAND git rev-parse --show-toplevel
  OUTPUT_VARIABLE REPO_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
get_filename_component(REPO_NAME ${REPO_PATH} NAME)
set(REPO_NAME ${REPO_NAME} CACHE STRING "Name of parent repo")
project(${REPO_NAME})

######################################################################
# JUSTFILE GEN                                                       #
######################################################################
set(JUSTFILE_PATH ${CMAKE_SOURCE_DIR}/justfile)
if( (FIRST_RUN) AND (NOT EXISTS ${CMAKE_BINARY_DIR}/build.justfile) )
  message("No justfile at project root: Generating from template")
  set(TEMPLATE_JUSTFILE ${CMAKE_SOURCE_DIR}/src/template.justfile)
  configure_file(${TEMPLATE_JUSTFILE} ${CMAKE_BINARY_DIR}/build.just @ONLY)
endif()

######################################################################
# VCPKG                                                              #
######################################################################
if (WIN32)
  set(VCPKG_CMAKEFILE C:/vcpkg/scripts/buildsystems/vcpkg.cmake)
  if (EXISTS ${VCPKG_CMAKEFILE})
    set(CMAKE_TOOLCHAIN_FILE ${VCPKG_CMAKEFILE})
    # Dyn. linking is default on Win
    set(VCPKG_TARGET_TRIPLET "x64-windows-static")
  else()
    message(WARNING "Couldn't find vcpkg cmake file")
  endif()
endif (WIN32)

if (LINUX)
  set(VCPKG_CMAKEFILE_LINUX "$ENV{HOME}/vcpkg/scripts/buildsystems/vcpkg.cmake")
  if(EXISTS ${VCPKG_CMAKEFILE_LINUX})
    set(CMAKE_TOOLCHAIN_FILE ${VCPKG_CMAKEFILE_LINUX})
  else()
    set(CMAKE_TOOLCHAIN_FILE /usr/local/vcpkg/scripts/buildsystems/vcpkg.cmake)
  endif()
endif (LINUX)

if (MSVC)
  add_compile_options(/nologo)
  # Force static linking of C++ runtime
  # set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

######################################################################
# EXTERNAL LIBS/CONTENT                                              #
######################################################################
# SDL3: Try local system first - fall back to git if not found

set(SDL_ARCHIVE_PATH ${CMAKE_SOURCE_DIR}/src/extern/archives/SDL-preview-3.1.3.zip)
set(EXTERN_SRC_DIR ${CMAKE_SOURCE_DIR}/src/extern)
set(SDL_SRC_DIR ${CMAKE_SOURCE_DIR}/src/extern/sdl-src)
# set(JUSTFILE_PATH ${CMAKE_SOURCE_DIR}/justfile)
set(SDL3_FOUND FALSE CACHE BOOL "Indicates whether CMake has found SDL3")
set(SDL_SHARED TRUE CACHE BOOL "Build SDL as shared lib (if available)")
set(SDL_STATIC TRUE CACHE BOOL "Build SDL as static lib (if available)")
set(FETCHCONTENT_BASE_DIR ${EXTERN_SRC_DIR})

find_package(SDL3 QUIET)
include(FetchContent)
if(SDL3_FOUND)
  message(STATUS "Using system SDL3 (find_package)")
else() ############################################# Try archive
  if(EXISTS ${SDL_ARCHIVE_PATH})
    message(STATUS "Using SDL3 (preview-v3.1.3) source archive")
    # Ensure dst exists and extract src
    if(NOT EXISTS ${SDL_SRC_DIR})
      file(MAKE_DIRECTORY ${SDL_SRC_DIR})
      file(ARCHIVE_EXTRACT
        INPUT        ${SDL_ARCHIVE_PATH}
        DESTINATION  ${EXTERN_SRC_DIR}
        # TOUCH        # Replace archive's timestamps with current local times
      )
    endif()
    # add_subdirectory(${SDL_SRC_DIR})
    FetchContent_Declare(
      SDL
      SOURCE_DIR ${SDL_SRC_DIR}
    )
    FetchContent_MakeAvailable(SDL)
    set_property(DIRECTORY ${SDL_SRC_DIR} PROPERTY EXCLUDE_FROM_ALL TRUE)
    set(SDL3_FOUND TRUE)
  else() ############################################# no archive: use github fallback
    FetchContent_Declare(
      SDL
      GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
      # GIT_TAG https://github.com/libsdl-org/SDL/releases/tag/preview-3.1.3
      GIT_TAG e292d1f5ace469f718d7b6b4dec8c28e37dcaa0e # preview-3.1.3
      GIT_SHALLOW TRUE
      GIT_PROGRESS TRUE
    )
    message(STATUS "No (system) SDL3 & no archived SDL found: Using github fallback.)")
    FetchContent_MakeAvailable(SDL)
    set_property(DIRECTORY ${SDL_SRC_DIR} PROPERTY EXCLUDE_FROM_ALL TRUE)
    set(SDL3_FOUND TRUE)
  endif()
endif()


######################################################################
# SOURCE GLOBS                                                       #
######################################################################
set(SRC)
file(GLOB SRC
  src/*.h src/*.hpp
  src/*.c src/*.cpp
)

######################################################################
# TARGETS & LINKS                                                    #
######################################################################
if(SDL_SHARED)
  add_executable(${PROJECT_NAME}-dyn ${SRC})
  target_compile_options(${PROJECT_NAME}-dyn
    PRIVATE
    "/W3" "/Zi" "/cgthreads8")
endif()

if(SDL_STATIC)
  # Force static linking of C++ runtime
  # set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  add_executable(${PROJECT_NAME}-static ${SRC})
  target_compile_options(${PROJECT_NAME}-static
    PRIVATE
    "/W3" "/Zi" "/cgthreads8")
endif()

if(SDL_SHARED)
  target_link_libraries(${PROJECT_NAME}-dyn
    PRIVATE
    SDL3::SDL3
  )
endif()

# target_link_libraries(${PROJECT_NAME}
# PRIVATE
# SDL3::SDL3-shared
# )

if(SDL_STATIC)
  target_link_libraries(${PROJECT_NAME}-static
    PRIVATE
    SDL3::SDL3-static
  )
endif()

######################################################################
# TARGET INCLUDES                                                    #
######################################################################
# find_package(fmt CONFIG REQUIRED)

target_include_directories(${PROJECT_NAME}-dyn
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/src/extern
  ${SDL3_INCLUDE_DIRS}
)
target_include_directories(${PROJECT_NAME}-static
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/src/extern
  ${SDL3_INCLUDE_DIRS}
)

#   # Unnecessary on Win (it uses LoadLibrary) but useful in case
#   # a bout of cross-compilation breaks out.
#   ${CMAKE_DL_LIBS}
# )

set(OUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/Debug")
add_custom_command(TARGET ${PROJECT_NAME}-dyn POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
  "${CMAKE_CURRENT_SOURCE_DIR}/src/extern/sdl-build/Debug/SDL3.dll"
  "${OUT_DIR}/SDL3.dll"
)
