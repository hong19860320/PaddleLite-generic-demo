#!/bin/bash
set -e

# User config
src_dir=/Work/Paddle-Lite/experiment/Paddle-Lite
# HuaweiKirinNPU
#nnadapter_device_name="huawei_kirin_npu"
#nnadapter_device_list="UQG0220A15000356"
# MediatekAPU
#nnadapter_device_name="mediatek_apu"
#nnadapter_device_list="0123456789ABCDEF"
# RockchipNPU
#nnadapter_device_name="rockchip_npu"
#nnadapter_device_list="192.168.180.8,22,toybrick,toybrick"
# HuaweiAscendNPU
#nnadapter_device_name="huawei_ascend_npu" # No need to set 'nnadapter_device_list' because this script must be run on the device locally
# AmlogicNPU
#nnadapter_device_name="amlogic_npu"
#nnadapter_device_list="192.168.100.244,22,root,123456"
# ImaginationNNA
#nnadapter_device_name="imagination_nna"
#nnadapter_device_list="192.168.100.10,22,img,imgroc1"
# VerisiliconTIMVX
#nnadapter_device_name="verisilicon_timvx"
#nnadapter_device_list="c8631471d5cd"
# KunlunxinXTCL
#nnadapter_device_name="kunlunxin_xtcl" # No need to set 'nnadapter_device_list' because this script must be run on the device locally
# CambriconMLU
#nnadapter_device_name="cambricon_mlu" # No need to set 'nnadapter_device_list' because this script must be run on the device locally

if [ -z $nnadapter_device_name ]; then
  echo "nnadapter_device_name should not be empty!"
  exit 1
fi
if [ "$nnadapter_device_name" = "huawei_kirin_npu" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_mobilenet_v1_fp32_nnadapter,test_resnet50_fp32_nnadapter,test_ssd_mobilenet_v1_relu_voc_fp32_nnadapter"
  unit_test_filter_type=1
  remote_device_type=0
  remote_device_list=$nnadapter_device_list
  build_target=huawei_kirin_npu_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
elif [ "$nnadapter_device_name" = "mediatek_apu" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter,test_mobilenet_v1_int8_per_channel_nnadapter,test_resnet50_int8_per_layer_nnadapter,test_ssd_mobilenet_v1_relu_voc_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=0
  remote_device_list=$nnadapter_device_list
  build_target=mediatek_apu_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
elif [ "$nnadapter_device_name" = "rockchip_npu" ]; then
  os=armlinux
  arch=armv8
  toolchain=gcc
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter,test_resnet50_int8_per_layer_nnadapter,test_ssd_mobilenet_v1_relu_voc_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=1
  remote_device_list=$nnadapter_device_list
  build_target=rockchip_npu_build_and_test
  remote_device_work_dir="~/$build_target"
elif [ "$nnadapter_device_name" = "huawei_ascend_npu" ]; then
  #os=armlinux
  #arch=armv8
  arch=x86
  toolchain=gcc
  #unit_test_check_list="test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view"
  #unit_test_filter_type=0
  unit_test_check_list="test_kernel_activation_compute"
  unit_test_filter_type=1
  build_target=huawei_ascend_npu_build_and_test
elif [ "$nnadapter_device_name" = "amlogic_npu" ]; then
  os=armlinux
  arch=armv8
  toolchain=gcc
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=1
  remote_device_list=$nnadapter_device_list
  build_target=amlogic_npu_build_and_test
  remote_device_work_dir="~/$build_target"
elif [ "$nnadapter_device_name" = "imagination_nna" ]; then
  os=armlinux
  arch=armv8
  toolchain=gcc
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=1
  remote_device_list=$nnadapter_device_list
  build_target=imagination_nna_build_and_test
  remote_device_work_dir="~/$build_target"
elif [ "$nnadapter_device_name" = "verisilicon_timvx" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_cxx_api,test_mobilenetv1_int8,test_mobilenetv1_int16,test_inceptionv4,test_fast_rcnn,test_light_api,test_apis,test_gen_code,test_generated_code,sgemv_compute_test,conv_compute_test,conv_int8_compute_test,sgemm_compute_test,test_kernel_decode_bboxes_compute,test_decode_bboxes_compute_arm,test_inception_v4_fp32_arm,test_mobilenet_v1_fp32_arm,test_mobilenet_v1_int8_dygraph_arm,test_mobilenet_v2_fp32_arm,test_mobilenet_v3_small_x1_0_fp32_arm,test_mobilenet_v3_large_x1_0_fp32_arm,test_resnet50_fp32_arm,test_squeezenet_fp32_arm,test_transformer_with_mask_fp32_arm,test_mobilenet_v1_int8_arm,test_mobilenet_v2_int8_arm,test_resnet50_int8_arm,test_ocr_lstm_int8_arm,test_nlp_lstm_int8_arm,test_lac_crf_fp32_int16_arm"
  unit_test_filter_type=0
  remote_device_type=0
  remote_device_list=$nnadapter_device_list
  build_target=verisilicon_timvx_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
  extra_arguments="--nnadapter_verisilicon_timvx_src_git_tag=main --nnadapter_verisilicon_timvx_viv_sdk_url=http://paddlelite-demo.bj.bcebos.com/devices/verisilicon/sdk/viv_sdk_android_9_armeabi_v7a_6_4_4_3_generic.tgz"
elif [ "$nnadapter_device_name" = "kunlunxin_xtcl" ]; then
  #os=armlinux
  #arch=armv8
  arch=x86
  toolchain=gcc
  #unit_test_check_list="test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view"
  #unit_test_filter_type=0
  unit_test_check_list="test_kernel_activation_compute,test_mobilenet_v1_fp32_v1_8_nnadapter,test_mobilenet_v1_fp32_v2_0_nnadapter,test_resnet50_fp32_v1_8_nnadapter,test_resnet50_fp32_v2_0_nnadapter,test_ssd_mobilenet_v1_relu_voc_fp32_v1_8_nnadapter"
  unit_test_filter_type=1
  build_target=kunlunxin_xtcl_build_and_test
elif [ "$nnadapter_device_name" = "cambricon_mlu" ]; then
  arch=x86
  toolchain=gcc
  unit_test_check_list="test_kernel_argmax_compute,test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view"
  unit_test_filter_type=0
  build_target=cambricon_mlu_build_and_test
else
  echo "nnadapter_device_name($nnadapter_device_name) is not supported."
  exit 1
fi
unit_test_log_level=5

cd $src_dir
./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=$unit_test_log_level --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target

echo "done"
