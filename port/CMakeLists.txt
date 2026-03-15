cmake_minimum_required(VERSION 3.20)
project(ff5-port VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Backend options ────────────────────────────────────────────────────────────
option(FF5_GFX_SDL2   "Use SDL2 graphics backend" ON)
option(FF5_AUDIO_SDL2 "Use SDL2 audio backend"    ON)
option(FF5_INPUT_SDL2 "Use SDL2 input backend"    ON)

# ── Platform abstraction library ───────────────────────────────────────────────
add_library(ff5-platform STATIC)

target_include_directories(ff5-platform PUBLIC src)

if(FF5_GFX_SDL2 OR FF5_AUDIO_SDL2 OR FF5_INPUT_SDL2)
    find_package(SDL2 CONFIG REQUIRED)
    # SDL2::SDL2 = the main library; SDL2::SDL2main = entry-point shim (Windows)
    target_link_libraries(ff5-platform PUBLIC SDL2::SDL2)
endif()

if(FF5_GFX_SDL2)
    target_sources(ff5-platform PRIVATE
        src/platform/gfx/sdl2/SDL2Renderer.cpp)
    target_compile_definitions(ff5-platform PUBLIC FF5_GFX_SDL2)
endif()

if(FF5_AUDIO_SDL2)
    target_sources(ff5-platform PRIVATE
        src/platform/audio/sdl2/SDL2AudioOutput.cpp)
    target_compile_definitions(ff5-platform PUBLIC FF5_AUDIO_SDL2)
endif()

if(FF5_INPUT_SDL2)
    target_sources(ff5-platform PRIVATE
        src/platform/input/sdl2/SDL2Input.cpp)
    target_compile_definitions(ff5-platform PUBLIC FF5_INPUT_SDL2)
endif()

# ── Engine library ─────────────────────────────────────────────────────────────
add_library(ff5-engine STATIC
    src/engine/Engine.cpp
    src/engine/field/Field.cpp
    src/engine/battle/Battle.cpp
    src/engine/menu/Menu.cpp
    src/engine/cutscene/Cutscene.cpp
    src/engine/sound/Sound.cpp
)

target_include_directories(ff5-engine PUBLIC src)
target_link_libraries(ff5-engine PUBLIC ff5-platform)

# ── Main executable ────────────────────────────────────────────────────────────
add_executable(ff5-port src/main.cpp)

target_link_libraries(ff5-port PRIVATE ff5-engine)

# SDL2main provides the WinMain → main entry-point shim on Windows.
# It must link to the executable, not the static library.
if(FF5_GFX_SDL2 OR FF5_AUDIO_SDL2 OR FF5_INPUT_SDL2)
    target_link_libraries(ff5-port PRIVATE SDL2::SDL2main)
endif()
