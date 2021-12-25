#!/bin/bash
set -e

readlinkf() {
  perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}

cur_dir=$(readlinkf $(pwd))

# User config
src_dir=/Work/Paddle-Lite/experiment/Paddle-Lite
# HuaweiKirinNPU
build_huawei_kirin_npu=0
hiai_ddk_lib=$src_dir/hiai_ddk_lib_510
# MediatekAPU
build_mediatek_apu=0
apu_ddk=$src_dir/apu_ddk
# RockchipNPU
build_rockchip_npu=0
rknpu_ddk=$src_dir/rknpu_ddk
# AmlogicNPU
build_amlogic_npu=0
amlnpu_ddk_android=$src_dir/amlnpu_ddk_android
amlnpu_ddk_linux=$src_dir/amlnpu_ddk_linux
# ImaginationNNA
build_imagination_nna=0
imagination_nna_sdk=$src_dir/imagination_nna_sdk
# VerisiliconTIMVX
build_verisilicon_timvx=0 # No need to set the SDK path since it can be downloaded automatically
# HuaweiAscendNPU
build_huawei_ascend_npu=0
ascend_toolkit_aarch64_linux=$src_dir/ascend-toolkit-aarch64-linux/3.3.0
ascend_toolkit_x86_64_linux=$src_dir/ascend-toolkit-x86_64-linux/3.3.0
# KunlunxinXTCL
build_kunlunxin_xtcl=0 # No need to set the SDK path since it can be downloaded automatically

