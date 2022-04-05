#!/bin/bash
set -e

source settings.sh

if [ "$ENABLE_TEST_HUAWEI_KIRIN_NPU" == "1" ] && [ -n "$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view,test_gen_code,test_generated_code,test_mobilenetv1_int8,test_mobilenetv1,test_mobilenetv1_int16,test_mobilenetv2,test_resnet50,test_inceptionv4,test_fast_rcnn,test_resnet50_fpga,test_mobilenetv1_opt_quant,sgemv_compute_test,test_kernel_decode_bboxes_compute,test_decode_bboxes_compute_arm"
  unit_test_filter_type=0
  #unit_test_check_list="test_kernel_activation_compute"
  #unit_test_filter_type=1
  remote_device_type=0
  remote_device_list=$HUAWEI_KIRIN_NPU_ANDROID_ARM64_V8A_DEVICE_LIST
  build_target=huawei_kirin_npu_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_MEDIATEK_APU" == "1" ] && [ -n "$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter,test_mobilenet_v1_int8_per_channel_nnadapter,test_resnet50_int8_per_layer_nnadapter,test_ssd_mobilenet_v1_relu_voc_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=0
  remote_device_list=$MEDIATEK_APU_ANDROID_ARMEABI_V7A_DEVICE_LIST
  build_target=mediatek_apu_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_ROCKCHIP_NPU" == "1" ] && [ -n "$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
  os=armlinux
  arch=armv8
  toolchain=gcc
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter,test_resnet50_int8_per_layer_nnadapter,test_ssd_mobilenet_v1_relu_voc_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=1
  remote_device_list=$ROCKCHIP_NPU_LINUX_ARM64_DEVICE_LIST
  build_target=rockchip_npu_build_and_test
  remote_device_work_dir="~/$build_target"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_HUAWEI_ASCEND_NPU" == "1" ] && [ -n "$HUAWEI_ASCEND_NPU_LINUX_AMD64_DEVICE_LIST" ]; then
  #os=armlinux
  #arch=armv8
  arch=x86
  toolchain=gcc
  #unit_test_check_list="test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view"
  #unit_test_filter_type=0
  unit_test_check_list="test_kernel_activation_compute"
  unit_test_filter_type=1
  build_target=huawei_ascend_npu_build_and_test
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_AMLOGIC_NPU" == "1" ] && [ -n "$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST" ]; then
  os=armlinux
  arch=armv8
  toolchain=gcc
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=1
  remote_device_list=$AMLOGIC_NPU_LINUX_ARM64_DEVICE_LIST
  build_target=amlogic_npu_build_and_test
  remote_device_work_dir="~/$build_target"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
if

if [ "$ENABLE_TEST_IMAGINATION_NNA" == "1" ] && [ -n "$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST" ]; then
  os=armlinux
  arch=armv8
  toolchain=gcc
  unit_test_check_list="test_mobilenet_v1_int8_per_layer_nnadapter"
  unit_test_filter_type=1
  remote_device_type=1
  remote_device_list=$IMAGINATION_NNA_LINUX_ARM64_DEVICE_LIST
  build_target=imagination_nna_build_and_test
  remote_device_work_dir="~/$build_target"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_VERISILICON_TIMVX" == "1" ] && [ -n "$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_cxx_api,test_mobilenetv1_int8,test_mobilenetv1_int16,test_inceptionv4,test_fast_rcnn,test_light_api,test_apis,test_gen_code,test_generated_code,sgemv_compute_test,conv_compute_test,conv_int8_compute_test,sgemm_compute_test,test_kernel_decode_bboxes_compute,test_decode_bboxes_compute_arm,test_inception_v4_fp32_arm,test_mobilenet_v1_fp32_arm,test_mobilenet_v1_int8_dygraph_arm,test_mobilenet_v2_fp32_arm,test_mobilenet_v3_small_x1_0_fp32_arm,test_mobilenet_v3_large_x1_0_fp32_arm,test_resnet50_fp32_arm,test_squeezenet_fp32_arm,test_transformer_with_mask_fp32_arm,test_mobilenet_v1_int8_arm,test_mobilenet_v2_int8_arm,test_resnet50_int8_arm,test_ocr_lstm_int8_arm,test_nlp_lstm_int8_arm,test_lac_crf_fp32_int16_arm"
  unit_test_filter_type=0
  remote_device_type=0
  remote_device_list=$VERISILICON_TIMVX_ANDROID_ARMEABI_V7A_DEVICE_LIST
  build_target=verisilicon_timvx_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
  extra_arguments="--nnadapter_verisilicon_timvx_src_git_tag=$VERISILICON_TIMVX_SRC_GIT_TAG --nnadapter_verisilicon_timvx_viv_sdk_url=http://paddlelite-demo.bj.bcebos.com/devices/verisilicon/sdk/viv_sdk_android_9_armeabi_v7a_6_4_4_3_generic.tgz"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_KUNLUNXIN_XTCL" == "1" ] && [ -n "$KUNLUNXIN_XTCL_LINUX_AMD64_DEVICE_LIST" ]; then
  #os=armlinux
  #arch=armv8
  arch=x86
  toolchain=gcc
  #unit_test_check_list="test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view"
  #unit_test_filter_type=0
  unit_test_check_list="test_kernel_activation_compute,test_mobilenet_v1_fp32_v1_8_nnadapter,test_mobilenet_v1_fp32_v2_0_nnadapter,test_resnet50_fp32_v1_8_nnadapter,test_resnet50_fp32_v2_0_nnadapter,test_ssd_mobilenet_v1_relu_voc_fp32_v1_8_nnadapter"
  unit_test_filter_type=1
  build_target=kunlunxin_xtcl_build_and_test
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_CAMBRICON_MLU" == "1" ] && [ -n "$CAMBRICON_MLU_LINUX_AMD64_DEVICE_LIST" ]; then
  arch=x86
  toolchain=gcc
  unit_test_check_list="test_kernel_argmax_compute,test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view"
  unit_test_filter_type=0
  build_target=cambricon_mlu_build_and_test
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

if [ "$ENABLE_TEST_ANDROID_NNAPI" == "1" ] && [ -n "$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST" ]; then
  os=android
  arch=armv7
  toolchain=clang
  unit_test_check_list="test_light_api,test_apis,test_paddle_api,test_cxx_api,test_vector_view,test_gen_code,test_generated_code,test_mobilenetv1_int8,test_mobilenetv1,test_mobilenetv1_int16,test_mobilenetv2,test_resnet50,test_inceptionv4,test_fast_rcnn,test_resnet50_fpga,test_mobilenetv1_opt_quant,sgemv_compute_test,test_kernel_decode_bboxes_compute,test_decode_bboxes_compute_arm"
  unit_test_filter_type=0
  #unit_test_check_list="test_kernel_activation_compute"
  #unit_test_filter_type=1
  remote_device_type=0
  remote_device_list=$ANDROID_NNAPI_ANDROID_ARMEABI_V7A_DEVICE_LIST
  build_target=android_nnapi_build_and_test
  remote_device_work_dir="/data/local/tmp/$build_target"
  cd $LITE_DIR
  ./tools/ci_tools/ci_nn_accelerators_unit_test.sh --os_list=$os --arch_list=$arch --toolchain_list=$toolchain --unit_test_check_list=$unit_test_check_list --unit_test_filter_type=$unit_test_filter_type --unit_test_log_level=5 --remote_device_type=$remote_device_type --remote_device_list=$remote_device_list --remote_device_work_dir=$remote_device_work_dir $extra_arguments $build_target
fi

echo "all done."
