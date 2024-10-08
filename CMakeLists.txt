cmake_minimum_required(VERSION 3.30)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # Gen. compile_commands.json

if (WIN32)
  set(CMAKE_TOOLCHAIN_FILE C:/vcpkg/scripts/buildsystems/vcpkg.cmake)
  set(VCPKG_TARGET_TRIPLET "x64-windows-static") # Dyn. linking is default on Win
endif (WIN32)

set(CMAKE_CXX_STANDARD 17)
project(SDL3_msvc_template)

if (MSVC)
    # add_compile_options(/nologo /W3 /Zi /cgthreads8)
    add_compile_options(/nologo)
    # Force static linking of C++ runtime
    # set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

##############################################################
# SDL3                                                       #
##############################################################
# Try local system first - fetch from git if not found
find_package(SDL3 QUIET)
if(SDL3_FOUND)
    message(STATUS "Using system SDL3 (find_package)")
endif()

if(NOT SDL3_FOUND)
  include(FetchContent)
  set(FETCHCONTENT_BASE_DIR "${CMAKE_SOURCE_DIR}/src/extern")
  set(SDL_SHARED TRUE CACHE BOOL "Build SDL as shared lib (if available)")
  set(SDL_STATIC TRUE CACHE BOOL "Build SDL as static lib (if available)")
  FetchContent_Declare(
    SDL
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    # GIT_TAG https://github.com/libsdl-org/SDL/releases/tag/preview-3.1.3
    GIT_TAG e292d1f5ace469f718d7b6b4dec8c28e37dcaa0e # preview-3.1.3
    GIT_SHALLOW TRUE
    GIT_PROGRESS TRUE
  )
  message(STATUS "No SDL3 found on system: Building from source")
  message(STATUS "¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨")
  FetchContent_MakeAvailable(SDL)
  set_property(DIRECTORY "${CMAKE_SOURCE_DIR}/src/extern/sdl-src" PROPERTY EXCLUDE_FROM_ALL TRUE)
endif()


##############################################################
# SOURCE GLOBS                                               #
##############################################################
set(SRC)
file(GLOB SRC
  src/*.h src/*.hpp
  src/*.c src/*.cpp
)


##############################################################
# TARGETS & LINKS                                            #
##############################################################
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


##############################################################
# TARGET INCLUDES                                            #
##############################################################

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

# target_link_libraries(SDL3_msvc_template-dyn
#   PRIVATE
#   fmt::fmt

#   # Unnecessary on Win (it uses LoadLibrary, I think) but useful in case
#   # a bout of cross-compilation breaks out.
#   ${CMAKE_DL_LIBS}
# )

set(OUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/Debug")
add_custom_command(TARGET ${PROJECT_NAME}-dyn POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
  "${CMAKE_CURRENT_SOURCE_DIR}/src/extern/sdl-build/Debug/SDL3.dll"
  "${OUT_DIR}/SDL3.dll"
)
