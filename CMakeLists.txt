cmake_minimum_required(VERSION 3.28...3.30)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules")

project(obs-studio VERSION ${OBS_VERSION_CANONICAL})

if(CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
  include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/windows/architecture.cmake")
  if(NOT OBS_PARENT_ARCHITECTURE STREQUAL CMAKE_VS_PLATFORM_NAME)
    return()
  endif()
endif()

include(compilerconfig)
include(defaults)
include(helpers)

option(ENABLE_FRONTEND "Enable building with UI (requires Qt)" ON)
option(ENABLE_SCRIPTING "Enable scripting support" OFF)
option(ENABLE_HEVC "Enable HEVC encoders" ON)

add_subdirectory(libobs)
if(OS_WINDOWS)
  add_subdirectory(libobs-d3d11)
  add_subdirectory(libobs-winrt)
endif()
add_subdirectory(libobs-opengl)
if(OS_MACOS)
  add_subdirectory(libobs-metal)
endif()
add_subdirectory(plugins)

add_subdirectory(test/test-input)

add_subdirectory(frontend)

# LBS frontend.
add_subdirectory(src)

# Build-tree layout for ./build_ubuntu/src/lbs
set(LBS_BUILD_DATA_DIR "${CMAKE_BINARY_DIR}/share/obs/lbs")
set(LIBOBS_BUILD_DATA_DIR "${CMAKE_BINARY_DIR}/share/obs/libobs")

# OBS rundir layout for ./build_ubuntu/rundir/Debug/bin/lbs
set(LBS_RUNTIME_DATA_DIR "${OBS_OUTPUT_DIR}/$<CONFIG>/share/obs/lbs")
set(LIBOBS_RUNTIME_DATA_DIR "${OBS_OUTPUT_DIR}/$<CONFIG>/share/obs/libobs")

message_configuration()
