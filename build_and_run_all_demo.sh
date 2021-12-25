#!/bin/bash
set -e

# User config
# Set it to empty if you do not want to test on the specified hardware
# HuaweiKirinNPU
#huawei_kirin_npu_test_device_name=UQG0220A15000356
# MediatekAPU
#mediatek_apu_test_device_name=0123456789ABCDEF
# RockchipNPU
#rockchip_npu_rk1808evb_test_device_name=a133d8abb26137b2
#rockchip_npu_tb_rk1808s0_test_device_name="192.168.180.8 22 toybrick toybrick"
#rockchip_npu_rv1109_test_device_name="192.168.100.13 22 root rockchip"
# AmlogicNPU
#amlogic_npu_test_device_name="192.168.100.244 22 root 123456"
# ImaginationNNA
#imagination_nna_test_device_name="192.168.100.10 22 img imgroc1"
# HuaweiAscendNPU]
#huawei_ascend_npu_arm64_test_device_name="localhost 9022 root root"
#huawei_ascend_npu_amd64_test_device_name="localhost 9022 root root"
# VerisiliconTIMVX
#verisilicon_timvx_armlinux_test_device_name="192.168.100.30 22 khadas khadas"
# KunlunxinXTCL
#kunlunxin_xtcl_arm64_test_device_name="localhost 9023 root root"
#kunlunxin_xtcl_amd64_test_device_name="localhost 9023 root root"

readlinkf() {
  perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}
cur_dir=$(readlinkf $(pwd))

