set windows-shell := ["C:\\Program Files\\Git\\bin\\sh.exe","-c"]

bin_root := "SDL3_msvc_template"
dyn_suffix := "-dyn"
static_suffix := "-static"
bin_name_dyn := bin_root + dyn_suffix
bin_name_static := bin_root + static_suffix

_default:
    @just _fuzzy-list
    
# This list, but with fzf \o/
@_fuzzy-list:
    if ! which fzf > /dev/null 2>&1; then \
    echo "FATAL: fzf not installed." && exit 1; fi
    just --choose \
    --chooser "fzf --no-multi --min-height=10 --height=~25 --border=sharp"

# Run CMake project config/dep. installs
@configure:
    if ! which cmake > /dev/null 2>&1; then \
    echo "FATAL: CMake not installed." && exit 1; fi
    echo "============================================"
    echo "CMake: Configuring project..."
    echo "============================================"
    cmake -B build -S .

alias b := build
# Build project
@build:
    if ! which cmake > /dev/null 2>&1; then \
    echo "FATAL: CMake not installed." && exit 1; fi
    echo "============================================"
    echo "CMake: Building project..."
    echo "============================================"
    cmake --build build

alias purge := purge-build-artefacts
@purge-build-artefacts:
    echo "============================================"
    echo "Purging build artefacts..."
    echo "============================================"
    rm -rf ./build/Debug
    #rm -rf ./src/extern/sdl*

alias r := run-dyn
alias rd := run-dyn
# Run the thing (dyn. linked)
@run-dyn:
    ./build/Debug/{{bin_name_dyn}}.exe

alias rs := run-static
# Run the thing (Statically Linked Edition)
@run-static:
    ./build/Debug/{{bin_name_static}}.exe

# Just do it
@go: configure build run-static
    ./build/Debug/{{bin_name_static}}.exe

# Display available recipes
list:
    @just --list
