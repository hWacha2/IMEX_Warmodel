cmake_minimum_required(VERSION 3.15)
project(CombatCore VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SOURCES
    src/types.cpp
    src/matrix.cpp
    src/file_io.cpp
    src/solver.cpp
    src/ffi_interface.cpp
)

set(HEADERS
    include/types.h
    include/matrix.h
    include/solver.h
    include/file_io.h
    include/ffi_interface.h
)

add_library(combat_core SHARED ${SOURCES} ${HEADERS})
target_include_directories(combat_core PUBLIC include)

if(WIN32)
    set_target_properties(combat_core PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/build/Release"
    )
    if(MSVC)
        target_compile_options(combat_core PRIVATE /O2 /W4)
    endif()
endif()