build_and_update_lib() {
  local os=$1
  local arch=$2
  local toolchain=$3
  local rebuild_all=$4
  local tiny_publish=$5
  local disable_huawei_ascend_npu=$6

  build_cmd="--arch=$arch --toolchain=$toolchain --with_extra=ON --with_exception=ON --with_nnadapter=ON"
  build_dir=$src_dir/build.lite.$os.$arch.$toolchain
  device_list={}
  if [ "$os" = "android" ]; then
    # android
    build_cmd="$build_cmd --android_stl=c++_shared --with_cv=ON"
    if [ "$arch" = "armv8" ]; then
      lib_abi="arm64-v8a"
      if [ $build_huawei_kirin_npu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_kirin_npu=ON --nnadapter_huawei_kirin_npu_sdk_root=$hiai_ddk_lib"
        device_list={"${device_list[@]}" "huawei_kirin_npu"}
      fi
    elif [ "$arch" = "armv7" ]; then
      lib_abi="armeabi-v7a"
      if [ $build_huawei_kirin_npu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_kirin_npu=ON --nnadapter_huawei_kirin_npu_sdk_root=$hiai_ddk_lib"
        device_list={"${device_list[@]}" "huawei_kirin_npu"}
      fi
      if [ $build_mediatek_apu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_mediatek_apu=ON --nnadapter_mediatek_apu_sdk_root=$apu_ddk"
        device_list={"${device_list[@]}" "mediatek_apu"}
      fi
      if [ $build_amlogic_npu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_amlogic_npu=ON --nnadapter_amlogic_npu_sdk_root=$amlnpu_ddk_android"
        device_list={"${device_list[@]}" "amlogic_npu"}
      fi
      if [ $build_verisilicon_timvx -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_verisilicon_timvx=ON"
        device_list={"${device_list[@]}" "verisilicon_timvx"}
      fi
    else
      echo "Abi $arch is not supported for $os and any devices."
    fi
    lib_os="android"
  else
    # linux
    if [ "$arch" = "armv8" ]; then
      lib_abi="arm64"
      build_cmd="$build_cmd --with_cv=ON"
      if [ $build_rockchip_npu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_rockchip_npu=ON --nnadapter_rockchip_npu_sdk_root=$rknpu_ddk"
        device_list={"${device_list[@]}" "rockchip_npu"}
      fi
      if [ $build_imagination_nna -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_imagination_nna=ON --nnadapter_imagination_nna_sdk_root=$imagination_nna_sdk"
        device_list={"${device_list[@]}" "imagination_nna"}
      fi
      if [ $build_amlogic_npu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_amlogic_npu=ON --nnadapter_amlogic_npu_sdk_root=$amlnpu_ddk_linux"
        device_list={"${device_list[@]}" "amlogic_npu"}
      fi
      if [ $build_verisilicon_timvx -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_verisilicon_timvx=ON"
        device_list={"${device_list[@]}" "verisilicon_timvx"}
      fi
      if [ $build_kunlunxin_xtcl -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_kunlunxin_xtcl=ON"
        device_list={"${device_list[@]}" "kunlunxin_xtcl"}
      fi
      if [ $disable_huawei_ascend_npu -eq 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_ascend_npu=ON --nnadapter_huawei_ascend_npu_sdk_root=$ascend_toolkit_aarch64_linux"
        device_list={"huawei_ascend_npu"}
      fi
    elif [ "$arch" = "armv7hf" ]; then
      lib_abi="armhf"
      build_cmd="$build_cmd --with_cv=ON"
      if [ $build_rockchip_npu -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_rockchip_npu=ON --nnadapter_rockchip_npu_sdk_root=$rknpu_ddk"
        device_list={"${device_list[@]}" "rockchip_npu"}
      fi
    elif [ "$arch" = "x86" ]; then
      lib_abi="amd64"
      if [ $build_kunlunxin_xtcl -ne 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_kunlunxin_xtcl=ON"
        device_list={"${device_list[@]}" "kunlunxin_xtcl"}
      fi
      if [ $disable_huawei_ascend_npu -eq 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_ascend_npu=ON --nnadapter_huawei_ascend_npu_sdk_root=$ascend_toolkit_x86_64_linux"
        device_list={"huawei_ascend_npu"}
      fi
    else
      echo "Abi $arch is not supported for $os and any devices."
    fi
    lib_os="armlinux"
  fi
  device_count=${#device_list[@]}
  if [ $device_count -eq 0 ]; then
    return 0
  fi

  lib_dir=$cur_dir/libs/PaddleLite/$os/$lib_abi
  if [ -d "$build_dir" ] && [ $rebuild_all -eq 0 ]; then
    cd $build_dir
    make -j8 publish_inference
    cd $cur_dir
  else
    if [ $tiny_publish -eq 0 ]; then
      build_cmd="$build_cmd full_publish"
    fi
    rm -rf $build_dir
    cd $src_dir
    ./lite/tools/build_${os}.sh ${build_cmd}
    cd $cur_dir
  fi

  lib_name="libpaddle_light_api_shared.so"
  if [ $tiny_publish -eq 0 ]; then
    lib_name="libpaddle_full_api_shared.so"
  fi

  if [ "$arch" = "x86" ]; then
    publish_inference_dir="inference_lite_lib"
  else
    publish_inference_dir="inference_lite_lib.$lib_os.$arch.nnadapter"
  fi

  rm -rf $lib_dir/include/*.h
  cp $build_dir/$publish_inference_dir/cxx/include/* $lib_dir/include/
  rm -rf $lib_dir/lib/${lib_name}
  cp $build_dir/$publish_inference_dir/cxx/lib/${lib_name} $lib_dir/lib/

  for device_name in ${device_list[@]}
  do
    echo $device_name
    rm -rf $lib_dir/lib/$device_name/libnnadapter*.so
    cp $build_dir/lite/backends/nnadapter/nnadapter/libnnadapter.so $lib_dir/lib/$device_name/
    cp $build_dir/lite/backends/nnadapter/nnadapter/driver/${device_name}/*.so $lib_dir/lib/$device_name/
  done

  echo "done"
}

# Build Paddle Lite and NNAdapter runtime and HAL libraries for the supported
export LIT_BUILD_THREAD=8

# hardware on tiny_publish and full_publish mode
# os: android, linux
# arch: armv7, armv8, armv7hf, x86
# toolchain: gcc, clang
# rebuild_all: 0, 1
# tiny_publish: 0, 1
# disable_huawei_ascend_npu: 0, 1

#=:<<!
# Android arm64-v8a: HuaweiKirinNPU
echo "1/14"
build_and_update_lib android armv8 clang 1 0 1
echo "2/14"
build_and_update_lib android armv8 clang 1 1 1
# Android armeabi-v7a: HuaweiKirinNPU, MediaTekAPU, AmlogicNPU, TIM-VX
echo "3/14"
build_and_update_lib android armv7 clang 1 0 1
echo "4/14"
build_and_update_lib android armv7 clang 1 1 1
# Linux amd64: KunlunxinXTCL/x86
echo "5/14"
build_and_update_lib linux x86 gcc 1 0 1
echo "6/14"
build_and_update_lib linux x86 gcc 1 1 1
# Linux arm64: RockchipNPU, AmlogicNPU, ImaginationNNA, TIM-VX, KunlunxinXTCL
echo "7/14"
build_and_update_lib linux armv8 gcc 1 0 1
echo "8/14"
build_and_update_lib linux armv8 gcc 1 1 1
# Linux armhf: RockchipNPU
echo "9/14"
build_and_update_lib linux armv7hf gcc 1 0 1
echo "10/14"
build_and_update_lib linux armv7hf gcc 1 1 1
if [[ $build_huawei_ascend_npu -ne 0 ]]; then
    # Linux amd64: HuaweiAscendNPU/x86
    echo "11/14"
    build_and_update_lib linux x86 gcc 1 0 0
    echo "12/14"
    build_and_update_lib linux x86 gcc 1 1 0
    # Linux arm64: HuaweiAscendNPU/aarch64
    echo "13/14"
    build_and_update_lib linux armv8 gcc 1 0 0
    echo "14/14"
    build_and_update_lib linux armv8 gcc 1 1 0
fi
#!

echo "all done."
