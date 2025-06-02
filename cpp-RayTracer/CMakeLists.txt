#---------------------------------------------------------------------------------------------------
# CMake Build Configuration for the Ray Tracing Weekend Series
#
# See README.md for guidance.
#---------------------------------------------------------------------------------------------------

cmake_minimum_required ( VERSION 3.1.0...3.27.0 ) # Use a reasonable minimum

project ( CppRaytracer LANGUAGES CXX )

# Set to C++ Standard (Using C++23 as per your original file)
set ( CMAKE_CXX_STANDARD          23 )
set ( CMAKE_CXX_STANDARD_REQUIRED ON )
set ( CMAKE_CXX_EXTENSIONS        OFF )
# Keep your hardcoded compiler if needed, otherwise comment out for flexibility
set ( CMAKE_CXX_COMPILER          "clang++" )
#set ( CMAKE_CXX_COMPILER          "g++" )

# --- Standard Release Flags ---
# Base flags for optimization, separated for clarity
set(RT_BASE_RELEASE_FLAGS "-O3 -DNDEBUG")
if (NOT MSVC) # Add flags common to GCC/Clang
    # Using flags from your original file (removed -ffast-math to allow proper infinity handling)
    set(RT_BASE_RELEASE_FLAGS "${RT_BASE_RELEASE_FLAGS} -mtune=native -march=native")
endif()

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
            set(RT_OPENMP_FLAGS "-Xpreprocessor -fopenmp")
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
            set(RT_OPENMP_FLAGS "${OpenMP_CXX_FLAGS}")
            set(OPENMP_LINK_LIBRARIES OpenMP::OpenMP_CXX)
        else()
            message(WARNING "--> OpenMP requested but not found by CMake. Disabling.")
            set(ENABLE_OPENMP OFF)
        endif()
    endif()
else()
    message(STATUS "--> OpenMP is disabled")
endif()

# --- PGO Flags (GCC and Clang) ---
set(RT_PGO_GENERATE_FLAGS "")
set(RT_PGO_USE_FLAGS "")
# Check compiler ID to set the correct PGO flags
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(RT_PGO_GENERATE_FLAGS "-fprofile-instr-generate")
    # Assumes profile data file is named rtweekend.profdata in the build dir
    set(RT_PGO_USE_FLAGS "-fprofile-instr-use=rtweekend.profdata")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(RT_PGO_GENERATE_FLAGS "-fprofile-generate")
    # GCC uses profile data location implicitly, -fprofile-correction helps
    set(RT_PGO_USE_FLAGS "-fprofile-use -fprofile-correction")
endif()

# --- Define Build Type Flags ---
# Combine base, OpenMP, and PGO flags based on build type
# Standard Release
set(CMAKE_CXX_FLAGS_RELEASE "${RT_BASE_RELEASE_FLAGS} ${RT_OPENMP_FLAGS}" CACHE STRING "Flags used by the C++ compiler for Release builds." FORCE)
# PGO Generate Step
set(CMAKE_CXX_FLAGS_RELEASE_PGO_GENERATE "${RT_BASE_RELEASE_FLAGS} ${RT_OPENMP_FLAGS} ${RT_PGO_GENERATE_FLAGS}" CACHE STRING "Flags for PGO Instrumentation build." FORCE)
# PGO Use Step
set(CMAKE_CXX_FLAGS_RELEASE_PGO_USE "${RT_BASE_RELEASE_FLAGS} ${RT_OPENMP_FLAGS} ${RT_PGO_USE_FLAGS}" CACHE STRING "Flags for PGO Optimized build." FORCE)
# Standard Debug
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0" CACHE STRING "Flags used by the C++ compiler for Debug builds." FORCE)

# Add the custom build types to the list CMake knows about (for GUIs, etc.)
# Set default build type if none is specified (optional, often Release)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the build type" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release Release_PGO_Generate Release_PGO_Use)


# --- Source Files ---
# List only the main source file needed for the executable
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
if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # /wd #### - Disable warning
    # /we #### - treat warning as error
    add_compile_options("/W4")      # Enable level-4 warnings
    add_compile_options("/we 4265") # Class has virtual functions, but its non-trivial destructor is not virtual
    add_compile_options("/we 5204") # Class has virtual functions, but its trivial destructor is not virtual
    add_compile_options("/wd 4100") # unreferenced formal parameter
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Consider adding -Wall -Wextra for more warnings
    # add_compile_options(-Wall -Wextra)
    add_compile_options(-Wnon-virtual-dtor) # Class has virtual functions, but its destructor is not virtual
    add_compile_options(-Wreorder) # Data member will be initialized after [other] data member
    add_compile_options(-Wmaybe-uninitialized) # Variable improperly initialized
    add_compile_options(-Wunused-variable) # Variable is defined but unused
elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Consider adding -Wall -Wextra for more warnings
    # add_compile_options(-Wall -Wextra)
    add_compile_options(-Wnon-virtual-dtor) # Class has virtual functions, but its destructor is not virtual
    add_compile_options(-Wreorder) # Data member will be initialized after [other] data member
    add_compile_options(-Wsometimes-uninitialized) # Variable improperly initialized (Clang equivalent)
    add_compile_options(-Wunused-variable) # Variable is defined but unused
endif()

# --- Status Messages ---
# Display the flags being used for different configurations
message (STATUS "Debug flags: " ${CMAKE_CXX_FLAGS_DEBUG})
message (STATUS "Release flags: " ${CMAKE_CXX_FLAGS_RELEASE})
message (STATUS "PGO Generate flags: " ${CMAKE_CXX_FLAGS_RELEASE_PGO_GENERATE})
message (STATUS "PGO Use flags: " ${CMAKE_CXX_FLAGS_RELEASE_PGO_USE})

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

# --- Optional: Installation ---
# If you want to install the executable
# install(TARGETS inOneWeekend DESTINATION bin)