build_and_run_image_classification_demo() {
  local test_name="image_classification_demo"
  echo "build and run $test_name"
  cd $cur_dir/$test_name/shell
  # android arm64-v8a
  ./build.sh android arm64-v8a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 1"
    ./run_with_adb.sh mobilenet_v1_fp32_224 android arm64-v8a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 2"
    ./run_with_adb.sh mobilenet_v1_fp32_224 android arm64-v8a huawei_kirin_npu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 3"
    ./run_with_adb.sh resnet50_fp32_224 android arm64-v8a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 4"
    ./run_with_adb.sh resnet50_fp32_224 android arm64-v8a huawei_kirin_npu $huawei_kirin_npu_test_device_name
  fi
  # android armeabi-v7a
  ./build.sh android armeabi-v7a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 5"
    ./run_with_adb.sh mobilenet_v1_fp32_224 android armeabi-v7a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 6"
    ./run_with_adb.sh mobilenet_v1_fp32_224 android armeabi-v7a huawei_kirin_npu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 7"
    ./run_with_adb.sh resnet50_fp32_224 android armeabi-v7a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 8"
    ./run_with_adb.sh resnet50_fp32_224 android armeabi-v7a huawei_kirin_npu $huawei_kirin_npu_test_device_name
  fi
  if [ -n "$mediatek_apu_test_device_name" ]; then
    echo "Running on device: Xiaodu Tablet X10"
    echo "Perform step $test_name 9"
    #./run_with_adb.sh mobilenet_v1_int8_224_per_layer android armeabi-v7a cpu $mediatek_apu_test_device_name
    echo "Perform step $test_name 10"
    ./run_with_adb.sh mobilenet_v1_int8_224_per_layer android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name
    echo "Perform step $test_name 11"
    #./run_with_adb.sh mobilenet_v1_int8_224_per_channel android armeabi-v7a cpu $mediatek_apu_test_device_name
    echo "Perform step $test_name 12"
    ./run_with_adb.sh mobilenet_v1_int8_224_per_channel android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name
    echo "Perform step $test_name 13"
    #./run_with_adb.sh resnet50_int8_224_per_layer android armeabi-v7a cpu $mediatek_apu_test_device_name
    echo "Perform step $test_name 14"
    ./run_with_adb.sh resnet50_int8_224_per_layer android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name
  fi
  # linux arm64
  ./build.sh linux arm64
  if [ -n "$rockchip_npu_rk1808evb_test_device_name" ]; then
    echo "Running on device: RK1808EVB"
    echo "Perform step $test_name 15"
    ./run_with_adb.sh mobilenet_v1_int8_224_per_layer linux arm64 cpu $rockchip_npu_rk1808evb_test_device_name
    echo "Perform step $test_name 16"
    ./run_with_adb.sh mobilenet_v1_int8_224_per_layer linux arm64 rockchip_npu $rockchip_npu_rk1808evb_test_device_name
    echo "Perform step $test_name 17"
    ./run_with_adb.sh resnet50_int8_224_per_layer linux arm64 cpu $rockchip_npu_rk1808evb_test_device_name
    echo "Perform step $test_name 18"
    ./run_with_adb.sh resnet50_int8_224_per_layer linux arm64 rockchip_npu $rockchip_npu_rk1808evb_test_device_name
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_test_device_name" ]; then
    echo "Running on device: Toybirck TB-RK1808S0"
    echo "Perform step $test_name 19"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 cpu $rockchip_npu_tb_rk1808s0_test_device_name
    echo "Perform step $test_name 20"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 rockchip_npu $rockchip_npu_tb_rk1808s0_test_device_name
    echo "Perform step $test_name 21"
    ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 cpu $rockchip_npu_tb_rk1808s0_test_device_name
    echo "Perform step $test_name 22"
    ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 rockchip_npu $rockchip_npu_tb_rk1808s0_test_device_name
  fi
  if [ -n "$amlogic_npu_test_device_name" ]; then
    echo "Running on device: Amlogic A311D"
    echo "Perform step $test_name 23"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 cpu $amlogic_npu_test_device_name
    echo "Perform step $test_name 24"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 amlogic_npu $amlogic_npu_test_device_name
  fi
  if [ -n "$imagination_nna_test_device_name" ]; then
    echo "Running on device: ROC1"
    echo "Perform step $test_name 25"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 cpu $imagination_nna_test_device_name
    echo "Perform step $test_name 26"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 imagination_nna $imagination_nna_test_device_name
  fi
  if [ -n "$huawei_ascend_npu_arm64_test_device_name" ]; then
    echo "Running on device: Kunpeng 920 + Huawei Atlas 300C(3000)"
    echo "Perform step $test_name 27"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 cpu $huawei_ascend_npu_arm64_test_device_name
    echo "Perform step $test_name 28"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 huawei_ascend_npu $huawei_ascend_npu_arm64_test_device_name
    echo "Perform step $test_name 29"
    ./run_with_ssh.sh resnet50_fp32_224 linux arm64 cpu $huawei_ascend_npu_arm64_test_device_name
    echo "Perform step $test_name 30"
    ./run_with_ssh.sh resnet50_fp32_224 linux arm64 huawei_ascend_npu $huawei_ascend_npu_arm64_test_device_name
  fi
  if [ -n "$verisilicon_timvx_armlinux_test_device_name" ]; then
    echo "Running on device: Khadas VIM3"
    echo "Perform step $test_name 31"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 32"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 33"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 34"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 35"
    ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 36"
    ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 37"
    ./run_with_ssh.sh resnet50_fp32_224 linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 38"
    ./run_with_ssh.sh resnet50_fp32_224 linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
  fi
  if [ -n "$kunlunxin_arm64_test_device_name" ]; then
    echo "Running on device: ARM CPU + Kunlunxin K100"
    echo "Perform step $test_name 39"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 cpu $kunlunxin_arm64_test_device_name
    echo "Perform step $test_name 40"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 kunlunxin_xtcl $kunlunxin_arm64_test_device_name
    echo "Perform step $test_name 41"
    ./run_with_ssh.sh resnet50_fp32_224 linux arm64 cpu $kunlunxin_arm64_test_device_name
    echo "Perform step $test_name 42"
    ./run_with_ssh.sh resnet50_fp32_224 linux arm64 kunlunxin_xtcl $kunlunxin_arm64_test_device_name
  fi
  # linux armhf
  ./build.sh linux armhf
  if [ -n "$rockchip_npu_rv1109_test_device_name" ]; then
    echo "Running on device: Dumu RV1109"
    echo "Perform step $test_name 43"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux armhf cpu $rockchip_npu_rv1109_test_device_name
    echo "Perform step $test_name 44"
    ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux armhf rockchip_npu $rockchip_npu_rv1109_test_device_name
    echo "Perform step $test_name 45"
    ./run_with_ssh.sh resnet50_int8_224_per_layer linux armhf cpu $rockchip_npu_rv1109_test_device_name
    echo "Perform step $test_name 46"
    ./run_with_ssh.sh resnet50_int8_224_per_layer linux armhf rockchip_npu $rockchip_npu_rv1109_test_device_name
  fi
  # linux amd64
  ./build.sh linux amd64
  if [ -n "$huawei_ascend_npu_amd64_test_device_name" ]; then
    echo "Running on device: Intel x86 + Huawei Atlas 300C(3010)"
    echo "Perform step $test_name 47"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 cpu $huawei_ascend_npu_amd64_test_device_name
    echo "Perform step $test_name 48"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 huawei_ascend_npu $huawei_ascend_npu_amd64_test_device_name
    echo "Perform step $test_name 49"
    ./run_with_ssh.sh resnet50_fp32_224 linux amd64 cpu $huawei_ascend_npu_amd64_test_device_name
    echo "Perform step $test_name 50"
    ./run_with_ssh.sh resnet50_fp32_224 linux amd64 huawei_ascend_npu $huawei_ascend_npu_amd64_test_device_name
  fi
  if [ -n "$kunlunxin_xtcl_amd64_test_device_name" ]; then
    echo "Running on device: x86 CPU + Kunlunxin K100"
    echo "Perform step $test_name 51"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 cpu $kunlunxin_xtcl_amd64_test_device_name
    echo "Perform step $test_name 52"
    ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 kunlunxin_xtcl $kunlunxin_xtcl_amd64_test_device_name
    echo "Perform step $test_name 53"
    ./run_with_ssh.sh resnet50_fp32_224 linux amd64 cpu $kunlunxin_xtcl_amd64_test_device_name
    echo "Perform step $test_name 54"
    ./run_with_ssh.sh resnet50_fp32_224 linux amd64 kunlunxin_xtcl $kunlunxin_xtcl_amd64_test_device_name
  fi
  echo "done"
}

