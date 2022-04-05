#!/bin/bash
set -e

source settings.sh

run_demo() {
  local cmd=$1
  local model_list=$2
  local os=$3
  local abi=$4
  local device_name=$5
  local device_list=$6
  echo "cmd=$cmd"
  echo "model_list=$model_list"
  echo "os=$os"
  echo "abi=$abi"
  echo "device_name=$device_name"
  echo "device_list=$device_list"
  local model_names=(${model_list//:/ })
  for model_name in ${model_names[@]}; do
    model_name=$(echo $model_name | sed "s/#/ /g")
    echo "Run $model_name on cpu:$os:$abi"
    $cmd $model_name $os $abi cpu $device_list
    echo "Run $model_name on $device_name:$os:$abi"
    $cmd $model_name $os $abi $device_name $device_list
  done
}

clean_demo() {
  local demo_dir=$ROOT_DIR/$1
  echo "clean $demo_dir"
  rm -f $demo_dir/assets/models/*.nb
  rm -f $demo_dir/assets/models/*.nnc
  rm -f $demo_dir/shell/*.nb
  rm -f $demo_dir/shell/*.nnc
  rm -f $demo_dir/shell/*.log
  rm -rf $demo_dir/python/infer/__pycache__
  # CMake files
  rm -f $demo_dir/shell/build.android.armeabi-v7a/CMakeCache.txt
  rm -rf $demo_dir/shell/build.android.armeabi-v7a/CMakeFiles
  rm -f $demo_dir/shell/build.android.armeabi-v7a/Makefile
  rm -f $demo_dir/shell/build.android.armeabi-v7a/cmake_install.cmake
  rm -f $demo_dir/shell/build.android.arm64-v8a/CMakeCache.txt
  rm -rf $demo_dir/shell/build.android.arm64-v8a/CMakeFiles
  rm -f $demo_dir/shell/build.android.arm64-v8a/Makefile
  rm -f $demo_dir/shell/build.android.arm64-v8a/cmake_install.cmake
  rm -f $demo_dir/shell/build.linux.amd64/CMakeCache.txt
  rm -rf $demo_dir/shell/build.linux.amd64/CMakeFiles
  rm -f $demo_dir/shell/build.linux.amd64/Makefile
  rm -f $demo_dir/shell/build.linux.amd64/cmake_install.cmake
  rm -f $demo_dir/shell/build.linux.arm64/CMakeCache.txt
  rm -rf $demo_dir/shell/build.linux.arm64/CMakeFiles
  rm -f $demo_dir/shell/build.linux.arm64/Makefile
  rm -f $demo_dir/shell/build.linux.arm64/cmake_install.cmake
  rm -f $demo_dir/shell/build.linux.armhf/CMakeCache.txt
  rm -rf $demo_dir/shell/build.linux.armhf/CMakeFiles
  rm -f $demo_dir/shell/build.linux.armhf/Makefile
  rm -f $demo_dir/shell/build.linux.armhf/cmake_install.cmake
}

build_and_run_image_classification_demo() {
  echo "build and run image_classification_demo"
  cd $ROOT_DIR/image_classification_demo/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224 $os $abi fake_device,builtin_device "$BUILTIN_DEVICE_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224:resnet50_int8_224_per_layer:resnet50_fp32_224 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  # android armeabi-v7a
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_FAKE_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224 $os $abi fake_device,builtin_device "$BUILTIN_DEVICE_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_MEDIATEK_APU" == "1" ] && [ -n "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:resnet50_int8_224_per_layer $os $abi mediatek_apu "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_fp32_224:resnet50_int8_224_per_layer:resnet50_fp32_224 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224:resnet50_int8_224_per_layer:resnet50_fp32_224 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224 $os $abi fake_device,builtin_device "$BUILTIN_DEVICE_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_AMLOGIC_NPU" == "1" ] && [ -n "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi amlogic_npu "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_IMAGINATION_NNA" == "1" ] && [ -n "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer $os $abi imagination_nna "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_fp32_224:resnet50_int8_224_per_layer:resnet50_fp32_224 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_LINUX_ARMHF_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224 $os $abi fake_device,builtin_device "$BUILTIN_DEVICE_LINUX_ARMHF_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST"
  fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:mobilenet_v1_fp32_224 $os $abi fake_device,builtin_device "$BUILTIN_DEVICE_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_CAMBRICON_MLU" == "1" ] && [ -n "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi cambricon_mlu "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_INTEL_OPENVINO" == "1" ] && [ -n "$INTEL_OPENVINO_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh resnet50_fp32_224 $os $abi intel_openvino "$INTEL_OPENVINO_LINUX_AMD64_DEVICE_LIST"
  fi
  echo "done"
}

build_and_run_ssd_detection_demo() {
  echo "build and run ssd_detection_demo"
  cd $ROOT_DIR/ssd_detection_demo/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer:ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  # android armeabi-v7a
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_MEDIATEK_APU" == "1" ] && [ -n "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi mediatek_apu "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer:ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer:ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_AMLOGIC_NPU" == "1" ] && [ -n "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi amlogic_npu "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  #if [ "$ENABLE_DEMO_IMAGINATION_NNA" == "1" ] && [ -n "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi imagination_nna "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST"
  #fi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer:ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST"
  fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST"
  fi
  #if [ "$ENABLE_DEMO_CAMBRICON_MLU" == "1" ] && [ -n "$CAMBRICON_MUL_LINUX_AMD64_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi cambricon_mlu "$CAMBRICON_MUL_LINUX_AMD64_DEVICE_LIST"
  #fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST"
  fi
  echo "done"
}

build_and_run_yolo_detection_demo() {
  echo "build and run yolo_detection_demo"
  cd $ROOT_DIR/yolo_detection_demo/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  #if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST"
  #fi
  #if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_int8_608_per_channel:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST"
  #fi
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  #if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  #fi
  #if [ "$ENABLE_DEMO_MEDIATEK_APU" == "1" ] && [ -n "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_int8_608_per_channel $os $abi mediatek_apu "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  #fi
  #if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  #fi
  #if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_int8_608_per_channel:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  #fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  #if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST"
  #fi
  #if [ "$ENABLE_DEMO_AMLOGIC_NPU" == "1" ] && [ -n "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi amlogic_npu "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST"
  #fi
  #if ["$ENABLE_DEMO_IMAGINATION_NNA" == "1" ] && [ -n "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi imagination_nna "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST"
  #fi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  #if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST"
  #fi
  #if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST" ]; then
     # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST"
  #fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi nvidia_tensorrt "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  #if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST"
  #fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_CAMBRICON_MLU" == "1" ] && [ -n "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi cambricon_mlu "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST"
  fi
  echo "done"
}

build_and_run_model_test() {
  echo "build and run model_test"
  cd $ROOT_DIR/model_test/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_FAKE_DEVICE" == "1" ] && [ -n "$FAKE_DEVICE_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi fake_device "$FAKE_DEVICE_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi builtin_device "$BUILTIN_DEVICE_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARM64_V8A_DEVICE_LIST"
  fi
  # android armeabi-v7a
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_FAKE_DEVICE" == "1" ] && [ -n "$FAKE_DEVICE_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi fake_device "$FAKE_DEVICE_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi builtin_device "$BUILTIN_DEVICE_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_kirin_npu "$HUAWEI_KIRIN_NPU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_MEDIATEK_APU" == "1" ] && [ -n "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32 $os $abi mediatek_apu "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi android_nnapi "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST"
  fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_FAKE_DEVICE" == "1" ] && [ -n "$FAKE_DEVICE_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi fake_device "$FAKE_DEVICE_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi builtin_device "$BUILTIN_DEVICE_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_AMLOGIC_NPU" == "1" ] && [ -n "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi amlogic_npu "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_IMAGINATION_NNA" == "1" ] && [ -n "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi imagination_nna "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi verisilicon_timvx "$VERISILICON_TIMVX_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_ARM64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_ARM64_DEVICE_LIST"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_FAKE_DEVICE" == "1" ] && [ -n "$FAKE_DEVICE_LINUX_ARMHF_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi fake_device "$FAKE_DEVICE_LINUX_ARMHF_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_LINUX_ARMHF_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi builtin_device "$BUILTIN_DEVICE_LINUX_ARMHF_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi rockchip_npu "$ROCKCHIP_NPU_LINUX_ARMHF_DEVICE_LIST"
  fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ "$ENABLE_DEMO_FAKE_DEVICE" == "1" ] && [ -n "$FAKE_DEVICE_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi fake_device "$FAKE_DEVICE_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_BUILTIN_DEVICE" == "1" ] && [ -n "$BUILTIN_DEVICE_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi builtin_device "$BUILTIN_DEVICE_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_ascend_npu "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi kunlunxin_xtcl "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_CAMBRICON_MLU" == "1" ] && [ -n "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi cambricon_mlu "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_NVIDIA_TENSORRT" == "1" ] && [ -n "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi nvidia_tensorrt "$NVIDIA_TENSORRT_LINUX_AMD64_DEVICE_LIST"
  fi
  if [ "$ENABLE_DEMO_INTEL_OPENVINO" == "1" ] && [ -n "$INTEL_OPENVINO_LINUX_AMD64_DEVICE_LIST" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi intel_openvino "$INTEL_OPENVINO_LINUX_AMD64_DEVICE_LIST"
  fi
  echo "done"
}

build_and_run_image_classification_demo
build_and_run_ssd_detection_demo
build_and_run_yolo_detection_demo
build_and_run_model_test

# clean all
clean_demo image_classification_demo
clean_demo ssd_detection_demo
clean_demo yolo_detection_demo
clean_demo model_test

echo "all done."
