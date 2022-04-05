#!/bin/bash
set -e

source settings.sh

build_and_update_lib() {
  local os=$1
  local arch=$2
  local toolchain=$3
  local rebuild_all=$4
  local tiny_publish=$5
  local disable_huawei_ascend_npu=$6

  build_cmd="--arch=$arch --toolchain=$toolchain --with_extra=ON --with_exception=ON --with_nnadapter=ON --nnadapter_with_fake_device=ON"
  build_dir=$LITE_DIR/build.lite.$os.$arch.$toolchain
  device_list=( "builtin_device" "fake_device" )
  if [ "$os" = "android" ]; then
    # android
    build_cmd="$build_cmd --android_stl=c++_shared --with_cv=ON"
    if [ "$arch" = "armv8" ]; then
      lib_abi="arm64-v8a"
      if [ "$ENABLE_BUILD_HUAWEI_KIRIN_NPU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_kirin_npu=ON --nnadapter_huawei_kirin_npu_sdk_root=$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_SDK_ROOT"
        device_list=( "${device_list[@]}" "huawei_kirin_npu" )
      fi
      if [ "$ENABLE_BUILD_ANDROID_NNAPI" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_android_nnapi=ON"
        device_list=( "${device_list[@]}" "android_nnapi" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
    elif [ "$arch" = "armv7" ]; then
      lib_abi="armeabi-v7a"
      if [ "$ENABLE_BUILD_HUAWEI_KIRIN_NPU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_kirin_npu=ON --nnadapter_huawei_kirin_npu_sdk_root=$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_SDK_ROOT"
        device_list=( "${device_list[@]}" "huawei_kirin_npu" )
      fi
      if [ "$ENABLE_BUILD_MEDIATEK_APU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_mediatek_apu=ON --nnadapter_mediatek_apu_sdk_root=$MEDIATEK_APU_ANDROID_ARMEABI_V7A_SDK_ROOT"
        device_list=( "${device_list[@]}" "mediatek_apu" )
      fi
      if [ "$ENABLE_BUILD_AMLOGIC_NPU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_amlogic_npu=ON --nnadapter_amlogic_npu_sdk_root=$AMLOGIC_NPU_ANDROID_ARMEABI_V7A_SDK_ROOT"
        device_list=( "${device_list[@]}" "amlogic_npu" )
      fi
      if [ "$ENABLE_BUILD_VERISILICON_TIMVX" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_verisilicon_timvx=ON --nnadapter_verisilicon_timvx_src_git_tag=$VERISILICON_TIMVX_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "verisilicon_timvx" )
      fi
      if [ "$ENABLE_BUILD_ANDROID_NNAPI" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_android_nnapi=ON"
        device_list=( "${device_list[@]}" "android_nnapi" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
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
      if [ "$ENABLE_BUILD_ROCKCHIP_NPU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_rockchip_npu=ON --nnadapter_rockchip_npu_sdk_root=$ROCKCHIP_NPU_LINUX_ARM64_SDK_ROOT"
        device_list=( "${device_list[@]}" "rockchip_npu" )
      fi
      if [ "$ENABLE_BUILD_IMAGINATION_NNA" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_imagination_nna=ON --nnadapter_imagination_nna_sdk_root=$IMAGINATION_NNA_LINUX_ARM64_SDK_ROOT"
        device_list=( "${device_list[@]}" "imagination_nna" )
      fi
      if [ "$ENABLE_BUILD_AMLOGIC_NPU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_amlogic_npu=ON --nnadapter_amlogic_npu_sdk_root=$AMLOGIC_NPU_LINUX_ARM64_SDK_ROOT"
        device_list=( "${device_list[@]}" "amlogic_npu" )
      fi
      if [ "$ENABLE_BUILD_VERISILICON_TIMVX" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_verisilicon_timvx=ON --nnadapter_verisilicon_timvx_src_git_tag=$VERISILICON_TIMVX_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "verisilicon_timvx" )
      fi
      if [ "$ENABLE_BUILD_KUNLUNXIN_XTCL" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_kunlunxin_xtcl=ON --nnadapter_kunlunxin_xtcl_sdk_url=$KUNLUNXIN_XTCL_SDK_URL"
        device_list=( "${device_list[@]}" "kunlunxin_xtcl" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      if [ "$ENABLE_BUILD_NVIDIA_TENSORRT" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_nvidia_tensorrt=ON --nnadapter_nvidia_cuda_root=$NVIDIA_TENSORRT_LINUX_ARM64_CUDA_ROOT --nnadapter_nvidia_tensorrt_root=$NVIDIA_TENSORRT_LINUX_ARM64_TENSORRT_ROOT"
        device_list=( "${device_list[@]}" "nvidia_tensorrt" )
      fi
      if [ "$ENABLE_BUILD_HUAWEI_ASCEND_NPU" == "1" ] && [ $disable_huawei_ascend_npu -eq 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_ascend_npu=ON --nnadapter_huawei_ascend_npu_sdk_root=$HUAWEI_ASCEND_NPU_LINUX_ARM64_SDK_ROOT"
        device_list=( "huawei_ascend_npu" )
      fi
    elif [ "$arch" = "armv7hf" ]; then
      lib_abi="armhf"
      build_cmd="$build_cmd --with_cv=ON"
      if [ "$ENABLE_BUILD_ROCKCHIP_NPU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_rockchip_npu=ON --nnadapter_rockchip_npu_sdk_root=$ROCKCHIP_NPU_LINUX_ARMHF_SDK_ROOT"
        device_list=( "${device_list[@]}" "rockchip_npu" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
    elif [ "$arch" = "x86" ]; then
      lib_abi="amd64"
      if [ "$ENABLE_BUILD_KUNLUNXIN_XTCL" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_kunlunxin_xtcl=ON --nnadapter_kunlunxin_xtcl_sdk_url=$KUNLUNXIN_XTCL_SDK_URL"
        device_list=( "${device_list[@]}" "kunlunxin_xtcl" )
      fi
      if [ "$ENABLE_BUILD_CAMBRICON_MLU" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_cambricon_mlu=ON --nnadapter_cambricon_mlu_sdk_root=$CAMBRICON_MLU_LINUX_AMD64_SDK_ROOT"
        device_list=( "${device_list[@]}" "cambricon_mlu" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      if [ "$ENABLE_BUILD_NVIDIA_TENSORRT" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_nvidia_tensorrt=ON --nnadapter_nvidia_cuda_root=$NVIDIA_TENSORRT_LINUX_AMD64_CUDA_ROOT --nnadapter_nvidia_tensorrt_root=$NVIDIA_TENSORRT_LINUX_AMD64_TENSORRT_ROOT"
        device_list=( "${device_list[@]}" "nvidia_tensorrt" )
      fi
      if [ "$ENABLE_BUILD_INTEL_OPENVINO" == "1" ]; then
        build_cmd="$build_cmd --nnadapter_with_intel_openvino=ON --nnadapter_intel_openvino_sdk_root=$INTEL_OPENVINO_LINUX_AMD64_SDK_ROOT"
        device_list=( "${device_list[@]}" "intel_openvino" )
      fi
      if [ "$ENABLE_BUILD_HUAWEI_ASCEND_NPU" == "1" ] && [ $disable_huawei_ascend_npu -eq 0 ]; then
        build_cmd="$build_cmd --nnadapter_with_huawei_ascend_npu=ON --nnadapter_huawei_ascend_npu_sdk_root=$HUAWEI_ASCEND_NPU_LINUX_AMD64_SDK_ROOT"
        device_list=( "huawei_ascend_npu" )
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

  lib_root=$ROOT_DIR/libs/PaddleLite
  lib_dir=$lib_root/$os/$lib_abi
  if [ -d "$build_dir" ] && [ $rebuild_all -eq 0 ]; then
    cd $build_dir
    make -j8 publish_inference
  else
    if [ $tiny_publish -eq 0 ]; then
      build_cmd="$build_cmd full_publish"
    fi
    rm -rf $build_dir
    cd $LITE_DIR
    ./lite/tools/build_${os}.sh ${build_cmd}
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
  cp -rf $build_dir/$publish_inference_dir/cxx/include/*.h $lib_dir/include/
  rm -rf $lib_dir/lib/${lib_name}
  cp $build_dir/$publish_inference_dir/cxx/lib/${lib_name} $lib_dir/lib/

  for device_name in ${device_list[@]}
  do
    echo $device_name
    mkdir -p $lib_dir/lib/$device_name
    rm -rf $lib_dir/lib/$device_name/libnnadapter*.so
    cp $build_dir/lite/backends/nnadapter/nnadapter/src/libnnadapter.so $lib_dir/lib/$device_name/
    if [ "$device_name" == "builtin_device" ]; then
      rm -rf $lib_dir/lib/$device_name/include
      mkdir -p $lib_dir/lib/$device_name/include
      cp -rf $build_dir/$publish_inference_dir/cxx/include/nnadapter/* $lib_dir/lib/$device_name/include/
      rm -rf $lib_dir/lib/$device_name/samples/fake_device
      cp -rf $LITE_DIR/lite/backends/nnadapter/nnadapter/src/driver/fake_device $lib_root/samples/
    else
      cp $build_dir/lite/backends/nnadapter/nnadapter/src/driver/${device_name}/*.so $lib_dir/lib/$device_name/
    fi
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

#:<<!
# Android arm64-v8a: Huawei Kirin NPU, Android NNAPI, Google XNNPACK
echo "1/14"
build_and_update_lib android armv8 clang 1 0 1
echo "2/14"
build_and_update_lib android armv8 clang 1 1 1
# Android armeabi-v7a: Huawei Kirin NPU, MediaTek APU, Amlogic NPU, Verisilicon TIM-VX, Android NNAPI, Google XNNPACK
echo "3/14"
build_and_update_lib android armv7 clang 1 0 1
echo "4/14"
build_and_update_lib android armv7 clang 1 1 1
# Linux amd64: KunlunxinXTCL/x86, CambriconMLU/x86, Google XNNPACK
echo "5/14"
build_and_update_lib linux x86 gcc 1 0 1
echo "6/14"
build_and_update_lib linux x86 gcc 1 1 1
# Linux arm64: Rockchip NPU, Amlogic NPU, Imagination NNA, Verisilicon TIM-VX, Kunlunxin XTCL, Google XNNPACK
echo "7/14"
build_and_update_lib linux armv8 gcc 1 0 1
echo "8/14"
build_and_update_lib linux armv8 gcc 1 1 1
# Linux armhf: Rockchip NPU, Google XNNPACK
echo "9/14"
build_and_update_lib linux armv7hf gcc 1 0 1
echo "10/14"
build_and_update_lib linux armv7hf gcc 1 1 1
if [ "$ENABLE_BUILD_HUAWEI_ASCEND_NPU" == "1" ]; then
  # Linux amd64: Huawei Ascend NPU / x86
  echo "11/14"
  build_and_update_lib linux x86 gcc 1 0 0
  echo "12/14"
  build_and_update_lib linux x86 gcc 1 1 0
  # Linux arm64: Huawei Ascend NPU / aarch64
  echo "13/14"
  build_and_update_lib linux armv8 gcc 1 0 0
  echo "14/14"
  build_and_update_lib linux armv8 gcc 1 1 0
fi
#!

echo "all done."
