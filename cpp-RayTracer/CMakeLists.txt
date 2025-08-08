cmake_minimum_required ( VERSION 3.1.0...3.27.0 )

project ( CppRaytracer LANGUAGES CXX )


set ( CMAKE_CXX_STANDARD          23 )
set ( CMAKE_CXX_STANDARD_REQUIRED ON )
set ( CMAKE_CXX_EXTENSIONS        OFF )

set ( CMAKE_CXX_COMPILER          "clang++" )
#set ( CMAKE_CXX_COMPILER          "g++" )

# --- Standard Release Flags ---
# Base flags for optimization, separated for clarity
set(RELEASE_FLAGS "-O3 -DNDEBUG")
if (NOT MSVC) 
    # Using flags from your original file (removed -ffast-math to allow proper infinity handling)
    set(RELEASE_FLAGS "${RELEASE_FLAGS} -mtune=native -march=native")
endif()

# Apply the release flags to CMAKE_CXX_FLAGS_RELEASE
set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_FLAGS}")

# --- OpenMP Handling (Robust Method) ---
option(ENABLE_OPENMP "Enable OpenMP support" OFF)
set(RT_OPENMP_FLAGS "")
if (ENABLE_OPENMP)
    message(STATUS "--> OpenMP is requested")
    
    # Special handling for macOS and Clang
    if(APPLE AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        # First, try to query Homebrew for an explicit prefix (Apple Silicon default under /opt/homebrew)
        set(HOMEBREW_LIBOMP_PREFIX "")
        find_program(HOMEBREW_EXECUTABLE brew)
        if(HOMEBREW_EXECUTABLE)
            execute_process(
                COMMAND ${HOMEBREW_EXECUTABLE} --prefix libomp
                OUTPUT_VARIABLE HOMEBREW_LIBOMP_PREFIX
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
        endif()

        # Prefer Homebrew prefix if detected; avoid accidentally picking stale libs from /usr/local
        if(HOMEBREW_LIBOMP_PREFIX)
            set(OPENMP_HINT_LIB "${HOMEBREW_LIBOMP_PREFIX}/lib")
            set(OPENMP_HINT_INC "${HOMEBREW_LIBOMP_PREFIX}/include")
        else()
            # Fallback to common locations (Apple Silicon first)
            set(OPENMP_HINT_LIB 
                "/opt/homebrew/opt/libomp/lib"
                "/usr/local/opt/libomp/lib"
                "/opt/local/lib"
            )
            set(OPENMP_HINT_INC 
                "/opt/homebrew/opt/libomp/include"
                "/usr/local/opt/libomp/include"
                "/opt/local/include"
            )
        endif()

        # If Apple Silicon Homebrew libomp exists, force it to avoid older Intel /usr/local installs
        set(_APPLE_SILICON_LIBOMP "/opt/homebrew/opt/libomp/lib/libomp.dylib")
        if(EXISTS ${_APPLE_SILICON_LIBOMP})
            set(OPENMP_LIBRARY ${_APPLE_SILICON_LIBOMP})
        else()
            # Use HINTS to prioritize our desired locations over system defaults
            find_library(OPENMP_LIBRARY
                NAMES omp libomp.dylib
                HINTS ${OPENMP_HINT_LIB}
                PATHS ${OPENMP_HINT_LIB}
            )
        endif()
        find_path(OPENMP_INCLUDES
            NAMES omp.h
            HINTS ${OPENMP_HINT_INC}
            PATHS ${OPENMP_HINT_INC}
        )

        if(OPENMP_LIBRARY AND OPENMP_INCLUDES)
            message(STATUS "--> Found OpenMP: ${OPENMP_LIBRARY}")
            set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_FLAGS} -Xpreprocessor -fopenmp")
            include_directories(${OPENMP_INCLUDES})
            set(OPENMP_LINK_LIBRARIES ${OPENMP_LIBRARY})
            set(OpenMP_CXX_FOUND TRUE)
            # Ensure runtime can locate libomp when outside default loader paths
            get_filename_component(_OPENMP_LIB_DIR ${OPENMP_LIBRARY} DIRECTORY)
            set(_OPENMP_RPATH ${_OPENMP_LIB_DIR})
        else()
            message(STATUS "--> OpenMP not found in standard locations. Please install with: brew install libomp")
        endif()
    else()
        # Standard OpenMP detection for other platforms
        find_package(OpenMP)
        if (OpenMP_CXX_FOUND)
            message(STATUS "--> OpenMP is enabled")
            set(CMAKE_CXX_FLAGS_RELEASE "${OpenMP_CXX_FLAGS} ${RELEASE_FLAGS}" )
            set(OPENMP_LINK_LIBRARIES OpenMP::OpenMP_CXX)
        else()
            message(WARNING "--> OpenMP requested but not found by CMake. Disabling.")
            set(ENABLE_OPENMP OFF)
        endif()
    endif()
else()
    message(STATUS "--> OpenMP is disabled")
endif()

# --- Source Files ---
set ( CPP_RAY_TRACER_SOURCES
  src/main.cpp
  src/camera.hpp
  src/color.hpp
  src/hittable.hpp
  src/hittable_list.hpp
  src/interval.hpp
  src/material.hpp
  src/ray.hpp
  src/rtweekend.hpp
  src/sphere.hpp
  src/vec3.hpp
)

# Include directory for headers
include_directories(src)

# --- Compiler Warnings (Preserving your original flags) ---
message (STATUS "Compiler ID: " ${CMAKE_CXX_COMPILER_ID})
# Add your specific warning flags here

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Considered adding -Wall -Wextra for more warnings
    # add_compile_options(-Wall -Wextra)
    add_compile_options(-Wnon-virtual-dtor) 
    add_compile_options(-Wreorder) 
    add_compile_options(-Wmaybe-uninitialized) 
    add_compile_options(-Wunused-variable) 
elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Considered adding -Wall -Wextra for more warnings
    # add_compile_options(-Wall -Wextra)
    add_compile_options(-Wnon-virtual-dtor) 
    add_compile_options(-Wreorder) 
    add_compile_options(-Wsometimes-uninitialized) 
    add_compile_options(-Wunused-variable) 
endif()

# --- Status Messages ---
# Display the flags being used for different configurations
message (STATUS "Debug flags: " ${CMAKE_CXX_FLAGS_DEBUG})
message (STATUS "Release flags: " ${CMAKE_CXX_FLAGS_RELEASE})

# --- Executable ---
add_executable(raytracer ${CPP_RAY_TRACER_SOURCES})

# --- Linking ---
# Link OpenMP libraries if enabled and found
if (ENABLE_OPENMP AND OpenMP_CXX_FOUND)
    if(DEFINED OPENMP_LINK_LIBRARIES)
        target_link_libraries(raytracer PUBLIC ${OPENMP_LINK_LIBRARIES})
    else()
        target_link_libraries(raytracer PUBLIC OpenMP::OpenMP_CXX)
    endif()
    # Add rpath for Homebrew libomp if we detected a non-system location
    if(DEFINED _OPENMP_RPATH)
        message(STATUS "--> Adding rpath: ${_OPENMP_RPATH}")
        target_link_options(raytracer PRIVATE -Wl,-rpath,${_OPENMP_RPATH})
    endif()
endif()