build_and_run_ssd_detection_demo() {
  local test_name="ssd_detection_demo"
  echo "build and run $test_name"
  cd $cur_dir/$test_name/shell
  # android arm64-v8a
  ./build.sh android arm64-v8a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 1"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 android arm64-v8a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 2"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 android arm64-v8a huawei_kirin_npu $huawei_kirin_npu_test_device_name
  fi
  # android armeabi-v7a
  ./build.sh android armeabi-v7a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 3"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 android armeabi-v7a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 4"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 android armeabi-v7a huawei_kirin_npu $huawei_kirin_npu_test_device_name
  fi
  if [ -n "$mediatek_apu_test_device_name" ]; then
    echo "Running on device: Xiaodu Tablet X10"
    echo "Perform step $test_name 5"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer android armeabi-v7a cpu $mediatek_apu_test_device_name
    echo "Perform step $test_name 6"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name
  fi
  # linux arm64
  ./build.sh linux arm64
  if [ -n "$rockchip_npu_rk1808evb_test_device_name" ]; then
    echo "Running on device: RK1808EVB"
    echo "Perform step $test_name 7"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 cpu $rockchip_npu_rk1808evb_test_device_name
    echo "Perform step $test_name 8"
    ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 rockchip_npu $rockchip_npu_rk1808evb_test_device_name
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_test_device_name" ]; then
    echo "Running on device: Toybirck TB-RK1808S0"
    echo "Perform step $test_name 9"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 cpu $rockchip_npu_tb_rk1808s0_test_device_name
    echo "Perform step $test_name 10"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 rockchip_npu $rockchip_npu_tb_rk1808s0_test_device_name
  fi
  if [ -n "$amlogic_npu_test_device_name" ]; then
    echo "Running on device: Amlogic A311D"
    echo "Perform step $test_name 11"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 cpu $amlogic_npu_test_device_name
    echo "Perform step $test_name 12"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 amlogic_npu $amlogic_npu_test_device_name
  fi
  if [ -n "$imagination_nna_test_device_name" ]; then
    echo "Running on device: ROC1"
    echo "Perform step $test_name 13"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 cpu $imagination_nna_test_device_name
    echo "Perform step $test_name 14"
    # ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 imagination_nna $imagination_nna_test_device_name (Not support)
  fi
  if [ -n "$huawei_ascend_npu_arm64_test_device_name" ]; then
    echo "Running on device: Kunpeng 920 + Huawei Atlas 300C(3000)"
    echo "Perform step $test_name 15"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 cpu $huawei_ascend_npu_arm64_test_device_name
    echo "Perform step $test_name 16"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 huawei_ascend_npu $huawei_ascend_npu_arm64_test_device_name
  fi
  if [ -n "$verisilicon_timvx_armlinux_test_device_name" ]; then
    echo "Running on device: Khadas VIM3"
    echo "Perform step $test_name 17"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 18"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 19"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 20"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
  fi
  if [ -n "$kunlunxin_arm64_test_device_name" ]; then
    echo "Running on device: ARM CPU + Kunlunxin K100"
    echo "Perform step $test_name 21"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 cpu $kunlunxin_arm64_test_device_name
    echo "Perform step $test_name 22"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 kunlunxin_xtcl $kunlunxin_arm64_test_device_name
  fi
  # linux armhf
  ./build.sh linux armhf
  if [ -n "$rockchip_npu_rv1109_test_device_name" ]; then
    echo "Running on device: Dumu RV1109"
    echo "Perform step $test_name 23"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux armhf cpu $rockchip_npu_rv1109_test_device_name
    echo "Perform step $test_name 24"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux armhf rockchip_npu $rockchip_npu_rv1109_test_device_name
  fi
  # linux amd64
  ./build.sh linux amd64
  if [ -n "$huawei_ascend_npu_amd64_test_device_name" ]; then
    echo "Running on device: Intel x86 + Huawei Atlas 300C(3010)"
    echo "Perform step $test_name 25"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux amd64 cpu $huawei_ascend_npu_amd64_test_device_name
    echo "Perform step $test_name 26"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux amd64 huawei_ascend_npu $huawei_ascend_npu_amd64_test_device_name
  fi
  if [ -n "$kunlunxin_xtcl_amd64_test_device_name" ]; then
    echo "Running on device: x86 CPU + Kunlunxin K100"
    echo "Perform step $test_name 27"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux amd64 cpu $kunlunxin_xtcl_amd64_test_device_name
    echo "Perform step $test_name 28"
    ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux amd64 kunlunxin_xtcl $kunlunxin_xtcl_amd64_test_device_name
  fi
  echo "done"
}

