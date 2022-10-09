#!/bin/bash
set -e

USE_FULL_API=TRUE
# Settings only for Android
ANDROID_NDK=/opt/android-ndk-r17c # docker
#ANDROID_NDK=/Users/hongming/Library/android-ndk-r17c # macOS

# For TARGET_OS=android, TARGET_ABI should be arm64-v8a or armeabi-v7a.
# For TARGET_OS=linux, TARGET_ABI should be arm64, armhf or amd64.
# Kirin810/820/985/990/9000/9000E: TARGET_OS=android and TARGET_ABI=arm64-v8a
# MT8168/8175, Kirin810/820/985/990/9000/9000E: TARGET_OS=android and TARGET_ABI=armeabi-v7a
# RK1808EVB, TB-RK1808S0, Kunpeng-920+Ascend310: TARGET_OS=linux and TARGET_ABI=arm64
# RK1806EVB, RV1109/1126 EVB: TARGET_OS=linux and TARGET_ABI=armhf 
# Intel-x86+Ascend310: TARGET_OS=linux and TARGET_ABI=amd64
TARGET_OS=linux
if [ -n "$1" ]; then
  TARGET_OS=$1
fi

TARGET_ABI=arm64
if [ -n "$2" ]; then
  TARGET_ABI=$2
fi

function readlinkf() {
  perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}

CMAKE_COMMAND_ARGS="-DCMAKE_VERBOSE_MAKEFILE=ON -DUSE_FULL_API=${USE_FULL_API} -DTARGET_OS=${TARGET_OS} -DTARGET_ABI=${TARGET_ABI} -DPADDLE_LITE_DIR=$(readlinkf ../../libs/PaddleLite) -DOpenCV_DIR=$(readlinkf ../../libs/OpenCV)"
if [ "${TARGET_OS}" == "android" ]; then
  ANDROID_NATIVE_API_LEVEL=android-23
  if [ $TARGET_ABI == "armeabi-v7a" ]; then
    ANDROID_NATIVE_API_LEVEL=android-21
  fi
  CMAKE_COMMAND_ARGS="${CMAKE_COMMAND_ARGS} -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake -DANDROID_NDK=${ANDROID_NDK} -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL} -DANDROID_STL=c++_shared -DANDROID_ABI=${TARGET_ABI} -DANDROID_ARM_NEON=TRUE"
fi

BUILD_DIR=build.${TARGET_OS}.${TARGET_ABI}

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR
cmake ${CMAKE_COMMAND_ARGS} ..
make
