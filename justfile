set windows-shell := ["C:\\Program Files\\Git\\bin\\sh.exe","-c"]

import? 'build/build.just'

[no-exit-message]
_default:
    @just _fuzzy-list
    
# List available recipes, with fzf previews
[no-exit-message]
@_fuzzy-list:
    if ! which fzf > /dev/null 2>&1; then \
    echo "FATAL: fzf not installed." && exit 1; fi
    just --choose --chooser "fzf --no-multi --preview 'just --show {1}' --height=16 --border=rounded"    

alias c := configure  
# Run CMake project config/dep. installs
@configure:
    if ! which cmake > /dev/null 2>&1; then \
    echo "FATAL: CMake not installed." && exit 1; fi
    echo "============================================"
    echo "CMake: Configuring project..."
    echo "============================================"
    cmake -B build -S .

alias purge := purge-build-artefacts
[confirm('Confirm purge all build artefacts?')]
@purge-build-artefacts:
    echo "============================================"
    echo "Purging all build artefacts..."
    echo "============================================"
    rm -rf ./build/
    rm -rf ./src/extern/sdl-*/

