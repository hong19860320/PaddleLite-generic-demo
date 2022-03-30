cmake_minimum_required(VERSION 3.10)

if(TARGET_OS STREQUAL "linux")
  set(CMAKE_SYSTEM_NAME Linux)
  if(TARGET_ABI STREQUAL "arm64")
    set(CMAKE_SYSTEM_PROCESSOR aarch64)
    set(CMAKE_C_COMPILER "aarch64-linux-gnu-gcc")
    set(CMAKE_CXX_COMPILER "aarch64-linux-gnu-g++")
  elseif(TARGET_ABI STREQUAL "armhf")
    set(CMAKE_SYSTEM_PROCESSOR arm)
    set(CMAKE_C_COMPILER "arm-linux-gnueabihf-gcc")
    set(CMAKE_CXX_COMPILER "arm-linux-gnueabihf-g++")
  elseif(TARGET_ABI STREQUAL "amd64")
    set(CMAKE_SYSTEM_PROCESSOR x86_64)
    set(CMAKE_C_COMPILER "gcc")
    set(CMAKE_CXX_COMPILER "g++")
  else()
    message(FATAL_ERROR "Unknown ABI ${TARGET_ABI}, only supports arm64, armhf and amd64 for Linux.")
    return()
  endif()
elseif(TARGET_OS STREQUAL "android")
  if(TARGET_ABI STREQUAL "arm64-v8a")
  elseif(TARGET_ABI STREQUAL "armeabi-v7a")
  else()
    message(FATAL_ERROR "Unknown ABI ${TARGET_ABI}, only supports arm64-v8a and armeabi-v7a for Android.")
    return()
  endif()
else()
  message(FATAL_ERROR "Unknown OS ${TARGET_OS}.")
  return()
endif()

project(model_test)
message(STATUS "TARGET OS: ${TARGET_OS}")
message(STATUS "TARGET ABI: ${TARGET_ABI}")
message(STATUS "PADDLE LITE DIR: ${PADDLE_LITE_DIR}")
message(STATUS "OpenCV DIR: ${OpenCV_DIR}")

include_directories(${PADDLE_LITE_DIR}/${TARGET_OS}/${TARGET_ABI}/include)
link_directories(${PADDLE_LITE_DIR}/${TARGET_OS}/${TARGET_ABI}/lib)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wl,--allow-shlib-undefined")
if(TARGET_ABI STREQUAL "arm64")
  set(CMAKE_CXX_FLAGS "-march=armv8-a ${CMAKE_CXX_FLAGS}")
  set(CMAKE_C_FLAGS "-march=armv8-a ${CMAKE_C_FLAGS}")
elseif(TARGET_ABI STREQUAL "armhf")
  set(CMAKE_CXX_FLAGS "-march=armv7-a -mfloat-abi=hard -mfpu=neon-vfpv4 ${CMAKE_CXX_FLAGS}")
  set(CMAKE_C_FLAGS "-march=armv7-a -mfloat-abi=hard -mfpu=neon-vfpv4 ${CMAKE_C_FLAGS}" )
endif()

find_package(OpenMP REQUIRED)
if(OpenMP_FOUND OR OpenMP_CXX_FOUND)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
  message(STATUS "Found OpenMP ${OpenMP_VERSION} ${OpenMP_CXX_VERSION}")
  message(STATUS "OpenMP C flags:  ${OpenMP_C_FLAGS}")
  message(STATUS "OpenMP CXX flags:  ${OpenMP_CXX_FLAGS}")
  message(STATUS "OpenMP OpenMP_CXX_LIB_NAMES:  ${OpenMP_CXX_LIB_NAMES}")
  message(STATUS "OpenMP OpenMP_CXX_LIBRARIES:  ${OpenMP_CXX_LIBRARIES}")
else()
  message(FATAL_ERROR "Could not found OpenMP!")
  return()
endif()

#set(OpenCV_DIR "${OpenCV_DIR}/${TARGET_OS}/sdk/native/jni")
#find_package(OpenCV REQUIRED)
#message(STATUS "OpenCV libraries: ${OpenCV_LIBS}")
#include_directories(${OpenCV_INCLUDE_DIRS})

add_executable(model_test model_test.cc)

if(NOT DEFINED USE_FULL_API)
  set(USE_FULL_API TRUE)
endif()

add_library(
  # Sets the name of the library.
  paddle_api_shared
  # Sets the library as a shared library.
  SHARED
  # Provides a relative path to your source file(s).
  IMPORTED)

if(USE_FULL_API)
  add_definitions(-DUSE_FULL_API)
  set_target_properties(
    # Specifies the target library.
    paddle_api_shared
    # Specifies the parameter you want to define.
    PROPERTIES
      IMPORTED_LOCATION
      ${PADDLE_LITE_DIR}/${TARGET_OS}/${TARGET_ABI}/lib/libpaddle_full_api_shared.so
      # Provides the path to the library you want to import.
  )
else()
  set_target_properties(
    # Specifies the target library.
    paddle_api_shared
    # Specifies the parameter you want to define.
    PROPERTIES
      IMPORTED_LOCATION
      ${PADDLE_LITE_DIR}/${TARGET_OS}/${TARGET_ABI}/lib/libpaddle_light_api_shared.so
      # Provides the path to the library you want to import.
  )
endif()

target_link_libraries(model_test paddle_api_shared dl)
