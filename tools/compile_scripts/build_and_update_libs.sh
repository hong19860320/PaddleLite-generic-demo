#!/bin/bash
set -e

source settings.sh

build_and_update_lib() {
  local os=$1
  local arch=$2
  local toolchain=$3
  local rebuild_all=$4
  local tiny_publish=$5
  local only_huawei_ascend_npu=$6
  local only_xpu=$7
  local only_opencl=$8

  # Don't compiling OpenCL and XPU at the same time!
  if [ $only_xpu -ne 0 ] && [ $only_opencl -ne 0 ]; then
    echo "Not supported!"
    return -1
  fi

  # Build options
  build_cmd="--arch=$arch --toolchain=$toolchain --with_extra=ON --with_exception=ON"
  extra_args="--with_nnadapter=ON --nnadapter_with_fake_device=ON"
  device_list=( "builtin_device" "fake_device" )
  if [ "$os" = "android" ]; then
    # Android
    build_cmd="$build_cmd --android_stl=c++_shared --with_cv=ON"
    if [ "$arch" = "armv8" ]; then
      lib_abi="arm64-v8a"
      if [ "$ENABLE_BUILD_HUAWEI_KIRIN_NPU" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_huawei_kirin_npu=ON --nnadapter_huawei_kirin_npu_sdk_root=$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_SDK_ROOT"
        device_list=( "${device_list[@]}" "huawei_kirin_npu" )
      fi
      if [ "$ENABLE_BUILD_ANDROID_NNAPI" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_android_nnapi=ON"
        device_list=( "${device_list[@]}" "android_nnapi" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      if [ "$ENABLE_BUILD_QUALCOMM_QNN" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_qualcomm_qnn=ON --nnadapter_qualcomm_qnn_sdk_root=$QUALCOMM_QNN_SDK_ROOT --nnadapter_qualcomm_hexagon_sdk_root=$QUALCOMM_HEXAGON_SDK_ROOT"
        device_list=( "${device_list[@]}" "qualcomm_qnn" )
      fi
      if [ "$ENABLE_BUILD_OPENCL" == "1" ] && [ $only_opencl -ne 0 ]; then
        extra_args="--with_opencl=ON"
        device_list=( "opencl" )
      fi
    elif [ "$arch" = "armv7" ]; then
      lib_abi="armeabi-v7a"
      if [ "$ENABLE_BUILD_HUAWEI_KIRIN_NPU" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_huawei_kirin_npu=ON --nnadapter_huawei_kirin_npu_sdk_root=$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_SDK_ROOT"
        device_list=( "${device_list[@]}" "huawei_kirin_npu" )
      fi
      if [ "$ENABLE_BUILD_MEDIATEK_APU" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_mediatek_apu=ON --nnadapter_mediatek_apu_sdk_root=$MEDIATEK_APU_ANDROID_ARMEABI_V7A_SDK_ROOT"
        device_list=( "${device_list[@]}" "mediatek_apu" )
      fi
      if [ "$ENABLE_BUILD_VERISILICON_TIMVX" == "1" ]; then
        extra_args="$extra_args --with_arm_dotprod=OFF --nnadapter_with_verisilicon_timvx=ON --nnadapter_verisilicon_timvx_src_git_tag=$VERISILICON_TIMVX_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "verisilicon_timvx" )
      fi
      if [ "$ENABLE_BUILD_ANDROID_NNAPI" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_android_nnapi=ON"
        device_list=( "${device_list[@]}" "android_nnapi" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      # QNN 2.5 or later no longer supports android armeabi-v7a
      #if [ "$ENABLE_BUILD_QUALCOMM_QNN" == "1" ]; then
      #  extra_args="$extra_args --nnadapter_with_qualcomm_qnn=ON --nnadapter_qualcomm_qnn_sdk_root=$QUALCOMM_QNN_SDK_ROOT --nnadapter_qualcomm_hexagon_sdk_root=$QUALCOMM_HEXAGON_SDK_ROOT"
      #  device_list=( "${device_list[@]}" "qualcomm_qnn" )
      #fi
      if [ "$ENABLE_BUILD_OPENCL" == "1" ] && [ $only_opencl -ne 0 ]; then
        extra_args="--with_opencl=ON"
        device_list=( "opencl" )
      fi
    else
      echo "Abi $arch is not supported for $os and any devices."
      return -1
    fi
    lib_os="android"
  elif [ "$os" = "linux" ]; then
    # linux
    if [ "$arch" = "armv8" ]; then
      lib_abi="arm64"
      build_cmd="$build_cmd --with_cv=ON"
      if [ "$ENABLE_BUILD_IMAGINATION_NNA" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_imagination_nna=ON --nnadapter_imagination_nna_sdk_root=$IMAGINATION_NNA_LINUX_ARM64_SDK_ROOT"
        device_list=( "${device_list[@]}" "imagination_nna" )
      fi
      if [ "$ENABLE_BUILD_VERISILICON_TIMVX" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_verisilicon_timvx=ON --nnadapter_verisilicon_timvx_src_git_tag=$VERISILICON_TIMVX_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "verisilicon_timvx" )
      fi
      if [ "$ENABLE_BUILD_KUNLUNXIN_XTCL" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_kunlunxin_xtcl=ON --nnadapter_kunlunxin_xtcl_sdk_url=$KUNLUNXIN_XTCL_SDK_URL"
        device_list=( "${device_list[@]}" "kunlunxin_xtcl" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      if [ "$ENABLE_BUILD_HUAWEI_ASCEND_NPU" == "1" ] && [ $only_huawei_ascend_npu -ne 0 ]; then
        extra_args="$extra_args --nnadapter_with_huawei_ascend_npu=ON --nnadapter_huawei_ascend_npu_sdk_root=$HUAWEI_ASCEND_NPU_LINUX_ARM64_SDK_ROOT"
        device_list=( "huawei_ascend_npu" )
      fi
      if [ "$ENABLE_BUILD_XPU" == "1" ] && [ $only_xpu -ne 0 ]; then
        extra_args="--with_kunlunxin_xpu=ON --kunlunxin_xpu_sdk_url=$XPU_SDK_URL"
        device_list=( "xpu" )
      fi
      if [ "$ENABLE_BUILD_OPENCL" == "1" ] && [ $only_opencl -ne 0 ]; then
        extra_args="--with_opencl=ON"
        device_list=( "opencl" )
      fi
    elif [ "$arch" = "armv7hf" ]; then
      lib_abi="armhf"
      build_cmd="$build_cmd --with_cv=ON"
      if [ "$ENABLE_BUILD_VERISILICON_TIMVX" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_verisilicon_timvx=ON --nnadapter_verisilicon_timvx_src_git_tag=$VERISILICON_TIMVX_SRC_GIT_TAG --nnadapter_verisilicon_timvx_viv_sdk_url=$VERISILICON_TIMVX_LINUX_ARM32_6435"
        device_list=( "${device_list[@]}" "verisilicon_timvx" )
      fi
      if [ "$ENABLE_BUILD_EEASYTECH_NPU" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_eeasytech_npu=ON --nnadapter_eeasytech_npu_sdk_root=$EEASYTECH_NPU_LINUX_ARMHF_SDK_ROOT"
        device_list=( "${device_list[@]}" "eeasytech_npu" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      if [ "$ENABLE_BUILD_OPENCL" == "1" ] && [ $only_opencl -ne 0 ]; then
        extra_args="--with_opencl=ON"
        device_list=( "opencl" )
      fi
    elif [ "$arch" = "x86" ]; then
      lib_abi="amd64"
      if [ "$ENABLE_BUILD_KUNLUNXIN_XTCL" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_kunlunxin_xtcl=ON --nnadapter_kunlunxin_xtcl_sdk_url=$KUNLUNXIN_XTCL_SDK_URL"
        device_list=( "${device_list[@]}" "kunlunxin_xtcl" )
      fi
      if [ "$ENABLE_BUILD_CAMBRICON_MLU" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_cambricon_mlu=ON --nnadapter_cambricon_mlu_sdk_root=$CAMBRICON_MLU_LINUX_AMD64_SDK_ROOT"
        device_list=( "${device_list[@]}" "cambricon_mlu" )
      fi
      if [ "$ENABLE_BUILD_GOOGLE_XNNPACK" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_google_xnnpack=ON --nnadapter_google_xnnpack_src_git_tag=$GOOGLE_XNNPACK_SRC_GIT_TAG"
        device_list=( "${device_list[@]}" "google_xnnpack" )
      fi
      if [ "$ENABLE_BUILD_NVIDIA_TENSORRT" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_nvidia_tensorrt=ON --nnadapter_nvidia_cuda_root=$NVIDIA_TENSORRT_LINUX_AMD64_CUDA_ROOT --nnadapter_nvidia_tensorrt_root=$NVIDIA_TENSORRT_LINUX_AMD64_TENSORRT_ROOT"
        device_list=( "${device_list[@]}" "nvidia_tensorrt" )
      fi
      if [ "$ENABLE_BUILD_INTEL_OPENVINO" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_intel_openvino=ON --nnadapter_intel_openvino_sdk_root=$INTEL_OPENVINO_LINUX_AMD64_SDK_ROOT"
        device_list=( "${device_list[@]}" "intel_openvino" )
      fi
      if [ "$ENABLE_BUILD_QUALCOMM_QNN" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_qualcomm_qnn=ON --nnadapter_qualcomm_qnn_sdk_root=$QUALCOMM_QNN_SDK_ROOT --nnadapter_qualcomm_hexagon_sdk_root=$QUALCOMM_HEXAGON_SDK_ROOT"
        device_list=( "${device_list[@]}" "qualcomm_qnn" )
      fi
      if [ "$ENABLE_BUILD_HUAWEI_ASCEND_NPU" == "1" ] && [ $only_huawei_ascend_npu -ne 0 ]; then
        extra_args="$extra_args --nnadapter_with_huawei_ascend_npu=ON --nnadapter_huawei_ascend_npu_sdk_root=$HUAWEI_ASCEND_NPU_LINUX_AMD64_SDK_ROOT"
        device_list=( "huawei_ascend_npu" )
      fi
      if [ "$ENABLE_BUILD_XPU" == "1" ] && [ $only_xpu -ne 0 ]; then
        extra_args="--with_kunlunxin_xpu=ON --kunlunxin_xpu_sdk_url=$XPU_SDK_URL"
        device_list=( "xpu" )
      fi
      if [ "$ENABLE_BUILD_OPENCL" == "1" ] && [ $only_opencl -ne 0 ]; then
        extra_args="--with_opencl=ON"
        device_list=( "opencl" )
      fi
    else
      echo "Abi $arch is not supported for $os and any devices."
      return -1
    fi
    lib_os="armlinux"
  else
    # qnx
    if [ "$arch" = "armv8" ]; then
      lib_abi="arm64"
      build_cmd="$build_cmd --with_cv=ON"
      if [ "$ENABLE_BUILD_QUALCOMM_QNN" == "1" ]; then
        extra_args="$extra_args --nnadapter_with_qualcomm_qnn=ON --nnadapter_qualcomm_qnn_sdk_root=$QUALCOMM_QNN_SDK_ROOT --nnadapter_qualcomm_hexagon_sdk_root=$QUALCOMM_HEXAGON_SDK_ROOT"
        device_list=( "${device_list[@]}" "qualcomm_qnn" )
      fi
    else
      echo "Abi $arch is not supported for $os and any devices."
      return -1
    fi
    lib_os="qnx"
  fi
  device_count=${#device_list[@]}
  if [ $device_count -eq 0 ]; then
    return 0
  fi

  build_dir=$LITE_DIR/build.lite.$os.$arch.$toolchain
  if [ $only_xpu -ne 0 ]; then
    build_dir=$LITE_DIR/build.lite.$os.$arch.$toolchain.kunlunxin_xpu
  fi
  if [ $only_opencl -ne 0 ]; then
    if [ "$os" == "linux" ]; then
      build_dir=$LITE_DIR/build.lite.$os.$arch.$toolchain.opencl
    fi
  fi
  lib_root=$ROOT_DIR/libs/PaddleLite
  lib_dir=$lib_root/$os/$lib_abi
  if [ -d "$build_dir" ] && [ $rebuild_all -eq 0 ]; then
    cd $build_dir
    make -j8 publish_inference
  else
    build_cmd="$build_cmd $extra_args"
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
    if [ $only_xpu -ne 0 ]; then
      if [ "$os" == "linux" ] && [ "$arch" == "armv8" ]; then
        publish_inference_dir="inference_lite_lib.armlinux.armv8.xpu"
      else
        echo "Not supported!"
        return -1
      fi
    fi
    if [ $only_opencl -ne 0 ]; then
      if [ "$os" == "android" ]; then
        publish_inference_dir="inference_lite_lib.android.$arch.opencl"
      elif [ "$os" == "linux" ]; then
        publish_inference_dir="inference_lite_lib.armlinux.$arch.opencl"
      else
        echo "Not supported!"
        return -1
      fi
    fi
  fi

  rm -rf $lib_dir/include/*.h
  cp -rf $build_dir/$publish_inference_dir/cxx/include/paddle_api.h $lib_dir/include/
  cp -rf $build_dir/$publish_inference_dir/cxx/include/paddle_place.h $lib_dir/include/
  if [ "$arch" = "armv8" ] || [ "$arch" = "armv7" ] || [ "$arch" = "armv7hf" ]; then
    cp -rf $build_dir/$publish_inference_dir/cxx/include/paddle_image_preprocess.h $lib_dir/include/
  fi

  for device_name in ${device_list[@]}
  do
    echo $device_name
    mkdir -p $lib_dir/lib/$device_name
    if [ "$device_name" == "opencl" ] || [ "$device_name" == "xpu" ] ; then
      rm -rf $lib_dir/lib/$device_name/$lib_name
      cp -rf $build_dir/$publish_inference_dir/cxx/lib/$lib_name $lib_dir/lib/$device_name
      if [ "$device_name" == "xpu" ] ; then
        cp -rf $build_dir/$publish_inference_dir/third_party/xpu/xdnn/so/*.so* $lib_dir/lib/$device_name
        cp -rf $build_dir/$publish_inference_dir/third_party/xpu/xre/so/*.so* $lib_dir/lib/$device_name
      fi
    else
      rm -rf $lib_dir/lib/$lib_name
      cp $build_dir/$publish_inference_dir/cxx/lib/$lib_name $lib_dir/lib/
      if [ "$device_name" == "builtin_device" ]; then
        rm -rf $lib_dir/lib/builtin_device/include
        mkdir -p $lib_dir/lib/builtin_device/include
        cp -rf $build_dir/$publish_inference_dir/cxx/include/nnadapter/* $lib_dir/lib/builtin_device/include/
        rm -rf $lib_root/samples/fake_device
        cp -rf $LITE_DIR/lite/backends/nnadapter/nnadapter/src/driver/fake_device $lib_root/samples/
      else
        if [ "$device_name" == "qualcomm_qnn" ]; then
          rm $lib_dir/lib/$device_name/*.so
          if [ "$os" == "android" ] && [ "$arch" == "armv8" ]; then
            cp $QUALCOMM_QNN_SDK_ROOT/target/aarch64-android/lib/*.so $lib_dir/lib/$device_name/
          elif [ "$os" == "android" ] && [ "$arch" == "armv7" ]; then
            cp $QUALCOMM_QNN_SDK_ROOT/target/arm-android/lib/*.so $lib_dir/lib/$device_name/
          elif [ "$os" == "linux" ] && [ "$arch" == "x86" ]; then
            cp $QUALCOMM_QNN_SDK_ROOT/target/x86_64-linux-clang/lib/*.so $lib_dir/lib/$device_name/
          elif [ "$os" == "qnx" ] && [ "$arch" == "armv8" ]; then
            cp $QUALCOMM_QNN_SDK_ROOT/target/aarch64-qnx/lib/*.so $lib_dir/lib/$device_name/
          else
            echo "Not supported!"
            return -1
          fi
        fi
        cp $build_dir/lite/backends/nnadapter/nnadapter/src/driver/$device_name/*.so* $lib_dir/lib/$device_name/
      fi
      rm -rf $lib_dir/lib/$device_name/libnnadapter*.so
      cp $build_dir/lite/backends/nnadapter/nnadapter/src/libnnadapter.so $lib_dir/lib/$device_name/
    fi
  done

  echo "Done"
}

# Build Paddle Lite and NNAdapter runtime and HAL libraries for the supported
export LIT_BUILD_THREAD=8

# full_publish mode ? or tiny_publish mode ?
# os: android, linux
# arch: armv7, armv8, armv7hf, x86
# toolchain: gcc, clang
# rebuild_all: 0, 1
# tiny_publish: 0, 1
# only_huawei_ascend_npu: 0, 1
# only_xpu: 0, 1
# only_opencl: 0, 1

#:<<!
# Huawei Ascend NPU only
if [ "$ENABLE_BUILD_HUAWEI_ASCEND_NPU" == "1" ]; then
  # Linux amd64
  echo "Build #1"
  build_and_update_lib linux x86 gcc 1 0 1 0 0
  echo "Build #2"
  build_and_update_lib linux x86 gcc 1 1 1 0 0
  # Linux arm64
  echo "Build #3"
  build_and_update_lib linux armv8 gcc 1 0 1 0 0
  echo "Build #4"
  build_and_update_lib linux armv8 gcc 1 1 1 0 0
fi

# XPU only
if [ "$ENABLE_BUILD_XPU" == "1" ]; then
  # Linux amd64
  echo "Build #5"
  build_and_update_lib linux x86 gcc 1 0 0 1 0
  echo "Build #6"
  build_and_update_lib linux x86 gcc 1 1 0 1 0
  # Linux arm64
  echo "Build #7"
  build_and_update_lib linux armv8 gcc 1 0 0 1 0
  echo "Build #8"
  build_and_update_lib linux armv8 gcc 1 1 0 1 0
fi

# OpenCL only
if [ "$ENABLE_BUILD_OPENCL" == "1" ]; then
  # Android arm64-v8a
  echo "Build #9"
  build_and_update_lib android armv8 clang 1 0 0 0 1
  echo "Build #10"
  build_and_update_lib android armv8 clang 1 1 0 0 1
  # Android armeabi-v7a
  echo "Build #11"
  build_and_update_lib android armv7 clang 1 0 0 0 1
  echo "Build #12"
  build_and_update_lib android armv7 clang 1 1 0 0 1
  # Linux arm64
  echo "Build #13"
  build_and_update_lib linux armv8 gcc 1 0 0 0 1
  echo "Build #14"
  build_and_update_lib linux armv8 gcc 1 1 0 0 1
  # Linux armhf
  echo "Build #15"
  build_and_update_lib linux armv7hf gcc 1 0 0 0 1
  echo "Build #16"
  build_and_update_lib linux armv7hf gcc 1 1 0 0 1
fi

# Android arm64-v8a
# Huawei Kirin NPU, Android NNAPI, Google XNNPACK, Qualcomm QNN
echo "Build #17"
build_and_update_lib android armv8 clang 1 0 0 0 0
echo "Build #18"
build_and_update_lib android armv8 clang 1 1 0 0 0

# Android armeabi-v7a
# Huawei Kirin NPU, MediaTek APU, Verisilicon TIM-VX, Android NNAPI, Google XNNPACK, Qualcomm QNN
echo "Build #19"
build_and_update_lib android armv7 clang 1 0 0 0 0
echo "Build #20"
build_and_update_lib android armv7 clang 1 1 0 0 0

# Linux amd64
# Kunlunxin XTCL, CambriconMLU, Google XNNPACK, Qualcomm QNN
echo "Build #21"
build_and_update_lib linux x86 gcc 1 0 0 0 0
echo "Build #22"
build_and_update_lib linux x86 gcc 1 1 0 0 0

# Linux arm64
# Imagination NNA, Verisilicon TIM-VX, Kunlunxin XTCL, Google XNNPACK
echo "Build #23"
build_and_update_lib linux armv8 gcc 1 0 0 0 0
echo "Build #24"
build_and_update_lib linux armv8 gcc 1 1 0 0 0

# Linux armhf
# Google XNNPACK
echo "Build #25"
build_and_update_lib linux armv7hf gcc 1 0 0 0 0
echo "Build #26"
build_and_update_lib linux armv7hf gcc 1 1 0 0 0

# QNX arm64
# Qualcomm QNN
echo "Build #27"
build_and_update_lib qnx armv8 gcc 1 0 0 0 0
echo "Build #28"
build_and_update_lib qnx armv8 gcc 1 1 0 0 0
#!

echo "Done."