build_and_run_yolo_detection_demo() {
  local test_name="yolo_detection_demo"
  echo "build and run $test_name"
  cd $cur_dir/$test_name/shell
  # android arm64-v8a
  ./build.sh android arm64-v8a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 1"
    ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 android arm64-v8a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 2"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 android arm64-v8a huawei_kirin_npu $huawei_kirin_npu_test_device_name (Not try)
  fi
  # android armeabi-v7a
  ./build.sh android armeabi-v7a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 3"
    ./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 android armeabi-v7a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 4"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_fp32_608 android armeabi-v7a huawei_kirin_npu $huawei_kirin_npu_test_device_name (Not try)
  fi
  if [ -n "$mediatek_apu_test_device_name" ]; then
    echo "Running on device: Xiaodu Tablet X10"
    echo "Perform step $test_name 5"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer android armeabi-v7a cpu $mediatek_apu_test_device_name (Lack of quant model)
    echo "Perform step $test_name 6"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name (Lack of quant model)
    echo "Perform step $test_name 7"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_channel android armeabi-v7a cpu $mediatek_apu_test_device_name (Lack of quant model)
    echo "Perform step $test_name 8"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_channel android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name (Lack of quant model)
  fi
  # linux arm64
  ./build.sh linux arm64
  if [ -n "$rockchip_npu_rk1808evb_test_device_name" ]; then
    echo "Running on device: RK1808EVB"
    echo "Perform step $test_name 9"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 cpu $rockchip_npu_rk1808evb_test_device_name (Lack of quant model)
    echo "Perform step $test_name 10"
    #./run_with_adb.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 rockchip_npu $rockchip_npu_rk1808evb_test_device_name (Lack of quant model)
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_test_device_name" ]; then
    echo "Running on device: Toybirck TB-RK1808S0"
    echo "Perform step $test_name 11"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 cpu $rockchip_npu_tb_rk1808s0_test_device_name (Lack of quant model)
    echo "Perform step $test_name 12"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 rockchip_npu $rockchip_npu_tb_rk1808s0_test_device_name (Lack of quant model)
  fi
  if [ -n "$amlogic_npu_test_device_name" ]; then
    echo "Running on device: Amlogic A311D"
    echo "Perform step $test_name 13"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 cpu $amlogic_npu_test_device_name (Lack of quant model)
    echo "Perform step $test_name 14"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 amlogic_npu $amlogic_npu_test_device_name (Lack of quant model)
  fi
  if [ -n "$imagination_nna_test_device_name" ]; then
    echo "Running on device: ROC1"
    echo "Perform step $test_name 15"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 cpu $imagination_nna_test_device_name (Lack of quant model)
    echo "Perform step $test_name 16"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 imagination_nna $imagination_nna_test_device_name (Lack of quant model)
  fi
  if [ -n "$huawei_ascend_npu_arm64_test_device_name" ]; then
    echo "Running on device: Kunpeng 920 + Huawei Atlas 300C(3000)"
    echo "Perform step $test_name 17"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 cpu $huawei_ascend_npu_arm64_test_device_name
    echo "Perform step $test_name 18"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 huawei_ascend_npu $huawei_ascend_npu_arm64_test_device_name
  fi
  if [ -n "$verisilicon_timvx_armlinux_test_device_name" ]; then
    echo "Running on device: Khadas VIM3"
    echo "Perform step $test_name 19"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name (Lack of quant model)
    echo "Perform step $test_name 20"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name (Lack of quant model)
    echo "Perform step $test_name 21"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 22"
    #./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name (Not support)
  fi
  if [ -n "$kunlunxin_arm64_test_device_name" ]; then
    echo "Running on device: ARM CPU + Kunlunxin K100"
    echo "Perform step $test_name 23"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 cpu $kunlunxin_arm64_test_device_name
    echo "Perform step $test_name 24"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 kunlunxin_xtcl $kunlunxin_arm64_test_device_name
  fi
  # linux armhf
  ./build.sh linux armhf
  if [ -n "$rockchip_npu_rv1109_test_device_name" ]; then
    echo "Running on device: Dumu RV1109"
    echo "Perform step $test_name 25"
    # ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux armhf cpu $rockchip_npu_rv1109_test_device_name (Lack of quant model)
    echo "Perform step $test_name 26"
    # ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_int8_608_per_layer linux armhf rockchip_npu $rockchip_npu_rv1109_test_device_name (Lack of quant model)
  fi
  # linux amd64
  ./build.sh linux amd64
  if [ -n "$huawei_ascend_npu_amd64_test_device_name" ]; then
    echo "Running on device: Intel x86 + Huawei Atlas 300C(3010)"
    echo "Perform step $test_name 27"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 cpu $huawei_ascend_npu_amd64_test_device_name
    echo "Perform step $test_name 28"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 huawei_ascend_npu $huawei_ascend_npu_amd64_test_device_name
  fi
  if [ -n "$kunlunxin_xtcl_amd64_test_device_name" ]; then
    echo "Running on device: x86 CPU + Kunlunxin K100"
    echo "Perform step $test_name 29"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 cpu $kunlunxin_xtcl_amd64_test_device_name
    echo "Perform step $test_name 30"
    ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 kunlunxin_xtcl $kunlunxin_xtcl_amd64_test_device_name
  fi
  echo "done"
}

