#!/bin/bash
set -e

# User config
# Set it to empty if you do not want to test on the specified hardware
# Huawei Kirin NPU
huawei_kirin_npu_device_list=UQG0220A15000356
# Mediatek APU
mediatek_apu_device_list=0123456789ABCDEF
# Rockchip NPU
rockchip_npu_rk1808evb_device_list=a133d8abb26137b2
rockchip_npu_tb_rk1808s0_device_list="192.168.182.8 22 toybrick toybrick"
rockchip_npu_rv1109_device_list="192.168.100.13 22 root rockchip"
# Amlogic NPU
amlogic_npu_device_list="192.168.100.244 22 root 123456"
# Imagination NNA
imagination_nna_device_list="192.168.100.10 22 img imgroc1"
# Huawei Ascend NPU
huawei_ascend_npu_arm64_device_list="localhost 9022 root root"
huawei_ascend_npu_amd64_device_list="localhost 9022 root root"
# Verisilicon TIM-VX
verisilicon_timvx_armlinux_device_list="c8631471d5cd"
verisilicon_timvx_armlinux_device_list="192.168.100.30 22 khadas khadas"
# Kunlunxin XTCL
kunlunxin_xtcl_arm64_device_list="localhost 9022 root root"
kunlunxin_xtcl_amd64_device_list="localhost 9022 root root"
# Cambricon MLU
cambricon_mlu_amd64_device_list="localhost 9022 root root"
# Android NNAPI
android_nnapi_device_list=UQG0220A15000356

readlinkf() {
  perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}
