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
        # Check common Homebrew and MacPorts install locations
        find_library(OPENMP_LIBRARY
            NAMES omp libomp.dylib
            PATHS
                /usr/local/opt/libomp/lib
                /opt/homebrew/opt/libomp/lib
                /opt/local/lib
        )
        find_path(OPENMP_INCLUDES
            NAMES omp.h
            PATHS
                /usr/local/opt/libomp/include
                /opt/homebrew/opt/libomp/include
                /opt/local/include
        )
        
        if(OPENMP_LIBRARY AND OPENMP_INCLUDES)
            message(STATUS "--> Found OpenMP: ${OPENMP_LIBRARY}")
            set(CMAKE_CXX_FLAGS_RELEASE "${RELEASE_FLAGS} -Xpreprocessor -fopenmp")
            include_directories(${OPENMP_INCLUDES})
            set(OPENMP_LINK_LIBRARIES ${OPENMP_LIBRARY})
            set(OpenMP_CXX_FOUND TRUE)
        else()
            message(STATUS "--> OpenMP not found in standard locations. Please install with: brew install libomp")
        endif()
    else()
        # Standard OpenMP detection for other platforms
        find_package(OpenMP)
        if (OpenMP_CXX_FOUND)
            message(STATUS "--> OpenMP is enabled")
            set(CMAKE_CXX_FLAGS_RELEASE "${OpenMP_CXX_FLAGS}")
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
  src/main.cc
  src/camera.h
  src/color.h
  src/hittable.h
  src/hittable_list.h
  src/interval.h
  src/material.h
  src/ray.h
  src/rtweekend.h
  src/sphere.h
  src/vec3.h
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
endif()