build_and_run_model_test() {
  local test_name="model_test"
  echo "build and run $test_name"
  cd $cur_dir/$test_name/shell
  # android arm64-v8a
  ./build.sh android arm64-v8a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 1"
    ./run_with_adb.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 android arm64-v8a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 2"
    ./run_with_adb.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 android arm64-v8a huawei_kirin_npu $huawei_kirin_npu_test_device_name
  fi
  # android armeabi-v7a
  ./build.sh android armeabi-v7a
  if [ -n "$huawei_kirin_npu_test_device_name" ]; then
    echo "Running on device: Huawei P40pro 5G"
    echo "Perform step $test_name 3"
    ./run_with_adb.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 android armeabi-v7a cpu $huawei_kirin_npu_test_device_name
    echo "Perform step $test_name 4"
    ./run_with_adb.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 android armeabi-v7a huawei_kirin_npu $huawei_kirin_npu_test_device_name
  fi
  if [ -n "$mediatek_apu_test_device_name" ]; then
    echo "Running on device: Xiaodu Tablet X10"
    echo "Perform step $test_name 5"
    ./run_with_adb.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 android armeabi-v7a cpu $mediatek_apu_test_device_name
    echo "Perform step $test_name 6"
    ./run_with_adb.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name
    echo "Perform step $test_name 7"
    ./run_with_adb.sh conv_bn_relu_224_int8_per_channel 0 1,3,224,224 float32 float32 android armeabi-v7a cpu $mediatek_apu_test_device_name
    echo "Perform step $test_name 8"
    ./run_with_adb.sh conv_bn_relu_224_int8_per_channel 0 1,3,224,224 float32 float32 android armeabi-v7a mediatek_apu $mediatek_apu_test_device_name
  fi
  # linux arm64
  ./build.sh linux arm64
  if [ -n "$rockchip_npu_rk1808evb_test_device_name" ]; then
    echo "Running on device: RK1808EVB"
    echo "Perform step $test_name 9"
    ./run_with_adb.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 cpu $rockchip_npu_rk1808evb_test_device_name
    echo "Perform step $test_name 10"
    ./run_with_adb.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 rockchip_npu $rockchip_npu_rk1808evb_test_device_name
  fi
  if [ -n "$rockchip_npu_tb_rk1808s0_test_device_name" ]; then
    echo "Running on device: Toybirck TB-RK1808S0"
    echo "Perform step $test_name 11"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 cpu $rockchip_npu_tb_rk1808s0_test_device_name
    echo "Perform step $test_name 12"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 rockchip_npu $rockchip_npu_tb_rk1808s0_test_device_name
  fi
  if [ -n "$amlogic_npu_test_device_name" ]; then
    echo "Running on device: Amlogic A311D"
    echo "Perform step $test_name 13"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 cpu $amlogic_npu_test_device_name
    echo "Perform step $test_name 14"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 amlogic_npu $amlogic_npu_test_device_name
  fi
  if [ -n "$imagination_nna_test_device_name" ]; then
    echo "Running on device: ROC1"
    echo "Perform step $test_name 15"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 cpu $imagination_nna_test_device_name
    echo "Perform step $test_name 16"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 imagination_nna $imagination_nna_test_device_name
  fi
  if [ -n "$huawei_ascend_npu_arm64_test_device_name" ]; then
    echo "Running on device: Kunpeng 920 + Huawei Atlas 300C(3000)"
    echo "Perform step $test_name 17"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 cpu $huawei_ascend_npu_arm64_test_device_name
    echo "Perform step $test_name 18"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 huawei_ascend_npu $huawei_ascend_npu_arm64_test_device_name
  fi
  if [ -n "$verisilicon_timvx_armlinux_test_device_name" ]; then
    echo "Running on device: Khadas VIM3"
    echo "Perform step $test_name 19"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 20"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 21"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 cpu $verisilicon_timvx_armlinux_test_device_name
    echo "Perform step $test_name 22"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 verisilicon_timvx $verisilicon_timvx_armlinux_test_device_name
  fi
  if [ -n "$kunlunxin_arm64_test_device_name" ]; then
    echo "Running on device: ARM CPU + Kunlunxin K100"
    echo "Perform step $test_name 23"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 cpu $kunlunxin_arm64_test_device_name
    echo "Perform step $test_name 24"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 kunlunxin_xtcl $kunlunxin_arm64_test_device_name
  fi
  # linux armhf
  ./build.sh linux armhf
  if [ -n "$rockchip_npu_rv1109_test_device_name" ]; then
    echo "Running on device: Dumu RV1109"
    echo "Perform step $test_name 25"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux armhf cpu $rockchip_npu_rv1109_test_device_name
    echo "Perform step $test_name 26"
    ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux armhf rockchip_npu $rockchip_npu_rv1109_test_device_name
  fi
  # linux amd64
  ./build.sh linux amd64
  if [ -n "$huawei_ascend_npu_amd64_test_device_name" ]; then
    echo "Running on device: Intel x86 + Huawei Atlas 300C(3010)"
    echo "Perform step $test_name 27"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 cpu $huawei_ascend_npu_amd64_test_device_name
    echo "Perform step $test_name 28"
    ./run_with_ssh.sh  conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 huawei_ascend_npu $huawei_ascend_npu_amd64_test_device_name
  fi
  if [ -n "$kunlunxin_xtcl_amd64_test_device_name" ]; then
    echo "Running on device: x86 CPU + Kunlunxin K100"
    echo "Perform step $test_name 29"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 cpu $kunlunxin_xtcl_amd64_test_device_name
    echo "Perform step $test_name 30"
    ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 kunlunxin_xtcl $kunlunxin_xtcl_amd64_test_device_name
  fi
  echo "done"
}

clean() {
  local demo_dir=$cur_dir/$1
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

build_and_run_image_classification_demo
build_and_run_ssd_detection_demo
build_and_run_yolo_detection_demo
build_and_run_model_test

# clean all
clean image_classification_demo
clean ssd_detection_demo
clean yolo_detection_demo
clean model_test

echo "all done."
