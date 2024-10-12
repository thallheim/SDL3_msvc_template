bin_root          := "@REPO_NAME@"
dyn_suffix        := "-dyn"
static_suffix     := "-static"
bin_name_dyn      := bin_root + dyn_suffix
bin_name_static   := bin_root + static_suffix

alias b := build
# Build project
@build:
    if ! which cmake > /dev/null 2>&1; then \
    echo "FATAL: CMake not installed." && exit 1; fi
    echo "============================================"
    echo "CMake: Building project..."
    echo "============================================"
    cmake --build build

alias r := run-dyn
alias rd := run-dyn
# Run the thing (dyn. linked)
[windows]
@run-dyn: build
    ./build/Debug/{{bin_name_dyn}}.exe

alias rs := run-static
# Run the thing (Statically Linked Edition)
[windows]
@run-static: build
    ./build/Debug/{{bin_name_static}}.exe

# Just do it (configure -> build -> run (static))
[windows]
@go: configure build run-static
    ./build/Debug/{{bin_name_static}}.exe

# Display available recipes on stdout
list:
    @just --list