root_dir=$(readlinkf $(pwd)/../../)

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
  local demo_dir=$root_dir/$1
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
  local name="image_classification_demo"
  echo "build and run $name"
  cd $root_dir/$name/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  if [ -n "$huawei_kirin_npu_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  fi
  if [ -n "$android_nnapi_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi android_nnapi "$android_nnapi_device_list"
  fi
  # android armeabi-v7a
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  if [ -n "$huawei_kirin_npu_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  fi
  if [ -n "$mediatek_apu_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_int8_224_per_channel:resnet50_int8_224_per_layer $os $abi mediatek_apu "$mediatek_apu_device_list"
  fi
  if [ -n "$verisilicon_timvx_android_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_fp32_224:resnet50_int8_224_per_layer:resnet50_fp32_224 $os $abi verisilicon_timvx "$verisilicon_timvx_android_device_list"
  fi
  if [ -n "$android_nnapi_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi android_nnapi "$android_nnapi_device_list"
  fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  if [ -n "$rockchip_npu_rk1808evb_device_list" ]; then
    run_demo ./run_with_adb.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi rockchip_npu "$rockchip_npu_rk1808evb_device_list"
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi rockchip_npu "$rockchip_npu_tb_rk1808s0_device_list"
  fi
  if [ -n "$amlogic_npu_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi amlogic_npu "$amlogic_npu_device_list"
  fi
  if [ -n "$imagination_nna_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer $os $abi imagination_nna "$imagination_nna_device_list"
  fi
  if [ -n "$huawei_ascend_npu_arm64_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_ascend_npu "$huawei_ascend_npu_arm64_device_list"
  fi
  if [ -n "$verisilicon_timvx_armlinux_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:mobilenet_v1_fp32_224:resnet50_int8_224_per_layer:resnet50_fp32_224 $os $abi verisilicon_timvx "$verisilicon_timvx_armlinux_device_list"
  fi
  if [ -n "$kunlunxin_xtcl_arm64_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_arm64_device_list"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  if [ -n "$rockchip_npu_rv1109_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer:resnet50_int8_224_per_layer $os $abi rockchip_npu "$rockchip_npu_rv1109_device_list"
  fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ -n "$huawei_ascend_npu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi huawei_ascend_npu "$huawei_ascend_npu_amd64_device_list"
  fi
  if [ -n "$kunlunxin_xtcl_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_amd64_device_list"
  fi
  if [ -n "$cambricon_mlu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh mobilenet_v1_fp32_224:resnet50_fp32_224 $os $abi cambricon_mlu "$cambricon_mlu_amd64_device_list"
  fi
  echo "done"
}

build_and_run_ssd_detection_demo() {
  local test_name="ssd_detection_demo"
  echo "build and run $test_name"
  cd $root_dir/$test_name/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  if [ -n "$huawei_kirin_npu_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  fi
  if [ -n "$android_nnapi_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi android_nnapi "$android_nnapi_device_list"
  fi
  # android armeabi-v7a
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  if [ -n "$huawei_kirin_npu_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  fi
  if [ -n "$mediatek_apu_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi mediatek_apu "$mediatek_apu_device_list"
  fi
  if [ -n "$verisilicon_timvx_android_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer:ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi verisilicon_timvx "$verisilicon_timvx_android_device_list"
  fi
  if [ -n "$android_nnapi_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi android_nnapi "$android_nnapi_device_list"
  fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  if [ -n "$rockchip_npu_rk1808evb_device_list" ]; then
    run_demo ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi rockchip_npu "$rockchip_npu_rk1808evb_device_list"
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi rockchip_npu "$rockchip_npu_tb_rk1808s0_device_list"
  fi
  if [ -n "$amlogic_npu_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi amlogic_npu "$amlogic_npu_device_list"
  fi
  #if [ -n "$imagination_nna_device_list" ]; then
    # run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi imagination_nna "$imagination_nna_device_list"
  #fi
  if [ -n "$huawei_ascend_npu_arm64_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_ascend_npu "$huawei_ascend_npu_arm64_device_list"
  fi
  if [ -n "$verisilicon_timvx_armlinux_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer:ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi verisilicon_timvx "$verisilicon_timvx_armlinux_device_list"
  fi
  if [ -n "$kunlunxin_xtcl_arm64_device_list" ]; then
     run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_arm64_device_list"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  if [ -n "$rockchip_npu_rv1109_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer $os $abi rockchip_npu "$rockchip_npu_rv1109_device_list"
  fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ -n "$huawei_ascend_npu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi huawei_ascend_npu "$huawei_ascend_npu_amd64_device_list"
  fi
  if [ -n "$kunlunxin_xtcl_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_amd64_device_list"
  fi
  #if [ -n "$cambricon_mlu_amd64_device_list" ]; then
    # run_demo ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 $os $abi cambricon_mlu "$cambricon_mlu_amd64_device_list"
  #fi
  echo "done"
}

build_and_run_yolo_detection_demo() {
  local test_name="yolo_detection_demo"
  echo "build and run $test_name"
  cd $root_dir/$test_name/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  #if [ -n "$huawei_kirin_npu_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  #fi
  #if [ -n "$android_nnapi_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_int8_608_per_channel:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi android_nnapi "$android_nnapi_device_list"
  #fi
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  #if [ -n "$huawei_kirin_npu_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  #fi
  #if [ -n "$mediatek_apu_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_int8_608_per_channel $os $abi mediatek_apu "$mediatek_apu_device_list"
  #fi
  #if [ -n "$verisilicon_timvx_android_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi verisilicon_timvx "$verisilicon_timvx_android_device_list"
  #fi
  #if [ -n "$android_nnapi_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_int8_608_per_channel:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi android_nnapi "$android_nnapi_device_list"
  #fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  #if [ -n "$rockchip_npu_rk1808evb_device_list" ]; then
    # run_demo ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi rockchip_npu "$rockchip_npu_rk1808evb_device_list"
  #fi
  #if [ -n "$rockchip_npu_tb_rk1808s0_device_list" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi rockchip_npu "$rockchip_npu_tb_rk1808s0_device_list"
  #fi
  #if [ -n "$amlogic_npu_device_list" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi amlogic_npu "$amlogic_npu_device_list"
  #fi
  #if [ -n "$imagination_nna_device_list" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi imagination_nna "$imagination_nna_device_list"
  #fi
  if [ -n "$huawei_ascend_npu_arm64_device_list" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_ascend_npu "$huawei_ascend_npu_arm64_device_list"
  fi
  #if [ -n "$verisilicon_timvx_armlinux_device_list" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer:yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi verisilicon_timvx "$verisilicon_timvx_armlinux_device_list"
  #fi
  #if [ -n "$kunlunxin_xtcl_arm64_device_list" ]; then
     # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_arm64_device_list"
  #fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  #if [ -n "$rockchip_npu_rv1109_device_list" ]; then
    # run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer $os $abi rockchip_npu "$rockchip_npu_rv1109_device_list"
  #fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ -n "$huawei_ascend_npu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi huawei_ascend_npu "$huawei_ascend_npu_amd64_device_list"
  fi
  if [ -n "$kunlunxin_xtcl_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_amd64_device_list"
  fi
  if [ -n "$cambricon_mlu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 $os $abi cambricon_mlu "$cambricon_mlu_amd64_device_list"
  fi
  echo "done"
}

build_and_run_model_test() {
  local test_name="model_test"
  echo "build and run $test_name"
  cd $root_dir/$test_name/shell
  # android arm64-v8a
  local os=android
  local abi=arm64-v8a
  ./build.sh $os $abi
  if [ -n "$huawei_kirin_npu_device_list" ]; then
    run_demo ./run_with_adb.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  fi
  if [ -n "$android_nnapi_device_list" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi android_nnapi "$android_nnapi_device_list"
  fi
  # android armeabi-v7a
  os=android
  abi=armeabi-v7a
  ./build.sh $os $abi
  if [ -n "$huawei_kirin_npu_device_list" ]; then
    run_demo ./run_with_adb.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_kirin_npu "$huawei_kirin_npu_device_list"
  fi
  if [ -n "$mediatek_apu_device_list" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32 $os $abi mediatek_apu "$mediatek_apu_device_list"
  fi
  if [ -n "$verisilicon_timvx_android_device_list" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi verisilicon_timvx "$verisilicon_timvx_android_device_list"
  fi
  if [ -n "$android_nnapi_device_list" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_int8_per_channel#0#1,3,224,224#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi android_nnapi "$android_nnapi_device_list"
  fi
  # linux arm64
  os=linux
  abi=arm64
  ./build.sh $os $abi
  if [ -n "$rockchip_npu_rk1808evb_device_list" ]; then
    run_demo ./run_with_adb.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi rockchip_npu "$rockchip_npu_rk1808evb_device_list"
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi rockchip_npu "$rockchip_npu_tb_rk1808s0_device_list"
  fi
  if [ -n "$amlogic_npu_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi amlogic_npu "$amlogic_npu_device_list"
  fi
  if [ -n "$imagination_nna_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi imagination_nna "$imagination_nna_device_list"
  fi
  if [ -n "$huawei_ascend_npu_arm64_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_ascend_npu "$huawei_ascend_npu_arm64_device_list"
  fi
  if [ -n "$verisilicon_timvx_armlinux_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32:conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi verisilicon_timvx "$verisilicon_timvx_armlinux_device_list"
  fi
  if [ -n "$kunlunxin_arm64_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi kunlunxin_xtcl "$kunlunxin_arm64_device_list"
  fi
  # linux armhf
  os=linux
  abi=armhf
  ./build.sh $os $abi
  if [ -n "$rockchip_npu_rv1109_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_add_144_192_int8_per_layer#0#1,3,192,144#float32#float32 $os $abi rockchip_npu "$rockchip_npu_rv1109_device_list"
  fi
  # linux amd64
  os=linux
  abi=amd64
  ./build.sh $os $abi
  if [ -n "$huawei_ascend_npu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi huawei_ascend_npu "$huawei_ascend_npu_amd64_device_list"
  fi
  if [ -n "$kunlunxin_xtcl_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi kunlunxin_xtcl "$kunlunxin_xtcl_amd64_device_list"
  fi
  if [ -n "$cambricon_mlu_amd64_device_list" ]; then
    run_demo ./run_with_ssh.sh conv_bn_relu_224_fp32#0#1,3,224,224#float32#float32 $os $abi cambricon_mlu "$cambricon_mlu_amd64_device_list"
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
